#!/usr/bin/env python3
"""Validate canonical enemy columns and project named enemy facts."""
import replay_compare as R
import current_replay_schema as M
from projectile_qualification import column


def phase(value):
    R.words(value, 2, 'enemy phase')
    if value[0] not in (0, 1, 2):
        raise R.ReplayError('Unknown enemy lifetime phase')


def state(value):
    if not isinstance(value, dict) or set(value) != {'spatial', 'archetype', 'identity', 'vitals', 'status'}:
        raise R.ReplayError('Incomplete typed enemy snapshot')
    R.words(value['spatial'], 4, 'enemy spatial bits')
    R.u32(value['archetype'], 'enemy archetype')
    R.u32(value['identity'], 'enemy identity')
    R.words(value['vitals'], 2, 'enemy vitals')
    R.words(value['status'], 2, 'enemy status')
    return value


def fact(value, role='EnemySlot', kind=0):
    state(value)
    x, y, age, radius = value['spatial']
    hp, maximum = value['vitals']
    return dict(xBits=x, yBits=y, kind=kind, variant=value['archetype'], age=age,
                seed=value['identity'], radiusBits=radius, role=role,
                health=hp, maximum=maximum,
                status=dict(zip(('slow', 'burn'), value['status'])))


def validate_and_project(components, metadata, layout):
    total = layout['totalCount']
    names = ('enemyPhases', 'vitals', 'statuses', 'spaces', 'bodies', 'roles', 'identities')
    columns = {name: column(components, name, total) for name in names}
    now = M.actual_tick(metadata['clock'][0], 'World clock')
    facts, seen = [], set()
    for index in range(total):
        identity = columns['identities'][index][1]
        R.u32(identity, 'issued slot identity')
        if identity >= total or identity in seen:
            raise R.ReplayError('Missing or duplicate issued slot identity')
        seen.add(identity)
        role = columns['roles'][index][1]
        if role != M.assigned(identity, layout):
            raise R.ReplayError('Enemy role disagrees with issued slot identity')
        enemy, pooled = role == 'EnemySlot', role in ('EnemySlot', 'RelicSlot')
        for name in names:
            present = (name in ('spaces', 'roles', 'identities') or
                       name == 'enemyPhases' and pooled or
                       name in ('vitals', 'statuses') and enemy)
            value, stamp = columns[name][index][1:]
            if (value is not None) != present:
                raise R.ReplayError(f'Wrong current {name} membership for {role}')
            M.stamp_valid(stamp, present, now)
        R.words(columns['spaces'][index][1], 4, 'canonical spatial bits')
        if not pooled:
            continue
        lifetime = columns['enemyPhases'][index][1]
        phase(lifetime)
        if role == 'RelicSlot':
            if lifetime[0] == 1:
                raise R.ReplayError('Relic slot became an active enemy')
            continue
        value = dict(spatial=columns['spaces'][index][1], archetype=lifetime[1],
                     identity=identity, vitals=columns['vitals'][index][1],
                     status=columns['statuses'][index][1])
        state(value)
        # Occupied slots are projected by the pickup handler, which owns loot.
        if lifetime[0] != 2:
            facts.append(fact(value, role, 0 if lifetime[0] == 1 else 8))
    return facts
