import assert from "node:assert/strict"
import { test } from "node:test"
import { admitSnapshot } from "./snapshot-envelope.mts"

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
const lane = { $: "Lane", lastSeq: 0, inputSeq: 0, appliedSeq: 0, appliedTick: 0, receivedAt: 0, x: 1, y: 1 }
const journal: BendABI.CoopHitJournal.State = {
  $: "State",
  epoch: 0,
  now: 1,
  events: { $: "Nil" },
  overflow: 0,
  expired: 0
}
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
