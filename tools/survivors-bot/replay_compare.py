#!/usr/bin/env python3
"""Exact streaming native replay oracle. Development only; no game or policy code.

The observer records F32 values as U32 bits. We compare every declared gameplay
field and every authoritative component/lifecycle/allocator/clock observation.
Only named wall-clock timing fields are excluded. Missing data fails closed.
"""
from __future__ import annotations
import argparse
import hashlib
import itertools
import json
from pathlib import Path

SCHEMA_VERSION = 1
TIMING_FIELDS = frozenset({"wallMs", "windowMs", "elapsedMs", "timingMs"})
PAYLOAD_KEYS = frozenset({"run", "bodies", "offers", "snapshots", "pending", "components", "metadata"})

class ReplayError(ValueError):
    pass

def _pairs(pairs):
    value = {}
    for key, entry in pairs:
        if key in value:
            raise ReplayError(f"Duplicate JSON key: {key}")
        value[key] = entry
    return value

def _constant(value):
    raise ReplayError(f"Non-finite JSON number: {value}")

def integer(value, label, maximum=None):
    if type(value) is not int or value < 0 or (maximum is not None and value > maximum):
        raise ReplayError(f"Invalid {label}: expected nonnegative integer" )
    return value

def u32(value, label):
    return integer(value, label, 0xffffffff)

def words(value, length, label):
    if not isinstance(value, list) or len(value) != length:
        raise ReplayError(f"Invalid {label}: expected {length} words")
    for entry in value:
        u32(entry, label)

def tick(value):
    if value is not None:
        if not isinstance(value, list) or len(value) != 2:
            raise ReplayError("Invalid lifecycle tick")
        integer(value[0], "tick epoch")
        u32(value[1], "tick low")

def validate_payload(payload, checkpoint_tick):
    if not isinstance(payload, dict) or set(payload) != PAYLOAD_KEYS:
        raise ReplayError("Incomplete full-state payload")
    run = payload["run"]
    if not isinstance(run, list) or len(run) != 29:
        raise ReplayError("Incomplete Run observation")
    for index, value in enumerate(run):
        if index in (12, 13, 27):
            if not isinstance(value, list):
                raise ReplayError("Invalid Run list")
            for word in value:
                u32(word, "Run list word")
        else:
            u32(value, "Run word/F32 bits")
    if run[0] > 4 or run[1] != checkpoint_tick or len(run[12]) != 24 or len(run[13]) != 18:
        raise ReplayError("Run phase/tick/loadout shape does not match checkpoint")
    for body in payload["bodies"]:
        words(body, 9, "Body")
    for offer in payload["offers"]:
        words(offer, 3, "Offer")
    for snapshot in payload["snapshots"]:
        if not isinstance(snapshot, list) or len(snapshot) != 2:
            raise ReplayError("Invalid Snapshot")
        words(snapshot[0], 9, "Snapshot Body")
        validate_motion(snapshot[1])
    for entry in payload["pending"]:
        if u32(entry, "pending reward") not in (1, 2):
            raise ReplayError("Unknown pending reward kind")
    components = payload["components"]
    if not isinstance(components, dict) or set(components) != {"bodies", "vitals", "motions"}:
        raise ReplayError("Missing authoritative component family")
    for family, records in components.items():
        if not isinstance(records, list) or len(records) != 1468:
            raise ReplayError(f"Expected all 1468 authoritative {family} slots")
        for expected_id, record in enumerate(records, 1):
            if not isinstance(record, list) or len(record) != 3 or record[0] != expected_id:
                raise ReplayError(f"Noncanonical {family} slot order")
            value, stamp = record[1:]
            if family == "motions":
                validate_motion(value)
            else:
                words(value, 9 if family == "bodies" else 2, family)
            if family == "bodies" and value[7] != expected_id - 1:
                raise ReplayError("Authoritative Body slot identity changed")
            if not isinstance(stamp, list) or len(stamp) != 2:
                raise ReplayError("Missing lifecycle stamp pair")
            tick(stamp[0]); tick(stamp[1])
    metadata = payload["metadata"]
    if not isinstance(metadata, dict) or set(metadata) != {"namespace", "allocator", "clock", "events", "pendingCommands", "registrations", "nextSystemId"}:
        raise ReplayError("Missing world metadata")
    # Commands are affine closures, which this fixed-game observer cannot encode.
    # Refuse them rather than pretending equal counts establish equal effects.
    if metadata["pendingCommands"] != 0:
        raise ReplayError("Opaque pending World commands are outside this replay oracle")
    if metadata["events"] != 0 or metadata["registrations"] != []:
        raise ReplayError("Unexpected fixed-game world events/registrations")
    u32(metadata["namespace"], "namespace"); u32(metadata["nextSystemId"], "nextSystemId")
    clock = metadata["clock"]
    if not isinstance(clock, list) or len(clock) != 2 or not isinstance(clock[1], list):
        raise ReplayError("Invalid world clock")
    tick(clock[0])
    for scoped in clock[1]:
        tick(scoped)
    alloc = metadata["allocator"]
    if not isinstance(alloc, list) or len(alloc) != 7:
        raise ReplayError("Missing allocator observation")
    for value in alloc[:4]:
        integer(value, "allocator scalar")
    if not isinstance(alloc[6], list) or len(alloc[6]) != alloc[2]:
        raise ReplayError("Allocator slot count differs from capacity")
    for slot in alloc[6]:
        words(slot, 2, "allocator slot")
        if slot[1] > 4:
            raise ReplayError("Invalid allocator phase")
    for free in alloc[4]:
        u32(free, "free slot")
    for key in alloc[5]:
        words(key, 2, "entity key")

