import test from 'node:test';
import assert from 'node:assert/strict';
import { freshProfile, loadProfile, saveProfile, upgradeCost, buyUpgrade, purchaseStatus, unlock, recordRun, metaCode, allowedWeapons, isUnlocked, toBend, fromBend, observeRun, validateSetup } from '../progression.mjs';
import { CHARACTERS, STAGES, META_UPGRADES } from '../content.mjs';
let saved = null;
globalThis.localStorage = { getItem: () => saved, setItem: (key, value) => { saved = value; } };

test('generic transport round-trips JSON values including floating-point extremes', () => {
  const extremes = [0, -0, 1, -1, .35, 9.899999999999999, 16777217, 4294967297, Number.MAX_SAFE_INTEGER, Number.MAX_VALUE, Number.MIN_VALUE, 1e-300, -1e100];
  let seed = 123456789;
  for (let i = 0; i < 500; i++) {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    const value = { index: i, text: `value ${seed} 🗡`, flag: i % 2 === 0, nested: [null, extremes[i % extremes.length], { x: seed / 37 }] };
    assert.deepEqual(fromBend(toBend(value)), JSON.parse(JSON.stringify(value)));
  }
  assert.equal(fromBend(toBend(NaN)), null);
  assert.equal(fromBend(toBend(Infinity)), null);
  assert.throws(() => toBend(() => {}), TypeError);
});

test('Bend normalization preserves valid saves, fractional survival and high counters', () => {
  saved = null;
  const profile = freshProfile();
  profile.gold = 16777217;
  profile.stats.kills = 4294967297;
  profile.stats.survive = 9.899999999999999;
  profile.settings.volume = .35;
  saveProfile(profile);
  assert.deepEqual(loadProfile(), profile);
  for (let i = 0; i < 4; i++) { const normalized = loadProfile(); saveProfile(normalized); assert.deepEqual(loadProfile(), normalized); }
  profile.stats.survive = Number.MIN_VALUE;
  saveProfile(profile);
  assert.deepEqual(loadProfile(), profile);
  saved = JSON.stringify({ version: 1, gold: '12.8', meta: [-1, 999], characters: [0, 1, 1, 999], stages: null, stats: { kills: -2, survive: '3.25' }, collection: null });
  const normalized = loadProfile();
  assert.equal(normalized.gold, 12);
  assert.equal(normalized.stats.kills, 0);
  assert.equal(normalized.stats.survive, 3.25);
  assert.deepEqual(normalized.characters, [0, 1]);
  assert.deepEqual(normalized.stages, [0]);
  assert.deepEqual(normalized.meta.slice(0, 2), [0, META_UPGRADES[1].maxLevel]);
  saved = '{broken'; assert.deepEqual(loadProfile(), freshProfile());
});

test('Bend rejects ineligible, unaffordable and repeated purchases without spending', () => {
  const profile = freshProfile(); profile.gold = 300;
  assert.equal(unlock(profile, 'character', 1), false);
  assert.equal(profile.gold, 300);
  profile.stats.kills = 100;
  assert.deepEqual(purchaseStatus(profile, 'character', 1), { owned: false, eligible: true, affordable: true, canBuy: true, missingGold: 0, cost: 250 });
  assert.equal(unlock(profile, 'character', 1), true);
  assert.equal(profile.gold, 50); assert.ok(profile.characters.includes(1));
  assert.equal(unlock(profile, 'character', 1), false); assert.equal(profile.gold, 50);
  assert.equal(unlock(profile, 'character', 7), false); assert.equal(profile.gold, 50);
  assert.deepEqual(loadProfile(), profile);
  const setup = validateSetup(profile, { character: 7, stage: 4, arcana: 99, mode: 99 });
  assert.deepEqual(setup, { character: 0, stage: 0, arcana: 0, mode: 0 });
  assert.equal(isUnlocked(profile, 'arcana', 0), true); assert.equal(isUnlocked(profile, 'arcana', 99), false);
});

test('all catalog upgrade ranks use exact Bend prices and bit packing', () => {
  const profile = freshProfile(); profile.gold = 1000000;
  for (const upgrade of META_UPGRADES) {
    for (let rank = 0; rank < upgrade.maxLevel; rank++) {
      const cost = Math.floor(upgrade.costBase * (1 + rank * .75));
      assert.equal(upgradeCost(profile, upgrade.id), cost);
      const before = profile.gold;
      assert.equal(buyUpgrade(profile, upgrade.id), true);
      assert.equal(profile.gold, before - cost);
    }
    assert.equal(buyUpgrade(profile, upgrade.id), false);
  }
  const code = metaCode(profile);
  for (const upgrade of META_UPGRADES) assert.equal(Math.floor(code / 2 ** (upgrade.id * 3)) % 8, upgrade.maxLevel);
});

test('Bend retains weapon history and records each run once', () => {
  const profile = freshProfile();
  let history = observeRun({}, { weapons: [1, 0, 9] });
  history = observeRun(history, { weapons: [0, 1, 0] });
  assert.deepEqual(history, { usedWeapons: [0, 2, 1], evolvedWeapons: [2] });
  const frame = { runId: 'progression-contract', character: 0, stage: 0, phase: 4, tick: 36000, kills: 1000, gold: 1000, level: 50, revivalsUsed: 1, bossesKilled: 2, relicCollected: 1, weapons: [0, 1, 0], ...history, enemiesKilled: [0, 1, 20] };
  const added = recordRun(profile, frame);
  assert.deepEqual(added, ['firstblood', 'hunter', 'purse', 'minute', 'five', 'dawn', 'evolve', 'level20', 'level50', 'rebirth']);
  assert.equal(profile.gold, 1000); assert.equal(profile.stats.survive, 600); assert.equal(profile.stats.evolutions, 1);
  assert.deepEqual(profile.collection.weapons, [0, 2, 1]); assert.deepEqual(profile.collection.evolutions, [2]);
  assert.ok(allowedWeapons(profile) & (1 << 12));
  const snapshot = structuredClone(profile);
  assert.deepEqual(recordRun(profile, frame), []); assert.deepEqual(profile, snapshot);
});
