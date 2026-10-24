import assert from "node:assert/strict";
import Game from "./dist/game.mjs";
const list = (xs) =>
  xs.reduceRight((tail, head) => ({ $: "Con", head, tail }), { $: "Nil" });
const empty = list(Array(18).fill(0));
assert.equal(Game.earned_xp(2, empty, 0, 0), 2, "XP awards retain their original precision");
assert.equal(Game.earned_xp(6, empty, 0, 0), 6);
assert.equal(Game.next_xp_need(1), 46, "Early upgrades remain attainable without map actor rewards");
assert.equal(Game.active_limit(0), 96);
assert.equal(Game.active_limit(21600), 300);
assert.equal(Game.active_limit(100000), 300);
assert.ok(Game.next_xp_need(40) > Game.next_xp_need(20) * 2,
  "Later levels require accelerating investment rather than constant interruption");
const openingSpawns = Array.from({length: 24}, (_, i) => Game.enemy_new(i, 60, 1800, 1800, 0, 0, 0));
assert.ok(new Set(openingSpawns.map(b => b.x + ":" + b.y)).size > 12, "Spawns occupy varied offscreen positions");
assert.ok(openingSpawns.every(b => Math.max(Math.abs(b.x - 1800), Math.abs(b.y - 1800)) > 512 + 3 * b.radius + 24));
const early = Game.pressure_damage(1, 0, 0, 0, empty, 0, 0, 0);
const late = Game.pressure_damage(12, 30000, 0, 0, empty, 0, 0, 0);
assert.ok(
  late >= early + 12,
  "Time and surrounding enemies increase contact pressure",
);
assert.equal(
  Game.pressure_damage(12, 36000, 0, 1, empty, 0, 0, 0),
  0,
  "Invulnerability still protects",
);
assert.ok(
  Game.pressure_damage(1001, 36000, 0, 0, empty, 0, 0, 0) >= 2000,
  "Reaper contact is lethal",
);
assert.ok(
  Game.pressure_damage(1, 36000, 0, 0, empty, 0, 0, 0) < 100,
  "Ordinary enemies do not inherit Reaper contact lethality",
);
assert.ok(
  Game.pressure_damage(1, 36000, 2, 0, empty, 0, 0, 0) < 100,
  "Endless has no Dawn execution",
);
const accept = (p) => {
  assert.equal(p.$, "Packet");
  return { state: p.state, frame: JSON.parse(p.frame) };
};
// Advance the ordinary public entry; do not inject frames or bypass ECS.
let current = accept(Game.start(0, 0));
assert.equal(current.frame.xpNeed, 20, "First reward requires actual collection of 20 XP");
for (let i = 0; i < 120; i++) {
  if (current.frame.phase === 1 || current.frame.phase === 2)
    current = accept(Game.choose(current.state, 0));
  if (current.frame.phase === 0)
    current = accept(Game.advance(current.state, 1, 0));
}
const enemies = current.frame.bodies.filter((b) => b[2] === 0);
assert.ok(
  enemies.length >= 75,
  "The opening contains a visible horde within two seconds",
);
console.log(
  JSON.stringify({
    test: "balance pressure",
    tick: current.frame.tick,
    enemies: enemies.length,
    earlyDamage: early,
    lateDamage: late,
  }),
);
// Inject only the clock at the boundary; all entities are created/moved/damaged
// by real advance/ECS passes. This is not an end-to-end survival witness.
for (const mode of [0, 1, 3]) {
  let boundary = accept(Game.start(0, 0));
  boundary = accept(Game.set_mode(boundary.state, mode));
  boundary.state.run.tick = boundary.frame.runLength - 1;
  boundary = accept(Game.advance(boundary.state, 0, 0));
  assert.notEqual(
    boundary.frame.phase,
    4,
    "Clock completion alone must not stop the run",
  );
  assert.ok(
    boundary.frame.bodies.some((b) => b[2] === 0 && b[3] === 30),
    "Dawn creates a real Reaper entity",
  );
  for (let i = 0; i < 900 && ![3, 4].includes(boundary.frame.phase); i++) {
    boundary = accept(
      [1, 2].includes(boundary.frame.phase)
        ? Game.choose(boundary.state, 0)
        : Game.advance(boundary.state, 0, 0),
    );
  }
  assert.equal(
    boundary.frame.phase,
    4,
    "Actual lethal finale receives completed-run credit",
  );
  assert.equal(boundary.frame.hp, 0);
  console.log(
    JSON.stringify({
      test: "injected-clock ECS finale",
      mode,
      tick: boundary.frame.tick,
      phase: boundary.frame.phase,
    }),
  );
}
let endless = accept(Game.start(0, 0));
endless = accept(Game.set_mode(endless.state, 2));
endless.state.run.tick = 35999;
endless = accept(Game.advance(endless.state, 0, 0));
assert.ok(
  !endless.frame.bodies.some((b) => b[3] === 30),
  "Endless never summons Dawn Reaper",
);
// Former map-actor locations cannot activate AoE damage or grant rescue rewards.
let actorFree = accept(Game.start(0, 0));
actorFree.state.run.weapons = list(Array(24).fill(0));
for (const [px, py] of [[1960, 1800], [2012, 1890], [1800, 1800]]) {
  actorFree.state.run = { ...actorFree.state.run, px, py };
  for (let tick = 0; tick < 4; tick++) {
    actorFree = accept(Game.advance(actorFree.state, 0, 0));
    assert.ok(actorFree.frame.bodies.every(body => body[2] !== 10 && body[2] !== 11),
      "Map wisps and wards never spawn");
    assert.equal(actorFree.frame.xp, 0, "Former rescue locations grant no XP");
    assert.equal(actorFree.frame.gold, 0, "Former rescue locations grant no gold");
    assert.equal(actorFree.frame.kills, 0, "No independent map AoE kills enemies");
  }
}
const obsoleteWard = list([{
  $: "Snapshot",
  body: { $: "Body", x: 100, y: 100, kind: 11, variant: 1,
    hp: 160, maxHp: 160, age: 90, seed: Game.pool_xp_start(), radius: 12 },
  motion: Game.empty_motion(),
}]);
const obsoleteCollision = Game.collisions(Game.plan_hits(obsoleteWard, list([])), 100, 100, 12, 0);
assert.equal(obsoleteCollision.damage, 0, "Removed ward snapshots cannot create AoE damage");
assert.equal(obsoleteCollision.slow, 0, "Removed ward snapshots cannot create slow status");
console.log(JSON.stringify({ test: "no independent map actors, rescue rewards or ward AoE", passed: true }));
// An evolved-control build must not permanently freeze or displace the Reaper.
const immuneRun = accept(Game.start(0, 0)).state.run;
immuneRun.tick = 36010;
const reaperBody = {
  $: "Body",
  x: 2000,
  y: 1800,
  kind: 0,
  variant: 30,
  hp: 10000000,
  maxHp: 10000000,
  age: 20,
  seed: 0,
  radius: 36,
};
const frozenMotion = {
  ...Game.empty_motion(),
  vx: 0,
  vy: 0,
  life: 0,
  pierce: 0,
  visited: list([]),
  slow: 65590,
  burn: 0,
};
const controlCollision = {
  $: "Collision",
  damage: 25,
  slow: 65590,
  burn: 0,
  pull: 1,
  knock: 1,
  pullX: 100,
  pullY: 100,
};
const immuneResult = Game.enemy_applied(
  2000,
  1800,
  {
    $: "Row",
    body: reaperBody,
    hit: 0,
    xp: 0,
    gold: 0,
    heal: 0,
    chest: 0,
    killed: 0,
    relic: 0,
  },
  frozenMotion,
  controlCollision,
  immuneRun,
);
assert.equal(
  immuneResult.row.body.hp,
  9999975,
  "Reaper still receives weapon damage",
);
assert.equal(
  immuneResult.row.body.x,
  2000,
  "Knockback and pull cannot move the Reaper",
);
assert.equal(immuneResult.row.body.y, 1800);
assert.equal(
  immuneResult.motion.slow,
  0,
  "Freeze and slow do not persist on Reaper",
);
const movingReaper = Game.move_body(reaperBody, frozenMotion, {
  $: "Args",
  run: immuneRun,
  bodies: list([]),
  dx: 0,
  dy: 0,
  snapshots: list([]),
  hits: list([]),
});
assert.ok(
  movingReaper.x < reaperBody.x,
  "Reaper pursues despite frozen input status",
);
console.log(
  JSON.stringify({
    test: "Reaper control immunity",
    hp: immuneResult.row.body.hp,
    slow: immuneResult.motion.slow,
    moved: movingReaper.x < reaperBody.x,
  }),
);

