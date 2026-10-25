// Diagnostics of emitted Bend geometry; laws own the pure contact policy.
// Usage: node coop-contact-playback-check.mjs /tmp/coop-contact-playback.mjs /tmp/coop-playback.mjs
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
const {default:C}=await import(pathToFileURL(resolve(process.argv[2]??'examples/survivors/dist/coop-contact-playback.mjs')));
const {default:P}=await import(pathToFileURL(resolve(process.argv[3]??'examples/survivors/dist/coop-playback.mjs')));
const list=rows=>rows.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=rows=>{const out=[];for(;rows.$==='Con';rows=rows.tail)out.push(rows.head);return out;};
const enemy=(key,x,extra={})=>({$:'Actor',key,kind:0,generation:`enemy:${key}:7`,x,y:0,age:20,alive:true,owner:0,...extra});
const shot=(key,x,extra={})=>({$:'Actor',key,kind:1,generation:`shot:${key}`,x,y:0,age:3,alive:true,owner:1,...extra});
const event=(extra={})=>({$:'HitEvent',id:'hit:1',tick:104,kind:2,shotId:'shot:50',shotSeed:50,targetSeed:42,targetGeneration:7,fraction:.5,impactX:11.5,impactY:0,targetAtImpactX:13.5,targetAtImpactY:0,radius:3,outcome:0,...extra});
const journal=events=>({$:'State',epoch:1,now:106,events:list(events),overflow:0,expired:0});
const frame=(observation,tick,bodies)=>({$:'Frame',observation,tick,receivedAt:tick*16667,players:list([]),bodies:list(bodies)});
const fixture=(old,next,events)=>{let state=P.push(P.fresh(),frame(1,100,old));state=P.push(state,frame(2,106,next));return {state,prepared:C.prepare(journal(events))};};
const display=(fixture,tick,fraction=0)=>{const state={...fixture.state,cursor:{$:'Cursor',tick,fraction,lastAt:0,mode:{$:'Playing'}}};const sample=P.sample(state).value;return C.project(state,sample,fixture.prepared);};
const body=(out,key)=>array(out.sample.bodies).find(a=>a.key===key);
let checks=0;const check=(value,message)=>{assert.ok(value,message);checks++;};
let f=fixture([enemy(42,10),shot(50,0)],[enemy(42,16)],[event()]);
let out=display(f,101,750000);
check(Math.abs(body(out,50).x-5.75)<1e-5,'missing terminal shot travels to its confirmed contact instead of freezing');
check(body(out,42).x===11.75,'living enemy keeps the shared interpolation clock');
check(array(out.contacts).length===0,'future receipt does not play early');
out=display(f,103,499000);
check(Math.abs((body(out,42).x-body(out,50).x)-2)<.01,'shot meets moving target at contact-relative offset');
out=display(f,103,500000);
check(!body(out,50),'terminal shot disappears exactly at fractional contact time');
out=display(f,104);
check(array(out.contacts)[0].x===12,'confirmed FX follows displayed target plus original contact offset');
check(array(out.contacts)[0].x!==11.5,'FX does not stay at stale authority coordinates');
// Dying targets travel to the authoritative contact position; their HP is never invented.
f=fixture([enemy(42,10),shot(50,0)],[],[event()]);
out=display(f,101,750000);
check(body(out,42).x===11.75,'dying target reconstructs the last observed path');
check(body(out,42).alive===true,'presentation preserves explicit actor liveness');
out=display(f,104);
check(body(out,42).x===13.5&&!body(out,50),'target holds impact point after shot removal');
check(array(out.contacts)[0].x===11.5,'dying target FX shares the same contact point');
check(!body(display(f,106),42),'dead target disappears when next inventory is adopted');
// Two shots contact one dying target along a nonlinear authoritative history.
// Both visual endpoints must sample the ONE selected target trajectory.
f=fixture([enemy(42,0),shot(50,0),shot(51,0)],[],[
 event({id:'early',tick:102,fraction:.5,targetAtImpactX:10,impactX:8}),
 event({id:'late',tick:105,fraction:.5,shotSeed:51,shotId:'shot:51',targetAtImpactX:12,impactX:10})]);
