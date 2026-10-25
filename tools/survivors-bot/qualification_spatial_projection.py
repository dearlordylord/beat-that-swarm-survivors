#!/usr/bin/env python3
"""Temporary co-op qualification of explicit spatial ownership.

The player authority projection is explicit and reused. Only the newly added
spatial column is projected into the prior actor representation; all common
physical metadata, references, gameplay, frames and ordering stay exact.
"""
import argparse
import copy
import json
import math
from pathlib import Path
import sys
import qualification_player_projection as P

sys.setrecursionlimit(100000)
FIELDS = ('x', 'y', 'age', 'radius')
ENEMY_COUNT = 512
TOTAL_COUNT = 1456


def exact(value, tag, fields):
    P.payload(value, fields, tag)
    return value


def u32(value):
    assert type(value) is int and 0 <= value <= 0xffffffff
    return value


def tick(value):
    exact(value, 'Tick', ['epoch', 'low'])
    assert type(value['epoch']) is int and value['epoch'] >= 0
    return value['epoch'], u32(value['low'])


def column(value):
    exact(value, 'Indexed', ['state'])
    exact(value['state'], 'IndexedOrdinaryOwned', ['state'])
    return exact(value['state']['state'], 'IndexedOrdinaryState', ['values', 'metadata'])


def project(capture):
    result = P.project(capture, False)
    for row in result['rows']:
        world = row['physical']['world']
        store = world['store']
        spatial = column(store.pop('spaces'))
        bodies = column(store['bodies'])['values']
        roles = column(store['roles'])['values']
        assert len(bodies) >= TOTAL_COUNT and len(roles) >= TOTAL_COUNT
        values = spatial['values']
        metadata = exact(spatial['metadata'], 'Metadata',
                         ['added', 'changed', 'capacity', 'depth', 'exceptional'])
        assert metadata['capacity'] == len(values) == ENEMY_COUNT
        assert metadata['depth'] == 9 and metadata['exceptional'] == {'$': 'Nil'}
        assert len(metadata['added']) == len(metadata['changed']) == len(values)
        now = tick(world['clock']['now'])
        for index in range(TOTAL_COUNT):
            role = exact(roles[index], 'Some', ['value'])['value']
            expected = ('RelicSlot' if index == ENEMY_COUNT - 1 else 'EnemySlot') if index < ENEMY_COUNT else (
                'PlayerProjectileSlot' if index < 1024 else 'HostileProjectileSlot' if index < 1056 else 'XpSlot')
            assert role == {'$': expected}, 'Spatial membership must follow declared static roles'
            if index >= ENEMY_COUNT:
                continue
            space = exact(exact(values[index], 'Some', ['value'])['value'], 'Spatial', FIELDS)
            body = exact(bodies[index], 'Some', ['value'])['value']
            assert body['seed'] == index and [body[field] for field in FIELDS] == [0, 0, 0, 0], 'Duplicate spatial authority'
            u32(space['age'])
            for field in ('x', 'y', 'radius'):
                assert type(space[field]) in (float, int) and math.isfinite(space[field])
            added = tick(exact(metadata['added'][index], 'Some', ['value'])['value'])
            changed = tick(exact(metadata['changed'][index], 'Some', ['value'])['value'])
            assert added <= changed <= now, 'Invalid spatial lifecycle metadata'
            for field in FIELDS:
                body[field] = space[field]
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    reference = P.project(json.loads(args.baseline.read_text()), True)
    raw = json.loads(args.candidate.read_text())
    current = project(raw)
    P.compare(reference, current)
    # Mutate actual authoritative input before validation/projection.
    for name in ('spatial-age', 'duplicate-position', 'missing-member', 'future-stamp'):
        changed = copy.deepcopy(raw)
        world = changed['rows'][0]['physical']['world']
        store = world['store']
        spaces = store['spaces']['state']['state']
        if name == 'spatial-age':
            spaces['values'][0]['value']['age'] += 1
        elif name == 'duplicate-position':
            store['bodies']['state']['state']['values'][0]['value']['x'] = 1
        elif name == 'missing-member':
            spaces['values'][0] = {'$': 'None'}
        else:
            spaces['metadata']['changed'][0]['value']['low'] = world['clock']['now']['low'] + 1
        try:
            P.compare(reference, project(changed))
        except (AssertionError, ValueError):
            pass
        else:
            raise AssertionError('Undetected raw-source ' + name)
    receipt = dict(status='passed', checkpoints=len(current['rows']),
                   comparison='exact after explicit player partition and spatial ownership projection',
                   allCommonPhysicalMetadataCompared=True,
                   actualSpatialCompositionAndStampsValidated=True,
                   controls=['raw-source-spatial-age', 'duplicate-position', 'missing-member', 'future-stamp'])
    args.output.write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt))


if __name__ == '__main__':
    main()
