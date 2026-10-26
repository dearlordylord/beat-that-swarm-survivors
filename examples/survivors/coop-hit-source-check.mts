import { bendModule } from "../bend-module.mts"
import { at, defined, list, rows as array } from "./host-values.mts"
import { coreFrame } from "./observations.mts"
import { corePacket } from "./coop-fixtures.mts"
// Runtime oracle fixtures for host-confirmed cosmetic contacts. Core receipts
// are checked against literal identities and hand-computed simple geometry;
// Game's prepared hit plans are also sent through its actual enemy resolver.
import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"

function moduleUrl(variable: string, fallback: string) {
  const configured = process.env[variable]
  if (!configured) return new URL(fallback, import.meta.url)
  if (configured.startsWith("file:")) return new URL(configured)
  return pathToFileURL(resolve(configured))
}

const [{ default: Core }, { default: Game }] = await Promise.all([
  bendModule<BendABI.CoopCore.API>()(moduleUrl("COOP_CORE_MODULE", "./dist/web/dist/coop-core.mjs"), [
    "core_start",
    "core_join",
    "core_step",
    "core_observe"
  ]),
  bendModule<BendABI.Game.API>()(moduleUrl("COOP_GAME_MODULE", "./dist/web/dist/game.mjs"), [
    "enemy_targets",
    "nearest",
    "nearest_shooter",
    "contact_team",
    "solo_team",
    "team_move_space",
    "team_enemy_updated"
  ])
])
const nil = () => list<never>([])
type EnemySnapshot = Extract<BendABI.Game.Snapshot, { $: "EnemySnapshot" }>
type ProjectileSnapshot = Extract<BendABI.Game.Snapshot, { $: "ProjectileSnapshot" }>
function target(
  x: number,
  seed: number,
  { age = 90, hp = 100, radius = 8, y = 1000, archetype = 1 } = {}
): EnemySnapshot {
  return {
    $: "EnemySnapshot",
    enemy: {
      $: "State",
      spatial: { $: "Spatial", x, y, age, radius },
      archetype,
      identity: seed,
      vitals: { $: "Vitals", health: hp, maximum: hp },
      status: {
        $: "Status",
        slow: { $: "Slow", ticks: 0, frozen: true },
        burn: { $: "Burn", ticks: 0, sourcePlayer: { $: "None" } }
      }
    }
  }
}

function shot({
  x,
  y = 1000,
  weapon = 18,
  damage = 7,
  age = 10,
  seed = 900,
  radius = 1,
  vx = 100,
  vy = 0,
  pierce = 3,
  owner = 2,
  slot = 0
}: {
  x: number
  y?: number
  weapon?: number
  damage?: number
  age?: number
  seed?: number
  radius?: number
  vx?: number
  vy?: number
  pierce?: number
  owner?: number
  slot?: number
}): ProjectileSnapshot {
  return {
    $: "ProjectileSnapshot",
    projectile: {
      $: "State",
      spatial: { $: "Spatial", x, y, age, radius },
      identity: seed,
      side: { $: "PlayerShot" },
      payload: { $: "ShotPayload", weapon, damage, active: true },
      trajectory: {
        $: "Trajectory",
        vx,
        vy,
        life: 30,
        pierce,
        visited: nil(),
        weaponOwner: owner,
        logicalSlot: slot,
        sourcePlayer: { $: "Some", value: 0 }
      }
    }
  }
}

// Targeting consumes a narrow immutable phase projection. Health and reward
// words never enter aiming; hostile firing still reads actual archetype/age.
{
  const source: BendABI.Game.Snapshot[] = [
    target(100, 11, { y: 100, archetype: 9, age: 120 }),
    target(100, 12, { y: 100, archetype: 0, age: 120 }),
    shot({ x: 0, y: 0, seed: 13 })
  ]
  const targets = Game.enemy_targets(list(source))
  assert.deepEqual(array(targets.aims), [
    { $: "Target", x: 100, y: 100, identity: 11 },
    { $: "Target", x: 100, y: 100, identity: 12 }
  ])
  assert.deepEqual(
    Game.enemy_targets(
      list(
        source.map((value) =>
          value.$ === "EnemySnapshot"
            ? { ...value, enemy: { ...value.enemy, vitals: { $: "Vitals", health: 1000, maximum: 2000 } } }
            : value
        )
      )
    ),
    targets
  )
  const fallback: BendABI.Game.Aim = { $: "Aim", x: 0, y: 0, id: 0, distance: 10000000 }
  assert.equal(Game.nearest(targets, 0, 0, fallback).id, 11, "first equal-distance target wins")
  assert.equal(Game.nearest_shooter(targets, 0, 0, fallback).id, 11, "ranged source fires at its actual age")
  const first = at(source, 0)
  assert.ok(first.$ === "EnemySnapshot")
  source[0] = { ...first, enemy: { ...first.enemy, spatial: { ...first.enemy.spatial, age: 119 } } }
  assert.equal(
    Game.nearest_shooter(Game.enemy_targets(list(source)), 0, 0, fallback).id,
    0,
    "a nonfiring age cannot borrow another source eligibility"
  )
}

