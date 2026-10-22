import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,writeFile,readFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {spawn} from 'node:child_process';
// Process-lifecycle fixtures only: these executable stubs are not game runs.
async function runStub(body){
 const directory=await mkdtemp(join(tmpdir(),'visible-process-'));
 try{
  const binary=join(directory,'stub');await writeFile(binary,'#!/usr/bin/env node\n'+body,{mode:0o700});
  const child=spawn(process.execPath,['tools/survivors-bot/visible.mjs','--mode','heuristic','--seconds','1','--binary',binary,'--receipts-dir',join(directory,'receipts')],{cwd:resolve('.'),stdio:['ignore','pipe','pipe']});
  let stdout='',stderr='';child.stdout.on('data',x=>stdout+=x);child.stderr.on('data',x=>stderr+=x);
  const timer=setTimeout(()=>child.kill('SIGKILL'),6000);
  const code=await new Promise((r,j)=>{child.on('error',j);child.on('exit',r)});clearTimeout(timer);
  const path=stdout.match(/^Visible bot receipt: (.+)$/m)?.[1];assert.ok(path,stderr);
  const records=(await readFile(path,'utf8')).trim().split('\n').map(JSON.parse);
  return {code,records};
 }finally{await rm(directory,{recursive:true,force:true});}
}
test('wall deadline remains wall-limit after deliberate native termination',async()=>{
 const {code,records}=await runStub('setInterval(()=>{},1000);');
 assert.equal(code,0);const end=records.at(-1);assert.equal(end.outcome,'wall-limit');assert.equal(end.nativeExit.expected,true);assert.equal(end.nativeExit.signal,'SIGTERM');
});
test('controller errors terminate and reap native process on error path',async()=>{
 const {code,records}=await runStub("const fs=require('node:fs');fs.writeFileSync(process.env.NIGHTFALL_BOT_SESSION+'/observation.json',JSON.stringify({sequence:1,frame:{tick:0},actions:[]}));setInterval(()=>{},1000);");
 assert.equal(code,1);const end=records.at(-1);assert.equal(end.outcome,'controller-error');assert.equal(end.nativeExit.expected,true);assert.ok(end.nativeExit.signal);
});

test('unexpected native signal marks the session failed',async()=>{
 const {code,records}=await runStub("process.kill(process.pid,'SIGTERM');");
 assert.equal(code,1);const end=records.at(-1);assert.equal(end.outcome,'native-error');assert.equal(end.nativeExit.expected,false);assert.equal(end.nativeExit.signal,'SIGTERM');
});