out=display(f,101,499000);
check(Math.abs((body(out,42).x-body(out,50).x)-2)<.01,'earlier terminal shot samples the same nonlinear dying-target trajectory');
check(!!body(out,51),'later shot remains until its own terminal time');
out=display(f,104,499000);
check(Math.abs((body(out,42).x-body(out,51).x)-2)<.01,'later terminal shot shares that target trajectory');

// Piercing events cannot remove the projectile; only the final terminal event owns its endpoint.
f=fixture([enemy(42,10),enemy(43,20),shot(50,0)],[enemy(42,16),enemy(43,26)],
 [event({id:'pierce',kind:0,tick:102,fraction:.2}),event({id:'end-a',tick:104,fraction:.2,targetSeed:43,impactX:21.2,targetAtImpactX:23.2}),event({id:'end-b',tick:104,fraction:.8,targetSeed:43,impactX:21.8,targetAtImpactX:23.8})]);
check(!!body(display(f,103,500000),50),'largest terminal fraction wins within the final tick');
check(!body(display(f,103,900000),50),'selected terminal event removes exhausted shot');
// Missing terminal evidence and mismatched lifetimes must keep ordinary playback.
for(const change of [{kind:0},{outcome:1},{shotId:'other-life'},{shotSeed:51},{tick:100},{tick:107}]){
 f=fixture([shot(50,0)],[],[event(change)]);check(body(display(f,104),50).x===0,'unknown event cannot fabricate a terminal path');
}
f=fixture([enemy(42,10,{generation:'enemy:42:8'}),shot(50,0)],[],[event()]);
check(body(display(f,102),42).x===10,'unrelated target generation is never nudged');
out=display(f,104);check(array(out.contacts)[0].x===11.5,'unknown target lifetime uses canonical impact fallback');
f=fixture([enemy(42,10),shot(50,0)],[enemy(42,100,{generation:'enemy:42:8'})],[event()]);
check(body(display(f,104),42).x===13.5,'old target lifetime is reconstructed before slot replacement');
check(body(display(f,106),42).x===100,'reused slot adopts its own new position without interpolation');
for(const [tick,expected] of [[103,0],[104,1],[105,1],[106,1],[107,1],[108,0]]){
 const plain={$:'Sample',baseObservation:1,nextObservation:1,tick,fraction:0,alpha:0,players:list([]),bodies:list([enemy(42,20)])};
 check(array(C.output(plain,C.prepare(journal([event()]))).contacts).length===expected,'FX bounded four ticks and presentation gated');
}
// All receipts for shared seed buckets remain available; no first-wins loss.
const denseEvents=Array.from({length:512},(_,i)=>event({id:`dense:${i}`,shotSeed:50+i%16,shotId:`shot:${50+i%16}`,targetSeed:100+i%32,tick:101+i%6,fraction:(i%10)/10}));
const prepared=C.prepare(journal(denseEvents));
for(let key=50;key<66;key++){
 const actor=shot(key,0);const context={$:'Context',baseTick:100,nextTick:106,tick:102,fraction:0,base:{$:'Empty'},next:{$:'Empty'},prepared};
 const selected=C.contact_for(context,actor,true);check(selected.$==='Some','bucket retains every shot seed');
 const relevant=denseEvents.filter(e=>e.shotSeed===key).sort((a,b)=>b.tick-a.tick||b.fraction-a.fraction)[0];
 check(selected.value.tick===relevant.tick&&Math.abs(selected.value.fraction-relevant.fraction)<1e-6,'bucket selects latest terminal time');
}
const denseOld=Array.from({length:12000},(_,i)=>enemy(100+i,i));
f=fixture([...denseOld,...Array.from({length:16},(_,i)=>shot(50+i,0))],[],denseEvents);
out=display(f,103,200000);
check(array(out.sample.bodies).length>=12000,'large actor cohort remains stack safe');
check(array(out.contacts).length<=512,'confirmed FX remain bounded by prepared journal');
console.log(JSON.stringify({status:'PASS',checks,receipts:512,denseActors:12016,scope:'emitted Bend contact playback diagnostics'}));
