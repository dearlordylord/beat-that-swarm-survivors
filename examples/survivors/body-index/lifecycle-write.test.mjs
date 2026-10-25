// Ordinary fixed-pool lifecycle candidate, not an arbitrary-World equivalence claim.
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import G from '../dist/game.mjs';
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const body=(kind,seed=17)=>({$:'Body',x:123.5,y:456.25,kind,variant:7,hp:19,maxHp:40,age:83,seed,radius:6.5});
const row=(b,killed=0)=>({$:'Row',body:b,hit:3,xp:4,gold:5,heal:6,chest:7,killed,relic:8});
const entity=r=>({$:'EntityRow',row:r,motion:G.empty_motion()});
for(const kind of [0,2,3,4,5,8,9,10,11]) {
 for(const killed of [0,1]) {
  const original=row(body(kind),killed);
  const finalRows=G.xp_free_enemies(list([entity(original)]));
  assert.deepEqual(G.stored_combat_body(original),finalRows.head.row.body,`Stored Body kind=${kind} killed=${killed}`);
  assert.equal(original.body.kind,kind,'Pure stored-body transform leaves returned event intact');
  assert.equal(original.killed,killed);
 }
}
const xpDeath=row(body(2),1);
assert.equal(G.stored_combat_body(xpDeath).kind,8);
assert.equal(xpDeath.body.kind,2,'XP routing retains the original death event');
const baselinePath=process.env.NIGHTFALL_LIFECYCLE_BASELINE_MODULE;
if(baselinePath) {
 const {default:Reference}=await import(pathToFileURL(baselinePath).href);
 const accept=p=>{assert.equal(p.$,'Packet',p.error);return {state:p.state,frame:JSON.parse(p.frame)};};
 const start=(Game,seed,advanced)=>{
  let p=accept(Game.start_seed(advanced?2:0,advanced?364304237:0,seed));
  p=accept(Game.configure(p.state,0,advanced?9:0));
  return p;
 };
 for(const [seed,advanced] of [[42,false],[12345,true]]) {
  let actual=start(G,seed,advanced),expected=start(Reference,seed,advanced);
  for(let step=0;step<240;step++) {
   while([1,2].includes(expected.frame.phase)) {
    expected=accept(Reference.choose(expected.state,0));actual=accept(G.choose(actual.state,0));
    assert.deepEqual(actual.frame,expected.frame,'Reward resolution preserves all observations');
   }
   if([3,4].includes(expected.frame.phase))break;
   const dx=step%120<60?1:-1,dy=step%80<40?0.5:-0.5;
   expected=accept(Reference.advance(expected.state,dx,dy));actual=accept(G.advance(actual.state,dx,dy));
   assert.deepEqual(actual.frame,expected.frame,`Ordinary multi-tick frame seed=${seed} tick=${expected.frame.tick}`);
  }
 }
 console.log('Lifecycle write-through: baseline/candidate ordinary multi-tick frames match');
} else {
 console.log('Lifecycle write-through: stored-body/event fixture passed; baseline differential requires NIGHTFALL_LIFECYCLE_BASELINE_MODULE');
}
