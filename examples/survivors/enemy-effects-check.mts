import { bendModule } from "../bend-module.mts"
import { at } from "./host-values.mts"
import assert from "node:assert/strict"
import { pathToFileURL } from "node:url"
import { resolve } from "node:path"
const { default: E } = await bendModule<BendABI.EnemyEffects.API>()(pathToFileURL(resolve(at(process.argv, 2))), [
  "cool_slow",
  "stronger_slow",
  "burn",
  "cool_burn",
  "stronger_burn"
])
const slow = (ticks: number, frozen = false): BendABI.EnemyEffects.Slow => ({ $: "Slow", ticks, frozen })
const burn = (ticks: number, player: number | null = null): BendABI.EnemyEffects.Burn => ({
  $: "Burn",
  ticks,
  sourcePlayer: player === null ? { $: "None" } : { $: "Some", value: player }
})
assert.deepEqual(E.cool_slow(slow(1, true)), slow(0))
assert.deepEqual(E.stronger_slow(slow(1, true), slow(90)), slow(1, true), "current movement retains freeze")
assert.deepEqual(
  E.stronger_slow(E.cool_slow(slow(1, true)), slow(90)),
  slow(90),
  "cool before fresh merge permits slow next tick"
)
assert.deepEqual(E.cool_slow(slow(90, true)), slow(89, true))
assert.deepEqual(E.stronger_slow(slow(90), slow(30, true)), slow(30, true))
assert.deepEqual(E.stronger_slow(slow(30), slow(90)), slow(90))
assert.deepEqual(E.burn(0, 17), burn(0))
assert.deepEqual(E.burn(30, 0), burn(30, 0), "active player zero remains an explicit owner")
assert.deepEqual(E.cool_burn(burn(1, 17)), burn(0), "expired burn clears source")
assert.deepEqual(E.cool_burn(burn(30, 17)), burn(29, 17))
assert.deepEqual(E.stronger_burn(burn(50, 1), burn(50, 0)), burn(50, 0))
assert.deepEqual(E.stronger_burn(burn(50, 0), burn(50, 1)), burn(50, 0))
assert.deepEqual(E.stronger_burn(burn(51, 1), burn(50, 0)), burn(51, 1))
assert.deepEqual(
  E.stronger_burn(E.cool_burn(burn(51, 1)), burn(50, 0)),
  burn(50, 0),
  "cooling precedes fresh owner tie-break"
)
console.log("PASS explicit slow/freeze and burn duration/source policies")
