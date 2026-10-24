// Real Bend shared-world integration. This file never substitutes a mock game.
import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';
const directory=process.env.COOP_GAME_TEST_DIST;
if(!directory)throw Error('Run bash examples/survivors/check-coop-game.sh');
const load=async name=>(await import(pathToFileURL(`${directory}/${name}.mjs`))).default;
const [Game,Session,Protocol]=await Promise.all(['coop-core','coop-session','coop-protocol'].map(load));
const command=(session,player,seq,action)=>({$:'Command',session,player,seq,intendedTick:0,action});
const movement=(session,player,seq,x,y)=>command(session,player,seq,{$:'Movement',x,y});
function random(seed){let value=seed>>>0;return n=>{value=(Math.imul(value,1664525)+1013904223)>>>0;return value%n;};}
function serializable(value){
  return JSON.stringify(value,(_key,item)=>{
    if(typeof item==='function')throw Error('oracle refuses to omit an opaque closure from authoritative state');
    if(typeof item==='bigint')throw Error('oracle requires explicit encoding for a new big integer field');
    return item;
  });
}
const hash=value=>createHash('sha256').update(serializable(value)).digest('hex');
function fixture(seed,{forceLevel=false,guestArcana=1,gameModule=Game}={}){
  let state;
  function packet(result){
    assert.notEqual(result.$,'CoreFailed',result.message);
    assert.equal(result.$,'CorePacket',result.message);
    state=result.state;return result.frame?JSON.parse(result.frame):null;
  }
  packet(gameModule.core_start(0,0,seed));
  packet(gameModule.core_configure(state,0,0,0));
  packet(gameModule.core_configure_unlocks(state,0,16777215));
  packet(gameModule.core_join(state,1,0,guestArcana));
  packet(gameModule.core_configure_unlocks(state,1,16777215));
  if(forceLevel)state.shared.xp=state.shared.xpNeed;
  return {get state(){return state;},packet,
    invoke(name,...args){return packet(gameModule[name](state,...args));},
    control(name,...args){const result=gameModule[name](state,...args);assert.notEqual(result.$,'CoreFailed',result.message);state=result.state;return result.$;},
  };
}
function run({seed,clocks,schedule,forceLevel=false,autoChoices=false,gameModule=Game}){
  const game=fixture(seed,{forceLevel,gameModule}),log=[],trace=[],stats={accepted:0,rejected:0,coreRejected:0,choices:0,paused:0,steps:0,seenTwo:false,stepMs:0,observeMs:0,captureMs:0};
  let admission=Session.fresh(seed),frame,choiceRound=0;
  const work=schedule.map(event=>structuredClone(event));
  const sequence=[10000,10000];
  function observe(){const a=game.invoke('core_observe',0),b=game.invoke('core_observe',1);frame=a;return [a,b];}
  function deliver(event,at){
    if(event.kind==='disconnect'){
      admission=Session.disconnect(event.player,admission);
      if(event.player===1)game.control('core_disconnect',1);
      log.push({at,kind:'disconnect',player:event.player});return;
    }
    const decoded=Protocol.decode(event.wire);
    if(decoded.$!=='Some'){stats.rejected++;return;}
    const received=Session.receive(admission,event.peer,decoded.value);admission=received.state;
    if(!received.accepted){stats.rejected++;return;}
    stats.accepted++;log.push({at,kind:'command',peer:event.peer,wire:event.wire});
    const action=received.command.action;
    if(action.$==='Choice'){
      stats.choices++;
      if(game.control('core_choose',event.peer,action.round,action.index)==='CoreRejected')stats.coreRejected++;
    }
  }
  for(let at=0;at<clocks;at++){
    // Preserve sender arrival order among equal-clock deliveries. Reordering is
    // represented by their independently generated delivery clocks.
    for(const event of work)if(event.at===at)deliver(event,at);
    admission=Session.clock(admission);
    if(!admission.ended){
      const before=game.state.shared.tick;
      const move=Session.directions(admission);
      const stepStart=performance.now();
      game.invoke('core_step',move.x0,move.y0,move.x1,move.y1);
      stats.stepMs+=performance.now()-stepStart;
      const after=game.state.shared.tick;
      assert.ok(after===before || after===before+1,'the world advances at most once per clock with both inputs');
      if(after!==before){stats.steps++;admission=Session.applied(after,admission);}else stats.paused++;
    }
    const observeStart=performance.now();
    const observed=observe();
    stats.observeMs+=performance.now()-observeStart;
    stats.seenTwo ||= frame.players.length===2;
    if(autoChoices && frame.roundId>choiceRound && frame.requiredPlayers?.length){
      choiceRound=frame.roundId;
      for(const player of frame.requiredPlayers){
        const c=command(seed,player,++sequence[player],{$:'Choice',round:frame.roundId,index:0});
        const wire=Protocol.encode(c);
        // Delayed choices intentionally hold the shared barrier for different durations.
        work.push({at:at+2+player*5,kind:'command',peer:player,wire});
        work.push({at:at+3+player*5,kind:'command',peer:player,wire});
      }
    }
    // Test-only capture. This serializes all authoritative fields, not merely a
    // renderer packet, and never feeds a clone back into the affine simulation.
    const captureStart=performance.now();
    trace.push({at,state:hash(game.state),admission:hash(admission),views:hash(observed)});
    stats.captureMs+=performance.now()-captureStart;
  }
  return {log,trace,stats,finalState:serializable(game.state),finalAdmission:serializable(admission),frame};
}
function noisySchedule(seed,clocks){
  const r=random(seed),rows=[];
  for(let seq=1;seq<clocks/2;seq++){
    const peer=seq%2,c=movement(seed,peer,seq,r(3),r(3)),wire=Protocol.encode(c);
    if(r(6)===0)continue;
    const at=Math.min(clocks-1,seq*2+r(9));rows.push({at,kind:'command',peer,wire});
    if(r(4)===0)rows.push({at:Math.min(clocks-1,at+r(7)),kind:'command',peer,wire});
    if(r(8)===0)rows.push({at,kind:'command',peer:1-peer,wire});
  }
  rows.push({at:clocks-15,kind:'disconnect',player:1});
  rows.push({at:clocks-5,kind:'disconnect',player:0});
  return rows;
}

