// Input-only objective integration. Opaque Bend State is consumed, never edited.
import assert from "node:assert/strict";
import { stat } from "node:fs/promises";
import { performance } from "node:perf_hooks";
import { STAGE_RELICS } from "./content.mjs";
import {
  allowedWeapons,
  loadProfile,
  metaCode,
  recordRun,
} from "./progression.mjs";

const artifact = await stat(new URL("./dist/game.mjs", import.meta.url));
for (const source of ["game.bend", "projectile.bend", "encounters.bend"]) {
  assert.ok(
    artifact.mtimeMs >= (await stat(new URL(source, import.meta.url))).mtimeMs,
    `Rebuild dist/game.mjs after changing ${source}`,
  );
}
const { default: Game } = await import("./dist/game.mjs");
for (const name of [
  "start",
  "configure",
  "configure_unlocks",
  "set_mode",
  "advance",
  "choose",
])
  assert.equal(typeof Game[name], "function", `Missing public API ${name}`);

const storage = new Map();
const previousStorage = globalThis.localStorage;
globalThis.localStorage = {
  getItem: (key) => storage.get(key) ?? null,
  setItem: (key, value) => storage.set(key, String(value)),
  removeItem: (key) => storage.delete(key),
};
const started = performance.now();
const deadline = started + 28_000;
let current;
function accept(packet) {
  assert.equal(packet.$, "Packet", packet.error || "Expected owned packet");
  const frame = JSON.parse(packet.frame);
  assert.ok(Number.isFinite(frame.px) && Number.isFinite(frame.py));
  assert.ok(frame.hp >= 0 && frame.hp <= frame.maxHp);
  assert.ok(frame.relicCollected === 0 || frame.relicCollected === 1);
  return { state: packet.state, frame };
}
function command(name, ...args) {
  assert.ok(current, "Each owned State must be consumed once");
  const owned = current.state;
  current = null;
  current = accept(Game[name](owned, ...args));
  return current.frame;
}
function budget() {
  assert.ok(
    performance.now() < deadline,
    "Objective integration exceeded its 28 second gameplay budget: " + JSON.stringify({stage:current?.frame.stage,tick:current?.frame.tick,level:current?.frame.level,elapsedMs:performance.now()-started}),
  );
}
function resolveChoice() {
  while (current.frame.phase === 1 || current.frame.phase === 2) {
    budget();
    const frame = current.frame;
    assert.ok(frame.offers.length > 0);
    let choice = frame.offers.findIndex(
      (offer) => offer.kind === 0 && frame.weapons[offer.id] > 0,
    );
    if (choice < 0)
      choice = frame.offers.findIndex(
        (offer) => offer.kind === 1 && [0, 1, 6, 7, 11].includes(offer.id),
      );
    command("choose", Math.max(0, choice));
    assert.equal(
      current.frame.tick,
      frame.tick,
      "Choosing an upgrade does not advance simulation",
    );
  }
  assert.equal(
    current.frame.phase,
    0,
    "Controller must remain alive while reaching the relic",
  );
}

