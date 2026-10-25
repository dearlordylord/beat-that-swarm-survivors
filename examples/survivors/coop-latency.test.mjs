// Controller boundary checks with the actual compiled Bend predictor. There is
// deliberately no guest authoritative world in this harness.
import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFile } from 'node:fs/promises';
import { pathToFileURL, fileURLToPath } from 'node:url';
import path from 'node:path';
const modules = process.env.COOP_LATENCY_MODULE_DIR || fileURLToPath(new URL('./dist/web/dist',import.meta.url));
const Prediction = (await import(pathToFileURL(path.join(modules,'coop-prediction.mjs')))).default;
const source = (await readFile(new URL('./coop-browser.mjs',import.meta.url),'utf8')).replace(/^import .*;\n/gm,'');
function freeze(value) { if(value&&typeof value==='object'){for(const child of Object.values(value))freeze(child);Object.freeze(value);}return value; }
function harness(WeaponForecast,WeaponReconcile={rebase:(_prior,fresh)=>fresh}){
 let now=0, callbacks, receive;const displayed=[],sent=[];
 class UI {constructor(value){callbacks=value;}role(){}status(){}setChoicePending(){}present(frame){displayed.push(freeze(frame));}reset(){}}
 const channel={send:async text=>sent.push(text),join:async()=>receive({type:'connected',peerId:'host'}),close(){}};
 const context=vm.createContext({Prediction,WeaponForecast,WeaponReconcile,Set,Protocol:{encode:JSON.stringify},CoopTransport:{create:async callback=>{receive=callback;return channel;}},CoopUI:UI,
  Worker:class {constructor(){throw Error('Guest must not construct an authoritative world');}},
  performance:{now:()=>now},crypto:{getRandomValues:array=>array},Uint32Array,TextDecoder,URL,Math,Number,JSON,Boolean,
  location:{href:'https://fixture.invalid/coop.html?session=123'},setInterval:()=>1,clearInterval(){},addEventListener(){},console});
 vm.runInContext(source,context);
 return {displayed,sent,get callbacks(){return callbacks;},async join(){await callbacks.onJoin('ticket',{character:0,arcana:0,meta:0,allowedWeapons:1},{session:123});},
  observe(frame,observationSeq,receipt={$:'Receipt',seq:0,steps:0,x:1,y:1,expired:false}){receive({type:'message',bytes:new TextEncoder().encode(JSON.stringify({type:'frame',predictionModel:'input-ticks-weapons-v1',frame,observationSeq,receipt}))});},
  draw(at){now=at;return callbacks.onDisplay(displayed.at(-1),now);},at(value){now=value;},
 };
}
function frame(overrides={}){return {runId:'run',stage:0,ownPlayerId:1,phase:0,tick:10,px:7200,py:7200,stepDistance:2.5,predictionAllowed:true,
 hp:70,maxHp:70,xp:4,level:1,gold:7,offers:[],weapons:[1],bodies:[[7300,7300,0,0,12,12,4,100,6]],
 players:[{id:0,px:7100,py:7100,hp:60,character:0},{id:1,px:overrides.px??7200,py:overrides.py??7200,hp:70,character:1}],...overrides};}
test('predicted local rendering preserves the authoritative observation and every remote/gameplay field',async()=>{
 const h=harness();await h.join();h.observe(frame(),1);const authority=h.displayed.at(-1),before=JSON.stringify(authority);
 h.callbacks.onInput({x:1,y:0});const display=h.draw(17);
 assert.ok(display.px>authority.px,'local camera responds before any host reply');
 assert.ok(display.players[1].px>authority.players[1].px,'local player responds before host reply');
 assert.equal(display.px-authority.px,display.players[1].px-authority.players[1].px);
 assert.equal(JSON.stringify(authority),before,'frozen received authority must remain unchanged');
 assert.equal(display.players[0],authority.players[0],'remote actor remains the received/interpolated actor');
 for(const key of ['tick','phase','hp','maxHp','xp','level','gold','offers','weapons','bodies'])assert.deepEqual(display[key],authority[key],key+' is never locally simulated');
 assert.equal(h.displayed.length,1,'prediction did not fabricate an authoritative snapshot');
});
test('observed reward pause immediately disables prediction without changing the bank or offers',async()=>{
 const h=harness();await h.join();h.observe(frame(),1);h.callbacks.onInput({x:1,y:0});h.draw(17);
 h.at(18);h.observe(frame({phase:1,predictionAllowed:false,px:7202.5,offers:[{kind:0,id:2}]}),2);
 h.callbacks.onInput({x:-1,y:0});const display=h.draw(100),authority=h.displayed.at(-1);
 assert.equal(display.px,7202.5);assert.equal(display.py,7200);assert.equal(display.gold,7);
 assert.equal(display.offers,authority.offers);assert.equal(display.phase,1);
 assert.equal(JSON.stringify(h.draw(200)),JSON.stringify(display),'held input cannot move a paused display');
});
test('stale observation cannot rewind a reconciled display or reenable a paused player',async()=>{
 const h=harness();await h.join();h.observe(frame(),1);h.at(1);
 h.observe(frame({phase:1,predictionAllowed:false,px:7205}),3);
 h.observe(frame({px:1000,predictionAllowed:true,phase:0}),2);
 assert.equal(h.displayed.length,2,'older frame must not reach UI');
 h.callbacks.onInput({x:1,y:0});const display=h.draw(100);
 assert.equal(display.phase,1);assert.equal(display.px,7205);
});

