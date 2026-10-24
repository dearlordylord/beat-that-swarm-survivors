#!/usr/bin/env python3
"""Strict, explicit replay projection across the Survivors ECS schema migration."""
from __future__ import annotations
import argparse
import hashlib
import itertools
import json
import math
from pathlib import Path
import replay_compare as R

ReplayError = R.ReplayError
LAYOUT_KEYS = {'enemyCount', 'relicSeed', 'playerStart', 'hostileStart', 'xpStart', 'totalCount'}
OLD_COMPONENTS = {'bodies', 'vitals', 'motions'}
NEW_COMPONENTS = OLD_COMPONENTS | {'trajectories', 'statuses', 'roles', 'pickups', 'movementCandidates', 'projectileCandidates', 'poolCandidates'}
GAMEPLAY = ('run', 'bodies', 'offers', 'snapshots', 'pending')
ENEMIES = {'EnemySlot', 'RelicSlot'}
PROJECTILES = {'PlayerProjectileSlot', 'HostileProjectileSlot'}
EMPTY_MOTION = [0, 0, 0, 0, [], 0, 0, 0, 0]
EXCLUSIONS = [
    'Cross-schema absolute World clock and component lifecycle stamps are not compared; each observation is validated against its own clock.',
    'Removed non-enemy Vitals payloads are excluded. Enemy and relic Vitals remain bit-exact.',
    'Added Role, Trajectory, Status, Pickup and routing metadata have no old physical counterpart; their composition, logical coherence and issued-handle membership are independently validated.',
    'Only declared outer record timing fields and replay-summary timing/digest records are excluded from gameplay equality.',
]


def exact_keys(value, keys, label):
    if not isinstance(value, dict) or set(value) != set(keys):
        raise ReplayError(f'Unknown/missing {label} fields')


def sequence(value, label):
    if not isinstance(value, list):
        raise ReplayError(f'Invalid {label}: expected list')
    return value


def validate_layout(layout):
    exact_keys(layout, LAYOUT_KEYS, 'layout')
    for key, value in layout.items():
        R.u32(value, key)
    if not (0 <= layout['relicSeed'] < layout['enemyCount'] == layout['playerStart'] < layout['hostileStart'] < layout['xpStart'] < layout['totalCount']):
        raise ReplayError('Invalid ordered pool layout')
    return layout


def assigned(seed, layout):
    if seed == layout['relicSeed']:
        return 'RelicSlot'
    if seed < layout['enemyCount']:
        return 'EnemySlot'
    if seed < layout['hostileStart']:
        return 'PlayerProjectileSlot'
    if seed < layout['xpStart']:
        return 'HostileProjectileSlot'
    if seed < layout['totalCount']:
        return 'XpSlot'
    return 'OutsideSlot'


def actual_tick(value, label):
    if value is None:
        raise ReplayError(f'Missing {label}')
    R.tick(value)
    return tuple(value)


def stamp_valid(stamp, present, now):
    if not isinstance(stamp, list) or len(stamp) != 2:
        raise ReplayError('Invalid actual lifecycle stamp')
    for value in stamp:
        R.tick(value)
    if not present:
        if stamp != [None, None]:
            raise ReplayError('Absent sparse component has lifecycle stamps')
    else:
        added, changed = (actual_tick(value, 'present component stamp') for value in stamp)
        if not added <= changed <= now:
            raise ReplayError('Lifecycle stamp order/future tick')


