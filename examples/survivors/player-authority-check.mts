import { bendModule } from "../bend-module.mts"
import { at, list, rows as array, some, object } from "./host-values.mts"
// Real solo/co-op transitions plus a focused personal-outcome boundary check.
import assert from "node:assert/strict"
import { resolve, join } from "node:path"
import { pathToFileURL } from "node:url"

const directory = resolve(at(process.argv, 2))
const [{ default: Game }, { default: Core }, { default: Encoder }] = await Promise.all([
  bendModule<BendABI.Game.API>()(pathToFileURL(join(directory, "game.mjs")), [
    "start_seed",
    "advance",
    "living_views",
    "effect_players",
    "enemy_effects_indexed",
    "finish_personal_tick"
  ]),
  bendModule<BendABI.CoopCore.API>()(pathToFileURL(join(directory, "coop-core.mjs")), [
    "core_observe",
    "save_players",
    "core_start",
    "core_join",
    "core_step",
    "core_choose",
    "player_views"
  ]),
  bendModule<BendABI.CoopEncoder.API>()(pathToFileURL(join(directory, "coop-encoder.mjs")), ["encode"])
])
const view = (state: BendABI.CoopCore.CoreState, id = 0) => {
  const packet = Core.core_observe(state, id)
  assert.ok(packet.$ === "CorePacket")
  assert.ok(packet.observation.$ === "ViewObservation")
  return packet.observation
}
function replacePlayers(state: BendABI.CoopCore.CoreState, players: BendABI.GameComponents.PlayerRecord[]) {
  return { ...state, world: Core.save_players(state.refs, list(players), state.world) }
}

let solo = Game.start_seed(0, 0, 12345)
assert.ok(solo.$ === "Packet")
assert.equal(solo.state.run.session.$, "Session")
assert.equal(solo.state.run.player.$, "PlayerState")
solo = Game.advance(solo.state, 1, 0)
assert.ok(solo.$ === "Packet")
assert.equal(solo.state.run.session.tick, 1)

let packet = Core.core_start(0, 0, 12345)
assert.ok(packet.$ === "CorePacket")
packet = Core.core_join(packet.state, 1, 0, 0)
assert.ok(packet.$ === "CorePacket")
let state = packet.state
assert.equal(state.shared.$, "Session")
for (const personalFact of ["hp", "px", "weapons", "meta", "revivals"]) {
  assert.equal(Object.hasOwn(state.shared, personalFact), false)
}
let observed = view(state)
let players = array(observed.players)
assert.equal(players.length, 2)
for (const record of players) {
  assert.equal(record.$, "PlayerRecord")
  assert.equal(record.player.$, "PlayerState")
  assert.equal(Object.hasOwn(record, "run"), false)
  for (const sharedFact of ["tick", "xp", "level", "gold", "seed", "mode"]) {
    assert.equal(Object.hasOwn(record.player, sharedFact), false)
  }
}
for (let tick = 1; tick <= 3; tick += 1) {
  packet = Core.core_step(state, 1, 0, 0, 1)
  assert.ok(packet.$ === "CorePacket")
  state = packet.state
  assert.equal(state.shared.tick, tick)
}
observed = view(state, 1)
assert.equal(observed.forecast.tick, state.shared.tick, "forecast clock comes explicitly from the session")
for (const snapshot of array(observed.forecast.players)) {
  assert.equal(snapshot.$, "PlayerSnapshot")
  assert.equal(snapshot.run.session.tick, state.shared.tick)
}

// Reward decisions mutate personal equipment or shared gold through one owner.
state = {
  ...state,
  shared: { ...state.shared, phase: 2 },
  round: 7,
  required: list([0, 1]),
  offers: list(
    [0, 1].map((id) => ({ $: "PlayerOffers", id, offers: list([{ $: "Offer", kind: 4, id: 0, level: 50 }]) }))
  )
}
const startingGold = state.shared.gold
packet = Core.core_choose(state, 0, 7, 0)
assert.ok(packet.$ === "CorePacket")
assert.equal(packet.state.shared.gold, startingGold + 50)
const duplicate = Core.core_choose(packet.state, 0, 7, 0)
assert.ok(duplicate.$ === "CoreRejected")
assert.deepEqual(duplicate.state, packet.state)
packet = Core.core_choose(duplicate.state, 1, 7, 0)
assert.ok(packet.$ === "CorePacket")
assert.equal(packet.state.shared.gold, startingGold + 100)
assert.equal(packet.state.shared.phase, 0)
state = packet.state

