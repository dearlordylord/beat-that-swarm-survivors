import assert from "node:assert/strict";
import { stat } from "node:fs/promises";
for (const file of ["game.bend", "projectile.bend", "encounters.bend"])
  assert.ok(
    (await stat(new URL("./dist/game.mjs", import.meta.url))).mtimeMs >=
      (await stat(new URL(file, import.meta.url))).mtimeMs,
    "Rebuild stale " + file,
  );
const { default: Game } = await import("./dist/game.mjs");
const spawn = (id, level = 1) =>
  Game["projectile.spawn"](id, level, 0, 100, 100, 400, 100, 1, 0, 1, 1, 1);
const step = (id, age, shot, px = 100, py = 100, tx = 400, ty = 100) =>
  Game["projectile.step"](id, age, shot, px, py, tx, ty);
const hit = (id, age) => Game["projectile.active_hit"](id, age) === true;
for (let id = 0; id < 24; id++) {
  let shot = spawn(id);
  assert.equal(shot.$, "projectile.Shot");
  assert.ok(shot.life > 0 && shot.radius > 0);
  for (let age = 0; age < 300; age++) {
    const life = shot.life;
    shot = step(id, age, shot);
    assert.equal(shot.life, Math.max(0, life - 1), `lifetime weapon${id}`);
    assert.ok(
      [shot.x, shot.y, shot.vx, shot.vy, shot.radius].every(Number.isFinite),
      `finite weapon${id}`,
    );
  }
}
let knife = spawn(1),
  next = step(1, 1, knife);
assert.ok(next.x > knife.x);
assert.equal(next.y, knife.y);
let axe = spawn(2);
assert.ok(step(2, 1, axe).vy > axe.vy);
let homing = spawn(0);
assert.ok(step(0, 1, homing, 100, 100, 100, 400).vy > 0);
let aura = step(4, 1, spawn(4), 250, 280);
assert.equal(aura.x, 250);
assert.equal(aura.y, 280);
let cross = spawn(8);
cross = { ...cross, x: 400, y: 100 };
assert.ok(step(8, 80, cross, 100, 100).vx < cross.vx);
let bomb = spawn(14);
for (let age = 0; age < 32; age++) bomb = step(14, age, bomb);
assert.equal(bomb.radius, 64);
assert.equal(hit(14, 29), false);
assert.equal(hit(14, 30), true);
let meteor = spawn(17);
for (let age = 0; age < 22; age++) meteor = step(17, age, meteor);
assert.equal(meteor.radius, 78);
assert.equal(hit(17, 20), true);
assert.equal(hit(22, 24), false);
assert.equal(hit(22, 25), true);
assert.equal(Game["projectile.status"](10), 1);
assert.equal(Game["projectile.status"](20), 4);
console.log(
  "24 projectile lifetimes, finite trajectories, aiming, gravity, homing, return, aura anchoring and delayed impact controls pass.",
);
