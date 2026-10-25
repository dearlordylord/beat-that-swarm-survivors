import { bendModule } from "../bend-module.mts"
import { at, defined, list, rows as array, object } from "./host-values.mts"
import assert from "node:assert/strict"
import { resolve, join } from "node:path"
import { pathToFileURL } from "node:url"
const directory = resolve(at(process.argv, 2))
const { default: G } = await bendModule<BendABI.Game.API>()(pathToFileURL(join(directory, "game.mjs")), [
  "xp_lifecycle",
  "advance_live",
  "start_seed",
  "pickup_turn",
  "solo_team",
  "combat_args",
  "xp_route_rows_at"
])
const { default: Core } = await bendModule<BendABI.CoopCore.API>()(pathToFileURL(join(directory, "coop-core.mjs")), [
  "core_start",
  "core_join",
  "core_step"
])
const pickup = (identity: number, item: BendABI.PickupState.Item, generation = 456): BendABI.PickupState.State => ({
  $: "State",
  identity,
  spatial: { $: "Spatial", x: 7200, y: 7200, age: 0, radius: 6 },
  payload: { $: "Payload", item, generation, active: true }
})
function install<T extends Pick<BendABI.Game.State, "world">>(state: T, rows: BendABI.PickupState.State[]): T {
  const installed = object(
    G.xp_lifecycle(
      list([]),
      list(
        rows.map((state) => ({
          $: "PickupRow",
          outcome: { $: "Outcome", state, reward: { $: "Reward", xp: 0, coins: 0, healing: 0, chests: 0, relics: 0 } }
        }))
      ),
      state.world
    )
  )
  assert.equal(installed.$, "Executed")
  assert.equal(object(installed.outcome).$, "Success")
  return { ...state, world: installed.world }
}
function advance(state: BendABI.Game.State) {
  const packet = G.advance_live(state, 0, 0)
  assert.ok(packet.$ === "Packet")
  return packet.state
}
function fresh() {
  const packet = G.start_seed(0, 0, 12345)
  assert.ok(packet.$ === "Packet")
  return packet.state
}
const rewardCases: [BendABI.PickupState.Item, number, "xp" | "gold", number][] = [
  [{ $: "Xp", amount: 17, accumulator: true }, 1056, "xp", 17],
  [{ $: "Gold", coins: 13 }, 0, "gold", 13]
]
for (const [item, identity, field, expected] of rewardCases) {
  const next = advance(install(fresh(), [pickup(identity, item)]))
  assert.equal(next.run.session[field], expected, "actual reward through storage/query/finish")
  const retired = pickupSnapshot(next.snapshots, identity)
  assert.equal(retired.payload.active, false)
  assert.equal(retired.payload.generation, 456)
  const idle = advance(next)
  assert.equal(idle.run.session[field], expected, "actual next query cannot collect twice")
  if (identity === 1056) {
    assert.ok(retired.payload.item.$ === "Xp")
    assert.equal(retired.payload.item.accumulator, true, "collection tick preserves the old accumulator marker")
    const dormant = pickupSnapshot(idle.snapshots, identity)
    assert.deepEqual(
      dormant.payload,
      { $: "Payload", item: { $: "Xp", amount: 0, accumulator: false }, generation: 0, active: false },
      "next inactive XP pool turn clears amount, marker and generation"
    )
    assert.deepEqual(
      dormant.spatial,
      { ...retired.spatial, age: 0, radius: 0 },
      "idle XP retains position and resets age/radius"
    )
    assert.equal(dormant.identity, retired.identity, "idle XP retains canonical identity")
  } else {
    const unchanged = G.pickup_turn(
      { $: "PickupCall", team: G.solo_team(G.combat_args(next.run, 0, 0, list([]))), advance: true, relic: false },
      retired
    )
    assert.deepEqual(unchanged.state, retired, "inactive non-XP loot is unaffected by XP idle reset")
  }
  const unused = pickupSnapshot(next.snapshots, 1057)
  assert.equal(unused.spatial.age, 0, "first inactive pool query clears bootstrap slot age")
  assert.equal(unused.payload.generation, 0)
}
const dropCases: [BendABI.EnemyCombat.DropKind, BendABI.PickupState.Item][] = [
  [{ $: "XpDrop" }, { $: "Xp", amount: 7, accumulator: false }],
  [{ $: "GoldDrop" }, { $: "Gold", coins: 7 }]
]
for (const [kind, item] of dropCases) {
  const dormant = pickup(1056, { $: "Xp", amount: 0, accumulator: false })
  dormant.payload.active = false
  const rows = G.xp_route_rows_at(
    list([
      {
        $: "EnemyRow",
        credit: { $: "Credit", contactDamage: 0, kills: 1 },
        outcome: {
          $: "Killed",
          enemy: {
            $: "State",
            spatial: { $: "Spatial", x: 7200, y: 7200, age: 1, radius: 6 },
            archetype: 17,
            identity: 0,
            vitals: { $: "Vitals", health: 0, maximum: 1 },
            status: {
              $: "Status",
              slow: { $: "Slow", ticks: 0, frozen: false },
              burn: { $: "Burn", ticks: 0, sourcePlayer: { $: "None" } }
            }
          },
          reward: {
            $: "DeathReward",
            kind,
            amount: 7,
            x: 7200,
            y: 7200,
            archetype: 17,
            identity: 0,
            killer: { $: "Some", value: 0 }
          }
        }
      },
      {
        $: "PickupRow",
        outcome: {
          $: "Outcome",
          state: dormant,
          reward: { $: "Reward", xp: 0, coins: 0, healing: 0, chests: 0, relics: 0 }
        }
      }
    ]),
    66,
    7200,
    7200
  )
  const created = defined(array(rows).find((row) => row.$ === "PickupRow" && row.outcome.state.payload.active))
  assert.ok(created.$ === "PickupRow")
  const createdState = created.outcome.state
  assert.deepEqual(createdState.payload.item, item, "typed death handoff chooses explicit loot payload")
  assert.equal(createdState.payload.generation, 66)
  assert.equal(createdState.spatial.x, 7200)
  assert.equal(createdState.spatial.y, 7200)
}
let state = fresh()
state = { ...state, run: { ...state.run, player: { ...state.run.player, hp: 35 } } }
state = advance(install(state, [pickup(0, { $: "Healing", health: 25 })]))
assert.equal(state.run.player.hp, 60, "non-XP healing uses explicit reward and personal health")
const held = G.pickup_turn(
  { $: "PickupCall", team: G.solo_team(G.combat_args(fresh().run, 0, 0, list([]))), advance: false, relic: false },
  { ...pickup(0, { $: "Gold", coins: 13 }), spatial: { $: "Spatial", x: 7200, y: 7200, age: 19, radius: 6 } }
)
assert.equal(held.state.spatial.age, 19, "rejected fresh enemy birth holds occupied loot age")
assert.equal(held.reward.coins, 0, "rejected fresh enemy birth cannot collect occupied loot")
let coop = Core.core_start(0, 0, 12345)
assert.ok(coop.$ === "CorePacket")
coop = Core.core_join(coop.state, 0, 0, 0)
assert.ok(coop.$ === "CorePacket")
coop = Core.core_step(install(coop.state, [pickup(1056, { $: "Xp", amount: 17, accumulator: false })]), 0, 0, 0, 0)
assert.ok(coop.$ === "CorePacket")
assert.equal(coop.state.shared.xp, 17, "co-op reduces collected XP once across both personal views")
coop = Core.core_step(coop.state, 0, 0, 0, 0)
assert.ok(coop.$ === "CorePacket")
assert.equal(coop.state.shared.xp, 17, "co-op persistent pool cannot pay twice")
console.log(
  "PICKUP WIRING PASS: actual storage/query rewards, one-time collection, healing, deferred occupied slot, co-op allocation"
)

function pickupSnapshot(snapshots: BendList<BendABI.Game.Snapshot>, identity: number) {
  const snapshot = defined(
    array(snapshots).find((row) => row.$ === "PickupSnapshot" && row.pickup.identity === identity)
  )
  assert.ok(snapshot.$ === "PickupSnapshot")
  return snapshot.pickup
}
