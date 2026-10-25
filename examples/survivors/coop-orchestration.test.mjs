import { test } from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFile } from 'node:fs/promises';
const workerSource = (await readFile(new URL('./coop-worker.mjs', import.meta.url), 'utf8')).replace(/^import .*;\n/gm, '');
const browserSource = (await readFile(new URL('./coop-browser.mjs', import.meta.url), 'utf8')).replace(/^import .*;\n/gm, '');
const setup = { character:0, meta:0, stage:0, mode:0, arcana:0, allowedWeapons:1 };
function workerHarness() {
  let now = 0, coreTick = 0;
  const calls = [], output = [], timers = new Map();
  let id = 0;
  const options = { rejectJoin:false, rejectUnlocks:false, accept:true, paused:false };
  const result = () => ({ $:'CorePacket', state:{tick:coreTick}, frame:JSON.stringify({tick:coreTick}) });
  const Game = Object.fromEntries(['core_start','core_configure','core_configure_unlocks','core_observe','core_choose','core_disconnect'].map(name => [name,(...args)=> {
    calls.push({name,args});
    if (name==='core_configure_unlocks' && args[1]===1 && options.rejectUnlocks)
      return {$:'CoreRejected',state:args[0],message:'bad unlocks'};
    return result();
  }]));
  Game.core_join = (...args) => { calls.push({name:'core_join',args}); return options.rejectJoin ? {$:'CoreRejected',state:args[0],message:'bad setup'} : result(); };
  Game.core_step = (...args) => { calls.push({name:'core_step',args}); if (!options.paused) coreTick++; return {...result(),frame:JSON.stringify({tick:coreTick,phase:options.paused?1:0,advanced:!options.paused})}; };
  const Session = {
    receipt_fresh:()=>({$:'Receipt',seq:0,steps:0,x:1,y:1,expired:false}),
    receipt_step:(receipt,state,player)=>{calls.push({name:'receipt_step',args:[receipt,state,player]});return {...receipt,steps:receipt.steps+1};},
    fresh:session=>({session}), receive:(state,peer,command)=> {
      calls.push({name:'receive',args:[peer,command]}); return {state,accepted:options.accept};
    }, clock:state=>state, directions:()=>({x0:0,y0:0,x1:0,y1:0}),
    applied:(tick,state)=> {calls.push({name:'applied',args:[tick]});return state;}, disconnect:(player,state)=> { calls.push({name:'session_disconnect',args:[player]}); return state; },
  };
  const context = vm.createContext({Game,Session,Protocol:{decode:text=> {try{return {$:'Some',value:JSON.parse(text)};}catch{return {$:'None'};}}},
    performance:{now:()=>now}, postMessage:message=>output.push(message), close(){},
    setInterval:callback=> {timers.set(++id,callback);return id;}, clearInterval:key=>timers.delete(key)});
  vm.runInContext(workerSource,context);
  const send = data=>context.onmessage({data});
  const command = action=>send({type:'command',player:1,text:JSON.stringify({action})});
  return {options,calls,output,timers,send,command,
    init:()=>send({type:'init',setup,session:1,seed:2}),
    advance:elapsed=> {now+=elapsed;for(const callback of [...timers.values()])callback();},
  };
}
test('worker owns fixed clock without requestAnimationFrame and discards suspension backlog',()=>{
  const h=workerHarness();h.init();h.advance(1000);
  assert.equal(h.calls.filter(c=>c.name==='core_step').length,0,'lobby must not simulate');
  h.command({$:'Setup',...setup});h.advance(10000);
  const steps=h.calls.filter(c=>c.name==='core_step').length;
  assert.ok(steps>=3&&steps<=4,'ten-second suspension must run at most four steps');
  h.advance(17);assert.ok(h.calls.filter(c=>c.name==='core_step').length<=steps+2);
});
test('Bend admission is consulted before any setup or reward effect',()=>{
  const h=workerHarness();h.init();h.options.accept=false;
  h.command({$:'Setup',...setup});h.command({$:'Choice',round:1,index:0});h.advance(50);
  assert.equal(h.calls.filter(c=>['core_join','core_choose','core_step'].includes(c.name)).length,0);
  assert.equal(h.calls.filter(c=>c.name==='receive').length,2);
});
test('rejected guest setup never starts world',()=>{
  const h=workerHarness();h.init();h.options.rejectJoin=true;
  h.command({$:'Setup',...setup});h.advance(50);
  assert.equal(h.output.filter(e=>e.type==='started').length,0);
  assert.equal(h.calls.filter(c=>c.name==='core_step').length,0);
});
test('guest unlock configuration must succeed before match begins',()=>{
  const h=workerHarness();h.init();h.options.rejectUnlocks=true;
  h.command({$:'Setup',...setup});h.advance(50);
  assert.equal(h.output.filter(e=>e.type==='started').length,0);
  assert.equal(h.calls.filter(c=>c.name==='core_step').length,0);
});
test('guest disconnect removes guest in both Bend boundaries; host scheduler continues',()=>{
  const h=workerHarness();h.init();h.command({$:'Setup',...setup});h.send({type:'disconnect'});h.advance(34);
  assert.equal(h.calls.filter(c=>c.name==='session_disconnect').length,1);
  assert.equal(h.calls.filter(c=>c.name==='core_disconnect').length,1);
  assert.ok(h.calls.some(c=>c.name==='core_step'));
});
test('initializing twice cannot install two authoritative clocks',()=>{
  const h=workerHarness();h.init();h.init();assert.equal(h.timers.size,1);
});
function browserHarness() {
  let now=0, handlers, id=0;
  const transports=[],workers=[],timers=new Map(),statuses=[],pendingChoices=[],options={createWait:[],sendWait:[]};
  class UI { constructor(h){handlers=h;} role(){} setChoicePending(value){pendingChoices.push(value);} status(...args){statuses.push(args);} present(){} invitation(){} reset(){} }
  class Worker { constructor(){this.messages=[];workers.push(this);} postMessage(m){this.messages.push(m);} terminate(){this.terminated=true;} }
  const context=vm.createContext({Protocol:{encode:JSON.stringify},CoopTransport:{create:async callback=> {
    const t={callback,sent:[],invitation:()=> 'ticket',join:async()=>{},send:async text=>{t.sent.push(text);await options.sendWait[transports.indexOf(t)];},close(){t.closed=true;}};
    transports.push(t);await options.createWait[transports.length-1];return t;
  }},CoopUI:UI,Worker, TextDecoder,Uint32Array,URL,Math,Number,JSON,
  crypto:{getRandomValues:a=>{a[0]=123;return a;}}, location:{href:'https://example.com/?session=123'},performance:{now:()=>now},
  setInterval:callback=>{timers.set(++id,callback);return id;},clearInterval:key=>timers.delete(key),addEventListener(){},console});
  vm.runInContext(browserSource,context);
  return {transports,workers,statuses,pendingChoices,options,get handlers(){return handlers;},
    interval:()=>{now+=50;for(const cb of [...timers.values()])cb();},
  };
}
test('host continues local movement and choice commands after guest departure',async()=>{
  const h=browserHarness();await h.handlers.onHost(setup);
  h.transports[0].callback({type:'connected',peerId:'guest'});
  h.transports[0].callback({type:'disconnected',peerId:'guest'});
  h.handlers.onInput({x:1,y:0});h.interval();h.handlers.onChoice({round:1,index:0});
  const commands=h.workers[0].messages.filter(m=>m.type==='command').map(m=>JSON.parse(m.text).action.$);
  assert.ok(commands.includes('Movement'));assert.ok(commands.includes('Choice'));
});
test('callbacks from a departed transport cannot control the next run worker',async()=>{
  const h=browserHarness();await h.handlers.onHost(setup);const old=h.transports[0];
  await h.handlers.onHost(setup);const current=h.workers[1];
  old.callback({type:'message',peerId:'old',bytes:new TextEncoder().encode('old command')});
  old.callback({type:'disconnected',peerId:'old'});
  assert.equal(current.messages.filter(m=>['command','disconnect'].includes(m.type)).length,0);
});