test('duplicate observation is rejected before replacing authority or advancing prediction clocks',async()=>{
 const h=harness();await h.join();h.observe(frame(),1);h.callbacks.onInput({x:1,y:0});h.draw(17);
 h.at(18);h.observe(frame({phase:1,predictionAllowed:false,px:1000}),1);
 assert.equal(h.displayed.length,1);
 const display=h.draw(34);assert.equal(display.phase,0);assert.ok(display.px>7200);
});
test('a new reward round resets pre-pause history even when the paused snapshot was coalesced',async()=>{
 const h=harness();await h.join();h.observe(frame({roundId:0}),1);h.callbacks.onInput({x:1,y:0});h.draw(34);
 h.at(35);h.observe(frame({roundId:1,px:7210,predictionAllowed:true,phase:0}),3);
 const display=h.draw(35);assert.equal(display.px,7210,'resumed authority is the new anchor without old pending replay');
 assert.equal(display.players[1].px,7210);
 const next=h.draw(52);assert.ok(next.px>7210,'fresh current input can resume on the next local tick');
});

test('guest sends one numbered movement per fixed step, never a held-state heartbeat segment',async()=>{
 const h=harness();await h.join();h.observe(frame({roundId:4}),1);
 h.callbacks.onInput({x:1,y:0});
 assert.equal(h.sent.map(JSON.parse).filter(command=>command.action.$==='MovementTick').length,0,'keydown does not invent an extra simulation tick');
 h.draw(17);h.draw(20);h.draw(34);
 const ticks=h.sent.map(JSON.parse).filter(command=>command.action.$==='MovementTick');
 assert.equal(ticks.length,2);assert.equal(ticks[1].seq,ticks[0].seq+1);
 for(const command of ticks)assert.deepEqual(command.action,{$:'MovementTick',round:4,x:2,y:1});
 assert.equal(h.sent.map(JSON.parse).filter(command=>command.action.$==='Movement').length,0);
 const before=h.draw(34).px;
 h.at(35);h.observe(frame({roundId:4,px:7202.5}),2,{$:'Receipt',seq:ticks[0].seq,steps:1,x:2,y:1,expired:false});
 assert.equal(h.draw(35).px,before,'consumed exact prefix plus pending suffix preserves displayed position');
 h.at(36);h.observe(frame({roundId:4,px:7205}),3,{$:'Receipt',seq:ticks[1].seq,steps:1,x:2,y:1,expired:false});
 assert.equal(h.draw(36).px,before,'a batched ACK also leaves position unchanged');
});
test('disabled prediction and exhausted horizon send no new numbered input ticks',async()=>{
 const h=harness();await h.join();h.observe(frame(),1);h.callbacks.onInput({x:1,y:0});
 for(let now=17;now<1500;now+=17)h.draw(now);
 const ticks=h.sent.map(JSON.parse).filter(command=>command.action.$==='MovementTick');
 assert.equal(ticks.length,Prediction.horizon(),'unacknowledged horizon bounds both local and wire ticks');
 h.observe(frame({phase:1,predictionAllowed:false}),2);h.draw(1600);h.draw(1700);
 assert.equal(h.sent.map(JSON.parse).filter(command=>command.action.$==='MovementTick').length,ticks.length);
});

test('an older RAF timestamp cannot rewind a prediction clock sampled by a network message',async()=>{
 const h=harness();await h.join();h.observe(frame(),1);h.callbacks.onInput({x:1,y:0});
 h.draw(17);
 h.at(25);h.observe(frame(),2);
 h.draw(18); // Same browser frame's RAF can carry an older timestamp than the message handler.
 assert.equal(h.draw(33).px,7202.5,'only one fixed input tick fits in 33 milliseconds');
 assert.equal(h.sent.map(JSON.parse).filter(command=>command.action.$==='MovementTick').length,1);
 assert.equal(h.draw(34).px,7205,'the second input tick appears only at its actual fixed-step boundary');
});

