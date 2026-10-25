#!/usr/bin/env python3
"""Current Survivors typed ECS physical schema. No historical schema detection."""
import json
import math
import replay_compare as R
ReplayError = R.ReplayError
LAYOUT_KEYS = {'enemyCount', 'relicSeed', 'playerStart', 'hostileStart', 'xpStart', 'totalCount'}
DEFAULT_LAYOUT = dict(enemyCount=512,relicSeed=511,playerStart=512,hostileStart=1024,xpStart=1056,totalCount=1456)
ENEMIES = {'EnemySlot','RelicSlot'}
PROJECTILES = {'PlayerProjectileSlot','HostileProjectileSlot'}
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
    if capacity != 1 << depth or not (total == high < capacity and next_id == high + 1):
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
    if free:
        raise ReplayError('Fixed native pool unexpectedly has allocator free slots')
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


FAMILIES = {'bodies','vitals','trajectories','statuses','pickups','roles','spaces','shots','enemyPhases','identities'}
ROSTERS = {'movementCandidates','projectileCandidates','poolCandidates'}

def column(records,total,label):
    if len(sequence(records,label)) != total:
        raise ReplayError('Incomplete '+label+' column')
    for index,row in enumerate(records,1):
        if not isinstance(row,list) or len(row)!=3 or type(row[0]) is not int or row[0]!=index:
            raise ReplayError('Noncanonical '+label+' physical row order')
    return records

def validate_run(run,checkpoint_tick):
    if len(sequence(run,'Run')) != 29: raise ReplayError('Incomplete Run')
    for i,value in enumerate(run):
        if i in (12,13,27):
            for word in sequence(value,'Run list'): R.u32(word,'Run list word')
        else: R.u32(value,'Run word/F32 bits')
    if run[0]>4 or run[1]!=checkpoint_tick or len(run[12])!=24 or len(run[13])!=18:
        raise ReplayError('Run phase/tick/loadout shape')

