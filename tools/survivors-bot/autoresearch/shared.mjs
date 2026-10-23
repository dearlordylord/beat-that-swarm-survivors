import { spawnSync } from 'node:child_process';
import { createHash, randomUUID } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync, renameSync, openSync, closeSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { makeJobs, runPool } from '../batch.mjs';
export const repo = fileURLToPath(new URL('../../../', import.meta.url));
export const root = new URL('../../../examples/survivors/dist/autoresearch/', import.meta.url);
export const reference = new URL('../../../examples/survivors/dist/autoresearch-reference/reference.mjs', import.meta.url);
export const contract = Object.freeze({ count: 10, ticks: 1200, workers: 2, seed: 100, profile: 'fresh' });
export const workloadSHA = hash(JSON.stringify(contract));
export const deadline = Math.min(Date.parse('2026-10-23T00:38:25Z'), Date.now() + 465000);
export function hash(value) { return createHash('sha256').update(value).digest('hex'); }
export function remaining(maxSeconds = 480) {
  const left = Math.floor((deadline - Date.now()) / 1000);
  if (left < 1) throw new Error('Experiment deadline reached');
  return Math.min(maxSeconds, left);
}
export function atomic(url, data) {
  const temporary = new URL(url.href + '.' + randomUUID() + '.tmp');
  writeFileSync(temporary, JSON.stringify(data, null, 2)); renameSync(temporary, url);
}
export function command(args, seconds, logURL) {
  const fd = openSync(logURL, 'w');
  let result;
  try { result = spawnSync(process.execPath, ['examples/run-bounded.mjs', String(remaining(seconds)), ...args], { cwd: repo, env: process.env, stdio: ['ignore', fd, fd], timeout: (remaining(seconds) + 3) * 1000, killSignal: 'SIGKILL' }); }
  finally { closeSync(fd); }
  if (result.error || result.status !== 0) throw new Error('Bounded command failed; see ' + fileURLToPath(logURL));
}
export async function evaluate(bundleURL, seconds = 420) {
  const jobs = makeJobs(contract, 'fixed-semantic-workload');
  const started = performance.now();
  const result = await runPool(jobs, { ...contract, wallSeconds: remaining(seconds), bundleURL: bundleURL.href, workerURL: new URL('./worker.mjs', import.meta.url) });
  const batchSeconds = (performance.now() - started) / 1000;
  if (result.status !== 'complete' || result.completed !== contract.count) throw new Error('Incomplete evaluation: ' + JSON.stringify({ ...result, results: undefined }));
  return { batchSeconds, records: result.results.sort((a, b) => a.index - b.index), bundleSHA: hash(readFileSync(bundleURL)), workloadSHA };
}
export function semantic(records) {
  const strip = value => {
    if (Array.isArray(value)) return value.map(strip);
    if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).filter(([key]) => !['wallMs', 'classifierWaitMs', 'runId', 'elapsedMs'].includes(key)).map(([key, child]) => [key, strip(child)]));
    return value;
  };
  return strip(records);
}
export function newDirectory(prefix) {
  mkdirSync(root, { recursive: true });
  const directory = new URL(`${prefix}-${Date.now()}-${randomUUID()}/`, root);
  mkdirSync(directory); return directory;
}

export function verifyProtected() {
  const inventory = JSON.parse(readFileSync(new URL('./protected-inputs.json', import.meta.url), 'utf8'));
  const entries = inventory.paths ?? inventory.files ?? inventory.hashes;
  if (!entries || typeof entries !== 'object' || !/^[0-9a-f]{64}$/.test(inventory.referenceBundleSHA)) throw new Error('Invalid protected input inventory');
  for (const [path, expected] of Object.entries(entries)) {
    if (typeof path !== 'string' || path.startsWith('/') || path.split('/').includes('..') || !/^[0-9a-f]{64}$/.test(expected)) throw new Error('Invalid protected path');
    const actual = hash(readFileSync(new URL(path, new URL('../../../', import.meta.url))));
    if (actual !== expected) throw new Error('Protected input drift: ' + path);
  }
  if (hash(readFileSync(reference)) !== inventory.referenceBundleSHA) throw new Error('Protected reference bundle drift');
  return inventory;
}
