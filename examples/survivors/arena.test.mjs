import assert from 'node:assert/strict';
import G from './dist/game.mjs';
const nil={$:'Nil'};
const size=G.world_size(),center=G.world_center();
assert.equal(size,14400);assert.equal(center,size/2);
const initial=G.start(0,0),frame=JSON.parse(initial.frame);
assert.equal(frame.worldSize,size);assert.equal(frame.px,center);assert.equal(frame.py,center);
for(let stage=0;stage<5;stage++) {
 const distance=Math.hypot(G.relic_x(stage)-center,G.relic_y(stage)-center);
 assert.ok(distance>=3599.9,'Every stage relic requires a deliberate journey, not an opening pickup');
}
function inside(body) {
 const envelope=3*body.radius+24;
 assert.ok(body.x>=envelope&&body.x<=size-envelope,JSON.stringify(body));
 assert.ok(body.y>=envelope&&body.y<=size-envelope,JSON.stringify(body));
}
let checked=0;
for(let variant=0;variant<31;variant++) {
 const radius=G['encounters:radius'](variant);
 const near=G.enemy_result(100,G.world_margin(),G.world_margin(),variant,100,1,0,radius,G.world_margin(),G.world_margin()).body;
 assert.ok(Math.hypot(near.x-G.world_margin(),near.y-G.world_margin())<=radius+10, "No safe-corner exploit from enemy visual bounds");
 for(const [x,y] of [[160,160],[size-160,160],[160,size-160],[size-160,size-160]]) {
  const body={$:'Body',x,y,kind:0,variant,hp:100,maxHp:100,age:240,seed:0,radius};
  for(const [vx,vy] of [[-50000,-50000],[50000,50000],[-50000,50000],[50000,-50000]]) {
   // Actual movement and combat mutation functions, including charging speeds
   // and knockback/pull beyond an entire arena width.
   inside(G.moved_intent(body,{$:'Intent',vx,vy,fire:{$:'False'}},1));
   inside(G.enemy_result(100,x+vx,y+vy,variant,100,240,0,radius,center,center).body);
   const collision={$:'Collision',damage:0,slow:0,burn:0,pull:1000,knock:1000,pullX:x+vx,pullY:y+vy};
   const row={$:'Row',body,hit:0,xp:0,gold:0,heal:0,chest:0,killed:0,relic:0};
   const run={...initial.state.run,px:center,py:center};
   inside(G.enemy_applied_effects(x,y,row,G.empty_motion(),collision,run).row.body);
   checked++;
  }
 }
}
console.log(`PASS arena: ${checked} full-footprint movement/knockback/pull boundaries; enlarged world and distant relics`);
