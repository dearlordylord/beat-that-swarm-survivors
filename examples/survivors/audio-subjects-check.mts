import assert from "node:assert/strict"
import { mkdtemp, mkdir, copyFile, symlink, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join, resolve } from "node:path"
import { pathToFileURL } from "node:url"
import type { AudioEngine as Audio } from "./audio.mts"
import type { Renderer as Graphics } from "./renderer.mts"
import type { Frame } from "./frame.mts"
import { bendModule } from "../bend-module.mts"
import { gameFrame } from "./observations.mts"
import { parseFrame } from "./frame.mts"
import { defined, list, object, parseJson } from "./host-values.mts"
const directory = resolve(defined(process.argv[2]))
const url = (name: string) => pathToFileURL(join(directory, name + ".mjs")).href
const [{ default: Game }, { default: Encoder }] = await Promise.all([
  bendModule<BendABI.Game.API>()(url("game"), ["start_seed", "observe", "observation"]),
  bendModule<BendABI.GameEncoder.API>()(url("game-encoder"), ["encode"])
])
const packet = Game.start_seed(0, 0, 12345)
if (packet.$ !== "Packet") throw Error(packet.error)
const observed = Game.observe(packet.state)
const spatial = {
  $: "Spatial",
  x: observed.observation.run.player.px,
  y: observed.observation.run.player.py,
  age: 10,
  radius: 8
} satisfies BendABI.EnemySpatial.Spatial
const enemy: BendABI.EnemyCombat.State = {
  $: "State",
  spatial,
  archetype: 1,
  identity: 7,
  vitals: { $: "Vitals", health: 10, maximum: 10 },
  status: {
    $: "Status",
    slow: { $: "Slow", ticks: 0, frozen: false },
    burn: { $: "Burn", ticks: 0, sourcePlayer: { $: "None" } }
  }
}
const items: BendABI.PickupState.Item[] = [
  { $: "Xp", amount: 31, accumulator: false },
  { $: "Gold", coins: 17 },
  { $: "Healing", health: 9 },
  { $: "Chest" },
  { $: "Relic", stage: 2 }
]
const frame = (tick: number, age: number, health = 10): Frame => {
  const snapshots: BendABI.Game.Snapshot[] = [
    { $: "EnemySnapshot", enemy: { ...enemy, spatial: { ...spatial, age }, vitals: { ...enemy.vitals, health } } },
    ...items.map(
      (item, index): BendABI.Game.Snapshot => ({
        $: "PickupSnapshot",
        pickup: {
          $: "State",
          spatial,
          payload: { $: "Payload", item, generation: index + 3, active: true },
          identity: index + 20
        }
      })
    )
  ]
  const observation = Game.observation(
    { ...observed.observation.run, session: { ...observed.observation.run.session, tick } },
    observed.observation.offers,
    list(snapshots)
  )
  const direct = gameFrame(observation)
  const encoded = parseFrame(parseJson(Encoder.encode(observation)))
  assert.deepEqual(encoded, direct)
  return encoded
}
const scratch = await mkdtemp(join(tmpdir(), "survivors-presentation-"))
try {
  await mkdir(join(scratch, "dist"))
  for (const name of ["game", "audio-events"])
    await symlink(join(directory, name + ".mjs"), join(scratch, "dist", name + ".mjs"))
  for (const name of ["audio", "renderer", "host-values", "survivor-art", "survivor-shapes", "content"])
    await copyFile(new URL(name + ".mts", import.meta.url), join(scratch, name + ".mts"))
  const audioImport: unknown = await import(pathToFileURL(join(scratch, "audio.mts")).href)
  const audioConstructor = object(audioImport).AudioEngine
  if (typeof audioConstructor !== "function" || typeof object(audioConstructor.prototype).observe !== "function")
    throw Error("Missing audio adapter")
  const AudioEngine = audioConstructor as typeof Audio
  const engine = new AudioEngine(),
    events: string[] = []
  engine.event = (name) => {
    events.push(name)
  }
  const first = frame(5, 10)
  assert.equal(first.enemies[0]?.lifetime, "enemy:7:0")
  assert.equal(frame(20, 10).enemies[0]?.lifetime, "enemy:7:10")
  engine.observe(first)
  assert.deepEqual(events.slice(), [])
  engine.observe(frame(6, 11, 8))
  assert.deepEqual(events.slice(), ["impact"])
  const shotFrame: Frame = {
    ...frame(8, 13),
    enemies: [],
    projectiles: [
      {
        identity: 2,
        lifetime: "shot:2:8",
        hostile: false,
        weapon: 4,
        radius: 2,
        x: spatial.x,
        y: spatial.y,
        age: 0,
        damage: 1,
        vx: 1,
        vy: 0,
        life: 20,
        pierce: 1,
        sourcePlayer: 1,
        weaponOwner: 4,
        logicalSlot: 0,
        birthTick: 8,
        tick: 8
      },
      {
        identity: 3,
        lifetime: "shot:3:8",
        hostile: true,
        weapon: 0,
        radius: 2,
        x: spatial.x,
        y: spatial.y,
        age: 0,
        damage: 1,
        vx: 1,
        vy: 0,
        life: 20,
        pierce: 1,
        sourcePlayer: null,
        weaponOwner: 0,
        logicalSlot: 0,
        birthTick: 8,
        tick: 8
      }
    ],
    actorOrder: [{ projectile: 3 }, { projectile: 2 }]
  }
  engine.observe(shotFrame)
  assert.deepEqual(events.slice(-2), ["hostile", "shot"])
  engine.observe({ ...shotFrame, tick: 9, gold: 1, xp: 1 })
  assert.ok(events.includes("pickup"))
  const invalid = { ...shotFrame, projectiles: shotFrame.projectiles.map((p) => ({ ...p, lifetime: "" })), tick: 10 }
  assert.throws(() => engine.observe(invalid), /explicit lifetime/)
  const graphicsImport: unknown = await import(pathToFileURL(join(scratch, "renderer.mts")).href)
  const graphicsConstructor = object(graphicsImport).Renderer
  if (typeof graphicsConstructor !== "function" || typeof object(graphicsConstructor.prototype).draw !== "function")
    throw Error("Missing renderer")
  const Renderer = graphicsConstructor as typeof Graphics
  const paints: string[] = []
  const gradient = { addColorStop() {} }
  const context = new Proxy(
    { fillStyle: "", strokeStyle: "" },
    {
      get(target, key) {
        if (key === "fillStyle") return target.fillStyle
        if (key === "strokeStyle") return target.strokeStyle
        if (key === "createRadialGradient") return () => gradient
        if (key === "measureText") return () => ({ width: 50 })
        return () => {
          paints.push(String(key))
        }
      }
    }
  )
  const canvas = {
    width: 800,
    height: 600,
    getBoundingClientRect: () => ({ width: 800, height: 600 }),
    getContext: () => context
  } as unknown as HTMLCanvasElement
  const renderer = new Renderer(canvas)
  renderer.observedPlayer = () => {}
  const seen: string[] = []
  const pickup = renderer.drawPickup.bind(renderer)
  renderer.drawPickup = (value) => {
    seen.push(value.item.kind)
    pickup(value)
  }
  renderer.draw(first, 1 / 60, { reducedMotion: true })
  assert.deepEqual(seen, ["xp", "gold", "healing", "chest", "relic"])
  assert.ok(paints.includes("arc") && paints.includes("fillRect"))
  const depth: string[] = []
  renderer.drawEnemy = () => {
    depth.push("enemy")
  }
  renderer.drawProjectile = () => {
    depth.push("projectile")
  }
  renderer.drawPickup = (value) => {
    depth.push(value.item.kind)
  }
  renderer.observedPlayer = (player) => {
    depth.push("player" + player.id)
  }
  const ordered: Frame = {
    ...shotFrame,
    enemies: first.enemies,
    pickups: first.pickups.map((p) => ({ ...p, y: spatial.y })),
    projectiles: shotFrame.projectiles.map((p) => ({ ...p, y: spatial.y })),
    players: first.players.map((p) => ({ ...p, py: spatial.y - 1 })),
    actorOrder: [
      { projectile: 3 },
      { pickup: 20 },
      { enemy: 7 },
      { projectile: 2 },
      { pickup: 21 },
      { pickup: 22 },
      { pickup: 23 },
      { pickup: 24 }
    ]
  }
  renderer.draw(ordered, 1 / 60, { reducedMotion: true, showDamage: false })
  assert.deepEqual(depth, ["player0", "projectile", "xp", "enemy", "projectile", "gold", "healing", "chest", "relic"])
} finally {
  await rm(scratch, { recursive: true, force: true })
}
console.log(
  "PASS actual producer audio/render: named actors, lifetime identity, sound order, reward cues, all five pickup visuals and stable global actor/player depth order"
)
