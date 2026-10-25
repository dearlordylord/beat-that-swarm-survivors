// The one untrusted snapshot boundary. Local Bend results never call this parser.
import {roots, schema} from './observation-schema.generated.mjs';

const MAX_ROWS = 16384;
function object(value) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) throw TypeError('Expected snapshot object.');
  return value;
}
function record(fields, value, state, depth) {
  object(value);
  const keys = Object.keys(value);
  if (keys.length !== fields.length || fields.some(([key]) => !Object.hasOwn(value,key)))
    throw TypeError('Unexpected snapshot fields.');
  for (const [key,type] of fields) check(type,value[key],state,depth+1);
}
function check(type, value, state, depth = 0) {
  if (--state.nodes < 0 || depth > 96) throw RangeError('Snapshot structure is too large.');
  if (typeof type === 'string') {
    if (type === 'bool' ? typeof value !== 'boolean' : type === 'string' ? typeof value !== 'string' :
      typeof value !== 'number' || !Number.isFinite(value) ||
      (type === 'f32' ? !Number.isFinite(Math.fround(value)) :
        !Number.isInteger(value) || value < 0 || value > (type === 'u32' ? 0xffffffff : 2**48-1)))
      throw TypeError(`Invalid snapshot ${type}.`);
  } else if (type.ref) {
    object(value);
    const variants = schema[type.ref];
    if (!Object.hasOwn(variants,value.$)) throw TypeError('Invalid Bend constructor in snapshot.');
    record([['$',{literal:value.$}],...variants[value.$]],value,state,depth);
  } else if (type.list) {
    let count = 0, node = value;
    while (object(node).$ === 'Con') {
      if (++count > MAX_ROWS) throw RangeError('Snapshot list is too large.');
      record([['$',{literal:'Con'}],['head',type.list],['tail',{unchecked:true}]],node,state,depth);
      node = node.tail;
    }
    record([['$',{literal:'Nil'}]],node,state,depth);
  } else if (type.array) {
    if (!Array.isArray(value) || value.length > MAX_ROWS) throw TypeError('Invalid snapshot array.');
    for (const item of value) check(type.array,item,state,depth+1);
  } else if (type.tuple) {
    if (!Array.isArray(value) || value.length !== type.tuple.length) throw TypeError('Invalid body tuple.');
    type.tuple.forEach((item,index) => check(item,value[index],state,depth+1));
  } else if (type.record) {
    record(type.record,value,state,depth);
  } else if (Object.hasOwn(type,'literal')) {
    if (value !== type.literal) throw TypeError('Invalid snapshot kind.');
  } else if (type.nullable) {
    if (value !== null) check(type.nullable,value,state,depth+1);
  } else if (!type.unchecked) throw TypeError('Unsupported snapshot schema.');
}
function fields(ref) { return Object.values(schema[ref.ref])[0]; }
function presentation(type) {
  if (type.ref === 'GameBody') return {tuple:fields(type).map(([,field])=>field)};
  if (type.ref === 'GameOffer' || type.ref === 'CoopCoreObservedPlayer') return {record:fields(type)};
  return type;
}
const frameFields = [...fields(roots.game),...fields(roots.details)].map(([key,type]) =>
  [key,type.list ? {array:presentation(type.list)} : type]);
frameFields.push(['runId','string']);
const timing = {record:[['worldTick','u32'],['lastRejected',{nullable:{record:
  ['reason','seq','targetWorldTick','worldTick'].map(key=>[key,'u32'])}}]]};
const envelope = {record:[['type',{literal:'frame'}],['connectionVersion','u32'],['token','u32'],['initial','bool'],
  ['frame',{record:frameFields}],['admission',roots.admission],['receipt',roots.receipt],
  ['observationSeq','u32'],['contactJournal',roots.journal],['inputTiming',timing]]};

export function admitSnapshot(value) {
  check(envelope,value,{nodes:1024*1024});
  return value;
}
