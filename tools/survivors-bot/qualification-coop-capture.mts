import assert from "node:assert/strict"
import { writeFileSync } from "node:fs"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
import { bendModule } from "../../examples/bend-module.mts"
import { at, list, rows as array, some } from "../../examples/survivors/host-values.mts"

const [corePath, output, encoderPath] = process.argv.slice(2)
assert.ok(corePath && output, "usage: qualification-coop-capture.mts CORE.mjs OUTPUT.json [ENCODER.mjs]")
const coreUrl = pathToFileURL(resolve(corePath))
const [{ default: Core }, { default: Encoder }] = await Promise.all([
  bendModule<BendABI.CoopCore.API>()(coreUrl, [
    "load_players",
    "core_observe",
    "core_start",
    "core_join",
    "core_choose",
    "core_step",
    "core_disconnect"
  ]),
  bendModule<BendABI.CoopEncoder.API>()(
    encoderPath ? pathToFileURL(resolve(encoderPath)) : new URL("coop-encoder.mjs", coreUrl),
    ["encode"]
  )
])
interface Checkpoint {
  label: string
  tick: number
  shared: BendABI.RunState.Session
  players: BendABI.GameComponents.PlayerRecord[]
  refs: BendABI.CoopCore.PlayerRef[]
  frame: unknown
  physical: BendABI.CoopCore.CoreState
}
const checkpoints: Checkpoint[] = []
function state(packet: BendABI.CoopCore.CorePacket) {
  assert.ok(packet.$ === "CorePacket", "actual Core transition must succeed")
  return packet.state
}
function capture(label: string, current: BendABI.CoopCore.CoreState) {
  const loaded = Core.load_players(current.refs, list([]), current.world)
  current = { ...current, world: loaded.fst }
  const players = array(loaded.snd)
  assert.equal(players.length, 2)
  for (const player of players) assert.equal(player.$, "PlayerRecord")
  const observed = Core.core_observe(current, 0)
  current = state(observed)
  assert.ok(observed.$ === "CorePacket" && observed.observation.$ === "ViewObservation")
  const frame: unknown = JSON.parse(some(Encoder.encode(observed.observation)))
  // Keep the complete physical player column, allocator, clocks and stamps.
  checkpoints.push(
    structuredClone({
      label,
      tick: current.shared.tick,
      shared: current.shared,
      players,
      refs: array(current.refs),
      frame,
      physical: current
    })
  )
  return current
}
let current = state(Core.core_start(0, 0, 100))
current = state(Core.core_join(current, 1, 0, 0))
current = capture("joined", current)
for (let step = 0; step < 1200; step++) {
  if (current.shared.phase === 1 || current.shared.phase === 2) {
    for (const id of array(current.required)) current = state(Core.core_choose(current, id, current.round, 0))
  } else if (current.shared.phase === 0) {
    const dx = Math.floor(step / 120) % 2 ? -1 : 1
    current = state(Core.core_step(current, dx, 0, 0, dx))
  } else break
  if ([119, 599, 1199].includes(step)) current = capture("step-" + (step + 1), current)
}
current = capture("before-disconnect", current)
current = state(Core.core_disconnect(current, 1))
current = capture("guest-disconnected", current)
const last = at(checkpoints, checkpoints.length - 1)
assert.equal(last.players.find((player) => player.id === 1)?.connected, false)
writeFileSync(output, JSON.stringify({ scenario: "public-coop-seed100-1200", rows: checkpoints }) + "\n")
console.log(
  JSON.stringify({
    status: "passed",
    checkpoints: checkpoints.length,
    tick: current.shared.tick,
    playerIds: last.players.map((player) => player.id),
    actualPlayerColumn: true
  })
)
