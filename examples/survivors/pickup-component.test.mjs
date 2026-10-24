import assert from 'node:assert/strict';
import G from './dist/game.mjs';

const list = items => items.reduceRight((tail, head) => ({ $: 'Con', head, tail }), { $: 'Nil' });
const array = items => {
  const result = [];
  for (; items.$ === 'Con'; items = items.tail) result.push(items.head);
  return result;
};
const values = column => Array.isArray(column.values)
  ? column.values : values(column.carrier ?? column.state ?? column.inner);
const entry = (column, seed) => values(column)[seed] ?? { $: 'None' };
const bool = value => value === true || value?.$ === 'True';
const assertView = (state, seed) => {
  const body = entry(state.world.store.bodies, seed).value;
  const pickup = entry(state.world.store.pickups, seed).value;
  assert.equal(body.hp, pickup.amount);
  assert.equal(body.maxHp, pickup.generation);
  assert.equal(body.variant, pickup.variant);
  assert.equal(body.kind, bool(pickup.active) ? 2 : 8);
};

// Actual initialized owners and issued entities: XP has its own payload and
// enemy/projectile responsibilities do not acquire that component.
{
  const packet = G.start_seed_quiet(0, 0, 100);
  const store = packet.state.world.store;
  const roles = values(store.roles);
  for (let seed = 0; seed < G.pool_total(); seed++) {
    const role = roles[seed].value.$;
    assert.equal(entry(store.pickups, seed).$, role === 'XpSlot' ? 'Some' : 'None');
    if (role === 'XpSlot') {
      for (const column of ['vitals', 'statuses', 'motions'])
        assert.equal(entry(store[column], seed).$, 'None', `XP does not own ${column}`);
      assertView(packet.state, seed);
    }
  }
}

// Poison the stored frame view while retaining a real authoritative Pickup.
// Collection must credit its payload, clear occupancy coherently and never
// credit the cleared identity a second time.
{
  let packet = G.start_seed_quiet(0, 0, 100);
  const seed = G.pool_xp_start();
  const store = packet.state.world.store;
  const body = entry(store.bodies, seed);
  body.value = {
    ...body.value, x: packet.state.run.px, y: packet.state.run.py,
    kind: 8, hp: 999, maxHp: 888, variant: 999, age: 10, radius: 6,
  };
  entry(store.pickups, seed).value = {
    $: 'Pickup', amount: 7, generation: 333, variant: 1, active: true,
  };
  packet = G.advance_live_quiet(packet.state, 0, 0);
  assert.equal(packet.$, 'Packet');
  assert.equal(packet.state.run.xp, 7, 'collection reads Pickup, not poisoned Body');
  const cleared = entry(packet.state.world.store.pickups, seed).value;
  assert.equal(cleared.amount, 0);
  assert.equal(bool(cleared.active), false);
  assert.equal(cleared.generation, 333);
  assert.equal(cleared.variant, 1);
  assertView(packet.state, seed);
  packet = G.advance_live_quiet(packet.state, 0, 0);
  assert.equal(packet.$, 'Packet');
  assert.equal(packet.state.run.xp, 7, 'a cleared pickup cannot credit twice');
  assertView(packet.state, seed);
}

// A later missing payload fails the same lifecycle transaction after an earlier
// XP view/payload write. Both components and earlier enemy writes must roll back.
{
  const packet = G.start_seed_quiet(0, 0, 100);
  const store = packet.state.world.store;
  const seed = G.pool_xp_start();
  const before = structuredClone({
    enemy: entry(store.bodies, 0),
    body: entry(store.bodies, seed),
    pickup: entry(store.pickups, seed),
    movement: store.movement,
  });
  const rows = array(store.candidates.pool).map(handle => {
    const body = entry(store.bodies, handle.key.index - 1).value;
    return {
      $: 'EntityRow',
      row: {
        $: 'Row', body: body.seed === seed
          ? { ...body, kind: 2, hp: 7, maxHp: 333, variant: 1, radius: 6 } : body,
        hit: 0, xp: 0, gold: 0, heal: 0, chest: 0, killed: 0, relic: 0,
      },
      motion: G.empty_motion(),
    };
  });
  values(store.pickups)[seed + 1] = { $: 'None' };
  const result = G.xp_lifecycle({ $: 'Nil' }, list(rows), packet.state.world);
  assert.equal(result.outcome.$, 'Failure');
  assert.deepEqual(array(result.values), []);
  assert.deepEqual(entry(result.world.store.bodies, 0), before.enemy);
  assert.deepEqual(entry(result.world.store.bodies, seed), before.body);
  assert.deepEqual(entry(result.world.store.pickups, seed), before.pickup);
  assert.deepEqual(result.world.store.movement, before.movement);
}
console.log('PASS sparse Pickup ownership, authoritative collection, repeat refusal and joint lifecycle rollback');
