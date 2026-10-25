#!/usr/bin/env node
// Freeze new public-input actions against the current source. Historical trace
// upgrade timing is not valid after subsequent gameplay changes.
import assert from 'node:assert/strict';
import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const [commonPath,gamePath,sourcePath,output,targetText='1200',stationary='false']=process.argv.slice(2);
const [{default:C},{default:G}]=await Promise.all([import(pathToFileURL(resolve(commonPath))),import(pathToFileURL(resolve(gamePath)))]);
const words=readFileSync(sourcePath,'utf8').trim().split(/\s+/).map(Number);
const [,,profile,seed]=words;
const moves=[];
for(let i=9;i<words.length;) {
  const opcode=words[i++],tick=words[i++]; i++;
  if(opcode===0) moves.push([tick,words[i++],words[i++]]);
  else {assert.equal(opcode,1);i++;}
}
const decode=word=>new Float32Array(new Uint32Array([word]).buffer)[0];
const target=Number(targetText),actions=[];
let packet=C.start(profile,seed),move=0;
while(packet.$==='Packet' && packet.state.run.tick<target && actions.length<target*2) {
  const {run}=packet.state;
  if(run.phase===0) {
    while(move+1<moves.length && moves[move+1][0]<=run.tick) move++;
    const [,x,y]=stationary==='true'?[0,0,0]:moves[move];
    actions.push(`0 ${run.tick} 0 ${x} ${y}`);
    packet=G.advance_quiet(packet.state,decode(x),decode(y));
  } else if(run.phase===1 || run.phase===2) {
    actions.push(`1 ${run.tick} ${run.phase} 0`);
    packet=G.choose(packet.state,0);
  } else break;
}
assert.equal(packet.$,'Packet');
const {run}=packet.state;
writeFileSync(output,`1313231410 1 ${profile} ${seed} 0 ${target} ${run.tick} ${run.phase} ${actions.length}\n${actions.join('\n')}\n`);
console.log(JSON.stringify({status:'passed',profile,seed,tick:run.tick,phase:run.phase,actions:actions.length}));
