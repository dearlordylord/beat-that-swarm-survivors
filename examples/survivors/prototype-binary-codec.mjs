// Throwaway, fixed-schema codec. Never used by production browser entrypoints.
const U = 'u32', F = 'f32', B = 'bool', S = 'string';
const record = (tag, fields) => ({tag, fields});
const fields = (names, type = U) => names.split(' ').map(name => [name,type]);
const list = item => ({list:item});
const tuple = (...items) => ({tuple:items});
const constant = value => ({constant:value});
const run = record('Run', [
  ...fields('phase tick'), ...fields('px py',F),
  ...fields('hp maxHp xp xpNeed level kills gold character'),
  ['weapons',list(U)],['passives',list(U)],
  ...fields('invuln seed stage arcana meta revivals bosses mode rerolls banishes skips bannedWeapons bannedPassives'),
  ['enemyKinds',list(U)],['relicCollected',U],
]);
const body = record('Body',[...fields('x y',F),...fields('kind variant hp maxHp age seed'),['radius',F]]);
const motion = record('Motion',[...fields('vx vy',F),...fields('life pierce'),['visited',list(U)],...fields('slow burn ownerBase logicalSlot')]);
const player = record('PlayerRecord',[['id',U],['run',run],['connected',B]]);
const witness = record('Witness',[...fields('kind tick shot target shotBirth targetBirth'),...fields('x0 y0 x1 y1 ex0 ey0 ex1 ey1 radius time',F)]);
const tree = {tree:true};
const scene = record('Scene',[
  ['own',U],['players',list(player)],['snapshots',list(record('Snapshot',[['body',body],['motion',motion]]))],
  ['births',tree],['directions',record('Directions',fields('x0 y0 x1 y1',F))],
  ['contacts',list(witness)],['tick',U],['diagnostics',B],
]);
const array = item => ({array:item});
const frame = record(null,[
  ...fields('worldSize worldMargin',F),['relicCollected',U],...fields('relicX relicY',F),['runLength',U],
  ['enemiesKilled',array(U)],...fields('mode rerolls banishes skips stage arcana revivalsUsed bossesKilled phase tick'),
  ...fields('px py',F),...fields('hp maxHp xp xpNeed level kills gold character'),
  ['weapons',array(U)],['passives',array(U)],['offers',array(record(null,fields('kind id level')))],
  ['bodies',array(tuple(F,F,U,U,U,U,U,U,F))],['predictionAllowed',B],['stepDistance',F],
  ['coop',constant(true)],['ownPlayerId',U],['choicePending',B],['roundId',U],['requiredPlayers',array(U)],
  ['players',array(record(null,[['id',U],...fields('px py',F),...fields('hp maxHp character'),...fields('connected alive',B)]))],
  ['combatForecast',scene],['runId',S],
]);
const lane = record('Lane',fields('lastSeq inputSeq appliedSeq appliedTick receivedAt x y'));
const hit = record('HitEvent',[
  ['id',S],...fields('tick kind'),['shotId',S],...fields('shotSeed targetSeed targetGeneration'),
  ...fields('fraction impactX impactY targetAtImpactX targetAtImpactY radius',F),['outcome',U],
]);
const envelope = record(null,[
  ['type',constant('frame')],...fields('connectionVersion token'),['initial',B],['frame',frame],
  ['admission',record('State',[...fields('session clock'),['host',lane],['guest',lane],...fields('guestConnected ended',B)])],
  ['receipt',record('Receipt',[...fields('seq worldTick x y'),['applied',B]])],
  ['inputTiming',record(null,[['worldTick',U],['lastRejected',{nullable:record(null,fields('reason seq targetWorldTick worldTick'))}]])],
  ['observationSeq',U],['contactJournal',record('State',[...fields('epoch now'),['events',list(hit)],...fields('overflow expired')])],
]);
export const MAX_BYTES = 1024 * 1024;
const MAX_ROWS = 16384;
const encoder = new TextEncoder(), decoder = new TextDecoder('utf-8',{fatal:true});
function countRows(value) {
  let count = 0;
  for (;value?.$ === 'Con';value=value.tail) if (++count > MAX_ROWS) throw Error('too many rows');
  if (value?.$ !== 'Nil') throw Error('invalid list');
  return count;
}
export function rows(value) {
  const out=[];
  for (;value?.$ === 'Con';value=value.tail) out.push(value.head);
  if (value?.$ !== 'Nil') throw Error('invalid list');
  return out;
}

// Mechanical reshaping only. Bend supplied all selection and policy decisions.
export function presentation(o) {
  const r=o.run, out={};
  for (const key of 'worldSize worldMargin relicX relicY runLength predictionAllowed stepDistance ownPlayerId choicePending roundId combatForecast'.split(' ')) out[key]=o[key];
  for (const key of 'relicCollected mode rerolls banishes skips stage arcana phase tick px py hp maxHp xp xpNeed level kills gold character'.split(' ')) out[key]=r[key];
  Object.assign(out,{revivalsUsed:r.revivals,bossesKilled:r.bosses,enemiesKilled:rows(r.enemyKinds),weapons:rows(r.weapons),passives:rows(r.passives),
    offers:rows(o.offers).map(({kind,id,level})=>({kind,id,level})),
    bodies:rows(o.bodies).map(b=>[b.x,b.y,b.kind,b.variant,b.hp,b.maxHp,b.age,b.seed,b.radius]),
    coop:true,requiredPlayers:rows(o.requiredPlayers),players:rows(o.players).map(({$,...p})=>p)});
  return out;
}

