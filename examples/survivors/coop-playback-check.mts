import { bendModule } from "../bend-module.mts"
import { object, number, array as parseArray, list, rows as array, defined } from "./host-values.mts"
import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import { pathToFileURL } from "node:url"
import { resolve } from "node:path"
// Executable diagnostics of the emitted Bend model, not a substitute for laws.
// Usage: bend coop-playback.bend -o /tmp/coop-playback.mjs
//        node coop-playback-check.mts /tmp/coop-playback.mjs

const { default: P } = await bendModule<BendABI.CoopPlayback.API>()(
  pathToFileURL(resolve(process.argv[2] ?? "examples/survivors/dist/coop-playback.mjs")).href,
  [
    "accepts",
    "advance",
    "boost",
    "clock",
    "elapsed",
    "fraction_after",
    "fresh",
    "fresh_for",
    "is_buffering",
    "matched",
    "mode_rate",
    "observations",
    "push",
    "rate_for",
    "recovered_cursor",
    "refill",
    "sample",
    "tick_after",
    "waiting"
  ]
)
const actor = (key: number, x: number, extra = {}) => ({
  $: "Actor" as const,
  key,
  kind: 1,
  generation: `generation-${key}`,
  x,
  y: x / 2,
  age: 1,
  hp: 1,
  owner: 0,
  ...extra
})
const frame = (
  observation: number,
  tick: number,
  receivedAt: number,
  players: BendABI.CoopPlayback.Actor[] = [],
  bodies: BendABI.CoopPlayback.Actor[] = []
) => ({ $: "Frame" as const, observation, tick, receivedAt, players: list(players), bodies: list(bodies) })
const sample = (state: BendABI.CoopPlayback.State) => {
  const out = P.sample(state)
  assert.ok(out.$ === "Some")
  return out.value
}
const time = (state: BendABI.CoopPlayback.State) => Number(state.cursor.tick) * 1000000 + state.cursor.fraction
let checks = 0
const check = (condition: unknown, message: string) => {
  assert.ok(condition, message)
  checks++
}
check(P.fresh_for(0).delay === 3, "host keeps three-tick buffer")
check(P.fresh_for(1).delay === 6, "guest uses six-tick buffer")
let s = P.fresh()
check(P.sample(s).$ === "None", "no invented startup frame")
s = P.push(s, frame(1, 0, 100, [actor(0, 0)], [actor(42, 0)]))
check(sample(s).tick === 0, "initial tick zero visible")
const _initial = s
check(!P.accepts(s, frame(1, 30, 500)), "cache rejects duplicate observation")
assert.deepEqual(P.push(s, frame(1, 30, 500)), s)
checks++
assert.deepEqual(P.push(s, frame(0, 30, 500)), s)
checks++
s = P.push(s, frame(2, 3, 50100, [actor(0, 3)], [actor(42, 3)]))
s = P.advance(s, 50100)
check(s.cursor.tick === 0 && P.is_buffering(s), "wait six authority ticks")
s = P.push(s, frame(3, 6, 100100, [actor(0, 6)], [actor(42, 6), actor(43, 6)]))
s = P.advance(s, 100100)
check(
  !P.is_buffering(s) && s.cursor.tick === 2 && s.cursor.fraction === 40,
  "buffer release spends at most33334µs of the last sample interval"
)
s = P.advance(s, 125100)
let v = sample(s)
check(v.tick === 3 && v.fraction === 500040, "continuous 60Hz fraction")
check(Math.abs(defined(defined(array(v.players))[0]).x - 3.50004) < 1e-5, "remote player interpolates")
check(Math.abs(defined(defined(array(v.bodies))[0]).x - 3.50004) < 1e-5, "enemy shares player time")
check(array(v.bodies).length === 1, "future birth hidden")
s = P.advance(s, 200100)
v = sample(s)
check(v.tick === 6 && P.is_buffering(s), "underrun clamps latest")
check(array(v.bodies).length === 2, "birth visible at authority time")
assert.deepEqual(P.push(s, frame(4, 5, 210000)), s)
checks++
s = P.push(s, frame(4, 6, 210000, [actor(0, 6)], [actor(42, 6, { hp: 0 })]))
check(sample(s).baseObservation === 4, "paused same-tick metadata refreshes")
check(array(P.observations(s)).length === 3, "same-tick replacement does not grow queue")
for (let observation = 5; observation <= 50; observation++) {
  s = P.push(
    s,
    frame(
      observation,
      observation * 3,
      Number(observation) * 50000,
      [actor(0, observation * 3)],
      [actor(42, observation * 3)]
    )
  )
  check(array(P.observations(s)).length <= 8, "bounded eight-frame history")
}
check(s.recovered, "eviction diagnosed")
check(s.cursor.tick === 129, "evicted cursor moves forward to oldest retained tick")
const identities = [{ generation: "replacement" }, { kind: 2 }, { owner: 1 }, { key: 43 }, { hp: 0 }]
for (const diff of identities) {
  assert.deepEqual(P.matched({ $: "Some" as const, value: actor(42, 99, diff) }, actor(42, 1), 0.5), actor(42, 1))
  checks++
}
// Emitted Bend 2.0.38 Nat ABI is an exact integer Number up to 2^53.
// Timestamp above the 49-day U32 millisecond boundary remains exact.
const huge = 4300000000000
check(P.elapsed(huge + 16667, huge) === 16667, "Nat timestamp preserves elapsed beyond 49 days")
check(P.elapsed(huge - 1, huge) === 0, "clock regression contributes zero")
check(P.elapsed(huge + 90000000, huge) === 1000000, "background resume caps elapsed")
check(P.tick_after(4294967290, 60000000) === 4294967295, "U32 cursor saturates")
// A delayed startup must converge rather than retaining the initial backlog forever.
let catchup = P.push(P.fresh(), frame(1, 0, 0))
catchup = P.push(catchup, frame(2, 20, 0))
catchup = P.advance(catchup, 0)
let catchupObservation = 2,
  catchupLatest = 20,
  catchupRecovery = 0
