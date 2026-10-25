import { createHash } from 'node:crypto';
import { WEAPONS, PASSIVES, CHARACTERS, STAGES, ARCANA, UNIONS, RUN_MODES } from '../../examples/survivors/content.mjs';

// Mirrors game.bend's observable rules. These are explanatory estimates, never
// a second implementation deciding legality: the engine's offers are authoritative.
const hash = (value) => createHash('sha256').update(JSON.stringify(value)).digest('hex');
const rank = (values, id) => values?.[id] ?? 0;
const occupied = (values) => values.filter((n) => n > 0).length;
const metaRank = (meta, id) => Math.min(id === 3 ? 3 : id === 9 ? 2 : 5, (meta >>> (id * 3)) & 7);
const period = (id) => [40,30,90,14,24,120,70,110,80,65,100,600][id] ?? 35 + (id % 6) * 13;
const safeCopy = (value) => JSON.parse(JSON.stringify(value));
const observationHash = (frame) => hash(frame);

function offersOf(frame) {
  if (!Array.isArray(frame.offers)) throw new Error('Missing engine offers');
  return frame.offers.map((offer) => {
    if (![0,1,2,3,4,5].includes(offer.kind) || !Number.isInteger(offer.id) || !Number.isInteger(offer.level) || offer.id < 0 || offer.level < 0) throw new Error('Invalid engine offer');
    if ([0,3].includes(offer.kind) && !WEAPONS[offer.id] || offer.kind === 1 && !PASSIVES[offer.id] || offer.kind === 5 && !UNIONS[offer.id]) throw new Error('Unknown engine catalog ID');
    return { kind: offer.kind, id: offer.id, level: offer.level };
  });
}

function validateMechanics(mechanics, offers) {
  if (mechanics === undefined) return {available:false, qualification:'No authoritative engine mechanics supplied. JS arithmetic estimates are non-authoritative fallbacks.'};
  if (!mechanics || typeof mechanics.source !== 'string' || !mechanics.source || !mechanics.current || typeof mechanics.current !== 'object' || Array.isArray(mechanics.current) || !Array.isArray(mechanics.offers)) throw new Error('Invalid engine mechanics');
  const indices=new Set();
  for(const preview of mechanics.offers) {
    const index=preview?.offerIndex;
    if(!Number.isInteger(index)||index<0||index>=offers.length||indices.has(index)||hash(preview.offer)!==hash(offers[index])||!preview.after||typeof preview.after!=='object'||Array.isArray(preview.after)) throw new Error('Engine preview does not match actual offer');
    indices.add(index);
  }
  if(indices.size!==offers.length) throw new Error('Missing engine offer preview');
  return {...safeCopy(mechanics),available:true};
}

function weaponFacts(id, level, f, meta) {
  const p = f.passives;
  const a = f.arcana;
  const c = f.character;
  const evolved = level >= 9;
  const might = (1 + rank(p,0)*.10 + metaRank(meta,0)*.05 + .35*(a===0) + .15*(a===8) + .10*(c===0) + .20*(c===6))*(1-.15*(a===4))*(1+(.20+rank(p,14)*.05)*(a===5 && [9,11].includes(id)));
  const cooldown = Math.max(6,Math.floor(period(id)*Math.max(.12,1-rank(p,1)*.07-metaRank(meta,4)*.03-.20*(a===1)-.10*(c===5)+.15*(a===3))));
  return { id, name: level >= 10 ? UNIONS[level-10]?.name : evolved ? WEAPONS[id].evolvedName : WEAPONS[id].name, rank: level, evolved, unionId: level >= 10 ? level-10 : null,
    baseBehavior: WEAPONS[id].description,
    behavior: level >= 10 ? UNIONS[level-10]?.description : evolved ? WEAPONS[id].evolvedDescription : WEAPONS[id].description,
    alternatesWith: level >= 10 ? [WEAPONS[UNIONS[level-10].weapons[1]].description,WEAPONS[UNIONS[level-10].thirdWeapon].description] : evolved ? [WEAPONS[WEAPONS[id].evolutionSecondary].description] : [],
    projectilesPerVolley: Math.min(8,1+rank(p,4)+Math.floor(level/3)+(a===3)+(id===21)), projectileCap:8,
    estimates: { qualification: 'Non-authoritative JS fallback mirror of game.bend; source changes and F32 rounding may differ. Damage is a base-behavior estimate; evolved/union alternating projectile IDs can change it. Per-hit damage is not DPS, hit rate or projected survival.', damagePerHit: Math.floor((5+level*3+(id%4)*2)*might*(1+1.2*evolved)), cooldownTicks: cooldown,
      areaMultiplier: (1+rank(p,2)*.10+.35*(a===2)+.15*(a===11)+level*.025)*(1-.15*(a===1))*(1+.35*evolved) },
    evolution: { requiresWeaponRankExactly: 8, passiveId: WEAPONS[id].passive, passiveName: PASSIVES[WEAPONS[id].passive].name, requiresPassiveRankAtLeast: 1, currentPassiveRank: rank(p,WEAPONS[id].passive), eligibleNow: level === 8 && rank(p,WEAPONS[id].passive)>0, acquisition: 'Only when actually offered by a chest; readiness does not guarantee a current offer.' } };
}