test('real shared world replay agrees at every clock under loss, jitter, duplicates, forged ownership and departure',()=>{
  let accepted=0,rejected=0,steps=0;
  for(const seed of [17,29,57]){
    const clocks=90;
    const first=run({seed,clocks,schedule:noisySchedule(seed,clocks)});
    const replay=run({seed,clocks,schedule:first.log});
    assert.deepEqual(replay.trace,first.trace,`accepted-log replay seed ${seed}`);
    assert.equal(replay.finalState,first.finalState,'all authoritative ECS values, handles, allocator and reward state');
    assert.equal(replay.finalAdmission,first.finalAdmission);
    assert.ok(first.stats.seenTwo,'two actual participants must be observed before guest departure');
    assert.notEqual(first.frame.players.find(p=>p.id===1)?.connected,true);
    accepted+=first.stats.accepted;rejected+=first.stats.rejected;steps+=first.stats.steps;
    console.log(JSON.stringify({scenario:'noisy-world',seed,first:first.stats,replay:replay.stats}));
  }
  assert.ok(accepted>20);assert.ok(rejected>10);assert.ok(steps>100);
});

test('reward pauses and duplicate/stale choices survive real-world accepted-log replay',()=>{
  const seed=87,clocks=35;
  const stale=command(seed,0,9000,{$:'Choice',round:999,index:0});
  const first=run({seed,clocks,forceLevel:true,autoChoices:true,schedule:[{at:0,kind:'command',peer:0,wire:Protocol.encode(stale)}]});
  const replay=run({seed,clocks,forceLevel:true,schedule:first.log});
  assert.deepEqual(replay.trace,first.trace);
  assert.equal(replay.finalState,first.finalState);
  assert.ok(first.stats.coreRejected>=1,'stale round must reach real core and be refused');
  assert.ok(first.stats.choices>=3,'stale command plus independently delivered choices from both players');
  assert.ok(first.stats.paused>=5,'first player choice must not release the shared barrier');
  assert.ok(first.stats.rejected>=2,'duplicate choice sequences must not apply twice');
  assert.ok(first.frame.level>=2);
  console.log(JSON.stringify({scenario:'reward-world',seed,first:first.stats,replay:replay.stats}));
});

