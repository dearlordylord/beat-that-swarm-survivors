import assert from 'node:assert/strict';
import G from './dist/game.mjs';

const list = values => values.reduceRight((tail, head) => ({ $: 'Con', head, tail }), { $: 'Nil' });
const playerStart = G.pool_player_start();
const playerCount = G.pool_player_count();
const empty = list([]);
const initial = G.start(0, 0).state.run;
const weapons = Array(24).fill(0);
weapons[1] = 8;
const passives = Array(12).fill(0);
passives[4] = 5;
const run = { ...initial, tick: 1, weapons: list(weapons), passives: list(passives) };
const args = (currentRun, snapshots = []) => ({
  $: 'Args', run: currentRun, bodies: empty, dx: 1, dy: 0,
  snapshots: list(snapshots), hits: empty,
});
const snapshot = entity => ({ $: 'Snapshot', body: entity.row.body, motion: entity.motion });
const spawn = currentArgs => {
  const plan = G.prepare_shot_plan(currentArgs);
  return Array.from({ length: playerCount }, (_, i) => G.shot_spawn_planned(playerStart + i, currentArgs, plan))
    .filter(entity => entity.row.body.kind === 1);
};
assert.equal(playerCount, 512);
assert.equal(G.pool_xp_count(), 400);
assert.equal(G.pool_enemy_count(), 512);
assert.equal(G.pool_relic_seed(), 511);
assert.equal(G.pool_hostile_start() - playerStart, playerCount);
assert.equal(G.pool_xp_start() - G.pool_hostile_start(), 32, "No map actor slots remain between hostile and XP pools");
assert.equal(G.pool_total(), 1456);
assert.equal(G.pool_total(), G.pool_xp_start() + G.pool_xp_count());

const first = spawn(args(run));
assert.equal(first.length, 8, 'Full logical volley occupies eight physical slots');
const cooldown = G.cooldown_for(1, run.passives, run.meta, run.arcana, run.character);
const nextRun = { ...run, tick: 1 + cooldown };
const secondArgs = args(nextRun, first.map(snapshot));
const second = spawn(secondArgs);
assert.equal(second.length, 8);
assert.equal(new Set([...first, ...second].map(entity => entity.row.body.seed)).size, 16,
  'Overlapping ballistic volleys exceed eight live shots without replacing survivors');
