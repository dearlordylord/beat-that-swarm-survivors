import { motionOracle } from "./coop-motion-oracle.mts"
import type { Page } from "playwright"
import { loadChromium } from "./playwright-module.mts"
import type {
  Trace,
  Role,
  BrowserError,
  RenderRow,
  InputResolution,
  SnapshotSend,
  SnapshotAck
} from "./coop-browser-trace.mts"
import { defined, errorMessage, object, text, array } from "../../examples/survivors/host-values.mts"
import assert from "node:assert/strict"
import { mkdir, writeFile } from "node:fs/promises"
import { createHash } from "node:crypto"
import { spawnSync } from "node:child_process"
import { resolve } from "node:path"
import { fileURLToPath } from "node:url"
interface NetworkReport {
  nativeSendTraceFile: string
  sourceStable: boolean
  sourceExact: boolean
  reload: { beforeReload: number; suspended: string | null; rejoined: Trace["lastFrame"]; sameInvitation: boolean }
  [key: string]: unknown
}

// Fixed-input real-Iroh diagnostics. This is browser evidence, not a formal proof.
// COOP_URL must point at the frozen candidate; test-only route hooks do not alter source files.

const chromium = await loadChromium()
const base = process.env.COOP_URL || "http://127.0.0.1:32987/coop.html"
const output = process.env.COOP_QA_DIR || "/tmp/coop-reliability"
const duration = Math.max(30000, Number(process.env.COOP_DURATION_MS || 32000))
const observationDelay = Number(process.env.COOP_OBSERVATION_DELAY_MS || 300)
const sendDelayMode = process.env.COOP_SEND_DELAY_MODE || "before"
const recoveryOnly = process.env.COOP_RECOVERY_ONLY === "1"
const seedOverride = Number(process.env.COOP_TEST_SEED ?? 1729)
assert.ok(
  Number.isInteger(seedOverride) && seedOverride >= 0 && seedOverride <= 4294967295,
  "COOP_TEST_SEED must be a U32 integer"
)
const seedOverrides = [`host worker init seed override ${seedOverride}`]
const requestedCompletions = (process.env.COOP_SEND_COMPLETION_MS ?? "0").split(",").map(Number)
const completions = Array.from(new Set(requestedCompletions))
assert.ok(completions.every((n) => Number.isFinite(n) && n >= 0) && observationDelay >= 0, "nonnegative delays")
assert.ok(sendDelayMode === "before" || sendDelayMode === "after", "COOP_SEND_DELAY_MODE must be before or after")
await mkdir(output, { recursive: true })
const seedFiles = [
  "coop.html",
  "coop.css",
  "style.css",
  "menu-a.css",
  "menu-moon.css",
  "favicon.svg",
  "coop-browser.mjs",
  "coop-worker.mjs",
  "coop-ui.mjs",
  "coop-transport.mjs",
  "coop-presentation.mjs",
  "renderer.mjs",
  "audio.mjs",
  "content.mjs",
  "progression.mjs",
  "expedition-menu.mjs",
  "menu-controls.mjs",
  "survivor-art.mjs",
  "iroh/iroh_transport.js",
  "iroh/iroh_transport_bg.wasm",
  "dist/game.mjs",
  "dist/menu-progression.mjs",
  "dist/coop-protocol.mjs",
  "dist/coop-core.mjs",
  "dist/coop-session.mjs",
  "dist/coop-input-queue.mjs",
  "dist/coop-connection.mjs",
  "dist/coop-playback.mjs",
  "dist/coop-playback-wire.mjs",
  "dist/coop-contact-playback.mjs",
  "dist/coop-client-clock.mjs",
  "dist/coop-hit-journal.mjs",
  "dist/coop-hit-effects.mjs",
  "dist/coop-local-projectiles.mjs",
  "dist/coop-input-flow.mjs",
  "dist/coop-snapshot-flow.mjs",
  "dist/coop-snapshot-receipts.mjs",
  "dist/coop-client-delivery.mjs",
  "dist/coop-prediction.mjs",
  "version.json"
]
const artifactDirectory = resolve(
  process.env.COOP_SOURCE_ARTIFACT_DIR || fileURLToPath(new URL("../../examples/survivors/dist/web/", import.meta.url))
)
const digest = (bytes: Uint8Array) => createHash("sha256").update(bytes).digest("hex")
async function localSourceHashes() {
  // Parse syntax without evaluating any artifact. Dynamic worker/WASM entrypoints
  // remain explicit seeds; every relative static ESM dependency is discovered.
  const collector = String.raw`
 const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),crypto=require('node:crypto');
 const root=path.resolve(process.argv[1]),pending=JSON.parse(process.argv[2]),hashes={},imports={};
 for(let index=0;index<pending.length;index++){
  const file=pending[index];if(Object.hasOwn(hashes,file))continue;
  const absolute=path.resolve(root,file);
  if(!absolute.startsWith(root+path.sep))throw Error('Artifact import escapes root: '+file);
  const bytes=fs.readFileSync(absolute);hashes[file]=crypto.createHash('sha256').update(bytes).digest('hex');
  if(!/\.m?js$/.test(file))continue;
  const module=new vm.SourceTextModule(bytes.toString('utf8'),{identifier:absolute});
  imports[file]=module.dependencySpecifiers.filter(specifier=>specifier.startsWith('./')||specifier.startsWith('../')).map(specifier=>{
   const dependency=path.relative(root,path.resolve(path.dirname(absolute),specifier.split(/[?#]/)[0]));
   pending.push(dependency);return dependency;
  });
 }
 for(const[file,dependencies]of Object.entries(imports))for(const dependency of dependencies)
  if(!Object.hasOwn(hashes,dependency))throw Error('Unhashed local import '+file+' -> '+dependency);
 process.stdout.write(JSON.stringify({hashes,imports}));`
  const args = ["--experimental-vm-modules", "-e", collector, artifactDirectory, JSON.stringify(seedFiles)]
  const result = spawnSync(process.execPath, args, { encoding: "utf8", maxBuffer: 16 * 1024 * 1024, timeout: 60000 })
  assert.equal(
    result.status,
    0,
    `artifact import closure failed: ${JSON.stringify({
      command: [process.execPath, ...args],
      cwd: process.cwd(),
      status: result.status,
      signal: result.signal,
      error: result.error ? errorMessage(result.error) : null,
      stdout: result.stdout,
      stderr: result.stderr
    })}`
  )
  const value = object(JSON.parse(result.stdout))
  const closure = {
    hashes: Object.fromEntries(Object.entries(object(value.hashes)).map(([key, value]) => [key, text(value)])),
    imports: Object.fromEntries(Object.entries(object(value.imports)).map(([key, value]) => [key, array(value, text)]))
  }
  return closure
}
async function source() {
  const hashes: Record<string, string> = {}
  let version: unknown
  for (const file of files) {
    const r = await fetch(new URL(file, base), { cache: "no-store" })
    assert.equal(r.status, 200, file)
    const bytes = Buffer.from(await r.arrayBuffer())
    hashes[file] = digest(bytes)
    if (file === "version.json") version = JSON.parse(bytes.toString("utf8"))
  }
  return { hashes, version }
}
const artifactClosure = await localSourceHashes(),
  expectedHashes = artifactClosure.hashes,
  files = Object.keys(expectedHashes).sort()