test('overlapping async host creation closes obsolete endpoint without creating obsolete worker',async()=>{
  const h=browserHarness();let release;
  h.options.createWait[0]=new Promise(resolve=>{release=resolve;});
  const old=h.handlers.onHost(setup);
  await h.handlers.onHost(setup);release();await old;
  assert.equal(h.transports[0].closed,true);
  assert.equal(h.transports[1].closed,undefined);
  assert.equal(h.workers.length,1);
});
test('stale worker messages cannot update a replacement session',async()=>{
  const h=browserHarness();await h.handlers.onHost(setup);const old=h.workers[0];
  await h.handlers.onHost(setup);const before=h.statuses.length;
  old.onmessage({data:{type:'error',message:'obsolete'}});
  assert.equal(h.statuses.length,before);
});

test('only an advanced Bend step acknowledges movement application; paused frames do not',()=>{
  const h=workerHarness();h.init();h.command({$:'Setup',...setup});
  h.options.paused=true;h.advance(100);
  assert.ok(h.calls.some(c=>c.name==='core_step'));
  assert.equal(h.calls.filter(c=>c.name==='applied').length,0);
  h.options.paused=false;h.advance(34);
  const steps=h.calls.filter(c=>c.name==='applied');
  assert.ok(steps.length>=1);assert.equal(steps[0].args[0],1);
});
test('host closes Iroh endpoint after guest departure, retaining only local worker',async()=>{
  const h=browserHarness();await h.handlers.onHost(setup);
  h.transports[0].callback({type:'connected',peerId:'guest'});
  h.transports[0].callback({type:'disconnected',peerId:'guest'});
  assert.equal(h.transports[0].closed,true);
  assert.equal(h.workers[0].terminated,undefined);
});
test('stale worker error cannot replace current session status',async()=>{
  const h=browserHarness();await h.handlers.onHost(setup);const old=h.workers[0];
  await h.handlers.onHost(setup);const before=h.statuses.length;
  old.onerror({message:'obsolete'});assert.equal(h.statuses.length,before);
});
test('old in-flight snapshot cannot consume or block the new session snapshot queue',async()=>{
  const h=browserHarness();let release;
  h.options.sendWait[0]=new Promise(resolve=>{release=resolve;});
  await h.handlers.onHost(setup);const old=h.transports[0],oldWorker=h.workers[0];
  old.callback({type:'connected',peerId:'guest'});
  oldWorker.onmessage({data:{type:'remote-frame',frame:{tick:1},admission:{}}});
  oldWorker.onmessage({data:{type:'remote-frame',frame:{tick:2},admission:{}}});
  await h.handlers.onHost(setup);const current=h.transports[1],worker=h.workers[1];
  current.callback({type:'connected',peerId:'newguest'});
  worker.onmessage({data:{type:'remote-frame',frame:{tick:7},admission:{}}});
  release();await new Promise(resolve=>setImmediate(resolve));
  assert.deepEqual(old.sent.map(text=>JSON.parse(text).frame.tick),[1]);
  assert.deepEqual(current.sent.map(text=>JSON.parse(text).frame.tick),[7]);
  worker.onmessage({data:{type:'remote-frame',frame:{tick:8},admission:{}}});
  await new Promise(resolve=>setImmediate(resolve));
  assert.deepEqual(current.sent.map(text=>JSON.parse(text).frame.tick),[7,8]);
});

