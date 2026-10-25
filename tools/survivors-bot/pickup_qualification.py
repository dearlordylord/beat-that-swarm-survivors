"""Strict current-schema pickup authority checks and lossless named facts."""
import copy

PICKUP_ROLES = {'EnemySlot', 'RelicSlot', 'XpSlot'}


def require(condition, message):
    if not condition:
        raise ValueError('pickup authority: ' + message)


def word(value):
    return type(value) is int and 0 <= value <= 0xffffffff


def column(rows, name):
    result = {}
    for row in rows:
        require(type(row) is list and len(row) == 3, name + ' row shape')
        handle, value, _ = row
        require(word(handle) and handle not in result, name + ' duplicate/invalid handle')
        result[handle] = value
    return result


def item_fact(item):
    require(type(item) is list and item and word(item[0]), 'item tag')
    tag = item[0]
    sizes = {0: 3, 1: 2, 2: 2, 3: 1, 4: 2}
    require(tag in sizes and len(item) == sizes[tag] and all(word(v) for v in item), 'item shape')
    if tag == 0:
        require(item[2] in (0, 1), 'accumulator flag')
        return dict(kind='xp', amount=item[1], accumulator=bool(item[2]))
    if tag == 1:
        return dict(kind='gold', coins=item[1])
    if tag == 2:
        return dict(kind='healing', health=item[1])
    if tag == 3:
        return dict(kind='chest')
    return dict(kind='relic', stage=item[1])


def validate_and_project(c, metadata, layout):
    """Join physical rows by handle, then key facts by canonical Identity.slot.

    Generic world/column stamps, allocator, role and identity partitions are
    validated by the composed verifier. This handler never equates a handle's
    allocator index with the actor's semantic identity.
    """
    roles = column(c['roles'], 'roles')
    spaces = column(c['spaces'], 'spaces')
    identities = column(c['identities'], 'identities')
    phases = column(c['enemyPhases'], 'enemyPhases')
    pickups = column(c['pickups'], 'pickups')
    require(set(pickups) == set(roles), 'dense column handle membership')
    facts = {}
    for handle, payload in pickups.items():
        role = roles[handle]
        require((payload is not None) == (role in PICKUP_ROLES), 'payload role membership')
        if payload is None:
            continue
        require(type(payload) is list and len(payload) == 3, 'payload shape')
        item, generation, active = payload
        require(word(generation) and type(active) is int and active in (0, 1), 'generation/occupancy')
        item = item_fact(item)
        identity = identities[handle]
        require(word(identity) and identity not in facts, 'canonical identity')
        space = spaces[handle]
        require(type(space) is list and len(space) == 4 and all(word(v) for v in space), 'spatial shape')
        if role == 'XpSlot':
            require(item['kind'] == 'xp', 'XP pool payload kind')
            require(layout['xpStart'] <= identity < layout['totalCount'], 'XP pool identity range')
        elif active:
            require(item['kind'] != 'xp', 'non-XP slot has active XP')
            require(phases[handle][0] == 2, 'occupied loot phase')
            require((item['kind'] == 'relic') == (role == 'RelicSlot'), 'relic payload role')
        facts[identity] = dict(identity=identity, role=role, item=item,
                               generation=generation, active=bool(active),
                               spatial=dict(zip(('xBits','yBits','age','radiusBits'), space)))
    return facts


def controls(c, metadata, layout):
    """Mutate actual raw authority, never a projected fact or observation copy."""
    original = validate_and_project(c, metadata, layout)
    target = next(i for i, row in enumerate(c['pickups'])
                  if row[1] is not None and row[1][0][0] == 0
                  and column(c['roles'], 'roles')[row[0]] == 'XpSlot')
    for field in ('amount', 'generation', 'age', 'accumulator'):
        changed = copy.deepcopy(c)
        payload = changed['pickups'][target][1]
        if field == 'amount':
            payload[0][1] = (payload[0][1] + 1) & 0xffffffff
        elif field == 'generation':
            payload[1] = (payload[1] + 1) & 0xffffffff
        elif field == 'age':
            handle=changed['pickups'][target][0]
            space=next(row[1] for row in changed['spaces'] if row[0] == handle)
            space[2] = (space[2] + 1) & 0xffffffff
        else:
            payload[0][2] = 1 - payload[0][2]
        require(validate_and_project(changed, metadata, layout) != original,
                field + ' source mutation escaped projection')
    return ['pickup-amount', 'pickup-generation', 'pickup-age', 'pickup-accumulator']
