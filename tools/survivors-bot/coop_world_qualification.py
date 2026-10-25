"""Current-only full co-op World reader and physical qualification.

Read the pinned Bend indexed-column ABI explicitly. A physical array offset is
an allocator handle index, never an actor's semantic Identity.slot. Every actual
allocated entry/stamp is checked, including entries outside the pooled range.
"""
import math
import struct
import replay_compare as R
import current_replay_schema as C
import qualification_coop_players as P
import typed_qualification as T

def data(value,ctor,fields):
    C.exact_keys(value,{'$',*fields},ctor)
    if value['$']!=ctor:raise R.ReplayError('Expected '+ctor+' constructor')
    return value

def number(value):return R.u32(value,'Bend U32')
def boolean(value):
    if type(value) is not bool:raise R.ReplayError('Expected Bend Bool')
    return int(value)
def bits(value):
    if type(value) not in (int,float) or not math.isfinite(value):raise R.ReplayError('Invalid serialized F32')
    packed=struct.pack('>f',value)
    if struct.unpack('>f',packed)[0]!=value:raise R.ReplayError('Number is not an exact F32')
    return struct.unpack('>I',packed)[0]
def optional(value,convert):
    if value=={'$':'None'}:return None
    data(value,'Some',{'value'});return convert(value['value'])
def spatial(v):
    data(v,'Spatial',{'x','y','age','radius'})
    return [bits(v['x']),bits(v['y']),number(v['age']),bits(v['radius'])]
def vitals(v):
    data(v,'Vitals',{'health','maximum'});return [number(v['health']),number(v['maximum'])]
def trajectory(v):
    data(v,'Trajectory',{'vx','vy','life','pierce','visited','weaponOwner','logicalSlot','sourcePlayer'})
    return [bits(v['vx']),bits(v['vy']),number(v['life']),number(v['pierce']),[number(w) for w in P.array(v['visited'])],number(v['weaponOwner']),number(v['logicalSlot']),optional(v['sourcePlayer'],number)]
def status(v):
    data(v,'Status',{'slow','burn'});slow=v['slow'];burn=v['burn']
    data(slow,'Slow',{'ticks','frozen'});data(burn,'Burn',{'ticks','sourcePlayer'})
    return dict(slow=dict(ticks=number(slow['ticks']),frozen=bool(boolean(slow['frozen']))),burn=dict(ticks=number(burn['ticks']),sourcePlayer=optional(burn['sourcePlayer'],number)))
def item(v):
    tag=v.get('$')
    if tag=='Xp':
        data(v,'Xp',{'amount','accumulator'});return [0,number(v['amount']),boolean(v['accumulator'])]
    if tag=='Gold':data(v,'Gold',{'coins'});return [1,number(v['coins'])]
    if tag=='Healing':data(v,'Healing',{'health'});return [2,number(v['health'])]
    if tag=='Chest':data(v,'Chest',set());return [3]
    if tag=='Relic':data(v,'Relic',{'stage'});return [4,number(v['stage'])]
    raise R.ReplayError('Unknown current Pickup item')
def pickup(v):
    data(v,'Payload',{'item','generation','active'});return [item(v['item']),number(v['generation']),boolean(v['active'])]
def phase(v):
    if v.get('$') not in ('Dormant','ActiveEnemy','OccupiedByLoot'):raise R.ReplayError('Unknown enemy phase')
    C.exact_keys(v,{'$','archetype'},'enemy phase')
    return [('Dormant','ActiveEnemy','OccupiedByLoot').index(v['$']),number(v['archetype'])]
def role(v):
    if v not in [{'$':name} for name in ('EnemySlot','RelicSlot','PlayerProjectileSlot','HostileProjectileSlot','XpSlot')]:raise R.ReplayError('Unknown pooled Role')
    return v['$']
def identity(v):data(v,'Identity',{'slot'});return number(v['slot'])
def shot(v):data(v,'ShotPayload',{'weapon','damage','active'});return [number(v['weapon']),number(v['damage']),boolean(v['active'])]
def personal(v):
    data(v,'PlayerState',set(P.PLAYER_FIELDS));out=[]
    for key in P.PLAYER_FIELDS:
        value=v[key]
        out.append(bits(value) if key in ('px','py') else [number(w) for w in P.array(value)] if key in ('weapons','passives') else number(value))
    return out
def player(v):data(v,'PlayerRecord',{'id','player','connected'});return [number(v['id']),personal(v['player']),boolean(v['connected'])]
def absent(v):raise R.ReplayError('Removed Body authority is present')

