import assert from "node:assert/strict"
import { test } from "node:test"
import { parseBody, parseCoopFrame, parseFrame } from "./frame.mts"
import type { Frame } from "./frame.mts"
import { admitSnapshot } from "./snapshot-envelope.mts"

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
  frame: { ...coop, runId: "fixture", coop: true, choicePending: false, roundId: 0, requiredPlayers: [], players: [] },
  admission: { $: "State", session: 1, clock: 1, host: lane, guest: lane, guestConnected: true, ended: false },
  receipt: { $: "Receipt", seq: 0, worldTick: 1, x: 1, y: 1, applied: false },
  observationSeq: 1,
  contactJournal: journal,
  inputTiming: { worldTick: 1, lastRejected: null }
}
await test("round-trips complete observations and leaves game eligibility in Bend", () => {
  assert.deepEqual(parseFrame(frame), frame)
  assert.deepEqual(parseCoopFrame(coop), coop)
  assert.deepEqual(admitSnapshot(envelope), envelope)
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
      admitSnapshot({
        ...envelope,
        frame: { ...envelope.frame, combatForecast: { ...scene, directions: { ...scene.directions, x0: "0" } } }
      }),
    TypeError
  )
  assert.throws(
    () => admitSnapshot({ ...envelope, admission: { ...envelope.admission, host: { ...lane, lastSeq: "0" } } }),
    TypeError
  )
  assert.throws(
    () =>
      admitSnapshot({
        ...envelope,
        contactJournal: { ...journal, events: { $: "Con", head: {}, tail: { $: "Nil" } } }
      }),
    TypeError
  )
  assert.throws(() => admitSnapshot({ ...envelope, receipt: { ...envelope.receipt, applied: "false" } }), TypeError)
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
