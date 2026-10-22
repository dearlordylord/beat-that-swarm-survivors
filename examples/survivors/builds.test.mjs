import assert from "node:assert/strict";
import { stat } from "node:fs/promises";
import { WEAPONS, UNIONS } from "./content.mjs";
for (const file of ["game.bend", "projectile.bend", "encounters.bend"])
  assert.ok(
    (await stat(new URL("./dist/game.mjs", import.meta.url))).mtimeMs >=
      (await stat(new URL(file, import.meta.url))).mtimeMs,
    "Rebuild stale " + file,
  );
const { default: Game } = await import("./dist/game.mjs");
const list = (xs) =>
  xs.reduceRight((tail, head) => ({ $: "Con", head, tail }), { $: "Nil" });
const array = (xs) => {
  const out = [];
  while (xs.$ === "Con") {
    out.push(xs.head);
    xs = xs.tail;
  }
  assert.equal(xs.$, "Nil");
  return out;
};
const valid = (o) => {
  assert.equal(o.$, "Offer");
  assert.ok([0, 1, 2, 3, 4, 5].includes(o.kind));
  assert.ok(
    o.id >= 0 &&
      o.id <
        ([0, 3].includes(o.kind)
          ? 24
          : o.kind === 1
            ? 18
            : o.kind === 5
              ? 6
              : 1),
  );
};
for (const w of WEAPONS) {
  const weapons = Array(24).fill(0),
    passives = Array(18).fill(0);
  weapons[w.id] = 8;
  assert.equal(Game.evolution_passive(w.id), w.passive);
  valid(Game.evolution_offer(list(weapons), 0, list(passives)));
  assert.notEqual(
    Game.evolution_offer(list(weapons), 0, list(passives)).kind,
    3,
  );
  passives[w.passive] = 1;
  const offer = Game.evolution_offer(list(weapons), 0, list(passives));
  assert.equal(offer.kind, 3);
  assert.equal(offer.id, w.id);
  assert.equal(offer.level, 9);
  weapons[w.id] = 7;
  assert.notEqual(
    Game.evolution_offer(list(weapons), 0, list(passives)).kind,
    3,
  );
}
for (const u of UNIONS) {
  const weapons = Array(24).fill(0);
  for (const id of u.weapons) weapons[id] = 8;
  const offer = Game.union_offer(6, 0, list(weapons), {
    $: "Offer",
    kind: 4,
    id: 0,
    level: 50,
  });
  assert.equal(offer.kind, 5);
  assert.equal(offer.id, u.id);
  assert.equal(offer.level, 10 + u.id);
}
for (const [weapons, passives] of [
  [Array(24).fill(0), Array(18).fill(0)],
  [
    Array.from({ length: 24 }, (_, i) => (i < 6 ? 8 : 0)),
    Array.from({ length: 18 }, (_, i) => (i < 6 ? 5 : 0)),
  ],
]) {
  for (const o of array(Game.chest_offers(1, list(weapons), list(passives))))
    valid(o);
  for (const o of array(Game.make_offers(1, list(weapons), list(passives)))) {
    valid(o);
    if (o.kind === 0)
      assert.ok(weapons[o.id] > 0 || weapons.filter((x) => x > 0).length < 6);
    if (o.kind === 1)
      assert.ok(passives[o.id] > 0 || passives.filter((x) => x > 0).length < 6);
  }
}
console.log(
  "24 evolution recipes, missing prerequisites, 6 union recipes and bounded level/chest offers pass.",
);

// Recovery affects new healing, never the health already owned by the player.
assert.equal(Game.heal_after_damage(50, 0, 0, 120, 100), 50);
assert.equal(Game.heal_after_damage(50, 10, 0, 130, 100), 40);
assert.equal(Game.heal_after_damage(50, 10, 10, 150, 100), 55);
assert.equal(Game.heal_after_damage(90, 0, 20, 150, 100), 100);
const body = (kind, seed, variant = 1) => ({
  $: "Body",
  x: 100,
  y: 100,
  kind,
  variant,
  hp: 7,
  maxHp: 7,
  age: 1,
  seed,
  radius: 10,
});
const shot = (pierce, visited = []) => ({
  $: "Snapshot",
  body: body(1, 192),
  motion: {
    $: "Motion",
    vx: 1,
    vy: 0,
    life: 60,
    pierce,
    visited: list(visited),
    slow: 0,
    burn: 0,
  },
});
const enemies = list([body(0, 11), body(0, 12)]);
const single = Game.plan_hits(list([shot(1)]), enemies);
assert.deepEqual(array(Game.hit_targets(single, 192)), [11]);
assert.equal(Game.collisions(single, 100, 100, 10, 11).damage, 7);
assert.equal(Game.collisions(single, 100, 100, 10, 12).damage, 0);
const visited = Game.plan_hits(list([shot(1, [11])]), enemies);
assert.deepEqual(array(Game.hit_targets(visited, 192)), [12]);
const pair = Game.plan_hits(list([shot(2)]), enemies);
assert.deepEqual(array(Game.hit_targets(pair, 192)), [11, 12]);
assert.equal(Game.collisions(pair, 100, 100, 10, 12).damage, 7);
console.log(
  "Recovery does not create health; frozen collision recipients obey pierce and hit history.",
);