def column(value,convert,count,now):
    data(value,'Indexed',{'state'});owned=data(value['state'],'IndexedOrdinaryOwned',{'state'})
    state=data(owned['state'],'IndexedOrdinaryState',{'values','metadata'})
    meta=data(state['metadata'],'Metadata',{'added','changed','capacity','depth','exceptional'})
    capacity=number(meta['capacity']);depth=number(meta['depth'])
    if depth>31 or capacity!=1<<depth or P.array(meta['exceptional']):raise R.ReplayError('Invalid indexed column metadata')
    arrays=(state['values'],meta['added'],meta['changed'])
    if any(type(a) is not list or len(a)!=capacity for a in arrays):raise R.ReplayError('Incomplete actual indexed column')
    rows=[]
    for i,(entry,added,changed) in enumerate(zip(*arrays),1):
        value=optional(entry,convert);stamp=[P.maybe_time(added),P.maybe_time(changed)]
        C.stamp_valid(stamp,value is not None,now)
        if i>count and (value is not None or stamp!=[None,None]):raise R.ReplayError('Unissued/outside-scope component authority')
        if i<=count:rows.append([i,value,stamp])
    # Col.observe for a missing indexed address is absent with no lifecycle
    # stamp. This reads the column ABI; it does not synthesize gameplay values.
    rows.extend([i,None,[None,None]] for i in range(capacity+1,count+1))
    return rows

def key(v):data(v,'EntityKey',{'index','generation'});return [number(v['index']),number(v['generation'])]
def handle(v):data(v,'Handle',{'namespace','key'});return [number(v['namespace']),*key(v['key'])]
def metadata(world):
    data(world,'World',{'namespace','allocator','store','resource','events','pending','registrations','nextSystemId','clock'})
    if world['resource']!={'$':'Unit'} or any(P.array(world[k]) for k in ('events','pending','registrations')):raise R.ReplayError('Unsupported World resources/events/commands/registrations')
    a=data(world['allocator'],'Allocator',{'next','high','slots','capacity','depth','free','order'})
    slots=[]
    tags=('Consumed','Pending','Live','DeadRetained','Free')
    for v in a['slots']:
        data(v,'Slot',{'generation','phase'})
        if v['phase'] not in [{'$':name} for name in tags]:raise R.ReplayError('Unknown allocator phase')
        slots.append([number(v['generation']),tags.index(v['phase']['$'])])
    clock=data(world['clock'],'State',{'now','scopes'})
    return dict(namespace=number(world['namespace']),allocator=[number(a['next']),number(a['high']),number(a['capacity']),number(a['depth']),[number(w) for w in P.array(a['free'])],[key(k) for k in P.array(a['order'])],slots],clock=[P.time(clock['now']),[P.time(t) for t in P.array(clock['scopes'])]],events=0,pendingCommands=0,registrations=[],nextSystemId=number(world['nextSystemId']))

def snapshot(v):
    tag=v.get('$')
    if tag=='EnemySnapshot':
        data(v,tag,{'enemy'});s=data(v['enemy'],'State',{'spatial','archetype','identity','vitals','status'})
        return dict(enemy=dict(spatial=spatial(s['spatial']),archetype=number(s['archetype']),identity=number(s['identity']),vitals=vitals(s['vitals']),status=status(s['status'])))
    if tag=='ProjectileSnapshot':
        data(v,tag,{'projectile'});s=data(v['projectile'],'State',{'spatial','identity','side','payload','trajectory'})
        if s['side'] not in ({'$':'PlayerShot'},{'$':'HostileShot'}):raise R.ReplayError('Unknown projectile side')
        return dict(projectile=dict(spatial=spatial(s['spatial']),identity=number(s['identity']),side='player' if s['side']['$']=='PlayerShot' else 'hostile',payload=shot(s['payload']),trajectory=trajectory(s['trajectory'])))
    if tag=='PickupSnapshot':
        data(v,tag,{'pickup'});s=data(v['pickup'],'State',{'spatial','payload','identity'})
        return dict(pickup=dict(spatial=spatial(s['spatial']),payload=pickup(s['payload']),identity=number(s['identity'])))
    raise R.ReplayError('Unknown current Snapshot constructor')