for (let i = 1; i <= 180; i++) {
  const at = i * 16667
  if (i % 3 === 0) {
    catchupLatest = 20 + i
    catchup = P.push(catchup, frame(++catchupObservation, catchupLatest, at))
    if (catchup.recovered) catchupRecovery++
  }
  const before = time(catchup)
  catchup = P.advance(catchup, at)
  check(time(catchup) - before <= 1400028, "catch-up advances at most forty percent faster, without a cursor seek")
}
check(
  catchupLatest - catchup.cursor.tick - catchup.cursor.fraction / 1000000 <= 10,
  "twenty-tick startup backlog converges within three seconds"
)
check(catchupRecovery === 0, "convergence does not rely on history eviction recovery")
let refill = P.push(P.fresh(), frame(1, 0, 0))
refill = P.push(refill, frame(2, 6, 100000))
refill = P.advance(refill, 100000)
refill = P.advance(refill, 200000)
check(P.is_buffering(refill) && refill.cursor.tick === 6, "refill scenario begins with real underrun")
refill = P.push(refill, frame(3, 26, 300000))
refill = P.advance(refill, 300000)
let refillObservation = 3,
  refillLatest = 26
for (let i = 1; i <= 180; i++) {
  const at = 300000 + i * 16667
  if (i % 3 === 0) {
    refillLatest = 26 + i
    refill = P.push(refill, frame(++refillObservation, refillLatest, at))
  }
  const before = time(refill)
  refill = P.advance(refill, at)
  check(time(refill) - before <= 1400028 && !refill.recovered, "post-underrun catch-up stays continuous")
}
check(
  refillLatest - refill.cursor.tick - refill.cursor.fraction / 1000000 <= 10,
  "post-underrun backlog also converges within three seconds"
)
check(P.rate_for(100, 107, 6) === 60, "delay plus one remains inside the deadband")
check(P.rate_for(100, 108, 6) === 66, "backlog beyond delay plus one enables bounded catch-up")
const firstCatchupClock = P.clock(
  { ...P.fresh().cursor, tick: 100, lastAt: 0, mode: { $: "Playing" as const } },
  16667,
  108,
  6
)
check(
  firstCatchupClock.tick === 101 && firstCatchupClock.fraction === 100022,
  "lower deadband starts with one gradual tick rather than a clock skip"
)
check(P.rate_for(4294967295, 0, 6) === 60, "backward authority cannot wrap into excess backlog")
check(P.rate_for(0, 4294967295, 4294967295) === 60, "delay plus margin does not wrap U32")
check(P.fraction_after(0, huge + 90000000, huge, 66) === 66000000, "catch-up resume clamps before rate multiplication")
check(
  P.fraction_after(0, Number.MAX_SAFE_INTEGER, Number.MAX_SAFE_INTEGER - 16667, 66) === 1100022,
  "safe-integer timestamp edge preserves fractional catch-up"
)
let paused = P.advance(catchup, 9000000)
check(
  P.is_buffering(paused) && paused.cursor.tick === catchupLatest,
  "stopped authority clamps accelerated presentation at latest"
)
const pausedPosition = time(paused)
for (let i = 1; i <= 20; i++) {
  paused = P.push(paused, frame(++catchupObservation, catchupLatest, 9000000 + i * 50000))
  paused = P.advance(paused, 9000000 + i * 50000)
  check(
    time(paused) === pausedPosition && P.is_buffering(paused),
    "same-tick paused snapshots never cause catch-up drift"
  )
}
// Adversarial frame/clock schedule: drops, repeats, regressing timestamps and long stalls.
let previousTime = 0,
  now = 0,
  observation = 1,
  tick = 0
