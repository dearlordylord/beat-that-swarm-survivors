import assert from "node:assert/strict"
import { test } from "node:test"
import { parseCoopFrame, parseFrame } from "./frame.mts"
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
  enemies: [],
  projectiles: [],
  pickups: [],
  actorOrder: [],
  players: []
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
await test("round-trips complete observations and leaves game eligibility in Bend", () => {
  assert.deepEqual(parseFrame(frame), frame)
  assert.deepEqual(parseCoopFrame(coop), coop)
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
    { ...frame, enemies: [{ identity: 1 }] },
    { ...frame, offers: [{ kind: 0, id: "0", level: 1 }] }
  ])
    assert.throws(() => parseFrame(invalid), TypeError)
})
await test("rejects obsolete presentation snapshots and invalid connection versions", () => {
  for (const connectionVersion of [0, 1, 2, 3])
    assert.throws(() => admitSnapshot({ type: "frame", connectionVersion, frame: coop }), TypeError)
})
const nil = { $: "Nil" } satisfies BendList<never>
const raw: Extract<BendABI.CoopCore.Observation, { $: "ViewObservation" }> = {
  $: "ViewObservation",
  game: {
    $: "Observation",
    presentation: {
      $: "PresentationContext",
      worldSize: 14400,
      worldMargin: 100,
      relicX: 0,
      relicY: 0,
      runLength: 36000
    },
    run: {
      $: "Run",
      session: {
        $: "Session",
        phase: 0,
        tick: 1,
        xp: 0,
        xpNeed: 20,
        level: 1,
        kills: 0,
        gold: 0,
        seed: 1,
        stage: 0,
        bosses: 0,
        mode: 0,
        enemyKinds: nil,
        relicCollected: 0
      },
      player: {
        $: "PlayerState",
        px: 0,
        py: 0,
        hp: 70,
        maxHp: 70,
        character: 0,
        weapons: nil,
        passives: nil,
        invuln: 0,
        arcana: 0,
        meta: 0,
        revivals: 0,
        rerolls: 0,
        banishes: 0,
        skips: 0,
        bannedWeapons: 0,
        bannedPassives: 0
      }
    },
    offers: nil,
    enemies: nil,
    order: nil,
    projectiles: nil,
    pickups: nil
  },
  predictionAllowed: true,
  stepDistance: 2,
  ownPlayerId: 0,
  choicePending: false,
  round: 0,
  required: nil,
  players: nil,
  forecast: scene
}
const envelope = {
  type: "frame",
  connectionVersion: 1,
  token: 2,
  initial: true,
  runId: "fixture",
  frame: raw,
  admission: { $: "State", session: 1, clock: 1, host: lane, guest: lane, guestConnected: true, ended: false },
  receipt: { $: "Receipt", seq: 0, worldTick: 1, x: 1, y: 1, applied: false },
  observationSeq: 1,
  contactJournal: journal,
  inputTiming: { worldTick: 1, lastRejected: null }
}
await test("admits only the complete current raw Data graph at version one", () => {
  assert.equal(admitSnapshot(envelope), envelope)
  for (const version of [0, 2, 3]) assert.throws(() => admitSnapshot({ ...envelope, connectionVersion: version }))
  for (const invalid of [
    { ...raw, extra: true },
    { ...raw, $: "NoObservation" },
    { ...raw, game: { ...raw.game, run: { ...raw.game.run, session: { ...raw.game.run.session, tick: -1 } } } },
    { ...raw, game: { ...raw.game, presentation: { ...raw.game.presentation, worldSize: Infinity } } },
    { ...raw, game: { ...raw.game, pickups: { $: "Con", head: { $: "Body" }, tail: nil } } },
    { ...raw, forecast: { ...scene, directions: { ...scene.directions, x0: "0" } } }
  ])
    assert.throws(() => admitSnapshot({ ...envelope, frame: invalid }), TypeError)
})
