import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdtemp, readFile, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const runner = fileURLToPath(new URL('./run-bounded.mjs', import.meta.url));
const fixture = await mkdtemp(path.join(tmpdir(), 'bendvy-bounded-'));
const active = new Set();
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
function run(seconds, command, args) {
  const child = spawn(process.execPath, [runner, String(seconds), command, ...args], { stdio: ['ignore', 'pipe', 'pipe'] });
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
  console.log('BOUNDED RUNNER PASS: success, exit status, missing command, timeout descendant cleanup, signal descendant cleanup');
} finally {
  for (const child of active) child.kill('SIGTERM');
  await Promise.allSettled([...active].map(child => child.done));
  await rm(fixture, { recursive: true, force: true });
}