s = P.push(P.fresh(), frame(observation, tick, now, [actor(0, 0)], [actor(42, 0)]))
for (let i = 1; i <= 4000; i++) {
  now += i % 101 === 0 ? 2000000 : Number(9000 + ((i * 7919) % 18000))
  if (i % 3 === 0) {
    observation++
    tick += i % 17 === 0 ? 15 : 3
    s = P.push(s, frame(observation, tick, now, [actor(0, tick)], [actor(42, tick)]))
  }
  if (i % 19 === 0) s = P.push(s, frame(observation - 1, tick + 50, now))
  s = P.advance(s, i % 37 === 0 ? now - 500000 : now)
  check(
    Number.isInteger(s.cursor.fraction) && s.cursor.fraction >= 0 && s.cursor.fraction < 1000000,
    "reachable fraction invariant"
  )
  const cursor = time(s)
  check(cursor >= previousTime, "presentation cursor never rewinds")
  previousTime = cursor
  check(s.cursor.tick <= tick, "never extrapolates beyond authority")
  check(array(P.observations(s)).length <= 8, "history remains bounded")
  v = sample(s)
  check(v.alpha >= 0 && v.alpha <= 1, "reachable sample alpha bounded")
  check(
    defined(defined(array(v.players))[0]).x === defined(defined(array(v.bodies))[0]).x,
    "whole combat cohort shares cursor"
  )
}
// Large actor cohort exercises stack-safe mapping and indexed lookup.
const rows = Array.from({ length: 12000 }, (_, i) => actor(i, i))
s = P.push(P.fresh(), frame(1, 0, 0, [], rows))
s = P.push(
  s,
  frame(
    2,
    6,
    100000,
    [],
    rows.map((a) => ({ ...a, x: a.x + 6 }))
  )
)
s = P.advance(s, 0)
s = P.advance(s, 50000)
const large = array(sample(s).bodies)
check(large.length === 12000, "large cohort retains all rows")
check(defined(large[11999]).x === 12002, "large cohort mapped in order")
// The observed producer hole is replayed through actual emitted Bend. This
// fixture intentionally stores no model implementation or actor world payload.
const fixtureRow = object(
  JSON.parse(await readFile(new URL("./fixtures/coop-playback-producer-gap.json", import.meta.url), "utf8"))
)
const fixture = {
  arrivals: parseArray(fixtureRow.arrivals, (value): [number, number, number] => {
    const row = parseArray(value, number)
    return [number(row[0]), number(row[1]), number(row[2])]
  }),
  samples: parseArray(fixtureRow.samples, (value): [number, number, number, number] => {
    const row = parseArray(value, number)
    return [number(row[0]), number(row[1]), number(row[2]), number(row[3])]
  }),
  expected: (() => {
    const row = object(fixtureRow.expected)
    return {
      windowMs: number(row.windowMs),
      p95LagTicks: number(row.p95LagTicks),
      maxLagTicks: number(row.maxLagTicks),
      maxWindowP95Ticks: number(row.maxWindowP95Ticks)
    }
  })()
}
let replay = P.fresh(),
  arrivalIndex = 0,
  priorCursor = 0