assert.ok(
  files.includes("coop-snapshot-codec.mjs"),
  "the imported snapshot codec must belong to the automatic source closure"
)
function p95(values: number[]) {
  const sorted = [...values].sort((a, b) => a - b)
  return sorted[Math.max(0, Math.ceil(sorted.length * 0.95) - 1)] ?? 0
}
function authorityLag(hostRows: InputResolution[], guestRows: RenderRow[], startWall: number) {
  const hosts = hostRows
    .filter((row) => Number.isFinite(row.wall) && Number.isFinite(row.worldTick))
    .sort((a, b) => a.wall - b.wall)
  const activeGuests = guestRows.filter(
    (row) => row.phase === 0 && Number.isFinite(row.wall) && Number.isFinite(row.tick)
  )
  const measured = activeGuests.filter((row) => row.wall >= startWall + 5000)
  const lagRows = []
  let hostIndex = 0,
    current = null
  for (const guest of measured) {
    while (hostIndex < hosts.length && defined(hosts[hostIndex]).wall <= guest.wall) {
      current = hosts[hostIndex]
      hostIndex++
    }
    if (current && current.phase === 0 && current.round === guest.round)
      lagRows.push({ wall: guest.wall, lag: Math.max(0, current.worldTick - guest.tick) })
  }
  const buckets = new Map<number, number[]>()
  for (const row of lagRows) {
    const index = Math.floor((row.wall - (startWall + 5000)) / 5000),
      values = buckets.get(index) || []
    values.push(row.lag)
    buckets.set(index, values)
  }
  const windows = [...buckets.entries()]
    .sort((a, b) => a[0] - b[0])
    .map(([index, values]) => ({
      startMs: 5000 + index * 5000,
      samples: values.length,
      maxTicks: Math.max(...values),
      p95Ticks: p95(values)
    }))
  return {
    reference: "authoritative host worker advanced-step clock",
    hostClockSamples: hosts.length,
    activePhaseZeroMs: activeGuests.length > 1 ? defined(activeGuests.at(-1)).wall - defined(activeGuests[0]).wall : 0,
    measuredMs: measured.length > 1 ? defined(measured.at(-1)).wall - defined(measured[0]).wall : 0,
    samples: lagRows.length,
    maxTicks: lagRows.length ? Math.max(...lagRows.map((row) => row.lag)) : 0,
    p95Ticks: p95(lagRows.map((row) => row.lag)),
    windows
  }
}