for (const entity of [...first, ...second]) {
  assert.equal(entity.motion.ownerBase, 1);
  assert.ok(entity.motion.logicalSlot < 8);
  assert.ok(entity.row.body.seed >= playerStart && entity.row.body.seed < playerStart + playerCount);
}
const plan = G.prepare_shot_plan(secondArgs);
for (const entity of first) {
  const advanced = G.shot_step_planned(entity.row.body, entity.motion, secondArgs, plan);
  assert.equal(advanced.row.body.kind, 1);
  assert.equal(advanced.row.body.seed, entity.row.body.seed);
  assert.equal(advanced.motion.ownerBase, 1);
  assert.equal(advanced.motion.logicalSlot, entity.motion.logicalSlot);
  assert.equal(advanced.row.body.age, entity.row.body.age + 1);
}
const occupied = count => Array.from({ length: count }, (_, i) => ({
  $: 'Snapshot', body: { ...first[0].row.body, seed: playerStart + i },
  motion: { ...first[0].motion, life: 100, pierce: 9999, logicalSlot: i % 8 },
}));
assert.equal(spawn(args(nextRun, occupied(60))).length, 0, 'Owner live cap stops additional volleys');
const capped = spawn(args(nextRun, occupied(59)));
assert.equal(capped.length, 1, 'Only remaining owner capacity is allocated');
assert.equal(capped[0].row.body.seed, playerStart + 59);
const full = occupied(playerCount).map((s, i) => ({ ...s, motion: { ...s.motion, ownerBase: i % 24 } }));
assert.equal(spawn(args(nextRun, full)).length, 0, 'Global physical exhaustion never overwrites a live slot');
const released = full.slice(1);
const reclaimed = spawn(args(nextRun, released));
assert.equal(reclaimed.length, 1);
assert.equal(reclaimed[0].row.body.seed, playerStart, 'One released physical slot can be reclaimed');
for (const field of ['life', 'pierce']) {
  const expired = full.map((entry, index) => index === 0
    ? { ...entry, motion: { ...entry.motion, [field]: 0 } } : entry);
  const reused = spawn(args(nextRun, expired));
  assert.equal(reused.length, 1, `${field}=0 releases the physical slot`);
  assert.equal(reused[0].row.body.seed, playerStart);
}
console.log('Shared projectile pools: overlapping volleys, identity, owner metadata, owner cap, global exhaustion and reclaim passed');
const ownedArgs = args(nextRun, first.map(snapshot));
const ownedPlan = G.prepare_shot_plan(ownedArgs);
for (const carrier of [
  { $: 'ArgsShots', args: ownedArgs, plan: ownedPlan },
  { $: 'ArgsWrapped', inner: { $: 'ArgsWrapped', inner: { $: 'ArgsShots', args: ownedArgs, plan: ownedPlan } } },
]) {
  const opened = G.open_projectile_carrier(carrier);
  assert.deepEqual(opened.fst, ownedArgs);
  assert.deepEqual(opened.snd, ownedPlan);
}
const hostileSeed = G.pool_hostile_start();
const lateArgs = args({ ...run, tick: 21600 });
const dormantHostile = G.dormant_entity(1800, 1800, hostileSeed);
const dispatchedHostile = G.entity_update(dormantHostile.row.body, dormantHostile.motion, lateArgs);
assert.ok([7, 8].includes(dispatchedHostile.row.body.kind), 'Hostile identity can never enter enemy admission');
const liveHostile = G.hostile_created(true, hostileSeed, run.px, run.py,
  { $: 'Aim', x: 1700, y: 1700, id: 0, distance: 20000 });
const movedHostile = G.entity_update(liveHostile.row.body, liveHostile.motion, lateArgs);
assert.equal(movedHostile.row.body.kind, 7);
assert.equal(movedHostile.row.body.seed, hostileSeed);
assert.equal(movedHostile.row.body.age, liveHostile.row.body.age + 1);
assert.equal(movedHostile.motion.life, liveHostile.motion.life - 1);
console.log('Projectile carrier roundtrip and disjoint hostile dispatch regressions passed');
const array = values => {
  const result = [];
  while (values.$ === 'Con') { result.push(values.head); values = values.tail; }
  return result;
};
let ecsPacket = G.start(0, 0);
ecsPacket.state.run = { ...run, tick: 0 };
ecsPacket = G.advance_quiet(ecsPacket.state, 1, 0);
const ecsShots = array(ecsPacket.state.snapshots).filter(entry => entry.body.kind === 1);
assert.equal(ecsShots.length, 8, 'Actual ECS query realizes the complete prepared volley');
assert.deepEqual(ecsShots.map(entry => entry.motion.logicalSlot).sort((a, b) => a - b), [0,1,2,3,4,5,6,7]);
for (const entry of ecsShots) assert.equal(entry.motion.ownerBase, 1);
const ecsNext = G.advance_quiet(ecsPacket.state, 1, 0);
const ecsBySeed = new Map(array(ecsNext.state.snapshots).map(entry => [entry.body.seed, entry]));
for (const entry of ecsShots) {
  const advanced = ecsBySeed.get(entry.body.seed);
  assert.equal(advanced.body.kind, 1);
  assert.equal(advanced.body.age, entry.body.age + 1);
  assert.equal(advanced.motion.ownerBase, entry.motion.ownerBase);
  assert.equal(advanced.motion.logicalSlot, entry.motion.logicalSlot);
}
console.log('Actual ECS projectile query carries one complete plan and preserves all live owner/slot metadata');
