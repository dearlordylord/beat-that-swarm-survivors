// Cross-side regression: actual client ticks, host FIFO consumption and ACK replay.
// This compares the two running state machines, including every pending suffix length.
import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
const directory=process.env.COOP_LATENCY_MODULE_DIR || fileURLToPath(new URL('./dist/web/dist',import.meta.url));
const load=async name=>(await import(pathToFileURL(path.join(directory,name+'.mjs')))).default;
const [P,Q,M,S]=await Promise.all(['coop-prediction','coop-input-queue','player-movement','coop-session'].map(load));
const point=state=>P.view(state);
const same=(actual,expected,label)=>assert.deepEqual(actual,expected,label);
let randomState=0x51ab19;
const random=()=>{randomState^=randomState<<13;randomState^=randomState>>>17;randomState^=randomState<<5;return randomState>>>0;};
test('all consumed-prefix/pending-suffix splits preserve the actual predicted path',()=>{
 let comparisons=0;
 for(let sample=0;sample<48;sample++){
  const distance=[2.5,3.125,4.2][sample%3];
  let client=P.fresh(sample%2?128:7200,sample%3?7200:14270,distance,true);
  let queue=Q.fresh(7);const commands=[];
  for(let i=0;i<60;i++){
   const command={seq:2*i+1,x:random()%3,y:random()%3};commands.push(command);
   client=P.tick(P.command(client,command.seq,command.x,command.y));
   const admitted=Q.push(queue,7,command.seq,command.x,command.y);
   assert.equal(admitted.accepted,true);queue=admitted.state;
  }
  const predicted=point(client);let host={$:'Point',x:sample%2?128:7200,y:sample%3?7200:14270};
  let receipt=S.receipt_fresh();
  for(let consumed=0;consumed<=60;consumed++){
   if(consumed){const next=Q.take(queue);queue=next.state;
    const tick=next.tick.value;host=M.move_point(host.x,host.y,distance,S.axis(tick.x),S.axis(tick.y));receipt=Q.receipt(receipt,next.tick);}
   const reconciled=P.reconcile(client,consumed+1,host.x,host.y,distance,true,receipt);
   same(point(reconciled),predicted,`sample${sample} consumed${consumed}`);comparisons++;
   // Repeated cumulative snapshots must preserve that same position too.
   const repeated=P.reconcile(reconciled,consumed+2,host.x,host.y,distance,true,receipt);
   same(point(repeated),predicted,'repeated consumed prefix');comparisons++;
  }
 }
 assert.equal(comparisons,5856);
});
test('interleaved client frames, batched delivery and delayed ACKs preserve movement',()=>{
 let client=P.fresh(7200,7200,2.5,true),queue=Q.fresh(3),host={$:'Point',x:7200,y:7200};
 let receipt=S.receipt_fresh(),outgoing=[],observation=0,sequence=0;
 for(let frame=0;frame<900;frame++){
  if(client.age<P.horizon()){
   const command={seq:++sequence,x:frame%120<60?2:0,y:frame%180<90?2:1};
   client=P.tick(P.command(client,command.seq,command.x,command.y));outgoing.push(command);
  }
  if(frame%4===0){for(const tick of outgoing){const a=Q.push(queue,3,tick.seq,tick.x,tick.y);assert.equal(a.accepted,true);queue=a.state;}outgoing=[];}
  const next=Q.take(queue);queue=next.state;
  if(next.tick.$==='Some'){const tick=next.tick.value;host=M.move_point(host.x,host.y,2.5,S.axis(tick.x),S.axis(tick.y));receipt=Q.receipt(receipt,next.tick);}
  if(frame%7===0){const before=point(client);client=P.reconcile(client,++observation,host.x,host.y,2.5,true,receipt);same(point(client),before,`frame${frame} ACK must not move the camera`);}
 }
});