def validate_motion(value):
    if not isinstance(value, list) or len(value) != 9 or not isinstance(value[4], list):
        raise ReplayError("Invalid Motion")
    for index, entry in enumerate(value):
        for word in (entry if index == 4 else [entry]):
            u32(word, "Motion word/F32 bits")

def semantic(record):
    # Restrict timing removal to outer record fields, never arbitrary nested
    # gameplay keys, so a future state field cannot silently escape comparison.
    return {key: value for key, value in record.items() if key not in TIMING_FIELDS}

def records(path, max_bytes=1024**3):
    if path.stat().st_size > max_bytes:
        raise ReplayError(f"Replay exceeds byte bound: {path}")
    last_semantic = None
    timing_seen = False
    with path.open(encoding="utf-8") as source:
        for line_number, line in enumerate(source, 1):
            if not line.endswith("\n"):
                raise ReplayError(f"Incomplete final record: {path}:{line_number}")
            if not line.strip():
                raise ReplayError(f"Empty replay record: {path}:{line_number}")
            try:
                record = json.loads(line, object_pairs_hook=_pairs, parse_constant=_constant)
            except (ValueError, TypeError) as error:
                raise ReplayError(f"Invalid JSON at {path}:{line_number}: {error}") from error
            if not isinstance(record, dict) or record.get("type") not in {"start", "checkpoint", "summary", "replay-summary"}:
                raise ReplayError(f"Unknown replay record at {path}:{line_number}")
            if record["type"] == "replay-summary":
                # Benchmark-only timing is not a gameplay observation.
                if last_semantic is None or timing_seen:
                    raise ReplayError("Duplicate replay timing or timing before semantic start")
                duration = record.get("windowMs")
                if type(duration) not in (int, float) or duration < 0:
                    raise ReplayError("Invalid replay timing record")
                timing_seen = True
                continue
            last_semantic = record["type"]
            yield record

def first_difference(left, right, path="$", remaining=120):
    if type(left) is not type(right):
        return path + " (type)"
    if isinstance(left, dict):
        if left.keys() != right.keys():
            return path + " (keys)"
        for key in left:
            if left[key] != right[key]:
                return first_difference(left[key], right[key], path + "." + key, remaining - 1) if remaining else path
    elif isinstance(left, list):
        if len(left) != len(right):
            return path + " (length)"
        for index, value in enumerate(left):
            if value != right[index]:
                return first_difference(value, right[index], path + f"[{index}]", remaining - 1) if remaining else path
    elif left != right:
        return path
    return None