// The spectator camera follows a living player without changing either owner.
players = array(view(state).players).map((record) => ({
  ...record,
  player: {
    ...record.player,
    hp: record.id === 0 ? 0 : 40,
    px: record.id === 0 ? 100 : 200,
    py: record.id === 0 ? 120 : 220
  }
}))
state = replacePlayers(state, players)
observed = view(state, 0)
assert.equal(observed.game.run.player.hp, 0)
assert.equal(observed.game.run.player.px, 200)
assert.equal(observed.game.run.player.py, 220)
assert.deepEqual(
  array(observed.players),
  players,
  "spectator observation does not overwrite authoritative player coordinates"
)

// Disconnect eligibility does not spoof health or discard an in-flight owner.
players = players.map((record) => ({
  ...record,
  connected: record.id === 0,
  player: { ...record.player, hp: record.id === 0 ? 30 : 40 }
}))
const views = array(Core.player_views(state.shared, 0, 0, 0, 0, list(players)))
assert.equal(views.length, 2)
assert.equal(at(views, 1).eligible, false)
assert.equal(at(views, 1).run.player.hp, 40)
assert.deepEqual(
  array(Game.living_views(list(views))).map((row) => row.id),
  [0]
)
assert.equal(
  array(Game.effect_players(list(views))).length,
  2,
  "existing projectile owners retain their actual effect inputs"
)

// A disconnected guest's existing burn keeps its real statistics and credit.
const burnPlayers = players.map((record) => ({
  ...record,
  player: { ...record.player, arcana: record.id === 1 ? 7 : 0 }
}))
const burnViews = Core.player_views({ ...state.shared, tick: 299 }, 0, 0, 0, 0, list(burnPlayers))
const burningEnemy: BendABI.EnemyCombat.State = {
  $: "State",
  spatial: { $: "Spatial", x: 1000, y: 1000, age: 90, radius: 8 },
  archetype: 1,
  identity: 77,
  vitals: { $: "Vitals", health: 3, maximum: 100 },
  status: {
    $: "Status",
    slow: { $: "Slow", ticks: 0, frozen: false },
    burn: { $: "Burn", ticks: 120, sourcePlayer: { $: "Some", value: 1 } }
  }
}
const burned = Game.enemy_effects_indexed(Game.effect_players(burnViews), 1000, 1000, burningEnemy, list([]), {
  $: "Empty"
})
assert.ok(burned.$ === "Killed", "retained guest arcana applies its four burn damage")
assert.deepEqual(burned.reward.killer, { $: "Some", value: 1 }, "disconnected burn retains real owner credit")
assert.deepEqual(burned.enemy.status.burn, { $: "Burn", ticks: 119, sourcePlayer: { $: "Some", value: 1 } })

// Personal outcome owns health/invulnerability only, with no fake XP or revival.
const personalRun = {
  ...observed.game.run,
  session: { ...state.shared, tick: 1 },
  player: { ...at(players, 0).player, hp: 1, revivals: 2, invuln: 0 }
}
const outcome = Game.finish_personal_tick(personalRun, {
  $: "Totals",
  hit: 1,
  xp: 999,
  gold: 999,
  heal: 0,
  chest: 1,
  kills: 0,
  snapshots: list([]),
  relic: 1
})
assert.equal(outcome.$, "PlayerState")
assert.equal(outcome.hp, 0)
assert.equal(outcome.invuln, 45)
assert.equal(outcome.revivals, 2)
assert.equal(Object.hasOwn(outcome, "xp"), false)
assert.equal(Object.hasOwn(outcome, "gold"), false)

const frame = object(JSON.parse(some(Encoder.encode(view(state, 0)))))
assert.equal(frame.ownPlayerId, 0)
assert.equal(object(frame.combatForecast).$, "Scene")
assert.equal(Core.core_observe(state, 99).$, "CoreRejected")
console.log("PLAYER AUTHORITY PASS: solo/co-op, rewards, spectator, eligibility, scoped outcomes")