function aggregateStats(f,meta) {
  const p=f.passives,a=f.arcana,c=f.character;
  return { qualification:'Non-authoritative JS fallback mirror; may drift from Bend source and floating-point rounding may differ. Multipliers are not a combat outcome prediction.',
    movementMultiplier:(1+rank(p,5)*.10+metaRank(meta,5)*.05+.15*(c===1)+.30*(a===10))*(1-.15*(a===2)),
    armor:rank(p,6)+metaRank(meta,3)+3*(a===4)+(c===3),
    baseContactDamage:Math.max(1,9-rank(p,6)-metaRank(meta,3)-3*(a===4)-(c===3)),
    armorLimit:'Contact additionally adds minute, crowd and final-minute pressure; armor does not remove these terms or stage hazards.',
    regenerationPerSecond:(metaRank(meta,2)+rank(p,11)+2*(a===9)+(c===2))*(100+rank(p,17)*20+30*(a===10))/100,
    healingMultiplier:(100+rank(p,17)*20+30*(a===10))/100,
    pickupRadius:24*(1+rank(p,8)*.25+metaRank(meta,6)*.15+(a===6)+.50*(c===7)),
    durationMultiplier:1+rank(p,3)*.15+.50*(a===7),
    projectileSpeedMultiplier:(1+rank(p,12)*.15+.50*(a===8))*(1-.20*(a===7)),
    xpMultiplier:null, xpQualification:'Unknown without authoritative engine mechanics; XP balance is controlled by Bend.',
    goldMultiplier:(100+rank(p,15)*15+rank(p,14)*10+50*(f.mode===1)+metaRank(meta,8)*10+25*(a===6))/100,
    projectileCountByWeapon:f.weapons.flatMap((n,id)=>n>0?[{id,count:Math.min(8,1+rank(p,4)+Math.floor(n/3)+(a===3)+(id===21))}]:[]) };
}

function prerequisites(f) {
  return {
    evolutions: WEAPONS.map((w) => ({ weaponId:w.id, weaponName:w.name, currentWeaponRank:rank(f.weapons,w.id), requiredWeaponRankExactly:8, passiveId:w.passive, passiveName:PASSIVES[w.passive].name, currentPassiveRank:rank(f.passives,w.passive), requiredPassiveRankAtLeast:1, eligibleNow:rank(f.weapons,w.id)===8 && rank(f.passives,w.passive)>0 })),
    unions: UNIONS.map((u) => ({ id:u.id, name:u.name, ingredients:u.weapons.map((id)=>({id,name:WEAPONS[id].name,currentRank:rank(f.weapons,id),requiredRankRange:[8,9]})), eligibleNow:u.weapons.every((id)=>[8,9].includes(rank(f.weapons,id))), effects:'Chest-only offer. Removes partner weapon, sets base weapon to union rank 10 + union ID, frees one weapon slot, heals up to 30 and grants 50 run gold.', thirdBehavior:WEAPONS[u.thirdWeapon].description }))
  };
}

