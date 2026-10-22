import test from 'node:test';
import assert from 'node:assert/strict';
import { buildUpgradeDecision, resolveCandidate } from './context.mjs';
const options={runId:'run-a',decisionSeq:3};
function frame(extra={}) {return {phase:1,tick:1000,px:1800,py:1800,hp:40,maxHp:100,xp:0,xpNeed:30,level:4,kills:25,gold:0,character:0,arcana:4,stage:0,mode:0,weapons:[1,...Array(23).fill(0)],passives:Array(18).fill(0),offers:[{kind:0,id:0,level:2},{kind:1,id:7,level:1},{kind:2,id:0,level:1}],bodies:[[1810,1800,0,0,10,10,0,1,8],[1900,1800,7,0,8,8,0,704,6]],...extra};}
function response(req,index=0){return {runId:req.runId,decisionSeq:req.decisionSeq,candidatesHash:req.candidatesHash,selectedCandidateId:req.candidates[index].id};}
test('context describes current build, relative health and actual bounded stats',()=>{
 const f=frame(),r=buildUpgradeDecision(f,{...options,history:[{tick:900,hp:80,action:'move'}]});
 assert.equal(r.snapshot.slots.weaponsFree,5);assert.equal(r.snapshot.threats.hostileProjectiles,1);assert.equal(r.snapshot.threats.within60,1);
 assert.equal(r.snapshot.recentHealthLoss.observedNetLoss,40);assert.equal(r.candidates[1].effect.maxHpIncrease,20);assert.equal(r.candidates[1].effect.statsAfter.armor,3);
 assert.equal(r.candidates[2].effect.immediateHealing,30);assert.equal(resolveCandidate(r,response(r,1),f,options),1);
 const changed=frame({hp:95});assert.equal(buildUpgradeDecision(changed,options).candidates[2].effect.immediateHealing,5);
 assert.notEqual(buildUpgradeDecision(changed,options).candidates[0].id,r.candidates[0].id);
});
test('source evolution and AND union prerequisites, slot removal and rewards',()=>{
 const f=frame({phase:2,offers:[{kind:3,id:0,level:9},{kind:5,id:0,level:10},{kind:4,id:0,level:50}]});f.weapons[0]=8;f.weapons[5]=9;f.passives[1]=1;
 const r=buildUpgradeDecision(f,options);assert.equal(r.snapshot.progression.evolutions[0].eligibleNow,true);assert.equal(r.snapshot.progression.unions[0].eligibleNow,true);
 assert.equal(r.candidates[0].effect.gold,25);assert.equal(r.candidates[1].effect.weaponSlotsFreed,1);assert.equal(r.candidates[1].effect.removedWeapon.id,5);assert.equal(r.candidates[2].effect.gold,50);
 f.weapons[5]=7;assert.equal(buildUpgradeDecision(f,options).snapshot.progression.unions[0].eligibleNow,false);
 f.weapons[0]=9;assert.equal(buildUpgradeDecision(f,options).snapshot.progression.evolutions[0].eligibleNow,false);
});
test('actual list cardinality and duplicate effects preserve distinct real indices',()=>{
 for(const offers of [[],[{kind:2,id:0,level:1}],Array(4).fill({kind:2,id:0,level:1})]){
 const f=frame({offers}),r=buildUpgradeDecision(f,options);assert.equal(r.candidates.length,offers.length);assert.equal(new Set(r.candidates.map(c=>c.id)).size,offers.length);
 if(offers.length)assert.equal(resolveCandidate(r,response(r,offers.length-1),f,options),offers.length-1);
 }
});
test('stale identities, same-tick offers and changed observations rejected',()=>{
 const f=frame(),r=buildUpgradeDecision(f,options),ok=response(r);
 for(const bad of [null,'id',{}, {...ok,selectedCandidateId:'unknown'},{...ok,runId:'other'},{...ok,decisionSeq:4},{...ok,candidatesHash:'bad'}]) assert.throws(()=>resolveCandidate(r,bad,f,options));
 assert.throws(()=>resolveCandidate(r,ok,frame({hp:39}),options));assert.throws(()=>resolveCandidate(r,ok,frame({offers:[{kind:4,id:0,level:50}]}),options));
 assert.throws(()=>resolveCandidate(r,ok,f,{...options,decisionSeq:4}));
 const dup=structuredClone(r);dup.candidates[1].id=dup.candidates[0].id;assert.throws(()=>resolveCandidate(dup,ok,f,options));
});
test('stage hazard and mode horizon are actual mechanics, not just flavor',()=>{
 const r=buildUpgradeDecision(frame({stage:2,tick:660,px:1100,py:1100,mode:3}),options);
 assert.equal(r.snapshot.hazards.inHazardZone,true);assert.equal(r.snapshot.hazards.rawPulseDamage,4);assert.equal(r.snapshot.hazards.ticksUntilNextPulse,0);assert.equal(r.snapshot.facts.durationTicks,18000);
 assert.match(buildUpgradeDecision(frame({mode:2}),options).snapshot.objective,/no dawn/);
 assert.throws(()=>buildUpgradeDecision(frame({phase:0}),options));
});
test('full slots and cooldown cap reveal marginal benefits without preferred answer',()=>{
 const f=frame();f.weapons=Array.from({length:24},(_,id)=>id<6?8:0);f.passives[1]=5;
 const r=buildUpgradeDecision(f,{...options,meta:5<<(4*3)});assert.equal(r.snapshot.slots.weaponsFree,0);
 assert.ok(r.snapshot.weapons.every(w=>w.estimates.cooldownTicks>=6));assert.equal(r.snapshot.currentStats.xpMultiplier,null);
 assert.equal('preferredCandidateId' in r,false);assert.equal('score' in r.candidates[0],false);
});
test('rank thresholds, evolved behavior and capped extra projectiles are visible',()=>{
 const f=frame({offers:[{kind:0,id:0,level:3}]});f.weapons[0]=2;
 const e=buildUpgradeDecision(f,options).candidates[0].effect;
 assert.equal(e.before.projectilesPerVolley,1);assert.equal(e.after.projectilesPerVolley,2);
 f.passives[4]=5;f.weapons[0]=9;f.arcana=3;
 const w=buildUpgradeDecision(f,options).snapshot.weapons[0];assert.equal(w.projectilesPerVolley,8);assert.equal(w.alternatesWith.length,1);assert.notEqual(w.behavior,w.baseBehavior);
});

