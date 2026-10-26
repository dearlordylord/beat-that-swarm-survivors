#!/usr/bin/env python3
"""Run a fixed paired native replay cohort; preserve every output and check state.

Development tool only. No bot, rendering, compilation, or classifier runs here.
The internal replay window is the metric; process wall time is diagnostic.
"""
from __future__ import annotations

import argparse
import json
import math
import os
from pathlib import Path
import random
import signal
import statistics
import subprocess
import sys
import time

sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
from dataclasses import asdict
from process_diagnostics import RunResult, format_failure
from replay_compare import compare, file_sha  # noqa: E402


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, allow_nan=False) + "\n")


def run_sample(binary, fixture, output, timeout):
    environment = dict(os.environ)
    environment.pop("BENDRTS", None)
    environment.update(NIGHTFALL_REPLAY_TRACE=str(fixture),
                       NIGHTFALL_REPLAY_CHECKPOINT_EVERY="0")
    started = time.monotonic()
    command = [str(binary), "+RTS", "--threads", "1", "-RTS"]
    child = None
    timed_out = False
    failure = None
    try:
        with output.open("wb") as stdout, output.with_suffix(".stderr").open("wb") as stderr:
            try:
                child = subprocess.Popen(command, env=environment, stdout=stdout, stderr=stderr)
                status = child.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                timed_out = True
                raise
            finally:
                if child is not None and child.poll() is None:
                    child.kill()
                    child.wait()
    except BaseException as error:
        failure = error
        raise
    finally:
        wall = time.monotonic() - started
        if failure is not None or child is None or child.returncode != 0:
            result = RunResult(command=tuple(command), cwd=os.getcwd(), returncode=child.returncode if child else None,
                               elapsed_wall_seconds=wall,
                               stdout=output.read_text(errors="replace") if output.exists() else "",
                               stderr=output.with_suffix(".stderr").read_text(errors="replace") if output.with_suffix(".stderr").exists() else "",
                               wall_timeout_seconds=timeout, cpu_limit_seconds=None, wall_timed_out=timed_out,
                               spawn_error=str(failure) if isinstance(failure, OSError) else None)
            write_json(output.with_suffix(".process.json"), {**asdict(result), "classification": result.classification,
                       "signal": result.signal_name, "stdoutPath": str(output), "stderrPath": str(output.with_suffix(".stderr")),
                       "error": repr(failure) if failure else None})
            if (not result.normal_exit or result.returncode != 0):
                print(format_failure(result, "Native replay failed"), file=sys.stderr)
    if status:
        raise RuntimeError(f"Replay failed ({status}); see {output}")
    with output.open() as source:
        summaries = [row for row in (json.loads(line) for line in source)
                     if row.get("type") == "replay-summary"]
    if len(summaries) != 1:
        raise ValueError(f"Expected one summary: {output}")
    milliseconds = summaries[0].get("windowMs")
    if type(milliseconds) is not int or milliseconds <= 0:
        raise ValueError(f"Missing positive integer windowMs: {output}")
    return {"windowMs": milliseconds, "processWallSeconds": wall,
            "outputSha256": file_sha(output)}


