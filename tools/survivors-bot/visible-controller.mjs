import { buildUpgradeDecision, resolveCandidate, buildGoalDecision, resolveGoalCandidate } from './context.mjs';
import { heuristicUpgrade, steering } from './runner.mjs';
import { createPlanner, planMovement, advisePlanner } from './planner.mjs';

// The native process alone advances the world. This controller receives snapshots.
export function makeVisibleController({ runId, mode = 'heuristic', profile = 'fresh', classify,
  maxUpgradeRequests = 6, maxGoalRequests = 2, timeoutMs = 2000, emit = () => {} }) {
  if (!runId || !['heuristic','jev'].includes(mode) || !['fresh','advanced'].includes(profile)) throw new Error('Invalid visible bot options');
  for (const n of [maxUpgradeRequests,maxGoalRequests]) if (!Number.isSafeInteger(n)||n<0||n>50) throw new Error('Invalid request budget');
  if (maxUpgradeRequests+maxGoalRequests>50 || !Number.isSafeInteger(timeoutMs)||timeoutMs<1||timeoutMs>10000) throw new Error('Invalid bounded options');
  if(mode==='jev' && typeof classify!=='function') throw new Error('Classifier required');
  let lastSequence=0, decisionSeq=0, nextGoal=1, lastAdviceTick=-300, previous=null, lastFrameTick=-60, pending=[], lastIntent=null;
  const plannerMemory=createPlanner();
  const history=[], attempts={upgrade:0,goal:0};
  return async function command(observation) {
    const {sequence,frame:f,actions:catalog,mechanics:engineMechanics}=observation;
    if(!Number.isSafeInteger(sequence)||sequence<=lastSequence||!f||!Number.isSafeInteger(f.tick)||!Number.isFinite(f.px)||!Number.isFinite(f.py)||!Array.isArray(catalog)) throw new Error('Invalid or repeated native observation');
    if(previous && f.tick<previous.tick) throw new Error('Native tick regressed');
    lastSequence=sequence;
    if(f.tick-lastFrameTick>=30 || f.phase!==previous?.phase || [3,4].includes(f.phase)) {emit({type:'frame',sequence,frame:f});lastFrameTick=f.tick;}
    pending=pending.filter(p=> {
      if(f.tick<p.until && ![3,4].includes(f.phase)) return true;
      emit({type:'outcome',decisionSeq:p.decisionSeq,kind:p.kind,fromTick:p.tick,toTick:f.tick,windowTicks:p.until-p.tick,
        delta:{hp:f.hp-p.hp,kills:f.kills-p.kills,gold:f.gold-p.gold,level:f.level-p.level},
        qualification:'Observed interval after this decision; overlapping decisions, combat and healing prevent causal attribution.'});
      return false;
    });
    previous=f;
    history.push({tick:f.tick,hp:f.hp}); while(history.length>32)history.shift();
    if([3,4].includes(f.phase)) return null;
    const options={runId,decisionSeq:++decisionSeq,meta:profile==='advanced'?364304237:0,history,engineMechanics};
    async function select(request,fallback,resolve) {
      emit({type:'decision-request',request});
      let selected=fallback,source='heuristic',reason,response;
      const limit=request.kind==='upgrade'?maxUpgradeRequests:maxGoalRequests;
      if(mode==='jev' && attempts[request.kind]<limit && request.candidates.length>1) {
        attempts[request.kind]++;
        try { response=await classify(request,{timeoutMs}); selected=resolve(response); source='classifier'; }
        catch(error) {source='fallback'; reason=['timeout','missing-credential','provider-unavailable','invalid-request'].includes(error?.code)?error.code:'invalid-or-stale-response';}
      } else if(mode==='jev') source=request.candidates.length===1?'only-legal-candidate':'budget-fallback';
      const safeResponse=response&&{selectedCandidateId:response.selectedCandidateId,model:response.model,latencyMs:response.latencyMs,usage:response.usage,probabilities:response.probabilities};
      if(request.kind==='goal' && source==='classifier' && !advisePlanner(plannerMemory,selected.id)) throw new Error('Selected goal is not a current planner candidate');
      emit({type:'decision',request,result:{source,reason,selected,response:safeResponse}});
      for(const window of [30,120,300]) pending.push({decisionSeq:request.decisionSeq,kind:request.kind,tick:f.tick,until:f.tick+window,hp:f.hp,kills:f.kills,gold:f.gold,level:f.level});
      return selected;
    }
    if([1,2].includes(f.phase)) {
      const request=buildUpgradeDecision(f,options);
      const index=await select(request,heuristicUpgrade(f),a=>resolveCandidate(request,a,f,options));
      history.push({tick:f.tick,hp:f.hp,action:'choose_upgrade',offer:f.offers[index]});
      return {kind:1,x:1000,y:1000,index,horizon:1};
    }
    let spatial=planMovement(plannerMemory,f,catalog,engineMechanics);
    const urgent=['target-gone','damage','stuck'].includes(spatial.reason) && f.tick-lastAdviceTick>=60;
    if(mode==='jev' && (f.tick>=nextGoal || urgent) && spatial.candidates.length>=2) {
      const request=buildGoalDecision(f,catalog,{...options,planner:spatial});
      const fallback=spatial.chosen?.goal ?? null;
      const goal=await select(request,fallback,a=>resolveGoalCandidate(request,a,f,catalog,options));
      spatial=planMovement(plannerMemory,f,catalog,engineMechanics); nextGoal=f.tick+300;lastAdviceTick=f.tick;
      history.push({tick:f.tick,hp:f.hp,action:'choose_goal',goal:goal?.kind??'retain_combat',target:goal?.target??null});
    }
    const target=spatial.target,identity=spatial.chosen?.identity??null;
    if(identity!==lastIntent) emit({type:'movement-intent',tick:f.tick,source:'memory-planner',goal:spatial.chosen?.goal??null,
      route:spatial.chosen?.waypoints??[],risk:spatial.chosen?.risk??null,reward:spatial.chosen?.reward??null,
      reason:spatial.reason,memory:{resources:Object.keys(plannerMemory.objects).length,clusters:plannerMemory.clusters.length}});
    lastIntent=identity;
    const [dx,dy]=steering(f,target,engineMechanics);
    // Short batches keep avoidance and goal identity under regular observation.
    return {kind:0,x:Math.round((dx+1)*1000),y:Math.round((dy+1)*1000),index:0,horizon:6};
  };
}

export function encodeCommand(c) {
  if(!c || ![0,1].includes(c.kind)||![c.x,c.y,c.index,c.horizon].every(Number.isSafeInteger)||c.x<0||c.x>2000||c.y<0||c.y>2000||c.index<0||c.index>2||c.horizon<1||c.horizon>30) throw new Error('Invalid native command');
  return `${c.kind}\n${c.x}\n${c.y}\n${c.index}\n${c.horizon}\n`;
}
