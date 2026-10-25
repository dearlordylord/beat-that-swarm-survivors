import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
import { bendModule } from "../bend-module.mts"
import { defined, list, parseJson } from "./host-values.mts"
import { gameFrame, coreFrame } from "./observations.mts"
import { parseFrame } from "./frame.mts"
const directory = resolve(defined(process.argv[2]))
const url = (name: string) => pathToFileURL(resolve(directory, `${name}.mjs`))
const [{ default: Game }, { default: Encoder }, { default: Core }] = await Promise.all([
  bendModule<BendABI.Game.API>()(url("game"), ["start_seed", "observe", "observation"]),
  bendModule<BendABI.GameEncoder.API>()(url("game-encoder"), ["encode"]),
  bendModule<BendABI.CoopCore.API>()(url("coop-core"), ["core_start", "core_observe", "core_clock"])
])
const packet = Game.start_seed(0, 0, 12345)
if (packet.$ !== "Packet") throw Error(packet.error)
const observed = Game.observe(packet.state)
const spatial = { $: "Spatial", x: 100, y: 200, age: 3, radius: 8 } satisfies BendABI.EnemySpatial.Spatial
const items: BendABI.PickupState.Item[] = [
  { $: "Xp", amount: 7, accumulator: true },
  { $: "Gold", coins: 13 },
  { $: "Healing", health: 17 },
  { $: "Chest" },
  { $: "Relic", stage: 2 }
]
const snapshots: BendABI.Game.Snapshot[] = items.map((item, index) => ({
  $: "PickupSnapshot",
  pickup: {
    $: "State",
    spatial,
    payload: { $: "Payload", item, generation: index + 10, active: true },
    identity: index + 100
  }
}))
snapshots.splice(2, 0, {
  $: "EnemySnapshot",
  enemy: {
    $: "State",
    spatial,
    archetype: 4,
    identity: 21,
    vitals: { $: "Vitals", health: 20, maximum: 40 },
    status: {
      $: "Status",
      slow: { $: "Slow", ticks: 2, frozen: false },
      burn: { $: "Burn", ticks: 3, sourcePlayer: { $: "Some", value: 1 } }
    }
  }
})
snapshots.unshift({
  $: "ProjectileSnapshot",
  projectile: {
    $: "State",
    spatial,
    identity: 31,
    side: { $: "PlayerShot" },
    payload: { $: "ShotPayload", weapon: 11, damage: 5, active: true },
    trajectory: {
      $: "Trajectory",
      vx: 1,
      vy: 2,
      life: 17,
      pierce: 2,
      visited: list([21]),
      weaponOwner: 0,
      logicalSlot: 3,
      sourcePlayer: { $: "Some", value: 1 }
    }
  }
})
const observation = Game.observation(
  { ...observed.observation.run, session: { ...observed.observation.run.session, tick: 20 } },
  observed.observation.offers,
  list(snapshots)
)
const direct = gameFrame(observation)
const encoded = parseFrame(parseJson(Encoder.encode(observation)))
assert.deepEqual(encoded, direct)
assert.deepEqual(
  direct.pickups.map((p) => p.item.kind),
  ["xp", "gold", "healing", "chest", "relic"]
)
assert.equal(direct.actorOrder.length, 7)
assert.equal(direct.projectiles[0]?.lifetime, "1:17:0:3")
assert.equal(direct.enemies[0]?.lifetime, "enemy:21:17")
const started = Core.core_start(0, 0, 12345)
if (started.$ !== "CorePacket") throw Error(started.message)
const view = Core.core_observe(started.state, 0)
if (view.$ !== "CorePacket") throw Error(view.message)
assert.ok(coreFrame(view.observation))
const clock = Core.core_clock(view.state)
if (clock.$ !== "CorePacket") throw Error(clock.message)
assert.equal(clock.observation.$, "StepObservation")
assert.equal(coreFrame({ $: "NoObservation" }), null)
console.log("PASS current raw observation parity: actual encoder, all pickups, actors, ordering, lifetimes, packets")
