// Executed emitted-Bend checks for first-due contact FX; no world simulation.
// Usage: node coop-hit-effects-check.mjs /tmp/coop-hit-effects.mjs
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
const {default:E}=await import(pathToFileURL(resolve(process.argv[2]??'examples/survivors/dist/coop-hit-effects.mjs')));
const list=rows=>rows.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=rows=>{const out=[];for(;rows.$==='Con';rows=rows.tail)out.push(rows.head);return out;};
const event=(id='late',tick=124,extra={})=>({$:'HitEvent',id,tick,kind:2,shotId:'shot:1',shotSeed:512,targetSeed:42,targetGeneration:7,fraction:.5,impactX:12,impactY:23,targetAtImpactX:10,targetAtImpactY:20,radius:3,outcome:0,...extra});
const journal=(events=[],epoch=1,now=130)=>({$:'State',epoch,now,events:list(events),overflow:0,expired:0});
const target=(x=100,y=200,generation='enemy:42:7')=>({$:'Actor',key:42,kind:0,generation,x,y,age:1,hp:10,owner:0});
const sample=(tick,bodies=[target()],fraction=0)=>({$:'Sample',baseObservation:1,nextObservation:2,tick,fraction,alpha:0,players:list([]),bodies:list(bodies)});
const output=(state,tick,bodies)=>array(E.render(state,sample(tick,bodies)));
let checks=0;
const check=(value,message)=>{assert.ok(value,message);checks++;};

// Initial/reconnected observers consume existing history without displaying it.
let state=E.advance(E.fresh(),journal([event()]),sample(130));
check(output(state,130).length===0,'first attachment skips historical hits');
// Intake can happen several times before the browser schedules its first draw.
// Only the first accepted journal establishes historical seen identities.
const firstReceived=E.receive(E.fresh(),journal([],1,120));
const racedReceived=E.receive(firstReceived,journal([event('between-intake-and-draw')],1,130));
assert.deepEqual(racedReceived,firstReceived);checks++;
const racedDraw=E.advance(racedReceived,journal([event('between-intake-and-draw')],1,130),sample(130));
check(output(racedDraw,130).length===1&&output(racedDraw,130)[0].id==='between-intake-and-draw','new hit between initial receipt and first draw is not skipped');
const repeatedRace=E.advance(E.receive(racedDraw,journal([event('between-intake-and-draw')],1,131)),journal([event('between-intake-and-draw')],1,131),sample(131));
check(output(repeatedRace,131).length===1&&output(repeatedRace,131)[0].age===1,'same-epoch intake preserves an active flash start');
const joinedHistory=journal([event('join-history')],2,130);
const joined=E.receive(repeatedRace,joinedHistory);
check(output(joined,130).length===0,'new epoch intake clears old active effects');
const nextJournal=journal([event('join-history'),event('new-after-rejoin',131)],2,132);
const afterRejoin=E.advance(E.receive(joined,nextJournal),nextJournal,sample(132));
check(output(afterRejoin,132).length===1&&output(afterRejoin,132)[0].id==='new-after-rejoin','rejoin skips only the first accepted history before a delayed first draw');
state=E.attach(journal());
state=E.advance(state,journal([event()]),sample(119));
check(output(state,119).length===0,'future authority event waits for presentation');
state=E.advance(state,journal([event()]),sample(130));
let fx=output(state,130);
check(fx.length===1&&fx[0].age===0&&fx[0].opacity===1,'cursor jump starts a late hit at first due display');
check(fx[0].x===102&&fx[0].y===203,'effect uses displayed target-relative contact');
check(fx[0].tick===124,'authority event tick remains available as evidence');
for(const [tick,opacity] of [[130,1],[131,.75],[132,.5],[133,.25]]){
 state=E.advance(state,journal([event()],1,140),sample(tick));
 fx=output(state,tick);
 check(fx.length===1&&fx[0].opacity===opacity,'repeated journal cannot restart a live flash');
}
state=E.advance(state,journal([event()],1,140),sample(134));
check(output(state,134).length===0,'four display ticks expire the flash');
state=E.advance(state,journal([event()],1,141),sample(135));
check(output(state,135).length===0,'duplicate receipt cannot restart an expired effect');

// Matching target motion and recycled target identity use the shared mapper.
state=E.advance(E.attach(journal()),journal([event()]),sample(130));
fx=output(state,131,[target(150,250)]);
check(fx[0].x===152&&fx[0].y===253,'effect follows its displayed target lifetime');
fx=output(state,131,[target(900,900,'enemy:42:8')]);
check(fx[0].x===12&&fx[0].y===23,'slot reuse falls back to recorded impact, never the new enemy');
fx=output(state,131,[]);
check(fx[0].x===12&&fx[0].y===23,'missing lifetime uses recorded impact');

// New epochs clear old FX and skip their supplied history, then accept new hits.
state=E.advance(state,journal([event('other-history')],2),sample(131));
check(output(state,131).length===0,'epoch change clears prior effects and skips history');
state=E.advance(state,journal([event('other-history'),event('new',131)],2,132),sample(132));
check(output(state,132).length===1&&output(state,132)[0].id==='new','new epoch accepts only subsequent receipts');
state=E.advance(state,journal([event('new',131),event('failed',132,{outcome:1}),event('future',140)],2,140),sample(133));
check(output(state,133).length===1,'failed and future receipts do not create effects');

// Duplicate entries inside a single due batch cannot produce double effects.
state=E.advance(E.attach(journal()),journal([event(),event()]),sample(130));
check(output(state,130).length===1,'duplicate IDs in one batch create one effect');
const duplicate=E.add(event(),132,list([{$:'Effect',event:event(),started:130}]));
check(array(duplicate).length===1&&array(duplicate)[0].started===130,'active duplicate preserves the original start');

// Two dense batches each obey the journal capacity; active lifetime overlaps.
const first=Array.from({length:500},(_,i)=>event(`a:${i}`,100));
const second=Array.from({length:500},(_,i)=>event(`b:${i}`,101));
state=E.advance(E.attach(journal([],1,99)),journal(first,1,100),sample(100));
state=E.advance(state,journal(second,1,101),sample(101));
check(array(state.effects).length===512&&state.dropped===488,'overlapping bursts cap and count active eviction');
check(output(state,101).length===512,'dense render retains every bounded effect');
const bodies=Array.from({length:12000},(_,i)=>({...target(i,i),key:i,generation:`enemy:${i}:7`}));
check(array(E.render(state,sample(101,bodies))).length===512,'large displayed cohort uses indexed target mapping');
state=E.advance(state,journal([],1,105),sample(105));
check(output(state,105).length===0&&state.dropped===488,'dense expired FX clear without changing eviction count');
console.log(JSON.stringify({status:'PASS',checks,denseActors:12000,activeCap:512,scope:'emitted Bend first-due contact effects; no browser/network qualification'}));
