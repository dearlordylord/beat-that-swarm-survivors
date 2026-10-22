import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { validateOptions, makeJobs, runPool } from './batch.mjs';
const worker = source => new URL('data:text/javascript,' + encodeURIComponent(`import {parentPort} from 'node:worker_threads'; ${source}`));
test('batch validates bounded options and unique wrapped U32 seeds', () => {
  const options = validateOptions({ seed: 4294967290, count: 1000, profile: 'both' }, 2);
  const jobs = makeJobs(options, 'test');
  assert.equal(new Set(jobs.map(j => j.seed)).size, 1000);
  assert.equal(jobs[6].seed, 0);
  assert.deepEqual(jobs.slice(0, 2).map(j => j.profile), ['fresh', 'advanced']);
  for (const bad of [{ workers: 3 }, { workers: 9 }, { count: 10001 }, { count: 0 }, { seed: -1 }, { ticks: 37001 }, { wallSeconds: 86401 }, { profile: 'jev' }]) assert.throws(() => validateOptions(bad, 2));
});
test('batch pool queues all jobs and persists exactly one result per job', async () => {
  const jobs = makeJobs(validateOptions({ count: 5 }, 2), 'test'), received = [];
  const result = await runPool(jobs, { workers: 2, wallSeconds: 5, bundleURL: '', workerURL: worker("parentPort.on('message',j=>parentPort.postMessage({...j,status:'completed'}));"), onResult: r => received.push(r) });
  assert.equal(result.status, 'complete'); assert.equal(result.completed, 5); assert.equal(result.unstarted, 0);
  assert.equal(new Set(received.map(r => r.index)).size, 5);
});
test('wall budget reports running timeouts and unstarted jobs separately', async () => {
  const result = await runPool(makeJobs(validateOptions({ count: 3 }, 1), 'test'), { workers: 1, wallSeconds: 0.15, bundleURL: '', workerURL: worker("parentPort.on('message',()=>{});") });
  assert.equal(result.status, 'wall-budget'); assert.equal(result.completed, 0); assert.equal(result.timedOut, 1); assert.equal(result.unstarted, 2);
});
test('worker exceptions remain failures rather than completed simulations', async () => {
  const result = await runPool(makeJobs(validateOptions({ count: 2 }, 1), 'test'), { workers: 1, wallSeconds: 5, bundleURL: '', workerURL: worker("parentPort.on('message',()=>{throw new Error('fixture');});") });
  assert.equal(result.status, 'completed-with-errors'); assert.equal(result.failed, 2); assert.equal(result.completed, 0);
});
test('abort terminates active workers and records incomplete batch', async () => {
  const controller = new AbortController(); controller.abort();
  const result = await runPool(makeJobs(validateOptions({ count: 2 }, 1), 'test'), { workers: 1, wallSeconds: 5, signal: controller.signal, bundleURL: '' });
  assert.equal(result.status, 'interrupted'); assert.equal(result.started, 0); assert.equal(result.unstarted, 2);
});
test('batch paths never load classifier provider', () => {
  for (const file of ['batch.mjs', 'batch-worker.mjs', 'batch.sh']) assert.doesNotMatch(readFileSync(new URL(file, import.meta.url), 'utf8'), /import\s*\([^)]*provider|from\s*['"][^'"]*provider|classifyDecision/);
});
