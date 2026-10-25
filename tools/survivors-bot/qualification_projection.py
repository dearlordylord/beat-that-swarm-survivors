#!/usr/bin/env python3
"""Temporary, explicit semantic oracle for the overloaded-state removal.

Only this baseline exporter knows the old representation. Candidate slices must
emit these same named facts from their authoritative components, validate their
own physical schema, and retain strict same-schema replay independently.
"""
import argparse
import copy
import json
from pathlib import Path
import ecs_migration_compare as M
import replay_compare as R

RUN_FIELDS = 'phase tick pxBits pyBits health maximum xp xpNeed level kills gold character weapons passives invulnerability seed stage arcana meta revivals bosses mode rerolls banishes skips bannedWeapons bannedPassives enemyKinds relicCollected'.split()
LAYOUT = dict(enemyCount=512, relicSeed=511, playerStart=512, hostileStart=1024, xpStart=1056, totalCount=1456)
EXCLUSIONS = [
    'Outer timing and replay-summary timing/digest records.',
    'World clock and component lifecycle stamps across schemas only: retained in raw captures and validated within each schema.',
    'Physical component partition, storage plumbing and prepared-roster representation across schemas only: raw captures retained and each schema independently validated.',
    'Redundant Body hp/maxHp copies where Vitals/Pickup are authoritative; meaningless hp/maxHp words for inactive/non-health kinds.',
    'Unused Motion fields for roles without the corresponding trajectory or status component.',
]

def actor(body):
    x, y, kind, variant, hp, maximum, age, seed, radius = body
    fact = dict(xBits=x, yBits=y, kind=kind, variant=variant, age=age, seed=seed, radiusBits=radius)
    if kind == 0:
        fact.update(health=hp, maximum=maximum)
    elif kind in (1, 7):
        fact.update(damage=hp)
    elif kind == 2:
        fact.update(amount=hp, generation=maximum)
    return fact

def snapshot(value):
    body, motion = value
    fact = actor(body)
    if body[2] in (1, 7):
        fact['trajectory'] = dict(zip(('vxBits', 'vyBits', 'life', 'pierce', 'visited', 'owner', 'logicalSlot'), motion[:5] + motion[7:]))
    elif body[2] == 0:
        fact['status'] = dict(slow=motion[5], burn=motion[6])
    return fact

def project(payload, tick):
    M.validate_payload(payload, tick, LAYOUT, migrated=True)
    c = payload['components']
    entities = []
    for i, (_, body, _) in enumerate(c['bodies']):
        fact = actor(body)
        role = c['roles'][i][1]
        fact['role'] = role
        if role in M.ENEMIES:
            fact['health'], fact['maximum'] = c['vitals'][i][1]
            fact['status'] = dict(zip(('slow', 'burn'), c['statuses'][i][1]))
        if role in M.PROJECTILES:
            fact['damage'] = body[4]
            fact['trajectory'] = dict(zip(('vxBits', 'vyBits', 'life', 'pierce', 'visited', 'owner', 'logicalSlot'), c['trajectories'][i][1]))
        if role == 'XpSlot':
            fact['pickup'] = dict(zip(('amount', 'generation', 'variant', 'active'), c['pickups'][i][1]))
            fact.pop('amount', None); fact.pop('generation', None)
        entities.append(fact)
    return dict(run=dict(zip(RUN_FIELDS, payload['run'])), entities=entities,
                visible=[actor(b) for b in payload['bodies']],
                snapshots=[snapshot(s) for s in payload['snapshots']],
                offers=payload['offers'], pending=payload['pending'],
                identity=dict(namespace=payload['metadata']['namespace'], allocator=payload['metadata']['allocator']))

def export(path):
    result = []
    for record in R.records(path):
        if record['type'] == 'replay-summary':
            continue
        row = R.semantic(record)
        if row['type'] == 'checkpoint':
            row['facts'] = project(row.pop('payload'), record['payload']['run'][1])
        result.append(row)
    if not result or result[0]['type'] != 'start' or result[-1]['type'] != 'summary':
        raise R.ReplayError('Incomplete qualification capture')
    return result

def compare(left, right):
    # No recursive exclusions, numeric tolerances, sorting or missing-field defaults.
    a = json.dumps(left, sort_keys=True, separators=(',', ':'), allow_nan=False)
    b = json.dumps(right, sort_keys=True, separators=(',', ':'), allow_nan=False)
    if a != b:
        raise R.ReplayError('Qualification facts differ: ' + R.first_difference(left, right))

def controls(path):
    raw = list(R.records(path))
    checkpoint = next(r for r in raw if r['type'] == 'checkpoint')
    original = checkpoint['payload']
    baseline = project(original, original['run'][1])
    compare(baseline, copy.deepcopy(baseline))
    for label in ('damage', 'xp', 'generation', 'status'):
        changed = copy.deepcopy(original)
        c = changed['components']
        if label == 'damage':
            index = next(i for i, row in enumerate(c['roles']) if row[1] in M.PROJECTILES)
            c['bodies'][index][1][4] += 1
        elif label == 'xp':
            changed['run'][6] += 1
        elif label == 'generation':
            index = next(i for i, row in enumerate(c['roles']) if row[1] == 'XpSlot')
            c['pickups'][index][1][1] += 1
            c['bodies'][index][1][5] += 1
        else:
            index = next(i for i, row in enumerate(c['roles']) if row[1] in M.ENEMIES)
            c['statuses'][index][1][0] += 1
            c['motions'][index][1][5] += 1
        projected = project(changed, changed['run'][1])
        try:
            compare(baseline, projected)
        except R.ReplayError:
            continue
        raise AssertionError('Undetected raw-source ' + label)
    # A storage-clock-only difference validates physically but is explicitly
    # excluded from cross-schema semantics. Ordinary replay still compares it.
    representation = copy.deepcopy(original)
    representation['metadata']['clock'][0][1] += 1
    compare(baseline, project(representation, original['run'][1]))
    return ['raw-source-damage', 'raw-source-xp', 'raw-source-generation', 'raw-source-status', 'representation-clock-positive']

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('capture', type=Path)
    p.add_argument('--output', required=True, type=Path)
    args = p.parse_args()
    facts = export(args.capture)
    args.output.write_text(json.dumps(facts, separators=(',', ':'), allow_nan=False) + '\n')
    print(json.dumps(dict(status='passed', controls=controls(args.capture), exclusions=EXCLUSIONS)))

if __name__ == '__main__':
    main()
