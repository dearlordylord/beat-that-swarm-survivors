import assert from "node:assert/strict"
import test from "node:test"
import {
  parseCoopCombatPredictionScene,
  parseCoopHitJournalState,
  parseCoopSessionReceipt,
  parseCoopConnectionSignal
} from "../examples/survivors/bend-codecs.generated.mts"
import { list } from "../examples/survivors/host-values.mts"

const scene = {
  $: "Scene",
  own: 0,
  players: { $: "Nil" },
  snapshots: { $: "Nil" },
  births: { $: "Item", key: 1, value: 2 },
  directions: { $: "Directions", x0: 0, y0: 0, x1: 0, y1: 0 },
  contacts: { $: "Nil" },
  tick: 3,
  diagnostics: false
}
await test("constructs nested Bend ADTs and rejects malformed children", () => {
  assert.deepEqual(parseCoopCombatPredictionScene(scene), scene)
  assert.notEqual(parseCoopCombatPredictionScene(scene), scene)
  assert.throws(
    () => parseCoopCombatPredictionScene({ ...scene, births: { $: "Item", key: 1, value: "2" } }),
    TypeError
  )
  assert.throws(
    () => parseCoopCombatPredictionScene({ ...scene, players: { $: "Con", head: {}, tail: { $: "Nil" } } }),
    TypeError
  )
  assert.throws(
    () => parseCoopCombatPredictionScene({ ...scene, directions: { ...scene.directions, x0: Infinity } }),
    TypeError
  )
  assert.throws(() => parseCoopCombatPredictionScene({ ...scene, contacts: { $: "Wrong" } }), TypeError)
})
await test("rejects wrong constructors, missing fields and primitive substitutions", () => {
  const receipt = { $: "Receipt", seq: 1, worldTick: 2, x: 0, y: 1, applied: true }
  assert.deepEqual(parseCoopSessionReceipt(receipt), receipt)
  assert.throws(() => parseCoopSessionReceipt({ ...receipt, applied: 1 }), TypeError)
  assert.throws(() => parseCoopSessionReceipt({ $: "Receipt" }), TypeError)
  assert.deepEqual(parseCoopConnectionSignal({ $: "Lost", ignored: true }), { $: "Lost" })
  assert.throws(() => parseCoopConnectionSignal({ $: "Unknown" }), TypeError)
})
await test("parses long linked lists without recursive list traversal", () => {
  const event = {
    $: "HitEvent",
    id: "event",
    tick: 1,
    kind: 0,
    shotId: "shot",
    shotSeed: 1,
    targetSeed: 2,
    targetGeneration: 0,
    fraction: 0.5,
    impactX: 0,
    impactY: 0,
    targetAtImpactX: 0,
    targetAtImpactY: 0,
    radius: 1,
    outcome: 0
  }
  const state = {
    $: "State",
    epoch: 1,
    now: 2,
    events: list(Array.from({ length: 25000 }, () => event)),
    overflow: 0,
    expired: 0
  }
  const parsed = parseCoopHitJournalState(state)
  let count = 0
  for (let row = parsed.events; row.$ === "Con"; row = row.tail) count++
  assert.equal(count, 25000)
  assert.throws(() => parseCoopHitJournalState({ ...state, events: { $: "Con", head: event, tail: null } }), TypeError)
})
