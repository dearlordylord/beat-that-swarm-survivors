// Real Iroh, two browser players, read-only projectile/visibility instrumentation.
import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
const {chromium}=await import(process.env.PLAYWRIGHT_MODULE||'playwright');
const base=process.env.COOP_URL||'https://survivors.dearlordylord.com/coop.html';
const output=process.env.COOP_QA_DIR||'/tmp/bendvy-coop-projectiles';
const cases=(process.env.COOP_PROJECTILE_CASES||'same-context,isolated').split(',');
const duration=Number(process.env.COOP_PROJECTILE_MS||10000);
const observationDelayMs=Number(process.env.COOP_PROJECTILE_DELAY_MS||0);
const enforce=process.env.COOP_PROJECTILE_ENFORCE!=='0';
const originLimit=Number(process.env.COOP_PROJECTILE_ORIGIN_LIMIT||8);
await mkdir(output,{recursive:true});
const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
const results=[];
const ownerOf=body=>body[10]??body[7]%2;
const summarise=rows=>({samples:rows.length,framesWithHostShots:rows.filter(row=>row.shots.some(body=>ownerOf(body)===0)).length,framesWithGuestShots:rows.filter(row=>row.shots.some(body=>ownerOf(body)===1)).length,hostSeeds:[...new Set(rows.flatMap(row=>row.shots.filter(body=>ownerOf(body)===0).map(body=>body[7])))],guestSeeds:[...new Set(rows.flatMap(row=>row.shots.filter(body=>ownerOf(body)===1).map(body=>body[7])))]});
try{
 for(const mode of cases){
  assert.ok(['same-context','isolated','throttled','frozen'].includes(mode),'known scenario');
  const contexts=[await browser.newContext({viewport:{width:1280,height:800}})];
  if(mode==='isolated')contexts.push(await browser.newContext({viewport:{width:1280,height:800}}));
  const host=await contexts[0].newPage(),guest=await contexts.at(-1).newPage();
  const errors=[];
  try{
   for(const [name,page]of[['host',host],['guest',guest]]){
    page.on('pageerror',error=>errors.push(name+': '+error.message));
    await page.addInitScript(()=>{
     globalThis.__projectileTrace={worker:[],received:[],renders:[],draws:[],inputs:[],visibility:[{at:performance.now(),state:document.visibilityState}]};
     const trace=globalThis.__projectileTrace;
     const observe=frame=>({at:performance.now(),tick:frame.tick,phase:frame.phase,ownPlayerId:frame.ownPlayerId,px:frame.px,py:frame.py,players:frame.players,shots:(frame.bodies||[]).filter(row=>row[2]===1)});
     globalThis.__projectileReceived=envelope=>{if(envelope?.type==='frame'){trace.received.push({...observe(envelope.frame),receipt:envelope.receipt});globalThis.__projectileLatest=envelope.frame;}};
     globalThis.__projectileRender=frame=>{const own=frame.players?.find(player=>player.id===1),auth=globalThis.__projectileLatest?.players?.find(player=>player.id===1);trace.current={tick:frame.tick,phase:frame.phase,ownPlayerId:frame.ownPlayerId,authoritativeTick:globalThis.__projectileLatest?.tick,predicted:own?{x:own.px,y:own.py}:null,authoritative:auth?{x:auth.px,y:auth.py}:null};trace.renders.push(observe(frame));};
     globalThis.__projectileDraw=(x,y,v,b,hostile,width,height)=>{if(!hostile&&b[2]===1)trace.draws.push({...trace.current,at:performance.now(),seed:b[7],owner:b[10]??b[7]%2,generation:b[9]??null,variant:v,body:b,x,y,width,height,onScreen:x>=0&&x<=width&&y>=0&&y<=height});};
     for(const type of ['keydown','keyup'])addEventListener(type,event=>{if(['ArrowRight','ArrowLeft'].includes(event.code))trace.inputs.push({at:performance.now(),type,code:event.code});},true);
     addEventListener('visibilitychange',()=>trace.visibility.push({at:performance.now(),state:document.visibilityState}));
     const NativeWorker=globalThis.Worker;
     globalThis.Worker=class extends NativeWorker{
      constructor(...args){super(...args);this.addEventListener('message',event=>{
       if(event.data.type==='frame'||event.data.type==='remote-frame'){
        trace.worker.push({...observe(event.data.frame),type:event.data.type});
        if(event.data.type==='frame')globalThis.__projectileLatest=event.data.frame;
       }
       if(event.data.type==='error')trace.workerError=event.data;
      });}
     };
    });
    await page.route('**/coop-browser.mjs',async route=>{
     const response=await route.fetch(),source=await response.text(),marker='const envelope = JSON.parse(text);';
     assert.ok(source.includes(marker),'received-frame instrumentation target');
     await route.fulfill({response,body:source.replace(marker,marker+' globalThis.__projectileReceived?.(envelope);')});
    });
    await page.route('**/renderer.mjs',async route=>{
     const response=await route.fetch(),source=await response.text();
     const draw='draw(frame, dt = 1 / 60, options = {}) {',shot='projectile(x, y, v, b, hostile) {';
     assert.ok(source.includes(draw)&&source.includes(shot),'renderer instrumentation targets');
     await route.fulfill({response,body:source.replace(draw,draw+' globalThis.__projectileRender?.(frame);').replace(shot,shot+' globalThis.__projectileDraw?.(x,y,v,b,hostile,this.width,this.height);')});
    });
   }
   if(observationDelayMs>0)await guest.route('**/coop-transport.mjs',async route=>{
    const response=await route.fetch(),source=await response.text();
    const marker='#emit(event) { this.#callback({ ...event, connectionEpoch: this.#epoch, state: this.snapshot() }); }';
    assert.ok(source.includes(marker),'observation-delay IO instrumentation target');
    await route.fulfill({response,body:source.replace(marker,`#emit(event) { const value={ ...event, connectionEpoch: this.#epoch, state: this.snapshot() }; if(event.type==='message')setTimeout(()=>this.#callback(value),${observationDelayMs});else this.#callback(value); }`)});
   });
   if(mode==='throttled')await host.route('**/coop-worker.mjs',async route=>{
    const response=await route.fetch(),source=await response.text();
    await route.fulfill({response,body:'const interval=globalThis.setInterval;globalThis.setInterval=(callback,ms,...rest)=>interval(callback,Math.max(1000,ms),...rest);\n'+source});
   });
   await host.goto(base);assert.equal(await host.locator('#coop-character').inputValue(),'0','host default survivor');
   await host.locator('#coop-host').click();
   await host.waitForFunction(()=>document.querySelector('#coop-invite-link')?.value.includes('join='),null,{timeout:120000});
   const invite=await host.locator('#coop-invite-link').inputValue();
   await guest.goto(invite);assert.equal(await guest.locator('#coop-character').inputValue(),'0','guest default survivor');
   await guest.locator('#coop-join').click();
   await host.waitForFunction(()=>globalThis.__projectileLatest?.players?.length===2&&globalThis.__projectileLatest.tick>5,null,{timeout:120000});
   await guest.waitForFunction(()=>globalThis.__projectileLatest?.players?.length===2,null,{timeout:120000});
   await host.bringToFront();const hostFront=await Promise.all([host.evaluate(()=>document.visibilityState),guest.evaluate(()=>document.visibilityState)]);
   await guest.bringToFront();const guestFront=await Promise.all([host.evaluate(()=>document.visibilityState),guest.evaluate(()=>document.visibilityState)]);
   await guest.locator('#coop-game').focus();
   const start=await host.evaluate(()=>({at:performance.now(),tick:globalThis.__projectileLatest.tick}));
   await guest.keyboard.down('ArrowRight');await guest.waitForTimeout(4000);await guest.keyboard.up('ArrowRight');
   await guest.keyboard.down('ArrowLeft');await guest.waitForTimeout(3000);await guest.keyboard.up('ArrowLeft');
   await guest.waitForTimeout(Math.max(0,duration-7000));
   let freeze=null;
   if(mode==='frozen'){
    const cdp=await contexts[0].newCDPSession(host);
    const before=await guest.evaluate(()=>({received:globalThis.__projectileTrace.received.length,tick:globalThis.__projectileLatest.tick,at:performance.now()}));
    await cdp.send('Page.setWebLifecycleState',{state:'frozen'});await guest.waitForTimeout(6000);
    const after=await guest.evaluate(()=>({received:globalThis.__projectileTrace.received.length,tick:globalThis.__projectileLatest.tick,at:performance.now(),status:document.querySelector('#coop-play-status').textContent}));
    await cdp.send('Page.setWebLifecycleState',{state:'active'});freeze={before,after};await guest.waitForTimeout(1000);await cdp.detach();
   }
   const hostTrace=await host.evaluate(()=>({trace:globalThis.__projectileTrace,latest:{tick:globalThis.__projectileLatest.tick,phase:globalThis.__projectileLatest.phase,players:globalThis.__projectileLatest.players,bodies:globalThis.__projectileLatest.bodies},visibility:document.visibilityState,at:performance.now()}));
   const guestTrace=await guest.evaluate(()=>({trace:globalThis.__projectileTrace,latest:{tick:globalThis.__projectileLatest.tick,phase:globalThis.__projectileLatest.phase,players:globalThis.__projectileLatest.players,bodies:globalThis.__projectileLatest.bodies},visibility:document.visibilityState,status:document.querySelector('#coop-play-status').textContent}));
   const source=await guest.evaluate(async()=>{const response=await fetch('./version.json');try{return JSON.parse(await response.text());}catch{return {available:false,status:response.status};}});
   const generated=hostTrace.trace.worker.filter(row=>row.type==='frame');
   const sent=hostTrace.trace.worker.filter(row=>row.type==='remote-frame');
   const received=guestTrace.trace.received;
   const draws=guestTrace.trace.draws;
   const lastAges=new Map(),births=[];
   for(const row of draws.filter(row=>row.owner===1)){
    const age=row.body[6],identity=row.generation??row.seed,prior=lastAges.get(identity);lastAges.set(identity,age);
    if((prior===undefined||age<prior)&&age<=3&&row.predicted&&row.authoritative)births.push({...row,predictedDistance:Math.hypot(row.body[0]-row.predicted.x,row.body[1]-row.predicted.y),authoritativeDistance:Math.hypot(row.body[0]-row.authoritative.x,row.body[1]-row.authoritative.y),predictionLead:Math.hypot(row.predicted.x-row.authoritative.x,row.predicted.y-row.authoritative.y)});
   }
   const movingAgeZeroBirths=births.filter(row=>row.body[6]===0&&row.predictionLead>10);
   const maxMovingBirthDistance=Math.max(0,...movingAgeZeroBirths.map(row=>row.predictedDistance));
   const flights=new Map(),flightJumps=[];let flightSamples=0,maxFlightAdvanceExcess=0;
   for(const row of draws.filter(row=>row.owner===1&&row.variant%24===0)){
    const identity=row.generation??row.seed,previous=flights.get(identity);flights.set(identity,row);
    if(!previous||row.body[6]<previous.body[6]||row.at<=previous.at)continue;
    const dt=row.at-previous.at,distance=Math.hypot(row.body[0]-previous.body[0],row.body[1]-previous.body[1]);
    const bound=7.5*(Math.ceil(dt/(1000/60))+1)+1,excess=Math.max(0,distance-bound);
    flightSamples++;maxFlightAdvanceExcess=Math.max(maxFlightAdvanceExcess,excess);
    if(excess>.1)flightJumps.push({at:row.at,identity,dt,distance,bound,previous,row});
   }
   const outcome={mode,observationDelayMs,originLimit,flightSamples,maxFlightAdvanceExcess,movingAgeZeroBirths:movingAgeZeroBirths.length,maxMovingBirthDistance,source,hostFront,guestFront,hostVisibility:hostTrace.visibility,guestVisibility:guestTrace.visibility,hostSimHz:1000*(hostTrace.latest.tick-start.tick)/(hostTrace.at-start.at),host: summarise(generated),sent:summarise(sent),received:summarise(received),guestRender:summarise(guestTrace.trace.renders),guestProjectileDrawCalls:draws.filter(row=>row.owner===1).length,guestProjectileOnScreenCalls:draws.filter(row=>row.owner===1&&row.onScreen).length,hostProjectileOnScreenCalls:draws.filter(row=>row.owner===0&&row.onScreen).length,births:births.map(row=>({at:row.at,tick:row.tick,seed:row.seed,generation:row.generation,owner:row.owner,age:row.body[6],x:row.body[0],y:row.body[1],predicted:row.predicted,authoritative:row.authoritative,predictedDistance:row.predictedDistance,authoritativeDistance:row.authoritativeDistance,predictionLead:row.predictionLead})),guestMovement:{initial:received[0]?.players.find(p=>p.id===1),final:guestTrace.latest.players.find(p=>p.id===1)},freeze,workerError:hostTrace.trace.workerError,errors};
   results.push(outcome);
   await writeFile(`${output}/${mode}.json`,JSON.stringify({outcome,hostTrace,guestTrace,flightJumps},null,2));
   await guest.screenshot({path:`${output}/${mode}-guest.png`});
   await host.screenshot({path:`${output}/${mode}-host.png`});
   console.log(JSON.stringify(outcome));
   assert.deepEqual(errors,[]);assert.equal(outcome.workerError,undefined);
   if(enforce&&mode!=='frozen'){
    assert.ok(outcome.host.framesWithGuestShots>0,'authoritative world must contain guest-owned projectiles');
    assert.ok(outcome.sent.framesWithGuestShots>0,'guest snapshots must include guest-owned projectiles');
    assert.ok(outcome.received.framesWithGuestShots>0,'guest must receive its projectiles');
    assert.ok(outcome.guestProjectileOnScreenCalls>0,'guest-owned projectile must reach on-screen renderer');
    assert.ok(outcome.movingAgeZeroBirths>=2,'observe at least two newborn guest projectiles while prediction is ahead');
    assert.ok(outcome.flightSamples>=30,'capture sustained guest ballistic motion');
    assert.ok(outcome.maxFlightAdvanceExcess<.1,'existing guest projectile must fit elapsed fixed-tick flight-speed bound');
    assert.ok(outcome.maxMovingBirthDistance<=originLimit,`newborn projectile is ${outcome.maxMovingBirthDistance.toFixed(1)}units from displayed guest; limit${originLimit}`);
   }
  }finally{await Promise.all(contexts.map(context=>context.close()));}
 }
 await writeFile(`${output}/summary.json`,JSON.stringify({pass:enforce?true:null,enforce,results},null,2));
}catch(error){await writeFile(`${output}/failure.json`,JSON.stringify({message:error.message,stack:error.stack,results},null,2));throw error;}
finally{await browser.close();}
