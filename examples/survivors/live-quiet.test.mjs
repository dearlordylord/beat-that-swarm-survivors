import assert from 'node:assert/strict';
import Game from './dist/game.mjs';
const list=items=>items.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
let comparisons=0;
for(const phase of [0,1,2,3,4])for(const seed of [100,4294967295]){
 let normal=Game.start_seed(0,0,seed),quiet=Game.start_seed_quiet(0,0,seed);
 for(const packet of [normal,quiet]){
  packet.state.run=Game.with_phase(packet.state.run,phase);
  packet.state.pending=list([1,2]);
  packet.state.offers=Game.reward_offers(packet.state.run,{$:phase===2?'True':'False'});
  if(phase<3){packet.state.run.xp=500;packet.state.run.xpNeed=100;}
 }
 for(let step=0;step<6;step++){
  normal=Game.advance_live(normal.state,0.6,-0.8);
  quiet=Game.advance_live_quiet(quiet.state,0.6,-0.8);
  assert.equal(quiet.$,'Packet');assert.equal(quiet.frame,'');
  assert.deepEqual(quiet.state,normal.state,`phase ${phase}, seed ${seed}, step ${step}: complete state including world metadata and deferred rewards`);
  comparisons++;
 }
}
for(const [hero,meta] of [[0,0],[2,364304237]]){
 let normal=Game.start_seed(hero,meta,101),quiet=Game.start_seed_quiet(hero,meta,101);
 for(let tick=0;tick<120;tick++){
  normal=Game.advance_live(normal.state,Math.sin(tick/15),Math.cos(tick/15));
  quiet=Game.advance_live_quiet(quiet.state,Math.sin(tick/15),Math.cos(tick/15));
  assert.deepEqual(quiet.state,normal.state);assert.equal(quiet.frame,'');comparisons++;
 }
}
console.log(`PASS quiet live advancement: ${comparisons} complete state comparisons; active, held, queued and terminal rewards preserved`);