function coreSeedState() {
  const started = corePacket(Core.core_start(0, 0, 1))
  assert.equal(started.$, "CorePacket", "Core.core_start must return a Core packet")
  const joined = corePacket(Core.core_join(started.state, 0, 0, 0))
  assert.equal(joined.$, "CorePacket", "fixture player must join before stepping")
  return joined.state
}

function coreContacts(tick: number, snapshots: BendABI.Game.Snapshot[]) {
  const state = coreSeedState()
  const input = { ...state, shared: { ...state.shared, tick: tick - 1 }, snapshots: list(snapshots) }
  const packet = corePacket(Core.core_step(input, 0, 0, 0, 0))
  assert.equal(packet.$, "CorePacket", `Core.core_step failed: ${JSON.stringify(packet)}`)
  const frame = coreFrame(packet.observation)
  assert.ok(frame && "contacts" in frame && frame.contacts)
  assert.equal(frame.advanced, true, "fixture must exercise the advancing Core path")
  assert.ok(Object.hasOwn(frame, "contacts"), "Core frame must expose its journaled contact receipts")
  return array(frame.contacts)
}

function preparedTeam(tick: number, snapshots: BendABI.Game.Snapshot[]) {
  const state = coreSeedState()
  const observation = corePacket(Core.core_observe(state, 0)).observation
  assert.ok(observation.$ === "ViewObservation")
  const observedRun = observation.game.run
  const run = { ...observedRun, session: { ...observedRun.session, tick } }
  const args: BendABI.Game.Args = {
    $: "Args",
    run,
    targets: Game.enemy_targets(nil()),
    dx: 0,
    dy: 0,
    snapshots: list(snapshots),
    hits: nil()
  }
  return Game.contact_team(Game.solo_team(args))
}

function hitPlans(team: BendABI.Game.Team) {
  return array(team.base.hits)
}

function resolveMovedEnemy(team: BendABI.Game.Team, value: EnemySnapshot) {
  const enemy = value.enemy
  const space = Game.team_move_space(team, enemy.spatial, enemy.archetype, enemy.status.slow)
  const moved = { ...enemy, spatial: space }
  const decision = Game.team_enemy_updated(team, { $: "ActiveEnemy", archetype: enemy.archetype }, moved, { $: "None" })
  assert.ok(decision.$ === "Resolved")
  assert.ok(decision.outcome.$ === "Alive" || decision.outcome.$ === "Killed")
  return { moved, result: decision.outcome }
}

function close(actual: number, expected: number, label: string, epsilon = 0.0001) {
  assert.ok(Math.abs(actual - expected) <= epsilon, `${label}: expected ${expected}, got ${actual}`)
}

// Both browser roles use the same typed snapshot projection. The host must
// receive its own Scene too, even though it never predicts the world.
{
  let state = coreSeedState()
  for (const id of [0, 1]) {
    const observed = corePacket(Core.core_observe(state, id))
    state = observed.state
    const frame = coreFrame(observed.observation)
    assert.ok(frame && "combatForecast" in frame)
    assert.equal(frame.combatForecast.own, id, "typed projection exists for each observer")
    assert.equal(frame.combatForecast.$, "Scene")
  }
}

