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
