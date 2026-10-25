import assert from "node:assert/strict"
import { test } from "node:test"
import { motionOracle } from "./coop-motion-oracle.mts"
import type { RenderRow } from "./coop-browser-trace.mts"

function row(sampledAt: number, drawAt: number, x: number, recovered = false): RenderRow {
  return {
    at: drawAt,
    wall: drawAt + 100000,
    tick: Math.floor((sampledAt * 60) / 1000),
    phase: 0,
    round: 0,
    runId: "run",
    presentationMeasurement: { sampledAt, callbackEntry: sampledAt, onDisplayEnd: drawAt },
    remotePresentation: {
      sampledAt,
      sourceTick: 1,
      tick: 1,
      fraction: 0,
      alpha: 0,
      baseObservation: 1,
      nextObservation: 2,
      retainedFrames: 8,
      recovered,
      buffering: false
    },
    players: [{ id: 0, px: x, py: 0, character: 0, hp: 70, maxHp: 70, alive: true, connected: true }],
    enemies: []
  }
}
const startWall = 100000

await test("normal selected trajectory is independent of delays after sampling and after drawing", (context) => {
  const samples = [6000, 6023.9, 6047.8]
  const immediate = samples.map((at) => row(at, at, ((at * 60) / 1000) * 2.5))
  const delayed = samples.map((at, index) => row(at, at + (index === 0 ? 18 : 0.6), ((at * 60) / 1000) * 2.5))
  const baseline = motionOracle(immediate, startWall)
  const result = motionOracle(delayed, startWall)
  assert.equal(result.host.samples, 2)
  assert.equal(result.host.violationCount, 0)
  assert.equal(result.host.maxUnitsPerWallTick, baseline.host.maxUnitsPerWallTick)
  const evaluationClock = context.mock.method(Date, "now", () => 1000000)
  const earlierEvaluation = motionOracle(delayed, startWall)
  evaluationClock.mock.mockImplementation(() => 9000000)
  assert.deepEqual(
    motionOracle(delayed, startWall),
    earlierEvaluation,
    "delayed observation cannot alter recorded coordinate elapsed time"
  )
  assert.ok(
    (2.5 * 23.9 * 60) / 1000 > (4 * 6.5 * 60) / 1000 + 1,
    "the former draw clock rejects this known legal trajectory"
  )
})

await test("physical overspeed is rejected even when delayed drawing would conceal it", () => {
  const result = motionOracle([row(6000, 6000, 0), row(6000 + 1000 / 60, 6200, 10)], startWall)
  assert.equal(result.host.samples, 1)
  assert.equal(result.host.violationCount, 1)
})

await test("the recorded stock 200ms recovery jump still fails the unchanged speed bound", () => {
  const result = motionOracle(
    [row(29829.89999985695, 29830.799999952316, 7593.90185546875), row(29949.39999985695, 29950.5, 7639.5, true)],
    startWall
  )
  assert.equal(result.buffer.recoveryEntries, 1)
  assert.equal(result.host.violationCount, 1)
})

await test("enemy diagnostics pair actual lifetimes rather than recycled identities", () => {
  const a = row(6000, 6000, 0),
    b = row(6100, 6100, 0),
    c = row(6200, 6200, 0)
  a.enemies = [{ identity: 5, lifetime: "born1", x: 10, y: 10 }]
  b.enemies = [{ identity: 5, lifetime: "born2", x: 100, y: 100 }]
  c.enemies = [{ identity: 5, lifetime: "born2", x: 106, y: 100 }]
  assert.deepEqual(motionOracle([a, b, c], startWall).enemies, {
    samples: 1,
    maxUnitsPerWallTick: 1,
    p95UnitsPerWallTick: 1,
    scope: "same-generation diagnostics; monster dash mechanics have no asserted speed bound"
  })
})

await test("missing sample clocks fail instead of silently using draw timestamps", () => {
  const a = row(6000, 6000, 0),
    b = row(6100, 6100, 0)
  b.presentationMeasurement = undefined
  assert.throws(() => motionOracle([a, b], startWall), /Missing required value/)
})

await test("a finite telemetry wrapper cannot replace a missing remote sample clock", () => {
  const a = row(6000, 6000, 0),
    b = row(6100, 6100, 0)
  b.remotePresentation = undefined
  assert.throws(() => motionOracle([a, b], startWall), /Missing required value/)
})

await test("telemetry and remote sample clocks must match", () => {
  const a = row(6000, 6000, 0),
    b = row(6100, 6100, 0)
  b.presentationMeasurement = { sampledAt: 6101, callbackEntry: 6100, onDisplayEnd: 6100 }
  assert.throws(() => motionOracle([a, b], startWall), /must retain the actual remote presentation sample clock/)
})

await test("a nonfinite actual remote clock is rejected despite finite telemetry", () => {
  const a = row(6000, 6000, 0),
    b = row(6100, 6100, 0)
  assert.ok(b.remotePresentation)
  b.remotePresentation.sampledAt = Number.NaN
  assert.throws(() => motionOracle([a, b], startWall), /actual remote presentation sample clock/)
})
