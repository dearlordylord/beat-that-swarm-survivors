// Executed diagnostics of emitted typed projection and the actual browser adapter.
// Usage: node coop-playback-wire-check.mjs <wire.mjs> <directory-of-emitted-modules>
import assert from 'node:assert/strict';
import {mkdtemp,copyFile,mkdir,symlink,rm,readFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {resolve,join,dirname} from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
const wirePath=resolve(process.argv[2]??'examples/survivors/dist/coop-playback-wire.mjs');
const moduleDir=resolve(process.argv[3]??dirname(wirePath));
const {default:W}=await import(pathToFileURL(wirePath));
const {default:P}=await import(pathToFileURL(join(moduleDir,'coop-playback.mjs')));
const list=rows=>rows.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=rows=>{const out=[];for(;rows.$==='Con';rows=rows.tail)out.push(rows.head);return out;};
const run=({tick=100,character=1,hp=100}={})=>({$:'Run',session:{$:'Session',phase:0,tick,xp:0,xpNeed:1,level:1,kills:0,gold:0,seed:1,stage:0,bosses:0,mode:0,enemyKinds:list([]),relicCollected:0},player:{$:'PlayerState',px:.1,py:-.2,hp,maxHp:100,character,weapons:list([]),passives:list([]),invuln:0,arcana:0,meta:0,revivals:0,rerolls:0,banishes:0,skips:0,bannedWeapons:0,bannedPassives:0}});
const spatial=({x=.1,y=-.2,age=10,radius=3}={})=>({$:'Spatial',x,y,age,radius});
const enemy=({identity=42,archetype=2,health=17,maximum=100,...position}={})=>({$:'EnemySnapshot',enemy:{$:'State',spatial:spatial(position),archetype,identity,vitals:{$:'Vitals',health,maximum},status:{$:'Status',slow:{$:'Slow',ticks:0,frozen:false},burn:{$:'Burn',ticks:0,sourcePlayer:{$:'None'}}}}});
const projectile=({identity=42,hostile=false,weapon=2,damage=0,life=20,pierce=2,...position}={})=>({$:'ProjectileSnapshot',projectile:{$:'State',spatial:spatial(position),identity,side:{$:hostile?'HostileShot':'PlayerShot'},payload:{$:'ShotPayload',weapon,damage,active:true},trajectory:{$:'Trajectory',vx:1,vy:0,life,pierce,visited:list([]),weaponOwner:3,logicalSlot:4,sourcePlayer:hostile?{$:'None'}:{$:'Some',value:1}}}});
const identity=snapshot=>(snapshot.enemy||snapshot.projectile).identity;
const scene=(tick,snapshot,extra={})=>({$:'Scene',own:0,players:list([{$:'PlayerSnapshot',id:0,run:run({tick}),connected:true}]),snapshots:list([snapshot]),births:{$:'Item',key:identity(snapshot),value:90},directions:{$:'Directions',hostX:0,hostY:0,guestX:0,guestY:0},contacts:list([]),tick,diagnostics:false,...extra});
const raw=(observation,tick,snapshot,extra={})=>{
 const e=snapshot.enemy,p=snapshot.projectile;
 return {observationSeq:observation,tick,ownPlayerId:0,px:0,py:0,players:[{id:0,px:.1,py:-.2,hp:100,maxHp:100,character:1,connected:true}],
  enemies:e?[{identity:e.identity,...e.spatial,archetype:e.archetype,health:e.vitals.health,maximum:e.vitals.maximum,lifetime:`enemy:${e.identity}:90`}]:[],
  projectiles:p?[{identity:p.identity,...p.spatial,hostile:p.side.$==='HostileShot',weapon:p.payload.weapon,damage:p.payload.damage,life:p.trajectory.life,pierce:p.trajectory.pierce,weaponOwner:p.trajectory.weaponOwner,logicalSlot:p.trajectory.logicalSlot,sourcePlayer:p.trajectory.sourcePlayer.$==='Some'?p.trajectory.sourcePlayer.value:null,lifetime:p.side.$==='HostileShot'?`hostile:${p.identity}:90`:'1:90:3:4'}]:[],
  pickups:[],actorOrder:[e?{enemy:e.identity}:{projectile:p.identity}],combatForecast:scene(tick,snapshot),...extra};
};
let checks=0;const check=(v,message)=>{assert.ok(v,message);checks++;};
for(const connected of [true,false]){
 const actor=W.player_actor({$:'PlayerSnapshot',id:1,run:run(),connected});
 check(actor.key===1&&actor.owner===1&&actor.generation==='player:1:1','player identity projected');
 check(actor.x===Math.fround(.1)&&actor.y===Math.fround(-.2),'nested player F32 normalized');
 check(actor.alive===connected,'player health follows connection without projectile-kind collision');
}
for(const kind of [0,1,7])for(const life of [0,1,20])for(const pierce of [0,1,2]){
 const actor=W.snapshot_actor({$:'ActorContext',tick:100,births:{$:'Item',key:42,value:90}},kind===0?enemy():projectile({hostile:kind===7,life,pierce}));
 check(actor.alive===(kind===0?true:(life>0&&pierce>0)),'kind-specific presentation liveness');
 check(actor.x===Math.fround(.1)&&actor.y===Math.fround(-.2),'nested body F32 normalized');
 check(actor.owner===(kind===1?1:4294967295),'projectile owner from explicit source player');
 check(actor.generation===(kind===0?'enemy:42:90':kind===1?'1:90:3:4':'hostile:42:90'),'exact body lifetime');
}
check(W.snapshot_actor({$:'ActorContext',tick:100,births:{$:'Item',key:42,value:7}},projectile()).generation==='1:7:3:4','explicit birth overrides age fallback');
check(W.snapshot_actor({$:'ActorContext',tick:100,births:{$:'Empty'}},projectile()).generation==='1:90:3:4','missing birth falls back to tick-age');
for(const generation of [0,9,4294967295])for(const active of [true,false])for(const item of [{$:'Gold',coins:17},{$:'Xp',amount:31,accumulator:false},{$:'Healing',health:9},{$:'Chest'},{$:'Relic',stage:2}]){
 const actor=W.pickup_actor({$:'State',spatial:spatial(),payload:{$:'Payload',item,generation,active},identity:99});
 check(actor.key===99&&actor.kind===({Xp:2,Gold:3,Healing:4,Chest:5,Relic:9}[item.$])&&actor.generation===`pickup:99:${generation}`&&actor.alive===active&&actor.x===.1&&actor.y===-.2&&actor.age===10&&actor.owner===4294967295,'typed pickup preserves lifetime and explicit liveness without health');
}
// Typed projectile interpolation uses life and pierce, preserving explicit zero damage.
let state=P.push(P.fresh(),W.project(scene(100,projectile({x:0})),1,0,list([])));
state=P.push(state,W.project(scene(106,projectile({x:6,age:16})),2,100000,list([])));
state={...state,cursor:{$:'Cursor',tick:103,fraction:0,lastAt:100000,mode:{$:'Playing'}}};
check(array(P.sample(state).value.bodies)[0].x===3,'real zero-damage projectile interpolates between canonical frames');
check(projectile().projectile.payload.damage===0,'presentation liveness does not mutate gameplay projectile damage');
const owned=run({character:7,hp:0});
check(W.own_run(scene(100,projectile(),{own:8,players:list([{$:'PlayerSnapshot',id:3,run:run(),connected:true},{$:'PlayerSnapshot',id:8,run:owned,connected:false}])})).value===owned,'own run follows ID rather than list position');
const extra=Array.from({length:12000},(_,key)=>({$:'Actor',key,kind:2,generation:`extra:${key}`,x:0,y:0,age:0,alive:false,owner:4294967295}));
check(array(W.join(list(extra),list(extra))).length===24000,'large ordered join remains stack safe');
const scratch=await mkdtemp(join(tmpdir(),'coop-wire-adapter-'));
try{
 await mkdir(join(scratch,'dist'));
 const adapterSource=await readFile(new URL('./coop-presentation.mjs',import.meta.url),'utf8');
 for(const [,name] of adapterSource.matchAll(/from ['"]\.\/dist\/([\w-]+)\.mjs['"]/g))
  await symlink(name==='coop-playback-wire'?wirePath:join(moduleDir,`${name}.mjs`),join(scratch,'dist',`${name}.mjs`));
 await copyFile(fileURLToPath(new URL('./coop-presentation.mjs',import.meta.url)),join(scratch,'coop-presentation.mjs'));
 const {ObservationPresentation}=await import(pathToFileURL(join(scratch,'coop-presentation.mjs')));
 const adapter=new ObservationPresentation();
 adapter.push(raw(1,100,enemy({health:80,maximum:100,x:0,age:10})),0);
 adapter.push(raw(2,106,enemy({health:30,maximum:100,x:6,age:16,archetype:4,radius:7})),100);
 adapter.sample(100);let displayed=adapter.sample(200);
 check(displayed.remotePresentation.baseObservation===2,'base observation advances');
 check(displayed.enemies[0].health===30&&displayed.enemies[0].age===16&&displayed.enemies[0].archetype===4&&displayed.enemies[0].radius===7,'render metadata belongs to selected base observation, not oldest lifetime cache');
 const savedFrame=adapter.frames.get(2),savedMetadata=adapter.metadata.get(2),savedContacts=adapter.contacts;
 const poison={$:'State',epoch:99,now:999,events:list([]),overflow:0,expired:0};
 adapter.push(raw(2,109,enemy({health:999}),{contactJournal:poison}),220);
 check(adapter.frames.get(2)===savedFrame&&adapter.metadata.get(2)===savedMetadata&&adapter.contacts===savedContacts,'duplicate observation cannot overwrite payload, metadata or receipt cache');
 adapter.push(raw(3,105,enemy({health:999}),{contactJournal:poison}),230);
 check(!adapter.frames.has(3)&&adapter.contacts===savedContacts,'newer observation with backward world tick cannot mutate cache');
 adapter.push(raw(3,106,enemy({health:20,age:16,x:6})),240);
 check(adapter.sample(240).enemies[0].health===20,'same-tick newer metadata is presented');
 for(let obs=4;obs<24;obs++)adapter.push(raw(obs,106+(obs-3)*3,enemy({x:obs,health:20,age:16+(obs-3)*3})),240+(obs-3)*50);
 check(adapter.frames.size<=8&&adapter.metadata.size<=8,'IO payload and metadata caches follow bounded Bend retention');
 const shots=new ObservationPresentation();
 // Seed an established cursor so projection/liveness is independent of startup policy.
 shots.push(raw(1,100,projectile({x:0})),0);shots.push(raw(2,104,projectile({x:4,age:14})),100);
 shots.state={...shots.state,cursor:{$:'Cursor',tick:103,fraction:0,lastAt:100000,mode:{$:'Playing'}}};
 displayed=shots.sample(100);
 check(displayed.projectiles[0].x===3&&displayed.projectiles[0].damage===0,'actual adapter interpolates projectile while preserving zero damage');
 for(const item of [{kind:'xp',amount:31,accumulator:false},{kind:'gold',coins:17},{kind:'healing',health:9},{kind:'chest'},{kind:'relic',stage:2}]){
  const pickups=new ObservationPresentation();
  for(const [obs,tick,at] of [[1,100,0],[2,104,100]])pickups.push(raw(obs,tick,enemy(),{pickups:[{slot:99,generation:77,active:true,x:.1,y:-.2,age:10,radius:6,item}],actorOrder:[{enemy:42},{pickup:99}]}),at);
  pickups.sample(100);const shown=pickups.sample(200).pickups[0];
  check(shown?.slot===99&&shown?.lifetime==='pickup:99:77'&&JSON.stringify(shown.item)===JSON.stringify(item),'actual adapter retains every typed pickup item and current payload lifetime');
 }
 const early=new ObservationPresentation();
 const hit={$:'HitEvent',id:'first-render-race',tick:102,kind:0,shotId:'shot:50',shotSeed:50,targetSeed:42,targetGeneration:90,fraction:.5,impactX:0,impactY:0,targetAtImpactX:2,targetAtImpactY:0,radius:3,outcome:0};
 const history=events=>({$:'State',epoch:7,now:106,events:list(events),overflow:0,expired:0});
 early.push(raw(1,100,enemy({health:20,age:10,x:0}),{contactJournal:history([])}),0);
 early.push(raw(2,106,enemy({health:20,age:16,x:6}),{contactJournal:history([hit])}),100);
 early.state={...early.state,cursor:{$:'Cursor',tick:100,fraction:0,lastAt:100000,mode:{$:'Playing'}}};
 check(early.sample(100).combatImpacts.length===0,'first-render race keeps future hit hidden');
 check(early.sample(150).combatImpacts.some(effect=>effect.id===hit.id),'hit received after attachment but before first rAF plays when due');

}finally{await rm(scratch,{recursive:true,force:true});}
console.log(JSON.stringify({status:'PASS',checks,largeJoinActors:24000,scope:'emitted projection and actual IO adapter diagnostics'}));
