import { readFileSync, writeFileSync } from 'node:fs';
import { root, contract, workloadSHA, hash, atomic, command, evaluate, newDirectory, remaining, verifyProtected } from './shared.mjs';
const directory = newDirectory('candidate');
const receiptURL = new URL('receipt.json', directory);
const receipt = { status: 'running', startedAt: new Date().toISOString(), workload: contract, workloadSHA, directory: directory.href };
let failure;
try {
  verifyProtected(); remaining();
  const emitted = new URL('../../../examples/survivors/dist/bot-actions.mjs', import.meta.url);
  command([process.env.BEND || 'bend', 'examples/survivors/bot-actions.bend', '-o', emitted.pathname], 60, new URL('compile.log', directory));
  const bundle = new URL('candidate.mjs', directory), bytes = readFileSync(emitted);
  writeFileSync(bundle, bytes); receipt.bundleURL = bundle.href; receipt.bundleSHA = hash(bytes);
  const evaluation = await evaluate(bundle);
  receipt.evaluation = evaluation; receipt.status = 'complete';
} catch (error) { receipt.status = 'failed'; receipt.error = error.message; failure = error; }
finally {
  try { verifyProtected(); } catch (error) { receipt.status = 'failed'; receipt.error = error.message; failure = error; }
  receipt.finishedAt = new Date().toISOString(); atomic(receiptURL, receipt); atomic(new URL('latest-candidate.json', root), { receiptURL: receiptURL.href });
}
console.log('ARTIFACT candidate_receipt=' + receiptURL.pathname.slice(new URL('../../../', import.meta.url).pathname.length));
if (failure) { console.error(failure.message); process.exitCode = 1; }
else console.log('METRIC batch_seconds=' + receipt.evaluation.batchSeconds.toFixed(6));
