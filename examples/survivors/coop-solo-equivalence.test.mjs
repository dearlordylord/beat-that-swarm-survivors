import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const directory=process.env.COOP_SOLO_TEST_DIST;
if(!directory)throw Error('Run bash examples/survivors/check-coop-solo.sh');
const load=async name=>(await import(pathToFileURL(`${directory}/${name}.mjs`))).default;
const [G,O]=await Promise.all(['game','coop-solo-oracle'].map(load));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const array=xs=>{const result=[];for(;xs.$==='Con';xs=xs.tail)result.push(xs.head);return result;};
const values=c=>Array.isArray(c.values)?c.values:values(c.carrier??c.state??c.inner);
const state=result=>{assert.equal(result.$,'Packet',result.error);return result.state;};
const hash=object=>createHash('sha256').update(JSON.stringify(object,(_key,value)=>{assert.notEqual(typeof value,'function','oracle must not omit affine closure');return value;})).digest('hex');
function fresh(character,arcana,seed){
 let s=state(G.start_seed_quiet(character,0,seed));
 s=state(G.configure_quiet(s,character%5,arcana));
 s=state(G.configure_unlocks_quiet(s,16777215));return s;
}
let checks=0;
function equal(actual,expected,label){
 assert.deepEqual(actual.run,expected.run,`${label}: complete run`);
 assert.equal(hash(actual.bodies),hash(expected.bodies),`${label}: every body`);
 assert.equal(hash(actual.snapshots),hash(expected.snapshots),`${label}: every motion/status snapshot`);
 assert.deepEqual(actual.offers,expected.offers,`${label}: offers`);
 assert.deepEqual(actual.pending,expected.pending,`${label}: pending rewards`);
 assert.equal(hash(actual.world),hash(expected.world),`${label}: complete world columns, allocator, generations, routing, clocks and metadata`);checks++;
}
function replay({character,arcana,seed,ticks,setup=x=>x,label}){
 let actual=setup(fresh(character,arcana,seed)),expected=setup(fresh(character,arcana,seed));equal(actual,expected,`${label}:initial`);
 for(let tick=0;tick<ticks;tick++){
  if(actual.run.phase===1||actual.run.phase===2){actual=state(G.choose_quiet(actual,tick%3));expected=state(G.choose_quiet(expected,tick%3));equal(actual,expected,`${label}:reward${tick}`);}
  const dx=[1,0,-1,0][Math.floor(tick/15)%4],dy=[0,1,0,-1][Math.floor(tick/15)%4];
  actual=state(G.advance_quiet(actual,dx,dy));expected=state(O.step_scalar(expected,dx,dy));equal(actual,expected,`${label}:tick${tick}`);
 }
}
for(const character of [0,1,3,7])for(const arcana of [0,7,11])replay({character,arcana,seed:12345+character*23+arcana,ticks:60,label:`c${character}-a${arcana}`});
for(const arcana of [0,7,8,11])replay({character:2,arcana,seed:7700+arcana,ticks:40,label:`allweapons-a${arcana}`,setup(s){
 s.run.weapons=list(Array(24).fill(8));s.run.passives=list(Array(18).fill(3));s.run.tick=9000;s.run.seed=21345;s.run.hp=10000;s.run.maxHp=10000;return s;
}});
for(const slow of [90,65626])for(const burn of [0,120])replay({character:0,arcana:7,seed:441,ticks:12,label:`recycled-status-${slow}-${burn}`,setup(s){
 // Prime ordinary ECS lifecycle, then place a trusted old-incarnation fixture.
 s=state(G.advance_quiet(s,0,0));
 const bodies=values(s.world.store.bodies),vitals=values(s.world.store.vitals),statuses=values(s.world.store.statuses);
 const seed=17,body={...G.initial_body(seed),x:s.run.px,y:s.run.py};
 bodies[seed].value=body;vitals[seed].value={$:'Vitals',health:0,maximum:0};statuses[seed].value={$:'Status',slow,burn};
 s.bodies=list(array(s.bodies).map(row=>row.seed===seed?body:row));
 s.snapshots=list(array(s.snapshots).map(row=>row.body.seed===seed?{...row,body,motion:{...G.empty_motion(),slow,burn}}:row));return s;
}});
let requestChecks=0;
const requestBase=fresh(0,0,12345).run;
for(let arcana=0;arcana<12;arcana++)for(const invuln of [0,31,45])for(const tick of [1,12,13,60,120])for(const weaponLevel of [0,8])for(const locked of [0,255]){
 const run={...requestBase,arcana,invuln,tick,weapons:list(Array(24).fill(weaponLevel))};
 const locks=list(Array(24).fill(locked)),owner=tick%24;
 assert.equal(JSON.stringify(G.shot_requests(24,owner,run,locks)),JSON.stringify(O.requests_scalar(24,owner,run,locks)),`request enumeration arcana=${arcana} invuln=${invuln} tick=${tick} weapons=${weaponLevel} locks=${locked}`);requestChecks++;
}
console.log(`PASS shared solo schedule equivalence: ${checks} complete-state checkpoints; ${requestChecks} independent request enumeration fixtures`);
