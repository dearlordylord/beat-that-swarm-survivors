"""Small complete current-schema world for offline oracle controls."""
import copy
import current_replay_schema as C
LAYOUT=dict(enemyCount=2,relicSeed=1,playerStart=2,hostileStart=4,xpStart=5,totalCount=7)
STAMP=[[0,1],[0,1]]
def payload(tick=0):
    total=LAYOUT['totalCount']; run=[0]*29;run[1]=tick;run[12]=[0]*24;run[13]=[0]*18;run[27]=[]
    # Semantic slots deliberately do not equal physical handle indices.
    identities=[2,0,6,1,4,3,5]; c={k:[] for k in C.FAMILIES}
    for handle,identity in enumerate(identities,1):
        role=C.assigned(identity,LAYOUT)
        values=dict(bodies=None,vitals=[0,0] if role=='EnemySlot' else None,statuses=[0,0] if role=='EnemySlot' else None,
                    trajectories=[0,0,0,0,[],0,0,None] if role in C.PROJECTILES else None,
                    shots=[0,0,0] if role in C.PROJECTILES else None,
                    pickups=[[0,0,0],0,0] if role in C.ENEMIES|{'XpSlot'} else None,
                    enemyPhases=[0,identity] if role in C.ENEMIES else None,
                    roles=role,spaces=[0,0,identity,0],identities=identity)
        for family,value in values.items():c[family].append([handle,value,copy.deepcopy(STAMP if value is not None else [None,None])])
    c.update(movementCandidates=[],projectileCandidates=[],poolCandidates=[])
    for handle,identity in enumerate(identities,1):
        role=C.assigned(identity,LAYOUT)
        if role in C.PROJECTILES:c['projectileCandidates'].append([1,handle,0])
        if role in C.ENEMIES|{'XpSlot'}:c['poolCandidates'].append([1,handle,0])
    snapshots=[]
    if tick:
        for handle,identity in reversed(list(enumerate(identities,1))):
            if C.assigned(identity,LAYOUT)=='XpSlot':snapshots.append(dict(pickup=dict(spatial=c['spaces'][handle-1][1],identity=identity,payload=c['pickups'][handle-1][1])))
        for handle,identity in reversed(list(enumerate(identities,1))):
            role=C.assigned(identity,LAYOUT)
            if role in C.PROJECTILES:snapshots.append(dict(projectile=dict(spatial=c['spaces'][handle-1][1],identity=identity,side='player' if role=='PlayerProjectileSlot' else 'hostile',payload=c['shots'][handle-1][1],trajectory=c['trajectories'][handle-1][1])))
    return dict(run=run,bodies=[],offers=[],snapshots=snapshots,pending=[],components=dict(actorColumns=c,players=[[i,None,[None,None]] for i in range(1,total+1)]),
                metadata=dict(namespace=1,allocator=[8,7,8,3,[],[[i,0] for i in range(1,8)],[[0,0]]+[[0,2] for _ in range(7)]],clock=[[0,1],[]],events=0,pendingCommands=0,registrations=[],nextSystemId=0))
def replay():
    fixture='seed100-profile0-warm0-end1'
    return [dict(type='start',schemaVersion=1,fixture=fixture,seed=100,profile=0,warmup=0,endTick=1),
            dict(type='checkpoint',fixture=fixture,step=0,payload=payload()),dict(type='checkpoint',fixture=fixture,step=1,payload=payload(1)),
            dict(type='summary',fixture=fixture,actions=1,firstTick=0,endTick=1,phase=0,wallMs=10)]