def validate_metadata(metadata, total):
    exact_keys(metadata, {'namespace', 'allocator', 'clock', 'events', 'pendingCommands', 'registrations', 'nextSystemId'}, 'metadata')
    R.u32(metadata['namespace'], 'namespace'); R.u32(metadata['nextSystemId'], 'nextSystemId')
    for key in ('events', 'pendingCommands'):
        if type(metadata[key]) is not int or metadata[key] != 0:
            raise ReplayError(f'Unsupported fixed-game {key}')
    if metadata['registrations'] != []:
        raise ReplayError('Unsupported registrations')
    clock = sequence(metadata['clock'], 'clock')
    if len(clock) != 2 or clock[1] != []:
        raise ReplayError('Invalid/unclosed World clock scope')
    now = actual_tick(clock[0], 'World clock')
    allocator = sequence(metadata['allocator'], 'allocator')
    if len(allocator) != 7:
        raise ReplayError('Invalid allocator')
    for value in allocator[:4]:
        R.integer(value, 'allocator scalar')
    next_id, high, capacity, depth, free, order, slots = allocator
    if not (total <= high < capacity and 1 <= next_id <= capacity):
        raise ReplayError('Allocator capacity/high/next bounds')
    if len(sequence(slots, 'allocator slots')) != capacity:
        raise ReplayError('Allocator capacity mismatch')
    for slot in slots:
        R.words(slot, 2, 'allocator slot')
        if slot[1] > 4:
            raise ReplayError('Unknown allocator phase')
    for index in sequence(free, 'free indices'):
        R.u32(index, 'free index')
        if not 1 <= index <= high or slots[index][1] != 4:
            raise ReplayError('Invalid free index')
    if len(set(free)) != len(free):
        raise ReplayError('Duplicate free index')
    seen = set()
    for key in sequence(order, 'issued order'):
        R.words(key, 2, 'issued entity key')
        index, generation = key
        if index in seen or not 1 <= index <= high or slots[index][0] != generation:
            raise ReplayError('Duplicate/stale/invalid issued key')
        seen.add(index)
    # This observer qualifies the preallocated fixed-world game, not structural
    # destruction or reservation. Every game identity must be an issued live key.
    live = [[index, generation] for index, generation in order if slots[index][1] == 2]
    if {key[0] for key in live} != set(range(1, total + 1)):
        raise ReplayError('Missing/extra issued live game identities')
    return now, live


def validate_gameplay(payload, checkpoint_tick):
    exact_keys(payload, R.PAYLOAD_KEYS, 'payload')
    run = sequence(payload['run'], 'Run')
    if len(run) != 29:
        raise ReplayError('Incomplete Run')
    for index, value in enumerate(run):
        if index in (12, 13, 27):
            for word in sequence(value, 'Run list'):
                R.u32(word, 'Run list word')
        else:
            R.u32(value, 'Run word/F32 bits')
    if run[0] > 4 or run[1] != checkpoint_tick or len(run[12]) != 24 or len(run[13]) != 18:
        raise ReplayError('Run phase/tick/loadout shape')
    for body in sequence(payload['bodies'], 'bodies'):
        R.words(body, 9, 'Body')
    for offer in sequence(payload['offers'], 'offers'):
        R.words(offer, 3, 'Offer')
    for snap in sequence(payload['snapshots'], 'snapshots'):
        if not isinstance(snap, list) or len(snap) != 2:
            raise ReplayError('Invalid Snapshot')
        R.words(snap[0], 9, 'Snapshot Body'); R.validate_motion(snap[1])
    for reward in sequence(payload['pending'], 'pending'):
        if R.u32(reward, 'pending reward') not in (1, 2):
            raise ReplayError('Invalid reward')


def rows(records, total, label):
    if len(sequence(records, label)) != total:
        raise ReplayError(f'Incomplete {label} slots')
    for index, row in enumerate(records, 1):
        if not isinstance(row, list) or len(row) != 3 or type(row[0]) is not int or row[0] != index:
            raise ReplayError(f'Noncanonical {label} row order')
    return records