function hazards(f) {
  const periods=[360,420,240,300,180], pulses=[300,360,180,240,120];
  const i=f.stage??0, x=Math.max(0,Math.trunc(f.px)), y=Math.max(0,Math.trunc(f.py));
  const zones=[x%480<65&&y%480<65,x%640<70&&y%640>150,x%400>240&&y%400>240,(x+y)%700<95,x%520<100&&y%520<160];
  const cross=Math.abs(f.px-(f.worldSize??14400)/2)<=90 || Math.abs(f.py-(f.worldSize??14400)/2)<=90;
  return { source:'encounters.bend hazard; exact stationary zone and pulse rules, not a damage forecast', enabledAfterTick:600, centralCrossSafe:cross, inHazardZone:zones[i] && !cross, pulsePeriodTicks:periods[i], pulseAtRemainder:pulses[i], ticksUntilNextPulse:(pulses[i]-f.tick%periods[i]+periods[i])%periods[i], rawPulseDamage:2+i, warning:'Invulnerability may suppress damage; invulnerability is not exposed in frame JSON.' };
}

function threats(f) {
  const enemies=f.enemies.filter(enemy=>enemy.health>0);
  const distances=enemies.map((b)=>Math.hypot(b.x-f.px,b.y-f.py));
  return { source:'Observed typed enemy and projectile records; geometric counts, not predicted danger or DPS.', livingEnemies:enemies.length, within60:distances.filter((d)=>d<=60).length, within150:distances.filter((d)=>d<=150).length, nearestEnemyDistance:distances.length?Math.min(...distances):null, bosses:enemies.filter((b)=>b.archetype>=20&&b.archetype<30).length, dawnReapers:enemies.filter((b)=>b.archetype===30).length, hostileProjectiles:f.projectiles.filter(projectile=>projectile.hostile).length };
}

function candidateEffect(o,f,meta) {
  if(o.kind===0) { const before=rank(f.weapons,o.id); return { type:'weapon', name:WEAPONS[o.id].name, currentRank:before, resultingRank:before+1, consumesWeaponSlot:before===0, before:before?weaponFacts(o.id,before,f,meta):null, after:weaponFacts(o.id,before+1,f,meta), note:'Engine increments current rank; offer.level is display metadata. A new weapon uses one of six weapon slots.' }; }
  if(o.kind===1) { const before=rank(f.passives,o.id); const hpIncrease=o.id===7?Math.floor(f.maxHp*20/(100+before*20)):0; return { type:'passive', name:PASSIVES[o.id].name, currentRank:before, resultingRank:before+1, consumesPassiveSlot:before===0, rule:PASSIVES[o.id].description, maxHpIncrease:hpIncrease, immediateHealing:Math.min(hpIncrease,Math.max(0,f.maxHp+hpIncrease-f.hp)), note:o.id===14?'Curse increases enemy health and admitted count as well as XP/gold; stronger rewards increase combat pressure.':o.id===13?'Adds a full-health revival allowance; remaining allowance also depends on revivals already used.':'Ranks stack with hero, Arcana and permanent upgrades; caps/floors can reduce marginal benefit.' }; }
  if(o.kind===2) return {type:'heal',name:'Restore health',immediateHealing:Math.min(30,Math.max(0,f.maxHp-f.hp)),rule:'Heals up to 30 HP; no permanent combat stat increase.'};
  if(o.kind===3) return {type:'evolution',name:WEAPONS[o.id].evolvedName,currentRank:rank(f.weapons,o.id),resultingRank:rank(f.weapons,o.id)===8?9:Math.min(9,rank(f.weapons,o.id)),immediateHealing:Math.min(20,Math.max(0,f.maxHp-f.hp)),gold:25,rule:WEAPONS[o.id].evolvedDescription,after:weaponFacts(o.id,9,f,meta)};
  if(o.kind===4) return {type:'gold',name:`${o.level} run gold`,gold:o.level,rule:'Adds run gold; no immediate healing or combat improvement. Gold supports future permanent progression.'};
  const u=UNIONS[o.id]; return {type:'union',name:u.name,removedWeapon:{id:u.weapons[1],name:WEAPONS[u.weapons[1]].name},baseWeaponId:u.weapons[0],resultingRank:10+o.id,weaponSlotsFreed:rank(f.weapons,u.weapons[1])>0?1:0,immediateHealing:Math.min(30,Math.max(0,f.maxHp-f.hp)),gold:50,rule:u.description,note:'Alternates base, partner and third weapon behaviors; partner slot is removed. Union rank is an encoding, not ordinary upgrade level.'};
}

