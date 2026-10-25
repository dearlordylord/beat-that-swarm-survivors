import { bendModule } from "../bend-module.mts"
import assert from "node:assert/strict"
import { pathToFileURL, fileURLToPath } from "node:url"
// Deterministic pure-function regression check for adaptive prediction lead.

const location =
  process.env.COOP_PREDICTION_MODULE || fileURLToPath(new URL("./dist/web/dist/coop-prediction.mjs", import.meta.url))
const Prediction = (
  await bendModule<BendABI.CoopPrediction.API>()(pathToFileURL(location).href, [
    "choose_lead",
    "command",
    "cursor",
    "fresh",
    "reconcile",
    "tick"
  ])
).default
assert.equal(typeof Prediction.choose_lead, "function", "the public adaptive lead helper is exported")
const running = Prediction.fresh(0, 0, 1, true, 100, 10) // display cursor is world tick 110.
assert.equal(
  Prediction.choose_lead(running, 109, 0, 16),
  16,
  "a nondecreasing ordinary observation keeps the larger epoch lead"
)
assert.equal(Prediction.choose_lead(running, 110, 200, 8), 16, "a fresh RTT estimate cannot reduce the current lead")
assert.equal(Prediction.choose_lead(running, 120, 0, 8), 8, "a shorter RTT also preserves the current epoch lead")
assert.equal(Prediction.choose_lead(running, 99, 1000, 10), 10, "a backward authority anchor cannot update lead")
const disabled = Prediction.fresh(0, 0, 1, false, 100, 10)
assert.equal(
  Prediction.choose_lead(disabled, 100, 100, 4),
  10,
  "caller-seeded reset lead adapts on the admitted anchor"
)
assert.equal(Prediction.choose_lead(disabled, 99, 100, 4), 4, "backward anchor preserves the caller-seeded lead")
// lead(ms) = min(54, ceil(min(ms,1000)*60/1000)+4).
for (const [roundTripMs, expected] of [
  [0, 4],
  [1, 5],
  [100, 10],
  [200, 16],
  [833, 54],
  [1000, 54],
  [1001, 54],
  [0xffffffff, 54]
] as const) {
  assert.equal(
    Prediction.choose_lead(running, 100, roundTripMs, 3),
    expected,
    `RTT ${roundTripMs} ms raises the lead from a smaller current value`
  )
}
// A slow ACK raises a same-anchor cursor from lead38 to lead54. The already
// assigned input remains on world tick139; extending through154 adds only the
// existing neutral default, so position and input rows stay unchanged.
const list = <T,>(rows: BendList<T>) => {
  const out = []
  for (; rows?.$ === "Con"; rows = rows.tail) out.push(rows.head)
  return out
}
const initial = Prediction.fresh(0, 0, 1, true, 100, 38)
const assigned = Prediction.command(initial, 1, 2, 1)
const current = Prediction.tick(assigned)
assert.equal(current.displayWorldTick, 139, "fixture starts with lead38 and current cursor139")
assert.deepEqual(
  list(current.inputs).map((row) => [row.seq, row.targetWorldTick, row.x, row.y]),
  [[1, 139, 2, 1]],
  "input keeps its assigned target and axes"
)
const lead800 = Prediction.choose_lead(current, 100, 800, 38)
assert.equal(lead800, 52, "800 ms ACK grows lead38 to52")
assert.equal(Prediction.cursor(current, 100, lead800), 152, "cursor advances to anchor100 plus lead52")
const lead1000 = Prediction.choose_lead(current, 100, 1000, lead800)
assert.equal(lead1000, 54, "1000 ms ACK grows lead52 to capped lead54")
assert.equal(Prediction.choose_lead(current, 100, 0, lead1000), 54, "a later faster ACK does not reduce the epoch lead")
assert.equal(Prediction.cursor(current, 100, lead1000), 154, "cursor advances to anchor100 plus lead54")
const beforeExtension = Prediction.reconcile(current, 1, 100, 0, 0, 1, true, 38)
const afterExtension = Prediction.reconcile(current, 1, 100, 0, 0, 1, true, lead1000)
assert.equal(beforeExtension.displayWorldTick, 139, "same-anchor baseline keeps cursor139")
assert.equal(afterExtension.displayWorldTick, 154, "same-anchor RTT update extends cursor to154")
assert.deepEqual(
  list(afterExtension.inputs),
  list(beforeExtension.inputs),
  "reconciliation preserves the assigned input row exactly"
)
assert.deepEqual(
  [afterExtension.x, afterExtension.y],
  [beforeExtension.x, beforeExtension.y],
  "neutral ticks added after old cursor do not change position"
)
assert.deepEqual(
  Prediction.reconcile(current, 0, 100, 9, 9, 1, true, lead1000),
  current,
  "stale observations preserve the full timeline"
)
assert.deepEqual(
  Prediction.reconcile(current, 1, 99, 9, 9, 1, true, lead1000),
  current,
  "backward anchors preserve the full timeline"
)
console.log(
  JSON.stringify({
    pass: true,
    ordinaryLeadMonotone: true,
    backwardAnchorNoop: true,
    lead38To54: true,
    neutralExtensionPreservesPosition: true,
    pendingInputTarget: 139,
    rttCases: 8
  })
)
