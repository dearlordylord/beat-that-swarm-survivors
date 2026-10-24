import assert from 'node:assert/strict';
import G from './dist/game.mjs';
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const array=xs=>{const a=[];for(;xs.$==='Con';xs=xs.tail)a.push(xs.head);return a;};
const values=c=>Array.isArray(c.values)?c.values:values(c.state??c.inner);
const outside=(b,px,py)=>Math.abs(b.x-px)>512+3*b.radius+24||Math.abs(b.y-py)>512+3*b.radius+24;
let checks=0;
for(const [px,py]of [[G.world_center(),G.world_center()],[20,20],[(G.world_size()-20),(G.world_size()-20)]])for(const seed of [17,23,57])for(const slow of [0,1,90,65626])for(const burn of [0,120])for(const staleArea of [false,true]){
 const p=G.start_seed_quiet(0,0,12345),tick=(6-seed%6)%6;
 const run={...p.state.run,tick,px,py,seed:12344+tick};
 const old={...G.initial_body(seed),x:px,y:py};
 const motion={...G.empty_motion(),vx:42,vy:13,life:17,pierce:23,visited:list([8,9]),slow,burn};
 const hits=staleArea?list([{$:'HitPlan',shot:G.pool_player_start(),weapon:10,damage:24,x:px,y:py,radius:120,area:{$:'True'},targets:nil}]):nil;
 const args={$:'Args',run,bodies:nil,dx:0,dy:0,snapshots:nil,hits};
 const candidate=G.update(old,run).body;
 assert.equal(candidate.kind,0,'fixture really admits a fresh enemy');
 const result=G.normal_regular_entity(old,motion,args);
 assert.deepEqual(result.row.body,candidate,'fresh birth retains accepted coordinates, health and identity');
 assert.deepEqual(result.motion,G.empty_motion(),'new incarnation clears every old motion/status field');
 assert.ok(outside(result.row.body,px,py),'old freeze/slow or tower hit cannot place birth inside viewport');
 checks++;
}
// Actual ECS integration: only mutate values in a real initialized world,
// then use the ordinary live step and inspect both authoritative columns.
for(const slow of [90,65626]){
 let p=G.start_seed_quiet(0,0,12345);const old={...G.initial_body(17),x:G.world_center(),y:G.world_center()};
 values(p.state.world.store.bodies)[17].value=old;
 values(p.state.world.store.vitals)[17].value={$:'Vitals',health:0,maximum:0};
 values(p.state.world.store.motions)[17].value={...G.empty_motion(),slow,burn:120};
 p.state.bodies=list(array(p.state.bodies).map(b=>b.seed===17?old:b));
 p=G.advance_live_quiet(p.state,0,0);
 const born=array(p.state.bodies).find(b=>b.seed===17);
 assert.equal(born.kind,0);assert.ok(outside(born,p.state.run.px,p.state.run.py));
 assert.deepEqual(values(p.state.world.store.motions)[17].value,G.empty_motion(),'actual ECS write clears previous life status');checks++;
}
// A boss replacing a living pool slot also starts with clean status.
{
 const p=G.start_seed_quiet(0,0,12345),run={...p.state.run,tick:7200};
 const old={...G.enemy_new(0,1,G.world_center(),G.world_center(),0,0,0),x:G.world_center(),y:G.world_center(),age:100};
 const args={$:'Args',run,bodies:nil,dx:0,dy:0,snapshots:nil,hits:nil};
 const born=G.normal_regular_entity(old,{...G.empty_motion(),slow:65626,burn:100},args);
 assert.equal(born.row.body.age,0);assert.ok(outside(born.row.body,G.world_center(),G.world_center()));assert.deepEqual(born.motion,G.empty_motion());checks++;
}
// Existing zero-age after a U32 age wrap is not another birth.
{
 const p=G.start_seed_quiet(0,0,12345),run={...p.state.run,tick:1};
 const old={...G.enemy_new(17,1,G.world_center(),G.world_center(),0,0,0),x:G.world_center(),y:G.world_center(),age:0};
 const args={$:'Args',run,bodies:nil,dx:0,dy:0,snapshots:nil,hits:nil};
 const result=G.normal_regular_entity(old,{...G.empty_motion(),slow:90,burn:120},args);
 assert.ok(result.motion.slow>0,'age wrap must retain ordinary status processing');
 assert.ok(result.motion.burn>0);checks++;
}
console.log(`PASS spawn lifecycle: ${checks} slow/freeze/burn/stale-area cases, actual ECS writes and boss replacement`);
