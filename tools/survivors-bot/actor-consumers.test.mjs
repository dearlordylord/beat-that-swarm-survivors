import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
import {actorThreats,createPlanner,planMovement,routePath} from './planner.mjs';
import {steering,runBot} from './runner.mjs';
import {buildGoalDecision,buildUpgradeDecision} from './context.mjs';
const frame={tick:100,phase:0,px:1800,py:1800,hp:100,maxHp:100,level:1,xp:0,xpNeed:10,kills:0,gold:0,character:0,arcana:0,stage:0,mode:0,weapons:Array(24).fill(0),passives:Array(16).fill(0),offers:[],enemies:[{identity:5,x:1900,y:1800,radius:12,health:20,maximum:20,archetype:21,age:40}],projectiles:[{identity:8,x:1850,y:1800,radius:4,hostile:true,lifetime:'8:80'},{identity:9,x:1700,y:1800,radius:4,hostile:false,lifetime:'9:90'}],pickups:[{slot:4,generation:10,age:90,active:true,x:1700,y:1800,radius:8,item:{kind:'xp',amount:7,accumulator:0}}],actorOrder:[{projectile:8},{pickup:4},{enemy:5},{projectile:9}]};
const xp=f=>({id:`t${f.tick}:approach_experience:4:xp:${f.pickups[0].age}`,kind:'approach_experience',observedTick:f.tick,distance:100,target:{x:1700,y:1800},resource:{kind:'experience',baseXp:7,generation:f.pickups[0].generation,autoClaimTicks:null}});
const north=f=>({id:`t${f.tick}:move_north:north`,kind:'move_north',observedTick:f.tick,distance:160,target:{x:1800,y:1640}});
assert.deepEqual(actorThreats(frame).map(t=>[t.x,t.hostile]),[[1850,true],[1900,false]]);
assert.ok(steering(frame,null).every(Number.isFinite));
assert.ok(routePath(frame,{x:1700,y:1800}).reachable);
const memory=createPlanner();planMovement(memory,frame,[xp(frame),north(frame)]);
const key=Object.keys(memory.objects)[0];assert.equal(key,'approach_experience:4:xp:10');
const next=structuredClone(frame);next.tick++;next.pickups[0].age++;next.pickups[0].item.amount=11;
const nextGoal={...xp(next),resource:{...xp(next).resource,baseXp:11}};
planMovement(memory,next,[nextGoal,north(next)]);assert.equal(memory.objects[key].firstSeen,100);assert.equal(memory.objects[key].value,11);
next.pickups[0].generation=101;planMovement(memory,next,[xp(next),north(next)]);assert.equal(Object.keys(memory.objects)[0],'approach_experience:4:xp:101');assert.equal(Object.values(memory.objects)[0].firstSeen,101);
const options={runId:'test',decisionSeq:1};
const decision=buildGoalDecision(frame,[xp(frame),north(frame)],options);
assert.equal(decision.candidates.find(c=>c.goal.kind==='approach_experience').effect.resource.slot,4);
assert.throws(()=>buildGoalDecision(frame,[{...xp(frame),resource:{...xp(frame).resource,generation:99}},north(frame)],options),/current persistent engine pile/);
const upgrade=buildUpgradeDecision({...frame,phase:1,offers:[{kind:2,id:0,level:0}]},options);
assert.equal(upgrade.snapshot.threats.livingEnemies,1);assert.equal(upgrade.snapshot.threats.hostileProjectiles,1);
// Exercise actual runner observation boundary and summary without a Body field.
const Game={fresh_start_seed:()=>({$: 'Packet',tick:0}),observed_packet:p=>({$: 'Observed',state:p,frame:JSON.stringify({...frame,tick:p.tick}),actions:JSON.stringify([north({...frame,tick:p.tick})]),mechanics:'{}'}),advance:state=>({$: 'Packet',tick:state.tick+1})};
const summary=await runBot(Game,{ticks:2,decisions:'upgrades'});assert.equal(summary.maxLiving,1);assert.equal(summary.uncollectedBaseXp,7);assert.equal(summary.xpPiles,1);
// Execute journal's actual draw function with canvas-only DOM stubs.
const html=await readFile(new URL('./journal.html',import.meta.url),'utf8');
const drawSource=html.slice(html.indexOf('function draw('),html.indexOf('function render('));const arcs=[],colors=[];
const ctx={clearRect(){},beginPath(){},moveTo(){},lineTo(){},stroke(){},fill(){colors.push(this.fillStyle);},arc(...args){arcs.push(args);}};
vm.runInNewContext(drawSource+';draw(frame,null)',{frame,$:()=>({getContext:()=>ctx}),selectedCandidate:()=>null});
assert.equal(arcs.length,5);assert.deepEqual(colors,['#eeeeee','#75bfff','#f47579','#eeeeee','#fff']);
// Browser diagnostic telemetry retains explicit lifetime, and recycled identities do not pair.
const browser=await readFile(new URL('./coop-reliability-browser-check.mjs',import.meta.url),'utf8');
const source=browser.slice(browser.indexOf('function motionOracle('),browser.indexOf('function inputCoverage('));
const diagnostic=vm.runInNewContext(source+';motionOracle(rows,0)',{assert,p95:()=>0,rows:[{wall:6000,phase:0,runId:1,round:1,enemies:[{identity:5,lifetime:'born1',x:10,y:10}]},{wall:6100,phase:0,runId:1,round:1,enemies:[{identity:5,lifetime:'born2',x:100,y:100}]},{wall:6200,phase:0,runId:1,round:1,enemies:[{identity:5,lifetime:'born2',x:106,y:100}]}]});
assert.equal(diagnostic.enemies.samples,1);assert.equal(diagnostic.enemies.maxUnitsPerWallTick,1);
console.log('actor consumer fixtures passed');
