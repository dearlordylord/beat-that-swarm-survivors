import assert from "node:assert/strict";
import { stat } from "node:fs/promises";
for (const file of ["game.bend", "projectile.bend", "encounters.bend"])
  assert.ok(
    (await stat(new URL("./dist/game.mjs", import.meta.url))).mtimeMs >=
      (await stat(new URL(file, import.meta.url))).mtimeMs,
    "Rebuild stale " + file,
  );
const { default: Game } = await import("./dist/game.mjs");
const accept = (p) => {
  assert.equal(p.$, "Packet", p.error);
  return { state: p.state, frame: JSON.parse(p.frame) };
};
let current = accept(Game.start(0, 0));
current = accept(Game.configure(current.state, 0, 0));
for (let i = 0; i < 3600 && current.frame.phase !== 3; i++) {
  const { state, frame: f } = current;
  assert.notEqual(f.phase, 4);
  if (f.phase === 1 || f.phase === 2) {
    let choice = f.offers.findIndex(
      (o) => o.kind === 1 && ![6, 7, 11, 13, 17].includes(o.id),
    );
    if (choice < 0) choice = 0;
    current = accept(Game.choose(state, choice));
    i--;
    continue;
  }
  const enemy = f.bodies
    .filter((b) => b[2] === 0)
    .sort(
      (a, b) =>
        (a[0] - f.px) ** 2 +
        (a[1] - f.py) ** 2 -
        ((b[0] - f.px) ** 2 + (b[1] - f.py) ** 2),
    )[0];
  const dx = enemy ? enemy[0] - f.px : 0,
    dy = enemy ? enemy[1] - f.py : 0,
    len = Math.max(1, Math.hypot(dx, dy));
  current = accept(Game.advance(state, dx / len, dy / len));
}
const f = current.frame;
console.log(
  JSON.stringify({
    test: "fresh profile defeat",
    tick: f.tick,
    phase: f.phase,
    hp: f.hp,
    kills: f.kills,
    gold: f.gold,
  }),
);
assert.equal(f.phase, 3);
assert.equal(f.hp, 0);
assert.ok(f.enemiesKilled.length>0,"Defeated enemy variants must reach the frame DTO");
assert.ok(f.enemiesKilled.every(id=>Number.isInteger(id)&&id>=0&&id<30));
assert.ok(f.gold > 0, "A lost run must still earn progression");
const terminal = current.frame;
current = accept(Game.advance(current.state, 1, 0));
assert.deepEqual(current.frame, terminal, "Defeated run must stay terminal");