export function buildUpgradeDecision(frame,{runId,decisionSeq,meta=0,history=[],engineMechanics}={}) {
  if(typeof runId!=='string'||!runId||!Number.isSafeInteger(decisionSeq)||decisionSeq<0) throw new Error('Require runId and nonnegative decisionSeq');
  if(![1,2].includes(frame.phase)) throw new Error('No pending upgrade or chest decision');
  const offers=offersOf(frame), mechanics=validateMechanics(engineMechanics,offers), candidatesHash=hash(offers), observation=observationHash(frame);
  const f=safeCopy(frame), durationTicks=f.runLength??(f.mode===3?18000:36000);
  const recent=history.filter((h)=>Number.isFinite(h.tick)&&h.tick<=f.tick&&f.tick-h.tick<=600);
  const snapshots=recent.filter((h)=>Number.isFinite(h.hp));
  const recentHealthLoss=snapshots.length?{windowTicks:600,observedNetLoss:Math.max(0,snapshots[0].hp-f.hp),qualification:'Net HP change only; healing and revivals can hide damage. Depends on caller sampling.'}:{windowTicks:600,observedNetLoss:null,qualification:'No recent HP observations supplied.'};
  const snapshot={ objective:f.mode===2?'Survive as long as possible; Endless has no dawn completion.':'Survive until dawn, then survive until the Dawn Reaper makes lethal contact to complete the run. Do not intentionally die before dawn.',
    facts:{tick:f.tick,seconds:f.tick/60,phase:f.phase,rewardType:f.phase===2?'chest':'level',hp:f.hp,maxHp:f.maxHp,hpFraction:f.hp/Math.max(1,f.maxHp),level:f.level,xp:f.xp,xpNeed:f.xpNeed,kills:f.kills,gold:f.gold,position:{x:f.px,y:f.py},worldSize:f.worldSize??14400,worldCenter:(f.worldSize??14400)/2,worldMargin:f.worldMargin??128,hero:CHARACTERS[f.character],arcana:ARCANA[f.arcana],stage:STAGES[f.stage],mode:RUN_MODES[f.mode],durationTicks,ticksUntilDawn:Math.max(0,durationTicks-f.tick),permanentUpgradeBits:meta,revivalsUsed:f.revivalsUsed??0,revivalsRemaining:Math.max(0,metaRank(meta,9)+rank(f.passives,13)-(f.revivalsUsed??0)),rerolls:f.rerolls,banishes:f.banishes,skips:f.skips},
    slots:{weaponLimit:6,weaponsOccupied:occupied(f.weapons),weaponsFree:Math.max(0,6-occupied(f.weapons)),passiveLimit:6,passivesOccupied:occupied(f.passives),passivesFree:Math.max(0,6-occupied(f.passives))},
    weapons:f.weapons.flatMap((n,id)=>n>0?[weaponFacts(id,n,f,meta)]:[]),passives:f.passives.flatMap((n,id)=>n>0?[{id,name:PASSIVES[id].name,rank:n,rule:PASSIVES[id].description}]:[]),
    engineMechanics:mechanics, mechanicsPriority:'When provided, engineMechanics.current and candidate.effect.enginePreview are authoritative Bend calculations. JS estimates and catalog descriptions are explanatory fallbacks and may drift; prefer the engine values on disagreement.', currentStats:aggregateStats(f,meta),progression:prerequisites(f),hazards:hazards(f),threats:threats(f),recentHealthLoss,actionHistory:safeCopy(history.slice(-12)),
    limits:['Only candidates listed below may be selected. Reroll, skip and banish are not candidates in this experiment.','No simulated rollouts, damage forecast or guaranteed best answer is provided.','Damage/area estimates mirror source arithmetic but do not measure real DPS; projectile collisions and pool occupancy matter.','Frame does not expose invulnerability, pending reward count, enemy velocity or future random choices.'],sources:['examples/survivors/game.bend','examples/survivors/encounters.bend','examples/survivors/content.mjs']};
  const candidates=offers.map((offer,offerIndex)=>{const effect=candidateEffect(offer,f,meta); if(mechanics.available) effect.enginePreview=mechanics.offers.find((preview)=>preview.offerIndex===offerIndex).after;
    if(offer.kind===1){ const after=safeCopy(f); after.passives[offer.id]=(after.passives[offer.id]??0)+1; effect.statsAfter=aggregateStats(after,meta); effect.weaponsAfter=after.weapons.flatMap((n,id)=>n>0?[weaponFacts(id,n,after,meta)]:[]); effect.recipeChanges=prerequisites(after).evolutions.filter((recipe)=>recipe.passiveId===offer.id); }
    return {id:`upgrade:${hash([runId,decisionSeq,candidatesHash,observation,offerIndex]).slice(0,24)}`,offerIndex,offer,effect,description:JSON.stringify({offerIndex,offer,effect})};});
  return {runId,decisionSeq,candidatesHash,observationHash:observation,kind:'upgrade',snapshot,candidates};
}

