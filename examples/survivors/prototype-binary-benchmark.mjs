// Throwaway, real emitted Bend + controlled population fixtures. No network claims.
import assert from 'node:assert/strict';
import {mkdtemp,rm,writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {spawnSync} from 'node:child_process';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {MessageChannel} from 'node:worker_threads';
import {cpus} from 'node:os';
import {encode,decode,presentation,rows,MAX_BYTES} from './prototype-binary-codec.mjs';

const scratch=await mkdtemp(join(tmpdir(),'bendvy-binary-benchmark-'));
const samples=Number(process.env.SAMPLES||60);
assert.ok(Number.isInteger(samples)&&samples>=10);
const list=values=>values.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const nil=()=>({$:'Nil'});
const percentile=(values,p)=>[...values].sort((a,b)=>a-b)[Math.min(values.length-1,Math.floor(values.length*p))];
const stats=values=>({p50Ms:+percentile(values,.5).toFixed(3),p95Ms:+percentile(values,.95).toFixed(3)});
const normalize=value=>{
  if(typeof value==='number')return Number.isInteger(value)?value:Math.fround(value);
  if(Array.isArray(value))return value.map(normalize);
  if(value&&typeof value==='object')return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,normalize(v)]));
  return value;
};
const lane=()=>({$:'Lane',lastSeq:9,inputSeq:8,appliedSeq:8,appliedTick:42,receivedAt:43,x:2,y:1});
function envelope(frame,events=[],lastRejected=null){return {
  type:'frame',connectionVersion:1,token:7,initial:false,frame:{...frame,runId:'00000000-0000-4000-8000-000000000001'},
  admission:{$:'State',session:123,clock:43,host:lane(),guest:lane(),guestConnected:true,ended:false},
  receipt:{$:'Receipt',seq:8,worldTick:42,x:2,y:1,applied:true},
  inputTiming:{worldTick:frame.tick,lastRejected},observationSeq:19,
  contactJournal:{$:'State',epoch:7,now:frame.tick,events:list(events),overflow:0,expired:0},
};}
function populated(state,count,statuses=false){
  const snapshots=Array.from({length:count},(_,i)=>({$:'Snapshot',
    body:{$:'Body',x:Math.fround(7100+(i%37)*3.17),y:Math.fround(7100+Math.floor(i/37)*2.23),kind:i%7===0?1:0,variant:i%7===0?11:i%5,hp:120,maxHp:200,age:20+i%40,seed:i,radius:Math.fround(8.1)},
    motion:{$:'Motion',vx:Math.fround(.7),vy:Math.fround(-.31),life:120,pierce:12,visited:statuses?list([1001,2002,3003]):nil(),slow:statuses?65536:0,burn:statuses?17:0,ownerBase:i%2,logicalSlot:65536*(i%2)+i%8},
  }));
  return {...state,shared:{...state.shared,tick:600},bodies:list(snapshots.map(x=>x.body)),snapshots:list(snapshots)};
}
function hits(count){return Array.from({length:count},(_,i)=>({$:'HitEvent',id:`600:1:shot:${i}:target:${i+1}`,tick:600,kind:1,shotId:`shot:1:580:11:${i}`,shotSeed:i,targetSeed:i+1,targetGeneration:560,fraction:Math.fround(.37),impactX:Math.fround(7200.12),impactY:Math.fround(7200.37),targetAtImpactX:Math.fround(7200.12),targetAtImpactY:Math.fround(7200.37),radius:8,outcome:0}));}
async function gzip(bytes){return new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new CompressionStream('gzip'))).arrayBuffer());}
async function gunzip(bytes){return new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))).arrayBuffer());}
const utf8=new TextEncoder(),text=new TextDecoder();
async function transfer(bytes){
  const {port1,port2}=new MessageChannel();
  const received=new Promise(resolve=>port2.once('message',resolve));
  port1.postMessage(bytes,[bytes.buffer]);assert.equal(bytes.byteLength,0);
  const result=await received;port1.close();port2.close();return result;
}
try {
  const output=join(scratch,'observation.mjs');
  const compile=spawnSync(process.env.BEND||'bend',[
    fileURLToPath(new URL('./prototype-binary-observation.bend',import.meta.url)),'-o',output,
  ],{encoding:'utf8',timeout:30000});
  if(compile.status!==0)throw Error(compile.stdout+compile.stderr);
  const {default:B}=await import(pathToFileURL(output));
  function liveState() {
    // Emitted Bend mutates affine array storage. Each fixture owns a fresh world.
    let state=B.join(B.start().state).state;
    assert.ok(state,'guest joins real core');
    for(let i=0;i<60;i++)state=B.step(state).state;
    return state;
  }
  const fixtures=[
    ['initial',B.start().state,[]],['live-60-ticks',liveState(),[]],
    ['population-128',populated(liveState(),128),[]],['population-512',populated(liveState(),512),[]],
    ['population-1000',populated(liveState(),1000),[]],['status-512-journal-512',populated(liveState(),512,true),hits(512)],
    ['choice', {...liveState(),round:3,required:list([0,1]),offers:list([{$:'PlayerOffers',id:1,offers:list([{$:'Offer',kind:0,id:11,level:2}])}])},[]],
    ['disconnected',B.disconnect(liveState()).state,[]],
  ];
  function assertFixture(name,frame) {
    const initial=name==='initial',populated=name.startsWith('population-')||name==='status-512-journal-512';
    assert.equal(frame.tick,initial?0:populated?600:60,`${name}: expected world tick`);
    assert.deepEqual(frame.players.map(p=>[p.id,p.connected,p.px,p.py]),initial?
      [[0,true,7200,7200]]:
      [[0,true,7350,7200],[1,name!=='disconnected',7232,7372.5]],
    `${name}: lifecycle and positions remain isolated from other fixtures`);
    if(name==='choice') {
      assert.equal(frame.roundId,3);assert.equal(frame.choicePending,true);
      assert.deepEqual(frame.requiredPlayers,[0,1]);
    }
  }
  // Check after every fixture is prepared: later transitions must not alter earlier worlds.
  for(const [name,state]of fixtures)assertFixture(name,JSON.parse(B.baseline(state,1).frame));
  const results=[];
  for(const [name,state,events]of fixtures){
    const rejection=name==='choice'?{reason:2,seq:10,targetWorldTick:42,worldTick:43}:null;
    const old=()=>envelope(JSON.parse(B.baseline(state,1).frame),events,rejection);
    const fresh=()=>envelope(presentation(B.observe(state,1).observation),events,rejection);
    const expected=old(),candidate=fresh();
    assertFixture(name,expected.frame);assertFixture(name,candidate.frame);
    assert.deepEqual(normalize(candidate),normalize(expected),`${name}: typed observation parity`);
    const binary=encode(candidate),json=utf8.encode(JSON.stringify(expected));
    assert.deepEqual(decode(binary),candidate,`${name}: binary roundtrip exact`);
    const transported=await transfer(binary.slice());assert.deepEqual(decode(transported),candidate);
    const compressedJson=await gzip(json),compressedBinary=await gzip(binary);
    assert.deepEqual(await gunzip(compressedBinary),binary);
    assert.deepEqual(JSON.parse(text.decode(await gunzip(compressedJson))),expected);
    const oldTimes=[],newTimes=[],typedJsonTimes=[];
    const stageTimes=Object.fromEntries(['bendJsonAndParse','bendTypedAndPresentation','cloneObjects','transferBytes','jsonEncodeDecode','binaryEncodeDecode'].map(key=>[key,[]]));
    const measureOld=()=>{const t=performance.now();const object=structuredClone(old());const bytes=utf8.encode(JSON.stringify(object));const received=JSON.parse(text.decode(bytes));assert.equal(received.observationSeq,19);return performance.now()-t;};
    const measureNew=()=>{const t=performance.now();const bytes=encode(fresh());const moved=structuredClone(bytes,{transfer:[bytes.buffer]});const received=decode(moved);assert.equal(received.observationSeq,19);return performance.now()-t;};
    const measureTypedJson=()=>{const t=performance.now();const bytes=utf8.encode(JSON.stringify(fresh()));const moved=structuredClone(bytes,{transfer:[bytes.buffer]});const received=JSON.parse(text.decode(moved));assert.equal(received.observationSeq,19);return performance.now()-t;};
    for(let i=0;i<8;i++){measureOld();measureNew();measureTypedJson();}
    for(let i=0;i<samples;i++){
      if(i%2){newTimes.push(measureNew());oldTimes.push(measureOld());}
      else{oldTimes.push(measureOld());newTimes.push(measureNew());}
      typedJsonTimes.push(measureTypedJson());
    }
    for(let i=0;i<samples;i++){
      for(const [name,fn]of [
        ['bendJsonAndParse',old],['bendTypedAndPresentation',fresh],
        ['cloneObjects',()=>structuredClone(expected)],
        ['transferBytes',null],
        ['jsonEncodeDecode',()=>JSON.parse(text.decode(utf8.encode(JSON.stringify(expected))))],
        ['binaryEncodeDecode',()=>decode(encode(candidate))],
      ]){
        // Preallocate the bytes outside this stage: measure ownership transfer alone.
        const bytes=name==='transferBytes'?binary.slice():null;
        const t=performance.now();
        if(bytes)structuredClone(bytes,{transfer:[bytes.buffer]});else fn();
        stageTimes[name].push(performance.now()-t);
      }
    }
    const gzipOld=[],gzipNew=[];
    for(let i=0;i<10;i++){
      const start=performance.now();const raw=await gunzip(await gzip(json));JSON.parse(text.decode(raw));gzipOld.push(performance.now()-start);
      const next=performance.now();decode(await gunzip(await gzip(binary)));gzipNew.push(performance.now()-next);
    }
    const entry={name,sourceBodies:rows(state.bodies).length,visibleBodies:expected.frame.bodies.length,samples,jsonBytes:json.length,binaryBytes:binary.length,jsonGzipBytes:compressedJson.length+4,binaryGzipBytes:compressedBinary.length+4,
      jsonPipeline:stats(oldTimes),binaryPipeline:stats(newTimes),typedJsonTransferPipeline:stats(typedJsonTimes),p50Speedup:+(percentile(oldTimes,.5)/percentile(newTimes,.5)).toFixed(2),
      stages:Object.fromEntries(Object.entries(stageTimes).map(([key,value])=>[key,stats(value)])),jsonGzipRoundtrip:stats(gzipOld),binaryGzipRoundtrip:stats(gzipNew)};
    results.push(entry);console.error(JSON.stringify(entry));
    // Integrity checks do not admit partial observations.
    for(const n of [0,11,binary.length-1])assert.throws(()=>decode(binary.subarray(0,n)));
    const bad=binary.slice();new DataView(bad.buffer).setUint32(4,99,true);assert.throws(()=>decode(bad));
    const trailing=new Uint8Array(binary.length+1);trailing.set(binary);new DataView(trailing.buffer).setUint32(8,trailing.length,true);assert.throws(()=>decode(trailing));
    const badCount=binary.slice();new DataView(badCount.buffer).setUint32(45,0xffffffff,true);assert.throws(()=>decode(badCount));
    const badBool=binary.slice();badBool[20]=2;assert.throws(()=>decode(badBool));
    const badFloat=binary.slice();new DataView(badFloat.buffer).setFloat32(21,Infinity,true);assert.throws(()=>decode(badFloat));
    assert.deepEqual(normalize(fresh()),normalize(old()),`${name}: parity after repeated observations`);
    assertFixture(name,fresh().frame);
  }
  assert.throws(()=>decode(new Uint8Array(MAX_BYTES+1)));
  const report={base:'01b4164612cd6e37d39aa75b16fab2dd253ebb0d',node:process.version,platform:process.platform,arch:process.arch,cpu:cpus()[0].model,samples,
    scope:'Fresh emitted Bend, full visual+prediction frame and representative full delivery envelope. Controlled population fixtures; no browser, Iroh, WASM, or network measurement. Synchronous pipeline excludes gzip; separate gzip measurements reuse prepared bytes.',results};
  const json=JSON.stringify(report,null,2)+'\n';
  if(process.env.RESULTS)await writeFile(process.env.RESULTS,json);else process.stdout.write(json);
}finally{await rm(scratch,{recursive:true,force:true});}
