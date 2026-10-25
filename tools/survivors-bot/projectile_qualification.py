#!/usr/bin/env python3
"""Validate actual projectile columns and export the frozen named shot facts.

This is one part of the migration oracle, not a replacement for the complete
current-schema replay validator. Every caller must validate all other columns
and actual allocator/identity/order metadata independently as well.
"""
import replay_compare as R
import ecs_migration_compare as M

PROJECTILE_ROLES = {'PlayerProjectileSlot', 'HostileProjectileSlot'}

def column(components, name, total):
    rows = components.get(name)
    if not isinstance(rows, list) or len(rows) != total:
        raise R.ReplayError(f'Incomplete actual {name} column')
    for index, row in enumerate(rows, 1):
        if not isinstance(row, list) or len(row) != 3 or type(row[0]) is not int or row[0] != index:
            raise R.ReplayError(f'Noncanonical actual {name} column order')
    return rows

def payload(value):
    R.words(value, 3, 'projectile payload')
    if value[2] not in (0, 1):
        raise R.ReplayError('Projectile active flag must be Boolean')

def trajectory(value):
    if not isinstance(value, list) or len(value) != 7:
        raise R.ReplayError('Incomplete actual projectile trajectory')
    for i, word in enumerate(value):
        if i == 4:
            if not isinstance(word, list):
                raise R.ReplayError('Missing projectile visited-target history')
            for identity in word:
                R.u32(identity, 'visited target')
        else:
            R.u32(word, 'projectile trajectory word')

def state(value):
    if not isinstance(value, dict) or set(value) != {'spatial', 'identity', 'side', 'payload', 'trajectory'}:
        raise R.ReplayError('Incomplete typed projectile snapshot')
    R.words(value['spatial'], 4, 'projectile spatial bits')
    R.u32(value['identity'], 'projectile identity')
    if value['side'] not in ('player', 'hostile'):
        raise R.ReplayError('Unknown projectile side')
    payload(value['payload']); trajectory(value['trajectory'])
    return value

def fact(value, role):
    state(value)
    x, y, age, radius = value['spatial']
    weapon, damage, active = value['payload']
    return dict(xBits=x, yBits=y, kind=(7 if value['side'] == 'hostile' else 1) if active else 8,
                variant=weapon, age=age, seed=value['identity'], radiusBits=radius,
                role=role, damage=damage,
                trajectory=dict(zip(('vxBits', 'vyBits', 'life', 'pierce', 'visited', 'owner', 'logicalSlot'), value['trajectory'])))

def validate_and_project(components, metadata, layout):
    total = layout['totalCount']
    columns = {name: column(components, name, total)
               for name in ('shots', 'spaces', 'trajectories', 'bodies', 'roles', 'identities')}
    now = M.actual_tick(metadata['clock'][0], 'World clock')
    facts = []
    for index in range(total):
        shot = columns['shots'][index]
        expected_role = M.assigned(index, layout)
        role = columns['roles'][index][1]
        if role != expected_role:
            raise R.ReplayError('Projectile role/slot assignment changed')
        present = role in PROJECTILE_ROLES
        M.stamp_valid(shot[2], present, now)
        if not present:
            if shot[1] is not None:
                raise R.ReplayError('Non-projectile has a projectile payload')
            continue
        M.stamp_valid(columns['bodies'][index][2], False, now)
        if columns['bodies'][index][1] is not None:
            raise R.ReplayError('Projectile retains a second Body authority')
        identity = columns['identities'][index]
        if identity[1] != index or type(identity[1]) is not int:
            raise R.ReplayError('Actual projectile slot identity changed')
        for name in ('spaces', 'trajectories', 'identities'):
            M.stamp_valid(columns[name][index][2], True, now)
        snapshot = dict(spatial=columns['spaces'][index][1], identity=identity[1],
                        side='hostile' if role == 'HostileProjectileSlot' else 'player',
                        payload=shot[1], trajectory=columns['trajectories'][index][1])
        facts.append(fact(snapshot, role))
    return facts
