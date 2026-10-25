// Production observation + transferable JSON versus a separately compiled master.
// The discarded binary experiment remains reproducible at commit 46d5863.
import assert from "node:assert/strict"
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises"
import { tmpdir, cpus } from "node:os"
import { join } from "node:path"
import { spawnSync } from "node:child_process"
import { fileURLToPath } from "node:url"
import { bendModule } from "../bend-module.mts"
import { list, rows, defined, object, array, parseJson } from "./host-values.mts"
import { corePacket } from "./coop-fixtures.mts"
import { coreFrame } from "./observations.mts"
import { admitSnapshot } from "./snapshot-envelope.mts"
import { encodeSnapshot, decodeSnapshot } from "./coop-snapshot-codec.mts"
const base = "01b4164612cd6e37d39aa75b16fab2dd253ebb0d"
const scratch = await mkdtemp(join(tmpdir(), "bendvy-observation-benchmark-"))
const samples = Number(process.env.SAMPLES || 100)
assert.ok(Number.isInteger(samples) && samples >= 10)
const encoder = new TextEncoder(),
  decoder = new TextDecoder("utf-8", { fatal: true })
const percentile = (values: number[], p: number) =>
  defined([...values].sort((a, b) => a - b)[Math.min(values.length - 1, Math.floor(values.length * p))])
