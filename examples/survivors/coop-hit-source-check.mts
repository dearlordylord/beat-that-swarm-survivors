#!/usr/bin/env node
import { parseJson, list, rows as array, at, defined } from "./host-values.mts"
import { bendModule } from "../bend-module.mts"
import { parseCoopFrame } from "./frame.mts"
import { parseCoreView } from "./coop-boundary.mts"
import { corePacket } from "./coop-fixtures.mts"
import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"

// Runtime oracle fixtures for host-confirmed cosmetic contacts. Core receipts
// are checked against literal identities and hand-computed simple geometry;
// Game's prepared hit plans are also sent through its actual enemy resolver.

const parseCoreReceipt = (text: string) => {
  const view = parseCoreView(parseJson(text))
  return { ...view, contacts: defined(view.contacts), contactsOmitted: defined(view.contactsOmitted) }
}
function moduleUrl(variable: string, fallback: string) {
  const configured = process.env[variable]
  if (!configured) return new URL(fallback, import.meta.url)
  if (configured.startsWith("file:")) return new URL(configured)
  return pathToFileURL(resolve(configured))
}
const [{ default: Core }, { default: Game }] = await Promise.all([
  bendModule<BendABI.CoopCore.API>()(moduleUrl("COOP_CORE_MODULE", "./dist/web/dist/coop-core.mjs").href, [
    "core_join",
    "core_observe",
    "core_start",
    "core_step"
  ]),
  bendModule<BendABI.Game.API>()(moduleUrl("COOP_GAME_MODULE", "./dist/web/dist/game.mjs").href, [
    "contact_team",
    "enemy_update",
    "move_body",
    "solo_team",
    "team_args",
    "team_enemy_updated",
    "team_nearest"
  ])
])
const nil = () => ({ $: "Nil" as const })
function snapshot({
  x,
  y = 1000,
  kind,
  variant,
  hp,
  maxHp = hp,
  age,
  seed,
  radius,
  motion = {}
}: Pick<BendABI.Game.Body, "x" | "kind" | "variant" | "hp" | "age" | "seed" | "radius"> & {
  y?: number
  maxHp?: number
  motion?: Partial<BendABI.Game.Motion>
}): BendABI.Game.Snapshot {
  return {
    $: "Snapshot" as const,
    body: { $: "Body" as const, x, y, kind, variant, hp, maxHp, age, seed, radius },
    motion: {
      $: "Motion" as const,
      vx: 0,
      vy: 0,
      life: 0,
      pierce: 0,
      visited: nil(),
      slow: 0,
      burn: 0,
      ownerBase: 0,
      logicalSlot: 0,
      ...motion
    }
  }
}
function target(x: number, seed: number, { age = 90, hp = 100, radius = 8, y = 1000 } = {}) {
  // 65536 means fully frozen in this fixture, so the independently known path
  // is the constant point (x,y); the normal Game movement/resolver still runs.
  return snapshot({ x, y, kind: 0, variant: 1, hp, age, seed, radius, motion: { slow: 65536 } })
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
}: { x: number } & Partial<
  Record<"y" | "weapon" | "damage" | "age" | "seed" | "radius" | "vx" | "vy" | "pierce" | "owner" | "slot", number>
