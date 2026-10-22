// Integration through the emitted public API only. Never inspect or edit Bend State.
import assert from "node:assert/strict";
import { stat } from "node:fs/promises";
import { performance } from "node:perf_hooks";

const artifact = await stat(new URL("./dist/game.mjs", import.meta.url));
for (const source of ["game.bend", "projectile.bend", "encounters.bend"]) {
  const info = await stat(new URL(source, import.meta.url));
  assert.ok(
    artifact.mtimeMs >= info.mtimeMs,
    `Rebuild dist/game.mjs after changing ${source}`,
  );
}
const { default: Game } = await import("./dist/game.mjs");
for (const name of [
  "start",
  "configure",
  "set_mode",
  "configure_unlocks",
  "advance",
  "choose",
  "reroll",
  "banish",
  "skip",
]) {
  assert.equal(typeof Game[name], "function", `Missing public API ${name}`);
}
const started = performance.now();
const deadline = started + 28_000;
const locked = [12, 14, 16, 17, 18, 22];
const banned = locked.map((id) => ({ kind: 0, id }));
let current;
function accept(packet) {
  assert.equal(packet.$, "Packet", packet.error || "Expected owned Packet");
  const frame = JSON.parse(packet.frame);
  assert.ok(frame.hp >= 0 && frame.hp <= frame.maxHp);
  assert.ok(Number.isFinite(frame.px) && Number.isFinite(frame.py));
  for (const key of ["rerolls", "banishes", "skips"]) {
    assert.ok(
      Number.isInteger(frame[key]) && frame[key] >= 0 && frame[key] <= 3,
      `${key} bounded`,
    );
  }
  for (const offer of frame.offers) {
    assert.ok(
      !banned.some((item) => item.kind === offer.kind && item.id === offer.id),
      "Banished kind/id returned in a future offer",
    );
  }
  return { state: packet.state, frame };
}
function command(name, ...args) {
  assert.ok(current, "Owned state must be available and never reused");
  const owned = current.state;
  current = null;
  current = accept(Game[name](owned, ...args));
  return current.frame;
}
function unchanged(name, ...args) {
  const before = structuredClone(current.frame);
  command(name, ...args);
  assert.deepEqual(
    current.frame,
    before,
    `${name} must ignore an invalid phase or exhausted charge`,
  );
}
function budget() {
  assert.ok(
    performance.now() < deadline,
    "API integration exceeded its 28 second gameplay budget",
  );
}

// A single tick-zero state is consumed sequentially across every valid selection.
const meta = [5, 5, 5, 3, 5, 5, 5, 5, 5, 2].reduce(
  (code, rank, id) => code + rank * 2 ** (id * 3),
  0,
);
current = accept(Game.start(2, meta));
for (let stage = 0; stage < 5; stage++) {
  for (let arcana = 0; arcana < 12; arcana++) {
    const frame = command("configure", stage, arcana);
    assert.equal(frame.tick, 0);
    assert.equal(frame.stage, stage);
    assert.equal(frame.arcana, arcana);
  }
}
for (let mode = 0; mode < 4; mode++)
  assert.equal(command("set_mode", mode).mode, mode);
// Trial deliberately clears permanent upgrades; use a fresh owner for the normal controller.
current = null;
current = accept(Game.start(2, meta));
command("configure", 0, 9);
command("set_mode", 0);
command(
  "configure_unlocks",
  locked.reduce((mask, id) => mask & ~(1 << id), 0xffffff),
);
command("advance", 0, 0);
assert.equal(current.frame.tick, 1);
unchanged("configure", 4, 0);
unchanged("set_mode", 2);
unchanged("configure_unlocks", 0);
for (const [name, args] of [
  ["reroll", []],
  ["banish", [0]],
  ["skip", []],
  ["choose", [0]],
])
  unchanged(name, ...args);

let advances = 1;
let levelsSeen = 0;
let lastLevelTick = -1;
function reachLevelup() {
  while (current.frame.phase !== 1) {
    budget();
    const frame = current.frame;
    assert.ok(
      frame.phase !== 3 && frame.phase !== 4,
      "Controller ended before the required level-up",
    );
    if (frame.phase === 2) {
      command("choose", 0);
      continue;
    }
    assert.equal(frame.phase, 0);
    const loot = frame.bodies
      .filter((body) => body[2] === 2)
      .sort(
        (a, b) =>
          (a[0] - frame.px) ** 2 +
          (a[1] - frame.py) ** 2 -
          ((b[0] - frame.px) ** 2 + (b[1] - frame.py) ** 2),
      )[0];
    const target = loot || [
      1800 + Math.cos(frame.tick / 180) * 160,
      1800 + Math.sin(frame.tick / 180) * 160,
    ];
    const dx = target[0] - frame.px,
      dy = target[1] - frame.py;
    const length = Math.max(1, Math.hypot(dx, dy));
    command("advance", dx / length, dy / length);
    assert.equal(current.frame.tick, frame.tick + 1);
    advances++;
    assert.ok(
      advances <= 6000,
      "No required natural level-up within 6000 input ticks",
    );
  }
  assert.equal(current.frame.offers.length, 3);
  if (current.frame.tick !== lastLevelTick) {
    levelsSeen++;
    lastLevelTick = current.frame.tick;
  }
}
reachLevelup();
const firstTick = current.frame.tick;
while (current.frame.rerolls > 0) {
  const before = current.frame;
  command("reroll");
  assert.equal(current.frame.rerolls, before.rerolls - 1);
  assert.equal(current.frame.phase, 1);
  assert.equal(current.frame.tick, firstTick);
  assert.equal(current.frame.offers.length, 3);
  assert.equal(current.frame.banishes, before.banishes);
  assert.equal(current.frame.skips, before.skips);
}
unchanged("reroll");

// Banish at natural level-ups; every later offer is checked by accept().
while (current.frame.banishes > 0) {
  reachLevelup();
  const index = current.frame.offers.findIndex(
    (offer) => offer.kind === 0 || offer.kind === 1,
  );
  assert.ok(
    index >= 0,
    "A fresh build must provide a banishable weapon or passive",
  );
  const offer = { ...current.frame.offers[index] };
  const before = current.frame;
  command("banish", index);
  banned.push({ kind: offer.kind, id: offer.id });
  assert.equal(current.frame.banishes, before.banishes - 1);
  assert.equal(current.frame.phase, 0);
  assert.deepEqual(current.frame.weapons, before.weapons);
  assert.deepEqual(current.frame.passives, before.passives);
  assert.equal(current.frame.tick, before.tick);
}
reachLevelup();
unchanged("banish", 0);
while (current.frame.skips > 0) {
  reachLevelup();
  const before = current.frame;
  command("skip");
  assert.equal(current.frame.skips, before.skips - 1);
  assert.equal(current.frame.phase, 0);
  assert.equal(current.frame.tick, before.tick);
  assert.deepEqual(current.frame.weapons, before.weapons);
  assert.deepEqual(current.frame.passives, before.passives);
  assert.equal(current.frame.gold, before.gold + 10);
}
reachLevelup();
unchanged("skip");
unchanged("reroll");
unchanged("banish", 0);
budget();
console.log(
  JSON.stringify({
    test: "public API input-only integration",
    tick: current.frame.tick,
    levelsSeen,
    banned,
    seconds: (performance.now() - started) / 1000,
  }),
);
