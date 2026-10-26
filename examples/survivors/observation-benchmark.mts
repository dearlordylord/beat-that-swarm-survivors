// Opt-in measurement of the current raw observation pipeline.
import assert from "node:assert/strict"
import { mkdtemp, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { spawnSync } from "node:child_process"
import { fileURLToPath } from "node:url"
import { bendModule } from "../bend-module.mts"
import { defined, parseJson } from "./host-values.mts"
import { coreFrame } from "./observations.mts"
import { admitSnapshot } from "./snapshot-envelope.mts"
const scratch = await mkdtemp(join(tmpdir(), "bendvy-current-observation-"))
const samples = Number(process.env.SAMPLES || 100)
assert.ok(Number.isInteger(samples) && samples >= 10)
try {
  const output = join(scratch, "core.mjs")
  const compiled = spawnSync(
    process.env.BEND || "bend",
    [fileURLToPath(new URL("./coop-core.bend", import.meta.url)), "-o", output],
    { encoding: "utf8", timeout: 60000 }
  )
  if (compiled.status !== 0) throw Error(compiled.stdout + compiled.stderr)
  const { default: Core } = await bendModule<BendABI.CoopCore.API>()(output, ["core_start", "core_observe"])
  const started = Core.core_start(0, 0, 12345)
  if (started.$ !== "CorePacket") throw Error(started.message)
  const state = started.state
  const lane = { $: "Lane", lastSeq: 0, inputSeq: 0, appliedSeq: 0, appliedTick: 0, receivedAt: 0, x: 1, y: 1 }
  function fresh() {
    const packet = Core.core_observe(state, 0)
    if (packet.$ !== "CorePacket") throw Error(packet.message)
    return {
      type: "frame",
      connectionVersion: 1,
      token: 7,
      initial: true,
      runId: "benchmark",
      frame: packet.observation,
      admission: { $: "State", session: 1, clock: 0, host: lane, guest: lane, guestConnected: false, ended: false },
      receipt: { $: "Receipt", seq: 0, worldTick: 0, x: 1, y: 1, applied: false },
      observationSeq: 1,
      contactJournal: { $: "State", epoch: 0, now: 0, events: { $: "Nil" }, overflow: 0, expired: 0 },
      inputTiming: { worldTick: 0, lastRejected: null }
    }
  }
  const expected = fresh()
  const roundtrip = () => coreFrame(admitSnapshot(parseJson(JSON.stringify(fresh()))).frame)
  assert.deepEqual(roundtrip(), coreFrame(admitSnapshot(expected).frame))
  const elapsed: number[] = []
  for (let i = 0; i < samples + 10; i++) {
    const start = performance.now()
    roundtrip()
    if (i >= 10) elapsed.push(performance.now() - start)
  }
  elapsed.sort((a, b) => a - b)
  console.log(
    JSON.stringify({
      fixture: "initial",
      samples,
      serializedBytes: Buffer.byteLength(JSON.stringify(expected)),
      p50Ms: defined(elapsed[Math.floor(samples * 0.5)]),
      p95Ms: defined(elapsed[Math.floor(samples * 0.95)]),
      scope: "core_observe + JSON roundtrip + strict raw ingress + projection; no baseline speedup claim"
    })
  )
} finally {
  await rm(scratch, { recursive: true, force: true })
}