def validate_payload(payload, checkpoint_tick, layout, migrated):
    validate_gameplay(payload, checkpoint_tick)
    total = layout['totalCount']
    now, live = validate_metadata(payload['metadata'], total)
    components = payload['components']
    exact_keys(components, NEW_COMPONENTS if migrated else OLD_COMPONENTS, 'components')
    families = ('bodies', 'vitals', 'motions', 'trajectories', 'statuses', 'roles', 'pickups') if migrated else ('bodies', 'vitals', 'motions')
    for family in families:
        rows(components[family], total, family)
    roles = [assigned(seed, layout) for seed in range(total)]
    for offset, role in enumerate(roles):
        for family in families:
            _, value, stamp = components[family][offset]
            present = (family in ('bodies', 'motions', 'roles') or
                       family in ('vitals', 'statuses') and role in ENEMIES or
                       family == 'trajectories' and role in PROJECTILES or
                       family == 'pickups' and role == 'XpSlot') if migrated else True
            if (value is not None) != present:
                raise ReplayError(f'Wrong sparse {family} composition at {offset + 1}')
            if migrated and family == 'motions':
                if stamp is not None:
                    raise ReplayError('Derived logical Motion must not invent a stamp')
            else:
                stamp_valid(stamp, present, now)
            if not present:
                continue
            if family == 'motions':
                R.validate_motion(value)
            elif family == 'roles':
                if type(value) is not str or value != role:
                    raise ReplayError('Role differs from source layout')
            elif family == 'pickups':
                R.words(value, 4, 'Pickup')
                if value[3] not in (0, 1):
                    raise ReplayError('Invalid Pickup active bit')
                body = components['bodies'][offset][1]
                if [body[4], body[5], body[3], int(body[2] == 2)] != value or body[2] not in (2, 8):
                    raise ReplayError('Authoritative Pickup/Body view incoherence')
            elif family == 'trajectories':
                if not isinstance(value, list) or len(value) != 7 or not isinstance(value[4], list):
                    raise ReplayError('Invalid Trajectory')
                R.validate_motion(value[:5] + [0, 0] + value[5:])
            else:
                R.words(value, 9 if family == 'bodies' else 2, family)
            if family == 'bodies' and value[7] != offset:
                raise ReplayError('Authoritative Body identity changed')
        if migrated:
            trajectory = components['trajectories'][offset][1] or [0, 0, 0, 0, [], 0, 0]
            status = components['statuses'][offset][1] or [0, 0]
            if components['motions'][offset][1] != trajectory[:5] + status + trajectory[5:]:
                raise ReplayError('Physical/logical Motion incoherence')
    if migrated:
        expected = {'movementCandidates': [], 'projectileCandidates': [], 'poolCandidates': []}
        namespace = payload['metadata']['namespace']
        for index, generation in live:
            role = roles[index - 1]
            handle = [namespace, index, generation]
            if role in ENEMIES and components['bodies'][index - 1][1][2] == 0:
                expected['movementCandidates'].append(handle)
            if role in PROJECTILES:
                expected['projectileCandidates'].append(handle)
            if role in ENEMIES or role == 'XpSlot':
                expected['poolCandidates'].append(handle)
        for name, handles in expected.items():
            observed = components[name]
            sequence(observed, name)
            for handle in observed:
                R.words(handle, 3, 'candidate handle')
            if observed != handles:
                raise ReplayError(f'{name} differs from issued membership/order')
    return {**{key: payload[key] for key in GAMEPLAY},
            'authoritativeBodies': [row[1] for row in components['bodies']],
            'enemyVitals': [components['vitals'][offset][1] for offset, role in enumerate(roles) if role in ENEMIES],
            'logicalMotions': [row[1] for row in components['motions']],
            'metadata': {key: value for key, value in payload['metadata'].items() if key != 'clock'}}


RECORD_KEYS = {
    'start': {'type', 'schemaVersion', 'fixture', 'seed', 'profile', 'warmup', 'endTick'},
    'checkpoint': {'type', 'fixture', 'step', 'payload'},
    'summary': {'type', 'fixture', 'actions', 'firstTick', 'endTick', 'phase'},
    'replay-summary': {'type', 'fixture', 'windowMs', 'windowActions', 'firstTick', 'endTick', 'phase', 'stateDigest32'},
}


def strict_records(path, max_bytes):
    # R.records provides bounded JSONL reading, duplicate-key/nonfinite checks,
    # complete line checking and timing-record placement validation.
    # Preflight root schemas too, including timing records R.records excludes.
    if path.stat().st_size > max_bytes:
        raise ReplayError('Replay exceeds byte bound')
    with path.open(encoding='utf-8') as source:
        for line in source:
            row = json.loads(line, object_pairs_hook=R._pairs, parse_constant=R._constant)
            if not isinstance(row, dict) or row.get('type') not in RECORD_KEYS:
                raise ReplayError('Unknown replay record')
            kind = row['type']; required = RECORD_KEYS[kind]
            allowed = required | R.TIMING_FIELDS | ({'tick'} if kind == 'checkpoint' else set())
            if not required <= set(row) <= allowed:
                raise ReplayError('Unknown/missing replay record fields')
            if type(row['fixture']) is not str or not row['fixture']:
                raise ReplayError('Invalid fixture identity')
            for name in set(row) - {'type', 'fixture', 'payload'} - R.TIMING_FIELDS:
                R.u32(row[name], 'record ' + name)
            for name in set(row) & R.TIMING_FIELDS:
                if type(row[name]) not in (int, float) or row[name] < 0 or not math.isfinite(row[name]):
                    raise ReplayError('Invalid record timing')
            if kind == 'replay-summary':
                for name in ('windowActions', 'firstTick', 'endTick', 'phase', 'stateDigest32'):
                    R.u32(row[name], name)
    yield from R.records(path, max_bytes)


