import { parseFrame, parseCoopFrame } from "./frame.mts"
import { bendModule } from "../bend-module.mts"
import { at, some, object } from "./host-values.mts"
// Exercise the production result/observation boundary through real transitions.
import assert from "node:assert/strict"
import { resolve, join } from "node:path"
import { pathToFileURL } from "node:url"
const directory = resolve(at(process.argv, 2))
const [{ default: Game }, { default: GameEncoder }, { default: Core }, { default: CoopEncoder }] = await Promise.all([
  bendModule<BendABI.Game.API>()(pathToFileURL(join(directory, "game.mjs")), [
    "start_seed",
    "advance",
    "observe",
    "seeded_packet"
  ]),
  bendModule<BendABI.GameEncoder.API>()(pathToFileURL(join(directory, "game-encoder.mjs")), ["observe"]),
  bendModule<BendABI.CoopCore.API>()(pathToFileURL(join(directory, "coop-core.mjs")), [
    "core_start",
    "core_join",
    "core_observe",
    "core_step"
  ]),
  bendModule<BendABI.CoopEncoder.API>()(pathToFileURL(join(directory, "coop-encoder.mjs")), ["encode"])
])
function gamePacket(packet: BendABI.Game.Packet) {
  assert.ok(packet.$ === "Packet")
  assert.equal(Object.hasOwn(packet, "frame"), false)
  return packet
}
function corePacket(packet: BendABI.CoopCore.CorePacket) {
  assert.ok(packet.$ === "CorePacket")
  assert.equal(Object.hasOwn(packet, "frame"), false)
  return packet
}
const runtimeGame = object(object(await import(pathToFileURL(join(directory, "game.mjs")).href)).default)
assert.equal(
  Object.keys(runtimeGame).some((name) => name.endsWith("_quiet")),
  false,
  "one typed simulation API replaces quiet variants"
)
let packet = gamePacket(Game.start_seed(0, 0, 12345))
let observed = GameEncoder.observe(packet.state)
assert.deepEqual(observed.state, packet.state, "observation preserves owned world")
let frame = parseFrame(JSON.parse(observed.frame))
assert.equal(frame.tick, 0)
const raw = Game.observe(packet.state)
assert.deepEqual(raw.state, packet.state)
assert.equal(raw.observation.run.session.tick, 0)
assert.equal(Object.hasOwn(raw, "frame"), false)
assert.equal(frame.hp, packet.state.run.player.hp)
packet = gamePacket(Game.advance(observed.state, 1, 0))
observed = GameEncoder.observe(packet.state)
frame = parseFrame(JSON.parse(observed.frame))
assert.equal(frame.tick, 1)
assert.equal(frame.px, packet.state.run.player.px)
assert.equal(Object.hasOwn(runtimeGame, "observed_packet"), false)
let core = corePacket(Core.core_start(0, 0, 100))
assert.equal(core.observation.$, "NoObservation")
assert.equal(CoopEncoder.encode(core.observation).$, "None")
core = corePacket(Core.core_join(core.state, 1, 0, 0))
const beforeView = core.state
const view = corePacket(Core.core_observe(beforeView, 1))
assert.equal(view.observation.$, "ViewObservation")
assert.deepEqual(view.state, beforeView, "co-op observation preserves world")
const encoded = CoopEncoder.encode(view.observation)
assert.ok(encoded.$ === "Some")
const coopFrame = parseCoopFrame(JSON.parse(encoded.value))
assert.equal(coopFrame.ownPlayerId, 1)
assert.equal(coopFrame.players.length, 2)
assert.equal(coopFrame.combatForecast.$, "Scene")
const rejected = Core.core_join(view.state, 0, 0, 0)
assert.ok(rejected.$ === "CoreRejected")
assert.deepEqual(rejected.state, view.state, "rejection retains state")
assert.equal(Object.hasOwn(rejected, "frame"), false)
const step = corePacket(Core.core_step(rejected.state, 1, 0, 0, 1))
assert.ok(step.observation.$ === "StepObservation")
assert.equal(step.observation.advanced, true)
assert.equal(step.observation.tick, 1)
const stepFrame = object(JSON.parse(some(CoopEncoder.encode(step.observation))))
assert.equal(stepFrame.advanced, true)
assert.equal(stepFrame.tick, 1)
assert.deepEqual(stepFrame.contacts, step.observation.contacts)
const pausedState = { ...step.state, shared: { ...step.state.shared, phase: 1 } }
const paused = corePacket(Core.core_step(pausedState, 1, 0, 0, 1))
assert.ok(paused.observation.$ === "StepObservation")
assert.equal(paused.observation.advanced, false)
assert.deepEqual(paused.state, pausedState)
assert.deepEqual(JSON.parse(some(CoopEncoder.encode(paused.observation))), { tick: 1, phase: 1, advanced: false })
assert.deepEqual(
  Game.seeded_packet({ $: "Failed", error: "fixture" }, 1),
  { $: "Failed", error: "fixture" },
  "failure propagates without encoding"
)
console.log("TYPED RESULTS PASS: solo/co-op, observations, steps, rejection, failure")
