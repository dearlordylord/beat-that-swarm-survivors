import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
import { bendModule } from "../../examples/bend-module.mts"
import { gameFrame } from "../../examples/survivors/observations.mts"
import { defined } from "../../examples/survivors/host-values.mts"
import { parseGoals } from "./observations.mts"
import { createPlanner, planMovement } from "./planner.mts"

const { default: Game } = await bendModule<BendABI.BotActions.API>()(
  pathToFileURL(resolve(process.env.BOT_ACTIONS_MODULE ?? "examples/survivors/dist/bot-actions.mjs")),
  ["fresh_start_seed", "advance", "observed_packet"]
)
function observe(packet: BendABI.Game.Packet) {
  const observed = Game.observed_packet(packet)
  assert.ok(observed.$ === "Observed")
  return {
    state: observed.state,
    frame: gameFrame(observed.frame),
    catalog: parseGoals(JSON.parse(observed.actions)).filter((goal) => goal.kind === "approach_relic")
  }
}
const packet = Game.fresh_start_seed(12345)
assert.ok(packet.$ === "Packet")
const first = observe(Game.advance(packet.state, 0, 0))
const memory = createPlanner({ maxCandidates: 1 })
const initial = defined(planMovement(memory, first.frame, first.catalog).chosen)
const identity = initial.identity,
  waypoints = initial.waypoints
const second = observe(Game.advance(first.state, 0, 0))
const firstRelic = defined(first.frame.pickups.find((pickup) => pickup.item.kind === "relic"))
const secondRelic = defined(second.frame.pickups.find((pickup) => pickup.item.kind === "relic"))
assert.notEqual(firstRelic.generation, secondRelic.generation, "actual relic presentation generation ticks")
const continued = planMovement(memory, second.frame, second.catalog)
assert.equal(defined(continued.chosen).identity, identity, "unchanged relic retains its navigation objective")
assert.equal(memory.lastPlan, first.frame.tick, "generation-only refresh preserves the previous route plan")
assert.equal(continued.search.expanded, 0)
assert.equal(defined(continued.chosen).waypoints, waypoints, "route memory survives the next public observation")
assert.equal(defined(continued.chosen).goal.observedTick, second.frame.tick, "current catalog IDs still refresh")

const changedStage = structuredClone(second)
const stageRelic = defined(changedStage.frame.pickups.find((pickup) => pickup.item.kind === "relic"))
assert.ok(stageRelic.item.kind === "relic")
stageRelic.item.stage++
changedStage.frame.stage++
const stagePlan = planMovement(memory, changedStage.frame, changedStage.catalog)
assert.notEqual(defined(stagePlan.chosen).identity, identity, "another stage is a distinct relic objective")
const stageIdentity = defined(stagePlan.chosen).identity
const changedSlot = structuredClone(changedStage)
const slotRelic = defined(changedSlot.frame.pickups.find((pickup) => pickup.item.kind === "relic"))
const oldSlot = slotRelic.slot
slotRelic.slot++
changedSlot.frame.actorOrder = changedSlot.frame.actorOrder.map((ref) =>
  "pickup" in ref && ref.pickup === oldSlot ? { pickup: slotRelic.slot } : ref
)
changedSlot.catalog = changedSlot.catalog.map((goal) => ({
  ...goal,
  id: `t${changedSlot.frame.tick}:approach_relic:${slotRelic.slot}:relic:${slotRelic.age}`
}))
assert.notEqual(
  defined(planMovement(memory, changedSlot.frame, changedSlot.catalog).chosen).identity,
  stageIdentity,
  "another slot is a distinct relic objective"
)
console.log("Planner relic objectives retain routes across actual ticking presentation generations")
