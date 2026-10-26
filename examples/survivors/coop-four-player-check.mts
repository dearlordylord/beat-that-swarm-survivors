import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
import { bendModule } from "../bend-module.mts"
import { defined, list, rows } from "./host-values.mts"
const directory = resolve(defined(process.argv[2]))
const url = (name: string) => pathToFileURL(resolve(directory, `${name}.mjs`))
const [{ default: Core }, { default: Lobby }, { default: Session }, { default: Queue }] = await Promise.all([
  bendModule<BendABI.CoopCore.API>()(url("coop-core"), [
    "core_start",
    "core_attach_player",
    "core_network_observe",
    "core_step_players"
  ]),
  bendModule<BendABI.CoopLobby.API>()(url("coop-lobby"), [
    "fresh",
    "update",
    "can_start",
    "start",
    "running",
    "admit",
    "seats",
    "leave",
    "pause",
    "input_epoch",
    "can_configure"
  ]),
  bendModule<BendABI.CoopSession.API>()(url("coop-session"), ["fresh", "receive_peer"]),
  bendModule<BendABI.CoopInputQueue.API>()(url("coop-input-queue"), ["fresh", "push_active"])
])
const first = Core.core_start(0, 0, 12345)
if (first.$ !== "CorePacket") throw Error(first.message)
let state = first.state
for (const id of [1, 2, 3]) {
  const joined = Core.core_attach_player(state, id, id, 0, id, 16777215)
  if (joined.$ !== "CorePacket") throw Error(joined.message)
  state = joined.state
}
const before = Core.core_network_observe(state, 0)
state = before.state
assert.deepEqual(
  rows(before.view.players).map((p) => p.id),
  [0, 1, 2, 3]
)
assert.equal(Core.core_attach_player(state, 4, 0, 0, 0, 16777215).$, "CoreRejected")
const returned = Core.core_attach_player(state, 2, 7, 999, 11, 0)
if (returned.$ !== "CorePacket") throw Error(returned.message)
const rejoined = Core.core_network_observe(returned.state, 2)
assert.deepEqual(rejoined.view.players, before.view.players)
assert.equal(rejoined.view.own, 2)
const moved = Core.core_step_players(
  rejoined.state,
  list([
    { $: "Movement", id: 0, x: 1, y: 0 },
    { $: "Movement", id: 1, x: -1, y: 0 },
    { $: "Movement", id: 2, x: 0, y: 1 },
    { $: "Movement", id: 3, x: 0, y: -1 }
  ])
)
if (moved.$ !== "CorePacket") throw Error(moved.message)
const after = Core.core_network_observe(moved.state, 3)
const previous = rows(before.view.players),
  next = rows(after.view.players)
for (const id of [0, 1, 2, 3]) {
  const a = defined(previous.find((p) => p.id === id)).player
  const b = defined(next.find((p) => p.id === id)).player
  if (id === 0) {
    assert.ok(b.px > a.px)
    assert.equal(b.py, a.py)
  }
  if (id === 1) {
    assert.ok(b.px < a.px)
    assert.equal(b.py, a.py)
  }
  if (id === 2) {
    assert.ok(b.py > a.py)
    assert.equal(b.px, a.px)
  }
  if (id === 3) {
    assert.ok(b.py < a.py)
    assert.equal(b.px, a.px)
  }
}
let lobby = Lobby.fresh(0)
assert.equal(Lobby.can_configure(lobby, 1), true)
assert.equal(Lobby.can_configure(lobby, 0), false)
assert.equal(Lobby.can_configure(lobby, 4), false)
assert.equal(Lobby.can_start(lobby), false)
for (const player of [1, 2, 3])
  lobby = Lobby.update(lobby, { $: "Seat", player, character: player, ready: true, connected: true })
assert.equal(Lobby.can_start(lobby), true)
lobby = Lobby.start(lobby)
assert.equal(Lobby.can_configure(lobby, 1), false)
assert.equal(Lobby.running(lobby), true)
assert.equal(Lobby.admit(lobby, 4), false)
lobby = Lobby.update(lobby, { $: "Seat", player: 2, character: 2, ready: false, connected: false })
assert.equal(Lobby.running(lobby), false)
assert.equal(Lobby.admit(lobby, 2), true)
const reserved = Lobby.leave(lobby, 2)
assert.deepEqual(Lobby.seats(reserved), Lobby.seats(lobby))
const waiting = Lobby.update(
  Lobby.update(Lobby.fresh(0), { $: "Seat", player: 1, character: 1, ready: true, connected: true }),
  { $: "Seat", player: 2, character: 2, ready: false, connected: false }
)
assert.equal(Lobby.can_start(waiting), false)
assert.equal(Lobby.can_start(Lobby.leave(waiting, 2)), true)
const oldEpoch = Lobby.input_epoch(lobby)
const rewardEpoch = Lobby.pause(lobby)
const reconnectEpoch = Lobby.pause(rewardEpoch)
assert.notEqual(Lobby.input_epoch(reconnectEpoch), oldEpoch)
const pausedQueue = Queue.fresh(Lobby.input_epoch(reconnectEpoch), 20)
assert.equal(Queue.push_active(pausedQueue, 0, true, oldEpoch, 10, 25, 2, 1).accepted, false)
assert.equal(Queue.push_active(pausedQueue, 0, true, Lobby.input_epoch(reconnectEpoch), 11, 25, 2, 1).accepted, true)
const command: BendABI.CoopSession.Command = {
  $: "Command",
  session: 7,
  player: 2,
  seq: 1,
  intendedTick: 1,
  action: { $: "MovementTick", round: 0, x: 2, y: 1 }
}
assert.equal(Session.receive_peer(Session.fresh(7), 2, command).accepted, true)
assert.equal(Session.receive_peer(Session.fresh(7), 3, command).accepted, false)
console.log(
  "PASS four-player allocation, independent movement, own views, rejoin, capacity, lobby start/pause and peer command isolation"
)