test('weapon forecast replaces only own visuals after interpolation and never mutates received gameplay',async()=>{
 const calls=[];
 const WeaponForecast={
  receive:metadata=>metadata,
  forecast:(metadata,prediction)=>{calls.push({type:'forecast',metadata,age:prediction.age});return {metadata,steps:0};},
  advance:(state,x,y)=>{calls.push({type:'advance',x,y});return {...state,steps:state.steps+1};},
  render:state=>JSON.stringify({ownSeeds:[900],bodies:[[7200+state.steps,7200,1,0,8,8,state.steps,901,6,'player1:volley7:slot0',1]]}),
 };
 const h=harness(WeaponForecast);await h.join();
 const ownShot=[7000,7200,1,0,8,8,3,900,6],remoteShot=[7100,7200,1,0,8,8,3,800,6],enemy=[7300,7300,0,0,12,12,4,100,6];
 h.observe(frame({weaponForecast:{$:'Frame',player:1},bodies:[enemy,remoteShot,ownShot]}),1);
 const authority=h.displayed.at(-1),before=JSON.stringify(authority);
 h.callbacks.onInput({x:1,y:0});const display=h.draw(17);
 assert.equal(calls.filter(call=>call.type==='advance').length,1,'weapons advance with the same one local movement tick');
 assert.deepEqual(calls.find(call=>call.type==='advance'),{type:'advance',x:2,y:1});
 assert.equal(display.bodies.length,3,'own authoritative visual is replaced rather than duplicated');
 assert.equal(display.bodies[0],authority.bodies[0],'enemy is still the authoritative object');
 assert.equal(display.bodies[1],authority.bodies[1],'remote shot is still the authoritative object');
 assert.equal(display.bodies[2][9],'player1:volley7:slot0','Bend supplies semantic visual identity');
 assert.equal(display.bodies[2][10],1);
 assert.equal(JSON.stringify(authority),before,'forecast cannot alter the frozen host frame');
 for(const key of ['tick','phase','hp','maxHp','xp','level','gold','offers','weapons'])assert.deepEqual(display[key],authority[key]);
 assert.equal(h.displayed.length,1,'weapon rendering cannot fabricate a gameplay observation');
 h.at(18);h.observe(frame({phase:1,predictionAllowed:false,weaponForecast:{$:'Frame',player:1},bodies:[enemy,remoteShot,ownShot]}),2);
 const paused=h.draw(100);
 assert.equal(paused.bodies,h.displayed.at(-1).bodies,'pause removes speculative visuals immediately');
 assert.equal(calls.filter(call=>call.type==='advance').length,1,'paused prediction cannot advance weapons');
});

test('weapon forecast is rebuilt from each accepted anchor and only the reconciled pending suffix',async()=>{
 const replayed=[];
 const WeaponForecast={
  receive:metadata=>metadata,
  forecast:(metadata,prediction)=>{replayed.push({metadata,age:prediction.age});return {metadata};},
  advance:state=>state,
  render:()=>JSON.stringify({ownSeeds:[],bodies:[]}),
 };
 const h=harness(WeaponForecast);await h.join();
 h.observe(frame({weaponForecast:{anchor:1},roundId:0}),1);h.callbacks.onInput({x:1,y:0});h.draw(34);
 const ticks=h.sent.map(JSON.parse).filter(command=>command.action.$==='MovementTick');
 h.at(35);h.observe(frame({weaponForecast:{anchor:2},roundId:0,px:7202.5}),2,{$:'Receipt',seq:ticks[0].seq,steps:1,x:2,y:1,expired:false});
 assert.deepEqual(replayed.at(-1),{metadata:{anchor:2},age:1},'one acknowledged input is absent from weapon replay');
 h.at(36);h.observe(frame({weaponForecast:{anchor:3},roundId:1,px:7210}),3);
 assert.deepEqual(replayed.at(-1),{metadata:{anchor:3},age:0},'reward-epoch reset cannot forecast pre-pause movement');
 h.observe(frame({weaponForecast:{anchor:0},roundId:0}),2);
 assert.equal(replayed.length,3,'stale anchor never reaches weapon forecast');
});

test('continuing weapon trajectories are reconciled in Bend only within the same active prediction epoch',async()=>{
 const rebased=[];
 const WeaponForecast={
  receive:metadata=>metadata,
  forecast:(metadata,prediction)=>({anchor:metadata.anchor,steps:prediction.age}),
  advance:state=>({...state,steps:state.steps+1}),
  render:()=>JSON.stringify({ownSeeds:[],bodies:[]}),
 };
 const WeaponReconcile={rebase:(prior,fresh)=>{rebased.push({prior,fresh});return {...fresh,retained:true};}};
 const h=harness(WeaponForecast,WeaponReconcile);await h.join();
 h.observe(frame({roundId:0,weaponForecast:{anchor:1}}),1);h.callbacks.onInput({x:1,y:0});h.draw(17);
 h.at(18);h.observe(frame({roundId:0,weaponForecast:{anchor:2}}),2);
 assert.deepEqual(rebased,[{prior:{anchor:1,steps:1},fresh:{anchor:2,steps:1}}]);
 h.at(19);h.observe(frame({roundId:1,weaponForecast:{anchor:3}}),3);
 assert.equal(rebased.length,1,'new reward epoch must not inherit prior flight history');
 h.at(20);h.observe(frame({roundId:1,phase:1,predictionAllowed:false,weaponForecast:{anchor:4}}),4);
 assert.equal(rebased.length,1,'pause must not retain speculative trajectories');
});