function write(schema, value, state) {
  const {view}=state;
  function put(size, method, val) {
    if (state.at+size>MAX_BYTES) throw Error('oversized frame');
    if (view) view[method](state.at,val,true);
    state.at+=size;
  }
  if (schema===U) {
    if (!Number.isInteger(value)||value<0||value>0xffffffff) throw Error('invalid u32');
    put(4,'setUint32',value);
  } else if (schema===F) {
    if (!Number.isFinite(value)||!Number.isFinite(Math.fround(value))) throw Error('invalid f32');
    put(4,'setFloat32',value);
  } else if (schema===B) {
    if (typeof value!=='boolean') throw Error('invalid bool');
    put(1,'setUint8',+value);
  } else if (schema===S) {
    const bytes=encoder.encode(value);
    write(U,bytes.length,state);
    if (state.at+bytes.length>MAX_BYTES) throw Error('oversized string');
    if (view) new Uint8Array(view.buffer,state.at,bytes.length).set(bytes);
    state.at+=bytes.length;
  } else if ('constant' in schema) {
    if (value!==schema.constant) throw Error('invalid constant');
  } else if (schema.fields) {
    if (schema.tag && value.$!==schema.tag) throw Error('invalid constructor');
    for (const [key,type] of schema.fields) write(type,value[key],state);
  } else if (schema.list || schema.array) {
    const length=schema.list?countRows(value):value.length;
    if (length>MAX_ROWS) throw Error('too many rows');
    write(U,length,state);
    if (schema.list) for (let node=value;node.$==='Con';node=node.tail) write(schema.list,node.head,state);
    else for (const item of value) write(schema.array,item,state);
  } else if (schema.tuple) {
    schema.tuple.forEach((type,i)=>write(type,value[i],state));
  } else if (schema.nullable) {
    write(B,value!==null,state);
    if (value!==null) write(schema.nullable,value,state);
  } else if (schema.tree) {
    const tag=['Empty','Item','Fork'].indexOf(value.$);
    if (tag<0) throw Error('invalid tree');
    put(1,'setUint8',tag);
    if (tag===1) {write(U,value.key,state);write(U,value.value,state);}
    if (tag===2) {write(U,value.sample,state);write(U,value.mask,state);write(tree,value.zero,state);write(tree,value.one,state);}
  }
}
function read(schema,state,depth=0) {
  if (depth>96) throw Error('excessive depth');
  function get(size,method) {
    if (state.at+size>state.view.byteLength) throw Error('truncated frame');
    const value=state.view[method](state.at,true);state.at+=size;return value;
  }
  const child=type=>read(type,state,depth+1);
  if(schema===U)return get(4,'getUint32');
  if(schema===F){const value=get(4,'getFloat32');if(!Number.isFinite(value))throw Error('invalid float');return value;}
  if(schema===B){const value=get(1,'getUint8');if(value>1)throw Error('invalid bool');return !!value;}
  if(schema===S){const length=child(U);if(length>state.view.byteLength-state.at)throw Error('truncated string');const value=decoder.decode(new Uint8Array(state.view.buffer,state.view.byteOffset+state.at,length));state.at+=length;return value;}
  if('constant' in schema)return schema.constant;
  if(schema.fields){const out=schema.tag?{$:schema.tag}:{};for(const [key,type]of schema.fields)out[key]=child(type);return out;}
  if(schema.array||schema.list){
    const count=child(U);
    if(count>MAX_ROWS||count>state.view.byteLength-state.at)throw Error('invalid row count');
    const values=Array.from({length:count},()=>child(schema.array||schema.list));
    return schema.list?values.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'}):values;
  }
  if(schema.tuple)return schema.tuple.map(child);
  if(schema.nullable)return child(B)?child(schema.nullable):null;
  if(schema.tree){const tag=get(1,'getUint8');if(tag===0)return {$:'Empty'};if(tag===1)return {$:'Item',key:child(U),value:child(U)};if(tag===2)return {$:'Fork',sample:child(U),mask:child(U),zero:child(tree),one:child(tree)};throw Error('invalid tree tag');}
  throw Error('unknown schema');
}
export function encode(value) {
  const sizing={at:12};write(envelope,value,sizing);
  const bytes=new Uint8Array(sizing.at),view=new DataView(bytes.buffer);
  view.setUint32(0,0x314e4942,true);view.setUint32(4,1,true);view.setUint32(8,bytes.length,true);
  write(envelope,value,{at:12,view});return bytes;
}
export function decode(bytes) {
  if(bytes.byteLength<12||bytes.byteLength>MAX_BYTES)throw Error('invalid frame size');
  const view=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength);
  if(view.getUint32(0,true)!==0x314e4942||view.getUint32(4,true)!==1||view.getUint32(8,true)!==bytes.length)throw Error('invalid header');
  const state={view,at:12},value=read(envelope,state);
  if(state.at!==bytes.length)throw Error('trailing bytes');return value;
}
