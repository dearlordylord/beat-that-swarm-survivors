import assert from "node:assert/strict"
import { mkdtemp, rm, writeFile, mkdir, symlink, readFile } from "node:fs/promises"
import { tmpdir, loadavg } from "node:os"
import { join, resolve } from "node:path"
import { spawnSync, execFileSync } from "node:child_process"
import { fileURLToPath, pathToFileURL } from "node:url"
import { createHash } from "node:crypto"
import { bendModule } from "../bend-module.mts"
import { defined, parseJson } from "./host-values.mts"
import { coreFrame } from "./observations.mts"
import { snapshotValues, admitSnapshot, encodeSnapshotValues, decodeSnapshotValues } from "./snapshot-envelope.mts"
import { encodeSnapshot, decodeSnapshot } from "./coop-snapshot-codec.mts"

const scratch = await mkdtemp(join(tmpdir(), "bendvy-snapshot-measurement-"))
const loadBefore = loadavg()
const samples = Number(process.env.SAMPLES || 15)
assert.ok(Number.isInteger(samples) && samples >= 5 && samples <= 100)
const revision = execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim()
const baselineRevision = process.env.BASELINE_REVISION || "241f799d0928c196744b9ce838c003d8ee0df62f"
const sourceDiff = execFileSync("git", ["diff", "HEAD"], { encoding: "utf8" })
const provenance = {
  revision,
  dirty:
    execFileSync("git", ["status", "--porcelain", "--untracked-files=all"], { encoding: "utf8" }).trim().length > 0,
  diffSha256: createHash("sha256").update(sourceDiff).digest("hex"),
  baselineRevision
}
const authored = execFileSync("git", ["ls-files", "--cached", "--others", "--exclude-standard"], { encoding: "utf8" })
  .trim()
  .split("\n")
  .filter((file) => !file.startsWith(".audit/"))
  .sort()
const fingerprint = createHash("sha256")
for (const file of authored) {
  fingerprint.update(file + "\0")
  try {
    fingerprint.update(await readFile(file))
  } catch {
    fingerprint.update("deleted")
  }
}
const sourceFingerprint = fingerprint.digest("hex")
const textEncoder = new TextEncoder(),
  textDecoder = new TextDecoder("utf-8", { fatal: true })
