// Executed diagnostics of freshly emitted Bend population policy.
// Usage: node party-difficulty-check.mjs <emitted-party-difficulty.mjs>
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';

const modulePath=resolve(process.argv[2]||process.env.PARTY_DIFFICULTY_MODULE||
  fileURLToPath(new URL('./dist/party-difficulty.mjs',import.meta.url)));
const artifactHash=createHash('sha256').update(await readFile(modulePath)).digest('hex');
const {default:D}=await import(pathToFileURL(modulePath));
// Ordinary JavaScript arithmetic is the independent oracle. Every intermediate
// is at most 25,000,000, so these integers are exact even at arbitrary U32 inputs.
const reference=(base,players,extra)=>players===0?0:Math.min(500,Math.floor(
  Math.min(base,500)*(100+(Math.max(1,Math.min(players,500))-1)*Math.min(extra,100))/100));
let checks=0;
for(let base=0;base<=500;base++)for(let players=0;players<=500;players++){
  for(const extra of [0,25,50,100]){
    assert.equal(D.spawn_limit_for(base,players,extra),reference(base,players,extra));checks++;
    if(extra===100){
      assert.equal(D.spawn_limit_for(base,players,extra),Math.min(500,base*players));checks++;
    }
  }
}
const edges=[0,1,2,3,99,100,101,499,500,501,65535,2147483648,4294967295];
for(const base of edges)for(const players of edges)for(const extra of edges){
  const result=D.spawn_limit_for(base,players,extra);
  assert.equal(result,reference(base,players,extra));
  assert.ok(result>=0&&result<=500);checks++;
}
let seed=1729;
const next=()=>seed=(Math.imul(seed,1664525)+1013904223)>>>0;
for(let index=0;index<10000;index++){
  const base=next(),players=next(),extra=next();
  assert.equal(D.spawn_limit_for(base,players,extra),reference(base,players,extra));checks++;
}
for(const base of edges){
  assert.equal(D.spawn_limit(base,0),0);
  assert.equal(D.spawn_limit(base,1),Math.min(base,500));
  assert.equal(D.spawn_limit(base,2),reference(base,2,25));checks+=3;
}
assert.equal(D.extra_per_player_percent(),25);
assert.equal(D.spawn_limit(96,2),120);
assert.equal(D.spawn_limit(300,2),375);
assert.equal(D.spawn_limit(99,2),123);checks+=4;
console.log(JSON.stringify({status:'PASS',checks,artifactHash,
  initialPairBudget:D.spawn_limit(96,2),latePairBudget:D.spawn_limit(300,2),
  scope:'emitted Bend population policy and independent arithmetic oracle; not a gameplay balance qualification'}));
