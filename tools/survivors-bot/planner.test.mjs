import test from 'node:test';
import assert from 'node:assert/strict';
import {createPlanner,planMovement,advisePlanner,routePath} from './planner.mjs';
const frame=(tick=1,bodies=[])=>({tick,px:90,py:210,hp:100,maxHp:100,bodies});
const xp=(tick,seed,x,y,baseXp=10,generation=0)=>({id:`t${tick}:approach_experience:${seed}:2:0:${tick-generation}`,kind:'approach_experience',target:{x,y},distance:Math.hypot(x-90,y-210),resource:{baseXp,generation,autoClaimTicks:null}});
test('routing takes an actual detour around a contact barrier',()=>{
 const f=frame(1,[90,150,210,270].map((y,i)=>[210,y,0,0,100,100,0,i,18]));
 const r=routePath(f,{x:390,y:210},{worldSize:600,cell:30,maxExpanded:1000});
 assert.equal(r.reachable,true);assert.ok(r.waypoints.some(p=>p.y>310));
 assert.ok(r.waypoints.every(p=>Math.hypot(p.x-210,p.y-210)>35));
});
test('search budget bounds work even when no route exists',()=>{
 const r=routePath(frame(),{x:3500,y:3500},{maxExpanded:3});
 assert.equal(r.reachable,false);assert.equal(r.expanded,3);
});
test('remembered XP persists past 120 ticks, stable generation survives merging and IDs refresh',()=>{
 const m=createPlanner(),g=xp(1,748,300,210,10);
 planMovement(m,frame(),[g]);
 const p=planMovement(m,frame(500),[xp(500,748,300,210,30)]);
 assert.equal(Object.values(m.objects)[0].firstSeen,1);assert.equal(p.clusters[0].reward,30);
 assert.equal(p.chosen.goal.id,xp(500,748,300,210,30).id);
});
test('collected targets disappear and reused pool slots get a new identity',()=>{
 const m=createPlanner();planMovement(m,frame(),[xp(1,748,200,210)]);
 const original=m.current.identity;
 planMovement(m,frame(2),[]);assert.equal(m.current,null);assert.deepEqual(m.objects,{});
 planMovement(m,frame(3),[xp(3,748,200,210,10,3)]);assert.notEqual(m.current.identity,original);
});
test('hysteresis holds a useful current objective through modest alternative reward changes',()=>{
 const m=createPlanner();planMovement(m,frame(),[xp(1,748,300,210,10),xp(1,749,90,420,9)]);
 const id=m.current.identity;
 const p=planMovement(m,frame(31),[xp(31,748,300,210,10),xp(31,749,90,420,11)]);
 assert.equal(p.chosen.identity,id);
});
test('planner is reproducible and classifier advice only selects prepared routes',()=>{
 const goals=[xp(1,748,300,210),xp(1,749,90,420)],a=createPlanner(),b=createPlanner();
 assert.deepEqual(planMovement(a,frame(),goals),planMovement(b,frame(),goals));
 const original=a.current;assert.equal(advisePlanner(a,'invented'),false);assert.equal(a.current,original);
 assert.equal(advisePlanner(a,a.candidates.at(-1).goal.id),true);
 assert.equal(a.current.goal.id,a.candidates.at(-1).goal.id);
});
test('higher XP reward makes a comparable route worthwhile without classifier access',()=>{
 const p=planMovement(createPlanner(),frame(),[xp(1,748,300,210,2),xp(1,749,90,420,40)]);
 assert.equal(p.chosen.goal.id.split(':')[2],'749');assert.ok(p.search.expanded<=p.search.budget);
});
test('healthy empty-world cardinal suggestions leave combat steering in control',()=>{
 const m=createPlanner(),goal={id:'t1:move_east',kind:'move_east',target:{x:250,y:210},distance:160};
 const p=planMovement(m,frame(),[goal]);assert.equal(p.target,null);assert.equal(p.candidates.length,1);
 assert.equal(advisePlanner(m,goal.id),true);assert.ok(planMovement(m,frame(),[goal]).target);
});
test('cardinal candidates survive snapshot tick changes with current engine IDs and bounded cached routes',()=>{
 const m=createPlanner();
 const cardinal=(tick,x)=>({id:`t${tick}:move_east`,kind:'move_east',target:{x,y:210},distance:160});
 const initial=planMovement(m,frame(0),[cardinal(0,250)]);
 const originalRoute=structuredClone(initial.candidates[0].waypoints);
 const next=planMovement(m,{...frame(1),px:92},[cardinal(1,252)]);
 assert.equal(next.candidates.length,1);assert.equal(next.candidates[0].goal.id,'t1:move_east');
 assert.deepEqual(next.candidates[0].waypoints,originalRoute);assert.equal(next.search.expanded,0);
 assert.equal(next.target,null);assert.equal(advisePlanner(m,'t0:move_east'),false);
 assert.equal(advisePlanner(m,'t1:move_east'),true);assert.ok(planMovement(m,frame(1),[cardinal(1,252)]).target);
});
test('route length measures diagonal geometry and exact start/end links',()=>{
 const diagonal=routePath(frame(),{x:210,y:330},{cell:60,maxExpanded:100});
 assert.ok(Math.abs(diagonal.length-120*Math.SQRT2)<1e-9);
 const offset=routePath({...frame(),px:65,py:185},{x:205,y:325},{cell:60,maxExpanded:100});
 let measured=0,last={x:65,y:185};
 for(const point of offset.waypoints){measured+=Math.hypot(point.x-last.x,point.y-last.y);last=point;}
 assert.ok(Math.abs(offset.length-measured)<1e-9);
 const sameCell=routePath({...frame(),px:61,py:61},{x:89,y:89},{cell:60,maxExpanded:100});
 assert.ok(Math.abs(sameCell.length-28*Math.SQRT2)<1e-9);
});
test('route ETA uses engine base movement 2.5 units per tick and speed multiplier',()=>{
 const result=planMovement(createPlanner(),frame(),[xp(1,748,150,270)],{current:{speedMultiplier:1.5}});
 assert.ok(Math.abs(result.chosen.length-60*Math.SQRT2)<1e-9);
 assert.ok(Math.abs(result.chosen.etaTicks-result.chosen.length/(2.5*1.5))<1e-9);
});
test('blocked nearest XP representative does not hide a reachable sibling in its cluster',()=>{
 const f=frame(1,[[241,241,0,0,100,100,0,1,12]]);
 const p=planMovement(createPlanner(),f,[xp(1,748,241,241),xp(1,749,350,350)]);
 assert.ok(p.candidates.some(c=>c.goal.id.split(':')[2]==='749'));
 assert.ok(p.search.expanded<=1200);
});
test('XP backlog reserves bounded routes for reachable chest and retreat alternatives',()=>{
 const positions=[[241,241],[481,241],[721,241],[961,241],[241,481],[481,481],[721,481],[961,481]];
 const f=frame(1,positions.map(([x,y],i)=>[x,y,0,0,100,100,0,i,12]));
 const chest={id:'t1:approach_chest:50:5:0:1',kind:'approach_chest',target:{x:90,y:330},distance:120};
 const retreat={id:'t1:move_west',kind:'move_west',target:{x:30,y:210},distance:60};
 const p=planMovement(createPlanner(),f,[...positions.map(([x,y],i)=>xp(1,748+i,x,y)),chest,retreat]);
 assert.ok(p.candidates.some(c=>c.goal.kind==='approach_chest'));
 assert.ok(p.candidates.some(c=>c.goal.kind==='move_west'));
 assert.ok(p.candidates.length<=8);assert.ok(p.search.expanded<=1200);
});
test('NoHiddenActorGoal: removed actor intents cannot enter baseline routing',()=>{
 const catalog=['approach_wisp','approach_ward','activate_ward'].map((kind,i)=>({id:`removed${i}`,kind,target:{x:150,y:210},distance:60}));
 const planned=planMovement(createPlanner(),frame(),catalog);
 assert.ok(planned.candidates.every(c=>!catalog.includes(c.goal)));
 assert.equal(planned.chosen,null);
});
