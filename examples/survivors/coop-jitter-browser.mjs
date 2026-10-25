// Measures sustained motion, including backwards corrections on each drawn frame.
// Real Bend worker/UI, injected byte-link delay; not an Iroh network benchmark.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const web = path.resolve(process.env.COOP_LATENCY_WEB_DIR || fileURLToPath(new URL('./dist/web', import.meta.url)));
const output = process.env.COOP_LATENCY_QA_DIR || '/tmp/bendvy-coop-jitter';
const rtts = (process.env.COOP_LATENCY_RTTS || '100,250,500').split(',').map(Number);
const limit = Number(process.env.COOP_JITTER_BACKSTEP_LIMIT || 0.1);
const enforce = process.env.COOP_LATENCY_ENFORCE !== '0';
const jitterMs = Number(process.env.COOP_JITTER_MS || 0);
assert.ok(Number.isFinite(jitterMs)&&jitterMs>=0&&jitterMs<=200,'bounded injected jitter');
const mime = {'.html':'text/html','.mjs':'text/javascript','.js':'text/javascript','.css':'text/css','.wasm':'application/wasm','.svg':'image/svg+xml'};
await mkdir(output,{recursive:true});
const server = createServer(async (request,response) => {
  try {
    const name = decodeURIComponent(new URL(request.url,'http://localhost').pathname);
    const target = path.resolve(web,'.'+name);
    if (!target.startsWith(web+path.sep)) {response.writeHead(403).end();return;}
    const bytes = await readFile(target);
    response.writeHead(200,{'content-type':mime[path.extname(target)]||'application/octet-stream','cache-control':'no-store'}).end(bytes);
  } catch { response.writeHead(404).end(); }
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const base = `http://127.0.0.1:${server.address().port}/coop.html`;
const browser = await chromium.launch({headless:true,args:['--no-sandbox']});
const results=[];
const mockTransport = `
export class CoopTransport {
 static async create(callback){
  globalThis.__latencyReceive = event => {
   if(event.type==='message'){
    globalThis.__fixtureDeliveryTrace.push({at:performance.now(),sendIndex:event.sendIndex,bytes:event.bytes.length,oneWayMs:performance.timeOrigin+performance.now()-event.sentOrigin-event.sentAt});
    const wire=new TextDecoder().decode(new Uint8Array(event.bytes));globalThis.__jitterWireReceives.push({at:performance.now(),wire:wire.length<200?wire:undefined});
    try{const value=JSON.parse(wire);if(value.type==='frame'){globalThis.__latencyReceives.push({at:performance.now(),admission:value.admission,receipt:value.receipt,x:value.frame.px,y:value.frame.py,tick:value.frame.tick,phase:value.frame.phase});if(globalThis.__latencyReceives.length>200)globalThis.__latencyReceives.shift();}}catch{}
   }
   callback(event.type==='message'?{...event,bytes:new Uint8Array(event.bytes)}:event);
  };
  return new CoopTransport();
 }
 endpointId(){return 'latency-fixture';}
 invitation(){return 'latency-fixture';}
 async join(ticket){await globalThis.__latencyConnect();}
 async send(payload){
  const at=performance.now(),bytes=typeof payload==='string'?new TextEncoder().encode(payload):payload;
  let binary='';for(let offset=0;offset<bytes.length;offset+=32768)binary+=String.fromCharCode(...bytes.subarray(offset,offset+32768));
  await globalThis.__latencySend(btoa(binary),at,performance.timeOrigin);
 }
 close(){}
}
`;
function percentile(rows,fraction){const sorted=rows.slice().sort((a,b)=>a-b);return sorted[Math.min(sorted.length-1,Math.floor(sorted.length*fraction))];}
function deliveryStats(rows){return {samples:rows.length,p50Ms:percentile(rows.map(row=>row.oneWayMs),.5),p95Ms:percentile(rows.map(row=>row.oneWayMs),.95),maxMs:Math.max(0,...rows.map(row=>row.oneWayMs)),maxBytes:Math.max(0,...rows.map(row=>row.bytes))};}
try {
  for (const rtt of rtts) {
    assert.ok(Number.isFinite(rtt)&&rtt>=0&&rtt<=2000,'bounded injected RTT');
    const contexts = await Promise.all([browser.newContext({viewport:{width:1024,height:640}}),browser.newContext({viewport:{width:1024,height:640}})]);
    const pages = await Promise.all(contexts.map(context=>context.newPage()));
    const [host,guest]=pages, events=[],errors=[],deliveries=new Set();
    let joined=false;
    const deliveryAt=[0,0],deliveryQueues=[[],[]],deliveryActive=[false,false],sendCount=[0,0],jitterPattern=[0,1,-.5,.75,-1,.25];
    for(let index=0;index<pages.length;index++){
      const page=pages[index],peer=pages[1-index];
      page.on('pageerror',error=>errors.push(error.message));
      await page.route('**/coop-transport.mjs',route=>route.fulfill({contentType:'text/javascript',body:mockTransport}));
      await page.route('**/renderer.mjs',async route=>{
        const response=await route.fetch();const source=await response.text();
        assert.ok(source.includes('draw(frame, dt = 1 / 60, options = {}) {'),'renderer instrumentation target');
        await route.fulfill({response,body:source.replace('draw(frame, dt = 1 / 60, options = {}) {','draw(frame, dt = 1 / 60, options = {}) { globalThis.__latencyRender?.(frame);')});
      });
      await page.route('**/coop-browser.mjs',async route=>{
        const response=await route.fetch();const source=await response.text();
        const before='  prediction = Prediction.reconcile(prediction,envelope.observationSeq,frame.px,frame.py,';
        const after='  if (prediction.observation !== envelope.observationSeq) return false;';
        assert.ok(source.includes(before)&&source.includes(after),'reconciliation instrumentation target');
        await route.fulfill({response,body:source.replace(before,"  const jitterBefore=structuredClone(prediction);\n"+before).replace(after,"  globalThis.__jitterCorrections.push({at:performance.now(),before:jitterBefore,after:structuredClone(prediction),receipt:envelope.receipt,tick:frame.tick,x:frame.px,y:frame.py});\n"+after)});
      });
      await page.route('**/coop-worker.mjs',async route=>{
        const response=await route.fetch();const source=await response.text();
        const marker='session = Session.applied(frame.tick, session);';
        assert.ok(source.includes(marker),'worker consumed-receipt instrumentation target');
        const instrumented=source.replace(marker,marker+`\npostMessage({type:'latency-ack',at:performance.now(),origin:performance.timeOrigin,receipt:guestReceipt,tick:frame.tick});`);
        await route.fulfill({response,body:instrumented+`\nconst originalMessage=onmessage;onmessage=event=>{if(event.data.type==='latency-fixture-level'){core.shared.xp=core.shared.xpNeed;return;}originalMessage(event);};`});
      });
      await page.exposeFunction('__latencyConnect',async()=>{
        if(joined)return;joined=true;
        await Promise.all(pages.map((p,i)=>p.evaluate(id=>globalThis.__latencyReceive({type:'connected',peerId:'fixture-'+id}),1-i)));
      });
      await page.exposeFunction('__latencySend',(encoded,at,origin)=>{
        const bytes=Buffer.from(encoded,'base64'),wire=new TextDecoder().decode(bytes);
        events.push({kind:'send',peer:index,at,origin,wire:wire.length<200?wire:undefined});
        // Preserve stream ordering while varying its cadence, as a reliable link does.
        const sendIndex=sendCount[index]++,now=performance.now(),variation=jitterPattern[sendIndex%jitterPattern.length]*jitterMs;
        deliveryAt[index]=Math.max(deliveryAt[index],now+Math.max(0,rtt/2+variation));
        deliveryQueues[index].push({arrival:deliveryAt[index],encoded,peerId:'fixture-'+index,sendIndex,sentAt:at,sentOrigin:origin,wire:wire.length<200?wire:undefined});
        if(!deliveryActive[index]){
          deliveryActive[index]=true;
          // Batch already-due messages: one CDP roundtrip per byte would create
          // fake network backpressure at 60 commands/s on a busy test machine.
          const pump=async()=>{
            while(deliveryQueues[index].length&&!peer.isClosed()){
              const delay=deliveryQueues[index][0].arrival-performance.now();
              if(delay>0)await new Promise(resolve=>{
                const timer=setTimeout(()=>{deliveries.delete(timer);resolve();},delay);deliveries.add(timer);
              });
              if(peer.isClosed())return;
              const due=performance.now(),batch=[];
              while(deliveryQueues[index].length&&deliveryQueues[index][0].arrival<=due)batch.push(deliveryQueues[index].shift());
              if(!batch.length)continue;
              for(const row of batch)events.push({kind:'deliver',peer:index,sendIndex:row.sendIndex,wire:row.wire,driverAt:due});
              await peer.evaluate(rows=>{for(const {encoded,peerId,sendIndex,sentAt,sentOrigin}of rows){
                const binary=atob(encoded),bytes=Uint8Array.from(binary,char=>char.charCodeAt(0));
                globalThis.__latencyReceive?.({type:'message',bytes,peerId,sendIndex,sentAt,sentOrigin});
              }},batch);
            }
          };
          pump().catch(error=>{if(!peer.isClosed())errors.push(error.message);}).finally(()=>{deliveryActive[index]=false;});
        }
      });
      await page.addInitScript(()=>{
        globalThis.__fixtureDeliveryTrace=[];globalThis.__jitterWireReceives=[];globalThis.__jitterCorrections=[];globalThis.__latencyRenders=[];globalThis.__latencyInputs=[];globalThis.__latencyFrames=[];globalThis.__latencyReceives=[];globalThis.__latencyAcks=[];
        globalThis.__latencyRender=frame=>{
          const own=frame.players?.find(player=>player.id===frame.ownPlayerId);
          if(own){globalThis.__latencyRenders.push({at:performance.now(),x:own.px,y:own.py,cameraX:frame.px,cameraY:frame.py,tick:frame.tick,phase:frame.phase});if(globalThis.__latencyRenders.length>2000)globalThis.__latencyRenders.shift();}
        };
        addEventListener('keydown',event=>{if(!event.repeat)globalThis.__latencyInputs.push({at:performance.now(),type:'down',code:event.code});},true);
        addEventListener('keyup',event=>globalThis.__latencyInputs.push({at:performance.now(),type:'up',code:event.code}),true);
        const Original=Worker;
        globalThis.Worker=class extends Original{
          constructor(...args){super(...args);globalThis.__latencyWorker=this;this.addEventListener('message',event=>{
            if(event.data.type==='frame'){globalThis.__latencyAuthoritative=event.data.frame;globalThis.__latencyFrames.push({at:performance.now(),frame:event.data.frame});if(globalThis.__latencyFrames.length>100)globalThis.__latencyFrames.shift();}
            if(event.data.type==='latency-ack'){globalThis.__latencyAcks.push(event.data);if(globalThis.__latencyAcks.length>1000)globalThis.__latencyAcks.shift();}
            if(event.data.type==='error')globalThis.__latencyWorkerError=event.data.stack||event.data.message;
          });}
        };
      });
    }
    try{
      await host.goto(base);await host.locator('#coop-host').click();
      await host.waitForFunction(()=>document.querySelector('#coop-invite-link')?.value.includes('join='));
      const invite=await host.locator('#coop-invite-link').inputValue();
      await guest.goto(invite);await guest.locator('#coop-join').click();
      await guest.waitForFunction(()=>globalThis.__latencyRenders.length>5);
      await guest.locator('#coop-game').focus();
      await guest.keyboard.down('ArrowRight');await guest.waitForTimeout(3500);
      await guest.keyboard.up('ArrowRight');await guest.keyboard.down('ArrowLeft');await guest.waitForTimeout(800);
      await guest.keyboard.up('ArrowLeft');await guest.waitForTimeout(rtt+700);
      const trace=await guest.evaluate(()=>({renders:globalThis.__latencyRenders,inputs:globalThis.__latencyInputs,receives:globalThis.__latencyReceives,deliveries:globalThis.__fixtureDeliveryTrace,corrections:globalThis.__jitterCorrections,origin:performance.timeOrigin,status:document.querySelector('#coop-play-status')?.textContent}));
      const authoritative=await host.evaluate(()=>({frame:globalThis.__latencyAuthoritative,error:globalThis.__latencyWorkerError,frames:globalThis.__latencyFrames,deliveries:globalThis.__fixtureDeliveryTrace,acks:globalThis.__latencyAcks,wireReceives:globalThis.__jitterWireReceives,origin:performance.timeOrigin}));
      const inputs=trace.inputs.filter(input=>['ArrowRight','ArrowLeft'].includes(input.code));
      const holds=inputs.filter(input=>input.type==='down').map(input=>({
        begin:input.at,end:inputs.find(next=>next.type==='up'&&next.code===input.code&&next.at>=input.at).at,
        sign:input.code==='ArrowRight'?1:-1,code:input.code,
      }));
      const deltas=trace.renders.slice(1).map((row,index)=>({at:row.at,dt:row.at-trace.renders[index].at,dx:row.x-trace.renders[index].x,dy:row.y-trace.renders[index].y,cameraDx:row.cameraX-trace.renders[index].cameraX,tick:row.tick}));
      const motion=holds.map(hold=>{
        const rows=deltas.filter(row=>row.at>=hold.begin+300&&row.at<hold.end-100);
        const backwards=rows.filter(row=>hold.sign*row.dx<-.1);
        const first=deltas.find(row=>row.at>=hold.begin&&hold.sign*row.dx>.1);
        return {...hold,samples:rows.length,firstResponseMs:first?first.at-hold.begin:null,backwards:backwards.length,maxBackstep:Math.max(0,...backwards.map(row=>-hold.sign*row.dx)),minDx:Math.min(...rows.map(row=>hold.sign*row.dx)),maxDx:Math.max(...rows.map(row=>hold.sign*row.dx)),travel:rows.reduce((sum,row)=>sum+hold.sign*row.dx,0)};
      });
      const analysed=deltas.filter(row=>holds.some(hold=>row.at>=hold.begin+300&&row.at<hold.end-100));
      const receivedCorrelation=analysed.filter(row=>holds.some(hold=>row.at>=hold.begin+300&&row.at<hold.end-100&&hold.sign*row.dx<-.1)).map(row=>({...row,receipt:trace.receives.findLast(receive=>receive.at<=row.at)}));
      const corrections=trace.corrections.map(row=>({at:row.at,tick:row.tick,dx:row.after.x-row.before.x,dy:row.after.y-row.before.y,error:Math.hypot(row.after.x-row.before.x,row.after.y-row.before.y),receipt:row.receipt}));
      const step=authoritative.frame.stepDistance;
      const excessAdvance=analysed.map(row=>Math.max(0,Math.abs(row.dx)-step*(Math.ceil(row.dt/(1000/60))+1)));
      const release=holds.at(-1).end,afterStop=trace.renders.filter(row=>row.at>=release);
      const stable=afterStop.find((row,index)=>index>=2&&Math.abs(row.x-afterStop[index-1].x)<.05&&Math.abs(afterStop[index-1].x-afterStop[index-2].x)<.05);
      const settled=afterStop.filter(row=>row.at>=release+84),final=trace.renders.at(-1),own=authoritative.frame.players.find(player=>player.id===1);
      const hostFrom=authoritative.frames[0],hostTo=authoritative.frames.at(-1);
      const hostHz=(hostTo.frame.tick-hostFrom.frame.tick)/(hostTo.at-hostFrom.at)*1000;
      const commandOneWays=authoritative.wireReceives.filter(row=>row.wire).map(row=>{const sent=events.find(event=>event.kind==='send'&&event.peer===1&&event.wire===row.wire);return sent?authoritative.origin+row.at-sent.origin-sent.at:null;}).filter(value=>value!==null);
      const commandOneWayP50Ms=percentile(commandOneWays,.5),commandOneWayP95Ms=percentile(commandOneWays,.95);
      const maxPendingTicks=Math.max(...trace.corrections.map(row=>row.after.age));
      const outcome={rttMs:rtt,hostToGuestOWD:deliveryStats(trace.deliveries),guestToHostOWD:deliveryStats(authoritative.deliveries),jitterMs,hostHz,maxPendingTicks,commandOneWayP50Ms,commandOneWayP95Ms,samples:analysed.length,phase:authoritative.frame.phase,motion,backwards:motion.reduce((sum,row)=>sum+row.backwards,0),maxBackstep:Math.max(...motion.map(row=>row.maxBackstep)),maxReconcileCorrection:Math.max(0,...corrections.map(row=>row.error)),stopMs:stable?stable.at-release:null,postStopRange:settled.length?Math.max(...settled.map(row=>row.x))-Math.min(...settled.map(row=>row.x)):null,finalError:Math.hypot(final.x-own.px,final.y-own.py),maxAdvanceBeyondElapsedTicks:Math.max(0,...excessAdvance),zeroFrames:analysed.filter(row=>Math.abs(row.dx)<.01).length,frameDtP95:percentile(analysed.map(row=>row.dt),.95),cameraMismatch:Math.max(...analysed.map(row=>Math.abs(row.dx-row.cameraDx))),errors};
      results.push(outcome);
      await writeFile(`${output}/rtt-${rtt}.json`,JSON.stringify({outcome,trace,authoritative,events,deltas,corrections,receivedCorrelation},null,2));
      console.log(JSON.stringify(outcome));
      for(let peer=0;peer<2;peer++){const order=events.filter(event=>event.kind==='deliver'&&event.peer===peer).map(event=>event.sendIndex);assert.deepEqual(order,order.map((_,index)=>index),'fixture must deliver a strict send-order prefix');}
      assert.equal(authoritative.frame.phase,0,'sustained motion must stay in active gameplay');
      assert.ok(motion[0].samples>=100,'at least 100 drawn sustained-motion samples');
      assert.ok(motion[0].travel>300&&motion[1].travel>25,'real traversal in both directions, not a stationary false pass');
      assert.equal(authoritative.error,undefined,'real Bend worker must not fail');assert.deepEqual(errors,[]);
      if(enforce){
        assert.ok(outcome.maxBackstep<=limit,`${rtt}ms RTT backwards correction ${outcome.maxBackstep.toFixed(2)} exceeds ${limit}`);
        assert.ok(outcome.maxReconcileCorrection<.1,'consuming exact predicted ticks must not correct the displayed point');
        assert.ok(outcome.maxAdvanceBeyondElapsedTicks<.1,'movement must fit elapsed fixed-tick budget');
        for(const row of motion)assert.ok(row.firstResponseMs!==null&&row.firstResponseMs<=50,`${row.code} immediate response`);
        assert.ok(outcome.stopMs!==null&&outcome.stopMs<=84,'release stops locally within84ms');
        assert.ok(outcome.postStopRange<=step+.1,'released player must stay settled through subsequent ACKs');
        assert.ok(outcome.finalError<1,'released prediction converges with authority');
      }
    }finally{for(const timer of deliveries)clearTimeout(timer);await Promise.all(contexts.map(context=>context.close()));}
  }
  await writeFile(`${output}/summary.json`,JSON.stringify({pass:enforce ? true : null,mode:enforce ? 'regression' : 'baseline-collection',enforce,limitUnits:limit,results},null,2));
}catch(error){
  await writeFile(`${output}/failure.json`,JSON.stringify({message:error.message,stack:error.stack,results},null,2));
  throw error;
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
