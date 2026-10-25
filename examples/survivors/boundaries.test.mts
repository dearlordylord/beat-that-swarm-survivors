import assert from "node:assert/strict"
import { test } from "node:test"
import { parseBody, parseCoopFrame, parseFrame } from "./frame.mts"
import type { Frame } from "./frame.mts"
import { parseCoreView, parseSnapshotEnvelope, parseWorkerReply, parseWorkerRequest } from "./coop-boundary.mts"

const frame: Frame = {
  worldSize: 100,
  worldMargin: 5,
  relicCollected: 0,
  relicX: 10,
  relicY: 20,
  runLength: 600,
  enemiesKilled: [],
  mode: 0,
  rerolls: 0,
  banishes: 0,
  skips: 0,
  stage: 0,
  arcana: 0,
  revivalsUsed: 0,
  bossesKilled: 0,
  phase: 0,
  tick: 1,
  px: 20,
  py: 30,
  hp: 70,
  maxHp: 70,
  xp: 0,
  xpNeed: 20,
  level: 1,
  kills: 0,
  gold: 0,
  character: 0,
  weapons: [0],
  passives: [],
  offers: [{ kind: 0, id: 0, level: 1 }],
  bodies: [[1, 2, 0, 0, 10, 10, 0, 12, 4]]
}
const scene: BendABI.CoopCombatPrediction.Scene = {
  $: "Scene",
  own: 1,
  players: { $: "Nil" },
  snapshots: { $: "Nil" },
  births: { $: "Empty" },
  directions: { $: "Directions", x0: 0, y0: 0, x1: 0, y1: 0 },
  contacts: { $: "Nil" },
  tick: 1,
  diagnostics: false
}
const coop = { ...frame, combatForecast: scene, stepDistance: 2, predictionAllowed: true, ownPlayerId: 1 }
const lane = { $: "Lane", lastSeq: 0, inputSeq: 0, appliedSeq: 0, appliedTick: 0, receivedAt: 0, x: 1, y: 1 }
const journal: BendABI.CoopHitJournal.State = {
  $: "State",
  epoch: 0,
  now: 1,
  events: { $: "Nil" },
  overflow: 0,
  expired: 0
}
const envelope = {
  type: "frame",
  connectionVersion: 1,
  token: 2,
  initial: true,
  frame: coop,
  admission: { $: "State", session: 1, clock: 1, host: lane, guest: lane, guestConnected: true, ended: false },
  receipt: { $: "Receipt", seq: 0, worldTick: 1, x: 1, y: 1, applied: false },
  observationSeq: 1,
  contactJournal: journal,
  inputTiming: null
}
await test("round-trips complete observations and leaves game eligibility in Bend", () => {
  assert.deepEqual(parseFrame(frame), frame)
  assert.deepEqual(parseCoopFrame(coop), coop)
  assert.deepEqual(parseSnapshotEnvelope(envelope), envelope)
  assert.equal(parseFrame({ ...frame, hp: 90 }).hp, 90, "shape parser must not implement game HP policy")
  assert.throws(() => parseCoopFrame(frame), TypeError)
})
await test("rejects malformed nested numeric, tuple, ADT and session fields before consuming a snapshot", () => {
  for (const invalid of [
    null,
    [],
    "frame",
    { ...frame, hp: "70" },
    { ...frame, tick: Infinity },
    { ...frame, bodies: [[1, 2]] },
    { ...frame, offers: [{ kind: 0, id: "0", level: 1 }] }
  ])
    assert.throws(() => parseFrame(invalid), TypeError)
  assert.throws(
    () =>
      parseSnapshotEnvelope({
        ...envelope,
        frame: { ...coop, combatForecast: { ...scene, directions: { ...scene.directions, x0: "0" } } }
      }),
    TypeError
  )
  assert.throws(
    () => parseSnapshotEnvelope({ ...envelope, admission: { ...envelope.admission, host: { ...lane, lastSeq: "0" } } }),
    TypeError
  )
  assert.throws(
    () =>
      parseSnapshotEnvelope({
        ...envelope,
        contactJournal: { ...journal, events: { $: "Con", head: {}, tail: { $: "Nil" } } }
      }),
    TypeError
  )
  assert.throws(
    () => parseSnapshotEnvelope({ ...envelope, receipt: { ...envelope.receipt, applied: "false" } }),
    TypeError
  )
})
await test("checks worker messages instead of trusting MessageEvent generic annotations", () => {
  const init = {
    type: "init",
    session: 1,
    seed: 12345,
    runId: "fixture",
    setup: { character: 0, stage: 0, arcana: 0, mode: 0, meta: 0, allowedWeapons: 0 }
  }
  assert.deepEqual(parseWorkerRequest(init), init)
  assert.throws(() => parseWorkerRequest({ ...init, seed: "12345" }), TypeError)
  assert.throws(
    () => parseWorkerRequest({ type: "command", player: 0, text: "x", deliveryId: "1", connectionEpoch: 0 }),
    TypeError
  )
  const reply = { type: "frame", frame: coop, observationSeq: 1, contactJournal: journal, connectionReady: true }
  assert.deepEqual(parseWorkerReply(reply), reply)
  assert.throws(() => parseWorkerReply({ ...reply, frame: { ...coop, hp: "broken" } }), TypeError)
  const diagnostic = {
    type: "error",
    message: "worker failed",
    stack: "original stack",
    connectionEpoch: 0,
    context: { worldTick: 1 }
  }
  assert.deepEqual(parseWorkerReply(diagnostic), diagnostic)
})
await test("accepts reduced Core acknowledgments without inventing a full observation", () => {
  const view = { tick: 1, phase: 0, advanced: true, contacts: { $: "Nil" }, contactsOmitted: 0 }
  assert.deepEqual(parseCoreView(view), view)
  assert.throws(() => parseCoreView({ ...view, advanced: "true" }), TypeError)
  assert.throws(() => parseCoreView({ ...view, contacts: { $: "Con", head: {}, tail: { $: "Nil" } } }), TypeError)
  assert.throws(() => parseFrame(view), TypeError)
})
await test("preserves all serialized Body positions including optional generation and presentation metadata", () => {
  assert.deepEqual(parseBody([1, 2, 0, 0, 10, 10, 0, 12, 4, "generation", 1, 42, 0.45]), [
    1,
    2,
    0,
    0,
    10,
    10,
    0,
    12,
    4,
    "generation",
    1,
    42,
    0.45
  ])
  for (const value of [null, [1], [1, 2, 0, 0, 10, 10, 0, 12, 4, false], [1, 2, 0, 0, 10, 10, 0, 12, 4, "g", "owner"]])
    assert.throws(() => parseBody(value), TypeError)
})
