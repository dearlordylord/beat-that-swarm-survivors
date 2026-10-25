import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
import vm from "node:vm"
import ts from "typescript-compiler-api"
import { bendModule } from "../../examples/bend-module.mts"
import { gameFrame } from "../../examples/survivors/observations.mts"
import { at, defined, object } from "../../examples/survivors/host-values.mts"
import type { Frame } from "./observations.mts"
import { actorThreats, createPlanner, planMovement, routePath } from "./planner.mts"
import { steering, runBot } from "./runner.mts"
import { buildGoalDecision, buildUpgradeDecision } from "./context.mts"

const { default: Game } = await bendModule<BendABI.BotActions.API>()(
  pathToFileURL(resolve(process.env.BOT_ACTIONS_MODULE ?? "examples/survivors/dist/bot-actions.mjs")),
  ["fresh_start_seed", "advanced_start_seed", "observed_packet", "advance", "choose"]
)
const packet = Game.fresh_start_seed(12345)
const observed = Game.observed_packet(packet)
assert.ok(observed.$ === "Observed")
const frame: Frame = {
  ...gameFrame(observed.frame),
  tick: 100,
  phase: 0,
  px: 1800,
  py: 1800,
  hp: 100,
  maxHp: 100,
  enemies: [
    { identity: 5, x: 1900, y: 1800, radius: 12, health: 20, maximum: 20, archetype: 21, age: 40, lifetime: "5:60" }
  ],
  projectiles: [8, 9].map((identity) => ({
    identity,
    x: identity === 8 ? 1850 : 1700,
    y: 1800,
    radius: 4,
    hostile: identity === 8,
    lifetime: `${identity}:80`,
    weapon: 0,
    damage: 7,
    age: 20,
    vx: 1,
    vy: 0,
    life: 30,
    pierce: 1,
    sourcePlayer: identity === 8 ? null : 0,
    weaponOwner: 0,
    logicalSlot: 0,
    birthTick: 80,
    tick: 100
  })),
  pickups: [
    {
      slot: 4,
      generation: 10,
      age: 90,
      active: true,
      x: 1700,
      y: 1800,
      radius: 8,
      item: { kind: "xp", amount: 7, accumulator: false }
    }
  ],
  actorOrder: [{ projectile: 8 }, { pickup: 4 }, { enemy: 5 }, { projectile: 9 }]
}
const xp = (f: Frame, baseXp = 7) => ({
  id: `t${f.tick}:approach_experience:4:xp:${at(f.pickups, 0).age}`,
  kind: "approach_experience",
  observedTick: f.tick,
  distance: 100,
  target: { x: 1700, y: 1800 },
  resource: { baseXp, generation: at(f.pickups, 0).generation, autoClaimTicks: null }
})
const north = (f: Frame) => ({
  id: `t${f.tick}:move_north:north`,
  kind: "move_north",
  observedTick: f.tick,
  distance: 160,
  target: { x: 1800, y: 1640 }
})
assert.deepEqual(
  actorThreats(frame).map((t) => [t.x, t.hostile]),
  [
    [1850, true],
    [1900, false]
  ]
)
assert.ok(steering(frame, null).every(Number.isFinite))
assert.ok(routePath(frame, { x: 1700, y: 1800 }).reachable)
const memory = createPlanner()
planMovement(memory, frame, [xp(frame), north(frame)])
const key = at(Object.keys(memory.objects), 0)
assert.equal(key, "approach_experience:4:xp:10")
const next = structuredClone(frame)
next.tick++
const pickup = at(next.pickups, 0)
pickup.age++
assert.ok(pickup.item.kind === "xp")
pickup.item.amount = 11
planMovement(memory, next, [xp(next, 11), north(next)])
assert.equal(defined(memory.objects[key]).firstSeen, 100)
assert.equal(defined(memory.objects[key]).value, 11)
pickup.generation = 101
planMovement(memory, next, [xp(next, 11), north(next)])
assert.equal(at(Object.keys(memory.objects), 0), "approach_experience:4:xp:101")
assert.equal(at(Object.values(memory.objects), 0).firstSeen, 101)
const options = { runId: "test", decisionSeq: 1 }
const decision = buildGoalDecision(frame, [xp(frame), north(frame)], options)
assert.equal(
  object(defined(decision.candidates.find((c) => c.goal.kind === "approach_experience")).effect.resource).slot,
  4
)
assert.throws(
  () =>
    buildGoalDecision(
      frame,
      [{ ...xp(frame), resource: { ...xp(frame).resource, generation: 99 } }, north(frame)],
      options
    ),
  /current persistent engine pile/
)
const upgrade = buildUpgradeDecision({ ...frame, phase: 1, offers: [{ kind: 2, id: 0, level: 0 }] }, options)
assert.equal(upgrade.snapshot.threats.livingEnemies, 1)
assert.equal(upgrade.snapshot.threats.hostileProjectiles, 1)
const summary = await runBot(Game, { ticks: 2, decisions: "upgrades" })
assert.equal(summary.tick, 2)
assert.ok(Number.isFinite(summary.uncollectedBaseXp))

const journal = ts.transpileModule(await readFile(new URL("./journal-client.mts", import.meta.url), "utf8"), {
  compilerOptions: { target: ts.ScriptTarget.ES2023, module: ts.ModuleKind.ESNext }
}).outputText
const drawSource = journal.slice(journal.indexOf("function draw("), journal.indexOf("function render("))
const colors: string[] = []
const arcs: number[][] = []
const ctx = {
  fillStyle: "",
  clearRect() {},
  beginPath() {},
  moveTo() {},
  lineTo() {},
  stroke() {},
  fill() {
    colors.push(this.fillStyle)
  },
  arc(...args: number[]) {
    arcs.push(args)
  }
}
vm.runInNewContext(drawSource + ";draw(frame,undefined)", {
  frame,
  $: () => ({ getContext: () => ctx }),
  required: defined,
  selectedCandidate: () => null
})
assert.equal(arcs.length, 5)
assert.deepEqual(colors, ["#eeeeee", "#75bfff", "#f47579", "#eeeeee", "#fff"])
const browser = ts.transpileModule(
  await readFile(new URL("./coop-reliability-browser-check.mts", import.meta.url), "utf8"),
  { compilerOptions: { target: ts.ScriptTarget.ES2023, module: ts.ModuleKind.ESNext } }
).outputText
const motionSource = browser.slice(
  browser.indexOf("function motionOracle("),
  browser.indexOf("function inputCoverage(")
)
const diagnostic: unknown = vm.runInNewContext(motionSource + ";motionOracle(rows,0)", {
  assert,
  defined,
  p95: () => 0,
  rows: [
    { wall: 6000, phase: 0, runId: 1, round: 1, enemies: [{ identity: 5, lifetime: "born1", x: 10, y: 10 }] },
    { wall: 6100, phase: 0, runId: 1, round: 1, enemies: [{ identity: 5, lifetime: "born2", x: 100, y: 100 }] },
    { wall: 6200, phase: 0, runId: 1, round: 1, enemies: [{ identity: 5, lifetime: "born2", x: 106, y: 100 }] }
  ]
})
assert.ok(typeof diagnostic === "object" && diagnostic !== null && "enemies" in diagnostic)
assert.deepEqual(JSON.parse(JSON.stringify(diagnostic.enemies)), {
  samples: 1,
  maxUnitsPerWallTick: 1,
  p95UnitsPerWallTick: 0,
  scope: "same-generation diagnostics; monster dash mechanics have no asserted speed bound"
})
console.log("Actor consumer fixtures passed with the actual typed runner boundary")
