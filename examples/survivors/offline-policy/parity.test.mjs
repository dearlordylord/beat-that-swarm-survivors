// Behavioral parity checks for the same typed controller operations on both backends.
// This is deliberately not an assertion of identical F32/F64 full-run traces.
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
import {heuristicUpgrade,steering} from '../../../tools/survivors-bot/runner.mjs';
import {createPlanner,planMovement,routePath} from '../../../tools/survivors-bot/planner.mjs';
const modulePath=process.argv[2]??'examples/survivors/dist/offline-policy.mjs';
const {default:P}=await import(pathToFileURL(resolve(modulePath)));
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=xs=>{const out=[];for(let s=xs;s.$==='Con';s=s.tail)out.push(s.head);return out;};
const point=(x,y)=>({$:'Point',x,y});
const none={$:'None'};
const body=(seed,x,y,kind=2,hp=10,generation=0,radius=12)=>({$:'Body',seed,x,y,kind,variant:0,hp,maxHp:generation,age:0,radius});
const run=(patch={})=>({$:'Run',phase:0,tick:1,px:900,py:900,hp:100,maxHp:100,xp:0,xpNeed:100,level:1,kills:0,gold:0,character:0,weapons:list(Array(24).fill(0)),passives:list(Array(16).fill(0)),invuln:0,seed:12345,stage:0,arcana:0,meta:0,revivals:0,bosses:0,mode:0,rerolls:0,banishes:0,skips:0,bannedWeapons:0,bannedPassives:0,enemyKinds:list([]),relicCollected:0,...patch});
const frame=(r,bodies=[],offers=[])=>({...r,worldSize:14400,worldMargin:128,weapons:array(r.weapons),passives:array(r.passives),offers,bodies:bodies.map(b=>[b.x,b.y,b.kind,b.variant,b.hp,b.maxHp,b.age,b.seed,b.radius])});
const catalog=(r,bodies)=>bodies.filter(b=>b.kind===2&&b.hp>0).map(b=>({id:`t${r.tick}:approach_experience:${b.seed}:2:0:${b.age}`,kind:'approach_experience',target:{x:b.x,y:b.y},resource:{baseXp:b.hp,generation:b.maxHp}}));
const chosen=m=>m.current.$==='Some'?m.current.value.goal:null;
const step=(m,r,b)=>P.movement(m,r,list(b)).fst;
let upgrades=0;
for(const hp of [20,70,100])for(const owned of [false,true])for(let kind=0;kind<6;kind++)for(let id=0;id<24;id++){
 const ranks=Array(24).fill(owned?1:0),r=run({hp,weapons:list(ranks),passives:list(ranks)});
 const offers=[{$:'Offer',kind:4,id:0,level:1},{$:'Offer',kind,id,level:1},{$:'Offer',kind:0,id:4,level:1}];
 assert.equal(P.upgrade(r,list(offers)),heuristicUpgrade(frame(r,[],offers)),`upgrade hp=${hp} owned=${owned} kind=${kind} id=${id}`);upgrades++;
}
for(const [x,y,bodies,target] of [
 [900,900,[],null],
 [900,900,[body(1,960,900,0,100,100)],null],
 [900,900,[body(1,960,900,0,100,100),body(2,900,840,7,1,1)],{x:1200,y:1100}],
 [80,3500,[body(1,180,3450,0,100,100)],null],
]){
 const r=run({px:x,py:y}),actual=P.steer(r,list(bodies),target?{$:'Some',value:point(target.x,target.y)}:none);
 const expected=steering(frame(r,bodies),target);
 assert.ok(Math.abs(actual.fst-expected[0])<0.00001&&Math.abs(actual.snd-expected[1])<0.00001,`steering ${x},${y}`);
}
// Close-range-only loadouts keep their actual aura engagement band.
{
 const ranks=Array(24).fill(0);ranks[4]=1;
 const r=run({weapons:list(ranks)}),b=[body(1,1010,900,0,100,100)];
 const field=P.aura(r.weapons,0,r.passives,r.arcana,true,0,0).snd;
 const actual=P.steer(r,list(b),none),expected=steering(frame(r,b),null,{current:{weaponStats:[{selfFieldRadius:field}]}});
 assert.ok(Math.abs(actual.fst-expected[0])<0.00001&&Math.abs(actual.snd-expected[1])<0.00001,'weapon-aware aura engagement steering');
}
// Actual route length and bounded search semantics, including a contact detour.
for(const [from,to,bodies,budget] of [
 [point(900,900),point(1020,1020),[],150],
 [point(901,901),point(919,919),[],150],
 [point(900,900),point(3500,3500),[],3],
 [point(900,900),point(1200,900),[body(1,1050,900,0,100,100,18)],1000],
]){
 const r=run({px:from.x,py:from.y}),native=P.route(from,to,list(bodies),budget),js=routePath(frame(r,bodies),to,{maxExpanded:budget});
 assert.equal(native.found===true,js.reachable,'route reachability');
 assert.ok(native.expanded<=budget,'bounded expansion');
 if(js.reachable){let length=0,last=from;for(const p of array(native.path)){length+=Math.hypot(p.x-last.x,p.y-last.y);last=p;}assert.ok(Math.abs(length-native.length)<0.002);}
}
let r=run(),bodies=[body(748,1080,900,2,10),body(749,900,1140,2,9)];
let native=step(P.initial(),r,bodies),js=createPlanner();
let result=planMovement(js,frame(r,bodies),catalog(r,bodies));
assert.equal(chosen(native).seed,Number(result.chosen.goal.id.split(':')[2]),'initial XP choice');
const original=chosen(native).seed;
r=run({tick:31});bodies=[body(748,1080,900,2,10),body(749,900,1140,2,11)];
native=step(native,r,bodies);result=planMovement(js,frame(r,bodies),catalog(r,bodies));
assert.equal(chosen(native).seed,original,'retain modestly less attractive XP');
assert.equal(chosen(native).seed,Number(result.chosen.goal.id.split(':')[2]),'hysteresis operation');
r=run({tick:500});bodies=[body(748,1080,900,2,30)];native=step(native,r,bodies);
assert.equal(chosen(native).seed,748,'uncollected XP never expires');
native=step(native,run({tick:501}),[]);assert.equal(chosen(native),null,'collected XP removed');
native=step(native,run({tick:502}),[body(748,1080,900,2,10,502)]);assert.equal(chosen(native).generation,502,'reused XP slot has new generation');
// Damage and stuck timers immediately invalidate cached plans.
native=step(native,run({tick:503,hp:80}),[body(748,1080,900,2,10,502)]);assert.equal(native.lastPlan,503,'damage replans');
native=step(native,run({tick:700,hp:80}),[body(748,1080,900,2,10,502)]);assert.equal(native.stuckSince,700,'stuck recovery timer');
// A blocked nearest member must not hide a reachable sibling in its XP cluster.
{
 const r=run({px:90,py:210}),b=[body(1,241,241,0,100,100),body(748,241,241),body(749,350,350)];
 const memory=step(P.initial(),r,b);
 assert.equal(chosen(memory)?.seed,749,'retry reachable XP sibling within same cluster');
}
// A large blocked XP backlog must still leave a route slot for a chest.
{
 const positions=[[241,241],[481,241],[721,241],[961,241],[241,481],[481,481],[721,481],[961,481]];
 const r=run({px:90,py:210}),b=[...positions.flatMap(([x,y],i)=>[body(i,x,y,0,100,100),body(748+i,x,y)]),body(50,90,330,5,1,1)];
 const memory=step(P.initial(),r,b),prepared=array(memory.candidates);
 assert.equal(chosen(memory)?.seed,50,'reserve reachable chest despite XP backlog');
 assert.ok(prepared.some(c=>c.goal.kind>=12),'reserve cardinal retreat despite XP backlog');
 assert.ok(prepared.length<=8,'bounded prepared routes');
}
// Empty healthy worlds leave combat steering active but retain prepared retreats.
{
 const memory=step(P.initial(),run(),[]);
 assert.equal(chosen(memory),null,'healthy cardinal suggestions do not replace combat steering');
 assert.equal(array(memory.candidates).length,4,'four cardinal routes prepared');
}
// Reserving an incumbent cluster and chest must not spend slots twice.
{
 const r=run(),b=[...Array.from({length:9},(_,i)=>body(748+i,1020+(i%3)*120,780+Math.floor(i/3)*120)),body(50,900,1080,5,1,1)];
 let memory=step(P.initial(),r,b);memory=step(memory,run({tick:31}),b);
 const prepared=array(memory.candidates),keys=prepared.map(c=>c.goal.kind===2?`xp:${c.goal.cluster.x}:${c.goal.cluster.y}`:`${c.goal.kind}:${c.goal.seed}`);
 assert.equal(new Set(keys).size,keys.length,'reserved candidate deduplication');
 assert.ok(prepared.length<=8);
 assert.ok(prepared.some(c=>c.goal.kind===5),'reserved chest slot');
 assert.ok(prepared.some(c=>c.goal.kind>=12),'reserved retreat slot');
}
// Stuck recovery resets the displacement anchor as well as the timer.
{
 let memory=step(P.initial(),run(),[]);
 memory=step(memory,run({tick:31,px:906}),[]);
 memory=step(memory,run({tick:121,px:906}),[]);
 assert.equal(memory.anchor.x,906,'stuck reset anchors at actual current position');
 assert.equal(memory.stuckSince,121);
}
// XP may lie outside the arena: cluster coordinates must stay independent.
{
 const b=[body(1,3610,100),body(2,10,220),body(3,-10,100),body(4,3590,-20)];
 const groups=array(P.clusters(P.goals(list(b)),list([]),point(900,900)));
 assert.equal(groups.length,4,'off-arena XP cluster keys never alias');
 for(const x of [-240.01,-240,-120.01,-120,-0.01,0,119.99,120,3600,3610])assert.equal(P.floor_cell(x),Math.floor(x/120),`signed cluster floor ${x}`);
}
// Non-XP resources use birth tick identity, and relics use stable slot identity.
{
 const first=P.goals_at(list([{...body(50,1000,900,5,1,100),age:3}]),100).head;
 const fresh=P.goals_at(list([{...body(50,1000,900,5,1,200),age:4}]),101).head;
 assert.equal(first.generation,97);assert.equal(P.same(first,fresh),true,'chest identity uses birth tick');
 const respawn=P.goals_at(list([{...body(50,1000,900,5,1,100),age:0}]),102).head;
 assert.equal(P.same(first,respawn),false,'reused non-XP slot gets fresh identity');
 const relic=P.goals_at(list([{...body(51,1000,900,9,1,10),age:3}]),100).head;
 assert.equal(relic.generation,0,'relic stable identity');
}
console.log(`Native policy behavioral parity: ${upgrades} offer cases, steering, bounded routes, XP lifetime/generation, hysteresis, damage and stuck replans passed`);
assert.deepEqual(P.goals_at(list([body(1056,1000,900,10,80),body(1057,1050,900,11,80)]),100),{$:'Nil'},
 'NoHiddenActorGoal: native policy ignores removed map-actor bodies even when alive and inactive');
for(const [from,to] of [[point(7200,7200),point(10800,7200)],[point(14250,14250),point(14272,14272)],[point(128,128),point(9000,9000)]]) {
 const actual=P.route(from,to,list([]),150),r=run({px:from.x,py:from.y});
 const expected=routePath(frame(r),to,{maxExpanded:150});
 assert.equal(actual.found,expected.reachable,'expanded-world local route reachability');
 if(actual.found)assert.deepEqual(array(actual.path).map(p=>({x:p.x,y:p.y})),expected.waypoints,'world-space local route points');
}
