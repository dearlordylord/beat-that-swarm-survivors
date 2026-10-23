import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdtemp, readFile, rm, stat, mkdir, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const runner = fileURLToPath(new URL('./run-bounded.mjs', import.meta.url));
const fixture = await mkdtemp(path.join(tmpdir(), 'bendvy-bounded-'));
const active = new Set();
const fixturePids = new Set();
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
function run(seconds, command, args, env = process.env) {
  const child = spawn(process.execPath, [runner, String(seconds), command, ...args], { stdio: ['ignore', 'pipe', 'pipe'], env });
  active.add(child);
  let output = '';
  child.stdout.on('data', data => output += data);
  child.stderr.on('data', data => output += data);
  child.done = new Promise((resolve, reject) => {
    child.once('error', reject);
    child.once('close', code => { active.delete(child); resolve({ code, output }); });
  });
  return child;
}
async function ready(file) {
  for (let i = 0; i < 200; i++) {
    try { if ((await readFile(file, 'utf8')).length > 0) return; } catch (error) { if (error.code !== 'ENOENT') throw error; }
    await delay(10);
  }
  throw Error('Descendant fixture did not become ready.');
}
function tree(file) {
  const heartbeat = `const fs=require('node:fs');setInterval(()=>fs.appendFileSync(${JSON.stringify(file)},'.'),20);`;
  return ['-e', `require('node:child_process').spawn(process.execPath,['-e',${JSON.stringify(heartbeat)}],{stdio:'ignore'});setInterval(()=>{},1000);`];
}
async function stopped(file) {
  await delay(100);
  const size = (await stat(file)).size;
  await delay(120);
  assert.equal((await stat(file)).size, size, 'Descendant heartbeat continued after runner termination.');
}
function detachedTree(file) {
  const heartbeat = `const fs=require('node:fs');fs.writeFileSync(${JSON.stringify(file+'.pid')},String(process.pid));process.on('SIGTERM',()=>{});process.on('SIGINT',()=>{});setInterval(()=>fs.appendFileSync(${JSON.stringify(file)},'.'),10);`;
  const parent = `require('node:fs').writeFileSync(${JSON.stringify(file+'.parent.pid')},String(process.pid));require('node:child_process').spawn(process.execPath,['-e',${JSON.stringify(heartbeat)}],{stdio:'ignore',detached:true}).unref();process.on('SIGTERM',()=>process.exit(0));process.on('SIGINT',()=>process.exit(0));setInterval(()=>{},1000);`;
  return [runner,'30',process.execPath,'-e',parent];
}
async function detachedReady(file) {
  await ready(file);const pid=Number(await readFile(file+'.pid','utf8'));fixturePids.add(pid);fixturePids.add(Number(await readFile(file+'.parent.pid','utf8')));return pid;
}
async function assertNotRunning(pid) {
  // A dead orphan can remain as a zombie until the host init process reaps it.
  const {spawnSync}=await import('node:child_process');
  const state=spawnSync('ps',['-o','stat=','-p',String(pid)],{encoding:'utf8'}).stdout.trim();
  assert.ok(!state || state.startsWith('Z'), `Owned descendant ${pid} is still running: ${state}`);
}
try {
  assert.equal((await run(3, process.execPath, ['-e', 'process.exit(0)']).done).code, 0);
  assert.equal((await run(3, process.execPath, ['-e', 'process.exit(23)']).done).code, 23);
  assert.equal((await run(3, path.join(fixture, 'missing-command'), []).done).code, 1);
  const timeoutFile = path.join(fixture, 'timeout-heartbeat');
  const timeout = run(1, process.execPath, tree(timeoutFile));
  await ready(timeoutFile);
  assert.equal((await timeout.done).code, 124);
  await stopped(timeoutFile);
  const signalFile = path.join(fixture, 'signal-heartbeat');
  const signal = run(5, process.execPath, tree(signalFile));
  await ready(signalFile);
  signal.kill('SIGTERM');
  assert.equal((await signal.done).code, 143);
  await stopped(signalFile);
  if(process.platform!=='win32') {
    const unrelatedFile=path.join(fixture,'unrelated-heartbeat');
    const unrelated=spawn(process.execPath,['-e',`const fs=require('node:fs');setInterval(()=>fs.appendFileSync(${JSON.stringify(unrelatedFile)},'.'),10);`],{stdio:'ignore'});
    await ready(unrelatedFile);
    fixturePids.add(unrelated.pid);
    for(const signal of [null,'SIGTERM','SIGINT']) {
      const file=path.join(fixture,'nested-'+(signal??'timeout'));
      const wrapper=run(signal?10:0.6,process.execPath,detachedTree(file));
      const pid=await detachedReady(file);
      if(signal)wrapper.kill(signal);
      assert.equal((await wrapper.done).code,signal==='SIGTERM'?143:signal==='SIGINT'?130:124);
      await assertNotRunning(pid);await assertNotRunning(Number(await readFile(file+'.parent.pid','utf8')));await stopped(file);
      process.kill(unrelated.pid,0);
      const priorSize=(await stat(unrelatedFile)).size;await delay(40);
      assert.ok((await stat(unrelatedFile)).size>priorSize,'Unrelated process must remain running, not frozen');
    }
    const shim=path.join(fixture,'ps-shim');await mkdir(shim);
    const scanCount=path.join(fixture,'ps-scan-count');
    await writeFile(path.join(shim,'ps'),`#!/usr/bin/env node
const fs=require('node:fs');if(fs.existsSync(${JSON.stringify(scanCount)}))process.exit(1);fs.writeFileSync(${JSON.stringify(scanCount)},'1');process.exit(require('node:child_process').spawnSync('/bin/ps',process.argv.slice(2),{stdio:'inherit'}).status??1);
`,{mode:0o700});
    const failureFile=path.join(fixture,'snapshot-failure-heartbeat');
    const failure=run(0.6,process.execPath,detachedTree(failureFile),{...process.env,PATH:shim+path.delimiter+process.env.PATH});
    const failurePid=await detachedReady(failureFile);
    assert.equal((await failure.done).code,124);await assertNotRunning(failurePid);await stopped(failureFile);
    unrelated.kill('SIGKILL');
  }
  console.log('BOUNDED RUNNER PASS: success, exit status, missing command, timeout/signal cleanup, nested detached TERM-resistant descendants, unrelated process remains running');
} finally {
  for (const pid of fixturePids) {try{process.kill(pid,'SIGKILL')}catch(error){if(error.code!=='ESRCH')throw error}}
  for (const child of active) child.kill('SIGTERM');
  await Promise.allSettled([...active].map(child => child.done));
  await rm(fixture, { recursive: true, force: true });
}
