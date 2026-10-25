// Real emitted Bend ABI and the single untrusted snapshot boundary.
import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
import { bendModule } from "../bend-module.mts"
import { defined, object } from "./host-values.mts"
import { corePacket } from "./coop-fixtures.mts"
import { gameFrame, coreFrame, projectileFrame } from "./observations.mts"
import { admitSnapshot } from "./snapshot-envelope.mts"
const directory = resolve(defined(process.argv[2]))
const url = (name: string) => pathToFileURL(resolve(directory, `${name}.mjs`))
const [{ default: Game }, { default: Core }, { default: Session }, { default: Journal }, { default: Local }] =
  await Promise.all([
    bendModule<BendABI.Game.API>()(url("game"), ["start_seed", "quiet_packet"]),
    bendModule<BendABI.CoopCore.API>()(url("coop-core"), ["core_start", "quiet", "core_observe", "core_clock"]),
    bendModule<BendABI.CoopSession.API>()(url("coop-session"), ["fresh", "receipt_fresh"]),
    bendModule<BendABI.CoopHitJournal.API>()(url("coop-hit-journal"), ["fresh"]),
    bendModule<BendABI.CoopLocalProjectiles.API>()(url("coop-local-projectiles"), ["render_frame", "empty"])
  ])
const solo = Game.start_seed(0, 0, 12345)
if (solo.$ !== "Packet") throw Error(solo.error)
assert.equal(solo.frame.$, "Some")
const frame = defined(gameFrame(solo.frame))
assert.equal(frame.tick, 0)
assert.equal(frame.px, 7200)
assert.ok(Array.isArray(frame.bodies))
const quiet = Game.quiet_packet(solo.state)
if (quiet.$ !== "Packet") throw Error(quiet.error)
assert.equal(gameFrame(quiet.frame), null)
const started = corePacket(Core.core_start(0, 0, 12345))
assert.equal(coreFrame(corePacket(Core.quiet(started.state)).frame), null)
const observed = corePacket(Core.core_observe(started.state, 0))
const coop = defined(coreFrame(observed.frame))
if (!("combatForecast" in coop)) throw Error("Missing display observation")
assert.equal(coop.tick, 0)
assert.equal(coop.players.length, 1)
assert.equal(coop.combatForecast.$, "Scene")
const clock = corePacket(Core.core_clock(observed.state))
assert.deepEqual(coreFrame(clock.frame), {
  tick: 0,
  phase: 0,
  advanced: false,
  contacts: { $: "Nil" },
  contactsOmitted: 0
})
assert.deepEqual(projectileFrame(Local.render_frame(Local.empty(), 1, 0, { $: "Nil" })), {
  shots: [],
  contacts: [],
  corpses: []
})
const envelope = {
  type: "frame",
  connectionVersion: 1,
  token: 7,
  initial: true,
  frame: { ...coop, runId: "fixture" },
  admission: Session.fresh(1),
  receipt: Session.receipt_fresh(),
  observationSeq: 1,
  contactJournal: Journal.fresh(7),
  inputTiming: { worldTick: 0, lastRejected: null }
}
assert.equal(admitSnapshot(envelope), envelope)
function path(row: Record<string, unknown>, ...keys: string[]): Record<string, unknown> {
  for (const key of keys) row = object(row[key])
  return row
}
const corruptions: ((v: Record<string, unknown>) => void)[] = [
  (v) => {
    path(v, "frame").hp = -1
  },
  (v) => {
    path(v, "frame").tick = 0x100000000
  },
  (v) => {
    path(v, "frame").px = Infinity
  },
  (v) => {
    path(v, "frame").bodies = [[0, 0, 0]]
  },
  (v) => {
    path(v, "frame", "combatForecast").$ = "Unknown"
  },
  (v) => {
    delete path(v, "frame", "combatForecast").directions
  },
  (v) => {
    path(v, "contactJournal").events = { $: "Nil", extra: true }
  },
  (v) => {
    path(v, "receipt").applied = 1
  },
  (v) => {
    path(v, "inputTiming").lastRejected = { reason: 1 }
  },
  (v) => {
    path(v, "frame").extra = true
  }
]
for (const corrupt of corruptions) {
  const bad = object(structuredClone(envelope))
  corrupt(bad)
  assert.throws(() => admitSnapshot(bad))
}
const deep = object(structuredClone(envelope))
let tree: unknown = { $: "Empty" }
for (let i = 0; i < 100; i++) tree = { $: "Fork", sample: 0, mask: 1, zero: tree, one: { $: "Empty" } }
path(deep, "frame", "combatForecast").births = tree
assert.throws(() => admitSnapshot(deep), RangeError)
console.log("PASS emitted typed observations: full/quiet/clock, direct projectile render, strict network admission")
