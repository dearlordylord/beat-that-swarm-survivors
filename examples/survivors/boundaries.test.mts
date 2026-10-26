import assert from "node:assert/strict"
import { test } from "node:test"
import { array } from "./host-values.mts"
import { admitSnapshot, snapshotValues, encodeSnapshotValues, decodeSnapshotValues } from "./snapshot-envelope.mts"

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
const envelope: BendABI.CoopNetwork.Snapshot = {
  $: "Snapshot",
  connectionVersion: 1,
  token: 2,
  initial: true,
  runId: "fixture",
  view: {
    $: "NetworkView",
    shared: raw.game.run.session,
    players: {
      $: "Con",
      head: { $: "PlayerRecord", id: 0, player: raw.game.run.player, connected: true, reviveTick: 0 },
      tail: nil
    },
    snapshots: nil,
    own: 0,
    round: 0,
    required: nil,
    offers: nil
  },
  commandAck: 0,
  observationSeq: 1,
  contactJournal: journal,
  inputTiming: { $: "InputTiming", worldTick: 1, lastRejected: { $: "None" } }
}
await test("admits only the current compact Bend contract with exact numeric values", () => {
  assert.deepEqual(decodeSnapshotValues(encodeSnapshotValues(envelope)), envelope)
  assert.deepEqual(admitSnapshot(snapshotValues(envelope)), envelope)
  for (const connectionVersion of [0, 2, 3])
    assert.throws(() => admitSnapshot(snapshotValues({ ...envelope, connectionVersion })))
  for (const invalid of [-1, 2 ** 32, 1.5, NaN, Infinity])
    assert.throws(() => snapshotValues({ ...envelope, commandAck: invalid }))
  for (const value of [0, -0, 0.1, -0.2, Number.MIN_VALUE, 1.0000000000000002, Math.fround(3.4e38)]) {
    const snapshot = structuredClone(envelope)
    if (snapshot.view.players.$ !== "Con") throw Error("player")
    snapshot.view.players.head.player.px = value
    const decoded = decodeSnapshotValues(encodeSnapshotValues(snapshot))
    if (decoded.view.players.$ !== "Con") throw Error("player")
    assert.equal(decoded.view.players.head.player.px, value === 0 ? 0 : value)
  }
  const values = array(snapshotValues(envelope), (value) => value)
  if (!Array.isArray(values)) throw Error("root")
  assert.throws(() => admitSnapshot([...values, 0]))
  assert.throws(() => admitSnapshot(values.slice(1)))
  assert.throws(() => admitSnapshot({ ...envelope, frame: raw }))
})

await test("CBOR ingress rejects malformed values before building unbounded structures", async () => {
  const { encodeCbor, decodeCbor, MAX_CBOR_CONTAINER_LENGTH, MAX_CBOR_DEPTH, MAX_CBOR_TOKENS } =
    await import("./cbor.mts")
  for (const bytes of [
    Uint8Array.of(0x9f, 0xff),
    Uint8Array.of(0xc0, 0x80),
    Uint8Array.of(0xf7),
    Uint8Array.of(0xa2, 0x61, 0x61, 0x00, 0x61, 0x61, 0x01),
    Uint8Array.of(0x61, 0xff),
    Uint8Array.of(0x80, 0x00),
    Uint8Array.of(0x9a, 0xff, 0xff, 0xff, 0xff),
    Uint8Array.of(0x1a, 0x00),
    encodeCbor(Infinity),
    encodeCbor(-Infinity),
    encodeCbor(NaN),
    encodeCbor(2n ** 63n),
    encodeCbor(new Uint8Array([1])),
    encodeCbor("x".repeat(4097))
  ])
    assert.throws(() => decodeCbor(bytes))
  let nested: unknown = 0
  for (let depth = 0; depth <= MAX_CBOR_DEPTH; depth++) nested = [nested]
  assert.throws(() => decodeCbor(encodeCbor(nested)), /depth/)
  assert.throws(
    () => decodeCbor(encodeCbor(Array.from({ length: MAX_CBOR_CONTAINER_LENGTH + 1 }, () => 0))),
    /container/
  )
  const rows = Math.ceil(MAX_CBOR_TOKENS / MAX_CBOR_CONTAINER_LENGTH)
  assert.throws(
    () =>
      decodeCbor(
        encodeCbor(Array.from({ length: rows }, () => Array.from({ length: MAX_CBOR_CONTAINER_LENGTH }, () => 0)))
      ),
    /token/
  )
  const bytes = encodeSnapshotValues(envelope)
  for (let length = 0; length < bytes.byteLength; length++)
    assert.throws(() => decodeSnapshotValues(bytes.subarray(0, length)))
  const valid = array(snapshotValues(envelope), (value) => value)
  if (!Array.isArray(valid)) throw Error("root")
  for (const invalid of [-1, 2 ** 32, 0.5]) {
    const wrong = [...valid]
    wrong[7] = invalid
    assert.throws(() => admitSnapshot(wrong))
  }
})
