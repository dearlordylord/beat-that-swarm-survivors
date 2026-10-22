import test from 'node:test';
import assert from 'node:assert/strict';
import {makeVisibleController,encodeCommand} from './visible-controller.mjs';
function observation(sequence=1,tick=1,phase=0){
 const f={tick,phase,px:1800,py:1800,hp:70,maxHp:70,xp:0,xpNeed:50,level:1,kills:0,gold:0,character:0,arcana:0,stage:0,mode:0,rerolls:3,banishes:3,skips:3,weapons:[1,...Array(23).fill(0)],passives:Array(18).fill(0),bodies:[],offers:phase===1?[{kind:0,id:0,level:2},{kind:1,id:7,level:1}]:[]};
 const actions=['north','east','south','west'].map((name,i)=>({id:`t${tick}:move_${name}:${name}`,kind:'move_'+name,target:{x:f.px+[0,160,0,-160][i],y:f.py+[-160,0,160,0][i]},distance:160,observedTick:tick}));
 return {sequence,frame:f,actions,mechanics:{source:'offline fixture',current:{hp:70},offers:f.offers.map((offer,offerIndex)=>({offerIndex,offer,after:{hp:70}}))}};
}
const answer=r=>({runId:r.runId,decisionSeq:r.decisionSeq,candidatesHash:r.candidatesHash,selectedCandidateId:r.candidates[1].id});
test('visible controller selects only actual goals and offers; records measured windows',async()=>{
 const records=[],requests=[];
 const command=makeVisibleController({runId:'visible',mode:'jev',classify:async r=>{requests.push(r);return answer(r)},emit:r=>records.push(r)});
 assert.equal((await command(observation())).kind,0);
 assert.equal((await command(observation(2,2,1))).index,1);
 await command(observation(3,32));
 assert.deepEqual(requests.map(r=>r.kind),['goal','upgrade']);
 assert.equal(records.filter(r=>r.type==='outcome').length,2);
 assert.ok(records.some(r=>r.type==='decision-request'));
 await assert.rejects(command(observation(3,32)),/repeated/);
});
test('stale response and timeout fallback never execute proposed upgrade',async()=>{
 for(const failure of ['stale','timeout']){
 const records=[];
 const command=makeVisibleController({runId:'x',mode:'jev',emit:r=>records.push(r),classify:async r=>{if(failure==='timeout')throw Object.assign(new Error('secret'),{code:'timeout'});return {...answer(r),runId:'old',selectedCandidateId:r.candidates[0].id}}});
 const result=await command(observation(1,2,1));
 assert.equal(result.index,1);assert.equal(records.find(r=>r.type==='decision').result.source,'fallback');
 assert.ok(!JSON.stringify(records).includes('secret'));
 }
});
test('budgets bound calls and wire encoding rejects malformed commands',async()=>{
 const command=makeVisibleController({runId:'offline',mode:'jev',maxUpgradeRequests:0,maxGoalRequests:0,classify:()=>assert.fail('No HTTP')});
 const result=await command(observation());
 assert.match(encodeCommand(result),/^0\n\d+\n\d+\n0\n6\n$/);
 assert.throws(()=>encodeCommand({...result,horizon:31}));assert.throws(()=>encodeCommand({...result,x:NaN}));
 assert.equal(await command(observation(2,10,3)),null);
});


test('visible bot follows a persistent XP route between advice calls and releases a collected target',async()=>{
 const records=[];
 const command=makeVisibleController({runId:'xp',emit:r=>records.push(r)});
 await command(observation());
 const next=observation(2,7);
 next.frame.bodies=[[1860,1800,2,0,8,3,1500,748,6]];
 next.actions.push({id:'t7:approach_experience:748:2:0:1500',kind:'approach_experience',target:{x:1860,y:1800},distance:60,observedTick:7,resource:{baseXp:8,generation:3,autoClaimTicks:null}});
 const move=await command(next);
 assert.ok(move.x>1000, "Follow the eastward route; waypoints may add a lateral component");
 const event=records.find(r=>r.type==='movement-intent');assert.equal(event.goal.kind,'approach_experience');
 await command(observation(3,13));
 assert.equal(records.filter(r=>r.type==='movement-intent').at(-1).goal,null);
});


test('provider failures preserve resource memory and the same free planner route',async()=>{
 const requests=[],records=[];
 const command=makeVisibleController({runId:'memory',mode:'jev',maxGoalRequests:2,emit:r=>records.push(r),classify:async r=>{requests.push(r);throw Object.assign(new Error('offline'),{code:'provider-unavailable'})}});
 const pile=(seq,tick)=>{const o=observation(seq,tick);o.frame.bodies=[[2100,1800,2,0,25,3,tick+500,748,6]];o.actions.push({id:`t${tick}:approach_experience:748:2:0:${tick+500}`,kind:'approach_experience',target:{x:2100,y:1800},distance:300,observedTick:tick,resource:{baseXp:25,generation:3,autoClaimTicks:null}});return o};
 await command(pile(1,7));await command(pile(2,307));
 assert.equal(requests.length,2);
 for(const r of requests){assert.equal(r.snapshot.spatialPlanner.memory.clusters[0].firstSeen,7);assert.ok(r.candidates.some(c=>c.effect.resource?.baseXp===25));}
 const decision=records.filter(r=>r.type==='decision');assert.ok(decision.every(r=>r.result.source==='fallback'));
 assert.ok(decision.every(r=>r.result.selected.kind==='approach_experience'));
 assert.equal(records.filter(r=>r.type==='movement-intent').length,1,'Stable resource identity survives provider failure and age changes');
});
