import { bendModule } from "../bend-module.mts"
import assert from "node:assert/strict"
import { pathToFileURL } from "node:url"
import { resolve } from "node:path"
const root = pathToFileURL(resolve(process.argv[2] ?? "examples/survivors/dist/web/dist") + "/")
const { default: Finish } = await bendModule<BendABI.CoopFinish.API>()(new URL("coop-finish.mjs", root), [
  "fresh",
  "terminal",
  "begin",
  "applied",
  "expire",
  "closed"
])
const { default: Flow } = await bendModule<BendABI.CoopSnapshotFlow.API>()(new URL("coop-snapshot-flow.mjs", root), [
  "fresh",
  "offer",
  "prepare",
  "matches",
  "complete",
  "ack"
])
assert.equal(Finish.terminal(0), false)
assert.equal(Finish.terminal(2), false)
assert.equal(Finish.terminal(3), true)
assert.equal(Finish.terminal(4), true)
assert.equal(Finish.terminal(5), false)
assert.deepEqual(Finish.expire(Finish.fresh()), Finish.fresh(), "Active games survive drain deadlines")
let state = Finish.begin(Finish.fresh(), 3)
for (let remaining = 2; remaining >= 0; remaining--) {
  state = Finish.applied(state)
  assert.equal(Finish.closed(state), remaining === 0, "Every connected recipient must apply the final observation")
}
assert.deepEqual(Finish.applied(state), state, "Completion is idempotent")
assert.equal(Finish.closed(Finish.begin(Finish.fresh(), 0)), true, "Empty rooms close immediately")
assert.equal(
  Finish.closed(Finish.expire(Finish.begin(Finish.fresh(), 3))),
  true,
  "Missing or slow guests cannot retain a room"
)
let flow = Flow.offer(Flow.fresh(19), 30)
assert.equal(Flow.matches(flow, 19, 30), false, "An offered observation is not an application receipt obligation")
flow = Flow.prepare(flow).state
assert.equal(Flow.matches(flow, 20, 30), false, "Another connection token cannot acknowledge a final observation")
assert.equal(Flow.matches(flow, 19, 29), false, "A stale receipt cannot acknowledge a final observation")
assert.equal(Flow.matches(flow, 19, 31), false, "A forged future receipt cannot acknowledge a final observation")
flow = Flow.complete(flow, 19, 30)
assert.equal(Flow.matches(flow, 19, 30), true, "Native completion still requires an application receipt")
flow = Flow.ack(flow, 19, 30)
assert.equal(Flow.matches(flow, 19, 30), false, "Duplicate receipts cannot settle twice")
console.log("Terminal drain policy and authenticated receipt laws passed")
