#!/usr/bin/env python3
"""Temporary closed named-fact projection from the current typed schema.

Historical named-fact interpretation is confined to canonical_baseline and is
never used to validate or detect current raw storage. The raw baseline exporter
is frozen externally. This temporary migration oracle validates current storage
before projecting gameplay facts.
"""
import copy
import replay_compare as R
import current_replay_schema as C
import projectile_qualification as Shot
import enemy_qualification as Enemy
import pickup_qualification as Pickup
RUN_FIELDS='phase tick pxBits pyBits health maximum xp xpNeed level kills gold character weapons passives invulnerability seed stage arcana meta revivals bosses mode rerolls banishes skips bannedWeapons bannedPassives enemyKinds relicCollected'.split()

def entities(payload):
    c=payload['components']['actorColumns'];by_identity={}
    shots={v['seed']:v for v in Shot.validate_and_project(c,payload['metadata'],C.DEFAULT_LAYOUT)}
    pickups=Pickup.validate_and_project(c,payload['metadata'],C.DEFAULT_LAYOUT)
    for offset,(_,identity,_) in enumerate(c['identities']):
        role=c['roles'][offset][1];x,y,age,radius=c['spaces'][offset][1]
        fact=dict(xBits=x,yBits=y,age=age,seed=identity,radiusBits=radius,role=role)
        if role in C.PROJECTILES:fact=shots[identity]
        elif role=='EnemySlot':
            phase,archetype=c['enemyPhases'][offset][1];hp,maximum=c['vitals'][offset][1]
            item=pickups[identity];tag=c['pickups'][offset][1][0][0]
            kind=0 if phase==1 else (3,4,5,9)[tag-1] if phase==2 and item['active'] else 8
            fact.update(kind=kind,variant=archetype,health=hp,maximum=maximum,status=copy.deepcopy(c['statuses'][offset][1]))
        elif role=='RelicSlot':fact.update(kind=9 if pickups[identity]['active'] else 8,variant=pickups[identity]['item'].get('stage',0),health=0,maximum=0,status=dict(slow=dict(ticks=0,frozen=False),burn=dict(ticks=0,sourcePlayer=None)))
        else:
            p=pickups[identity];fact.update(kind=2 if p['active'] else 8,variant=int(p['item']['accumulator']),pickup=dict(amount=p['item']['amount'],generation=p['generation'],variant=int(p['item']['accumulator']),active=int(p['active'])))
        by_identity[identity]=fact
    return [by_identity[i] for i in range(C.DEFAULT_LAYOUT['totalCount'])]

def canonical(facts):
    """Closed gameplay surface, omitting retired inactive transport rows.

    All per-slot authoritative facts remain exact; snapshot membership/order is
    compared for active actors. Current physical validation separately checks
    complete typed inactive snapshot coverage/order and every actual stamp.
    """
    f=copy.deepcopy(facts)
    f.pop('visible')
    f['snapshots']=[s for s in f['snapshots'] if s['kind']!=8]
    return f

def project(payload,tick):
    C.validate_payload(payload,tick)
    es=entities(payload);snapshots=[]
    for s in payload['snapshots']:
        kind,v=next(iter(s.items()));e=es[v['identity']]
        f={k:e[k] for k in ('xBits','yBits','kind','variant','age','seed','radiusBits')}
        if f['kind']==0:f.update(health=e['health'],maximum=e['maximum'],status=e['status'])
        elif f['kind'] in (1,7):f.update(damage=e['damage'],trajectory=e['trajectory'])
        elif f['kind']==2:f.update(amount=e['pickup']['amount'],generation=e['pickup']['generation'])
        snapshots.append(f)
    return canonical(dict(run=dict(zip(RUN_FIELDS,payload['run'])),entities=es,visible=[],snapshots=snapshots,offers=payload['offers'],pending=payload['pending'],identity=dict(namespace=payload['metadata']['namespace'],allocator=payload['metadata']['allocator'])))