def extract(row):
    P.validate_row(row)
    core=data(row['physical'],'CoreState',{'world','shared','refs','bodies','snapshots','round','required','offers','pending'})
    if core['shared']!=row['shared'] or P.array(core['refs'])!=row['refs'] or P.array(core['bodies']):raise R.ReplayError('Actual Core observations/refs incoherent or Body transport remains')
    world=core['world'];m=metadata(world);now=tuple(m['clock'][0]);total=C.DEFAULT_LAYOUT['totalCount']
    store=data(world['store'],'Store',{'bodies','vitals','motions','statuses','pickups','roles','movement','candidates','players','spaces','enemyPhases','identities','shots'})
    converters=dict(bodies=absent,vitals=vitals,motions=trajectory,statuses=status,pickups=pickup,roles=role,spaces=spatial,enemyPhases=phase,identities=identity,shots=shot)
    c={('trajectories' if name=='motions' else name):column(store[name],convert,total,now) for name,convert in converters.items()}
    movement=store['movement'];candidates=store['candidates']
    if movement=={'$':'MovementCold'}:c['movementCandidates']=[]
    else:data(movement,'MovementPrepared',{'handles'});c['movementCandidates']=[handle(v) for v in P.array(movement['handles'])]
    if candidates=={'$':'CandidatesCold'}:c['projectileCandidates']=[];c['poolCandidates']=[]
    else:data(candidates,'CandidatesPrepared',{'projectiles','pool'});c['projectileCandidates']=[handle(v) for v in P.array(candidates['projectiles'])];c['poolCandidates']=[handle(v) for v in P.array(candidates['pool'])]
    players=column(store['players'],player,m['allocator'][1],now)
    refs={ref['handle']['key']['index']:(ref['id'],ref['handle']['key']['generation']) for ref in row['refs']}
    snaps=[snapshot(s) for s in P.array(core['snapshots'])]
    envelope=dict(actorColumns=c,players=players)
    C.validate_pool(envelope,m,snaps,row['tick'],player_refs=refs)
    return dict(components=envelope,metadata=m,snapshots=snaps),refs

def progress(core):
    offers=[]
    for v in P.array(core['offers']):
        data(v,'PlayerOffers',{'id','offers'});rows=[]
        for offer in P.array(v['offers']):
            data(offer,'Offer',{'kind','id','level'});rows.append([number(offer['kind']),number(offer['id']),number(offer['level'])])
        offers.append(dict(id=number(v['id']),offers=rows))
    pending=[]
    for v in P.array(core['pending']):
        data(v,'Reward',{'kind','collector'});pending.append(dict(kind=number(v['kind']),collector=number(v['collector'])))
    return dict(round=number(core['round']),required=[number(v) for v in P.array(core['required'])],offers=offers,pending=pending)

def facts(row):
    payload,refs=extract(row)
    es,snapshots=T.snapshot_facts(payload)
    pool=T.canonical(dict(entities=es,snapshots=snapshots,visible=[],lootItems=T.loot_items(payload),identity=dict(namespace=payload['metadata']['namespace'],allocator=payload['metadata']['allocator'])))
    c=payload['components']['actorColumns']
    pool['phases']=sorted([dict(identity=identity,phase=phase[0],archetype=phase[1]) for (_,identity,_),(_,phase,_) in zip(c['identities'],c['enemyPhases']) if phase is not None],key=lambda value:value['identity'])
    return dict(players=P.validate_row(row),pool=pool,progress=progress(row['physical']))

