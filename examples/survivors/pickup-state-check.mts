import { bendModule } from "../bend-module.mts"
import { at, list, rows as array, object, array as parseArray } from "./host-values.mts"
import assert from "node:assert/strict"
import { resolve, join } from "node:path"
import { pathToFileURL } from "node:url"

const directory = resolve(at(process.argv, 2))
const [{ default: Pickup }, { default: Pool }, { default: Encoder }] = await Promise.all([
  bendModule<BendABI.PickupState.API>()(pathToFileURL(join(directory, "pickup-state.mjs")), ["step"]),
  bendModule<BendABI.PickupXpPool.API>()(pathToFileURL(join(directory, "pickup-xp-pool.mjs")), ["route"]),
  bendModule<BendABI.PickupEncoder.API>()(pathToFileURL(join(directory, "pickup-encoder.mjs")), ["encode"])
])
const xp = (
  slot: number,
  amount: number,
  generation: number,
  x: number,
  { active = true, accumulator = false, age = 3 } = {}
): BendABI.PickupState.State => ({
  $: "State",
  identity: slot,
  spatial: { $: "Spatial", x, y: 7200, age, radius: active ? 6 : 0 },
  payload: { $: "Payload", item: { $: "Xp", amount, accumulator }, generation, active }
})
const drop = (amount: number, x = 7200): BendABI.PickupXpPool.Drop => ({ $: "Drop", amount, x, y: 7200 })

const active = xp(1056, 17, 456, 7200, { accumulator: true })
const encoded = object(at(parseArray(JSON.parse(Encoder.encode(list([active]))), object), 0))
assert.deepEqual(encoded.item, { kind: "xp", amount: 17, accumulator: true })
assert.equal(encoded.generation, 456)
assert.equal(Object.hasOwn(encoded, "hp"), false)
assert.equal(Object.hasOwn(encoded, "maxHp"), false)
const taken = Pickup.step(true, active)
assert.deepEqual(taken.reward, { $: "Reward", xp: 17, coins: 0, healing: 0, chests: 0, relics: 0 })
assert.equal(taken.state.payload.active, false)
assert.equal(taken.state.payload.item.$, "Xp")
if (taken.state.payload.item.$ !== "Xp") throw Error("XP changed kind")
assert.equal(taken.state.payload.item.amount, 0)
assert.equal(taken.state.payload.item.accumulator, true)
assert.equal(taken.state.payload.generation, 456)
assert.deepEqual(taken.state.spatial, { $: "Spatial", x: 7200, y: 7200, age: 0, radius: 0 })
assert.deepEqual(
  Pickup.step(true, taken.state),
  { $: "Outcome", state: taken.state, reward: { $: "Reward", xp: 0, coins: 0, healing: 0, chests: 0, relics: 0 } },
  "inactive loot cannot pay twice"
)
assert.equal(Pickup.step(false, active).state.spatial.age, 4)

const rewardCases: [BendABI.PickupState.Item, Omit<BendABI.PickupState.Reward, "$">][] = [
  [
    { $: "Gold", coins: 6 },
    { xp: 0, coins: 6, healing: 0, chests: 0, relics: 0 }
  ],
  [
    { $: "Healing", health: 25 },
    { xp: 0, coins: 0, healing: 25, chests: 0, relics: 0 }
  ],
  [{ $: "Chest" }, { xp: 0, coins: 0, healing: 0, chests: 1, relics: 0 }],
  [
    { $: "Relic", stage: 3 },
    { xp: 50, coins: 75, healing: 0, chests: 0, relics: 1 }
  ]
]
for (const [item, expected] of rewardCases) {
  const state = { ...active, payload: { ...active.payload, item } }
  assert.deepEqual(Pickup.step(true, state).reward, { $: "Reward", ...expected })
}

// The lowest free slot is allocated first. Overflow preserves the selected
// existing accumulator's generation/position and marks its contained XP red.
let rows = [xp(1056, 9, 21, 8000), xp(1057, 0, 7, 7000, { active: false }), xp(1058, 5, 31, 7300)]
let routed = array(Pool.route(list([drop(2, 7100), drop(6, 7200)]), list(rows), 99, 7200, 7200))
assert.deepEqual(
  routed.map((row) => {
    assert.equal(row.payload.item.$, "Xp")
    if (row.payload.item.$ !== "Xp") throw Error("XP changed kind")
    return row.payload.item.amount
  }),
  [15, 2, 5]
)
assert.equal(at(routed, 0).payload.generation, 21)
assert.equal(xpItem(at(routed, 0)).accumulator, true)
assert.equal(at(routed, 0).spatial.x, 8000)
assert.equal(at(routed, 1).payload.generation, 99)
assert.equal(at(routed, 1).spatial.x, 7100)

// A marked pile wins over a farther ordinary pile. Equal-distance unmarked
// piles keep the first observed candidate, making ownership/order observable.
rows = [xp(1056, 5, 11, 7300, { accumulator: true }), xp(1057, 8, 12, 9000)]
routed = array(Pool.route(list([drop(3)]), list(rows), 100, 7200, 7200))
assert.deepEqual(
  routed.map((row) => {
    assert.equal(row.payload.item.$, "Xp")
    if (row.payload.item.$ !== "Xp") throw Error("XP changed kind")
    return row.payload.item.amount
  }),
  [8, 8]
)
rows = [xp(1056, 5, 11, 7100), xp(1057, 8, 12, 7300)]
routed = array(Pool.route(list([drop(3)]), list(rows), 100, 7200, 7200))
assert.deepEqual(
  routed.map((row) => {
    assert.equal(row.payload.item.$, "Xp")
    if (row.payload.item.$ !== "Xp") throw Error("XP changed kind")
    return row.payload.item.amount
  }),
  [8, 8]
)
assert.equal(xpItem(at(routed, 0)).accumulator, true)

// An all-free pool selects the first newly allocated pile for excess drops;
// ordinary unsigned arithmetic, including wraparound, remains explicit.
rows = [xp(1056, 0, 2, 7000, { active: false })]
routed = array(Pool.route(list([drop(0xffffffff), drop(2)]), list(rows), 77, 7200, 7200))
assert.equal(xpItem(at(routed, 0)).amount, 1)
assert.equal(at(routed, 0).payload.generation, 77)
assert.equal(xpItem(at(routed, 0)).accumulator, true)
console.log("PICKUP STATE PASS: exact rewards, no duplicate collection, generation, stable overflow and unsigned merge")

function xpItem(state: BendABI.PickupState.State) {
  if (state.payload.item.$ !== "Xp") throw Error("XP changed kind")
  return state.payload.item
}
