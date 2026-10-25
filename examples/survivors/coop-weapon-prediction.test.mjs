// Actual authority -> detached Bend forecast -> renderer rows, without a guest world.
import test from 'node:test';import assert from 'node:assert/strict';
import path from 'node:path';import {pathToFileURL,fileURLToPath} from 'node:url';
const dir=process.env.COOP_LATENCY_MODULE_DIR||fileURLToPath(new URL('./dist/web/dist',import.meta.url));
const load=async name=>(await import(pathToFileURL(path.join(dir,name+'.mjs')))).default;
const [Core,Forecast,Prediction]=await Promise.all(['coop-core','coop-weapon-prediction','coop-prediction'].map(load));
function observation(ticks){let state=Core.core_start(0,0,1).state;state=Core.core_configure(state,0,0,0).state;state=Core.core_join(state,0,0,0).state;for(let i=0;i<ticks;i++)state=Core.core_step(state,0,0,0,0).state;return JSON.parse(Core.core_observe(state,1).frame);}
const render=s=>JSON.parse(Forecast.render(s));
function freeze(v){if(v&&typeof v==='object'){Object.values(v).forEach(freeze);Object.freeze(v);}return v;}
test('replayed local movement forecasts a new volley at the displayed owner, not the old server position',()=>{
 const frame=observation(100);assert.ok(frame.weaponForecast);freeze(frame);const saved=JSON.stringify(frame);
 let prediction=Prediction.fresh(frame.px,frame.py,frame.stepDistance,true);
 for(let seq=1;seq<=21;seq++)prediction=Prediction.tick(Prediction.command(prediction,seq,2,1));
 const output=render(Forecast.forecast(frame.weaponForecast,prediction));
 assert.equal(output.px,Prediction.view(prediction).x);assert.equal(output.py,Prediction.view(prediction).y);
 const newborn=output.bodies.filter(b=>b[6]===0&&b[3]===0);assert.ok(newborn.length>0,'shared Bend cooldown emitted the future volley');
 for(const body of newborn){assert.ok(Math.hypot(body[0]-output.px,body[1]-output.py)<=frame.stepDistance+.01);assert.equal(body[10],1);assert.equal(typeof body[9],'string');}
 assert.equal(JSON.stringify(frame),saved,'forecast cannot mutate the authoritative observation');
});
test('turning the owner does not drag an already flying default projectile',()=>{
 const frame=observation(2),initial=frame.weaponForecast;const before=render(initial);
 const right=render(Forecast.advance(initial,2,1)),left=render(Forecast.advance(initial,0,1));
 assert.ok(right.px>left.px);assert.ok(before.bodies.length>0);
 for(const body of before.bodies){const a=right.bodies.find(b=>b[9]===body[9]),b=left.bodies.find(b=>b[9]===body[9]);assert.ok(a&&b);assert.equal(a[0],b[0]);assert.equal(a[1],b[1]);assert.equal(a[6],body[6]+1);}
});
test('an empty pending suffix is a zero-step weapon observation',()=>{
 const frame=observation(25),initial=frame.weaponForecast,p=Prediction.fresh(frame.px,frame.py,frame.stepDistance,true);
 assert.deepEqual(render(Forecast.forecast(initial,p)),render(initial));
});
function nativeList(values){return values.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});}
test('every base weapon reuses the shared firing and trajectory code in a detached forecast',()=>{
 const initial=observation(0).weaponForecast;
 for(let weapon=0;weapon<24;weapon++){
  let state={...initial,run:{...initial.run,weapons:nativeList(Array.from({length:24},(_,i)=>Number(i===weapon)))}};
  state=Forecast.advance(state,2,1);const born=render(state);
  assert.ok(born.bodies.length>0,`weapon${weapon} fires on its shared first volley`);
  for(const body of born.bodies){assert.equal(body[2],1);assert.equal(body[10],1);assert.ok(body.slice(0,2).every(Number.isFinite));}
  for(let tick=0;tick<12;tick++)state=Forecast.advance(state,tick<6?2:0,1);
  const advanced=render(state);for(const body of advanced.bodies)assert.ok(body.slice(0,2).every(Number.isFinite));
  assert.equal(advanced.tick,13);
 }
});
test('paused and dead forecast frames cannot produce movement or a volley',()=>{
 const initial=observation(0).weaponForecast;
 for(const change of [{phase:1},{hp:0}]){const stopped={...initial,run:{...initial.run,...change}};assert.deepEqual(Forecast.advance(stopped,2,1),stopped);}
});
const Reconcile=await load('coop-weapon-reconcile');
const fromNative=rows=>{const values=[];for(let row=rows;row.$==='Con';row=row.tail)values.push(row.head);return values;};
test('a new aim observation cannot teleport an already displayed semantic shot',()=>{
 const previous=observation(2).weaponForecast;
 const shots=fromNative(previous.shots);
 const shifted={...previous,shots:nativeList(shots.map(s=>({...s,body:{...s.body,x:s.body.x+194,y:s.body.y-100,seed:s.body.seed+100}})))};
 const rebased=render(Reconcile.rebase(previous,shifted)),old=render(previous);
 for(const body of old.bodies){const next=rebased.bodies.find(b=>b[9]===body[9]);assert.ok(next);assert.equal(next[0],body[0]);assert.equal(next[1],body[1]);assert.equal(next[7],body[7]+100,'fresh physical allocation retained independently from trajectory');}
});
test('many volley lanes and birth ticks retain independent trajectories after reconciliation',()=>{
 const previous=observation(2).weaponForecast,seed=fromNative(previous.shots)[0];
 const rows=Array.from({length:32},(_,i)=>({...seed,body:{...seed.body,x:7300+i,y:7100-i,age:i%4,seed:513+i*2},motion:{...seed.motion,ownerBase:i%3,logicalSlot:65536+Math.floor(i/4)}}));
 const prior={...previous,run:{...previous.run,tick:40},shots:nativeList(rows)};
 const fresh={...prior,shots:nativeList(rows.map(s=>({...s,body:{...s.body,x:9000,y:9000}})))};
 const rebased=render(Reconcile.rebase(prior,fresh));
 assert.equal(rebased.bodies.length,rows.length);
 for(const original of render(prior).bodies){const actual=rebased.bodies.find(b=>b[9]===original[9]);assert.ok(actual);assert.equal(actual[0],original[0]);assert.equal(actual[1],original[1]);}
});
test('new generations use fresh births and confirmed removals do not resurrect old shots',()=>{
 const previous=observation(40).weaponForecast,fresh=Forecast.advance(previous,2,1),output=render(Reconcile.rebase(previous,fresh));
 const newborn=output.bodies.filter(b=>b[6]===0);assert.ok(newborn.length);for(const shot of newborn)assert.ok(Math.abs(shot[0]-output.px)<=2.51);
 const empty={...fresh,shots:nativeList([])};assert.equal(render(Reconcile.rebase(previous,empty)).bodies.length,0);
});
test('a burst of authoritative clock updates cannot age a visible projectile twice',()=>{
 const previous=observation(2).weaponForecast;
 const fresh={...previous,run:{...previous.run,tick:previous.run.tick+9},shots:nativeList(fromNative(previous.shots).map(s=>({...s,body:{...s.body,x:s.body.x+67.5,age:s.body.age+9}})))};
 const old=render(previous),rebased=Reconcile.rebase(previous,fresh),current=render(rebased);
 for(const shot of old.bodies){const actual=current.bodies.find(b=>b[9]===shot[9]);assert.ok(actual,'birth identity is independent of visual age');assert.equal(actual[0],shot[0]);assert.equal(actual[1],shot[1]);assert.equal(actual[6],shot[6]);}
 const next=render(Forecast.advance(rebased,2,1));
 for(const shot of current.bodies){const actual=next.bodies.find(b=>b[9]===shot[9]);assert.ok(actual);assert.equal(actual[6],shot[6]+1,'only the local fixed tick advances flight');assert.ok(Math.hypot(actual[0]-shot[0],actual[1]-shot[1])<=7.51);}
});
test('recycling a physical projectile slot creates a new immutable birth identity',()=>{
 let frame=observation(2).weaponForecast;
 frame={...frame,run:{...frame.run,tick:40},shots:nativeList(fromNative(frame.shots).map(s=>({...s,motion:{...s.motion,life:1}})))};
 frame=Forecast.advance(frame,2,1);
 assert.ok(render(frame).bodies.some(b=>b[9].includes(':41:')));
 frame={...frame,run:{...frame.run,tick:80},shots:nativeList(fromNative(frame.shots).map(s=>({...s,motion:{...s.motion,life:1}})))};
 const output=render(Forecast.advance(frame,2,1));
 const recycled=output.bodies.find(b=>b[7]===513);assert.ok(recycled);assert.ok(recycled[9].includes(':81:'),'new life must not inherit the first insertion at birth1');
});