const lagValues = [],
  windowValues = new Map<number, number[]>()
for (const [at, wall, workerTick, measured] of fixture.samples) {
  while (arrivalIndex < fixture.arrivals.length && defined(fixture.arrivals[arrivalIndex])[0] <= at) {
    const [received, obs, tick] = defined(fixture.arrivals[arrivalIndex++])
    replay = P.push(replay, frame(obs, tick, received))
  }
  if (replay.frames.$ === "Nil") continue
  replay = P.advance(replay, at)
  check(time(replay) >= priorCursor, "retained producer-gap trace never rewinds")
  priorCursor = time(replay)
  check(!replay.recovered, "retained producer gap does not recover by cursor seek")
  if (measured) {
    const lag = Math.max(0, workerTick - replay.cursor.tick)
    lagValues.push(lag)
    const index = Math.floor(wall / fixture.expected.windowMs)
    const rows = windowValues.get(index) || []
    rows.push(lag)
    windowValues.set(index, rows)
  }
}
const percentile95 = (rows: number[]) => [...rows].sort((a, b) => a - b)[Math.ceil(rows.length * 0.95) - 1] ?? 0
const traceClock = {
  samples: lagValues.length,
  p95: percentile95(lagValues),
  max: Math.max(...lagValues),
  windows: [...windowValues.values()].map(percentile95)
}
check(traceClock.p95 <= fixture.expected.p95LagTicks, "actual failed clock trace overall lag gate")
check(traceClock.max <= fixture.expected.maxLagTicks, "actual failed clock trace maximum lag gate")
check(
  traceClock.windows.every((value) => value <= fixture.expected.maxWindowP95Ticks),
  "actual failed clock trace every5s lag gate"
)
// Exact threshold and reset edges; only the explicit Mode stores hysteresis.
for (const mode of ["Priming", "Holding", "Playing", "Boosting"] as const) {
  check(P.waiting({ $: mode }) === (mode === "Priming" || mode === "Holding"), "only waiting modes are buffering")
  check(P.refill({ $: mode }, 6) === (mode === "Priming" ? 6 : 1), "startup and starvation have distinct refill")
  for (const gap of [0, 1, 6, 7, 8, 10, 11, 20]) {
    check(
      P.boost({ $: mode }, 100, 100 + gap, 6) === gap > (mode === "Boosting" ? 7 : 10),
      "exact hysteresis thresholds"
    )
    const rate = P.mode_rate({ $: mode }, 100, 100 + gap, 6)
    check(rate >= 60 && rate <= 84, "all mode rates bounded")
  }
}
for (const gap of [0, 1, 2, 5, 6]) {
  const cursor = (mode: BendABI.CoopPlayback.Mode["$"]) => ({
    $: "Cursor" as const,
    tick: 100,
    fraction: 0,
    lastAt: 0,
    mode: { $: mode }
  })
  const primed = P.clock(cursor("Priming"), 10000, 100 + gap, 6),
    held = P.clock(cursor("Holding"), 10000, 100 + gap, 6)
  check(P.waiting(primed.mode) === gap < 6, "initial playback waits configured six ticks")
  check(P.waiting(held.mode) === gap < 1, "starved playback resumes at one tick")
}
for (const gapMicros of [16667, 33334, 33335, 1000000, 4300000000000, Number.MAX_SAFE_INTEGER - 100]) {
  const held = { $: "Cursor" as const, tick: 100, fraction: 500000, lastAt: 100, mode: { $: "Holding" as const } }
  const result = P.clock(held, gapMicros + 100, 120, 6)
  check(result.lastAt === gapMicros + 100, "resume discards whole suspension debt by recording current clock")
  check(
    (result.tick - 100) * 1000000 + result.fraction - 500000 === Math.min(gapMicros, 33334) * 84,
    "resume spends only last interval capped at33334µs"
  )
  const repeated = P.clock(result, gapMicros + 100, 120, 6)
  check(
    repeated.tick === result.tick && repeated.fraction === result.fraction,
    "repeat timestamp never repays discarded debt"
  )
}
let hold: BendABI.CoopPlayback.Cursor = {
  $: "Cursor" as const,
  tick: 100,
  fraction: 0,
  lastAt: 0,
  mode: { $: "Holding" as const }
}
for (let i = 1; i <= 100; i++) hold = P.clock(hold, i * 16667, 100, 6)
const resumed = P.clock(hold, 101 * 16667, 101, 6)
check(
  resumed.tick === 101 && resumed.fraction === 0 && resumed.mode.$ === "Holding",
  "long hold resumes only one received tick, no extrapolation"
)
const reset = P.recovered_cursor(
  true,
  { $: "Cursor" as const, tick: 100, fraction: 999999, lastAt: 1, mode: { $: "Boosting" as const } },
  110
)
check(reset.mode.$ === "Priming" && reset.fraction === 0, "history recovery clears boost and reprimes")
// Deterministic production rates are diagnostic, not a promise that a30Hz
// authority can look like60Hz. Thin supply must not leave emergency latched.
const producerDiagnostics = []
for (const hz of [60, 45, 30])
  for (const hole of [false, true]) {
    let producer = P.fresh(),
      obs = 0,
      event = 0,
      previous = 0,
      stationary = 0,
      boosted = 0,
      measured = 0
    const events: [number, number, number][] = []
    for (let ms = 0; ms <= 10000; ms += 50) {
      if (hole && ms >= 5000 && ms < 5150) continue
      events.push([ms + 300, ++obs, Math.floor((ms * hz) / 1000)])
    }
    for (let i = 0; i <= 600; i++) {
      const at = 300000 + i * 16667
      while (event < events.length && defined(defined(events[event])[0]) * 1000 <= at) {
        const [ms, id, tick] = defined(events[event++])
        producer = P.push(producer, frame(id, tick, ms * 1000))
      }
      if (producer.frames.$ === "Nil") continue
      producer = P.advance(producer, at)
      assert.ok(producer.frames.$ === "Con")
      const current = time(producer)
      check(current >= previous, "slow producer cursor monotone")
      check(producer.cursor.tick <= producer.frames.head.frame.tick, "slow producer never extrapolates")
      check(array(P.observations(producer)).length <= 8, "slow producer memory bounded")
      if (i > 60) {
        measured++
        if (current === previous) stationary++
        if (producer.cursor.mode.$ === "Boosting") boosted++
      }
      previous = current
    }
    if (hz < 60) check(boosted === 0, "thin producer never remains in emergency mode")
    producerDiagnostics.push({ hz, hole, stationaryFraction: stationary / measured, boostedSamples: boosted })
  }
console.log(
  JSON.stringify({
    status: "PASS",
    checks,
    traceSteps: 4000,
    largeActors: 12000,
    traceClock,
    producerDiagnostics,
    scope: "emitted Bend snapshot playback diagnostics"
  })
)