const {buildGoalDecision,resolveGoalCandidate}=await import('./context.mjs');
function goals(f) {
 return ['north','east','south','west'].map((dir,i)=>({id:`t${f.tick}:move_${dir}:${dir}`,kind:`move_${dir}`,target:{x:f.px+([0,160,0,-160][i]),y:f.py+([-160,0,160,0][i])},distance:160,observedTick:f.tick,executable:false,safety:'unassessed'}));
}
test('goal requests use actual engine intents, informative warnings and snapshot threat geometry',()=>{
 const f=frame({phase:0}),catalog=goals(f);
 catalog.push({id:'wisp',kind:'approach_wisp',target:{x:1900,y:1800},distance:100,observedTick:f.tick,executable:false});
 const r=buildGoalDecision(f,catalog,options);assert.equal(r.kind,'goal');assert.equal(r.candidates.length,5);assert.equal(r.snapshot.facts.phase,0);
 assert.match(r.snapshot.goalExecution.loot,/120 ticks/);assert.match(r.candidates[4].description,/strictly below 100/);assert.match(r.candidates[4].description,/only if/);assert.equal(r.candidates[4].effect.safety,'unassessed');
 assert.equal(resolveGoalCandidate(r,response(r,4),f,catalog,options),catalog[4]);
});
test('goal choices omit no-ops, cap targets by actual nearest geometry, retain cardinals',()=>{
 const f=frame({phase:0}),catalog=goals(f);catalog[0].distance=0;catalog[0].target={x:f.px,y:f.py};
 for(let i=0;i<8;i++)catalog.push({id:`chest${i}`,kind:'approach_chest',target:{x:1900+i*10,y:1800},distance:100+i*10,observedTick:f.tick});
 const r=buildGoalDecision(f,catalog,options);assert.equal(r.candidates.length,7);assert.equal(r.candidates.some(c=>c.engineGoalId===catalog[0].id),false);assert.equal(r.candidates.at(-1).engineGoalId,'chest3');
 assert.throws(()=>buildGoalDecision(f,[],options));
});
test('goal resolution rejects stale frame/catalog/envelope and unknown IDs',()=>{
 const f=frame({phase:0}),catalog=goals(f),r=buildGoalDecision(f,catalog,options),ok=response(r);
 assert.throws(()=>resolveGoalCandidate(r,{...ok,selectedCandidateId:'bad'},f,catalog,options));
 assert.throws(()=>resolveGoalCandidate(r,ok,{...f,hp:39},catalog,options));
 assert.throws(()=>resolveGoalCandidate(r,ok,f,catalog.slice(1),options));
 assert.throws(()=>resolveGoalCandidate(r,ok,f,catalog,{...options,decisionSeq:99}));
 const changed=structuredClone(catalog);changed[0].target.x+=1;assert.throws(()=>resolveGoalCandidate(r,ok,f,changed,options));
 assert.throws(()=>buildGoalDecision(f,[...catalog,catalog[0]],options));
});
test('authoritative Bend mechanics override explanatory fallback and bind every actual offer',()=>{
 const f=frame();
 const engineMechanics={source:'Bend G functions + G.upgrade preview',current:{earnedXpFor100:100,armor:3},offers:f.offers.map((offer,offerIndex)=>({offerIndex,offer:{...offer},after:{hp:99,earnedXpFor100:110}}))};
 const r=buildUpgradeDecision(f,{...options,engineMechanics});assert.equal(r.snapshot.engineMechanics.current.earnedXpFor100,100);assert.equal(r.candidates[1].effect.enginePreview.hp,99);assert.match(r.snapshot.mechanicsPriority,/authoritative Bend/);
 const goal=buildGoalDecision(f,goals(f),{...options,engineMechanics});assert.equal(goal.snapshot.engineMechanics.available,true);
 const wrong=structuredClone(engineMechanics);wrong.offers[0].offer.id=4;assert.throws(()=>buildUpgradeDecision(f,{...options,engineMechanics:wrong}));
 const duplicate=structuredClone(engineMechanics);duplicate.offers[1].offerIndex=0;assert.throws(()=>buildUpgradeDecision(f,{...options,engineMechanics:duplicate}));
 assert.throws(()=>buildUpgradeDecision(f,{...options,engineMechanics:{...engineMechanics,offers:[]}}));
 assert.equal(buildUpgradeDecision(f,options).snapshot.engineMechanics.available,false);
});


test('fresh reachable XP gets a classifier slot; expired, blocked and distant XP do not',()=>{
 const f=frame({phase:0,bodies:[[1860,1800,2,0,0,10,20,42,6]],offers:[]});
 const xp={id:`t${f.tick}:approach_experience:42:2:0:20`,kind:'approach_experience',target:{x:1860,y:1800},distance:60,observedTick:f.tick};
 const catalog=[...goals(f),...Array.from({length:6},(_,i)=>({id:`ward${i}`,kind:'approach_ward',target:{x:1820+i,y:1800},distance:20+i,observedTick:f.tick})),xp];
 const r=buildGoalDecision(f,catalog,options);
 assert.equal(r.candidates.length,8);assert.ok(r.candidates.some(c=>c.goal.kind==='approach_experience'));
 const unavailable=[
  {...f,bodies:[[1860,1800,2,0,0,10,119,42,6]]},
  {...f,bodies:[...f.bodies,[1830,1800,0,0,10,10,0,1,8]]},
  {...f,bodies:[]}
 ];
 for(const changed of unavailable) assert.equal(buildGoalDecision(changed,catalog,options).candidates.some(c=>c.goal.kind==='approach_experience'),false);
});
