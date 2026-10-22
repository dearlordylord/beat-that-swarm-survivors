import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import assert from 'node:assert/strict';
import { root, reference, workloadSHA, hash, atomic, command, evaluate, semantic, newDirectory, remaining, verifyProtected } from './shared.mjs';
const directory = newDirectory('checks'), receipt = { status: 'running', startedAt: new Date().toISOString() };
let failure;
try {
  const inventory = verifyProtected(); remaining();
  const latest = JSON.parse(readFileSync(new URL('latest-candidate.json', root), 'utf8'));
  const candidate = JSON.parse(readFileSync(new URL(latest.receiptURL), 'utf8'));
  assert.equal(candidate.status, 'complete'); assert.equal(candidate.workloadSHA, workloadSHA);
  assert.equal(hash(readFileSync(new URL(candidate.bundleURL))), candidate.bundleSHA);
  const referenceSHA = hash(readFileSync(reference));
  assert.equal(referenceSHA, inventory.referenceBundleSHA);
  const cacheURL = new URL(`oracle-${referenceSHA}-${workloadSHA}.json`, root);
  let oracle;
  if (existsSync(cacheURL)) {
    oracle = JSON.parse(readFileSync(cacheURL, 'utf8'));
    assert.equal(oracle.referenceSHA, referenceSHA); assert.equal(oracle.workloadSHA, workloadSHA);
    assert.equal(oracle.semanticSHA, hash(JSON.stringify(oracle.records)));
  } else {
    const evaluated = await evaluate(reference);
    oracle = { referenceSHA, workloadSHA, records: semantic(evaluated.records) };
    oracle.semanticSHA = hash(JSON.stringify(oracle.records)); atomic(cacheURL, oracle);
  }
  assert.deepEqual(semantic(candidate.evaluation.records), oracle.records, 'Full observation trace and deterministic summary must match frozen reference');
  receipt.referenceSHA = referenceSHA; receipt.candidateSHA = candidate.bundleSHA; receipt.semanticSHA = oracle.semanticSHA;
  // Fixture files import the conventional candidate path; restore exact measured bytes.
  writeFileSync(new URL('../../../examples/survivors/dist/bot-actions.mjs', import.meta.url), readFileSync(new URL(candidate.bundleURL)));
  command([process.execPath, '--test', ...['provider', 'context', 'runner', 'visible-controller', 'visible-process', 'planner', 'batch', 'seed-cli'].map(name => `tools/survivors-bot/${name}.test.mjs`)], 60, new URL('offline-tests.log', directory));
  command([process.execPath, 'tools/survivors-bot/actions.test.mjs'], 60, new URL('actions.log', directory));
  command([process.execPath, 'tools/survivors-bot/integration.test.mjs'], 60, new URL('integration.log', directory));
  receipt.status = 'passed';
} catch (error) { receipt.status = 'failed'; receipt.error = error.message; failure = error; }
finally { try { verifyProtected(); } catch (error) { receipt.status = 'failed'; receipt.error = error.message; failure = error; } receipt.finishedAt = new Date().toISOString(); atomic(new URL('receipt.json', directory), receipt); }
console.log('ARTIFACT checks_receipt=' + new URL('receipt.json', directory).pathname.slice(new URL('../../../', import.meta.url).pathname.length));
if (failure) { console.error(failure.message); process.exitCode = 1; }
else console.log('CHECKS passed: frozen-reference full traces, deterministic summaries and offline regression suite');