const stats = (values: number[]) => ({
  p50Ms: +percentile(values, 0.5).toFixed(3),
  p95Ms: +percentile(values, 0.95).toFixed(3)
})
function normalize(value: unknown): unknown {
  if (typeof value === "number") return Number.isInteger(value) ? value : Math.fround(value)
  if (Array.isArray(value)) return value.map(normalize)
  if (value && typeof value === "object")
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, normalize(item)]))
  return value
}
function compile(source: string, output: string) {
  const result = spawnSync(process.env.BEND || "bend", [source, "-o", output], { encoding: "utf8", timeout: 30000 })
  if (result.status !== 0) throw Error(result.stdout + result.stderr)
}
function populated(state: BendABI.CoopCore.CoreState, count: number, statuses = false): BendABI.CoopCore.CoreState {
  const snapshots = Array.from(
    { length: count },
    (_, i): BendABI.Game.Snapshot => ({
      $: "Snapshot",
      body: {
        $: "Body",
        x: Math.fround(7100 + (i % 37) * 3.17),
        y: Math.fround(7100 + Math.floor(i / 37) * 2.23),
        kind: i % 7 === 0 ? 1 : 0,
        variant: i % 7 === 0 ? 11 : i % 5,
        hp: 120,
        maxHp: 200,
        age: 20 + (i % 40),
        seed: i,
        radius: Math.fround(8.1)
      },
      motion: {
        $: "Motion",
        vx: Math.fround(0.7),
        vy: Math.fround(-0.31),
        life: 120,
        pierce: 12,
        visited: list(statuses ? [1001, 2002, 3003] : []),
        slow: statuses ? 65536 : 0,
        burn: statuses ? 17 : 0,
        ownerBase: i % 2,
        logicalSlot: 65536 * (i % 2) + (i % 8)
      }
    })
  )
  return {
    ...state,
    shared: { ...state.shared, tick: 600 },
    bodies: list(snapshots.map((s) => s.body)),
    snapshots: list(snapshots)
  }
}
function hits(count: number): BendABI.CoopHitJournal.HitEvent[] {
  return Array.from({ length: count }, (_, i) => ({
    $: "HitEvent",
    id: `600:1:shot:${i}:target:${i + 1}`,
    tick: 600,
    kind: 1,
    shotId: `shot:1:580:11:${i}`,
    shotSeed: i,
    targetSeed: i + 1,
    targetGeneration: 560,
    fraction: Math.fround(0.37),
    impactX: Math.fround(7200.12),
    impactY: Math.fround(7200.37),
    targetAtImpactX: Math.fround(7200.12),
    targetAtImpactY: Math.fround(7200.37),
    radius: 8,
    outcome: 0
  }))
}
function assertFixture(name: string, value: unknown) {
  const frame = object(value),
    initial = name === "initial",
    populated = name.startsWith("population-") || name === "status-512-journal-512"
  assert.equal(frame.tick, initial ? 0 : populated ? 600 : 60)
  assert.deepEqual(
    array(frame.players, (item) => {
      const p = object(item)
      return [p.id, p.connected, p.px, p.py]
    }),
    initial
      ? [[0, true, 7200, 7200]]
      : [
          [0, true, 7350, 7200],
          [1, name !== "disconnected", 7232, 7372.5]
        ],
    `${name}: independent lifecycle and positions`
  )
  if (name === "choice") {
    assert.equal(frame.roundId, 3)
    assert.equal(frame.choicePending, true)
    assert.deepEqual(frame.requiredPlayers, [0, 1])
  }
}
try {
  const output = join(scratch, "core.mjs")
  compile(fileURLToPath(new URL("./coop-core.bend", import.meta.url)), output)
  const { default: Core } = await bendModule<BendABI.CoopCore.API>()(output, [
    "core_start",
    "core_join",
    "core_step",
    "core_disconnect",
    "core_observe"
  ])
  const legacyRoot = join(scratch, "legacy")
  await mkdir(legacyRoot)
  const archive = spawnSync("git", ["archive", base, "examples"], {
    cwd: fileURLToPath(new URL("../../", import.meta.url)),
    maxBuffer: 64 * 1024 * 1024
  })
  if (archive.status !== 0) throw Error(String(archive.stderr))
  const extract = spawnSync("tar", ["-x", "-C", legacyRoot], { input: archive.stdout })
  if (extract.status !== 0) throw Error(String(extract.stderr))
  const oldOutput = join(scratch, "legacy.mjs")
  compile(join(legacyRoot, "examples/survivors/coop-core.bend"), oldOutput)
  // The frozen master contract has a string frame; it must not use the new ABI declaration.
  const { default: Legacy } = await bendModule<{
    core_observe: (state: BendABI.CoopCore.CoreState, id: number) => { frame: string }
  }>()(oldOutput, ["core_observe"])
  function live() {
    let state = corePacket(Core.core_join(corePacket(Core.core_start(0, 0, 12345)).state, 1, 0, 0)).state
    for (let i = 0; i < 60; i++) state = corePacket(Core.core_step(state, 1, 0, 0, 1)).state
    return state
  }
  const fixtures: [string, BendABI.CoopCore.CoreState, BendABI.CoopHitJournal.HitEvent[]][] = [
    ["initial", corePacket(Core.core_start(0, 0, 12345)).state, []],
    ["live-60-ticks", live(), []],
    ["population-128", populated(live(), 128), []],
    ["population-512", populated(live(), 512), []],
    ["population-1000", populated(live(), 1000), []],
    ["status-512-journal-512", populated(live(), 512, true), hits(512)],
    [
      "choice",
      {
        ...live(),
        round: 3,
        required: list([0, 1]),
        offers: list([{ $: "PlayerOffers", id: 1, offers: list([{ $: "Offer", kind: 0, id: 11, level: 2 }]) }])
      },
      []
    ],
    ["disconnected", corePacket(Core.core_disconnect(live(), 1)).state, []]
  ]
  for (const [name, state] of fixtures) assertFixture(name, parseJson(Legacy.core_observe(state, 1).frame))
  const results = []
  for (const [name, state, events] of fixtures) {
    const lane = () => ({
      $: "Lane",
      lastSeq: 9,
      inputSeq: 8,
      appliedSeq: 8,
      appliedTick: 42,
      receivedAt: 43,
      x: 2,
      y: 1
    })
    const envelope = (frame: unknown) => ({
      type: "frame",
      connectionVersion: 1,
      token: 7,
      initial: false,
      frame: { ...object(frame), runId: "00000000-0000-4000-8000-000000000001" },
      admission: {
        $: "State",
        session: 123,
        clock: 43,
        host: lane(),
        guest: lane(),
        guestConnected: true,
        ended: false
      },
      receipt: { $: "Receipt", seq: 8, worldTick: 42, x: 2, y: 1, applied: true },
      observationSeq: 19,
      contactJournal: { $: "State", epoch: 7, now: state.shared.tick, events: list(events), overflow: 0, expired: 0 },
      inputTiming: {
        worldTick: state.shared.tick,
        lastRejected: name === "choice" ? { reason: 2, seq: 10, targetWorldTick: 42, worldTick: 43 } : null
      }
    })
    const old = () => envelope(parseJson(Legacy.core_observe(state, 1).frame))
    const fresh = () => envelope(coreFrame(corePacket(Core.core_observe(state, 1)).frame))
    const expected = old(),
      candidate = fresh()
    admitSnapshot(expected)
    admitSnapshot(candidate)
    assertFixture(name, candidate.frame)
    assert.deepEqual(normalize(candidate), normalize(expected))
    const bytes = encoder.encode(JSON.stringify(candidate)),
      compressed = await encodeSnapshot(bytes)
    assert.deepEqual(await decodeSnapshot(compressed), bytes)
    const legacyBytes = encoder.encode(JSON.stringify(expected))
    const legacyCompressed = await encodeSnapshot(legacyBytes)
    const oldTimes: number[] = [],
      newTimes: number[] = [],
      admissionTimes: number[] = []
    function measureOld() {
      const t = performance.now()
      const value = structuredClone(old())
      parseJson(decoder.decode(encoder.encode(JSON.stringify(value))))
      return performance.now() - t
    }
    function measureNew() {
      const t = performance.now()
      const value = encoder.encode(JSON.stringify(fresh()))
      const moved = structuredClone(value, { transfer: [value.buffer] })
      admitSnapshot(parseJson(decoder.decode(moved)))
      return performance.now() - t
    }
    for (let i = 0; i < 8; i++) {
      measureOld()
      measureNew()
    }
    for (let i = 0; i < samples; i++) {
      if (i % 2) {
        newTimes.push(measureNew())
        oldTimes.push(measureOld())
      } else {
        oldTimes.push(measureOld())
        newTimes.push(measureNew())
      }
    }
    for (let i = 0; i < samples; i++) {
      const t = performance.now()
      admitSnapshot(candidate)
      admissionTimes.push(performance.now() - t)
    }
    assertFixture(name, fresh().frame)
    assert.deepEqual(normalize(fresh()), normalize(old()))
    const result = {
      name,
      sourceBodies: rows(state.bodies).length,
      samples,
      legacyJsonBytes: legacyBytes.length,
      legacyGzipBytes: legacyCompressed.length,
      jsonBytes: bytes.length,
      gzipBytes: compressed.length,
      legacyPipeline: stats(oldTimes),
      productionPipeline: stats(newTimes),
      networkAdmission: stats(admissionTimes),
      p50Speedup: +(percentile(oldTimes, 0.5) / percentile(newTimes, 0.5)).toFixed(2)
    }
    results.push(result)
    console.error(JSON.stringify(result))
  }
  const report = {
    base,
    node: process.version,
    cpu: cpus()[0]?.model,
    samples,
    scope:
      "Actual production typed observation + transferable JSON including network admission; frozen master baseline. Controlled fixtures, no browser/network/FPS claim; gzip roundtrip checked outside timed region.",
    results
  }
  const json = JSON.stringify(report, null, 2) + "\n"
  if (process.env.RESULTS) await writeFile(process.env.RESULTS, json)
  else process.stdout.write(json)
} finally {
  await rm(scratch, { recursive: true, force: true })
}