def file_sha(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

def trace_contract(path):
    text = path.read_text(encoding="ascii")
    # Native format accepts only whitespace and decimal U32 words.
    tokens = text.split()
    if len(tokens) < 9 or any(not token.isascii() or not token.isdecimal() for token in tokens):
        raise ReplayError("Invalid numeric replay trace")
    values = [int(token) for token in tokens]
    if any(value > 0xffffffff for value in values):
        raise ReplayError("Trace word exceeds U32")
    magic, version, profile, seed, warmup, end, actual, phase, count = values[:9]
    if magic != 1313231410 or version != 1 or profile > 1 or phase > 4 or not warmup <= actual <= end:
        raise ReplayError("Invalid replay trace header")
    position = 9; actions = 0; tick_value = 0
    while position < len(values):
        tag = values[position]
        length = 5 if tag == 0 else 4 if tag == 1 else 0
        if not length or position + length > len(values):
            raise ReplayError("Truncated/unknown replay action")
        action = values[position:position + length]
        if action[1] != tick_value:
            raise ReplayError("Recorded action tick sequence is inconsistent")
        if tag == 0:
            if action[2] != 0 or any((word >> 23) & 255 == 255 for word in action[3:]):
                raise ReplayError("Invalid move phase or nonfinite direction bits")
            tick_value += 1
        elif action[2] not in (1, 2) or action[3] > 2:
            raise ReplayError("Invalid upgrade phase/index")
        position += length; actions += 1
    if actions != count or tick_value != actual:
        raise ReplayError("Trace count/end tick mismatch")
    return {"profile": profile, "seed": seed, "warmup": warmup, "endTick": end,
            "actualEnd": actual, "phase": phase, "actions": count,
            "fixture": f"seed{seed}-profile{profile}-warm{warmup}-end{end}"}

def compare(baseline: Path, candidate: Path, *, minimum_checkpoints=2, max_bytes=1024**3, trace=None):
    if minimum_checkpoints < 2:
        raise ReplayError("At least two full-state checkpoints required")
    expected = trace_contract(trace) if trace is not None else None
    chain = hashlib.sha256(); seen_start = False; seen_summary = False
    count = 0; fixture = None; last_step = -1; last_tick = -1
    sentinel = object()
    for position, (left, right) in enumerate(itertools.zip_longest(records(baseline, max_bytes), records(candidate, max_bytes), fillvalue=sentinel), 1):
        if left is sentinel or right is sentinel:
            raise ReplayError(f"Record count mismatch at record {position}")
        encoded = json.dumps(semantic(left), sort_keys=True, separators=(",", ":"), allow_nan=False).encode()
        other_encoded = json.dumps(semantic(right), sort_keys=True, separators=(",", ":"), allow_nan=False).encode()
        if encoded != other_encoded:
            raise ReplayError(f"Replay mismatch at record {position}: {first_difference(semantic(left), semantic(right))}")
        kind = left["type"]
        if seen_summary:
            raise ReplayError("Records after terminal summary")
        if kind == "start":
            if seen_start or position != 1 or left.get("schemaVersion") != SCHEMA_VERSION:
                raise ReplayError("Invalid/duplicate replay start")
            fixture = left.get("fixture")
            if not isinstance(fixture, str) or not fixture:
                raise ReplayError("Missing fixture identity")
            if expected and any(left.get(key) != expected[key] for key in ("fixture", "seed", "profile", "warmup", "endTick")):
                raise ReplayError("Replay start does not bind supplied trace")
            seen_start = True
        elif not seen_start or left.get("fixture") != fixture:
            raise ReplayError("Replay fixture/order mismatch")
        elif kind == "checkpoint":
            step = integer(left.get("step"), "checkpoint step")
            payload = left.get("payload")
            observed_tick = payload.get("run", [None, None])[1] if isinstance(payload, dict) else None
            current_tick = u32(left.get("tick", observed_tick), "checkpoint tick")
            if step <= last_step or current_tick < last_tick:
                raise ReplayError("Checkpoint order regressed/repeated")
            validate_payload(left.get("payload"), current_tick)
            last_step, last_tick = step, current_tick
            count += 1
        elif kind == "summary":
            if count < minimum_checkpoints:
                raise ReplayError("Too few full-state checkpoints")
            if expected and (left.get("actions") != expected["actions"] or left.get("endTick") != expected["actualEnd"] or left.get("phase") != expected["phase"] or left.get("firstTick") != expected["warmup"] or last_step != expected["actions"] or last_tick != expected["actualEnd"]):
                raise ReplayError("Replay summary/checkpoint does not bind supplied trace")
            seen_summary = True
        chain.update(len(encoded).to_bytes(8, "big")); chain.update(encoded)
    if not seen_start or not seen_summary:
        raise ReplayError("Incomplete replay: start/summary absent")
    return {"status": "passed", "fixture": fixture, "checkpoints": count, "semanticSha256": chain.hexdigest(), "baselineSha256": file_sha(baseline), "candidateSha256": file_sha(candidate), "scope": "Exact declared gameplay and all 1468 authoritative component/stamp/world-metadata observations; timing fields excluded only at record root."}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path); parser.add_argument("candidate", type=Path)
    parser.add_argument("--trace", type=Path); parser.add_argument("--receipt", type=Path); parser.add_argument("--minimum-checkpoints", type=int, default=2)
    args = parser.parse_args()
    try:
        result = compare(args.baseline, args.candidate, minimum_checkpoints=args.minimum_checkpoints, trace=args.trace)
    except (ValueError, OSError, TypeError) as error:
        result = {"status": "failed", "error": str(error)}
    if args.receipt:
        args.receipt.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result))
    return 0 if result["status"] == "passed" else 1

if __name__ == "__main__":
    raise SystemExit(main())
