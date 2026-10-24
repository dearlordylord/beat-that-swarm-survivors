import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const artifact=process.argv[2]?pathToFileURL(process.argv[2]):new URL('../dist/game.mjs',import.meta.url);
const {default:exports}=await import(artifact.href);
const P=Object.fromEntries(['allocate','lookup'].map(name=>[name,exports[`projectile-pool:${name}`]??exports[name]]));
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const request=(owner,slot=0,level=1)=>({$:'Request',owner,slot,level});
let checks=0;
function check(free,live,caps,requests) {
  assert.equal(live.length,24);assert.equal(caps.length,24);
  assert.equal(new Set(free).size,free.length,'unique genuinely-free identities are the production premise');
  const expected=new Map(),counts=[...live];let next=0;
  for(const r of requests) {
    if(next>=free.length)break;
    if(r.owner>=24||counts[r.owner]>=caps[r.owner])continue;
    expected.set(free[next++],r);counts[r.owner]++;
  }
  const plan=P.allocate(list(free),list(live),list(caps),list(requests));
  assert.equal(plan.count,expected.size);
  for(const seed of [...free,1,511,704,748,0xffffffff]) {
    const actual=P.lookup(plan,seed),wanted=expected.get(seed);
    assert.deepEqual(actual,wanted?{$:'Some',value:wanted}:{$:'None'},`seed=${seed}`);
  }
  checks++;
}
const zeros=()=>Array(24).fill(0),ones=()=>Array(24).fill(1);
check([],zeros(),ones(),[request(0)]);
check([512,513],zeros(),zeros(),[request(0),request(1)]);
check([512,513],zeros(),ones(),[request(0,3),request(0,4),request(1,5)]);
check([512,513],zeros(),ones(),[request(24),request(0xffffffff),request(1,7,9)]);
check([512],zeros(),ones(),[request(2),request(1)]);
let random=0x93245;
const next=()=>{random=(Math.imul(random,1664525)+1013904223)>>>0;return random;};
for(let trial=0;trial<300;trial++) {
  const caps=Array.from({length:24},()=>next()%12),live=caps.map(cap=>next()%(cap+2));
  const free=Array.from({length:next()%80},(_,i)=>512+i);
  const requests=Array.from({length:next()%150},()=>request(next()%28,next()%8,1+next()%15));
  check(free,live,caps,requests);
}
console.log(`PASS projectile pool: ${checks} allocation cases, exact priority/metadata/caps/saturation/lookup; only supplied free identities assigned.`);