try {
  for (const name of ["snapshot-envelope.mts", "snapshot-schema.mts", "observation-schema.mts"])
    await writeFile(
      join(scratch, name),
      execFileSync("git", ["show", `${baselineRevision}:examples/survivors/${name}`])
    )
  await symlink(fileURLToPath(new URL("./host-values.mts", import.meta.url)), join(scratch, "host-values.mts"))
  const old: unknown = await import(pathToFileURL(join(scratch, "snapshot-envelope.mts")).href)
  if (typeof old !== "object" || old === null || !("admitSnapshot" in old) || typeof old.admitSnapshot !== "function")
    throw Error("baseline parser")
  const oldAdmission = old.admitSnapshot as (value: unknown) => { frame: BendABI.CoopCore.Observation }
  const output = join(scratch, "core.mjs")
  const compiled = spawnSync(
    process.env.BEND || "bend",
    [fileURLToPath(new URL("./coop-core.bend", import.meta.url)), "-o", output],
    { encoding: "utf8", timeout: 60000 }
  )
  if (compiled.status !== 0) throw Error(compiled.stdout + compiled.stderr)
  const { default: Core } = await bendModule<BendABI.CoopCore.API>()(output, [
    "core_start",
    "core_attach",
    "core_step",
    "core_choose",
    "core_observe",
    "core_network_observe",
    "network_prediction_allowed",
    "restore_network"
  ])
  let packet = Core.core_start(0, 0, 12345)
  if (packet.$ !== "CorePacket") throw Error(packet.message)
  packet = Core.core_attach(packet.state, 1, 0, 0, 16777215)
  if (packet.$ !== "CorePacket") throw Error(packet.message)
  const fixtures: { name: string; state: BendABI.CoopCore.CoreState }[] = []
  for (let tick = 0; tick <= 1350; tick++) {
    if (tick === 150 || tick === 1350) fixtures.push({ name: tick === 150 ? "sparse" : "dense", state: packet.state })
    if (tick === 1350) break
    packet = Core.core_step(
      packet.state,
      Math.cos(tick / 130),
      Math.sin(tick / 130),
      Math.cos(tick / 130),
      Math.sin(tick / 130)
    )
    if (packet.$ !== "CorePacket") throw Error(packet.message)
    if (
      packet.observation.$ === "StepObservation" &&
      (packet.observation.phase === 1 || packet.observation.phase === 2)
    ) {
      for (const player of [0, 1]) {
        const view = Core.core_observe(packet.state, player)
        if (view.$ !== "CorePacket" || view.observation.$ !== "ViewObservation") throw Error("view")
        if (view.observation.choicePending) {
          packet = Core.core_choose(packet.state, player, view.observation.round, 0)
          if (packet.$ !== "CorePacket") throw Error(packet.message)
        }
      }
    }
  }
  const lane = { $: "Lane", lastSeq: 0, inputSeq: 0, appliedSeq: 0, appliedTick: 0, receivedAt: 0, x: 1, y: 1 } as const
  const journal: BendABI.CoopHitJournal.State = {
    $: "State",
    epoch: 7,
    now: 0,
    events: { $: "Nil" },
    overflow: 0,
    expired: 0
  }
  const results = []
  for (const fixture of fixtures) {
    const observed = Core.core_observe(fixture.state, 1)
    if (observed.$ !== "CorePacket" || observed.observation.$ !== "ViewObservation") throw Error("view")
    const expected = coreFrame(observed.observation)
    if (!expected || !("combatForecast" in expected)) throw Error("view frame")
    const full = () => {
      const p = Core.core_observe(fixture.state, 1)
      if (p.$ !== "CorePacket") throw Error(p.message)
      return {
        type: "frame",
        connectionVersion: 1,
        token: 7,
        initial: false,
        runId: "measured-gameplay",
        frame: p.observation,
        admission: { $: "State", session: 1, clock: 0, host: lane, guest: lane, guestConnected: true, ended: false },
        receipt: { $: "Receipt", seq: 0, worldTick: 0, x: 1, y: 1, applied: false },
        observationSeq: 1,
        contactJournal: journal,
        inputTiming: { worldTick: 0, lastRejected: null }
      }
    }
    const compact = (): BendABI.CoopNetwork.Snapshot => {
      const p = Core.core_network_observe(fixture.state, 1)
      assert.equal(
        Core.network_prediction_allowed(p.view),
        observed.observation.$ === "ViewObservation" && observed.observation.predictionAllowed
      )
      return {
        $: "Snapshot",
        connectionVersion: 1,
        token: 7,
        initial: false,
        runId: "measured-gameplay",
        observationSeq: 1,
        view: p.view,
        commandAck: 0,
        contactJournal: journal,
        inputTiming: { $: "InputTiming", worldTick: 0, lastRejected: { $: "None" } }
      }
    }
    const kinds = ["full-json", "compact-json", "compact-cbor"] as const
    const elapsed = new Map(kinds.map((kind) => [kind, [] as number[]]))
    const stages = new Map(
      kinds.map((kind) => [
        kind,
        {
          projection: [] as number[],
          codec: [] as number[],
          compression: [] as number[],
          reconstruction: [] as number[]
        }
      ])
    )
    const sizes = new Map<string, { raw: number; transmitted: number }>()
    for (let repetition = -5; repetition < samples; repetition++) {
      for (let index = 0; index < kinds.length; index++) {
        const kind = defined(kinds[(index + repetition + 6) % kinds.length])
        const start = performance.now()
        const payload = kind === "full-json" ? full() : compact()
        const projected = performance.now()
        const raw =
          kind === "full-json"
            ? textEncoder.encode(JSON.stringify(payload))
            : kind === "compact-json"
              ? textEncoder.encode(JSON.stringify(snapshotValues(payload as BendABI.CoopNetwork.Snapshot)))
              : encodeSnapshotValues(payload as BendABI.CoopNetwork.Snapshot)
        const encoded = performance.now()
        const compressed = await encodeSnapshot(raw)
        const restoredBytes = await decodeSnapshot(compressed)
        const decompressed = performance.now()
        const view =
          kind === "full-json"
            ? oldAdmission(parseJson(textDecoder.decode(restoredBytes))).frame
            : Core.restore_network(
                (kind === "compact-json"
                  ? admitSnapshot(parseJson(textDecoder.decode(restoredBytes)))
                  : decodeSnapshotValues(restoredBytes)
                ).view
              )
        const result = coreFrame(view)
        const end = performance.now()
        assert.deepEqual(result, expected)
        sizes.set(kind, { raw: raw.byteLength, transmitted: compressed.byteLength })
        if (repetition >= 0) {
          defined(elapsed.get(kind)).push(end - start)
          const stage = defined(stages.get(kind))
          stage.projection.push(projected - start)
          stage.codec.push(encoded - projected)
          stage.compression.push(decompressed - encoded)
          stage.reconstruction.push(end - decompressed)
        }
        if (repetition === 0 && process.env.ARTIFACT_DIR) {
          await mkdir(process.env.ARTIFACT_DIR, { recursive: true })
          await writeFile(join(process.env.ARTIFACT_DIR, `${fixture.name}-${kind}.frame`), compressed)
        }
      }
    }
    const summary = (values: number[]) => {
      const sorted = [...values].sort((a, b) => a - b)
      return {
        median: defined(sorted[Math.floor(sorted.length / 2)]),
        min: defined(sorted[0]),
        max: defined(sorted[sorted.length - 1])
      }
    }
    results.push({
      fixture: fixture.name,
      tick: expected?.tick,
      actors: expected
        ? {
            enemies: expected.enemies.length,
            projectiles: expected.projectiles.length,
            pickups: expected.pickups.length
          }
        : null,
      snapshots: snapshotValues(compact()),
      measurements: kinds.map((kind) => ({
        kind,
        ...sizes.get(kind),
        fullPathMs: summary(defined(elapsed.get(kind))),
        stagesMs: Object.fromEntries(
          Object.entries(defined(stages.get(kind))).map(([key, value]) => [key, summary(value)])
        )
      }))
    })
  }
  const report = {
    provenance: { ...provenance, sourceFingerprint },
    loadAverage: { before: loadBefore, after: loadavg() },
    samples,
    results: results.map(({ snapshots: _snapshots, ...result }) => result),
    scope:
      "real gameplay; Bend projection + codec + gzip/gunzip + admission + Bend reconstruction + guest-visible projection; excludes network latency"
  }
  if (process.env.ARTIFACT_DIR)
    await writeFile(resolve(process.env.ARTIFACT_DIR, "measurement.json"), JSON.stringify(report, null, 2))
  console.log(JSON.stringify(report, null, 2))
} finally {
  await rm(scratch, { recursive: true, force: true })
}