// Isolate progression queue semantics by seeding XP; simulation still advances
// through public ECS transitions. This is not a survival or balance witness.
let deferred = accept(Game.start(0, 0));
deferred.state.run.xp = 10000;
deferred = accept(Game.advance_live(deferred.state, 0, 0));
assert.equal(deferred.frame.phase, 1);
const heldOffers = deferred.frame.offers;
const firstTick = deferred.frame.tick;
for (let i = 0; i < 6; i++) deferred = accept(Game.advance_live(deferred.state, 0, 0));
assert.equal(deferred.frame.tick, firstTick + 6, "Deferred choice does not halt simulation");
assert.deepEqual(deferred.frame.offers, heldOffers, "The active offer remains exactly stable");
assert.equal(arrayQueue(deferred.state.pending).length, 6, "Every additional paid level queues a reward");
const first = deferred.frame.offers[0];
deferred = accept(Game.choose(deferred.state, 0));
assert.equal(deferred.frame.phase, 1, "Choosing promotes one pending reward");
assert.equal(arrayQueue(deferred.state.pending).length, 5);
if (first.kind === 0) assert.equal(deferred.frame.weapons[first.id], first.level);
for (const offer of deferred.frame.offers) {
  if (offer.kind === 0) assert.ok(offer.level > deferred.frame.weapons[offer.id], "Promoted offers cannot regress current inventory");
}
const freezeTick = deferred.frame.tick;
deferred = accept(Game.advance(deferred.state, 0, 0));
assert.equal(deferred.frame.tick, freezeTick, "Legacy paused advance contract remains intact");
assert.deepEqual(arrayQueue(Game.reward_backlog(3, true)), [1, 2, 2], "Simultaneous level and multiple chests are retained");
console.log(JSON.stringify({test: "deferred progression", tick: deferred.frame.tick, queued: arrayQueue(deferred.state.pending).length}));
function arrayQueue(xs) {
  const result = [];
  while (xs.$ === "Con") {result.push(xs.head); xs = xs.tail;}
  return result;
}
// Capacity boundary fixture: inject only a late-wave clock into a fresh world.
// Real ECS spawning must admit the advertised horde, then continue simulating it.
let dense = accept(Game.start(0, 0));
dense.state.run.tick = 21600;
for (let i = 0; i < 12; i++) dense = accept(Game.advance_live(dense.state, 0, 0));
const admittedEnemies = dense.frame.bodies.filter(b => b[2] === 0).length;
assert.equal(admittedEnemies, 300, "Normal late-wave admission follows the 300-enemy gameplay cap");
let boosted = accept(Game.start(0, 0));
// Legal maximum Curse rank plus Inverse mode exceeds the500 admission ceiling.
boosted = accept(Game.set_mode(boosted.state, 1));
boosted.state.run = { ...boosted.state.run, tick: 21600, passives: Game.set_at(boosted.state.run.passives, 14, 5) };
for (let i = 0; i < 6; i++) boosted = accept(Game.advance_live(boosted.state, 0, 0));
assert.equal(boosted.frame.bodies.filter(b => b[2] === 0).length, 500, "Modified admission saturates at 500 while preserving reserved relic capacity");
for (let i = 0; i < 60; i++) {
  if ([3, 4].includes(dense.frame.phase)) break;
  dense = accept(Game.advance_live(dense.state, 1, 0));
  assert.ok(dense.frame.bodies.every(b => Number.isFinite(b[0]) && Number.isFinite(b[1])));
}
console.log(JSON.stringify({test: "injected-clock horde capacity", admittedEnemies, tick: dense.frame.tick, enemies: dense.frame.bodies.filter(b => b[2] === 0).length, phase: dense.frame.phase}));
// Command boundaries below seed only XP to create several earned choices.
function queuedChoice() {
  let p = accept(Game.start(0, 0));
  p.state.run.xp = 10000;
  for (let i = 0; i < 3; i++) p = accept(Game.advance_live(p.state, 0, 0));
  return p;
}
let edge = queuedChoice();
const queuedBeforeReroll = arrayQueue(edge.state.pending);
const rerollsBefore = edge.frame.rerolls;
edge = accept(Game.reroll(edge.state));
assert.equal(edge.frame.rerolls, rerollsBefore - 1);
assert.deepEqual(arrayQueue(edge.state.pending), queuedBeforeReroll, "Reroll retains earned pending choices");
assert.equal(edge.frame.phase, 1);
edge = queuedChoice();
const skipsBefore = edge.frame.skips;
const beforeSkip = arrayQueue(edge.state.pending).length;
edge = accept(Game.skip(edge.state));
assert.equal(edge.frame.skips, skipsBefore - 1);
assert.equal(edge.frame.phase, 1, "Skip promotes the next earned choice");
assert.equal(arrayQueue(edge.state.pending).length, beforeSkip - 1);
edge = queuedChoice();
const banishIndex = edge.frame.offers.findIndex(o => [0, 1].includes(o.kind));
assert.ok(banishIndex >= 0);
const banishedOffer = edge.frame.offers[banishIndex];
const beforeBanish = arrayQueue(edge.state.pending).length;
const banishesBefore = edge.frame.banishes;
edge = accept(Game.banish(edge.state, banishIndex));
assert.equal(edge.frame.banishes, banishesBefore - 1);
assert.equal(edge.frame.phase, 1, "Banish promotes the next earned choice");
assert.equal(arrayQueue(edge.state.pending).length, beforeBanish - 1);
assert.ok(!edge.frame.offers.some(o => o.kind === banishedOffer.kind && o.id === banishedOffer.id), "Promoted choices respect the new ban");
edge = queuedChoice();
edge.state.run.hp = 0;
edge = accept(Game.advance_live(edge.state, 0, 0));
assert.equal(edge.frame.phase, 3, "Death overrides a held choice");
assert.deepEqual(edge.frame.offers, []);
assert.deepEqual(arrayQueue(edge.state.pending), []);
console.log(JSON.stringify({test: "queued reroll, skip, banish and terminal boundaries", passed: true}));
