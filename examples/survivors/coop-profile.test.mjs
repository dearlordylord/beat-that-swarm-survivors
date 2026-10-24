import assert from 'node:assert/strict';
import test from 'node:test';
import { freshProfile, loadProfile } from './progression.mjs';
import { CoopRunProgress } from './coop-ui.mjs';

const terminal = {
  runId: 'shared-match', ownPlayerId: 1, phase: 4, character: 0, stage: 0,
  tick: 36000, kills: 100, gold: 275, level: 20, weapons: [1], bossesKilled: 1,
};

test('co-op receipt preserves observed evolutions and saves an authoritative terminal result once', () => {
  const storage = new Map();
  globalThis.localStorage = { getItem: key => storage.get(key) ?? null, setItem: (key, value) => storage.set(key, value) };
  const profile = freshProfile(), progress = new CoopRunProgress(profile);
  assert.equal(progress.observe({ ...terminal, phase: 0, hp: 0, weapons: [9] }), null);
  assert.equal(profile.gold, 0, 'A fallen character does not settle a continuing shared match');
  const receipt = progress.observe(terminal);
  assert.equal(receipt.receipt, 'shared-match:1');
  assert.equal(profile.gold, 275);
  assert.equal(profile.stats.wins, 1);
  assert.deepEqual(profile.collection.evolutions, [0], 'Earlier evolved weapon survives replacement in final equipment');
  assert.ok(receipt.added.includes('firstblood'));
  progress.observe(terminal);
  assert.equal(profile.gold, 275);
  const reloaded = loadProfile();
  new CoopRunProgress(reloaded).observe(terminal);
  assert.equal(reloaded.gold, 275, 'Bend receipt deduplication survives a new UI adapter/profile load');
  assert.equal(reloaded.stats.wins, 1);
});

test('no missing or speculative receipt is banked', () => {
  const profile = freshProfile(), progress = new CoopRunProgress(profile);
  assert.equal(progress.observe({ ...terminal, runId: undefined }), null);
  assert.equal(progress.observe({ ...terminal, ownPlayerId: undefined }), null);
  assert.equal(profile.gold, 0);
});

test('aborted phase never banks accumulated gold or a win, and cannot undo a completed receipt', () => {
  const profile = freshProfile(), progress = new CoopRunProgress(profile);
  assert.equal(progress.observe({ ...terminal, phase: 5 }), null);
  assert.equal(profile.gold, 0);
  assert.equal(profile.stats.wins, 0);
  assert.deepEqual(profile.recorded, []);
  progress.observe({ ...terminal, runId: 'completed-before-disconnect' });
  assert.equal(profile.gold, 275);
  assert.equal(profile.stats.wins, 1);
  assert.equal(progress.observe({ ...terminal, runId: 'completed-before-disconnect', phase: 5 }), null);
  assert.equal(profile.gold, 275);
  assert.equal(profile.stats.wins, 1);
});