export function resolveCandidate(request,response,currentFrame,{runId,decisionSeq}={}) {
  if(!response||typeof response!=='object'||Array.isArray(response)) throw new Error('Require classifier response envelope');
  if(request.runId!==runId||response.runId!==runId||request.decisionSeq!==decisionSeq||response.decisionSeq!==decisionSeq||response.candidatesHash!==request.candidatesHash) throw new Error('Stale decision identity');
  if(![1,2].includes(currentFrame.phase)||hash(offersOf(currentFrame))!==request.candidatesHash||observationHash(currentFrame)!==request.observationHash) throw new Error('Stale game observation');
  const ids=request.candidates.map((c)=>c.id);
  if(new Set(ids).size!==ids.length) throw new Error('Duplicate candidate IDs');
  const selected=response.selectedCandidateId;
  const matches=request.candidates.filter((c)=>c.id===selected);
  if(matches.length!==1) throw new Error('Unknown or missing candidate ID');
  const candidate=matches[0];
  if(!Number.isInteger(candidate.offerIndex)||candidate.offerIndex<0||candidate.offerIndex>=currentFrame.offers.length||hash(candidate.offer)!==hash(offersOf(currentFrame)[candidate.offerIndex])) throw new Error('Invalid candidate index');
  return candidate.offerIndex;
}

