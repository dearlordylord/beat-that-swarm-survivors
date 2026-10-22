import assert from "node:assert/strict";
const storage = new Map();
globalThis.localStorage = {
  getItem: (k) => storage.get(k) ?? null,
  setItem: (k, v) => storage.set(k, v),
};
const {
  loadProfile,
  saveProfile,
  buyUpgrade,
  upgradeCost,
  metaCode,
  unlock,
  recordRun,
} = await import("./progression.mjs");
const p = loadProfile();
assert.equal(p.gold, 0);
assert.equal(buyUpgrade(p, 0), false);
p.gold = 100000;
const cost = upgradeCost(p, 0);
assert.equal(buyUpgrade(p, 0), true);
assert.equal(p.gold, 100000 - cost);
assert.equal(metaCode(p), 1);
for (let i = 0; i < 10; i++) buyUpgrade(p, 0);
assert.equal(p.meta[0], 5);
assert.equal(buyUpgrade(p, 0), false);
assert.equal(unlock(p, "character", 1), false);
p.stats.kills = 100;
assert.equal(unlock(p, "character", 1), true);
assert.equal(unlock(p, "character", 1), false);
assert.equal(unlock(p, "stage", 99), false);
const f = {
  runId: "first",
  phase: 4,
  character: 1,
  stage: 0,
  tick: 36000,
  kills: 100,
  gold: 250,
  level: 20,
  weapons: [9, 2],
  bossesKilled: 5,
};
const gold = p.gold;
recordRun(p, f);
assert.equal(p.gold, gold + 250);
recordRun(p, f);
assert.equal(p.gold, gold + 250);
recordRun(p, { ...f, runId: "second" });
assert.equal(p.gold, gold + 500);
assert.equal(p.stats.wins, 2);
assert.deepEqual(p.collection.evolutions, [0]);
saveProfile(p);
const q = loadProfile();
assert.equal(q.gold, p.gold);
assert.deepEqual(q.meta, p.meta);
storage.set(
  "nightfall-survivors-v1",
  JSON.stringify({
    version: 1,
    gold: -5,
    meta: [99],
    collection: { weapons: null },
    stats: { kills: "bad" },
  }),
);
const bad = loadProfile();
assert.equal(bad.gold, 0);
assert.equal(bad.meta[0], 5);
assert.equal(bad.stats.kills, 0);
recordRun(bad, { ...f, runId: "third" });
console.log(
  "Profile purchases, caps, run awards, deduplication and corrupted-save recovery pass.",
);