// The shot moves horizontally from x=500 to x=600. Enemy paths are frozen at
// y=1000 with radius 8; the shot radius is 1. Contact times are therefore
// (enemyX - 9 - 500) / 100. Equal-time contacts sort by seed before piercing.
{
  const source = shot({ x: 500, seed: 900, age: 10, pierce: 3 })
  const targets = [target(545, 42), target(558, 41), target(590, 43), target(545, 40)]
  const snapshots = [source, ...targets]
  const events = coreContacts(101, snapshots)

  assert.deepEqual(
    events.map((event) => event.id),
    ["0:90:2:0:40:10:101:2", "0:90:2:0:42:10:101:2", "0:90:2:0:41:10:101:2"],
    "receipt IDs must follow first-crossed target order, tie seed, then pierce budget"
  )
  assert.deepEqual(
    events.map((event) => event.targetSeed),
    [40, 42, 41]
  )
  close(at(events, 0).fraction, 0.36, "first crossing time")
  close(at(events, 1).fraction, 0.36, "equal-time crossing")
  close(at(events, 2).fraction, 0.49, "third piercing time")
  close(at(events, 0).impactX, 536, "first impact x")
  close(at(events, 2).impactX, 549, "third impact x")
  for (const event of events) {
    assert.equal(event.impactY, 1000)
    assert.equal(event.radius, 9)
    assert.equal(event.kind, 2)
    assert.equal(event.outcome, 0, "receipts remain cosmetic contact records")
  }
  assert.equal(
    events.some((event) => event.targetSeed === 43),
    false,
    "fourth crossing is beyond the three-hit budget"
  )

  const team = preparedTeam(101, snapshots)
  const plan = at(hitPlans(team), 0)
  assert.deepEqual(array(plan.targets), [40, 42, 41])
  for (const value of targets) {
    const { result } = resolveMovedEnemy(team, value)
    const expectedHp = [40, 42, 41].includes(value.enemy.identity) ? 93 : 100
    assert.equal(
      result.enemy.vitals.health,
      expectedHp,
      `actual prepared enemy resolver for seed ${value.enemy.identity}`
    )
  }
}

// A field centered at (500,1000) has radius 10. A radius-5 enemy at distance
// 15 is the inclusive edge; a target 0.25 beyond it must not be a recipient.
{
  const source = shot({
    x: 500,
    weapon: 11,
    damage: 7,
    age: 0,
    seed: 901,
    radius: 10,
    vx: 0,
    vy: 0,
    pierce: 9999,
    slot: 1
  })
  const edge = target(515, 51, { age: 90, hp: 100, radius: 5 })
  const outside = target(515.25, 52, { age: 90, hp: 100, radius: 5 })
  const snapshots = [source, edge, outside]
  const events = coreContacts(101, snapshots)

  assert.deepEqual(
    events.map((event) => event.id),
    ["0:100:2:1:51:10:101:1"]
  )
  assert.equal(at(events, 0).kind, 1)
  assert.equal(at(events, 0).fraction, 1)
  assert.equal(at(events, 0).radius, 15)
  assert.equal(at(events, 0).impactX, 515)
  assert.equal(at(events, 0).targetAtImpactX, 515)
  const team = preparedTeam(101, snapshots)
  const plan = at(hitPlans(team), 0)
  assert.equal(plan.area, true)
  assert.deepEqual(array(plan.targets), [])
  assert.equal(
    resolveMovedEnemy(team, edge).result.enemy.vitals.health,
    93,
    "actual resolver includes the exact AoE edge"
  )
  assert.equal(
    resolveMovedEnemy(team, outside).result.enemy.vitals.health,
    100,
    "actual resolver excludes the outside target"
  )
}

// One hit from a three-hit budget continues; terminal classification is per
// shot rather than the aggregate number of contacts in the team.
{
  const source = shot({ x: 500, seed: 920, pierce: 3 })
  const other = shot({ x: 500, seed: 921, pierce: 1, slot: 1 })
  const events = coreContacts(101, [source, other, target(545, 80)])
  assert.equal(defined(events.find((event) => event.shotSeed === 920)).kind, 0, "continuing piercing shot")
  assert.equal(defined(events.find((event) => event.shotSeed === 921)).kind, 2, "other shot independently exhausts")
}

