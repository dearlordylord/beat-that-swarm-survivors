import type { ObservationPresentation as Presentation } from "./coop-presentation.mts"
import type { Frame } from "./frame.mts"
import { bendModule } from "../bend-module.mts"
import { list, rows as array, defined, some, object } from "./host-values.mts"
import assert from "node:assert/strict"
import { mkdtemp, copyFile, mkdir, symlink, rm, readFile } from "node:fs/promises"
import { tmpdir } from "node:os"
import { resolve, join, dirname } from "node:path"
import { pathToFileURL, fileURLToPath } from "node:url"
// Executed diagnostics of emitted typed projection and the actual browser adapter.
// Usage: node coop-playback-wire-check.mts <wire.mjs> <directory-of-emitted-modules>

const wirePath = resolve(process.argv[2] ?? "examples/survivors/dist/coop-playback-wire.mjs")
const moduleDir = resolve(process.argv[3] ?? dirname(wirePath))
const { default: W } = await bendModule<BendABI.CoopPlaybackWire.API>()(pathToFileURL(wirePath).href, [
  "body_actor",
  "extra_actor",
  "join",
  "own_run",
  "player_actor",
  "project",
  "snapshot_actor"
])
const { default: P } = await bendModule<BendABI.CoopPlayback.API>()(
  pathToFileURL(join(moduleDir, "coop-playback.mjs")).href,
  ["fresh", "push", "sample"]
)
const run = (extra = {}) => ({
  $: "Run" as const,
  phase: 0,
  tick: 100,
  px: 0.1,
  py: -0.2,
  hp: 100,
  maxHp: 100,
  xp: 0,
  xpNeed: 1,
  level: 1,
  kills: 0,
  gold: 0,
  character: 1,
  weapons: list([]),
  passives: list([]),
  invuln: 0,
  seed: 1,
  stage: 0,
  arcana: 0,
  meta: 0,
  revivals: 0,
  bosses: 0,
  mode: 0,
  rerolls: 0,
  banishes: 0,
  skips: 0,
  bannedWeapons: 0,
  bannedPassives: 0,
  enemyKinds: list([]),
  relicCollected: 0,
  ...extra
})
const body = (extra = {}) => ({
  $: "Body" as const,
  x: 0.1,
  y: -0.2,
  kind: 1,
  variant: 2,
  hp: 0,
  maxHp: 0,
  age: 10,
  seed: 42,
  radius: 3,
  ...extra
})
const motion = (extra = {}) => ({
  $: "Motion" as const,
  vx: 1,
  vy: 0,
  life: 20,
  pierce: 2,
  visited: list([]),
  slow: 0,
  burn: 0,
  ownerBase: 3,
  logicalSlot: 65540,
  ...extra
})
const scene = (tick: number, b: BendABI.Game.Body, extra = {}) => ({
  $: "Scene" as const,
  own: 0,
  players: list([{ $: "PlayerRecord" as const, id: 0, run: run({ tick }), connected: true }]),
  snapshots: list([{ $: "Snapshot" as const, body: b, motion: motion() }]),
  births: { $: "Item" as const, key: b.seed, value: 90 },
  directions: { $: "Directions" as const, x0: 0, y0: 0, x1: 0, y1: 0 },
  contacts: list([]),
  tick,
  diagnostics: false,
  ...extra
})
const raw = (observation: number, tick: number, b: BendABI.Game.Body, extra: Partial<Frame> = {}): Frame => ({
  ...run(),
  worldSize: 1000,
  worldMargin: 0,
  relicCollected: 0,
  relicX: 0,
  relicY: 0,
  runLength: 0,
  enemiesKilled: [],
  revivalsUsed: 0,
  bossesKilled: 0,
  weapons: [],
  passives: [],
  offers: [],
  observationSeq: observation,
  tick,
  ownPlayerId: 0,
  px: 0,
  py: 0,
  players: [{ id: 0, px: 0.1, py: -0.2, hp: 100, maxHp: 100, character: 0 }],
  bodies: [[b.x, b.y, b.kind, b.variant, b.hp, b.maxHp, b.age, b.seed, b.radius]],
  combatForecast: scene(tick, b),
  ...extra
})
let checks = 0
const check = (v: unknown, message: string) => {
  assert.ok(v, message)
  checks++
}
for (const connected of [true, false]) {
  const actor = W.player_actor({ $: "PlayerRecord" as const, id: 1, run: run(), connected })
  check(actor.key === 1 && actor.owner === 1 && actor.generation === "player:1:1", "player identity projected")
  check(actor.x === Math.fround(0.1) && actor.y === Math.fround(-0.2), "nested player F32 normalized")
  check(actor.hp === (connected ? 100 : 0), "player health follows connection without projectile-kind collision")
}
for (const kind of [0, 1, 7])
  for (const life of [0, 1, 20])
    for (const pierce of [0, 1, 2]) {
      const actor = W.body_actor(body({ kind, hp: kind === 0 ? 17 : 0 }), motion({ life, pierce }), 90)
      check(actor.hp === (kind === 0 ? 17 : Number(life > 0 && pierce > 0)), "kind-specific presentation liveness")
      check(actor.x === Math.fround(0.1) && actor.y === Math.fround(-0.2), "nested body F32 normalized")
      check(actor.owner === (kind === 1 ? 1 : 4294967295), "projectile owner from packed slot")
      check(
        actor.generation === (kind === 0 ? "enemy:42:90" : kind === 1 ? "1:90:3:4" : "hostile:42:90"),
        "exact body lifetime"
      )
    }
