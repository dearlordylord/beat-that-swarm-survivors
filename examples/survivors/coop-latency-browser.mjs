// Measures input-to-render using the real Bend worker/UI and an explicitly delayed
// byte link. This is not an Iroh network benchmark; real Iroh has its own smoke.
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const web = path.resolve(process.env.COOP_LATENCY_WEB_DIR || fileURLToPath(new URL('./dist/web', import.meta.url)));
const output = process.env.COOP_LATENCY_QA_DIR || '/tmp/bendvy-coop-latency';
const rtts = (process.env.COOP_LATENCY_RTTS || '100,250,500').split(',').map(Number);
const limit = Number(process.env.COOP_INPUT_LATENCY_LIMIT_MS || 50);
const enforce = process.env.COOP_LATENCY_ENFORCE !== '0';
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
    const wire=new TextDecoder().decode(new Uint8Array(event.bytes));
    try{const value=JSON.parse(wire);if(value.type==='frame'){globalThis.__latencyReceives.push({at:performance.now(),admission:value.admission,receipt:value.receipt,tick:value.frame.tick,phase:value.frame.phase});if(globalThis.__latencyReceives.length>200)globalThis.__latencyReceives.shift();}}catch{}
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
    const deliveryAt=[0,0],deliveryQueues=[[],[]],deliveryActive=[false,false],sendCount=[0,0];
    for(let index=0;index<pages.length;index++){
      const page=pages[index],peer=pages[1-index];
      page.on('pageerror',error=>errors.push(error.message));
      await page.route('**/coop-transport.mjs',route=>route.fulfill({contentType:'text/javascript',body:mockTransport}));
      await page.route('**/renderer.mjs',async route=>{
        const response=await route.fetch();const source=await response.text();
        assert.ok(source.includes('draw(frame, dt = 1 / 60, options = {}) {'),'renderer instrumentation target');
        await route.fulfill({response,body:source.replace('draw(frame, dt = 1 / 60, options = {}) {','draw(frame, dt = 1 / 60, options = {}) { globalThis.__latencyRender?.(frame);')});
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
        const sendIndex=sendCount[index]++,now=performance.now(),variation=0;
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
        globalThis.__fixtureDeliveryTrace=[];globalThis.__latencyRenders=[];globalThis.__latencyInputs=[];globalThis.__latencyFrames=[];globalThis.__latencyReceives=[];globalThis.__latencyAcks=[];
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
      // Keep clear of a level barrier: two short movements and a full RTT of rest.
      await guest.keyboard.down('ArrowRight');await guest.waitForTimeout(350);
      await guest.keyboard.up('ArrowRight');await guest.keyboard.down('ArrowLeft');await guest.waitForTimeout(350);
      await guest.keyboard.up('ArrowLeft');await guest.waitForTimeout(rtt+600);
      const trace=await guest.evaluate(()=>({renders:globalThis.__latencyRenders,inputs:globalThis.__latencyInputs,receives:globalThis.__latencyReceives,deliveries:globalThis.__fixtureDeliveryTrace,origin:performance.timeOrigin,status:document.querySelector('#coop-play-status')?.textContent}));
      const authoritative=await host.evaluate(()=>({frame:globalThis.__latencyAuthoritative,error:globalThis.__latencyWorkerError,frames:globalThis.__latencyFrames,deliveries:globalThis.__fixtureDeliveryTrace,acks:globalThis.__latencyAcks}));
      await writeFile(`${output}/raw-rtt-${rtt}.json`,JSON.stringify({trace,authoritative,events,errors},null,2));
      for(let peer=0;peer<2;peer++){const order=events.filter(event=>event.kind==='deliver'&&event.peer===peer).map(event=>event.sendIndex);assert.deepEqual(order,order.map((_,index)=>index),'fixture must deliver a strict send-order prefix');}
      assert.equal(authoritative.error,undefined,'real Bend worker must not fail');assert.deepEqual(errors,[]);
      const moves=trace.inputs.filter(input=>input.type==='down'&&['ArrowRight','ArrowLeft'].includes(input.code)).map(input=>{
        const before=trace.renders.findLast(render=>render.at<=input.at);
        assert.ok(before,'rendered baseline before keydown');const sign=input.code==='ArrowRight'?1:-1;
        const seenIndex=trace.renders.findIndex((render,index)=>render.at>=input.at&&index>0&&sign*(render.x-trace.renders[index-1].x)>.1);
        const seen=trace.renders[seenIndex],prior=trace.renders[seenIndex-1];
        assert.ok(seen,'rendered movement after '+input.code);
        const axis=sign===1?'2':'0';
        const sent=events.find(event=>{const fields=event.wire?.split('|');return event.peer===1&&event.at>=input.at&&['T','I'].includes(fields?.[5])&&fields.at(-2)===axis&&fields.at(-1)==='1';});
        const seq=sent?Number(sent.wire.split('|')[3]):null;
        const ack=seq===null?null:authoritative.acks.find(event=>event.receipt.seq>=seq);
        const received=seq===null?null:trace.receives.find(event=>event.receipt?.seq>=seq);
        const appliedAt=ack?ack.origin+ack.at-trace.origin:null;
        return {code:input.code,inputAt:input.at,firstRenderAt:seen.at,latencyMs:seen.at-input.at,seq,inputToSendMs:sent?sent.at-input.at:null,sendToHostApplyMs:sent&&ack?appliedAt-sent.at:null,hostApplyToReceiveMs:ack&&received?received.at-appliedAt:null,receiveToRenderMs:received?seen.at-received.at:null,renderedBeforeAuthority:received?seen.at<received.at:null,cameraLag:Math.abs((seen.cameraX-prior.cameraX)-(seen.x-prior.x))};
      });
      const released=trace.inputs.findLast(input=>input.type==='up'&&input.code==='ArrowLeft');
      const afterStop=trace.renders.filter(render=>render.at>=released.at);
      const stable=afterStop.find((render,i)=>i>=2&&Math.abs(render.x-afterStop[i-1].x)<.05&&Math.abs(afterStop[i-1].x-afterStop[i-2].x)<.05);
      assert.ok(stable,'stop eventually renders without movement');
      const final=trace.renders.at(-1),own=authoritative.frame.players.find(player=>player.id===1);
      const outcome={rttMs:rtt,hostToGuestOWD:deliveryStats(trace.deliveries),guestToHostOWD:deliveryStats(authoritative.deliveries),moves,firstRenderP95Ms:percentile(moves.map(move=>move.latencyMs),.95),stopMs:stable.at-released.at,finalError:Math.hypot(final.x-own.px,final.y-own.py),phase:authoritative.frame.phase,transportSends:events.filter(event=>event.kind==='send').length,errors};
      // Trusted fixture changes real Bend XP, never a fabricated pause observation.
      await host.evaluate(()=>globalThis.__latencyWorker.postMessage({type:'latency-fixture-level'}));
      await guest.waitForFunction(()=>globalThis.__latencyReceives.some(frame=>frame.phase===1),null,{timeout:10000});
      await guest.waitForTimeout(100);
      const pauseFrom=await guest.evaluate(()=>({at:performance.now(),frame:globalThis.__latencyRenders.at(-1)}));
      await guest.keyboard.down('ArrowRight');await guest.waitForTimeout(120);await guest.keyboard.up('ArrowRight');
      const pause=await guest.evaluate(from=>{
        const rows=globalThis.__latencyRenders.filter(frame=>frame.at>=from.at);
        return {samples:rows.length,maxMotion:Math.max(...rows.map(frame=>Math.hypot(frame.x-from.frame.x,frame.y-from.frame.y))),phases:[...new Set(rows.map(frame=>frame.phase))]};
      },pauseFrom);
      outcome.pause=pause;
      results.push(outcome);await writeFile(`${output}/rtt-${rtt}.json`,JSON.stringify({outcome,trace,authoritative,events},null,2));
      console.log(JSON.stringify(outcome));
      assert.ok(pause.samples>=3&&pause.maxMotion<.5,'observed global reward pause must disable local prediction');
      if(enforce){
        for(const move of moves){assert.ok(move.seq!==null&&move.sendToHostApplyMs!==null&&move.hostApplyToReceiveMs!==null,'trace must include send, consumed receipt, and received ACK');assert.ok(move.renderedBeforeAuthority,'first motion must precede authoritative ACK');assert.ok(move.latencyMs<=limit,`${rtt}ms RTT ${move.code} input-to-render ${move.latencyMs.toFixed(1)}ms exceeds ${limit}ms`);assert.ok(move.cameraLag<1,'camera must respond with local player');}
        assert.ok(outcome.stopMs<=limit+34,`${rtt}ms RTT local stop delayed`);
        assert.ok(outcome.finalError<1,`${rtt}ms RTT prediction must converge after ACK/stop`);
      }
    }finally{for(const timer of deliveries)clearTimeout(timer);await Promise.all(contexts.map(context=>context.close()));}
  }
  await writeFile(`${output}/summary.json`,JSON.stringify({pass:true,enforce,limitMs:limit,results},null,2));
}catch(error){
  await writeFile(`${output}/failure.json`,JSON.stringify({message:error.message,stack:error.stack,results},null,2));
  throw error;
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
