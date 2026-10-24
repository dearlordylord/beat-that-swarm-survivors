import test from 'node:test';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
const directory = process.env.COOP_TEST_DIST;
if (!directory) throw new Error('Run bash examples/survivors/check-coop-session.sh');
const load = async name => (await import(pathToFileURL(`${directory}/${name}.mjs`))).default;
const [S,P,E] = await Promise.all(['coop-session','coop-protocol','coop-network-emulator'].map(load));
const movement = (session,player,seq,x=2,y=1) => ({ $:'Command',session,player,seq,intendedTick:0,action:{$:'Movement',x,y} });
const list = rows => rows.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
function oracleReceive(state,peer,command) {
  const lane = command.player===0 ? 'host':'guest';
  const a=command.action;
  const actionOK = a.$==='Movement' ? a.x<=2 && a.y<=2 : a.$==='Choice' ? a.round>0 && a.index<16 : a.character<8 && a.arcana<12 && a.allowedWeapons<=16777215;
  const accepted = !state.ended && (peer===0 || state.guestConnected) && peer===command.player && command.session===state.session && command.player<=1 && (command.player===0 || state.guestConnected) && command.seq>state[lane].lastSeq && actionOK;
  const next = structuredClone(state);
  if(accepted) {
    next[lane].lastSeq=command.seq;
    if(a.$==='Movement') Object.assign(next[lane],{inputSeq:command.seq,receivedAt:state.clock,x:a.x,y:a.y});
  }
  return {state:next,accepted};
}
function random(seed) { let v=seed>>>0; return n=>{v=(Math.imul(v,1664525)+1013904223)>>>0;return v%n;}; }

test('fresh valid input accepted, forged player/session, duplicate and older inputs leave state intact',()=>{
  let state=S.fresh(99);
  const command=movement(99,1,4);
  const result=S.receive(state,1,command);
  assert.equal(result.accepted,true); state=result.state;
  for(const [peer,c] of [[0,movement(99,1,5)],[1,movement(98,1,5)],[1,command],[1,movement(99,1,3)],[1,movement(99,1,5,3)]]) {
    const denied=S.receive(state,peer,c); assert.equal(denied.accepted,false);assert.deepEqual(denied.state,state);
  }
});
test('input is applied at next gameplay tick, expires at18 admission ticks including pause',()=>{
  let state=S.receive(S.fresh(9),1,movement(9,1,7)).state;
  assert.equal(state.guest.appliedSeq,0);
  state=S.applied(44,state);assert.equal(state.guest.appliedSeq,7);assert.equal(state.guest.appliedTick,44);
  state=S.applied(45,state);assert.equal(state.guest.appliedTick,44);
  for(let n=0;n<17;n++)state=S.clock(state);
  assert.equal(S.directions(state).x1,1);
  state=S.clock(state); assert.equal(S.directions(state).x1,0);
  assert.equal(state.guest.appliedTick,44);
});
test('disconnect guest denies further effects and host exit ends both lanes',()=>{
  let state=S.receive(S.fresh(9),1,movement(9,1,1)).state;
  state=S.disconnect(1,state);assert.equal(S.directions(state).x1,0);assert.equal(S.receive(state,1,movement(9,1,2)).accepted,false);
  state=S.disconnect(0,state);assert.equal(S.receive(state,0,movement(9,0,2)).accepted,false);assert.deepEqual(S.directions(state),{$:'Directions',x0:0,y0:0,x1:0,y1:0});
});
test('canonical codec roundtrips all actions and refuses malformed, overflow and oversized payloads',()=>{
  const r=random(93821);
  for(const edge of [0,1,0xffffffff]) {
    const c=movement(edge,1,edge,0,2);c.intendedTick=edge;
    assert.deepEqual(P.decode(P.encode(c)),{$:'Some',value:c});
    c.action={$:'Setup',character:7,arcana:11,meta:edge,allowedWeapons:16777215};
    assert.deepEqual(P.decode(P.encode(c)),{$:'Some',value:c});
  }
  for(let n=0;n<1000;n++) {
    const c=movement(r(0xffffffff),r(2),r(0xffffffff));c.intendedTick=r(0xffffffff);
    if(n%3===1)c.action={$:'Choice',round:r(0xffffffff),index:r(16)};
    if(n%3===2)c.action={$:'Setup',character:r(8),arcana:r(12),meta:r(0xffffffff),allowedWeapons:r(16777216)};
    assert.deepEqual(P.decode(P.encode(c)),{$:'Some',value:c});
  }
  for(const wire of ['', 'BSC1|01|0|1|0|I|1|1','BSC1|4294967296|0|1|0|I|1|1','BSC1|1|0|1|0|I|1|1|','BSC1|1|0|-1|0|I|1|1','BSC1|1|0|1|0|I|NaN|1','BSC2|1|0|1|0|I|1|1','x'.repeat(161),'BSC1|1|0|1|0|I|１|1'])assert.equal(P.decode(wire).$, 'None',wire);
});
test('generated admission sequences agree with independent model including exhaustion and disconnect',()=>{
  for(let seed=1;seed<=100;seed++) {
    const r=random(seed);let state=S.fresh(seed);let expected=structuredClone(state);
    for(let n=0;n<100;n++) {
      if(n===80 && seed%3===0){state=S.disconnect(1,state);expected.guest=S.neutral();expected.guestConnected=false;}
      const c=movement(r(6)===0?seed+1:seed,r(3),r(130),r(4),r(4));const peer=r(2);
      if(r(4)===0)c.action={$:'Choice',round:r(5),index:r(20)};
      const want=oracleReceive(expected,peer,c),actual=S.receive(state,peer,c);
      assert.equal(actual.accepted,want.accepted);assert.deepEqual(actual.state,want.state);state=actual.state;expected=want.state;
    }
  }
  let state=S.receive(S.fresh(1),0,movement(1,0,0xffffffff)).state;
  assert.equal(S.receive(state,0,movement(1,0,0)).accepted,false);
});
test('virtual loss jitter reordering duplicate and disconnect replay accepted log exactly',()=>{
  for(let seed=1;seed<=100;seed++) {
    const r=random(seed),schedule=[];
    for(let seq=1;seq<=40;seq++) {
      const peer=seq%2,command=movement(seed,peer,seq,r(3),r(3));
      if(r(5)===0)continue; // deterministic loss
      const at=seq+r(12);schedule.push({$:'Scheduled',at,event:{$:'Deliver',peer,command}});
      if(r(4)===0)schedule.push({$:'Scheduled',at:at+r(8),event:{$:'Deliver',peer,command}});
    }
    schedule.push({$:'Scheduled',at:35,event:{$:'Disconnect',player:1}});
    const result=E.run(70,seed,list(schedule));
    const replay=E.replay(70,seed,result.log);
    assert.deepEqual(replay,result);
  }
});
