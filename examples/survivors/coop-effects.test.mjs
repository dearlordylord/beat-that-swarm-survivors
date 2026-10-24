import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const E=(await import(pathToFileURL(process.env.COOP_EFFECTS_MODULE??'/tmp/bendvy-coop-effects.mjs'))).default;
const G=(await import(pathToFileURL(process.env.COOP_EFFECTS_GAME_MODULE??new URL('./dist/game.mjs',import.meta.url).pathname))).default;
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const truth={$:'True'};
const base=G.start_seed_quiet(0,0,12345).state.run;
const run=(patch={})=>({...base,tick:30,px:7100,py:7200,hp:100,maxHp:100,...patch});
const player=(id,patch={})=>({$:'Player',id,run:run(patch)});
const snapshot=(shot,id)=>({$:'Snapshot',body:{$:'Body',x:7200,y:7200,kind:1,variant:0,hp:1,maxHp:1,age:1,seed:shot,radius:10},motion:{...G.empty_motion(),logicalSlot:id*65536}});
const hit=(shot,weapon,damage)=>({$:'HitPlan',shot,weapon,damage,x:7200,y:7200,radius:100,area:truth,targets:nil});
const row=(patch={})=>({$:'Row',body:{$:'Body',x:7200,y:7200,kind:0,variant:0,hp:100,maxHp:100,age:10,seed:8,radius:10,...patch},hit:0,xp:0,gold:0,heal:0,chest:0,killed:0,relic:0});
let checks=0;
const snaps=list([snapshot(512,0),snapshot(513,1)]);
assert.equal(E.source(snaps,513),1);checks++;
assert.equal(E.credited_killer(list([hit(512,0,4),hit(513,0,7)]),snaps,7200,7200,10,8,10,0),1);checks++;
{
 const out=E.apply(list([player(0),player(1,{px:7300})]),7200,7200,row(),G.empty_motion(),list([hit(512,0,7),hit(513,0,11)]),snaps);
 assert.equal(out.row.body.hp,82,'both players hit once');checks++;
}
{
 const p=list([player(0,{arcana:0}),player(1,{arcana:7,hp:0})]);
 const out=E.apply(p,7200,7200,row(),{...G.empty_motion(),burn:E.pack_burn(120,1)},nil,snaps);
 assert.equal(out.row.body.hp,96,'dead source retains its arcana for existing burn');
 assert.equal(E.burn_source(out.motion.burn),1);assert.equal(E.burn_duration(out.motion.burn),119);checks++;
}
{
 const out=E.apply(list([player(0),player(1,{arcana:7})]),7200,7200,row(),G.empty_motion(),list([hit(513,6,1)]),snaps);
 assert.equal(out.motion.burn,E.pack_burn(240,1),'new burn takes source duration modifier');checks++;
}
{
 const passives=Array(18).fill(0);passives[16]=4;
 const out=E.apply(list([player(0),player(1,{px:7300,passives:list(passives)})]),7200,7200,row(),G.empty_motion(),list([hit(513,2,1)]),snaps);
 assert.ok(out.row.body.x<7191,'knockback uses firing player direction and modifier');checks++;
 const immune=E.apply(list([player(0),player(1,{px:7300,passives:list(passives)})]),7200,7200,row({variant:30}),{...G.empty_motion(),slow:90},list([hit(513,2,1)]),snaps);
 assert.equal(immune.row.body.x,7200);assert.equal(immune.motion.slow,0);checks++;
}
{
 const passives=Array(18).fill(0);passives[10]=10;
 const out=E.apply(list([player(0),player(1,{passives:list(passives)})]),7200,7200,row({hp:10}),G.empty_motion(),list([hit(512,0,4),hit(513,0,7)]),snaps);
 assert.equal(out.row.body.kind,G.lucky_kind(8,10),'lethal hit source supplies Luck');assert.equal(out.row.killed,1);checks++;
}
// The multi-player resolver with an inert second participant agrees exactly
// with the established solo resolver across damage/status/effect combinations.
for(const weapon of [0,2,5,6,10,17,20,22])for(const arcana of [0,7,11])for(const slow of [0,90,65626])for(const burn of [0,120]){
 const p=player(0,{arcana}),r=row(),m={...G.empty_motion(),slow,burn},hs=list([hit(512,weapon,7)]);
 const expected=G.enemy_applied(7200,7200,r,m,G.collisions(hs,7200,7200,10,8),p.run);
 const actual=E.apply(list([p,player(1,{hp:0})]),7200,7200,r,m,hs,snaps);
 assert.deepEqual(actual,expected,`solo equivalence weapon=${weapon} arcana=${arcana} slow=${slow} burn=${burn}`);checks++;
}
assert.equal(E.cool_burn(E.pack_burn(1,1)),0,'expired status clears provenance');checks++;
// Gold and healing have exactly the same physical-only admission as XP.
// Item age cannot silently credit an unattended pile in either game mode.
for(const kind of [3,4])for(const age of [120,121,10000]){
 const item={$:'Body',x:9200,y:9200,kind,variant:0,hp:0,maxHp:0,age,seed:13,radius:6};
 const far=G.loot_update(item,run({px:7200,py:7200}));
 assert.equal(far.body.kind,kind,'old distant pickup remains on ground');
 assert.equal(far.gold,0);assert.equal(far.heal,0);
 const near=G.loot_update(item,run({px:9200,py:9200}));
 assert.equal(near.body.kind,8,'physical collector removes pickup');
 assert.ok((kind===3?near.gold:near.heal)>0,'physical collection receives intended payload');checks++;
}
console.log(`PASS co-op source effects: ${checks} provenance/status/solo-equivalence checks`);
