import assert from 'node:assert/strict';
import Game from './dist/game.mjs';
const values=c=>Array.isArray(c.values)?c.values:values(c.carrier??c.state??c.inner);
let comparisons=0;
for(const seed of [100,101]){
 let normal=Game.start_seed(0,0,seed),quiet=Game.start_seed(0,0,seed);
 for(let n=0;n<650;n++){
  assert.equal(normal.$,'Packet');assert.equal(quiet.$,'Packet');
  assert.equal(normal.frame,quiet.frame,'same frame after re-observing quiet state');
  assert.deepEqual(normal.state.run,quiet.state.run);
  assert.deepEqual(normal.state.pending,quiet.state.pending);
  if(n%30===0) for(const column of ['bodies','vitals','motions','statuses','pickups','roles']) assert.deepEqual(values(normal.state.world.store[column]),values(quiet.state.world.store[column]),column);
  comparisons++;
  const phase=normal.state.run.phase;if(phase>=3)break;
  if(phase===1||phase===2){normal=Game.choose(normal.state,0);quiet=Game.choose(quiet.state,0);}
  else{
   normal=Game.advance(normal.state,Math.sin(n/90),Math.cos(n/90));
   const q=Game.advance_quiet(quiet.state,Math.sin(n/90),Math.cos(n/90));
   assert.equal(q.$,'Packet');assert.equal(q.frame,'','quiet step emits no frame');quiet=Game.packet(q.state);
  }
 }
}
console.log(JSON.stringify({test:'quiet step matches normal states, queues, frames and authoritative columns',comparisons}));