test('failed guest reward delivery permits a fresh-sequence retry',async()=>{
 const h=browserHarness();await h.handlers.onJoin('ticket',setup,{session:123});const t=h.transports[0];
 t.callback({type:'connected',peerId:'host'});await new Promise(resolve=>setImmediate(resolve));
 const attempts=[];t.send=async text=>{attempts.push(JSON.parse(text));throw Error('write failed');};
 h.handlers.onChoice({round:4,index:0});await new Promise(resolve=>setImmediate(resolve));
 assert.equal(h.pendingChoices.at(-1),false);
 h.handlers.onChoice({round:4,index:0});await new Promise(resolve=>setImmediate(resolve));
 assert.equal(attempts.length,2);assert.ok(attempts[1].seq>attempts[0].seq);
});
test('oversized guest command is refused before entering worker mailbox',async()=>{
 const h=browserHarness();await h.handlers.onHost(setup);const t=h.transports[0];t.callback({type:'connected',peerId:'guest'});
 t.callback({type:'message',bytes:new TextEncoder().encode('x'.repeat(161))});
 assert.equal(h.workers[0].messages.filter(m=>m.type==='command').length,0);
 assert.equal(t.closed,true);assert.ok(h.workers[0].messages.some(m=>m.type==='disconnect'));
});
test('worker mailbox is bounded and consumed acknowledgments release capacity',async()=>{
 const h=browserHarness();await h.handlers.onHost(setup);const t=h.transports[0],w=h.workers[0];t.callback({type:'connected',peerId:'guest'});
 const send=()=>t.callback({type:'message',bytes:new TextEncoder().encode('command')});
 for(let i=0;i<64;i++)send();assert.equal(w.messages.filter(m=>m.type==='command').length,64);
 const id=w.messages.find(m=>m.type==='command').deliveryId;w.onmessage({data:{type:'command-consumed',deliveryId:id}});
 send();assert.equal(t.closed,undefined);assert.equal(w.messages.filter(m=>m.type==='command').length,65);
 send();assert.equal(t.closed,true);assert.equal(w.messages.filter(m=>m.type==='command').length,65);
 assert.equal(w.terminated,undefined);
});

test('input change dispatches immediately without advancing the heartbeat timer',async()=>{
 const h=browserHarness();await h.handlers.onHost(setup);
 h.handlers.onInput({x:1,y:0});
 const commands=h.workers[0].messages.filter(message=>message.type==='command');
 assert.equal(commands.length,1);
 assert.deepEqual(JSON.parse(commands[0].text).action,{$:'Movement',x:2,y:1});
 h.handlers.onInput({x:0,y:0});
 const released=h.workers[0].messages.filter(message=>message.type==='command');
 assert.equal(released.length,2);
 assert.deepEqual(JSON.parse(released[1].text).action,{$:'Movement',x:1,y:1});
});
test('only actual simulation steps advance guest prediction receipts',()=>{
 const h=workerHarness();h.init();h.command({$:'Setup',...setup});h.advance(34);
 const before=h.calls.filter(call=>call.name==='receipt_step').length;assert.ok(before>0);
 h.options.paused=true;h.advance(34);
 assert.equal(h.calls.filter(call=>call.name==='receipt_step').length,before);
});

test('pause and resume observations have unique ordered IDs even without a gameplay tick',()=>{
 const h=workerHarness();h.init();h.command({$:'Setup',...setup});
 h.command({$:'Choice',round:1,index:0});
 const frames=h.output.filter(message=>message.type==='remote-frame');
 assert.ok(frames.length>=2);
 assert.equal(frames[0].frame.tick,frames[1].frame.tick);
 assert.ok(frames[1].observationSeq>frames[0].observationSeq);
 h.advance(17);
 assert.ok(h.calls.filter(call=>call.name==='receipt_step').every(call=>call.args[2]===1));
});