const GOAL_KINDS = new Set(['move_north','move_east','move_south','move_west','approach_chest','approach_relic','approach_experience']);
function catalogOf(frame, catalog) {
  if (!Array.isArray(catalog)) throw new Error('Require engine goal catalog');
  const ids = new Set();
  for (const g of catalog) {
    if (!g || typeof g.id !== 'string' || !g.id || ids.has(g.id) || !GOAL_KINDS.has(g.kind) || g.observedTick !== frame.tick || !Number.isFinite(g.distance) || g.distance < 0 || !Number.isFinite(g.target?.x) || !Number.isFinite(g.target?.y) || g.target.x < (frame.worldMargin??128) || g.target.x > (frame.worldSize??14400)-(frame.worldMargin??128) || g.target.y < (frame.worldMargin??128) || g.target.y > (frame.worldSize??14400)-(frame.worldMargin??128)) throw new Error('Invalid, duplicate or expired engine goal');
    if(g.kind==='approach_experience') {
      const [slot,itemKind,ageText]=g.id.split(':').slice(2),age=Number(ageText),r=g.resource;
      if(!r || !Number.isSafeInteger(r.baseXp)||r.baseXp<=0 || !Number.isSafeInteger(r.generation)||r.generation<0 || r.autoClaimTicks!==null || !frame.pickups.some(p=>p.active&&p.slot===Number(slot)&&p.item.kind===itemKind&&itemKind==='xp'&&p.age===age&&p.item.amount===r.baseXp&&p.generation===r.generation&&p.x===g.target.x&&p.y===g.target.y)) throw new Error('XP goal does not match a current persistent engine pile');
    }
    ids.add(g.id);
  }
  return catalog;
}

// Persistent resource candidates are ranked by cluster value, distance and risk.
// Navigation and temporal memory live in the shared spatial planner.
export function experienceGoals(frame, catalog) {
  return catalog.filter(g => g.kind === 'approach_experience').sort((a,b) =>
    (b.resource?.baseXp??0)/Math.max(24,b.distance) - (a.resource?.baseXp??0)/Math.max(24,a.distance) || a.id.localeCompare(b.id));
}

export function buildGoalDecision(frame, engineCatalog, {runId,decisionSeq,meta=0,history=[],engineMechanics,planner}={}) {
  if (![0,1,2].includes(frame.phase)) throw new Error('Cannot choose movement goal for ended run');
  const catalog=catalogOf(frame,engineCatalog);
  const available=catalog.filter((g)=>g.distance>=1 && Math.hypot(g.target.x-frame.px,g.target.y-frame.py)>=1);
  const cards=available.filter((g)=>g.kind.startsWith('move_'));
  const xp=experienceGoals(frame,available).slice(0,3);
  const entities=[...xp,...available.filter((g)=>g.kind.startsWith('approach_') && g.kind!=='approach_experience').sort((a,b)=>a.distance-b.distance || a.id.localeCompare(b.id))].slice(0,4);
  const proposed=planner?.candidates?.map(c=>catalog.find(g=>g.id===c.goal.id)).filter(Boolean);
  const selected=proposed?.length>=2 ? proposed.slice(0,8) : [...cards,...entities];
  if(selected.length<2 || selected.length>8) throw new Error('Goal classification requires 2 to 8 actual choices');
  const base=buildUpgradeDecision({...frame,phase:1,offers:frame.offers??[]},{runId,decisionSeq,meta,history,engineMechanics});
  const snapshot=base.snapshot;
  snapshot.facts.phase=frame.phase;
  delete snapshot.facts.rewardType;
  snapshot.spatialPlanner=planner ? safeCopy({reason:planner.reason,search:planner.search,memory:{resources:Object.keys(planner.memory?.objects??{}).length,clusters:(planner.clusters??[]).slice(0,8).map(c=>({id:c.id,reward:c.reward,x:c.x,y:c.y,firstSeen:c.firstSeen,members:c.members?.length??0}))},selectedPlan:planner.chosen?.goal?.id??null}) : null;
  snapshot.goalExecution={safety:'unassessed',method:'Choose an intent; controller steers using ordinary game movement, local enemy avoidance and persistent route memory, bounded searches and short movement batches. No teleport or direct reward grant.',warning:'Observed distance is geometric distance, not a safe route, arrival guarantee or viewport visibility. Snapshot goal IDs expire; persistent resource identities and routes are revalidated while moving.',loot:'XP drops persist until collected within the engine pickup radius. Plan visits to valuable clusters, account for danger and remember routes; there is no timed XP auto-claim. Gold and healing follow their separate engine rules. Chests and relics require approach.'};
  snapshot.limits[0]='Select only a listed engine goal. This decision does not select upgrades or invoke an executable engine command.';
  const candidatesHash=hash(selected), observation=observationHash(frame);
  const descriptions={
    approach_experience:'Collect a real persistent XP cluster within the engine pickup radius. Compare value, travel time, route danger and current upgrade progress. The cluster remains until collected; merging can increase its value while keeping its identity.',
    approach_chest:'Approach a real chest. Collection grants a reward choice; evolution/union eligibility depends on the current build. Travel and collection are not guaranteed safe.',
    approach_relic:'Approach the stage relic, which unlocks its associated weapon for future runs. It does not guarantee immediate combat power or a safe route.',
  };
  const enemies=frame.enemies.filter(enemy=>enemy.health>0);
  const candidates=selected.map((goal)=>{
    const targetThreats=enemies.map((b)=>Math.hypot(b.x-goal.target.x,b.y-goal.target.y));
    const effect={intent:goal.kind,target:safeCopy(goal.target),distance:goal.distance,safety:'unassessed',targetGeometry:{enemiesWithin60:targetThreats.filter(d=>d<=60).length,enemiesWithin150:targetThreats.filter(d=>d<=150).length,nearestEnemyDistance:targetThreats.length?Math.min(...targetThreats):null,qualification:'Snapshot geometry only. Does not assess the path, moving enemies, projectile danger or time to arrival.'},rule:descriptions[goal.kind]??'Move toward this bounded cardinal point. This is a geometric direction, not a guaranteed safe retreat or beneficial maneuver.'};
    if(goal.kind==='approach_experience') {
      const [slot,itemKind,ageText]=goal.id.split(':').slice(2),age=Number(ageText);
      effect.resource={...safeCopy(goal.resource??{}),kind:'experience',slot:Number(slot),itemKind,ageTicks:age,autoClaimTicks:null,pickupRadius:engineMechanics?.current?.pickupRadius??null,benefit:'Collect experience to progress toward the next upgrade; XP persists until approached.'};
    }
    const route=planner?.candidates?.find(c=>c.goal.id===goal.id);
    if(route) effect.route=safeCopy({waypoints:route.waypoints,risk:route.risk,etaTicks:route.etaTicks,reward:route.reward,length:route.length,clusterId:route.clusterId,partial:route.partial??false,qualification:'Bounded local-window route; remaining distance is a straight-line estimate and risk beyond the local segment is unassessed. Not a guarantee against moving threats.'});
    return {id:`goal:${hash([runId,decisionSeq,candidatesHash,observation,goal.id]).slice(0,24)}`,engineGoalId:goal.id,goal:safeCopy(goal),effect,description:JSON.stringify(effect)};
  });
  return {runId,decisionSeq,candidatesHash,observationHash:observation,catalogHash:hash(catalog),kind:'goal',snapshot,candidates};
}

