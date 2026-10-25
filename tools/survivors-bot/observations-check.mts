import assert from "node:assert/strict"
import { parseGoals, parseMechanics } from "./observations.mts"
import Game from "../../examples/survivors/dist/bot-actions.mjs"

for (const profile of ["fresh", "advanced"]) {
  const packet = profile === "fresh" ? Game.fresh_start_seed(12345) : Game.advanced_start_seed(12345)
  assert.equal(packet.$, "Packet")
  if (packet.$ !== "Packet") throw new Error("Start failed")
  const observed = Game.observe(packet.state)
  assert.equal(observed.$, "Observed")
  if (observed.$ !== "Observed") throw new Error("Observe failed")
  const goals: unknown = JSON.parse(observed.actions)
  const mechanics: unknown = JSON.parse(observed.mechanics)
  assert.deepEqual(parseGoals(goals), goals, "catalog parsing preserves the engine observation")
  assert.deepEqual(parseMechanics(mechanics), mechanics, "mechanics parsing preserves all engine preview fields")
  const parsed = parseMechanics(mechanics)
  assert.throws(() => parseMechanics({ ...parsed, current: { ...parsed.current, hp: "invalid" } }), TypeError)
  assert.throws(
    () => parseMechanics({ ...parsed, offers: [{ offerIndex: 0, offer: {}, after: parsed.current }] }),
    TypeError
  )
}
assert.throws(
  () => parseGoals([{ id: "goal", kind: "approach", target: { x: 0, y: Infinity }, distance: 1, observedTick: 0 }]),
  TypeError
)
assert.throws(() => parseGoals({}), TypeError)
console.log("Bot observation validation passed")
