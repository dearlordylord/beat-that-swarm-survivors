import { bendModule } from "../bend-module.mts"
import { rows as array } from "./host-values.mts"
import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
// Fresh emitted Bend diagnostics. Queue bounds do not promise network latency.

const F = (
  await bendModule<BendABI.CoopSnapshotFlow.API>()(
    pathToFileURL(resolve(process.argv[2] || "examples/survivors/dist/web/dist/coop-snapshot-flow.mjs")).href,
    ["ack", "complete", "decode_receipt", "encode_receipt", "fresh", "offer", "prepare", "window"]
  )
).default
const value = <T,>(m: BendMaybe<T>) => (m.$ === "Some" ? m.value : null)
const dispatch = (state: BendABI.CoopSnapshotFlow.State) => {
  const p = F.prepare(state)
  assert.ok(p.observation.$ === "Some")
  return p
}
assert.equal(F.window(), 16)
let s = F.fresh(7)
for (let id = 0; id < 16; id++) {
  s = F.offer(s, id)
  const p = dispatch(s)
  s = p.state
  assert.deepEqual(F.prepare(s).state, s, "native write cannot overlap")
  assert.deepEqual(F.complete(s, 8, id), s, "old connection completion ignored")
  assert.deepEqual(F.complete(s, 7, id + 1), s, "wrong observation completion ignored")
  s = F.complete(s, 7, id)
  assert.equal(array(s.flights).length, id + 1, "native completion retains application flight")
}
for (let id = 16; id < 10000; id++) {
  s = F.offer(s, id)
  assert.equal(value(F.prepare(s).observation), null, "full application window blocks dispatch")
  assert.equal(array(s.flights).length, 16)
  assert.equal(value(s.pending), id, "only latest unsent pending retained")
  assert.deepEqual(F.offer(s, id), s, "duplicate offer ignored")
  assert.deepEqual(F.ack(s, 7, id), s, "unsent future ACK cannot free capacity")
}
assert.deepEqual(F.ack(s, 8, 7), s, "stale connection application ACK ignored")
s = F.ack(s, 7, 3)
assert.deepEqual(
  array(s.flights),
  [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
  "exact member ACK cumulatively removes previous observations"
)
assert.deepEqual(F.ack(s, 7, 2), s, "out-of-order older ACK cannot affect remaining flights")
let p = dispatch(s)
assert.equal(value(p.observation), 9999)
s = p.state
s = F.ack(s, 7, 9999)
assert.equal(array(s.flights).length, 0, "latest ACK releases cumulative window")
assert.equal(value(s.writing), 9999, "application ACK arriving before native completion keeps writer busy")
s = F.offer(s, 10000)
assert.equal(value(F.prepare(s).observation), null, "early ACK does not overlap writer")
s = F.complete(s, 7, 9999)
assert.equal(value(dispatch(s).observation), 10000)
// ACK membership is exact even if coalescing skipped numeric observation IDs.
s = F.fresh(9)
for (const id of [1, 3, 7]) {
  p = dispatch(F.offer(s, id))
  s = F.complete(p.state, 9, id)
}
assert.deepEqual(F.ack(s, 9, 2), s, "nonmember between sent observations is refused")
assert.deepEqual(array(F.ack(s, 9, 3).flights), [7])
// A stable 800ms application round trip supports20Hz using at most sixteen IDs.
s = F.fresh(11)
let native = null,
  acks: { at: number; id: number }[] = [],
  sent = 0,
  maxFlights = 0
for (let now = 0; now <= 60000; now += 10) {
  if (native && native.at <= now) {
    s = F.complete(s, 11, native.id)
    native = null
  }
  for (const ack of acks.filter((a) => a.at <= now)) s = F.ack(s, 11, ack.id)
  acks = acks.filter((a) => a.at > now)
  if (now % 50 === 0) s = F.offer(s, now / 50)
  p = F.prepare(s)
  s = p.state
  if (p.observation.$ === "Some") {
    assert.equal(native, null, "at most one native write")
    const id = p.observation.value
    native = { at: now + 20, id }
    acks.push({ at: now + 800, id })
    sent++
  }
  maxFlights = Math.max(maxFlights, array(s.flights).length)
  assert.ok(maxFlights <= 16)
}
assert.equal(sent, 1201, "20Hz publication sustained for60s at800ms app ACK")
assert.equal(maxFlights, 16, "test fills the entire sixteen-snapshot window")
// Epoch reset cannot be reopened by a stale completion or cumulative ACK.
const fresh = F.fresh(12)
assert.deepEqual(F.ack(fresh, 11, 1200), fresh)
assert.deepEqual(F.complete(fresh, 11, 1200), fresh)
for (const token of [0, 1, 4294967295])
  for (const observation of [0, 1, 4294967295]) {
    const text = F.encode_receipt(token, observation)
    assert.ok(text.length <= 26)
    assert.deepEqual(F.decode_receipt(text), {
      $: "Some" as const,
      value: { $: "Receipt" as const, token, observation }
    })
  }
for (const text of [
  "",
  "BSA1|1",
  "BSA1|1|2|3",
  "BSA1|-1|2",
  "BSA1|01|2",
  "BSA1|4294967296|0",
  "BSA1|0|1x",
  "BSA1|0|0\n",
  "X|0|0",
  "BSA1|0|000000000000000000000000000"
])
  assert.deepEqual(F.decode_receipt(text), { $: "None" as const }, text)
console.log(
  JSON.stringify({
    status: "PASS",
    offers: 10000,
    window: 16,
    nativeWrites: 1,
    pending: 1,
    simulatedMs: 60000,
    appAckMs: 800,
    publicationHz: 20,
    sent,
    maxFlights,
    scope: "pure emitted model; not browser throughput"
  })
)
