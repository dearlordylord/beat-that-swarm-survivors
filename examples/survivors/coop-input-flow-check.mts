import { bendModule } from "../bend-module.mts"
import { list, rows as array, defined, some } from "./host-values.mts"
import assert from "node:assert/strict"
import { pathToFileURL, fileURLToPath } from "node:url"
interface PendingWrite {
  batch: BendABI.CoopInputFlow.Batch
  payload: string
}
interface NativeWrite extends PendingWrite {
  done: number
}
type ActiveWrite = { kind: "ack"; done: number } | ({ kind: "input"; done: number } & PendingWrite)

// Deterministic boundary check, not a general latency benchmark. The former
// 16-command/8-command-batch budget could not sustain 60 Hz at 200 ms writes;
// these checks cover the approved 64/62/2 journal and 32-row batch budget.

const location =
  process.env.COOP_FLOW_MODULE || fileURLToPath(new URL("./dist/web/dist/coop-input-flow.mjs", import.meta.url))
const Flow = (
  await bendModule<BendABI.CoopInputFlow.API>()(pathToFileURL(location).href, [
    "complete",
    "decode",
    "encode",
    "enqueue",
    "fail",
    "fresh",
    "journal",
    "max_batch",
    "max_commands",
    "max_controls",
    "max_frame_bytes",
    "max_inputs",
    "prepare"
  ])
).default
const command = (
  seq: number,
  target: number,
  action: BendABI.CoopSession.Action = { $: "MovementTick" as const, round: 3, x: seq % 3, y: (seq + 1) % 3 }
) => ({ $: "Command" as const, session: 7, player: 1, seq, intendedTick: target, action })
const byteLength = (wire: string) => new TextEncoder().encode(wire).length
const maximum = 0xffffffff
assert.equal(Flow.max_commands(), 64)
assert.equal(Flow.max_inputs(), 62)
assert.equal(Flow.max_controls(), 2)
assert.equal(Flow.max_batch(), 32)
assert.equal(Flow.max_frame_bytes(), 5156)
const rows = Array.from({ length: 32 }, (_, index: number) =>
  command(
    index + 1,
    maximum - index,
    index % 4 === 0
      ? { $: "Setup" as const, character: 7, arcana: 11, meta: maximum, allowedWeapons: 16777215 }
      : index % 4 === 1
        ? { $: "Choice" as const, round: maximum, index: 15 }
        : index % 4 === 2
          ? { $: "Movement" as const, x: 0, y: 2 }
          : { $: "MovementTick" as const, round: 3, x: index % 3, y: (index + 1) % 3 }
  )
)
const encoded = Flow.encode({ $: "Batch" as const, epoch: 1, id: 4, commands: list(rows) })
assert.ok(byteLength(encoded) <= Flow.max_frame_bytes())
assert.deepEqual(
  array(some(Flow.decode(encoded))),
  rows,
  "thirty-two varied commands round-trip without rewriting targets"
)
const thirtyThree = list([...rows, command(33, 33)])
const encodedThirtyThree = Flow.encode({ $: "Batch" as const, epoch: 1, id: 5, commands: thirtyThree })
assert.ok(
  byteLength(encodedThirtyThree) <= Flow.max_frame_bytes(),
  "the thirty-third-row fixture isolates the row-count bound"
)
assert.ok(Flow.decode(encodedThirtyThree).$ === "None", "a thirty-third row is refused")
// U32-max fields exercise the longest decimal spelling for every action shape;
// these are codec values, not a claim that Session authorizes those actions.
for (const action of [
  { $: "Movement" as const, x: maximum, y: maximum },
  { $: "MovementTick" as const, round: maximum, x: maximum, y: maximum },
  { $: "Choice" as const, round: maximum, index: maximum },
  { $: "Setup" as const, character: maximum, arcana: maximum, meta: maximum, allowedWeapons: maximum }
]) {
  const largest = Array.from({ length: 32 }, (_, index: number) => ({
    $: "Command" as const,
    session: maximum,
    player: maximum,
    seq: maximum - index,
    intendedTick: maximum,
    action
  }))
  const wire = Flow.encode({ $: "Batch" as const, epoch: maximum, id: maximum, commands: list(largest) })
  assert.ok(byteLength(wire) <= Flow.max_frame_bytes(), "thirty-two maximum-width action fields fit the frame bound")
  assert.deepEqual(array(some(Flow.decode(wire))), largest)
}
const broken = encoded.split("\n")
broken[8] += "|malformed"
assert.ok(Flow.decode(broken.join("\n")).$ === "None", "a malformed middle row refuses the entire batch")
assert.ok(Flow.decode("X".repeat(Flow.max_frame_bytes() + 1)).$ === "None", "oversized frames are refused")
assert.ok(Flow.decode("BSB1").$ === "None")
assert.ok(Flow.decode(encoded + "\n").$ === "None")
assert.ok(Flow.decode(defined(encoded.split("\n")[1])).$ === "None", "standalone Setup is refused")
let reserved = Flow.fresh(5)
for (let index = 0; index < 62; index++) {
  const admitted = Flow.enqueue(reserved, command(index + 1, index + 1))
  assert.equal(admitted.accepted, true)
  reserved = admitted.state
}
const fullInputs = Flow.enqueue(reserved, command(63, 63))
assert.equal(fullInputs.accepted, false)
assert.deepEqual(fullInputs.state, reserved)
for (let index = 0; index < 2; index++) {
  const admitted = Flow.enqueue(reserved, command(63 + index, 0, { $: "Choice" as const, round: 3, index }))
  assert.equal(admitted.accepted, true)
  reserved = admitted.state
}
assert.equal(array(Flow.journal(reserved)).length, 64)
assert.equal(array(Flow.journal(reserved)).filter((row) => row.action.$ === "MovementTick").length, 62)
assert.equal(Flow.enqueue(reserved, command(65, 0, { $: "Choice" as const, round: 3, index: 0 })).accepted, false)
const flight = Flow.prepare(reserved)
assert.ok(flight.batch.$ === "Some")
assert.equal(array(flight.batch.value.commands).length, 32)
assert.deepEqual(
  array(Flow.journal(flight.state)),
  array(Flow.journal(reserved)),
  "reserving a write retains the exact journal"
)
const failed = Flow.fail(flight.state, flight.batch.value.epoch, flight.batch.value.id)
assert.equal(failed.failed, true)
assert.deepEqual(array(Flow.journal(failed)), array(Flow.journal(reserved)))
assert.ok(Flow.prepare(failed).batch.$ === "None")
assert.deepEqual(
  Flow.complete(failed, flight.batch.value.epoch, flight.batch.value.id),
  failed,
  "late success cannot revive a failed flow"
)
function slowPipe(writeMs: number) {
  let state = Flow.fresh(19),
    native: NativeWrite | null = null,
    now = 0,
    nextInput = 0,
    seq = 0,
    displayTick = 0,
    blocked = 0,
    blockedInputs = 0,
    writes = 0,
    maxJournal = 0
  const activeNative = (): NativeWrite => defined(native)
  const accepted: BendABI.CoopSession.Command[] = [],
    delivered: BendABI.CoopSession.Command[] = []
  const flush = () => {
    const prepared = Flow.prepare(state)
    state = prepared.state
    if (prepared.batch.$ === "None") return
    assert.equal(native, null, "one native write at a time, never an unbounded promise queue")
    const batch = prepared.batch.value,
      payload = Flow.encode(batch)
    assert.ok(array(batch.commands).length <= 32)
    assert.ok(byteLength(payload) <= Flow.max_frame_bytes())
    native = { batch, payload, done: now + writeMs }
    writes++
  }
  const submit = (action: BendABI.CoopSession.Action) => {
    const input = action.$ === "MovementTick",
      candidate = command(seq + 1, input ? displayTick + 1 : 0, action)
    const admitted = Flow.enqueue(state, candidate),
      before = displayTick
    if (!admitted.accepted) {
      blocked++
      if (input) blockedInputs++
      assert.equal(displayTick, before, "rejected admission cannot advance prediction")
      return false
    }
    state = admitted.state
    seq++
    if (input) displayTick++
    accepted.push(candidate)
    return true
  }
  for (now = 0; now <= 5000; now++) {
    if (native && activeNative().done <= now) {
      const completed = activeNative()
      native = null
      const decoded = Flow.decode(completed.payload)
      assert.ok(decoded.$ === "Some")
      delivered.push(...array(decoded.value))
      state = Flow.complete(state, completed.batch.epoch, completed.batch.id)
    }
    if (now >= nextInput) {
      submit({ $: "MovementTick" as const, round: 3, x: Math.floor(now / 300) % 3, y: 1 })
      nextInput += 1000 / 60
    }
    if (now === 1700)
      assert.equal(
        submit({ $: "Choice" as const, round: 3, index: 1 }),
        true,
        "reserved control capacity survives input backpressure"
      )
    if (now % 50 === 0) flush()
    const journal = array(Flow.journal(state))
    maxJournal = Math.max(maxJournal, journal.length)
    assert.ok(journal.length <= 64)
    assert.ok(journal.filter((row) => row.action.$ === "MovementTick").length <= 62)
  }
  for (let turns = 0; array(Flow.journal(state)).length && turns < 100; turns++) {
    if (!native) flush()
    assert.ok(native)
    now = activeNative().done
    const completed = activeNative()
    native = null
    delivered.push(...array(some(Flow.decode(completed.payload))))
    state = Flow.complete(state, completed.batch.epoch, completed.batch.id)
  }
  assert.deepEqual(
    delivered,
    accepted,
    "every accepted command, including controls, arrives unchanged exactly once and in order"
  )
  assert.equal(array(Flow.journal(state)).length, 0)
  assert.equal(delivered.filter((row) => row.action.$ === "Choice").length, 1)
  return {
    writeMs,
    accepted: accepted.length,
    movementAccepted: accepted.filter((row) => row.action.$ === "MovementTick").length,
    blocked,
    blockedInputs,
    writes,
    maxJournal,
    allAcceptedDelivered: true
  }
}
const [ordinary, slow] = [slowPipe(200), slowPipe(600)]
assert.ok(
  ordinary.movementAccepted >= 300 && ordinary.movementAccepted <= 302,
  "200 ms writes sustain roughly 300 60 Hz movement ticks over five seconds"
)
assert.ok(ordinary.blockedInputs <= 2, "the 200 ms case has no or bounded startup backpressure")
assert.ok(slow.blockedInputs > 0, "600 ms writes force bounded movement backpressure")
console.log(
  JSON.stringify({
    pass: true,
    codecRows: rows.length,
    maxWidthRows: 32,
    reservedControls: 2,
    slowPipe: [ordinary, slow],
    latencyClaim: false
  })
)
// Shared serialized transport: every native input write waits behind a200ms
// snapshot ACK write, then takes200ms itself. This is a virtual schedule, not a
// claim about Iroh throughput. Target ticks are assigned once and never moved.
function sharedLane(writeMs: number, generateMs = 10000) {
  let state = Flow.fresh(73),
    pending: PendingWrite | null = null,
    active: ActiveWrite | null = { kind: "ack", done: writeMs },
    nextInput = 0
  const accepted: BendABI.CoopSession.Command[] = [],
    delivered: BendABI.CoopSession.Command[] = []
  let seq = 0,
    displayTick = 54,
    blocked = 0,
    maxJournal = 0,
    late = 0,
    applied = 0,
    lastWorld = -1
  const due = new Map<number, BendABI.CoopSession.Command>()
  for (let now = 0; now <= generateMs + 5000; now++) {
    if (active && active.done <= now) {
      if (active.kind === "ack") {
        active = pending ? { ...pending, kind: "input", done: now + writeMs } : null
        pending = null
      } else {
        const rows = array(some(Flow.decode(active.payload)))
        delivered.push(...rows)
        for (const row of rows)
          if (row.action.$ === "MovementTick") {
            if (row.intendedTick <= Math.floor((now * 60) / 1000)) late++
            else due.set(row.intendedTick, row)
          }
        state = Flow.complete(state, active.batch.epoch, active.batch.id)
        active = { kind: "ack", done: now + writeMs }
      }
    }
    if (now < generateMs && now >= nextInput) {
      const candidate = command(seq + 1, displayTick + 1, {
        $: "MovementTick" as const,
        round: 3,
        x: Math.floor(now / 1000) % 3,
        y: 1
      })
      const admitted = Flow.enqueue(state, candidate)
      state = admitted.state
      if (admitted.accepted) {
        seq++
        displayTick++
        accepted.push(candidate)
      } else blocked++
      nextInput += 1000 / 60
    }
    if (now % 50 === 0) {
      const prepared = Flow.prepare(state)
      state = prepared.state
      if (prepared.batch.$ === "Some") {
        assert.equal(pending, null, "one waiting input write")
        const batch = prepared.batch.value,
          payload = Flow.encode(batch)
        assert.ok(array(batch.commands).length <= 32)
        if (active) pending = { batch, payload }
        else active = { batch, payload, kind: "input", done: now + writeMs }
      }
    }
    const journal = array(Flow.journal(state))
    maxJournal = Math.max(maxJournal, journal.length)
    assert.ok(journal.length <= 64)
    assert.ok(journal.filter((r) => r.action.$ === "MovementTick").length <= 62)
    const world = Math.floor((now * 60) / 1000)
    if (world !== lastWorld) {
      if (due.has(world)) {
        applied++
        due.delete(world)
      }
      lastWorld = world
    }
  }
  assert.deepEqual(delivered, accepted, "shared lane preserves all command fields and FIFO")
  assert.equal(array(Flow.journal(state)).length, 0, "all accepted shared-lane commands drain")
  return { writeMs, generateMs, accepted: accepted.length, blocked, maxJournal, late, applied }
}
const shared200 = sharedLane(200)
assert.ok(shared200.accepted >= 599 && shared200.accepted <= 601, "shared200ms lanes sustain60Hz")
assert.equal(shared200.blocked, 0, "native flight plus pending history has enough admission capacity")
assert.equal(shared200.late, 0, "lead54 sends each movement before its immutable target tick")
assert.equal(shared200.applied, shared200.accepted, "every accepted movement applies at its original target tick")
const shared600 = sharedLane(600)
assert.ok(shared600.blocked > 0, "shared600ms lanes degrade under bounded admission pressure")
console.log(
  JSON.stringify({
    pass: true,
    sharedLane: [shared200, shared600],
    leadTicks: 54,
    scope: "emitted model under fixed virtual ACK/input service schedule; not network qualification"
  })
)
