import assert from 'node:assert/strict';
import G from './dist/game.mjs';
const list=xs=>xs.reduceRight((tail,head)=>({$: 'Con',head,tail}),{$:'Nil'});
const array=xs=>{const out=[];while(xs.$==='Con'){out.push(xs.head);xs=xs.tail;}return out;};
const body=(seed,kind=8,hp=0,x=100,y=100,generation=0,age=0)=>({$:'Body',x,y,kind,variant:0,hp,maxHp:generation,age,seed,radius:6});
const row=(b,killed=0)=>({$:'EntityRow',row:{$:'Row',body:b,hit:0,xp:0,gold:0,heal:0,chest:0,killed,relic:0},motion:G.empty_motion()});
const XP_START=G.pool_xp_start(), XP_COUNT=G.pool_xp_count();
const pool=()=>Array.from({length:XP_COUNT},(_,i)=>row(body(XP_START+i)));
let events=[row(body(5,2,0,123,456),1),...pool()];
let routed=array(G.xp_route_rows(list(events),400));
assert.equal(routed.find(r=>r.row.body.seed===5).row.body.kind,8,'Enemy slot releases immediately');
let drops=routed.filter(r=>r.row.body.kind===2);
assert.equal(drops.length,1);assert.equal(drops[0].row.body.hp,2);
assert.equal(drops[0].row.body.x,123);assert.equal(drops[0].row.body.y,456);
assert.equal(drops[0].row.body.maxHp,400);
const full=pool().map((r,i)=>row(body(XP_START+i,2,5,100+i*7,100,10,390)));
routed=array(G.xp_route_rows(list([row(body(6,2,0,111,100),1),...full]),401));
assert.equal(routed.filter(r=>r.row.body.kind===2).length,XP_COUNT);
assert.equal(routed.reduce((n,r)=>n+G.xp_amount(r.row.body),0),XP_COUNT*5+2,'Overflow preserves every XP unit');
assert.equal(routed.find(r=>r.row.body.seed===XP_START+XP_COUNT-1).row.body.hp,7,'Overflow chooses farthest pile from player');
assert.equal(routed.find(r=>r.row.body.seed===XP_START+XP_COUNT-1).row.body.maxHp,10,'Merge keeps pile identity');
const accumulator=routed.find(r=>r.row.body.seed===XP_START+XP_COUNT-1).row.body;
assert.equal(accumulator.variant,1,'Overflow marks one persistent accumulator');
const merged=array(G.xp_route_rows_at(list([row(body(7,2,0,200,200),1),...routed.filter(r=>r.row.body.seed>=XP_START)]),402,3580,3580));
const retained=merged.find(r=>r.row.body.seed===accumulator.seed).row.body;
assert.deepEqual({...retained,hp:accumulator.hp},accumulator,'Moving player cannot relocate or replace accumulator identity');
assert.equal(retained.hp,9);assert.equal(merged.reduce((n,r)=>n+G.xp_amount(r.row.body),0),XP_COUNT*5+4);
const p=G.start(0,0);assert.equal(p.$,'Packet');const run={...p.state.run,px:1800,py:1800};
const collectedAccumulator=G.loot_update(retained,{...run,px:retained.x,py:retained.y});
assert.equal(collectedAccumulator.xp,9);assert.equal(collectedAccumulator.body.kind,8);
const afterPickup=merged.map(entity=>entity.row.body.seed===retained.seed?row(collectedAccumulator.body):entity);
const replaced=array(G.xp_route_rows_at(list([row(body(8,2,0,321,654),1),...afterPickup]),403,3580,3580));
const replacement=replaced.find(entity=>entity.row.body.seed===retained.seed).row.body;
assert.equal(replacement.variant,0,'A collected accumulator frees a normal XP slot');
assert.equal(replacement.maxHp,403);assert.equal(replacement.x,321);assert.equal(replacement.y,654);
const old=body(XP_START,2,123,100,100,10,100000);
const untouched=G.loot_update(old,run);
assert.equal(untouched.xp,0);assert.equal(untouched.body.hp,123);assert.equal(untouched.body.kind,2,'No age expiration');
const picked=G.loot_update({...old,x:1800,y:1800},run);
assert.equal(picked.xp,123);assert.equal(picked.body.kind,8);
const repeated=G.xp_entity(picked.body,{$:'Args',run,bodies:list([]),dx:0,dy:0,snapshots:list([]),hits:list([])});
assert.equal(repeated.row.xp,0,'Pickup cannot duplicate value');
assert.equal(G.selected_kind(0,2,XP_START),false,'XP never enters projectile pass');
assert.equal(G.selected_kind(1,2,XP_START),false,'XP never enters enemy movement pass');
assert.equal(G.selected_kind(2,2,XP_START),true,'XP participates in ECS lifecycle');
console.log('Persistent XP: exact placement, physical pickup, no expiration, full-pool conservation and isolated ECS routing passed');
let crowded=pool();let expected=0;
for(let tick=1;tick<=24;tick++){
 const kills=Array.from({length:20},(_,i)=>row({...body(i,2,0,(tick*173+i*97)%3500+20,(tick*241+i*137)%3500+20),variant:i%20},1));
 expected+=kills.reduce((n,r)=>n+2+Math.min(4,Math.floor(r.row.body.variant/4)),0);
 crowded=array(G.xp_route_rows(list([...kills,...crowded]),tick)).filter(r=>r.row.body.seed>=XP_START);
 assert.equal(crowded.reduce((n,r)=>n+G.xp_amount(r.row.body),0),expected);
}
assert.equal(crowded.filter(r=>r.row.body.kind===2).length,XP_COUNT,'Pool saturates without losing later drops');
const simulate=seed=>{let packet=G.start_seed(0,0,seed);for(let i=0;i<30;i++)packet=G.advance(packet.state,0,0);return packet.frame;};
assert.equal(simulate(42),simulate(42),'Same seed and commands replay exactly');
assert.notEqual(simulate(42),simulate(43),'Different seeds change actual enemy placements');
let defaultPacket=G.start(0,0),seededDefault=G.start_seed(0,0,12345);
for(let i=0;i<30;i++){defaultPacket=G.advance(defaultPacket.state,0,0);seededDefault=G.advance(seededDefault.state,0,0);}
assert.equal(defaultPacket.frame,seededDefault.frame,'Default seed remains compatible');
console.log('480-drop conservation and deterministic production seed replay passed');
// Lifecycle lookup must keep its existing first-match rule and missing-ID fallback.
const firstMatch=body(XP_START+51,2,19,300,400,17,200);
const laterDuplicate=body(XP_START+51,2,900,900,900,999,0);
const fallback=body(XP_START+51,8,0,0,0);
assert.deepEqual(G.planned_body(list([row(body(10)),row(firstMatch),row(laterDuplicate)]),XP_START+51,fallback),firstMatch);
assert.deepEqual(G.planned_body(list([row(body(10)),row(firstMatch)]),123,fallback),fallback);
assert.deepEqual(G.planned_body(list([]),XP_START+51,fallback),fallback);
// Follow the same route -> lifecycle lookup -> next loot update path used in a tick.
const lifecycleRows=G.xp_route_rows(list([row(body(4,2,0,100,100),1),...pool()]),500);
const persisted=G.planned_body(lifecycleRows,XP_START,body(XP_START));
assert.equal(persisted.kind,2);assert.equal(persisted.hp,2);assert.equal(persisted.maxHp,500);
const nextLifecycleRows=G.xp_route_rows(list([
  G.xp_entity(persisted,{$:'Args',run,bodies:list([]),dx:0,dy:0,snapshots:list([]),hits:list([])}),
  ...pool().slice(1),
]),501);
const persistedAgain=G.planned_body(nextLifecycleRows,XP_START,body(XP_START));
assert.equal(persistedAgain.hp,2);assert.equal(persistedAgain.maxHp,500);assert.equal(persistedAgain.age,1);
console.log('Lifecycle lookup first-match/fallback and persistent XP across lifecycle ticks passed');
// Target geometry ignores non-enemy ECS kinds while preserving enemy order.
const mixedGeometry=list([
 body(XP_START,2,2000,100,100,1),
 {...body(2,0,10,110,100),variant:21,age:55},
 body(G.pool_actor_start(),10,80,100,100),
 body(G.pool_actor_start()+8,11,160,100,100),
 body(G.pool_player_start(),1,50,100,100),
 body(G.pool_hostile_start(),7,8,100,100),
 body(3,0,12,120,100),
 body(4,8,0,100,100),
]);
const enemyGeometry=G.enemy_geometry(mixedGeometry);
assert.deepEqual(array(enemyGeometry).map(b=>b.seed),[2,3]);
const noAim={$:'Aim',x:280,y:100,id:0,distance:100000000};
assert.deepEqual(G.nearest(mixedGeometry,100,100,noAim),G.nearest(enemyGeometry,100,100,noAim));
assert.deepEqual(G.nearest_shooter(mixedGeometry,100,100,noAim),G.nearest_shooter(enemyGeometry,100,100,noAim));
assert.equal(G.nearest_shooter(enemyGeometry,100,100,noAim).id,2);
assert.deepEqual(G.contacts(mixedGeometry,100,100,30,list([])),G.contacts(enemyGeometry,100,100,30,list([])));
assert.deepEqual(G.planned_targets(false,1,mixedGeometry,100,100,30,list([])),G.planned_targets(false,1,enemyGeometry,100,100,30,list([])));
const frozenShots=list([{$:'Snapshot',body:body(G.pool_player_start(),1,7,100,100),motion:{...G.empty_motion(),life:20,pierce:2}}]);
assert.deepEqual(G.plan_hits(frozenShots,mixedGeometry),G.plan_hits(frozenShots,enemyGeometry));
assert.equal(array(G.plan_hits(frozenShots,enemyGeometry)).length,1);
const combatArgs=G.combat_args(run,mixedGeometry,0,0,frozenShots);
assert.deepEqual(combatArgs.bodies,enemyGeometry);
assert.deepEqual(combatArgs.snapshots,frozenShots,'Full projectile/actor snapshots remain available');
assert.deepEqual(combatArgs.hits,G.plan_hits(frozenShots,mixedGeometry));
console.log('Enemy-only target geometry matches full mixed ECS observations and preserves frozen snapshots');
// A single dense frame can fill the empty pool and overflow before any old pile exists.
const simultaneousDeaths=Array.from({length:480},(_,seed)=>row(body(seed,2,0,100+seed*7,200),1));
const firstDenseDrop=simultaneousDeaths[0].row.body;
const simultaneous=array(G.xp_route_rows_at(list([...simultaneousDeaths,...pool()]),900,1800,1800));
const simultaneousPiles=simultaneous.filter(entity=>entity.row.body.seed>=XP_START&&entity.row.body.kind===2);
assert.equal(simultaneousPiles.length,XP_COUNT);
assert.equal(simultaneousPiles.reduce((sum,entity)=>sum+G.xp_amount(entity.row.body),0),960);
const newAccumulator=simultaneousPiles.find(entity=>entity.row.body.seed===XP_START).row.body;
assert.equal(newAccumulator.hp,162);
assert.equal(newAccumulator.variant,1);
assert.equal(newAccumulator.maxHp,900);
assert.equal(newAccumulator.x,firstDenseDrop.x);
assert.equal(newAccumulator.y,firstDenseDrop.y);
assert.equal(simultaneousPiles.filter(entity=>entity.row.body.variant===1).length,1);
console.log('480 simultaneous deaths: empty-pool batch creates400 persistent piles and one exact162XP accumulator');
