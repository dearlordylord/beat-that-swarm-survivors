import { defined } from "./host-values.mts"
// Fresh emitted Bend checks. Offers represent snapshots already admitted by IO.
// Native delivery/cadence is verified by the browser integration, not this model.
import assert from "node:assert/strict"
import { pathToFileURL } from "node:url"
import { resolve } from "node:path"
const { default: R }: { default: BendABI.CoopSnapshotReceipts.API } = await import(
  pathToFileURL(resolve(process.argv[2] ?? "examples/survivors/dist/coop-snapshot-receipts.mjs")).href
)
const value = <T,>(maybe: BendMaybe<T>) => (maybe.$ === "Some" ? maybe.value : null)
let checks = 0
const check = (condition: unknown, message: string) => {
  assert.ok(condition, message)
  checks++
}
const equal = (actual: unknown, expected: unknown, message: string) => {
  assert.deepEqual(actual, expected, message)
  checks++
}
check(R.max_frame_bytes() === 26 && R.max_buffered_bytes() === 52, "bounded receipt bytes")
let state = R.fresh(7)
equal(
  R.prepare(state),
  { $: "Prepared" as const, state, receipt: { $: "None" as const } },
  "fresh state cannot acknowledge anything"
)
state = R.offer(state, 900, 10)
check(R.buffered_count(state) === 1 && R.buffered_bytes(state) === 26, "one waiting receipt")
let prepared = R.prepare(state)
state = prepared.state
equal(
  value(prepared.receipt),
  { $: "Receipt" as const, token: 900, observation: 10 },
  "dispatch exactly the accepted host identity"
)
check(!state.pending && R.buffered_count(state) === 1, "dispatch moves waiting work into native flight")
state = R.offer(state, 900, 11)
state = R.offer(state, 900, 12)
equal(
  value(state.flight),
  { $: "Receipt" as const, token: 900, observation: 10 },
  "new observations preserve the native flight"
)
equal(
  value(state.latest),
  { $: "Receipt" as const, token: 900, observation: 12 },
  "latest waiting observation replaces intermediate IDs"
)
check(
  R.buffered_count(state) === 2 && R.buffered_bytes(state) === 52,
  "one flight plus one pending is the whole budget"
)
equal(R.offer(state, 900, 11), state, "out-of-order offer cannot regress latest")
equal(R.offer(state, 900, 12), state, "duplicate offer does not create new work")
equal(R.offer(state, 901, 999), state, "different host token requires a fresh local connection")
equal(
  R.prepare(state),
  { $: "Prepared" as const, state, receipt: { $: "None" as const } },
  "a native flight blocks another dispatch"
)
equal(R.complete(state, 900, 900, 10), state, "host token cannot substitute for local callback epoch")
equal(R.complete(state, 7, 7, 10), state, "local epoch cannot substitute for host receipt token")
equal(R.complete(state, 7, 900, 12), state, "newest pending identity cannot complete the older flight")
state = R.complete(state, 7, 900, 10)
check(
  value(state.flight) === null && state.pending && defined(value(state.latest)).observation === 12,
  "matching completion preserves latest pending"
)
equal(R.complete(state, 7, 900, 10), state, "duplicate completion cannot consume pending work")
prepared = R.prepare(state)
state = prepared.state
check(defined(value(prepared.receipt)).observation === 12, "next timer dispatch skips superseded observation11")
state = R.complete(state, 7, 900, 12)
check(
  R.buffered_count(state) === 0 && R.buffered_bytes(state) === 0,
  "completed high-water metadata consumes no queued bytes"
)
equal(
  R.prepare(state),
  { $: "Prepared" as const, state, receipt: { $: "None" as const } },
  "completion alone cannot trigger an ACK loop"
)
equal(R.offer(state, 900, 12), state, "completed high-water observation cannot be re-enqueued")
// Same host identity and observation may occur on a new local connection.
let next = R.prepare(R.offer(R.fresh(8), 900, 12)).state
equal(R.complete(next, 7, 900, 12), next, "stale completion cannot clear the new connection flight")
next = R.complete(next, 8, 900, 12)
check(value(next.flight) === null, "new connection completion clears its own flight")
// Dense snapshot arrivals with a slow writer remain two records, not a queue.
state = R.fresh(17)
let lastSent = -1,
  dispatches = 0
const accepted = new Set()
for (let observation = 0; observation < 10000; observation++) {
  accepted.add(observation)
  state = R.offer(state, 4321, observation)
  const previousFlight = value(state.flight)
  const result = R.prepare(state)
  state = result.state
  if (result.receipt.$ === "Some") {
    const receipt = result.receipt.value
    check(
      receipt.observation === observation && accepted.has(receipt.observation),
      "dispatch is newest actually received snapshot"
    )
    check(receipt.observation > lastSent, "same-epoch dispatch high-watermark increases")
    lastSent = receipt.observation
    dispatches++
  } else equal(value(state.flight), previousFlight, "burst offers do not replace in-flight identity")
  check(R.buffered_count(state) <= 2 && R.buffered_bytes(state) <= 52, "all reachable queue budgets remain bounded")
  equal(R.offer(state, 4321, observation), state, "burst duplicate is inert")
  const flight = value(state.flight)
  if (observation % 37 === 36 && flight) state = R.complete(state, 17, flight.token, flight.observation)
}
if (value(state.flight)) {
  const flight = value(state.flight)
  state = R.complete(state, 17, defined(flight).token, defined(flight).observation)
}
prepared = R.prepare(state)
state = prepared.state
check(value(prepared.receipt)?.observation === 9999, "after stalled send only latest unsent receipt remains")
state = R.complete(state, 17, 4321, 9999)
check(value(R.prepare(state).receipt) === null, "final completion drains without self-restarting")
for (const token of [0, 1, 4294967295])
  for (const observation of [0, 1, 4294967295]) {
    const result = R.prepare(R.offer(R.fresh(123), token, observation))
    const receipt = value(result.receipt),
      text = R.encode(defined(receipt))
    check(
      text === `BSA1|${token}|${observation}` && new TextEncoder().encode(text).length <= 26,
      "boundary identities fit canonical receipt bytes"
    )
  }
console.log(
  JSON.stringify({
    status: "PASS",
    checks,
    offers: 10000,
    dispatches,
    queueCap: 2,
    byteCap: 52,
    scope: "emitted Bend ACK coalescing and callback fencing; not network cadence"
  })
)