def canonical_baseline(facts):
    """Interpret only the explicitly frozen former schema, never current state."""
    expected_visible=[{k:v for k,v in snapshot.items() if k not in ('status','trajectory')} for snapshot in facts['snapshots']]
    if facts['visible']!=expected_visible:raise R.ReplayError('Frozen visible rows are not the duplicated snapshot transport')
    f=canonical(facts)
    for entity in f['entities']:
        initial_marker=entity['kind']==8 and entity['role']!='EnemySlot' and entity['variant']==entity['seed'] and entity['age']==entity['seed']
        if initial_marker:entity['variant']=0
        if entity['role']=='XpSlot':
            marker=entity['pickup']['variant']
            if marker not in (0,1) and not(initial_marker and marker==entity['seed']):raise R.ReplayError('Unexpected frozen XP marker')
            entity['pickup']['variant']=int(marker==1)
    for value in f['entities']+f['snapshots']:
        if 'trajectory' in value:
            trajectory=value['trajectory'];packed=trajectory.pop('logicalSlot')
            trajectory['weaponOwner']=trajectory.pop('owner')
            trajectory['sourcePlayer']=(packed//65536) if value['kind']==1 else None
            trajectory['logicalSlot']=packed%65536
        if 'status' in value:
            slow=value['status']['slow'];burn=value['status']['burn']
            value['status']=dict(slow=dict(ticks=slow%65536,frozen=slow>=65536),burn=dict(ticks=burn%65536,sourcePlayer=burn//65536 if burn%65536 else None))
    return f

def compare_capture(path,frozen_facts):
    import json
    baseline=json.loads(frozen_facts.read_text());candidate=[]
    for record in R.records(path):
        row=R.semantic(record)
        if row['type']=='checkpoint':row['facts']=project(row.pop('payload'),record['payload']['run'][1])
        candidate.append(row)
    for row in baseline:
        if row['type']=='checkpoint':row['facts']=canonical_baseline(row['facts'])
    if baseline!=candidate:raise R.ReplayError('Typed qualification differs: '+R.first_difference(baseline,candidate))
    return len([r for r in candidate if r['type']=='checkpoint'])

def controls(payload):
    tick=payload['run'][1];original=project(payload,tick)
    for label in ('damage','xp','generation','status','identity'):
        changed=copy.deepcopy(payload);c=changed['components']['actorColumns']
        if label=='xp':changed['run'][6]=(changed['run'][6]+1)&0xffffffff
        elif label=='identity':c['identities'][0][1]=c['identities'][1][1]
        else:
            family,word,role={'damage':('shots',1,'PlayerProjectileSlot'),'status':('statuses',0,'EnemySlot'),'generation':('pickups',1,'XpSlot')}[label]
            index=next(i for i,row in enumerate(c['roles']) if row[1]==role and (label!='generation' or c['pickups'][i][1][2]==1))
            if label=='status':
                value=c[family][index][1]['slow'];value['ticks']=(value['ticks']+1)&0xffffffff
            else:c[family][index][1][word]=(c[family][index][1][word]+1)&0xffffffff
            identity=c['identities'][index][1]
            for s in changed['snapshots']:
                kind,v=next(iter(s.items()))
                if v['identity']==identity:
                    if label=='damage':v['payload']=copy.deepcopy(c[family][index][1])
                    elif label=='status':v['status']=copy.deepcopy(c[family][index][1])
                    else:v['payload']=copy.deepcopy(c[family][index][1])
        try:result=project(changed,tick)
        except (R.ReplayError,ValueError):
            if label!='identity':raise
            continue
        if result==original:raise AssertionError('Raw-source '+label+' escaped qualification')
    return ['raw-source-'+name for name in ('damage','xp','generation','status','identity')]

CROSS_SCHEMA_BOUNDARY=[
    'All per-slot named gameplay facts, run facts, offers, pending rewards and namespace/allocator identity are exact.',
    'Actual current columns, stamps, clocks, issued identities, routing and typed snapshot coverage/order are validated before projection; their changed partition is not cross-schema equality.',
    'Former visible Body rows must exactly duplicate snapshot transport, then only one copy is retained.',
    'Inactive snapshot transport entries are absent from the ordered presentation projection; their complete per-slot gameplay facts remain exact.',
    'Only former inactive non-enemy kind8 initial variant==seed with age==seed is interpreted as retired marker zero.',
    'Former XP marker 0/1 (or that exact initial seed marker) is interpreted as the explicit accumulator flag.',
    'Only the frozen baseline side interprets former packed source-player/local-slot and slow/burn words; current storage is explicit.',
    'Only named outer wall-clock timing fields are excluded; no numeric tolerance or recursive exclusion is used.',
]

def main():
    import argparse,json
    from pathlib import Path
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture',type=Path);parser.add_argument('baseline_facts',type=Path)
    parser.add_argument('--trace',type=Path,required=True);parser.add_argument('--receipt',type=Path)
    args=parser.parse_args()
    physical=R.compare(args.capture,args.capture,trace=args.trace)
    checkpoints=compare_capture(args.capture,args.baseline_facts)
    observed=[r['payload'] for r in R.records(args.capture) if r['type']=='checkpoint']
    chosen=next(p for p in observed if any(row[1] is not None and row[1][2] and p['components']['actorColumns']['roles'][i][1]=='XpSlot' for i,row in enumerate(p['components']['actorColumns']['pickups'])))
    negative=controls(chosen)+Pickup.controls(chosen['components']['actorColumns'],chosen['metadata'],C.DEFAULT_LAYOUT)
    receipt=dict(status='passed',checkpoints=checkpoints,currentSchemaSelfValidation=physical,
                 frozenFactsSha256=R.file_sha(args.baseline_facts),rawSourceControls=negative,
                 crossSchemaBoundary=CROSS_SCHEMA_BOUNDARY)
    if args.receipt:args.receipt.write_text(json.dumps(receipt,indent=2)+'\n')
    print(json.dumps(receipt))

if __name__=='__main__':main()
