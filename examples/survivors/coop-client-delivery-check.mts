import { bendModule } from "../bend-module.mts"
import { list, rows as array, defined, some } from "./host-values.mts"
import assert from "node:assert/strict"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
// Fresh emitted composite delivery diagnostics; not a network latency proof.

const D = (
  await bendModule<BendABI.CoopClientDelivery.API>()(
    pathToFileURL(resolve(process.argv[2] || "examples/survivors/dist/web/dist/coop-client-delivery.mjs")).href,
    [
      "complete",
      "decode",
      "encode",
      "enqueue",
      "fail",
      "fresh",
      "max_frame_bytes",
      "offer_receipt",
      "prepare",
      "prepared_children"
    ]
  )
).default
const _nil = { $: "Nil" as const }
const command = (
  seq: number,
  target = seq + 54,
  action: BendABI.CoopSession.Action = { $: "MovementTick" as const, round: 1, x: 2, y: 1 }
) => ({ $: "Command" as const, session: 7, player: 1, seq, intendedTick: target, action })
const receipt = (token: number, observation: number) => ({ $: "Receipt" as const, token, observation })
const inputRows = (state: BendABI.CoopClientDelivery.State) => [
  ...(state.input.flight.$ === "Some" ? array(state.input.flight.value.commands) : []),
  ...array(state.input.pending)
]
const send = (state: BendABI.CoopClientDelivery.State) => {
  const p = D.prepare(state)
  assert.ok(p.packet.$ === "Some")
  return p
}
const roundtrip = (packet: BendABI.CoopClientDelivery.Packet) => {
  const wire = D.encode(packet)
  assert.ok(new TextEncoder().encode(wire).length <= D.max_frame_bytes())
  const parsed = D.decode(wire)
  assert.ok(parsed.$ === "Some")
  return parsed.value
}
assert.equal(D.max_frame_bytes(), 5190)
let s = D.fresh(3)
assert.ok(D.prepare(s).packet.$ === "None")
const empty = D.prepared_children(
  3,
  0,
  { $: "Prepared" as const, state: s.input, batch: { $: "None" as const } },
  { $: "Prepared" as const, state: s.receipts, receipt: { $: "None" as const } }
)
assert.ok(empty.packet.$ === "None")
assert.equal(empty.state.nextId, 0, "both idle children never spend a packet ID")
// Input plus receipt share one reservation and one unchanged encoded payload.
for (let i = 1; i <= 20; i++) {
  const out = D.enqueue(s, command(i))
  assert.equal(out.accepted, true)
  s = out.state
}
s = D.offer_receipt(s, 9, 100)
let p = send(s)
s = p.state
let payload = roundtrip(some(p.packet))
assert.deepEqual(payload.receipt, { $: "Some" as const, value: receipt(9, 100) })
assert.deepEqual(
  array(payload.commands),
  Array.from({ length: 20 }, (_, i) => command(i + 1))
)
assert.deepEqual(
  D.prepare(s),
  { $: "Prepared" as const, state: s, packet: { $: "None" as const } },
  "busy prepare preserves both children"
)
// Later offers/commands survive completion of exactly the stored children.
s = D.offer_receipt(s, 9, 101)
s = D.enqueue(s, command(21)).state
assert.deepEqual(D.complete(s, 4, some(p.packet).id), s, "stale epoch completion")
assert.deepEqual(D.complete(s, 3, some(p.packet).id + 1), s, "wrong shared packet ID")
s = D.complete(s, 3, some(p.packet).id)
assert.deepEqual(inputRows(s), [command(21)])
assert.equal(s.receipts.pending, true)
assert.equal(some(s.receipts.latest).observation, 101)
p = send(s)
payload = roundtrip(some(p.packet))
assert.equal(some(payload.receipt).observation, 101)
assert.deepEqual(array(payload.commands), [command(21)])
// ACK-only failure retains queued input, fences both lanes and ignores late success.
s = D.offer_receipt(D.fresh(8), 91, 12)
p = send(s)
s = p.state
assert.ok(some(p.packet).batch.$ === "None")
s = D.enqueue(s, command(1)).state
s = D.offer_receipt(s, 91, 13)
const before = inputRows(s)
s = D.fail(s, 8, some(p.packet).id)
assert.equal(s.failed, true)
assert.deepEqual(inputRows(s), before)
assert.equal(some(s.receipts.latest).observation, 13)
assert.equal(D.enqueue(s, command(2)).accepted, false)
assert.deepEqual(D.offer_receipt(s, 91, 14), s)
assert.ok(D.prepare(s).packet.$ === "None")
assert.deepEqual(D.complete(s, 8, some(p.packet).id), s)
// A failed input-bearing packet retains its exact child journal too.
s = D.enqueue(D.fresh(10), command(1)).state
p = send(s)
s = D.fail(p.state, 10, some(p.packet).id)
assert.equal(s.input.failed, true)
assert.deepEqual(inputRows(s), [command(1)])
// Maximal fields exercise all command actions without Session authorization claims.
const max = 0xffffffff
for (const action of [
  { $: "Movement" as const, x: max, y: max },
  { $: "MovementTick" as const, round: max, x: max, y: max },
  { $: "Choice" as const, round: max, index: max },
  { $: "Setup" as const, character: max, arcana: max, meta: max, allowedWeapons: max }
]) {
  const commands = Array.from({ length: 32 }, (_, i) => ({
    $: "Command" as const,
    session: max,
    player: max,
    seq: max - i,
    intendedTick: max,
    action
  }))
  const packet = {
    $: "Packet" as const,
    epoch: max,
    id: max,
    batch: { $: "Some" as const, value: { $: "Batch" as const, epoch: max, id: max, commands: list(commands) } },
    receipt: { $: "Some" as const, value: receipt(max, max) }
  }
  payload = roundtrip(packet)
  assert.deepEqual(array(payload.commands), commands)
  assert.deepEqual(payload.receipt, packet.receipt)
}
// Decode both children atomically; neither a good ACK nor a valid command prefix
// can escape a malformed sibling/middle row.
const batch = { $: "Batch" as const, epoch: 1, id: 1, commands: list([command(1), command(2), command(3)]) }
const packet = {
  $: "Packet" as const,
  epoch: 1,
  id: 1,
  batch: { $: "Some" as const, value: batch },
  receipt: { $: "Some" as const, value: receipt(9, 22) }
}
const good = D.encode(packet),
  bad = good.split("\n")