try {
  let profile = loadProfile();
  profile.meta = [5, 5, 5, 3, 5, 5, 5, 5, 5, 2]; // Legal purchased ranks supplied as a test fixture.
  const encodedMeta = metaCode(profile);
  for (const relic of STAGE_RELICS)
    assert.equal(
      allowedWeapons(profile) & (1 << relic.weapon),
      0,
      "A fresh profile must lock each relic weapon",
    );
  const results = [];
  for (const relic of STAGE_RELICS) {
    budget();
    current = accept(Game.start(2, encodedMeta));
    command("configure", relic.id, 9);
    command("configure_unlocks", allowedWeapons(profile));
    command("set_mode", 0);
    assert.equal(current.frame.stage, relic.id);
    assert.equal(current.frame.relicX, relic.x);
    assert.equal(current.frame.relicY, relic.y);
    assert.equal(current.frame.relicCollected, 0);
    let seenRelic = false;
    let collectionBefore;
    while (current.frame.relicCollected === 0) {
      budget();
      resolveChoice();
      const frame = current.frame;
      assert.ok(
        frame.tick < 600,
        `Stage ${relic.id} relic not reached within 600 normal input ticks`,
      );
      seenRelic ||= frame.bodies.some(
        (body) => body[2] === 9 && body[3] === relic.id,
      );
      const dx = frame.relicX - frame.px,
        dy = frame.relicY - frame.py;
      const length = Math.max(1, Math.hypot(dx, dy));
      command("advance", dx / length, dy / length);
      assert.equal(current.frame.tick, frame.tick + 1);
      if (current.frame.relicCollected === 1) collectionBefore = frame;
    }
    assert.ok(
      seenRelic,
      `Stage ${relic.id} relic must appear as entity kind 9 before collection`,
    );
    assert.ok(collectionBefore);
    assert.ok(
      current.frame.gold > collectionBefore.gold,
      "Collecting a relic grants gold",
    );
    assert.ok(
      current.frame.level > collectionBefore.level ||
        current.frame.xp > collectionBefore.xp,
      "Collecting a relic grants experience",
    );
    assert.ok(
      !current.frame.bodies.some((body) => body[2] === 9),
      "Collected relic entity disappears",
    );
    const collectedAt = current.frame.tick;
    for (let i = 0; i < 6; i++) {
      resolveChoice();
      command("advance", 0, 0);
      assert.equal(
        current.frame.relicCollected,
        1,
        "Relic collection flag remains authoritative",
      );
      assert.ok(
        !current.frame.bodies.some((body) => body[2] === 9),
        "Relic must not respawn after collection",
      );
    }
    // The user may abandon a live run; only the persisted result copy is marked ended.
    // No frame or State passed back to the Bend engine is modified.
    const abandoned = {
      ...current.frame,
      phase: 3,
      runId: `objective-relic-${relic.id}`,
    };
    recordRun(profile, abandoned);
    assert.ok(profile.stageRelics.includes(relic.id));
    assert.ok(
      allowedWeapons(profile) & (1 << relic.weapon),
      "Collected relic unlocks its designated weapon",
    );
    profile = loadProfile();
    assert.ok(
      profile.stageRelics.includes(relic.id),
      "Relic persists through profile reload",
    );
    assert.ok(
      allowedWeapons(profile) & (1 << relic.weapon),
      "Weapon unlock persists through profile reload",
    );
    results.push({ stage: relic.id, tick: collectedAt, weapon: relic.weapon });
    console.log(JSON.stringify({test:"relic-stage-completed",stage:relic.id,tick:collectedAt,elapsedMs:performance.now()-started}));
    current = null; // Discard this owned run; it is never reused for another stage.
  }
  assert.deepEqual([...profile.stageRelics].sort(), [0, 1, 2, 3, 4]);

  // Compare independent owned runs; setting Trial clears purchased ranks inside Bend.
  current = accept(Game.start(2, 0));
  command("configure", 0, 9);
  command("set_mode", 3);
  const zeroTrial = structuredClone(current.frame);
  assert.equal(zeroTrial.runLength, 18000);
  assert.equal(zeroTrial.mode, 3);
  current = null;
  current = accept(Game.start(2, encodedMeta));
  command("configure", 0, 9);
  const boostedHealth = current.frame.maxHp;
  command("set_mode", 3);
  assert.equal(current.frame.mode, 3);
  assert.equal(current.frame.runLength, 18000);
  assert.equal(
    current.frame.maxHp,
    zeroTrial.maxHp,
    "Trial disables permanent maximum-health upgrades",
  );
  assert.equal(current.frame.hp, zeroTrial.hp);
  assert.ok(
    boostedHealth > current.frame.maxHp,
    "Comparison exercises a real purchased health bonus",
  );
  budget();
  console.log(
    JSON.stringify({
      test: "input-only stage relics and Trial",
      relics: results,
      trialHealth: current.frame.maxHp,
      seconds: (performance.now() - started) / 1000,
    }),
  );
} finally {
  if (previousStorage === undefined) delete globalThis.localStorage;
  else globalThis.localStorage = previousStorage;
}