check(
  W.snapshot_actor(
    { $: "BodyContext" as const, tick: 100, births: { $: "Item" as const, key: 42, value: 7 } },
    { $: "Snapshot" as const, body: body(), motion: motion() }
  ).generation === "1:7:3:4",
  "explicit birth overrides age fallback"
)
check(
  W.snapshot_actor(
    { $: "BodyContext" as const, tick: 100, births: { $: "Empty" as const } },
    { $: "Snapshot" as const, body: body(), motion: motion() }
  ).generation === "1:90:3:4",
  "missing birth falls back to tick-age"
)
for (let kind = 0; kind < 12; kind++)
  check(
    W.extra_actor(99, kind, 2, 0.1, -0.2, 10, 1, 100).$ === ([0, 1, 7].includes(kind) ? "None" : "Some"),
    "extras exclude exactly combat cohort"
  )
// Actual game projectile has HP=0. It must interpolate using active Motion life/pierce.
let state = P.push(P.fresh(), W.project(scene(100, body({ x: 0 })), 1, 0, list([])))
state = P.push(state, W.project(scene(106, body({ x: 6, age: 16 })), 2, 100000, list([])))
state = {
  ...state,
  cursor: { $: "Cursor" as const, tick: 103, fraction: 0, lastAt: 100000, mode: { $: "Playing" as const } }
}
check(
  defined(array(some(P.sample(state)).bodies)[0]).x === 3,
  "real HP-zero projectile interpolates between canonical frames"
)
check(body().hp === 0, "presentation liveness does not mutate gameplay body HP")
const owned = run({ character: 7, hp: 0 })
check(
  some(
    W.own_run(
      scene(100, body(), {
        own: 8,
        players: list([
          { $: "PlayerRecord" as const, id: 3, run: run(), connected: true },
          { $: "PlayerRecord" as const, id: 8, run: owned, connected: false }
        ])
      })
    )
  ) === owned,
  "own run follows ID rather than list position"
)
const extra = Array.from({ length: 12000 }, (_, key: number) => ({
  $: "Actor" as const,
  key,
  kind: 2,
  generation: `extra:${key}`,
  x: 0,
  y: 0,
  age: 0,
  hp: 0,
  owner: 4294967295
}))
check(array(W.join(list(extra), list(extra))).length === 24000, "large ordered join remains stack safe")
const scratch = await mkdtemp(join(tmpdir(), "coop-wire-adapter-"))
try {
  await mkdir(join(scratch, "dist"))
  const adapterSource = await readFile(new URL("./coop-presentation.mts", import.meta.url), "utf8")
  for (const [, name] of adapterSource.matchAll(/from ['"]\.\/dist\/([\w-]+)\.mjs['"]/g))
    await symlink(
      name === "coop-playback-wire" ? wirePath : join(moduleDir, `${name}.mjs`),
      join(scratch, "dist", `${name}.mjs`)
    )
  await copyFile(
    fileURLToPath(new URL("./coop-presentation.mts", import.meta.url)),
    join(scratch, "coop-presentation.mts")
  )
  await copyFile(new URL("./host-values.mts", import.meta.url), join(scratch, "host-values.mts"))
  const imported: unknown = await import(pathToFileURL(join(scratch, "coop-presentation.mts")).href)
  const constructor = object(imported).ObservationPresentation
  if (typeof constructor !== "function") throw new TypeError("Missing ObservationPresentation constructor")
  const prototype: unknown = constructor.prototype
  const methods = object(prototype)
  for (const key of ["reset", "push", "sample", "bodyMetadata"]) {
    if (typeof methods[key] !== "function") throw new TypeError(`Missing presentation method: ${key}`)
  }
  // This is the same typed adapter copied above, loaded against the emitted fixtures.
  const ObservationPresentation = constructor as typeof Presentation
  const adapter = new ObservationPresentation()
  adapter.push(raw(1, 100, body({ kind: 0, hp: 80, maxHp: 100, x: 0, age: 10 })), 0)
  adapter.push(raw(2, 106, body({ kind: 0, hp: 30, maxHp: 100, x: 6, age: 16, variant: 4, radius: 7 })), 100)
  adapter.sample(100)
  let displayed = defined(adapter.sample(200))
  check(defined(displayed.remotePresentation).baseObservation === 2, "base observation advances")
  check(
    defined(displayed.bodies[0])[4] === 30 &&
      defined(displayed.bodies[0])[6] === 16 &&
      defined(displayed.bodies[0])[3] === 4 &&
      defined(displayed.bodies[0])[8] === 7,
    "render metadata belongs to selected base observation, not oldest lifetime cache"
  )
  const savedFrame = adapter.frames.get(2),
    savedMetadata = adapter.metadata.get(2),
    savedContacts = adapter.contacts
  const poison = { $: "State" as const, epoch: 99, now: 999, events: list([]), overflow: 0, expired: 0 }
  adapter.push(raw(2, 109, body({ kind: 0, hp: 999 }), { contactJournal: poison }), 220)
  check(
    adapter.frames.get(2) === savedFrame &&
      adapter.metadata.get(2) === savedMetadata &&
      adapter.contacts === savedContacts,
    "duplicate observation cannot overwrite payload, metadata or receipt cache"
  )
  adapter.push(raw(3, 105, body({ kind: 0, hp: 999 }), { contactJournal: poison }), 230)
  check(
    !adapter.frames.has(3) && adapter.contacts === savedContacts,
    "newer observation with backward world tick cannot mutate cache"
  )
  adapter.push(raw(3, 106, body({ kind: 0, hp: 20, age: 16, x: 6 })), 240)
  check(defined(defined(adapter.sample(240)).bodies[0])[4] === 20, "same-tick newer metadata is presented")
  for (let obs = 4; obs < 24; obs++)
    adapter.push(
      raw(obs, 106 + (obs - 3) * 3, body({ kind: 0, x: obs, hp: 20, age: 16 + (obs - 3) * 3 })),
      240 + (obs - 3) * 50
    )
  check(
    adapter.frames.size <= 8 && adapter.metadata.size <= 8,
    "IO payload and metadata caches follow bounded Bend retention"
  )
  const shots = new ObservationPresentation()
  // Seed an established cursor so projection/liveness is independent of startup policy.
  shots.push(raw(1, 100, body({ x: 0 })), 0)
  shots.push(raw(2, 104, body({ x: 4, age: 14 })), 100)
  shots.state = {
    ...shots.state,
    cursor: { $: "Cursor" as const, tick: 103, fraction: 0, lastAt: 100000, mode: { $: "Playing" as const } }
  }
  displayed = defined(shots.sample(100))
  check(
    defined(displayed.bodies[0])[0] === 3 && defined(displayed.bodies[0])[4] === 0,
    "actual adapter interpolates projectile while preserving raw HP zero"
  )
  const early = new ObservationPresentation()
  const hit = {
    $: "HitEvent" as const,
    id: "first-render-race",
    tick: 102,
    kind: 0,
    shotId: "shot:50",
    shotSeed: 50,
    targetSeed: 42,
    targetGeneration: 90,
    fraction: 0.5,
    impactX: 0,
    impactY: 0,
    targetAtImpactX: 2,
    targetAtImpactY: 0,
    radius: 3,
    outcome: 0
  }
  const history = (events: BendABI.CoopHitJournal.HitEvent[]) => ({
    $: "State" as const,
    epoch: 7,
    now: 106,
    events: list(events),
    overflow: 0,
    expired: 0
  })
  early.push(raw(1, 100, body({ kind: 0, hp: 20, age: 10, x: 0 }), { contactJournal: history([]) }), 0)
  early.push(raw(2, 106, body({ kind: 0, hp: 20, age: 16, x: 6 }), { contactJournal: history([hit]) }), 100)
  early.state = {
    ...early.state,
    cursor: { $: "Cursor" as const, tick: 100, fraction: 0, lastAt: 100000, mode: { $: "Playing" as const } }
  }
  check(defined(defined(early.sample(100)).combatImpacts).length === 0, "first-render race keeps future hit hidden")
  check(
    defined(defined(early.sample(150)).combatImpacts).some(
      (effect: BendABI.CoopContactPlayback.Fx) => effect.id === hit.id
    ),
    "hit received after attachment but before first rAF plays when due"
  )
} finally {
  await rm(scratch, { recursive: true, force: true })
}
console.log(
  JSON.stringify({
    status: "PASS",
    checks,
    largeJoinActors: 24000,
    scope: "emitted projection and actual IO adapter diagnostics"
  })
)