// Lethal contact occurs at x=14343 against a frozen target at x=14352. The
// Game resolver then loot-clamps the dead body to x=14272; the receipt must
// retain the pre-loot contact coordinate rather than the transformed pickup.
{
  const source = shot({ x: 14300, y: 1000, seed: 903, age: 10, vx: 60, pierce: 1 })
  const victim = target(14352, 60, { age: 90, hp: 7, radius: 8 })
  const snapshots = [source, victim]
  const events = coreContacts(101, snapshots)
  assert.deepEqual(
    events.map((event) => event.id),
    ["0:90:2:0:60:10:101:2"]
  )
  close(at(events, 0).fraction, 43 / 60, "lethal contact time")
  close(at(events, 0).impactX, 14343, "lethal projectile preimage")
  assert.equal(at(events, 0).targetAtImpactX, 14352, "receipt target coordinate is before loot placement")

  const team = preparedTeam(101, snapshots)
  const { result } = resolveMovedEnemy(team, victim)
  assert.equal(result.enemy.vitals.health, 0)
  assert.ok(result.$ === "Killed", "lethal resolver produced a typed death reward")
  assert.equal(result.reward.x, 14272, "actual loot placement clamps to the player upper edge")
  assert.notEqual(result.reward.x, at(events, 0).targetAtImpactX, "receipt does not use the post-loot coordinate")
}

// The same pooled target seed denotes a distinct incarnation at a new birth
// tick. A fresh spawn routed through Game's SL.Fresh branch bypasses old contact
// effects and receives clean status/contact data; an existing incarnation is damaged.
{
  const source = shot({ x: 500, seed: 904, age: 10, pierce: 1 })
  const oldIncarnation = target(545, 77, { age: 90, hp: 100 })
  const newborn = target(545, 77, { age: 0, hp: 100 })
  const oldEvents = coreContacts(101, [source, oldIncarnation])
  const newEvents = coreContacts(101, [source, newborn])
  assert.deepEqual(
    oldEvents.map((event) => event.id),
    ["0:90:2:0:77:10:101:2"]
  )
  assert.deepEqual(
    newEvents.map((event) => event.id),
    ["0:90:2:0:77:100:101:2"]
  )
  assert.notEqual(at(oldEvents, 0).id, at(newEvents, 0).id, "reused seed must not reuse the old lifetime ID")

  const team = preparedTeam(101, [source, newborn])
  assert.deepEqual(array(at(hitPlans(team), 0).targets), [77])
  const previousDormant: BendABI.EnemyCombat.State = {
    ...newborn.enemy,
    spatial: { ...newborn.enemy.spatial, age: 5 },
    vitals: { $: "Vitals", health: 0, maximum: 100 },
    status: {
      $: "Status",
      slow: { $: "Slow", ticks: 0, frozen: true },
      burn: { $: "Burn", ticks: 37, sourcePlayer: { $: "Some", value: 0 } }
    }
  }
  const candidate: BendABI.EnemyLifecycle.Candidate = {
    $: "Candidate",
    x: 545,
    y: 1000,
    archetype: 1,
    identity: 77,
    vitals: newborn.enemy.vitals,
    radius: 8
  }
  const fresh = Game.team_enemy_updated(team, { $: "Dormant", archetype: 1 }, previousDormant, {
    $: "Some",
    value: candidate
  })
  assert.ok(fresh.$ === "Resolved" && fresh.outcome.$ === "Born")
  assert.equal(fresh.outcome.newborn.candidate.vitals.health, 100, "fresh birth bypasses prepared old-incarnation hit")
  assert.deepEqual(fresh.outcome.newborn.status, {
    $: "Status",
    slow: { $: "Slow", ticks: 0, frozen: false },
    burn: { $: "Burn", ticks: 0, sourcePlayer: { $: "None" } }
  })
  assert.equal(fresh.outcome.newborn.contactDamage, 0)
  assert.deepEqual(fresh.outcome.newborn.killer, { $: "None" })
  const existing = Game.team_enemy_updated(
    team,
    { $: "ActiveEnemy", archetype: 1 },
    {
      ...newborn.enemy,
      status: {
        $: "Status",
        slow: { $: "Slow", ticks: 0, frozen: true },
        burn: { $: "Burn", ticks: 37, sourcePlayer: { $: "Some", value: 0 } }
      }
    },
    { $: "Some", value: candidate }
  )
  assert.ok(existing.$ === "Resolved" && (existing.outcome.$ === "Alive" || existing.outcome.$ === "Killed"))
  assert.equal(existing.outcome.enemy.vitals.health, 93, "the same prepared hit applies to an existing incarnation")
}

console.log(
  "PASS Core contact receipts against analytic sweep, AoE edge, lethal pre-loot geometry, and reused-seed newborn fixtures"
)
