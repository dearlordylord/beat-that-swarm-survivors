import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';

// Test the Bend policy through the ordinary game build; allow a standalone
// module override for isolated development checks.
const url = process.env.LOOT_VISUAL_MODULE
  ? pathToFileURL(process.env.LOOT_VISUAL_MODULE).href
  : new URL('./dist/game.mjs', import.meta.url).href;
const { default: exports } = await import(url);
const names = ['green_threshold','red_threshold','size_cap_amount','minimum_radius','maximum_radius','tier','color','radius','scale','pile_color'];
const Loot = Object.fromEntries(names.map(name => [name, exports[`loot-visual:${name}`] ?? exports[name]]));
const BLUE = 0x69ceff, GREEN = 0x79dba8, RED = 0xff707b;
const f32 = Math.fround;
const expectedRadius = amount => f32(3 + f32(f32(Math.sqrt(f32(Math.min(amount, 100)))) * 0.5));

assert.equal(Loot.green_threshold(), 5);
assert.equal(Loot.red_threshold(), 10);
assert.equal(Loot.size_cap_amount(), 100);
assert.equal(Loot.minimum_radius(), 3);
assert.equal(Loot.maximum_radius(), 8);
for (const [amount, tier, color] of [
  [0, 0, BLUE], [1, 0, BLUE], [2, 0, BLUE], [4, 0, BLUE],
  [5, 1, GREEN], [6, 1, GREEN], [9, 1, GREEN],
  [10, 2, RED], [25, 2, RED], [100, 2, RED], [400, 2, RED], [0xffffffff, 2, RED],
]) {
  assert.equal(Loot.tier(amount), tier, `tier boundary ${amount}`);
  assert.equal(Loot.color(amount), color, `color boundary ${amount}`);
}

// Exhaust every non-saturated input, then sample the full U32 saturated range.
let previousRadius = 0, previousTier = 0;
for (let amount = 0; amount <= 100; amount++) {
  const radius = Loot.radius(amount), tier = Loot.tier(amount);
  assert.equal(radius, expectedRadius(amount), `independent F32 radius ${amount}`);
  assert.ok(Number.isFinite(radius) && radius >= 3 && radius <= 8, `radius bounds ${amount}`);
  assert.ok(radius >= previousRadius, `monotone size ${amount}`);
  assert.ok(tier >= previousTier, `monotone color tier ${amount}`);
  assert.equal(Loot.scale(amount), f32(radius / 4), `native artwork scale ${amount}`);
  assert.equal(Loot.pile_color(amount, true), RED, `small accumulator stays red ${amount}`);
  assert.equal(Loot.pile_color(amount, false), Loot.color(amount), `ordinary tier unchanged ${amount}`);
  previousRadius = radius;
  previousTier = tier;
}
for (const amount of [100, 101, 127, 255, 400, 1000, 65535, 0x7fffffff, 0xfffffffe, 0xffffffff]) {
  assert.equal(Loot.radius(amount), 8, `visual cap ${amount}`);
  assert.equal(Loot.scale(amount), 2, `scale cap ${amount}`);
  assert.equal(Loot.pile_color(amount, true), RED, `large accumulator stays red ${amount}`);
  assert.equal(Loot.pile_color(amount, false), Loot.color(amount), `large ordinary tier unchanged ${amount}`);
}
assert.equal(Loot.radius(0), 3);
assert.equal(Loot.radius(25), 5.5);
assert.ok(Loot.radius(2) < Loot.radius(6));
assert.ok(Loot.radius(6) < Loot.radius(25));
assert.ok(Loot.radius(25) < Loot.radius(100));
assert.equal(Loot.color(4), BLUE);
assert.equal(Loot.pile_color(4, true), RED);
assert.equal(Loot.radius(4), expectedRadius(4), 'marker changes color, not amount-only radius');
console.log('PASS shared Bend XP visuals: accumulator always-red samples, blue/green/red boundaries, all101 values through the cap, monotone/capped size and U32 overflow-pile samples; no mechanics changed');
