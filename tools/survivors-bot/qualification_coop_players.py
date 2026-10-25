"""Current co-op player authority validation, complementary to native pool replay."""
import math
import replay_compare as R
import current_replay_schema as C
PLAYER_FIELDS='px py hp maxHp character weapons passives invuln arcana meta revivals rerolls banishes skips bannedWeapons bannedPassives'.split()
SESSION_FIELDS='phase tick xp xpNeed level kills gold seed stage bosses mode enemyKinds relicCollected'.split()
def array(value):
    out=[]
    while isinstance(value,dict) and value.get('$')=='Con':
        C.exact_keys(value,{'$','head','tail'},'Bend list');out.append(value['head']);value=value['tail']
    if value!={'$':'Nil'}:raise R.ReplayError('Malformed Bend list')
    return out

def time(value):
    C.exact_keys(value,{'$','epoch','low'},'actual Tick')
    if value['$']!='Tick':raise R.ReplayError('Unknown Tick constructor')
    R.integer(value['epoch'],'epoch');R.u32(value['low'],'tick low')
    return [value['epoch'],value['low']]
def maybe_time(value):
    if value=={'$':'None'}:return None
    C.exact_keys(value,{'$','value'},'stamp option')
    if value['$']!='Some':raise R.ReplayError('Unknown stamp option')
    return time(value['value'])
def player(value):
    C.exact_keys(value,{'$','id','player','connected'},'PlayerRecord')
    if value['$']!='PlayerRecord' or type(value['connected']) is not bool:raise R.ReplayError('Invalid PlayerRecord')
    R.u32(value['id'],'player id');state=value['player']
    C.exact_keys(state,{'$',*PLAYER_FIELDS},'personal PlayerState')
    if state['$']!='PlayerState':raise R.ReplayError('Invalid PlayerState')
    for key in PLAYER_FIELDS:
        if key in ('weapons','passives'):
            values=array(state[key])
            if len(values)!=(24 if key=='weapons' else 18):raise R.ReplayError('Invalid personal loadout length')
            for word in values:R.u32(word,'personal loadout')
        elif key in ('px','py'):
            if type(state[key]) not in (int,float) or not math.isfinite(state[key]):raise R.ReplayError('Invalid personal coordinate')
        else:R.u32(state[key],'personal state')
    return dict(id=value['id'],connected=value['connected'],personal={k:state[k] for k in PLAYER_FIELDS})
def validate_row(row):
    world=row['physical']['world'];R.u32(world['namespace'],'world namespace');now=time(world['clock']['now'])
    if array(world['clock']['scopes']):raise R.ReplayError('Unclosed co-op clock scope')
    store=world['store']['players']
    C.exact_keys(store,{'$','state'},'player column');owned=store['state'];C.exact_keys(owned,{'$','state'},'player owner')
    if store['$']!='Indexed' or owned['$']!='IndexedOrdinaryOwned':raise R.ReplayError('Unknown player storage constructor')
    state=owned['state'];C.exact_keys(state,{'$','values','metadata'},'player indexed state')
    if state['$']!='IndexedOrdinaryState':raise R.ReplayError('Unknown indexed player state')
    meta=state['metadata'];C.exact_keys(meta,{'$','added','changed','capacity','depth','exceptional'},'player lifecycle metadata')
    if meta['$']!='Metadata' or array(meta['exceptional']):raise R.ReplayError('Unexpected exceptional player metadata')
    capacity=R.u32(meta['capacity'],'player capacity');R.u32(meta['depth'],'player depth')
    if meta['depth'] > 31 or capacity != 1 << meta['depth']:raise R.ReplayError('Player column capacity/depth mismatch')
    allocator=world['allocator']
    if len(allocator['slots'])!=allocator['capacity'] or allocator['depth'] > 31 or allocator['capacity'] != 1 << allocator['depth']:raise R.ReplayError('Allocator capacity/depth mismatch')
    if len(state['values'])!=capacity or len(meta['added'])!=capacity or len(meta['changed'])!=capacity:raise R.ReplayError('Incomplete actual player column')
    expected={};facts=[]
    for ref in row['refs']:
        C.exact_keys(ref,{'$','id','handle'},'player ref');h=ref['handle'];C.exact_keys(h,{'$','namespace','key'},'player handle');k=h['key'];C.exact_keys(k,{'$','index','generation'},'player entity key')
        if ref['$']!='PlayerRef' or h['$']!='Handle' or k['$']!='EntityKey' or h['namespace']!=world['namespace']:raise R.ReplayError('Invalid player identity/ref')
        R.u32(ref['id'],'referenced player id')
        index=R.u32(k['index'],'player allocator index');R.u32(k['generation'],'player generation')
        if not 1<=index<=world['allocator']['high'] or index in expected:raise R.ReplayError('Duplicate/outside player handle')
        slot=world['allocator']['slots'][index]
        R.u32(slot['generation'],'actual player slot generation')
        if slot!={'$':'Slot','generation':k['generation'],'phase':{'$':'Live'}} or k not in array(world['allocator']['order']):raise R.ReplayError('Player ref is stale/unissued')
        expected[index]=ref['id']
    loaded={v['id']:v for v in row['players']}
    if len(loaded)!=len(expected):raise R.ReplayError('Missing/duplicate loaded player')
    for index,(value,added,changed) in enumerate(zip(state['values'],meta['added'],meta['changed']),1):
        stamps=[maybe_time(added),maybe_time(changed)]
        present=index in expected;C.stamp_valid(stamps,present,tuple(now))
        if not present:
            if value!={'$':'None'}:raise R.ReplayError('Unreferenced actual player authority')
            continue
        C.exact_keys(value,{'$','value'},'player value option')
        if value['$']!='Some' or value['value']['id']!=expected[index] or value['value']!=loaded[expected[index]]:raise R.ReplayError('Actual/loaded player authority mismatch')
        facts.append(player(value['value']))
    shared=row['shared'];C.exact_keys(shared,{'$',*SESSION_FIELDS},'shared Session')
    for key in SESSION_FIELDS:
        if key=='enemyKinds':
            for word in array(shared[key]):R.u32(word,'enemy kind')
        else:R.u32(shared[key],'shared session')
    if shared['$']!='Session' or shared['tick']!=row['tick']:raise R.ReplayError('Shared session tick mismatch')
    return dict(label=row['label'],tick=row['tick'],shared={k:shared[k] for k in SESSION_FIELDS},players=facts,refs=row['refs'])

def controls(row):
    import copy
    validate_row(row)
    ref=row['refs'][0];index=ref['handle']['key']['index']-1
    for label in ('payload','identity','stamp'):
        changed=copy.deepcopy(row);state=changed['physical']['world']['store']['players']['state']['state']
        if label=='payload':state['values'][index]['value']['player']['hp']=(state['values'][index]['value']['player']['hp']+1)&0xffffffff
        elif label=='identity':changed['refs'][0]['handle']['key']['generation']=(changed['refs'][0]['handle']['key']['generation']+1)&0xffffffff
        else:state['metadata']['changed'][index]['value']['epoch']+=1
        try:validate_row(changed)
        except R.ReplayError:continue
        raise AssertionError('Undetected actual player '+label)
    return ['actual-player-'+name for name in ('payload','identity','stamp')]

if __name__=='__main__':
    import json,sys
    sys.setrecursionlimit(100000)
    document=json.load(open(sys.argv[1]));rows=document['rows']
    facts=[validate_row(row) for row in rows]
    print(json.dumps(dict(status='passed',checkpoints=len(facts),controls=controls(rows[0]))))
