import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';

const artifact = process.env.SURVIVORS_SELECTION_ARTIFACT
  ? pathToFileURL(process.env.SURVIVORS_SELECTION_ARTIFACT)
  : new URL('./dist/game.mjs', import.meta.url);
const { default: G } = await import(artifact.href);
// The reference uses the same component schema and the ordinary query path.
const reference = G;
const array = xs => {
  const values = [];
  for (; xs.$ === 'Con'; xs = xs.tail) values.push(xs.head);
  return values;
};
const values = column => Array.isArray(column.values)
  ? column.values : values(column.carrier ?? column.state ?? column.inner);
const withoutRouting = state => {
  const { movement, candidates, ...store } = state.world.store;
  return { ...state, world: { ...state.world, store } };
};
const disableRouting = packet => {
  if (packet.state.world.store.movement)
    packet.state.world.store.movement = { $: 'MovementUnprepared' };
  if (packet.state.world.store.candidates)
    packet.state.world.store.candidates = { $: 'CandidatesUnprepared' };
  return packet;
};
const assertRoster = state => {
  const roster = array(state.world.store.movement.handles);
  const bodies = values(state.world.store.bodies);
  const roles = values(state.world.store.roles);
  const expected = array(state.world.allocator.order)
    .filter(key => {
      const body = bodies[key.index - 1].value;
      return ['EnemySlot', 'RelicSlot'].includes(roles[key.index - 1].value.$) && body.kind === 0;
    })
    .map(key => ({ $: 'Handle', namespace: state.world.namespace, key }));
  assert.deepEqual(roster, expected, 'active roster matches authoritative bodies in allocator order');
  assert.equal(new Set(roster.map(h => h.key.index)).size, roster.length);
  return roster;
};
const assertComposition = state => {
  const store = state.world.store;
  const bodies = values(store.bodies), roles = values(store.roles);
  const vitals = values(store.vitals), statuses = values(store.statuses), trajectories = values(store.motions);
  const pickups = values(store.pickups);
  const issued = array(state.world.allocator.order);
  const projectileKeys = [], poolKeys = [];
  for (const key of issued) {
    const index = key.index - 1, seed = bodies[index].value.seed;
    const expectedRole = seed === G.pool_relic_seed() ? 'RelicSlot'
      : seed < G.pool_enemy_count() ? 'EnemySlot'
      : seed < G.pool_hostile_start() ? 'PlayerProjectileSlot'
      : seed < G.pool_xp_start() ? 'HostileProjectileSlot' : 'XpSlot';
    assert.equal(roles[index].value.$, expectedRole, 'bootstrap assigns exact immutable composition role');
    const enemy = ['EnemySlot', 'RelicSlot'].includes(expectedRole);
    const projectile = ['PlayerProjectileSlot', 'HostileProjectileSlot'].includes(expectedRole);
    assert.equal(vitals[index]?.$ === 'Some', enemy, 'only enemy identities own health');
    assert.equal(statuses[index]?.$ === 'Some', enemy, 'only enemy identities own status effects');
    assert.equal(trajectories[index]?.$ === 'Some', projectile, 'only projectile identities own trajectory');
    assert.equal(pickups[index]?.$ === 'Some', expectedRole === 'XpSlot', 'only XP identities own pickup payload');
    if (expectedRole === 'XpSlot') {
      const pickup = pickups[index].value, body = bodies[index].value;
      const active = pickup.active === true || pickup.active?.$ === 'True';
      assert.equal(body.hp, pickup.amount);
      assert.equal(body.maxHp, pickup.generation);
      assert.equal(body.variant, pickup.variant);
      assert.equal(body.kind, active ? 2 : 8);
    }
    if (projectile) projectileKeys.push(key);
    if (enemy || expectedRole === 'XpSlot') poolKeys.push(key);
  }
  const handles = keys => keys.map(key => ({ $: 'Handle', namespace: state.world.namespace, key }));
  assert.equal(store.candidates.$, 'CandidatesPrepared');
  assert.deepEqual(array(store.candidates.projectiles), handles(projectileKeys));
  assert.deepEqual(array(store.candidates.pool), handles(poolKeys));
};
// Detached transport adapters must preserve both independent owners exactly.
let randomState = 0x5eed;
const word = () => randomState = (Math.imul(randomState, 1664525) + 1013904223) >>> 0;
const list = xs => xs.reduceRight((tail, head) => ({ $: 'Con', head, tail }), { $: 'Nil' });
for (let sample = 0; sample < 256; sample++) {
  const trajectory = {
    $: 'Trajectory', vx: sample ? Math.fround((word() / 0xffffffff - 0.5) * 1e6) : -0,
    vy: sample ? Math.fround(word() / 0xffffffff * 1e-30) : Math.fround(1.401298464e-45),
    life: word(), pierce: word(), visited: list([word(), word()]),
    ownerBase: word(), logicalSlot: word(),
  };
  const status = { $: 'Status', slow: word(), burn: word() };
  const motion = G.logical_motion(trajectory, status);
  assert.deepEqual(G.trajectory_of(motion), trajectory);
  assert.deepEqual(G.status_of(motion), status);
}
let comparisons = 0;
let witnessedActive = false;
for (const [hero, meta, seed, initialTick] of [
  [0, 0, 100, 0], [2, 364304237, 0xffffffff, 0],
  [0, 364304237, 101, 7199], [0, 364304237, 101, 35999],
]) {
  let selected = G.start_seed_quiet(hero, meta, seed);
  let ordinary = disableRouting(reference.start_seed_quiet(hero, meta, seed));
  assert.equal(selected.state.world.store.movement.$, 'MovementPrepared');
  assertComposition(selected.state);
  assert.deepEqual(assertRoster(selected.state), [], 'dormant bootstrap slots are not active');
  selected.state.run.tick = ordinary.state.run.tick = initialTick;
  for (let step = 0; step < 180; step++) {
    selected = G.advance_live_quiet(selected.state, Math.sin(step / 15), Math.cos(step / 15));
    ordinary = reference.advance_live_quiet(disableRouting(ordinary).state,
      Math.sin(step / 15), Math.cos(step / 15));
    assert.equal(selected.$, 'Packet');
    assert.equal(ordinary.$, 'Packet');
    assert.deepEqual(withoutRouting(selected.state), withoutRouting(ordinary.state),
      `complete state: hero ${hero}, seed ${seed}, injected initial tick ${initialTick}, step ${step}`);
    witnessedActive ||= assertRoster(selected.state).length > 0;
    comparisons++;
  }
}
// A real query failure after an earlier active row must roll back its Body write.
{
  let packet = G.advance_live_quiet(G.start_seed_quiet(0, 0, 100).state, 0, 0);
  const roster = assertRoster(packet.state);
  assert.ok(roster.length > 1);
  const first = roster[0], second = roster[1];
  const beforeBody = structuredClone(values(packet.state.world.store.bodies)[first.key.index - 1]);
  values(packet.state.world.store.statuses)[second.key.index - 1] = { $: 'None' };
  const result = G.execute_movement(packet.state.world, {
    $: 'Args', run: packet.state.run, bodies: packet.state.bodies,
    dx: 0, dy: 0, snapshots: packet.state.snapshots, hits: { $: 'Nil' },
  });
  assert.equal(result.outcome.$, 'Failure');
  assert.deepEqual(array(result.values), [], 'failed traversal publishes no partial outputs');
  assert.deepEqual(values(result.world.store.bodies)[first.key.index - 1], beforeBody,
    'earlier Body write rolls back');
  assert.deepEqual(array(result.world.store.movement.handles), roster,
    'failed movement leaves published membership intact');
}
// Trusted structural setup invalidates the derived list rather than hiding a birth.
{
  const packet = G.start_seed_quiet(0, 0, 100);
  const key = array(packet.state.world.allocator.order)[0];
  const handle = { $: 'Handle', namespace: packet.state.world.namespace, key };
  const body = { ...values(packet.state.world.store.bodies)[key.index - 1].value, kind: 0 };
  const world = G.populate_body(packet.state.world, handle, body);
  assert.equal(world.store.movement.$, 'MovementUnprepared');
  const result = G.execute_movement(world, {
    $: 'Args', run: packet.state.run, bodies: packet.state.bodies,
    dx: 0, dy: 0, snapshots: packet.state.snapshots, hits: { $: 'Nil' },
  });
  assert.equal(result.outcome.$, 'Success');
  assert.equal(values(result.world.store.bodies)[key.index - 1].value.age, body.age + 1,
    'unprepared fallback sees the structurally inserted active body');
}
assert.ok(witnessedActive, 'real lifecycle births publish active movement candidates');
console.log(`PASS movement selection: exact active roster and ${comparisons} complete-state comparisons; opening, injected boss/finale boundaries, rollback and setup invalidation`);
