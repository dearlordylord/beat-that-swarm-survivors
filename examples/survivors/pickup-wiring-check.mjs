#!/usr/bin/env node
import assert from 'node:assert/strict';
import {resolve,join} from 'node:path';
import {pathToFileURL} from 'node:url';
const directory=resolve(process.argv[2]);
const {default:G}=await import(pathToFileURL(join(directory,'game.mjs')));
const {default:Core}=await import(pathToFileURL(join(directory,'coop-core.mjs')));
const list=rows=>rows.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=rows=>{const result=[];for(;rows.$==='Con';rows=rows.tail)result.push(rows.head);return result;};
const pickup=(identity,item,generation=456)=>({$:'State',identity,
  spatial:{$:'Spatial',x:7200,y:7200,age:0,radius:6},
  payload:{$:'Payload',item,generation,active:true}});
function install(state,rows){
  const installed=G.xp_lifecycle(list([]),list(rows.map(state=>({$:'PickupRow',outcome:{$:'Outcome',state,
    reward:{$:'Reward',xp:0,coins:0,healing:0,chests:0,relics:0}}}))),state.world);
  assert.equal(installed.$,'Executed'); assert.equal(installed.outcome.$,'Success');
  return {...state,world:installed.world};
}
function advance(state){const packet=G.advance_live(state,0,0);assert.equal(packet.$,'Packet');return packet.state;}
function fresh(){const packet=G.start_seed(0,0,12345);assert.equal(packet.$,'Packet');return packet.state;}
for(const [item,identity,field,expected] of [
  [{$:'Xp',amount:17,accumulator:false},1056,'xp',17],
  [{$:'Gold',coins:13},0,'gold',13],
]){
  const next=advance(install(fresh(),[pickup(identity,item)]));
  assert.equal(next.run.session[field],expected,'actual reward through storage/query/finish');
  const retired=array(next.snapshots).find(row=>row.$==='PickupSnapshot'&&row.pickup.identity===identity).pickup;
  assert.equal(retired.payload.active,false);assert.equal(retired.payload.generation,456);
  assert.equal(advance(next).run.session[field],expected,'actual next query cannot collect twice');
}
for(const [kind,item] of [[{$:'XpDrop'},{$:'Xp',amount:7,accumulator:false}],[{$:'GoldDrop'},{$:'Gold',coins:7}]]){
  const dormant=pickup(1056,{$:'Xp',amount:0,accumulator:false});dormant.payload.active=false;
  const rows=G.xp_route_rows_at(list([
    {$:'EnemyRow',credit:{$:'Credit',contactDamage:0,kills:1},outcome:{$:'Killed',
      enemy:{$:'State',spatial:{$:'Spatial',x:7200,y:7200,age:1,radius:6},archetype:17,identity:0,
        vitals:{$:'Vitals',health:0,maximum:1},status:{$:'Status',slow:0,burn:0}},
      reward:{$:'DeathReward',kind,amount:7,x:7200,y:7200,archetype:17,identity:0,killer:{$:'Some',value:0}}}},
    {$:'PickupRow',outcome:{$:'Outcome',state:dormant,reward:{$:'Reward',xp:0,coins:0,healing:0,chests:0,relics:0}}}
  ]),66,7200,7200);
  const created=array(rows).find(row=>row.$==='PickupRow'&&row.outcome.state.payload.active).outcome.state;
  assert.deepEqual(created.payload.item,item,'typed death handoff chooses explicit loot payload');
  assert.equal(created.payload.generation,66);
  assert.equal(created.spatial.x,7200);assert.equal(created.spatial.y,7200);
}
let state=fresh();state={...state,run:{...state.run,player:{...state.run.player,hp:35}}};
state=advance(install(state,[pickup(0,{$:'Healing',health:25})]));
assert.equal(state.run.player.hp,60,'non-XP healing uses explicit reward and personal health');
const held=G.pickup_turn({$:'PickupCall',team:G.solo_team(G.combat_args(fresh().run,0,0,list([]))),advance:false,relic:false},
  {...pickup(0,{$:'Gold',coins:13}),spatial:{$:'Spatial',x:7200,y:7200,age:19,radius:6}});
assert.equal(held.state.spatial.age,19,'rejected fresh enemy birth holds occupied loot age');
assert.equal(held.reward.coins,0,'rejected fresh enemy birth cannot collect occupied loot');
let coop=Core.core_start(0,0,12345);assert.equal(coop.$,'CorePacket');
coop=Core.core_join(coop.state,0,0,0);assert.equal(coop.$,'CorePacket');
coop=Core.core_step(install(coop.state,[pickup(1056,{$:'Xp',amount:17,accumulator:false})]),0,0,0,0);
assert.equal(coop.$,'CorePacket');assert.equal(coop.state.shared.xp,17,'co-op reduces collected XP once across both personal views');
coop=Core.core_step(coop.state,0,0,0,0);
assert.equal(coop.$,'CorePacket');assert.equal(coop.state.shared.xp,17,'co-op persistent pool cannot pay twice');
console.log('PICKUP WIRING PASS: actual storage/query rewards, one-time collection, healing, deferred occupied slot, co-op allocation');
