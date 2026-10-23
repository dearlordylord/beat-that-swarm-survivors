// Differential oracle against the previously shipped first-match row lookup.
import assert from 'node:assert/strict';
import G from '../dist/game.mjs';
const list = xs => xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const body = (seed,salt=0,kind=2) => ({$:'Body',x:12.5+salt,y:99.25-salt,kind,variant:(salt*7)>>>0,hp:(salt*17+1)>>>0,maxHp:(salt*13+9)>>>0,age:(salt*23+11)>>>0,seed,radius:3.25+salt/100});
const row = b => ({$:'EntityRow',row:{$:'Row',body:b,hit:0,xp:0,gold:0,heal:0,chest:0,killed:0,relic:0},motion:G.empty_motion()});
const fallback = body(777,999,8);
const extremes = [0,1,1003,0x7fffffff,0x80000000,0x80000001,0xffffffff];
const mixed = extremes.map((key,i)=>body(key,i+1,[0,1,2,7,8,10,11][i]));
// A later duplicate differs in all fields; the original opaque value must win.
mixed.splice(3,0,body(1,800,5));
mixed.push(body(0xffffffff,700,9));
const mixedRows = list(mixed.map(row));
const mixedIndex = G.body_index(mixedRows);
for (const key of [...extremes,42,0xabcdef01]) {
  assert.deepEqual(G.indexed_body(mixedIndex,key,fallback),G.planned_body(mixedRows,key,fallback),`U32 key ${key}`);
}
assert.deepEqual(G.indexed_body(mixedIndex,1,fallback),mixed[1]);
assert.notDeepEqual(G.indexed_body(mixedIndex,1,fallback),G.indexed_body(mixedIndex,0x80000001,fallback),'High bit participates in the key');
assert.deepEqual(G.indexed_body(G.body_index(list([])),0xffffffff,fallback),fallback);
let entropy = 0x5eed1234;
const random = () => entropy = (Math.imul(entropy,1664525)+1013904223)>>>0;
for (let trial=0;trial<12;trial++) {
  const entries=Array.from({length:96},(_,i)=>body(random(),i+trial*100,i%12));
  entries.push(body(entries[3].seed,900),body(entries[41].seed,901));
  // Deterministically shuffle the input: duplicate precedence follows row order.
  for(let i=entries.length-1;i>0;i--){const j=random()%(i+1);[entries[i],entries[j]]=[entries[j],entries[i]];}
  const rows=list(entries.map(row));
  const index=G.body_index(rows);
  for(const key of [...entries.map(b=>b.seed),random(),random()]) {
    assert.deepEqual(G.indexed_body(index,key,fallback),G.planned_body(rows,key,fallback));
  }
}
console.log('Body index: full-U32 keys, first duplicate, opaque field preservation, missing fallback and shuffled differential oracle passed');