>) {
  return snapshot({
    x,
    y,
    kind: 1,
    variant: weapon,
    hp: damage,
    age,
    seed,
    radius,
    motion: { vx, vy, life: 30, pierce, ownerBase: owner, logicalSlot: slot }
  })
}
function coreSeedState() {
  const started = Core.core_start(0, 0, 1)
  assert.ok(started.$ === "CorePacket", "Core.core_start must return a Core packet")
  const joined = Core.core_join(started.state, 0, 0, 0)
  assert.ok(joined.$ === "CorePacket", "fixture player must join before stepping")
  return joined.state
}
function coreContacts(tick: number, snapshots: BendABI.Game.Snapshot[]) {
  const state = coreSeedState()
  const input = { ...state, shared: { ...state.shared, tick: tick - 1 }, snapshots: list(snapshots) }
  const packet = Core.core_step(input, 0, 0, 0, 0)
  assert.ok(packet.$ === "CorePacket", `Core.core_step failed: ${JSON.stringify(packet)}`)
  const frame = parseCoreReceipt(packet.frame)
  assert.equal(frame.advanced, true, "fixture must exercise the advancing Core path")
  assert.ok(Object.hasOwn(frame, "contacts"), "Core frame must expose its journaled contact receipts")
  return array(frame.contacts)
}
function preparedTeam(tick: number, snapshots: BendABI.Game.Snapshot[]) {
  const state = coreSeedState()
  const run = { ...state.shared, tick }
  const args = { $: "Args" as const, run, bodies: nil(), dx: 0, dy: 0, snapshots: list(snapshots), hits: nil() }
  return Game.contact_team(Game.solo_team(args))
}
function hitPlans(team: BendABI.Game.Team) {
  return array(team.base.hits)
}
function resolveMovedEnemy(team: BendABI.Game.Team, value: BendABI.Game.Snapshot) {
  const { body, motion } = value
  const nearest = Game.team_nearest(team, body.x, body.y)
  const args = Game.team_args(team, nearest)
  const moved = Game.move_body(body, motion, args)
  const row = Game.enemy_update(moved, args.run)
  const result = Game.team_enemy_updated(
    team,
    moved,
    { $: "Status" as const, slow: motion.slow, burn: motion.burn },
    row
  )
  return { moved, row, result }
}
function _eventFor(events: BendABI.CoopHitJournal.HitEvent[], seed: number) {
  const matches = events.filter((event) => event.targetSeed === seed)
  assert.equal(matches.length, 1, `expected exactly one Core receipt for target seed ${seed}`)
  return at(matches, 0)
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
    const frame = parseCoopFrame(parseJson(observed.frame))
    assert.equal(frame.combatForecast.own, id, "typed projection exists for each observer")
    assert.ok(frame.combatForecast.$ === "Scene")
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
  close(defined(events[0]).fraction, 0.36, "first crossing time")
  close(defined(events[1]).fraction, 0.36, "equal-time crossing")
  close(defined(events[2]).fraction, 0.49, "third piercing time")
  close(defined(events[0]).impactX, 536, "first impact x")
  close(defined(events[2]).impactX, 549, "third impact x")
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
  const [plan] = hitPlans(team)
  assert.deepEqual(array(defined(plan).targets), [40, 42, 41])
  for (const value of targets) {
    const { result } = resolveMovedEnemy(team, value)
    const expectedHp = [40, 42, 41].includes(value.body.seed) ? 93 : 100
    assert.equal(result.row.body.hp, expectedHp, `actual prepared enemy resolver for seed ${value.body.seed}`)
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
  assert.equal(defined(events[0]).kind, 1)
  assert.equal(defined(events[0]).fraction, 1)
  assert.equal(defined(events[0]).radius, 15)
  assert.equal(defined(events[0]).impactX, 515)
  assert.equal(defined(events[0]).targetAtImpactX, 515)
  const team = preparedTeam(101, snapshots)
  const [plan] = hitPlans(team)
  assert.equal(defined(plan).area, true)
  assert.deepEqual(array(defined(plan).targets), [])
  assert.equal(resolveMovedEnemy(team, edge).result.row.body.hp, 93, "actual resolver includes the exact AoE edge")
  assert.equal(resolveMovedEnemy(team, outside).result.row.body.hp, 100, "actual resolver excludes the outside target")
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
  close(defined(events[0]).fraction, 43 / 60, "lethal contact time")
  close(defined(events[0]).impactX, 14343, "lethal projectile preimage")
  assert.equal(defined(events[0]).targetAtImpactX, 14352, "receipt target coordinate is before loot placement")
  const team = preparedTeam(101, snapshots)
  const { result } = resolveMovedEnemy(team, victim)
  assert.equal(result.row.body.hp, 0)
  assert.notEqual(result.row.body.kind, 0, "lethal resolver produced a loot incarnation")
  assert.equal(result.row.body.x, 14272, "actual loot placement clamps to the player upper edge")
  assert.notEqual(
    result.row.body.x,
    defined(events[0]).targetAtImpactX,
    "receipt does not use the post-loot coordinate"
  )
}
// The same pooled target seed denotes a distinct incarnation at a new birth
// tick. A fresh spawn routed through Game's SL.Fresh branch bypasses old contact
// effects and receives clean Motion, while an existing incarnation is damaged.
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
  assert.notEqual(defined(oldEvents[0]).id, defined(newEvents[0]).id, "reused seed must not reuse the old lifetime ID")
  const team = preparedTeam(101, [source, newborn])
  assert.deepEqual(array(defined(hitPlans(team)[0]).targets), [77])
  const previousDormant = { ...newborn.body, kind: 8, age: 5, hp: 0 }
  const freshRow = {
    $: "Row" as const,
    body: newborn.body,
    hit: 0,
    xp: 0,
    gold: 0,
    heal: 0,
    chest: 0,
    killed: 0,
    relic: 0
  }
  const fresh = Game.team_enemy_updated(
    team,
    previousDormant,
    { $: "Status" as const, slow: 65536, burn: 37 },
    freshRow
  )
  assert.equal(fresh.row.body.hp, 100, "SL.Fresh bypasses the prepared old-incarnation hit")
  assert.deepEqual(
    fresh.motion,
    {
      $: "Motion" as const,
      vx: 0,
      vy: 0,
      life: 0,
      pierce: 0,
      visited: nil(),
      slow: 0,
      burn: 0,
      ownerBase: 0,
      logicalSlot: 0
    },
    "newborn does not inherit stale contact status"
  )
  const previousLive = { ...newborn.body, kind: 0, age: 0 }
  const existingRow = {
    $: "Row" as const,
    body: { ...newborn.body, kind: 0, age: 1 },
    hit: 0,
    xp: 0,
    gold: 0,
    heal: 0,
    chest: 0,
    killed: 0,
    relic: 0
  }
  const existing = Game.team_enemy_updated(
    team,
    previousLive,
    { $: "Status" as const, slow: 65536, burn: 37 },
    existingRow
  )
  assert.equal(existing.row.body.hp, 93, "the same prepared hit applies to an existing incarnation")
}
console.log(
  "PASS Core contact receipts against analytic sweep, AoE edge, lethal pre-loot geometry, and reused-seed newborn fixtures"
)
