// Pure, bounded spatial planning. The classifier is deliberately outside this module.
const distance = (a,b) => Math.hypot(a.x-b.x,a.y-b.y);
const position = f => ({x:f.px,y:f.py});
const identity = (g,frame) => {
  if(g.kind.startsWith('move_')) return g.kind;
  const [, ,slot,itemKind]=g.id.split(':');
  const pickup=frame.pickups.find(p=>p.active&&p.slot===Number(slot)&&p.item.kind===itemKind);
  if(!pickup) throw new Error('Goal has no current pickup');
  return `${g.kind}:${slot}:${itemKind}:${pickup.generation}`;
};
// Preserve actor query order when summing steering and risk contributions.
export function actorThreats(frame) {
  const enemies=new Map(frame.enemies.map(enemy=>[enemy.identity,enemy]));
  const projectiles=new Map(frame.projectiles.map(projectile=>[projectile.identity,projectile]));
  return frame.actorOrder.flatMap(ref=>{
    if(ref.enemy!==undefined){const enemy=enemies.get(ref.enemy);return [{x:enemy.x,y:enemy.y,radius:enemy.radius,health:enemy.health,hostile:false}];}
    if(ref.projectile!==undefined){const projectile=projectiles.get(ref.projectile);return projectile.hostile?[{x:projectile.x,y:projectile.y,radius:projectile.radius,hostile:true}]:[];}
    return [];
  });
}
export function createPlanner(options={}) {
  return {options:{cell:60,worldSize:null,maxExpanded:1200,maxCandidates:8,replanTicks:30,...options},objects:{},clusters:[],candidates:[],current:null,lastPlan:-Infinity,lastHp:null,lastPosition:null,stuckSince:null,reason:'initial'};
}
class Heap {
  a=[];
  push(v){let i=this.a.length;this.a.push(v);while(i){const p=(i-1)>>1;if(this.a[p].f<=v.f)break;this.a[i]=this.a[p];i=p;}this.a[i]=v;}
  pop(){const first=this.a[0],v=this.a.pop();if(this.a.length){let i=0;while(i*2+1<this.a.length){let j=i*2+1;if(j+1<this.a.length&&this.a[j+1].f<this.a[j].f)j++;if(this.a[j].f>=v.f)break;this.a[i]=this.a[j];i=j;}this.a[i]=v;}return first;}
}
function riskGrid(frame,options){
  const cell=options.cell,worldSize=options.worldSize??frame.worldSize??14400;
  const margin=frame.worldMargin??0,span=Math.min(3600,worldSize-2*margin),n=Math.ceil(span/cell);
  const origin={x:Math.min(worldSize-margin-span,Math.max(margin,Math.floor(Math.max(0,frame.px-span/2)/cell)*cell)),y:Math.min(worldSize-margin-span,Math.max(margin,Math.floor(Math.max(0,frame.py-span/2)/cell)*cell))};
  const risk=new Float64Array(n*n),blocked=new Uint8Array(n*n);
  for(const b of actorThreats(frame)){
    if(!b.hostile&&b.health<=0)continue;
    const radius=b.radius+(b.hostile?12:18), reach=radius+120;
    for(let y=Math.max(0,Math.floor((b.y-origin.y-reach)/cell));y<=Math.min(n-1,Math.floor((b.y-origin.y+reach)/cell));y++)
      for(let x=Math.max(0,Math.floor((b.x-origin.x-reach)/cell));x<=Math.min(n-1,Math.floor((b.x-origin.x+reach)/cell));x++){
        const d=Math.hypot(origin.x+(x+.5)*cell-b.x,origin.y+(y+.5)*cell-b.y),i=y*n+x;
        // A cell intersecting contact space cannot serve as a safe corridor.
        if(d<radius+cell*.35)blocked[i]=1;
        risk[i]+=Math.max(0,1-d/reach)*(b.hostile?8:4);
      }
  }
  return {n,risk,blocked,cell,origin,span};
}
export function routePath(frame,target,options={},suppliedGrid){
  const o={cell:60,worldSize:frame.worldSize??14400,maxExpanded:1200,...options},grid=suppliedGrid??riskGrid(frame,o),{n,cell,risk,blocked,origin,span}=grid;
  const projected={x:Math.max(origin.x,Math.min(origin.x+span,target.x)),y:Math.max(origin.y,Math.min(origin.y+span,target.y))};
  const index=(p)=>Math.max(0,Math.min(n-1,Math.floor((p.y-origin.y)/cell)))*n+Math.max(0,Math.min(n-1,Math.floor((p.x-origin.x)/cell)));
  const start=index(position(frame)),end=index(projected),cost=new Float64Array(n*n).fill(Infinity),previous=new Int32Array(n*n).fill(-1),closed=new Uint8Array(n*n),heap=new Heap();
  const h=i=>Math.hypot(i%n-end%n,Math.floor(i/n)-Math.floor(end/n));
  if(blocked[end]&&end!==start)return {reachable:false,waypoints:[],length:Infinity,risk:Infinity,expanded:0};
  cost[start]=0;heap.push({i:start,f:h(start)});let expanded=0;
  while(heap.a.length&&expanded<o.maxExpanded){
    const {i}=heap.pop();if(closed[i])continue;closed[i]=1;expanded++;
    if(i===end){let cursor=i,indices=[];while(cursor!==start){indices.push(cursor);cursor=previous[cursor];}indices.reverse();const waypoints=indices.map(k=>({x:origin.x+(k%n+.5)*cell,y:origin.y+(Math.floor(k/n)+.5)*cell}));waypoints.push({...projected});let length=0,last=position(frame);for(const point of waypoints){length+=distance(last,point);last=point;}return {reachable:true,waypoints,length:length+distance(projected,target),partial:distance(projected,target)>0,risk:indices.reduce((s,k)=>s+risk[k],0)/Math.max(1,indices.length),expanded};}
    const x=i%n,y=Math.floor(i/n);
    for(const [dx,dy] of [[1,0],[0,1],[-1,0],[0,-1],[1,1],[-1,1],[-1,-1],[1,-1]]){
      const nx=x+dx,ny=y+dy;if(nx<0||ny<0||nx>=n||ny>=n)continue;
      const j=ny*n+nx;if(blocked[j]&&j!==start)continue;
      if(dx&&dy&&(blocked[y*n+nx]||blocked[ny*n+x]))continue;
      const c=cost[i]+Math.hypot(dx,dy)*(1+risk[j]*2);
      if(c<cost[j]){cost[j]=c;previous[j]=i;heap.push({i:j,f:c+h(j)});}
    }
  }
  return {reachable:false,waypoints:[],length:Infinity,risk:Infinity,expanded};
}
function observe(memory,frame,catalog,mechanics){
  const objects={},xpPickups=new Map(frame.pickups.filter(p=>p.active&&p.item.kind==='xp').map(p=>[p.slot,p]));
  for(const goal of catalog.filter(g=>g.kind==='approach_experience')){
    const key=identity(goal,frame),prior=memory.objects[key];
    const pickup=xpPickups.get(Number(goal.id.split(':')[2]));
    const value=Number.isFinite(goal.resource?.baseXp)?goal.resource.baseXp:Number.isFinite(goal.reward?.xp)?goal.reward.xp:Number.isFinite(goal.experience)?goal.experience:pickup?.item.amount>0?pickup.item.amount:mechanics.resourceRules?.xpDefaultValue??1;
    objects[key]={key,goal,value,firstSeen:prior?.firstSeen??frame.tick,lastSeen:frame.tick};
  }
  // Observation is omniscient: disappeared pickups are removed, never remembered as available.
  memory.objects=objects;
  const clusters=new Map();
  for(const object of Object.values(objects)){
    const p=object.goal.target,key=`${Math.floor(p.x/120)}:${Math.floor(p.y/120)}`;
    let c=clusters.get(key);if(!c)clusters.set(key,c={id:key,reward:0,members:[],x:0,y:0,firstSeen:object.firstSeen});
    c.reward+=object.value;c.x+=p.x*object.value;c.y+=p.y*object.value;c.members.push(object);c.firstSeen=Math.min(c.firstSeen,object.firstSeen);
  }
  memory.clusters=[...clusters.values()].map(c=>({...c,x:c.x/c.reward,y:c.y/c.reward}));
}
export function advisePlanner(memory,goalId){
  const candidate=memory.candidates.find(c=>c.goal.id===goalId);
  if(!candidate)return false;
  memory.current=candidate;memory.reason='advisory';return true;
}
const availableGoalKinds=new Set(['move_north','move_east','move_south','move_west','approach_experience','approach_chest','approach_relic']);
export function planMovement(memory,frame,catalog,mechanics={}){
  catalog=catalog.filter(goal=>availableGoalKinds.has(goal.kind));
  observe(memory,frame,catalog,mechanics);
  const here=position(frame),current=memory.current;
  const currentGoal=current&&catalog.find(g=>identity(g,frame)===current.identity);
  const damaged=memory.lastHp!==null&&frame.hp<memory.lastHp;
  if(memory.lastPosition&&distance(here,memory.lastPosition)>12){memory.lastPosition=here;memory.stuckSince=frame.tick;}
  if(!memory.lastPosition){memory.lastPosition=here;memory.stuckSince=frame.tick;}
  const stuck=frame.tick-memory.stuckSince>=120;
  const invalid=!!current&&!currentGoal;
  const due=frame.tick-memory.lastPlan>=memory.options.replanTicks;
  const objectKeys=Object.keys(memory.objects).join("|");
  let expanded=0;
  if(memory.lastPlan===-Infinity||(!current&&objectKeys!==memory.lastObjectKeys)||invalid||damaged||stuck||due){
    const grid=riskGrid(frame,memory.options),pool=[];
    for(const cluster of memory.clusters){
      const members=[...cluster.members].sort((a,b)=>distance(here,a.goal.target)-distance(here,b.goal.target)||a.goal.id.localeCompare(b.goal.id));
      const member=members[0];
      pool.push({goal:member.goal,representatives:members.slice(0,3).map(m=>m.goal),reward:cluster.reward,clusterId:cluster.id,priority:cluster.reward/(60+distance(here,member.goal.target))});
    }
    for(const goal of catalog.filter(g=>g.kind!=='approach_experience'))pool.push({goal,reward:goal.kind==='approach_chest'?14:goal.kind==='approach_relic'?9:goal.kind.startsWith('approach_')?5:0.1,priority:0});
    pool.sort((a,b)=>b.priority-a.priority||distance(here,a.goal.target)-distance(here,b.goal.target)||a.goal.id.localeCompare(b.goal.id));
    // Reserve routes for non-XP objectives and retreat, even under a large XP backlog.
    const selected=[];
    const add=p=>{if(p&&!selected.includes(p)&&selected.length<memory.options.maxCandidates)selected.push(p);};
    if(currentGoal)add(pool.find(p=>p.goal.id===currentGoal.id||p.representatives?.some(g=>g.id===currentGoal.id)));
    add(pool.find(p=>p.goal.kind.startsWith('approach_')&&p.goal.kind!=='approach_experience'));
    add(pool.find(p=>p.goal.kind.startsWith('move_')));
    for(const p of pool)add(p);
    const candidates=[];
    for(const p of selected){
      const remaining=memory.options.maxExpanded-expanded;if(remaining<=0)break;
      const allowance=Math.min(remaining,Math.max(80,Math.floor(memory.options.maxExpanded/memory.options.maxCandidates)));
      let used=0,route,goal;
      // A blocked nearest pile must not hide reachable siblings in the same cluster.
      for(const representative of p.representatives??[p.goal]){
        if(used>=allowance)break;
        const attempt=routePath(frame,representative.target,{...memory.options,maxExpanded:allowance-used},grid);
        used+=attempt.expanded;
        if(attempt.reachable){route=attempt;goal=representative;break;}
      }
      expanded+=used;if(!route)continue;
      const etaTicks=route.length/(2.5*Math.max(.1,mechanics.current?.speedMultiplier??1));
      candidates.push({...p,goal,...route,etaTicks,identity:identity(goal,frame),score:p.reward/(1+etaTicks/60)/(1+route.risk*(frame.hp<frame.maxHp*.35?4:1))});
    }
    if(stuck)for(const candidate of candidates)if(candidate.identity===current?.identity)candidate.score*=0.2;
    candidates.sort((a,b)=>b.score-a.score||a.goal.id.localeCompare(b.goal.id));
    const retained=candidates.find(c=>c.identity===current?.identity),best=candidates[0];
    memory.current=retained&&!damaged&&!stuck&&(!best||best.score<retained.score*1.35)?retained:best??null;
    // Empty-world cardinal suggestions do not override weapon-aware combat steering.
    if(memory.current?.goal.kind.startsWith('move_')&&!damaged&&frame.hp>=frame.maxHp*.35&&memory.reason!=='advisory') memory.current=null;
    memory.candidates=candidates;memory.lastObjectKeys=objectKeys;memory.lastPlan=frame.tick;memory.reason=invalid?'target-gone':damaged?'damage':stuck?'stuck':current?'periodic':'initial';
    if(stuck){memory.lastPosition=here;memory.stuckSince=frame.tick;}
  }else if(currentGoal){memory.current.goal=currentGoal;}
  // Refresh snapshot-scoped IDs without replacing stable objectives or route memory.
  memory.candidates=memory.candidates.flatMap(c=>{const g=catalog.find(g=>identity(g,frame)===c.identity);return g?[{...c,goal:g}]:[];});
  if(memory.current){const fresh=memory.candidates.find(c=>c.identity===memory.current.identity);memory.current=fresh??null;}
  memory.lastHp=frame.hp;
  if(memory.current){while(memory.current.waypoints.length>1&&distance(here,memory.current.waypoints[0])<35)memory.current.waypoints.shift();}
  return {memory,candidates:memory.candidates,chosen:memory.current,target:memory.current?.waypoints[0]??null,reason:memory.reason,clusters:memory.clusters,search:{expanded,budget:memory.options.maxExpanded}};
}
