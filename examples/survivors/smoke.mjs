import assert from "node:assert/strict";
import { stat } from "node:fs/promises";
for (const file of ["game.bend", "projectile.bend", "encounters.bend"])
  assert.ok(
    (await stat(new URL("./dist/game.mjs", import.meta.url))).mtimeMs >=
      (await stat(new URL(file, import.meta.url))).mtimeMs,
    "Rebuild stale " + file,
  );
const { default: Game } = await import("./dist/game.mjs");
function accept(packet) {
  assert.equal(packet.$, "Packet", packet.error || "Expected owned packet");
  const frame = JSON.parse(packet.frame);
  assert.ok(Number.isFinite(frame.px) && Number.isFinite(frame.py));
  assert.equal(frame.weapons.length, 24);
  assert.equal(frame.passives.length, 18);
  assert.ok(frame.hp <= frame.maxHp);
  assert.ok(frame.weapons.filter((x) => x > 0).length <= 6);
  assert.ok(frame.passives.filter((x) => x > 0).length <= 6);
  return { state: packet.state, frame };
}
for (let character = 0; character < 8; character++) {
  let { state, frame } = accept(Game.start(character, 0));
  assert.equal(frame.character, character);
  assert.equal(frame.tick, 0);
  assert.equal(frame.phase, 0);
  assert.equal(frame.weapons.filter((x) => x > 0).length, 1);
  state = null;
}
let current = accept(Game.start(0, 0));
if (Game.configure) current = accept(Game.configure(current.state, 0, 0));
const limit = process.argv.includes("--full") ? 36000 : 600;
let choices = 0, firstRewardTick = null, levelRewards = 0;
for (let i = 0; i < limit; i++) {
  const { state, frame } = current;
  if (frame.phase === 3 || frame.phase === 4) break;
  if (frame.phase === 1 || frame.phase === 2) {
    assert.ok(frame.offers.length > 0);
    firstRewardTick ??= frame.tick;
    if (frame.phase === 1) levelRewards++;
    current = accept(Game.choose(state, 0));
    choices++;
    i--;
    continue;
  }
  const loot = frame.bodies
    .filter((b) => b[2] === 2)
    .sort(
      (a, b) =>
        (a[0] - frame.px) ** 2 +
        (a[1] - frame.py) ** 2 -
        ((b[0] - frame.px) ** 2 + (b[1] - frame.py) ** 2),
    )[0];
  const target = loot || [
    Game.world_center() + Math.cos(i / 150) * 280,
    Game.world_center() + Math.sin(i / 150) * 280,
  ];
  let dx = target[0] - frame.px,
    dy = target[1] - frame.py;
  const len = Math.hypot(dx, dy) || 1;
  dx /= len;
  dy /= len;
  current = accept(Game.advance(state, dx, dy));
  assert.equal(current.frame.tick, frame.tick + 1);
}
assert.ok(current.frame.tick > 0);
if (limit === 600 && ![3, 4].includes(current.frame.phase)) {
  assert.ok(current.frame.level >= 2 && current.frame.level <= 5,
    `Fresh natural ten-second progression should be paced: level ${current.frame.level}`);
}
assert.ok(current.frame.bodies.length <= 1024);
console.log(
  JSON.stringify({
    test: "ordinary gameplay",
    tick: current.frame.tick,
    phase: current.frame.phase,
    kills: current.frame.kills,
    level: current.frame.level,
    choices,
    levelRewards,
    firstRewardTick,
  }),
);