def compare(baseline, candidate, *, layout, trace, minimum_checkpoints=2, max_bytes=1024**3):
    validate_layout(layout)
    if minimum_checkpoints < 2:
        raise ReplayError('At least two checkpoints required')
    contract = R.trace_contract(trace)
    seen_start = False; seen_summary = False; count = 0; last_step = -1; last_tick = -1
    chain = hashlib.sha256(); sentinel = object(); previous_clocks = [None, None]
    for position, pair in enumerate(itertools.zip_longest(strict_records(baseline, max_bytes), strict_records(candidate, max_bytes), fillvalue=sentinel), 1):
        left, right = pair
        if left is sentinel or right is sentinel:
            raise ReplayError('Record count mismatch')
        if seen_summary or left['type'] != right['type']:
            raise ReplayError('Record kind/order mismatch')
        kind = left['type']
        a = R.semantic(left); b = R.semantic(right)
        if kind == 'start':
            if seen_start or position != 1 or left['schemaVersion'] != 1 or type(left['schemaVersion']) is not int:
                raise ReplayError('Invalid replay start')
            if any(left[key] != contract[key] for key in ('fixture', 'seed', 'profile', 'warmup', 'endTick')):
                raise ReplayError('Start does not bind supplied trace')
            seen_start = True
        elif not seen_start or left['fixture'] != contract['fixture']:
            raise ReplayError('Fixture/start mismatch')
        elif kind == 'checkpoint':
            step = R.integer(left['step'], 'checkpoint step')
            observed_tick = left['payload'].get('run', [None, None])[1] if isinstance(left['payload'], dict) else None
            current_tick = R.u32(left.get('tick', observed_tick), 'checkpoint tick')
            if step <= last_step or current_tick < last_tick:
                raise ReplayError('Checkpoint order regressed/repeated')
            a['payload'] = validate_payload(left['payload'], current_tick, layout, False)
            b['payload'] = validate_payload(right['payload'], current_tick, layout, True)
            for side, record in enumerate((left, right)):
                observed_clock = actual_tick(record['payload']['metadata']['clock'][0], 'World clock')
                if previous_clocks[side] is not None and observed_clock < previous_clocks[side]:
                    raise ReplayError('World clock regressed across checkpoints')
                previous_clocks[side] = observed_clock
            last_step, last_tick = step, current_tick; count += 1
        elif kind == 'summary':
            if count < minimum_checkpoints or any(left[key] != contract[other] for key, other in [('actions', 'actions'), ('endTick', 'actualEnd'), ('phase', 'phase'), ('firstTick', 'warmup')]) or last_step != contract['actions'] or last_tick != contract['actualEnd']:
                raise ReplayError('Summary/checkpoints do not bind supplied trace')
            seen_summary = True
        difference = R.first_difference(a, b)
        if difference:
            raise ReplayError(f'Migration gameplay mismatch at record {position}: {difference}')
        encoded = json.dumps(a, sort_keys=True, separators=(',', ':'), allow_nan=False).encode()
        chain.update(len(encoded).to_bytes(8, 'big')); chain.update(encoded)
    if not seen_start or not seen_summary:
        raise ReplayError('Incomplete replay')
    return {'status': 'passed', 'comparison': 'explicit-ecs-schema-migration', 'fixture': contract['fixture'], 'checkpoints': count,
            'semanticSha256': chain.hexdigest(), 'baselineSha256': R.file_sha(baseline), 'candidateSha256': R.file_sha(candidate),
            'traceSha256': R.file_sha(trace), 'layout': layout,
            'scope': 'Bit-exact Run, frame bodies, offers, snapshots, pending rewards, authoritative Body payloads, enemy/relic Vitals and all logical Motion payloads; non-clock World metadata exact.',
            'exclusions': EXCLUSIONS}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline', type=Path); parser.add_argument('candidate', type=Path)
    parser.add_argument('--trace', type=Path, required=True); parser.add_argument('--layout', type=Path, required=True)
    parser.add_argument('--receipt', type=Path, required=True)
    args = parser.parse_args()
    try:
        layout = json.loads(args.layout.read_text(), object_pairs_hook=R._pairs, parse_constant=R._constant)
        result = compare(args.baseline, args.candidate, layout=layout, trace=args.trace)
        result['layoutSha256'] = R.file_sha(args.layout)
    except (ValueError, OSError, TypeError, IndexError, KeyError) as error:
        result = {'status': 'failed', 'error': str(error), 'comparison': 'explicit-ecs-schema-migration', 'exclusions': EXCLUSIONS}
    args.receipt.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))
    return 0 if result['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
