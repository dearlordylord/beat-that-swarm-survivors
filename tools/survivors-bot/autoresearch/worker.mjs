import { parentPort, workerData } from 'node:worker_threads';
import { createHash } from 'node:crypto';
import { runBot } from '../runner.mjs';
const { default: Game } = await import(workerData.bundleURL);
if (typeof Game.observed_packet !== 'function' || typeof Game.fresh_start_seed !== 'function') throw new Error('Current seeded observation facade required');
parentPort.on('message', async job => {
  const started = performance.now();
  let chain = Buffer.alloc(32), observations = 0;
  const observed = packet => {
    const result = Game.observed_packet(packet);
    const digest = createHash('sha256').update(chain);
    for (const key of ['frame', 'actions', 'mechanics']) {
      if (typeof result[key] !== 'string') throw new Error('Invalid trace observation');
      const bytes = Buffer.from(result[key]);
      const size = Buffer.alloc(4); size.writeUInt32BE(bytes.length);
      digest.update(size).update(bytes);
    }
    chain = digest.digest(); observations++;
    return result;
  };
  try {
    const summary = await runBot({ ...Game, observed_packet: observed }, { mode: 'heuristic', profile: job.profile, seed: job.seed, ticks: job.ticks, decisions: 'both', maxUpgradeRequests: 0, maxGoalRequests: 0, runId: job.runId, emit: () => {} });
    if (Object.values(summary.classifierAttempts).some(n => n !== 0) || observations < 1) throw new Error('Offline trace invariant');
    parentPort.postMessage({ index: job.index, seed: job.seed, profile: job.profile, status: 'completed', elapsedMs: performance.now() - started, summary, trace: { sha256: chain.toString('hex'), observations } });
  } catch {
    parentPort.postMessage({ index: job.index, seed: job.seed, profile: job.profile, status: 'exception', elapsedMs: performance.now() - started });
  }
});
