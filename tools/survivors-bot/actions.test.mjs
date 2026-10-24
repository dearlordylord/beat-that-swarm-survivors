import assert from "node:assert/strict";
import Bot from "../../examples/survivors/dist/bot-actions.mjs";

const accept = (packet) => {
  assert.equal(packet.$, "Packet", packet.error);
  const originalFrame = packet.frame;
  const observation = Bot.observed_packet(packet);
  assert.equal(observation.$, "Observed", observation.error);
  assert.equal(observation.frame, originalFrame, "Packet observation reuses the exact serialized frame");
  return { state: observation.state, frame: JSON.parse(observation.frame), actions: JSON.parse(observation.actions), mechanics: JSON.parse(observation.mechanics) };
};
const verify = ({frame, actions, mechanics}) => {
  assert.equal(mechanics.source, "Bend game functions");
  for (const key of ["hp", "maxHp", "gold", "weapons", "passives"])
    assert.deepEqual(mechanics.current[key], frame[key]);
  assert.equal(mechanics.offers.length, frame.offers.length);
  for (const [index, preview] of mechanics.offers.entries()) {
    assert.equal(preview.offerIndex, index);
    assert.deepEqual(preview.offer, frame.offers[index]);
    assert.ok(preview.after.weaponStats.every(w => w.cooldownTicks >= 6));
  }
  assert.equal(new Set(actions.map(a => a.id)).size, actions.length);
  for (const action of actions) {
    assert.equal(action.observedTick, frame.tick);
    assert.equal(action.validOnlyAtObservedTick, true);
    assert.equal(action.executable, false);
    assert.equal(action.safety, "unassessed");
    assert.ok(Number.isFinite(action.distance));
    assert.ok(Math.abs(action.distance - Math.hypot(action.target.x - frame.px, action.target.y - frame.py)) < 0.01);
    if (action.kind.startsWith("move_")) continue;
    const kind = {approach_experience: 2, approach_chest: 5, approach_relic: 9}[action.kind];
    assert.ok(frame.bodies.some(b => b[2] === kind && b[0] === action.target.x && b[1] === action.target.y &&
      action.id === `t${frame.tick}:${action.kind}:${b[7]}:${b[2]}:${b[3]}:${b[6]}` &&
      (kind < 10 || (b[3] === 0 && b[4] > 0))), "Every entity goal matches the real engine snapshot");
  }
  for (const body of frame.bodies) {
    const actionable = (body[2] === 2 && body[4] > 0) || body[2] === 5 || body[2] === 9 || ([10,11].includes(body[2]) && body[3] === 0 && body[4] > 0);
    if (actionable) assert.ok(actions.some(a => a.target.x === body[0] && a.target.y === body[1] && a.id.includes(`:${body[7]}:${body[2]}:${body[3]}:${body[6]}`)));
  }
};
let current = accept(Bot.fresh_start());
assert.equal(current.frame.tick, 0);
assert.equal(current.frame.offers.length, 0);
assert.equal(current.actions.length, 4);
// Pure Run-data upgrade preview fixture only, not a gameplay choice or rollout.
const pureRun = structuredClone(current.state.run);
const healthPreview = JSON.parse(Bot.preview_stats({$: "Offer", kind: 1, id: 7, level: 1}, pureRun));
assert.equal(healthPreview.maxHp, current.frame.maxHp + Math.floor(current.frame.maxHp * 20 / 100));
assert.equal(healthPreview.hp, current.frame.hp + Math.floor(current.frame.maxHp * 20 / 100));
assert.equal(healthPreview.passives[7], 1);
const weaponPreview = JSON.parse(Bot.preview_stats({$: "Offer", kind: 0, id: 0, level: 2}, pureRun));
assert.equal(weaponPreview.weapons[0], current.frame.weapons[0] + 1);
assert.ok(weaponPreview.weaponStats.find(w => w.id === 0).baseHitDamage > current.mechanics.current.weaponStats.find(w => w.id === 0).baseHitDamage);
const pureMechanics = JSON.parse(Bot.mechanics(pureRun, {$: "Con", head: {$: "Offer", kind: 1, id: 7, level: 1}, tail: {$: "Nil"}}));
assert.equal(pureMechanics.offers[0].offerIndex, 0);
assert.deepEqual(pureMechanics.offers[0].after, healthPreview);
assert.deepEqual(pureMechanics.current, current.mechanics.current);
assert.equal(current.mechanics.current.pickupRadius, 24);
assert.equal(current.mechanics.current.weaponStats[0].selfFieldRadius, 0, "Ranged starter is not treated as a self-field weapon");
const original = current.frame;
current = accept(Bot.reroll(current.state));
assert.deepEqual(current.frame, original, "Reroll outside an upgrade menu does nothing");
current = accept(Bot.skip(current.state));
assert.deepEqual(current.frame, original);
current = accept(Bot.banish(current.state, 0));
assert.deepEqual(current.frame, original);
verify(current);
const oldIds = new Set(current.actions.map(a => a.id));
current = accept(Bot.advance(current.state, 1, 0));
assert.equal(current.frame.tick, 1, "Observation returns the actual affine world for further ECS advancement");
verify(current);
assert.ok(current.actions.every(a => !oldIds.has(a.id)), "Snapshot-scoped candidate IDs expire on advancement");
assert.ok(current.actions.every(a => !["approach_wisp","approach_ward","activate_ward"].includes(a.kind)), "NoHiddenActorGoal: normal world exposes no removed map-actor action");
assert.equal(current.actions.filter(a => a.kind === "approach_relic").length, 1);
for (let i = 0; i < 12; i++) {
  current = accept(Bot.advance_live(current.state, 0, -1));
  verify(current);
}
assert.equal(current.frame.tick, 13);
const advanced = accept(Bot.advanced_start());
assert.equal(advanced.frame.character, 2);
assert.equal(advanced.frame.arcana, 9);
assert.equal(advanced.frame.mode, 0);
assert.ok(advanced.mechanics.current.weaponStats.find(w => w.id === 4).selfFieldRadius > 0, "Aura starter exposes its actual projectile field radius");
// Pure serialization boundary tests only: no mutated gameplay state or simulated run.
const list = xs => xs.reduceRight((tail, head) => ({$: "Con", head, tail}), {$: "Nil"});
const body = (kind, variant, hp, seed) => ({$: "Body", x: 100, y: 200, kind, variant, hp, maxHp: hp, age: 7, seed, radius: 12});
const fixture = list([body(5, 20, 0, 1), body(10, 0, 80, 2), body(11, 0, 80, 3), body(8, 0, 0, 4), body(2, 4, 12, 748), {...body(2, 4, 18, 749), age: 2000}]);
const goals = JSON.parse(Bot.catalog_live(true, 12, 100, 100, fixture));
assert.equal(goals.length, 7);
assert.ok(goals.every(g=>!["approach_wisp","approach_ward","activate_ward"].includes(g.kind)), "NoHiddenActorGoal: even injected living actor bodies are not offered");
assert.ok(goals.some(g=>g.resource?.baseXp===18 && g.resource.autoClaimTicks===null), "Old XP piles remain actionable until approached");
assert.equal(goals.at(-1).kind, "approach_experience");
assert.equal(goals.at(-3).kind, "approach_chest");

assert.equal(goals.at(-3).id, "t12:approach_chest:1:5:20:7");
assert.deepEqual(JSON.parse(Bot.catalog_live(false, 12, 100, 100, fixture)), []);
console.log("BOT ACTIONS PASS: real affine world observation, fresh/advanced presets, engine-backed goals, snapshot expiry, empty-menu operations, removed map-actor goal exclusion");