def validate_payload(payload,checkpoint_tick,layout=None):
    import projectile_qualification as Shot
    import enemy_qualification as Enemy
    import pickup_qualification as Pickup
    layout = DEFAULT_LAYOUT if layout is None else layout
    validate_layout(layout)
    exact_keys(payload,R.PAYLOAD_KEYS,'payload')
    validate_run(payload['run'],checkpoint_tick)
    if payload['bodies'] != []: raise ReplayError('Untyped Body observations are forbidden')
    for offer in sequence(payload['offers'],'offers'): R.words(offer,3,'Offer')
    for reward in sequence(payload['pending'],'pending'):
        if R.u32(reward,'pending reward') not in (1,2): raise ReplayError('Invalid reward')
    now,live=validate_metadata(payload['metadata'],layout['totalCount'])
    envelope=payload['components'];exact_keys(envelope,{'actorColumns','players'},'component groups')
    c=envelope['actorColumns'];exact_keys(c,FAMILIES|ROSTERS,'actor components')
    high=payload['metadata']['allocator'][1]
    column(envelope['players'],high,'players')
    for _,value,stamp in envelope['players']:
        if value is not None: raise ReplayError('Native solo has unexpected ECS player authority')
        stamp_valid(stamp,False,now)
    total=layout['totalCount']
    for family in FAMILIES: column(c[family],total,family)
    identities={}; roles={}
    for offset,row in enumerate(c['identities']):
        physical,identity,_=row;R.u32(identity,'semantic slot identity')
        if identity>=total or identity in identities: raise ReplayError('Duplicate/outside semantic slot identity')
        identities[identity]=physical
        role=c['roles'][offset][1]
        if role!=assigned(identity,layout): raise ReplayError('Role differs from actual semantic slot identity')
        roles[physical]=role
        membership={'bodies':False,'vitals':role=='EnemySlot','statuses':role=='EnemySlot',
                    'trajectories':role in PROJECTILES,'shots':role in PROJECTILES,
                    'pickups':role in ENEMIES or role=='XpSlot','enemyPhases':role in ENEMIES,
                    'roles':True,'spaces':True,'identities':True}
        for family,present in membership.items():
            value,stamp=c[family][offset][1:]
            if (value is not None)!=present: raise ReplayError('Wrong sparse '+family+' membership')
            stamp_valid(stamp,present,now)
        R.words(c['spaces'][offset][1],4,'Spatial')
        if role=='EnemySlot':
            R.words(c['vitals'][offset][1],2,'Vitals');R.words(c['statuses'][offset][1],2,'Status')
        if role in ENEMIES:
            phase=c['enemyPhases'][offset][1];R.words(phase,2,'Enemy phase')
            if phase[0]>2: raise ReplayError('Unknown enemy phase')
        if role in PROJECTILES:
            Shot.payload(c['shots'][offset][1]);Shot.trajectory(c['trajectories'][offset][1])
            source=c['trajectories'][offset][1][7]
            if role=='HostileProjectileSlot' and source is not None: raise ReplayError('Hostile slot has player ownership')
            if role=='PlayerProjectileSlot' and c['shots'][offset][1][2] and source!=0: raise ReplayError('Active native projectile source is not the actual solo player')
        if membership['pickups']:
            value=c['pickups'][offset][1]
            if not isinstance(value,list) or len(value)!=3: raise ReplayError('Invalid Pickup payload')
            Pickup.item_fact(value[0]);R.u32(value[1],'Pickup generation');R.u32(value[2],'Pickup active')
            if value[2]>1: raise ReplayError('Unknown Pickup active flag')
    Enemy.validate_and_project(c,payload['metadata'],layout)
    Shot.validate_and_project(c,payload['metadata'],layout)
    Pickup.validate_and_project(c,payload['metadata'],layout)
    expected={name:[] for name in ROSTERS}
    for physical,generation in live:
        role=roles[physical];handle=[payload['metadata']['namespace'],physical,generation]
        if role in PROJECTILES: expected['projectileCandidates'].append(handle)
        if role in ENEMIES or role=='XpSlot': expected['poolCandidates'].append(handle)
        if role=='EnemySlot' and c['enemyPhases'][physical-1][1][0]==1: expected['movementCandidates'].append(handle)
    for name,value in expected.items():
        for handle in sequence(c[name],name): R.words(handle,3,'candidate handle')
        if c[name]!=value: raise ReplayError(name+' differs from actual issued membership/order')
    seen=set();snapshot_order=[]
    for snapshot in sequence(payload['snapshots'],'snapshots'):
        if not isinstance(snapshot,dict) or len(snapshot)!=1 or next(iter(snapshot)) not in ('enemy','projectile','pickup'):
            raise ReplayError('Unknown/missing typed Snapshot')
        kind,value=next(iter(snapshot.items()))
        keys={'spatial','identity'}|({'side','payload','trajectory'} if kind=='projectile' else {'archetype','vitals','status'} if kind=='enemy' else {'payload'})
        exact_keys(value,keys,'typed '+kind+' snapshot')
        if kind=='enemy': Enemy.state(value)
        if kind=='pickup':
            R.words(value['spatial'],4,'pickup snapshot spatial')
            Pickup.item_fact(value['payload'][0])
        identity=R.u32(value['identity'],'snapshot identity')
        if identity not in identities or identity in seen: raise ReplayError('Missing/duplicate snapshot identity')
        seen.add(identity);snapshot_order.append(identity);offset=identities[identity]-1;role=roles[offset+1]
        if value['spatial']!=c['spaces'][offset][1]: raise ReplayError('Snapshot/spatial authority incoherence')
        if kind=='projectile':
            Shot.state(value)
            if role not in PROJECTILES or value['side']!=('player' if role=='PlayerProjectileSlot' else 'hostile') or value['payload']!=c['shots'][offset][1] or value['trajectory']!=c['trajectories'][offset][1]: raise ReplayError('Snapshot/projectile authority incoherence')
        elif kind=='enemy':
            if role!='EnemySlot' or c['enemyPhases'][offset][1]!=[1,value['archetype']] or value['vitals']!=c['vitals'][offset][1] or value['status']!=c['statuses'][offset][1]: raise ReplayError('Snapshot/enemy authority incoherence')
        elif role not in ENEMIES|{'XpSlot'} or value['payload']!=c['pickups'][offset][1]: raise ReplayError('Snapshot/pickup authority incoherence')
    expected_snapshots=[]
    if checkpoint_tick:
        for physical,_ in reversed(live):
            role=roles[physical]
            if role=='XpSlot' or (role in ENEMIES and c['enemyPhases'][physical-1][1][0] in (1,2)):
                expected_snapshots.append(c['identities'][physical-1][1])
        for physical,_ in reversed(live):
            if roles[physical] in PROJECTILES: expected_snapshots.append(c['identities'][physical-1][1])
    if snapshot_order!=expected_snapshots: raise ReplayError('Typed snapshot coverage/order differs from actual issued cohorts')
    return payload
