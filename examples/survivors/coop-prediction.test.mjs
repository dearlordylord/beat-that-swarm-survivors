import test from 'node:test';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const dir=process.env.COOP_PREDICTION_TEST_DIST;
if(!dir)throw Error('Run check-coop-prediction.sh');
const load=async name=>(await import(pathToFileURL(`${dir}/${name}.mjs`))).default;
const [P,M,S,G]=await Promise.all(['coop-prediction','player-movement','coop-session','game'].map(load));
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=rows=>{const result=[];for(;rows.$==='Con';rows=rows.tail)result.push(rows.head);return result;};
const receipt=(seq,steps,expired=false)=>({$:'Receipt',seq,steps,x:1,y:1,expired});
const steps=(state,count)=>{for(let i=0;i<count;i++)state=P.tick(state);return state;};
const position=state=>{const {x,y}=P.view(state);return {x,y};};
const fresh=()=>P.fresh(7200,7200,2.5,true);

test('new input, release and reversal affect the next step after existing movement',()=>{
 let state=steps(P.command(fresh(),1,2,1),5);
 assert.deepEqual(position(state),{x:7212.5,y:7200});
 state=P.tick(P.command(state,2,1,1));assert.deepEqual(position(state),{x:7212.5,y:7200});
 state=P.tick(P.command(state,3,0,1));assert.deepEqual(position(state),{x:7210,y:7200});
 assert.deepEqual(P.command(state,2,2,1),state);assert.deepEqual(P.command(state,4,3,1),state);
});
test('partial and repeated cumulative ACKs never double-consume or undo progress',()=>{
 let state=steps(P.command(fresh(),1,2,1),6);
 state=P.reconcile(state,1,7205,7200,2.5,true,receipt(1,2));assert.equal(state.x,7215);
 state=P.reconcile(state,2,7205,7200,2.5,true,receipt(1,2));assert.equal(state.x,7215);
 state=P.reconcile(state,3,7207.5,7200,2.5,true,receipt(1,3));assert.equal(state.x,7215);
 state=P.reconcile(state,4,7207.5,7200,2.5,true,receipt(1,2));assert.equal(state.x,7215);
 assert.equal(array(state.segments)[0].consumed,3);
 const ahead=P.reconcile(steps(P.command(fresh(),1,2,1),2),1,7212.5,7200,2.5,true,receipt(1,5));
 assert.equal(array(ahead.segments)[0].steps,5);assert.equal(P.tick(ahead).x,7215);
});
test('pending movement replays oldest-first from authority and discards skipped sequences',()=>{
 let state=P.fresh(14270,7200,2.5,true);
 state=steps(P.command(state,1,2,1),3);state=steps(P.command(state,2,0,1),1);
 state=P.reconcile(state,1,14270,7200,2.5,true,receipt(0,0));
 assert.equal(state.x,14269.5,'right hits boundary before left; reverse order differs');
 state=P.reconcile(state,2,1000,2000,2.5,true,receipt(2,1));
 assert.deepEqual(position(state),{x:1000,y:2000});assert.deepEqual(array(state.segments).map(row=>row.seq),[2]);
});
test('expiry removes the old held direction, with no motion until a fresh command',()=>{
 let state=steps(P.command(fresh(),5,2,1),8);
 state=P.reconcile(state,1,7220,7200,2.5,true,receipt(5,18,true));
 assert.equal(array(state.segments).length,0);state=steps(state,20);assert.equal(state.x,7220);
 state=P.tick(P.command(state,6,2,1));assert.equal(state.x,7222.5);
});
test('prediction gate denies pause, death and disconnect, and resume discards old history',()=>{
 assert.equal(P.allowed(0,70,true),true);
 for(const phase of [1,2,3,4,5])assert.equal(P.allowed(phase,70,true),false);
 assert.equal(P.allowed(0,0,true),false);assert.equal(P.allowed(0,70,false),false);
 let state=steps(P.command(fresh(),1,2,1),5);
 state=P.reconcile(state,1,7205,7200,2.5,false,receipt(1,2));
 assert.deepEqual(P.tick(state),state);assert.deepEqual(array(state.segments),[]);
 state=P.command(state,2,0,1);
 state=P.reconcile(state,2,7205,7200,3.0,true,receipt(1,2));
 assert.deepEqual(array(state.segments),[]);assert.equal(P.tick(state).x,7205);
 assert.equal(P.tick(P.command(state,3,2,1)).x,7208);
 const old=state;assert.deepEqual(P.reconcile(state,1,99,99,99,true,receipt(1,0)),old);
});
test('horizon and 64-segment history remain bounded without acknowledgments',()=>{
 let state=P.command(fresh(),1,2,1);state=steps(state,200);
 assert.equal(state.age,60);assert.equal(state.x,7350);assert.deepEqual(P.tick(state),state);
 for(let seq=2;seq<=100;seq++)state=P.tick(P.command(state,seq,2,1));
 assert.equal(state.age,60);assert.equal(state.x,7350);assert.equal(array(state.segments).length,64);
 assert.equal(array(state.segments)[0].seq,100);assert.equal(array(state.segments).at(-1).seq,37);
});
test('receipt tracks actual advanced calls, changed sequence and explicit expiration',()=>{
 let session=S.fresh(7),ack=S.receipt_fresh();
 session=S.admission_state(S.receive(session,1,{$:'Command',session:7,player:1,seq:2,intendedTick:0,action:{$:'Movement',x:2,y:1}}));
 assert.equal(ack.seq,0,'receiving a command does not mutate the separate applied receipt');
 ack=S.receipt_step(ack,session,1);assert.equal(ack.seq,2);assert.equal(ack.steps,1);assert.equal(ack.x,2);
 ack=S.receipt_step(ack,session,1);assert.equal(ack.steps,2);
 session=S.admission_state(S.receive(session,1,{$:'Command',session:7,player:1,seq:3,intendedTick:0,action:{$:'Movement',x:0,y:1}}));
 ack=S.receipt_step(ack,session,1);assert.equal(ack.steps,1);assert.equal(ack.seq,3);assert.equal(ack.x,0);
 for(let n=0;n<18;n++)session=S.clock(session);
 ack=S.receipt_step(ack,session,1);assert.equal(ack.expired,true);assert.equal(ack.x,1);
});
test('ACK filtering and idempotence agree with an independent model over generated histories',()=>{
 let seed=941;const random=n=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed%n;};
 for(let n=0;n<1000;n++){
  const rows=Array.from({length:random(20)},()=>({$:'Segment',seq:random(20),x:random(3),y:random(3),steps:random(90),consumed:random(90)}));
  const ack=random(20),count=random(90),expired=!!random(2);
  const expected=rows.filter(row=>expired?row.seq>ack:row.seq>=ack).map(row=>{
   if(row.seq!==ack)return row;
   const consumed=Math.max(row.consumed,count),steps=Math.max(row.steps,consumed);
   return {...row,steps,consumed:expired?steps:consumed};
  });
  const actual=P.acknowledge(list(rows),ack,count,expired);
  assert.deepEqual(array(actual),expected);assert.deepEqual(P.acknowledge(actual,ack,count,expired),actual);
 }
});
test('authoritative and predicted movement share exact geometry across character builds',()=>{
 const packet=G.start_seed_quiet(0,0,91);assert.equal(packet.$,'Packet');const base=packet.state.run;
 const positions=[[7200,7200],[128,128],[14272,14272],[128,14272],[14272,128]];
 let comparisons=0;
 for(let character=0;character<8;character++)for(let arcana=0;arcana<12;arcana++)for(const rank of [0,4,8]){
  const passives=Array(18).fill(0);passives[5]=rank;
  const run={...base,character,arcana,meta:rank?0x55555:0,passives:list(passives)};
  const distance=G.run_step_distance(run);
  for(const [px,py]of positions)for(const [dx,dy]of [[0,0],[1,0],[-1,0],[0,1],[0,-1],[1,1],[-1,1],[1,-1],[-1,-1]]){
   const actual=G.moved_run({$:'PlayerView',id:0,run:{...run,px,py},dx,dy});
   const predicted=M.move_point(px,py,distance,dx,dy);
   assert.equal(actual.px,predicted.x);assert.equal(actual.py,predicted.y);comparisons++;
  }
 }
 assert.equal(comparisons,12960);
});

test('Bend observation admission rejects stale and duplicate frames before IO updates',()=>{
 let state=fresh();
 assert.equal(P.observation_newer(state,0),false);assert.equal(P.observation_newer(state,1),true);
 state=P.reconcile(state,7,7200,7200,2.5,true,receipt(0,0));
 assert.equal(P.observation_newer(state,6),false);assert.equal(P.observation_newer(state,7),false);assert.equal(P.observation_newer(state,8),true);
});