export function resolveGoalCandidate(request,response,currentFrame,currentEngineCatalog,{runId,decisionSeq}={}) {
  if(request.kind!=='goal'||!response||typeof response!=='object'||Array.isArray(response)||request.runId!==runId||response.runId!==runId||request.decisionSeq!==decisionSeq||response.decisionSeq!==decisionSeq||response.candidatesHash!==request.candidatesHash) throw new Error('Stale goal decision identity');
  const catalog=catalogOf(currentFrame,currentEngineCatalog);
  if(![0,1,2].includes(currentFrame.phase)||observationHash(currentFrame)!==request.observationHash||hash(catalog)!==request.catalogHash||hash(request.candidates.map(c=>c.goal))!==request.candidatesHash) throw new Error('Stale goal observation');
  const ids=request.candidates.map(c=>c.id);
  if(new Set(ids).size!==ids.length) throw new Error('Duplicate goal candidate IDs');
  const matches=request.candidates.filter(c=>c.id===response.selectedCandidateId);
  if(matches.length!==1) throw new Error('Unknown or missing goal candidate ID');
  const candidate=matches[0], goal=catalog.find(g=>g.id===candidate.engineGoalId);
  if(!goal||hash(goal)!==hash(candidate.goal)||goal.distance<1) throw new Error('Goal no longer available');
  return goal;
}