bad[4] += "|bad"
for (const text of [
  bad.join("\n"),
  good.replace("BSA1|9|22", "BSA1|09|22"),
  "BSC1\n-\n",
  "BSC1\nBSA1|9|22\nBSB1\nnot-a-command",
  "X".repeat(5191)
])
  assert.ok(D.decode(text).$ === "None", text.slice(0, 40))
assert.equal(some(some(D.decode("BSA1|9|22")).receipt).observation, 22, "standalone receipt compatibility")
const single = "BSC1|7|1|1|0|S|0|0|0|0"
assert.equal(array(some(D.decode(single)).commands).length, 1, "plain Setup compatibility")
const batchText = good.split("\n").slice(2).join("\n")
assert.equal(array(some(D.decode(batchText)).commands).length, 3, "standalone batch compatibility")
const tooMany = {
  $: "Packet" as const,
  epoch: 1,
  id: 2,
  batch: {
    $: "Some" as const,
    value: {
      $: "Batch" as const,
      epoch: 1,
      id: 2,
      commands: list(Array.from({ length: 33 }, (_, i) => command(i + 1)))
    }
  },
  receipt: packet.receipt
}
assert.ok(D.decode(D.encode(tooMany)).$ === "None", "33 commands refused without processing good ACK")
function sharedNative(writeMs: number, generateMs = 10000) {
  let state = D.fresh(73),
    native = null,
    nextInput = 0,
    seq = 0,
    displayTick = 54,
    blocked = 0,
    maxJournal = 0,
    packets = 0,
    piggybacked = 0,
    late = 0,
    applied = 0,
    lastWorld = -1
  const accepted = [],
    delivered = [],
    acks: number[] = [],
    due = new Map()
  for (let now = 0; now <= generateMs + 5000; now++) {
    if (native && native.done <= now) {
      const parsed = D.decode(native.wire)
      assert.ok(parsed.$ === "Some")
      const rows = array(parsed.value.commands)
      delivered.push(...rows)
      if (parsed.value.receipt.$ === "Some") acks.push(parsed.value.receipt.value.observation)
      for (const row of rows) {
        if (row.intendedTick <= Math.floor((now * 60) / 1000)) late++
        else due.set(row.intendedTick, row)
      }
      state = D.complete(state, native.packet.epoch, native.packet.id)
      native = null
    }
    if (now < generateMs && now >= nextInput) {
      const c = command(seq + 1, displayTick + 1),
        out = D.enqueue(state, c)
      state = out.state
      if (out.accepted) {
        accepted.push(c)
        seq++
        displayTick++
      } else blocked++
      nextInput += 1000 / 60
    }
    // New host observations arrive independently of the local input timer.
    if (now < generateMs && now % 50 === 0) state = D.offer_receipt(state, 17, now / 50)
    if (now % 50 === 0) {
      const prepared = D.prepare(state)
      state = prepared.state
      if (prepared.packet.$ === "Some") {
        assert.equal(native, null, "one shared native writer")
        const packet = prepared.packet.value,
          wire = D.encode(packet)
        native = { packet, wire, done: now + writeMs }
        packets++
        if (packet.batch.$ === "Some" && packet.receipt.$ === "Some") piggybacked++
      }
    }
    maxJournal = Math.max(maxJournal, inputRows(state).length)
    assert.ok(maxJournal <= 64)
    assert.ok((state.receipts.pending ? 1 : 0) + (state.receipts.flight.$ === "Some" ? 1 : 0) <= 2)
    const world = Math.floor((now * 60) / 1000)
    if (world !== lastWorld) {
      if (due.has(world)) {
        applied++
        due.delete(world)
      }
      lastWorld = world
    }
  }
  assert.deepEqual(delivered, accepted, "all composite inputs arrive unchanged in FIFO order")
  assert.equal(inputRows(state).length, 0)
  assert.ok(
    acks.every((id: number, i) => i === 0 || id > defined(acks[i - 1])),
    "ACKs are coalesced and strictly increase"
  )
  return {
    writeMs,
    accepted: accepted.length,
    blocked,
    maxJournal,
    packets,
    piggybacked,
    late,
    applied,
    lastAck: acks.at(-1)
  }
}
const normal = sharedNative(200),
  overload = sharedNative(600)
assert.equal(normal.accepted, 600)
assert.equal(normal.blocked, 0)
assert.equal(normal.late, 0)
assert.equal(normal.applied, 600)
assert.ok(normal.piggybacked >= 49)
assert.equal(normal.lastAck, 199)
assert.ok(overload.blocked > 0, "overload stays bounded instead of inventing movement")
console.log(
  JSON.stringify({
    status: "PASS",
    codecRows: 32,
    atomicDecode: true,
    sharedNative: [normal, overload],
    scope: "emitted composite state/codec model; not actual Iroh throughput"
  })
)