test('authoritative comparison includes sparse state omitted by renderer observations',()=>{
  const game=fixture(71);
  const before=hash(game.state);
  assert.ok(game.state.world.store.statuses,'status ECS column exists');
  const changed=structuredClone(game.state);
  changed.world.store.statuses={$:'DeliberatelyDifferentTestValue'};
  assert.notEqual(hash(changed),before);
});

const values=column=>Array.isArray(column.values)?column.values:values(column.carrier??column.state??column.inner);
function putPhysicalXp(game,amounts,position){
  const store=game.state.world.store;
  const roles=values(store.roles),bodies=values(store.bodies),pickups=values(store.pickups);
  const slots=roles.flatMap((row,index)=>row?.value?.$==='XpSlot'?[index]:[]);
  assert.ok(slots.length>=amounts.length);
  for(const [n,amount] of amounts.entries()){
    const seed=slots[n];
    bodies[seed].value={...bodies[seed].value,x:position.px,y:position.py,kind:2,hp:amount,maxHp:7,variant:1,age:0,radius:6};
    pickups[seed].value={$:'Pickup',amount,generation:7,variant:1,active:true};
  }
  return slots.slice(0,amounts.length);
}
test('physical XP is credited once using actual collector Growth after raw per-collector aggregation',()=>{
  const game=fixture(103,{guestArcana:5});
  let frame=game.invoke('core_observe',1);
  const guest=frame.players.find(player=>player.id===1);
  const slots=putPhysicalXp(game,[2,2],guest);
  game.invoke('core_step',0,0,0,0);
  const hostView=game.invoke('core_observe',0),guestView=game.invoke('core_observe',1);
  assert.equal(hostView.xp,5,'two raw2 piles aggregate to4 then collector Growth30% rounds to5');
  assert.equal(guestView.xp,5,'shared XP is observed equally and is not multiplied by participant count');
  for(const seed of slots)assert.equal(values(game.state.world.store.pickups)[seed].value.amount,0);
  game.invoke('core_step',0,0,0,0);
  assert.equal(game.invoke('core_observe',0).xp,5,'cleared physical pickup cannot credit again');
});
test('equidistant physical pickup chooses stable lower player id, not strongest Growth',()=>{
  const game=fixture(107,{guestArcana:5}),frame=game.invoke('core_observe',0);
  const [host,guest]=frame.players;
  putPhysicalXp(game,[4],{px:(host.px+guest.px)/2,py:(host.py+guest.py)/2});
  game.invoke('core_step',0,0,0,0);
  assert.equal(game.invoke('core_observe',0).xp,4,'tie goes to player0 with no Growth, rather than guest Growth30%');
});


test('candidate preserves exact baseline accepted-history world trace', {skip:!process.env.COOP_BASELINE_CORE},async()=>{
  const baseline=(await import(pathToFileURL(process.env.COOP_BASELINE_CORE))).default;
  const seed=17,clocks=90;
  const before=run({seed,clocks,schedule:noisySchedule(seed,clocks),gameModule:baseline});
  const after=run({seed,clocks,schedule:before.log});
  assert.deepEqual(after.trace,before.trace,'candidate must preserve full state and both views at every clock');
  assert.equal(after.finalState,before.finalState);
  assert.equal(after.finalAdmission,before.finalAdmission);
  console.log(JSON.stringify({scenario:'baseline-candidate-equivalence',seed,baseline:before.stats,candidate:after.stats}));
});