def analyze(pairs):
    ratios = [row["candidate"]["windowMs"] / row["reference"]["windowMs"] for row in pairs]
    logs = [math.log(value) for value in ratios]
    # Resample fixture clusters, preserving their repeated runs and paired order.
    clusters = {}
    for row, value in zip(pairs, logs):
        clusters.setdefault(row["fixtureSha256"], []).append(value)
    groups = list(clusters.values())
    rng = random.Random(20261023)
    samples = []
    for _ in range(10000):
        selected = [value for _ in groups for value in rng.choice(groups)]
        samples.append(math.exp(statistics.mean(selected)))
    samples.sort()
    strata = {}
    for order in ("reference-first", "candidate-first"):
        values = [ratio for row, ratio in zip(pairs, ratios) if row["order"] == order]
        if values:
            strata[order] = statistics.median(values)
    # This describes this fixed population; it does not prove all game workloads.
    return {"pairs": len(pairs), "fixtures": len(groups),
            "medianCandidateOverReference": statistics.median(ratios),
            "geometricMeanCandidateOverReference": math.exp(statistics.mean(logs)),
            "fixtureClusterBootstrap95": [samples[249], samples[9749]] if len(groups) >= 2 else None,
            "medianRatioByOrder": strata,
            "interpretation": "Lower is better. Inspect reference repeat noise and order strata before accepting; this interval alone is not an acceptance gate."}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument("--candidate", required=True, type=Path)
    parser.add_argument("--fixtures", required=True, type=Path,
                        help="Frozen fixture manifest, or JSON array of absolute trace paths")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--layout", type=Path,
                        help="Optional sparse ECS layout for exact same-schema comparison")
    parser.add_argument("--rounds", type=int, default=3)
    parser.add_argument("--timeout", type=int, default=180)
    parser.add_argument("--max-seconds", type=int, required=True,
                        help="Overall cohort wall bound, within the authorized action deadline")
    args = parser.parse_args()
    if not 1 <= args.rounds <= 100 or not 1 <= args.timeout <= 3600 or not 1 <= args.max_seconds <= 28800:
        parser.error("rounds 1..100, timeout 1..3600, max-seconds 1..28800 required")
    layout = None
    layout_path = None
    layout_sha = None
    if args.layout:
        from current_replay_schema import validate_layout
        layout_path = args.layout.resolve(strict=True)
        layout_sha = file_sha(layout_path)
        # Use the oracle's strict JSON hooks so duplicate layout keys fail closed.
        from replay_compare import _pairs, _constant
        layout = validate_layout(json.loads(layout_path.read_text(), object_pairs_hook=_pairs, parse_constant=_constant))
        if file_sha(layout_path) != layout_sha:
            parser.error("Layout changed while being read")
    document = json.loads(args.fixtures.read_text())
    expected = {}
    if isinstance(document, dict):
        if document.get("schemaVersion") != 1:
            parser.error("Unsupported fixture manifest")
        fixtures = []
        for row in document["fixtures"]:
            path = (args.fixtures.parent / row["path"]).resolve(strict=True)
            if file_sha(path) != row["traceSha256"]:
                parser.error(f"Fixture digest mismatch: {path}")
            expected[str(path)] = row["semanticSha256"]
            fixtures.append(path)
    else:
        fixtures = [Path(value).resolve(strict=True) for value in document]
    if not fixtures or len(set(fixtures)) != len(fixtures):
        parser.error("Fixtures must be a nonempty unique list")
    reference, candidate = args.reference.resolve(strict=True), args.candidate.resolve(strict=True)
    args.output.mkdir(parents=True, exist_ok=False)
    evaluators = [Path(__file__).resolve(), args.fixtures.resolve(), *[Path(__file__).with_name(name).resolve() for name in ("replay_compare.py", "current_replay_schema.py", "enemy_qualification.py", "projectile_qualification.py", "pickup_qualification.py")]]
    if layout_path is not None:
        evaluators.append(layout_path)
    bindings = {"reference": file_sha(reference), "candidate": file_sha(candidate),
                "evaluators": {str(path): file_sha(path) for path in evaluators},
                "fixtures": {str(path): file_sha(path) for path in fixtures}}
    if layout_path is not None and bindings["evaluators"][str(layout_path)] != layout_sha:
        parser.error("Layout changed before cohort binding")
    write_json(args.output / "plan.json", {"bindings": bindings, "rounds": args.rounds,
               "timeoutSeconds": args.timeout, "maxSeconds": args.max_seconds, "runtimeThreads": 1,
               "cpuAffinity": sorted(os.sched_getaffinity(0)) if hasattr(os, "sched_getaffinity") else None,
               "order": "AB/BA alternating by fixture index plus round",
               "metric": "replay-summary.windowMs, lower is better", "argv": sys.argv})
    pairs = []
    deadline = time.monotonic() + args.max_seconds
    def interrupted(signum, frame):
        raise InterruptedError(f"Received signal {signum}")
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    def guard():
        paths = {**bindings["evaluators"], **bindings["fixtures"],
                 str(reference): bindings["reference"], str(candidate): bindings["candidate"]}
        for path, expected in paths.items():
            if file_sha(Path(path)) != expected:
                raise RuntimeError(f"Frozen input changed: {path}")
        if time.monotonic() >= deadline:
            raise TimeoutError("Overall cohort deadline reached")
    try:
        for round_index in range(args.rounds):
            for index, fixture in enumerate(fixtures):
                guard()
                order = ("reference", "candidate") if (index + round_index) % 2 == 0 else ("candidate", "reference")
                prefix = f"r{round_index:02d}-f{index:03d}"
                pair = {"round": round_index, "fixture": str(fixture),
                        "fixtureSha256": bindings["fixtures"][str(fixture)],
                        "order": f"{order[0]}-first"}
                outputs = {}
                for role in order:
                    binary = reference if role == "reference" else candidate
                    guard()
                    outputs[role] = args.output / f"{prefix}-{role}.jsonl"
                    pair[role] = run_sample(binary, fixture, outputs[role], min(args.timeout, deadline - time.monotonic()))
                    guard()
                pair["oracle"] = compare(outputs["reference"], outputs["candidate"], trace=fixture, layout=layout)
                if str(fixture) in expected and pair["oracle"]["semanticSha256"] != expected[str(fixture)]:
                    raise RuntimeError("Replay differs from frozen recorder observations")
                pairs.append(pair)
                with (args.output / "pairs.jsonl").open("a") as ledger:
                    ledger.write(json.dumps(pair, allow_nan=False) + "\n")
                print(f"Completed {prefix}: exact state matched", flush=True)
        guard()
        write_json(args.output / "summary.json", {"status": "completed", **analyze(pairs)})
    except BaseException as error:
        write_json(args.output / "terminal.json", {"status": "incomplete", "completedPairs": len(pairs),
                   "error": f"{type(error).__name__}: {error}"})
        raise
    write_json(args.output / "terminal.json", {"status": "completed", "completedPairs": len(pairs)})


if __name__ == "__main__":
    main()
