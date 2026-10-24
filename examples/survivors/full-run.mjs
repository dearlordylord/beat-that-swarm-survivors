// Ordinary input-only controller: never edits Bend state or frame to force outcomes.
import assert from "node:assert/strict";
import { WEAPONS } from "./content.mjs";
import { stat } from "node:fs/promises";
for (const file of [
  "game.bend",
  "projectile.bend",
  "encounters.bend",
])
  assert.ok(
    (await stat(new URL("./dist/game.mjs", import.meta.url))).mtimeMs >=
      (await stat(new URL(file, import.meta.url))).mtimeMs,
    "Rebuild source before full run",
  );
const { default: Game } = await import("./dist/game.mjs");
function accept(p) {
  assert.equal(p.$, "Packet", p.error);
  const f = JSON.parse(p.frame);
  assert.ok(f.hp <= f.maxHp);
  assert.ok(f.weapons.filter((x) => x > 0).length <= 6);
  assert.ok(f.passives.filter((x) => x > 0).length <= 6);
  assert.ok(
    f.bodies.every((b) => Number.isFinite(b[0]) && Number.isFinite(b[1])),
  );
  return { state: p.state, frame: f };
}
const meta = [5, 5, 5, 3, 5, 5, 5, 5, 5, 2].reduce(
  (code, n, i) => code + n * 2 ** (i * 3),
  0,
);
let current = accept(Game.start(2, meta));
current = accept(Game.configure(current.state, 0, 9));
let decisions = 0,
  seenBoss = false,
  seenChest = false,
  seenLevel = false;
for (let steps = 0; steps < 37000; steps++) {
  if (steps > 0 && steps % 3600 === 0)
    console.log(
      JSON.stringify({
        checkpoint: steps,
        tick: current.frame.tick,
        level: current.frame.level,
        kills: current.frame.kills,
      }),
    );
  const { state, frame: f } = current;
  seenBoss ||= f.bodies.some((b) => b[2] === 0 && b[3] >= 20);
  if (f.phase === 3 || f.phase === 4) break;
  if (f.phase === 1 || f.phase === 2) {
    seenLevel ||= f.phase === 1;
    seenChest ||= f.phase === 2;
    assert.ok(f.offers.length);
    // A legal advanced defensive build: aura, thorns, frost and area weapons.
    // Reserve all six passive slots for survivability and their evolution recipes.
    const wantedWeapons = [4, 19, 10, 0, 2, 17];
    const wantedPassives = [11, 1, 6, 2, 0, 7];
    const score = (o) => {
      if (o.kind === 3 || o.kind === 5) return 1000;
      if (o.kind === 0 && wantedWeapons.includes(o.id))
        return (
          (o.id === 4 ? 260 : 170) +
          (f.weapons[o.id] > 0 ? 30 : 0) -
          wantedWeapons.indexOf(o.id)
        );
      if (o.kind === 1 && wantedPassives.includes(o.id))
        return (
          210 -
          wantedPassives.indexOf(o.id) * 5 +
          (f.passives[o.id] === 0 ? 20 : 0)
        );
      if (o.kind === 2) return f.hp < f.maxHp * 0.7 ? 300 : 10;
      if (o.kind === 4) return 5;
      return -100;
    };
    let choice = f.offers.reduce(
      (best, o, i) => (score(o) > score(f.offers[best]) ? i : best),
      0,
    );
    current = accept(Game.choose(state, choice));
    decisions++;
    steps--;
    continue;
  }
  const nearest = (rows) =>
    rows.sort(
      (a, b) =>
        (a[0] - f.px) ** 2 +
        (a[1] - f.py) ** 2 -
        ((b[0] - f.px) ** 2 + (b[1] - f.py) ** 2),
    )[0];
  const ready = f.weapons.some(
    (level, id) => level === 8 && f.passives[WEAPONS[id].passive] > 0,
  );
  const chest = ready ? nearest(f.bodies.filter((b) => b[2] === 5)) : null;
  const loot = nearest(f.bodies.filter((b) => b[2] === 2));
  const target = chest ||
    loot || [
      1800 + Math.cos(f.tick / 180) * 300,
      1800 + Math.sin(f.tick / 180) * 300,
    ];
  let dx = target[0] - f.px,
    dy = target[1] - f.py;
  const enemies = f.bodies.filter((b) => b[2] === 0 || b[2] === 7);
  // Steer around nearby bodies instead of running straight through XP piles.
  for (const enemy of enemies) {
    const ex = f.px - enemy[0],
      ey = f.py - enemy[1],
      distance = Math.max(1, Math.hypot(ex, ey));
    if (distance < 140) {
      const pressure = (140 - distance) * 4;
      dx += (ex / distance) * pressure;
      dy += (ey / distance) * pressure;
    }
  }
  if (f.px < 160) dx += 400;
  if (f.px > 3440) dx -= 400;
  if (f.py < 160) dy += 400;
  if (f.py > 3440) dy -= 400;
  const len = Math.max(1, Math.hypot(dx, dy));
  current = accept(Game.advance(state, dx / len, dy / len));
  assert.equal(current.frame.tick, f.tick + 1);
}
const f = current.frame;
console.log(
  JSON.stringify({
    tick: f.tick,
    phase: f.phase,
    kills: f.kills,
    level: f.level,
    gold: f.gold,
    decisions,
    seenBoss,
    seenChest,
    seenLevel,
    evolutions: f.weapons.filter((x) => x >= 9).length,
    weapons: f.weapons,
    passives: f.passives,
    bossesKilled: f.bossesKilled,
  }),
);
assert.equal(f.phase, 4, "Controller must complete a genuine run");
assert.ok(
  f.tick >= 36000 && f.tick <= 37000,
  "Dawn must end in actual death after the time limit",
);
assert.equal(f.hp, 0, "Completion follows the lethal Dawn hunt");
assert.ok(seenLevel, "No levelup reached");
assert.ok(seenBoss, "No boss encountered");
assert.ok(seenChest, "No boss chest collected");
assert.ok(
  f.weapons.some((x) => x >= 9),
  "No evolution achieved",
);
