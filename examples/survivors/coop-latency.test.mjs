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
function harness(){
 let now=0, callbacks, receive;const displayed=[],sent=[];
 class UI {constructor(value){callbacks=value;}role(){}status(){}setChoicePending(){}present(frame){displayed.push(freeze(frame));}reset(){}}
 const channel={send:async text=>sent.push(text),join:async()=>receive({type:'connected',peerId:'host'}),close(){}};
 const context=vm.createContext({Prediction,Protocol:{encode:JSON.stringify},CoopTransport:{create:async callback=>{receive=callback;return channel;}},CoopUI:UI,
  Worker:class {constructor(){throw Error('Guest must not construct an authoritative world');}},
  performance:{now:()=>now},crypto:{getRandomValues:array=>array},Uint32Array,TextDecoder,URL,Math,Number,JSON,Boolean,
  location:{href:'https://fixture.invalid/coop.html?session=123'},setInterval:()=>1,clearInterval(){},addEventListener(){},console});
 vm.runInContext(source,context);
 return {displayed,sent,get callbacks(){return callbacks;},async join(){await callbacks.onJoin('ticket',{character:0,arcana:0,meta:0,allowedWeapons:1},{session:123});},
  observe(frame,observationSeq,receipt={$:'Receipt',seq:0,steps:0,x:1,y:1,expired:false}){receive({type:'message',bytes:new TextEncoder().encode(JSON.stringify({type:'frame',frame,observationSeq,receipt}))});},
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