def controls(row):
    """Change actual raw component values and coherent cached observations."""
    import copy
    original=facts(row)
    def raw(store,name):return store[name]['state']['state']['values']
    actual=row['physical']['world']['store']
    shots=raw(actual,'shots');motions=raw(actual,'motions');pickups=raw(actual,'pickups');phases=raw(actual,'enemyPhases')
    shot_index=next(i for i,v in enumerate(shots) if v['$']=='Some' and v['value']['active'] and motions[i]['value']['sourcePlayer']=={'$':'Some','value':1})
    xp_index=next(i for i,v in enumerate(pickups) if v['$']=='Some' and v['value']['active'] and v['value']['item']['$']=='Xp')
    loot_index=next(i for i,v in enumerate(pickups) if v['$']=='Some' and v['value']['active'] and v['value']['item']['$']=='Gold')
    enemy_index=next(i for i,v in enumerate(phases) if v['$']=='Some' and v['value']['$']=='ActiveEnemy')
    for label in ('damage','xp','generation','status','identity','source-player','pickup-age','pickup-accumulator','loot-amount','future-stamp','routing-order'):
        changed=copy.deepcopy(row);core=changed['physical'];store=core['world']['store']
        if label=='xp':
            core['shared']['xp']=(core['shared']['xp']+1)&0xffffffff;changed['shared']['xp']=core['shared']['xp']
        elif label=='identity':
            first=shot_index;second=next(i for i,v in enumerate(raw(store,'shots')) if i!=first and v['$']=='Some')
            values=raw(store,'identities');a=values[first]['value']['slot'];b=values[second]['value']['slot']
            values[first]['value']['slot'],values[second]['value']['slot']=b,a
            for s in P.array(core['snapshots']):
                value=s.get('projectile',s.get('enemy',s.get('pickup')))
                if value['identity']==a:value['identity']=b
                elif value['identity']==b:value['identity']=a
        elif label=='future-stamp':
            store['shots']['state']['state']['metadata']['changed'][shot_index]['value']['epoch']+=1
        elif label=='routing-order':
            rows=P.array(store['candidates']['projectiles']);rows.reverse()
            tail={'$':'Nil'}
            for value in reversed(rows):tail={'$':'Con','head':value,'tail':tail}
            store['candidates']['projectiles']=tail
        else:
            index=loot_index if label=='loot-amount' else enemy_index if label=='status' else xp_index if label in ('generation','pickup-age','pickup-accumulator') else shot_index
            if label=='damage':raw(store,'shots')[index]['value']['damage']+=1
            elif label=='loot-amount':raw(store,'pickups')[index]['value']['item']['coins']+=1
            elif label=='generation':raw(store,'pickups')[index]['value']['generation']+=1
            elif label=='status':raw(store,'statuses')[index]['value']['slow']['ticks']+=1
            elif label=='source-player':raw(store,'motions')[index]['value']['sourcePlayer']={'$':'Some','value':0}
            elif label=='pickup-age':raw(store,'spaces')[index]['value']['age']+=1
            elif label=='pickup-accumulator':raw(store,'pickups')[index]['value']['item']['accumulator']=not raw(store,'pickups')[index]['value']['item']['accumulator']
            identity=raw(store,'identities')[index]['value']['slot']
            for s in P.array(core['snapshots']):
                value=s.get('projectile',s.get('enemy',s.get('pickup')))
                if value['identity']!=identity:continue
                if label=='damage':value['payload']=copy.deepcopy(raw(store,'shots')[index]['value'])
                elif label in ('generation','pickup-accumulator','loot-amount'):value['payload']=copy.deepcopy(raw(store,'pickups')[index]['value'])
                elif label=='status':value['status']=copy.deepcopy(raw(store,'statuses')[index]['value'])
                elif label=='source-player':value['trajectory']=copy.deepcopy(raw(store,'motions')[index]['value'])
                else:value['spatial']=copy.deepcopy(raw(store,'spaces')[index]['value'])
        try:result=facts(changed)
        except R.ReplayError:
            if label not in ('future-stamp','routing-order'):raise
            continue
        if label in ('future-stamp','routing-order') or result==original:raise AssertionError('Undetected raw co-op '+label)
    return ['raw-coop-'+name for name in ('damage','xp','generation','status','identity','source-player','pickup-age','pickup-accumulator','loot-amount','future-stamp','routing-order')]

if __name__=='__main__':
    import argparse,json,sys
    from pathlib import Path
    sys.setrecursionlimit(100000)
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture',type=Path);parser.add_argument('frozen_facts',type=Path);parser.add_argument('--receipt',type=Path)
    args=parser.parse_args();rows=json.loads(args.capture.read_text(),object_pairs_hook=R._pairs,parse_constant=R._constant)['rows']
    actual=[];previous_clock=None;previous_tick=-1;previous_system=-1
    for row in rows:
        value=facts(row);clock=tuple(P.time(row['physical']['world']['clock']['now']));system=row['physical']['world']['nextSystemId']
        if (previous_clock is not None and clock<previous_clock) or row['tick']<previous_tick or system<previous_system:raise R.ReplayError('Co-op World clock/tick/system counter regressed')
        previous_clock,previous_tick,previous_system=clock,row['tick'],system;actual.append(value)
    expected=json.loads(args.frozen_facts.read_text(),object_pairs_hook=R._pairs,parse_constant=R._constant)
    if actual!=expected:raise R.ReplayError('Full co-op qualification differs: '+R.first_difference(expected,actual))
    negative=controls(rows[2]);receipt=dict(status='passed',checkpoints=len(actual),captureSha256=R.file_sha(args.capture),frozenFactsSha256=R.file_sha(args.frozen_facts),rawSourceControls=negative,scope='Complete actual co-op pooled World and player authorities, lifecycle/allocator/clock/routing validation, exact named facts and ordered active snapshots; no tolerances or age/generation exclusions.')
    if args.receipt:args.receipt.write_text(json.dumps(receipt,indent=2)+'\n')
    print(json.dumps(receipt))
