interface NetworkReport {
  nativeSendTraceFile: string
  sourceStable: boolean
  sourceExact: boolean
  reload: { beforeReload: number; suspended: string | null; rejoined: Trace["lastFrame"]; sameInvitation: boolean }
  [key: string]: unknown
}
import type * as Playwright from "playwright"
import type { Page } from "playwright"
import type {
  Trace,
  Role,
  BrowserError,
  RenderRow,
  InputResolution,
  SnapshotSend,
  SnapshotAck
} from "./coop-browser-trace.mts"
import { defined, errorMessage } from "../../examples/survivors/host-values.mts"
// Fixed-input real-Iroh diagnostics. This is browser evidence, not a formal proof.
// COOP_URL must point at the frozen candidate; test-only route hooks do not alter source files.
import assert from "node:assert/strict"
import { mkdir, writeFile } from "node:fs/promises"
import { createHash } from "node:crypto"
import { spawnSync } from "node:child_process"
import { resolve } from "node:path"
import { fileURLToPath } from "node:url"
const { chromium }: Pick<typeof Playwright, "chromium"> = await import(process.env.PLAYWRIGHT_MODULE || "playwright")
const base = process.env.COOP_URL || "http://127.0.0.1:32987/coop.html"
const output = process.env.COOP_QA_DIR || "/tmp/coop-reliability"
const duration = Math.max(30000, Number(process.env.COOP_DURATION_MS || 32000))
const observationDelay = Number(process.env.COOP_OBSERVATION_DELAY_MS || 300)
const sendDelayMode = process.env.COOP_SEND_DELAY_MODE || "before"
const recoveryOnly = process.env.COOP_RECOVERY_ONLY === "1"
const seedOverride = process.env.COOP_TEST_SEED === undefined ? null : Number(process.env.COOP_TEST_SEED)
assert.ok(
  seedOverride === null || (Number.isInteger(seedOverride) && seedOverride >= 0 && seedOverride <= 4294967295),
  "COOP_TEST_SEED must be a U32 integer"
)
const seedOverrides = seedOverride === null ? [] : [`host worker init seed override ${seedOverride}`]
const requestedCompletions = (process.env.COOP_SEND_COMPLETION_MS || "200,600").split(",").map(Number)
const completions = Array.from(new Set([0, 200, ...requestedCompletions]))
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
  const result = spawnSync(
    process.execPath,
    ["--experimental-vm-modules", "-e", collector, artifactDirectory, JSON.stringify(seedFiles)],
    { encoding: "utf8", maxBuffer: 16 * 1024 * 1024, timeout: 60000 }
  )
  assert.equal(result.status, 0, `artifact import closure failed: ${result.error || result.stderr}`)
  const closure: { hashes: Record<string, string>; imports: Record<string, string[]> } = JSON.parse(result.stdout)
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
// Fixed default-character trajectory oracle, not a universal enemy physics bound.
function motionOracle(rows: RenderRow[], startWall: number) {
  const warmAt = startWall + 5000,
    hostSteps: number[] = [],
    enemySteps: number[] = [],
    violations: unknown[] = []
  let activeSamples = 0,
    bufferedSamples = 0,
    bufferEntries = 0,
    bufferExits = 0,
    recoveryEntries = 0
  for (let index = 0; index < rows.length; index++) {
    const row = defined(rows[index]),
      previous = rows[index - 1]
    if (row.wall < warmAt || row.phase !== 0) continue
    activeSamples++
    if (row.remotePresentation?.buffering) bufferedSamples++
    const continuous =
      previous &&
      previous.wall >= warmAt &&
      previous.phase === 0 &&
      previous.runId === row.runId &&
      previous.round === row.round
    if (!continuous) continue
    if (row.remotePresentation?.buffering && !previous.remotePresentation?.buffering) bufferEntries++
    if (!row.remotePresentation?.buffering && previous.remotePresentation?.buffering) bufferExits++
    if (row.remotePresentation?.recovered && !previous.remotePresentation?.recovered) recoveryEntries++
    const elapsedMs = row.wall - previous.wall
    if (!(elapsedMs > 0 && elapsedMs <= 250)) continue
    const oldHost = previous.players?.find((player) => player.id === 0),
      host = row.players?.find((player) => player.id === 0)
    if (
      host &&
      oldHost &&
      host.character === oldHost.character &&
      host.character === 0 &&
      host.alive &&
      oldHost.alive
    ) {
      const distance = Math.hypot(host.px - oldHost.px, host.py - oldHost.py),
        allowed = 4 * ((elapsedMs * 60) / 1000) + 1
      assert.ok(Number.isFinite(distance), "remote host coordinates must be finite")
      hostSteps.push(distance / ((elapsedMs * 60) / 1000))
      if (distance > allowed)
        violations.push({
          wall: row.wall,
          elapsedMs,
          distance,
          allowed,
          previousTick: previous.tick,
          tick: row.tick,
          previousPresentation: previous.remotePresentation,
          presentation: row.remotePresentation
        })
    }
    const oldEnemies = new Map((previous.enemies || []).map((enemy) => [enemy[2], enemy]))
    for (const enemy of row.enemies || []) {
      const old = oldEnemies.get(enemy[2])
      if (old) {
        const distance = Math.hypot(enemy[0] - old[0], enemy[1] - old[1])
        if (Number.isFinite(distance)) enemySteps.push(distance / ((elapsedMs * 60) / 1000))
      }
    }
  }
  return {
    warmupMs: 5000,
    maxPairGapMs: 250,
    host: {
      samples: hostSteps.length,
      maxUnitsPerWallTick: hostSteps.length ? Math.max(...hostSteps) : 0,
      p95UnitsPerWallTick: p95(hostSteps),
      violationCount: violations.length,
      violations: violations.slice(0, 12)
    },
    enemies: {
      samples: enemySteps.length,
      maxUnitsPerWallTick: enemySteps.length ? Math.max(...enemySteps) : 0,
      p95UnitsPerWallTick: p95(enemySteps),
      scope: "same-generation diagnostics; monster dash mechanics have no asserted speed bound"
    },
    buffer: { activeSamples, bufferedSamples, bufferEntries, bufferExits, recoveryEntries }
  }
}
function inputCoverage(rows: InputResolution[], rejections: { reason: number }[]) {
  let eligible = 0,
    applied = 0,
    nonneutralApplied = 0,
    longestNeutralStreak = 0,
    streak = 0,
    lastTick
  for (const row of rows) {
    if (!row.eligible || row.phase !== 0) {
      streak = 0
      lastTick = undefined
      continue
    }
    eligible++
    if (row.applied) applied++
    if (row.applied && (row.x !== 1 || row.y !== 1)) {
      nonneutralApplied++
      streak = 0
    } else {
      streak = lastTick === row.worldTick - 1 ? streak + 1 : 1
      longestNeutralStreak = Math.max(longestNeutralStreak, streak)
    }
    lastTick = row.worldTick
  }
  return {
    recordedSteps: rows.length,
    eligiblePhaseZeroSteps: eligible,
    appliedSteps: applied,
    nonneutralAppliedSteps: nonneutralApplied,
    appliedRatio: eligible ? applied / eligible : 0,
    nonneutralAppliedRatio: eligible ? nonneutralApplied / eligible : 0,
    longestNeutralStreak,
    lateRejections: rejections.filter((row) => row.reason === 5).length,
    totalRejections: rejections.length,
    scope:
      "actual advanced worker steps; neutral streak includes legitimate releases, not a mandatory 60Hz movement guarantee"
  }
}
function snapshotDelivery(sends: SnapshotSend[], acks: SnapshotAck[], startWall: number) {
  const pending = new Map<string, SnapshotSend>(),
    latencies: number[] = [],
    cadence: number[] = []
  let exactAcknowledgments = 0,
    cumulativelyAcknowledged = 0
  for (const event of [
    ...sends.map((row) => ({ ...row, kind: "send" as const })),
    ...acks.map((row) => ({ ...row, kind: "ack" as const }))
  ].sort((a, b) => a.at - b.at)) {
    const key = `${event.token}:${event.observation}`
    if (event.kind === "send") {
      pending.set(key, event)
      continue
    }
    const sent = pending.get(key)
    if (sent && event.wall >= sent.wall) {
      exactAcknowledgments++
      if (sent.phase === 0 && sent.wall >= startWall + 5000) latencies.push(event.wall - sent.wall)
    }
    for (const [key, row] of pending)
      if (row.token === event.token && row.observation <= event.observation) {
        pending.delete(key)
        cumulativelyAcknowledged++
      }
  }
  for (let i = 1; i < sends.length; i++) {
    const a = defined(sends[i - 1]),
      b = defined(sends[i])
    if (a.phase === 0 && b.phase === 0 && a.round === b.round && a.token === b.token && a.wall >= startWall + 5000)
      cadence.push(b.wall - a.wall)
  }
  const stats = (values: number[]) => ({
    samples: values.length,
    p50Ms: values.length ? [...values].sort((a, b) => a - b)[Math.floor(values.length / 2)] : 0,
    p95Ms: p95(values),
    maxMs: values.length ? Math.max(...values) : 0
  })
  return {
    sent: sends.length,
    receivedReceipts: acks.length,
    exactAcknowledgments,
    cumulativelyAcknowledged,
    remainingUnacknowledged: pending.size,
    activePreparedToAppAck: stats(latencies),
    activeSendCadence: stats(cadence),
    maxObservedWindowDepth: sends.length ? Math.max(...sends.map((row) => row.depth)) : 0,
    scope: "host snapshot preparation to cumulative application receipt; distinct from native stream completion"
  }
}
function emittedMarker(source: string, pattern: RegExp, label: string): string {
  const marker = source.match(pattern)?.[0]
  assert.ok(marker, `Missing emitted TypeScript hook: ${label}`)
  return marker
}
async function instrument(page: Page, role: Role, errors: BrowserError[]) {
  page.on("pageerror", (error) => errors.push({ role, message: error.message }))
  page.on("console", (message) => {
    if (message.type() === "error" && !message.location().url?.endsWith("/favicon.ico"))
      errors.push({ role, console: true, message: message.text(), location: message.location() })
  })
  await page.addInitScript((seedOverride) => {
    globalThis.__qaDefined = <T,>(value: T | null | undefined): T => {
      if (value === null || value === undefined) throw new Error("Missing QA observation")
      return value
    }
    globalThis.__reliable = {
      workerInitializations: [],
      workerErrors: [],
      workerFailures: [],
      inputResolutions: [],
      inputRejections: [],
      snapshotSends: [],
      snapshotAcks: [],
      predictionBlocks: { total: 0, horizon: 0, disconnected: 0 },
      presentationSamples: 0,
      failNextDraw: false,
      injectedDrawFailures: 0,
      renders: [],
      statuses: [],
      inputs: [],
      pointerEvents: [],
      arrivals: [],
      nativeSends: [],
      lastFrame: null
    }
    const trace = globalThis.__reliable
    for (const type of ["keydown", "keyup"] as const)
      addEventListener(type, (e) => {
        if (e.code.startsWith("Arrow")) trace.inputs.push({ at: performance.now(), type, code: e.code })
      })
    for (const type of ["pointerdown", "pointermove", "pointerup", "pointercancel"] as const)
      addEventListener(
        type,
        (e) => {
          if (e.pointerType === "touch")
            trace.pointerEvents.push({
              at: performance.now(),
              type,
              pointerId: e.pointerId,
              target: e.target instanceof Element ? e.target.id : ""
            })
        },
        true
      )
    globalThis.__reliableDraw = (frame) => {
      trace.renders.push({
        at: performance.now(),
        wall: Date.now(),
        tick: frame.tick,
        phase: frame.phase,
        round: frame.roundId ?? 0,
        runId: frame.runId ?? "",
        timing: frame.predictionTiming,
        presentationMeasurement: frame.presentationMeasurement,
        remotePresentation: frame.remotePresentation,
        players: frame.players,
        enemies: frame.bodies
          .filter((b) => b[2] === 0)
          .slice(0, 16)
          .map((b) => [b[0], b[1], b[9] ?? b[7]])
      })
      if (trace.renders.length > 5000) trace.renders.shift()
    }
    const NativeWorker = Worker
    globalThis.Worker = class extends NativeWorker {
      constructor(...args: ConstructorParameters<typeof Worker>) {
        super(...args)
        this.addEventListener("message", (e) => {
          if (e.data.type === "error") trace.workerErrors.push(e.data)
          if (e.data.type === "qa-input-resolution") {
            trace.inputResolutions.push(e.data)
            if (trace.inputResolutions.length > 5000) trace.inputResolutions.shift()
          }
          if (e.data.type === "input-rejected") {
            trace.inputRejections.push(e.data)
            if (trace.inputRejections.length > 5000) trace.inputRejections.shift()
          }
        })
        this.addEventListener("error", (e) =>
          trace.workerFailures.push({ message: e.message, at: performance.now(), wall: Date.now() })
        )
      }
      override postMessage(message: unknown, transferOrOptions: Transferable[] | StructuredSerializeOptions = []) {
        if (
          typeof message === "object" &&
          message !== null &&
          "type" in message &&
          message.type === "init" &&
          "seed" in message &&
          typeof message.seed === "number" &&
          "session" in message &&
          typeof message.session === "number"
        ) {
          const initial = { seed: message.seed, session: message.session },
            requestedSeed = initial.seed
          if (seedOverride !== null) message = { ...message, seed: seedOverride }
          trace.workerInitializations.push({
            wall: Date.now(),
            at: performance.now(),
            requestedSeed,
            seed: seedOverride ?? initial.seed,
            overridden: seedOverride !== null,
            session: initial.session
          })
        }
        if (Array.isArray(transferOrOptions)) return super.postMessage(message, transferOrOptions)
        return super.postMessage(message, transferOrOptions)
      }
    }
  }, seedOverride)
  if (role === "host")
    await page.route("**/coop-worker.mjs", async (route) => {
      const response = await route.fetch(),
        source = await response.text(),
        marker = emittedMarker(
          source,
          /guestReceipt = InputQueue\.receipt\(frame\.tick,\s*pending\.tick\);/,
          "worker applied input"
        )
      assert.ok(source.includes(marker), "worker applied-input resolution hook")
      const trace =
        "postMessage({type:'qa-input-resolution',wall:Date.now(),round:currentRound,seq:guestReceipt.seq,worldTick:guestReceipt.worldTick,applied:guestReceipt.applied,x:guestReceipt.x,y:guestReceipt.y,eligible:guestEligible,phase:frame.phase});"
      await route.fulfill({ response, body: source.replace(marker, marker + trace) })
    })
  await page.route("**/coop-ui.mjs", async (route) => {
    const r = await route.fetch()
    let s = await r.text()
    const marker = "this.frame = frame;",
      sampleMarker = emittedMarker(s, /const display = this\.displayFrame\(now\)\s*\|\|\s*this\.frame;/, "UI sample")
    assert.ok(s.includes(marker) && s.includes(sampleMarker), "UI frame and presentation timing hooks")
    s = s.replace(
      marker,
      marker +
        'globalThis.__reliable.lastFrame={wall:Date.now(),tick:frame.tick,phase:frame.phase,round:frame.roundId ?? 0,runId:frame.runId ?? "",choicePending:frame.choicePending};'
    )
    s = s.replace(
      sampleMarker,
      "const __qaCallbackEntry=performance.now();const __qaDisplay=this.displayFrame(now)||this.frame;const __qaOnDisplayEnd=performance.now();const display={...__qaDisplay,presentationMeasurement:{sampledAt:__qaDisplay.remotePresentation?.sampledAt??now,callbackEntry:__qaCallbackEntry,onDisplayEnd:__qaOnDisplayEnd}};"
    )
    await route.fulfill({ response: r, body: s })
  })
  await page.route("**/coop-presentation.mjs", async (route) => {
    const response = await route.fetch(),
      source = await response.text(),
      marker = "sample(now = performance.now()) {"
    assert.ok(source.includes(marker), "presentation sample counter hook")
    await route.fulfill({
      response,
      body: source.replace(marker, marker + "globalThis.__reliable.presentationSamples++;")
    })
  })
  await page.route("**/renderer.mjs", async (route) => {
    const r = await route.fetch(),
      s = await r.text(),
      marker = "draw(frame, dt = 1 / 60, options = {}) {"
    assert.ok(s.includes(marker), "renderer draw hook")
    await route.fulfill({
      response: r,
      body: s.replace(
        marker,
        marker +
          "if(globalThis.__reliable.failNextDraw&&frame.phase===0){globalThis.__reliable.failNextDraw=false;globalThis.__reliable.injectedDrawFailures++;throw Error('QA_INJECTED_RENDER_FAILURE');}globalThis.__reliableDraw?.(frame);"
      )
    })
  })
  if (role === "host")
    await page.route("**/coop-browser.mjs", async (route) => {
      const response = await route.fetch()
      let source = await response.text()
      const send = emittedMarker(
          source,
          /const message = latestSnapshot;\s*latestSnapshot = null;/,
          "snapshot selection"
        ),
        ack = emittedMarker(
          source,
          /snapshotFlow = SnapshotFlow\.ack\(snapshotFlow,\s*payload\.receipt\.value\.token,\s*payload\.receipt\.value\.observation\);/,
          "snapshot receipt"
        )
      assert.ok(source.includes(send) && source.includes(ack), "host snapshot preparation and application ACK hooks")
      source = source.replace(
        send,
        send +
          "{let depth=0;for(let row=snapshotFlow.flights;row.$==='Con';row=row.tail)depth++;const rows=globalThis.__reliable.snapshotSends;rows.push({at:performance.now(),wall:Date.now(),token:message?.token,observation:message?.observationSeq,tick:message?.frame?.tick,phase:message?.frame?.phase,round:message?.frame?.roundId,depth});if(rows.length>5000)rows.shift();}"
      )
      source = source.replace(
        ack,
        ack +
          "{const rows=globalThis.__reliable.snapshotAcks;rows.push({at:performance.now(),wall:Date.now(),token:payload.receipt.value.token,observation:payload.receipt.value.observation});if(rows.length>5000)rows.shift();}"
      )
      await route.fulfill({ response, body: source })
    })
  if (role === "guest")
    await page.route("**/coop-browser.mjs", async (route) => {
      const r = await route.fetch()
      let s = await r.text()
      const marker = "const envelope = JSON.parse(text);",
        inputMarker = emittedMarker(s, /onInput:\s*\(?value\)?\s*=>\s*\{/, "input callback")
      assert.ok(s.includes(marker) && s.includes(inputMarker), "authority/input hooks")
      s = s
        .replace(
          marker,
          marker +
            "if(envelope.frame)globalThis.__reliable.arrivals.push({at:performance.now(),wall:Date.now(),tick:envelope.frame.tick,observation:envelope.observationSeq,admissionGuestLastSeq:envelope.admission?.guest?.lastSeq,receipt:envelope.receipt,inputTiming:envelope.inputTiming});"
        )
        .replace(
          inputMarker,
          inputMarker + "globalThis.__reliable.inputs.push({at:performance.now(),wall:Date.now(),x:value.x,y:value.y});"
        )
      const blocked = emittedMarker(
        s,
        /if \(!Prediction\.can_tick\(prediction\) \|\| !connected\)\s*break;/,
        "prediction horizon"
      )
      assert.ok(s.includes(blocked), "prediction horizon stall hook")
      s = s.replace(
        blocked,
        "if (!Prediction.can_tick(prediction) || !connected) {const counts=globalThis.__reliable.predictionBlocks;counts.total++;if(connected)counts.horizon++;else counts.disconnected++;break;}"
      )
      await route.fulfill({ response: r, body: s })
    })
}
async function installTransportHooks(page: Page, role: Role, completionDelay = 0) {
  await page.route("**/coop-transport.mjs", async (route) => {
    const r = await route.fetch()
    let s = await r.text()
    const send = emittedMarker(s, /await this\.#transport\.send\(bytes,\s*confirmDelivery\);/, "native send")
    assert.ok(s.includes(send), "native send trace hook")
    let traced = `const __qaNativeStart=Date.now();try{${send}}finally{globalThis.__reliable.nativeSends.push({start:__qaNativeStart,end:Date.now(),byteLength:bytes.byteLength,confirmDelivery:!!confirmDelivery});}`
    if (role === "guest" && completionDelay > 0)
      traced =
        sendDelayMode === "before"
          ? `await new Promise(resolve=>setTimeout(resolve,${completionDelay}));${traced}`
          : `${traced}await new Promise(resolve=>setTimeout(resolve,${completionDelay}));`
    s = s.replace(send, traced)
    if (role === "guest") {
      const emit = emittedMarker(s, /#emit\(event\)\s*\{\s*this\.#callback\(\{[\s\S]*?\}\);\s*\}/, "transport callback")
      assert.ok(s.includes(emit), "transport observation delay hook")
      s = s.replace(
        emit,
        `#emit(event) {const value={...event,connectionEpoch:this.#epoch,state:this.snapshot()};if(event.type==='message')setTimeout(()=>this.#callback(value),${observationDelay});else this.#callback(value);}`
      )
    }
    await route.fulfill({ response: r, body: s })
  })
}
const browser = await chromium.launch({ headless: true, args: ["--no-sandbox"] })
const summaries: unknown[] = []
async function failureRecoveryAndTouch() {
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    isMobile: true,
    hasTouch: true,
    deviceScaleFactor: 2
  })
  const host = await context.newPage(),
    guest = await context.newPage(),
    errors: BrowserError[] = []
  let failWorkerOnce = true
  const before = await source()
  assert.deepEqual(before.hashes, expectedHashes, "recovery scenario must use the exact candidate artifact")
  try {
    await instrument(host, "host", errors)
    await instrument(guest, "guest", errors)
    await host.route("**/coop-worker.mjs", async (route) => {
      if (!failWorkerOnce) return route.fallback()
      failWorkerOnce = false
      const response = await route.fetch()
      await route.fulfill({
        response,
        body: `${await response.text()}\nthrow new Error('QA_INJECTED_WORKER_FAILURE');`
      })
    })
    await host.goto(base)
    await host.locator("#coop-host").click()
    await host.waitForFunction(
      () =>
        document.querySelector<HTMLElement>("#coop-status")?.dataset.error === "true" &&
        document.querySelector("#coop-status + .coop-diagnostic:not([hidden])"),
      null,
      { timeout: 90000 }
    )
    const failureText = defined(await host.locator("#coop-status + .coop-diagnostic pre").textContent())
    const workerFailures = await host.evaluate(() => __reliable.workerFailures)
    assert.ok(failureText.includes("QA_INJECTED_WORKER_FAILURE"), "worker failure details must be visible to the host")
    assert.ok(workerFailures.length > 0, "the browser must observe the actual worker error event")
    await host.waitForFunction(
      () =>
        document.querySelector<HTMLButtonElement>("#coop-host") &&
        !__qaDefined(document.querySelector<HTMLButtonElement>("#coop-host")).disabled,
      null,
      { timeout: 15000 }
    )
    await host.locator("#coop-host").click()
    await host.waitForFunction(
      () => document.querySelector<HTMLInputElement>("#coop-invite-link")?.value.includes("join="),
      null,
      { timeout: 90000 }
    )
    const invitation = await host.locator("#coop-invite-link").inputValue()
    await guest.goto(invitation)
    await guest.locator("#coop-join").click()
    await guest.waitForFunction(
      () =>
        (globalThis.__reliable.lastFrame?.tick ?? 0) > 0 ||
        document.querySelector<HTMLElement>("#coop-status")?.dataset.error === "true",
      null,
      { timeout: 90000 }
    )
    assert.ok(
      await guest.evaluate(() => (globalThis.__reliable.lastFrame?.tick ?? 0) > 0),
      "a fresh room must be usable after the worker failure"
    )
    const pad = guest.locator("#coop-touch"),
      box = await pad.boundingBox()
    assert.ok(box && (await pad.isVisible()), "mobile co-op exposes its touch control")
    const cdp = await context.newCDPSession(guest),
      cx = box.x + box.width / 2,
      cy = box.y + box.height / 2
    const first = { id: 1, x: cx + box.width * 0.32, y: cy }
    await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [first] })
    await guest.waitForFunction(
      () => __reliable.inputs.some((value) => Number.isInteger(value.x) && (value.x !== 0 || value.y !== 0)),
      null,
      { timeout: 5000 }
    )
    const ownerInput = await guest.evaluate(() =>
      __reliable.inputs.filter((value) => Number.isInteger(value.x) && (value.x !== 0 || value.y !== 0)).at(-1)
    )
    const ownerPointer = await guest.evaluate(
      () =>
        __qaDefined(__qaDefined(__reliable.pointerEvents.filter((event) => event.type === "pointerdown")).at(-1))
          .pointerId
    )
    const second = { id: 2, x: cx - box.width * 0.32, y: cy }
    await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [first, second] })
    await cdp.send("Input.dispatchTouchEvent", {
      type: "touchMove",
      touchPoints: [first, { ...second, x: cx - box.width * 0.42 }]
    })
    await guest.waitForTimeout(100)
    const afterSecond = await guest.evaluate(() =>
      __reliable.inputs.filter((value) => Number.isInteger(value.x)).at(-1)
    )
    assert.deepEqual(
      [defined(afterSecond).x, defined(afterSecond).y],
      [defined(ownerInput).x, defined(ownerInput).y],
      "a second finger cannot steal the active movement gesture"
    )
    // Chromium GenerateTouchEvents releases the supplied IDs on touchEnd; these
    // are ended points, not the fingers that remain down. Empty ends all points.
    // https://github.com/chromium/chromium/blob/main/content/browser/devtools/protocol/input_handler.cc
    const secondPointer = await guest.evaluate(
      () =>
        __qaDefined(__qaDefined(__reliable.pointerEvents.filter((event) => event.type === "pointerdown")).at(-1))
          .pointerId
    )
    assert.notEqual(secondPointer, ownerPointer, "the second finger must have a distinct actual pointer ID")
    await cdp.send("Input.dispatchTouchEvent", {
      type: "touchEnd",
      touchPoints: [{ ...second, x: cx - box.width * 0.42 }]
    })
    await guest.waitForTimeout(100)
    assert.equal(
      await guest.evaluate(
        () => __reliable.pointerEvents.filter((event) => event.type === "pointerup").at(-1)?.pointerId
      ),
      secondPointer,
      "the browser must release the non-owner finger first"
    )
    const afterSecondEnd = await guest.evaluate(() =>
      __reliable.inputs.filter((value) => Number.isInteger(value.x)).at(-1)
    )
    assert.deepEqual(
      [defined(afterSecondEnd).x, defined(afterSecondEnd).y],
      [defined(ownerInput).x, defined(ownerInput).y],
      "ending a non-owner pointer cannot clear movement"
    )
    await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [first] })
    await guest.waitForFunction(
      () => {
        const inputs = __reliable.inputs.filter((value) => Number.isInteger(value.x))
        return inputs.at(-1)?.x === 0 && inputs.at(-1)?.y === 0
      },
      null,
      { timeout: 5000 }
    )
    assert.equal(
      await guest.evaluate(
        () => __reliable.pointerEvents.filter((event) => event.type === "pointerup").at(-1)?.pointerId
      ),
      ownerPointer,
      "the browser must then release the owner finger"
    )
    // One synchronous browser task: no animation frame can interleave these clicks.
    const mapSampling = await guest.evaluate(() => {
      const before = __reliable.presentationSamples
      __qaDefined(document.querySelector<HTMLButtonElement>("#coop-map-toggle")).click()
      const opened = !__qaDefined(document.querySelector<HTMLElement>("#coop-map-panel")).hidden,
        afterOpen = __reliable.presentationSamples
      __qaDefined(document.querySelector<HTMLButtonElement>("#coop-map-close")).click()
      return {
        before,
        afterOpen,
        afterClose: __reliable.presentationSamples,
        opened,
        closed: __qaDefined(document.querySelector<HTMLElement>("#coop-map-panel")).hidden
      }
    })
    assert.ok(
      mapSampling.before > 0 && mapSampling.opened && mapSampling.closed,
      "map sampling check must exercise a rendered live game and both controls"
    )
    assert.equal(
      mapSampling.afterOpen,
      mapSampling.before,
      "opening the map must not advance presentation or consume due effects"
    )
    assert.equal(
      mapSampling.afterClose,
      mapSampling.before,
      "closing the map must not advance presentation or consume due effects"
    )
    const guestTrace = await guest.evaluate(() => __reliable)
    const beforeActiveReload = { host: await host.evaluate(() => __reliable.lastFrame), guest: guestTrace.lastFrame }
    assert.equal(defined(beforeActiveReload.host).phase, 0, "active rejoin must start in live gameplay on the host")
    assert.equal(defined(beforeActiveReload.guest).phase, 0, "active rejoin must start in live gameplay on the guest")
    assert.equal(
      defined(beforeActiveReload.guest).runId,
      defined(beforeActiveReload.host).runId,
      "both roles share the live run before reload"
    )
    await guest.reload()
    await host.waitForFunction(
      () =>
        document
          .querySelector<HTMLElement>("#coop-status")
          ?.textContent.includes("Waiting for your teammate to rejoin"),
      null,
      { timeout: 15000 }
    )
    const suspendedFrame = await host.evaluate(() => __reliable.lastFrame)
    assert.equal(defined(suspendedFrame).phase, 0, "disconnect pauses a live world, not a terminal replay")
    assert.equal(
      defined(suspendedFrame).runId,
      defined(beforeActiveReload.host).runId,
      "disconnect preserves the active run"
    )
    const resolutionStart = await host.evaluate(() => __reliable.inputResolutions.length)
    await guest.locator("#coop-join").click()
    await guest.waitForFunction(() => (globalThis.__reliable.lastFrame?.tick ?? 0) > 0, null, { timeout: 90000 })
    const joinedFrame = await guest.evaluate(() => __reliable.lastFrame)
    assert.equal(defined(joinedFrame).phase, 0, "guest resumes active gameplay after reload")
    assert.equal(
      defined(joinedFrame).runId,
      defined(suspendedFrame).runId,
      "active rejoin retains the original run identity"
    )
    assert.equal(defined(joinedFrame).round, defined(suspendedFrame).round, "active rejoin retains the suspended round")
    assert.ok(
      defined(joinedFrame).tick >= defined(suspendedFrame).tick &&
        defined(joinedFrame).tick >= defined(beforeActiveReload.guest).tick,
      "active rejoin never starts a fresh or older world"
    )
    await guest.keyboard.down("ArrowRight")
    await host.waitForFunction(
      ({ index, tick }) =>
        __reliable.inputResolutions
          .slice(index)
          .some(
            (row) =>
              row.worldTick > tick &&
              row.eligible &&
              row.phase === 0 &&
              row.applied &&
              row.seq > 0 &&
              (row.x !== 1 || row.y !== 1)
          ),
      { index: resolutionStart, tick: defined(suspendedFrame).tick },
      { timeout: 15000 }
    )
    await host.waitForFunction(
      (tick) => __reliable.lastFrame?.phase === 0 && __reliable.lastFrame.tick >= tick + 15,
      defined(suspendedFrame).tick,
      { timeout: 15000 }
    )
    await guest.keyboard.up("ArrowRight")
    const resumedHost = await host.evaluate(() => __reliable.lastFrame)
    const newAppliedInput = await host.evaluate(
      ({ index, tick }) =>
        __reliable.inputResolutions
          .slice(index)
          .find(
            (row) =>
              row.worldTick > tick &&
              row.eligible &&
              row.phase === 0 &&
              row.applied &&
              row.seq > 0 &&
              (row.x !== 1 || row.y !== 1)
          ),
      { index: resolutionStart, tick: defined(suspendedFrame).tick }
    )
    const sameInvitation = invitation === (await host.locator("#coop-invite-link").inputValue())
    assert.equal(sameInvitation, true, "active guest reload uses the same invitation")
    const activeRejoin = {
      passed: true,
      before: beforeActiveReload,
      suspended: suspendedFrame,
      joined: joinedFrame,
      resumedHost,
      newAppliedInput,
      sameInvitation
    }
    const failedRenderRun = defined(resumedHost).runId
    await host.evaluate(() => {
      __reliable.failNextDraw = true
    })
    await host.waitForFunction(
      () => {
        const panel = document.querySelector<HTMLElement>("#coop-play-status + .coop-diagnostic")
        return panel && !panel.hidden && panel.textContent.includes("QA_INJECTED_RENDER_FAILURE")
      },
      null,
      { timeout: 15000 }
    )
    const drawFailureText = await host.locator("#coop-play-status + .coop-diagnostic pre").textContent()
    const drawsAfterFailure = await host.evaluate(() => __reliable.renders.length)
    await host.waitForTimeout(300)
    assert.equal(
      await host.evaluate(() => __reliable.renders.length),
      drawsAfterFailure,
      "fatal presentation failure suspends drawing until an explicit session reset"
    )
    assert.equal(
      await host.evaluate(() => __reliable.injectedDrawFailures),
      1,
      "one renderer failure must not cause a repeated error storm"
    )
    assert.equal(
      errors.filter((error) => !error.console && error.message.includes("QA_INJECTED_RENDER_FAILURE")).length,
      1,
      "the browser must surface exactly one renderer exception"
    )
    await host.locator("#coop-leave").click()
    await host.locator("#coop-host").click()
    await host.waitForFunction(
      () => document.querySelector<HTMLInputElement>("#coop-invite-link")?.value.includes("join="),
      null,
      { timeout: 90000 }
    )
    const recoveredInvitation = await host.locator("#coop-invite-link").inputValue()
    await guest.goto(recoveredInvitation)
    await guest.locator("#coop-join").click()
    await host.waitForFunction(
      (oldRun) => {
        const frames = __reliable.renders.filter((row) => row.phase === 0 && row.runId && row.runId !== oldRun)
        return frames.length >= 3 && __qaDefined(frames.at(-1)).tick > __qaDefined(frames[0]).tick
      },
      failedRenderRun,
      { timeout: 15000 }
    )
    const recoveredRenders = await host.evaluate(
      (oldRun) => __reliable.renders.filter((row) => row.phase === 0 && row.runId && row.runId !== oldRun),
      failedRenderRun
    )
    const renderRecovery = {
      passed: true,
      failedRunId: failedRenderRun,
      diagnostic: drawFailureText,
      injectedFailures: await host.evaluate(() => __reliable.injectedDrawFailures),
      drawsWhileFailed: 0,
      newRunId: defined(recoveredRenders.at(-1)).runId,
      newRunDraws: recoveredRenders.length,
      firstTick: defined(recoveredRenders[0]).tick,
      lastTick: defined(recoveredRenders.at(-1)).tick,
      hostPageReloaded: false
    }
    assert.notEqual(
      renderRecovery.newRunId,
      failedRenderRun,
      "renderer recovery must draw a new room without reloading the host page"
    )
    assert.deepEqual(
      errors.filter(
        (error) =>
          !error.message.includes("QA_INJECTED_WORKER_FAILURE") && !error.message.includes("QA_INJECTED_RENDER_FAILURE")
      ),
      [],
      "recovery permits only the explicitly injected worker and renderer failures"
    )
    const after = await source()
    assert.deepEqual(
      after.hashes,
      expectedHashes,
      "served sources remain exact through recovery, touch, and active rejoin checks"
    )
    assert.ok(
      guestTrace.pointerEvents.some((event) => event.type === "pointerdown") &&
        guestTrace.pointerEvents.some((event) => event.type === "pointerup"),
      "touch ownership must be exercised by pointer events"
    )
    const result = {
      kind: "worker and renderer failure recovery, mobile touch ownership, map sampling, and active guest rejoin",
      sourceExact: true,
      expectedSourceHashes: expectedHashes,
      sourceImportClosure: artifactClosure.imports,
      runtimeOverrides: [
        ...seedOverrides,
        "one-shot worker module exception",
        "one-shot live renderer exception",
        "UI/renderer/input telemetry",
        "worker advanced-step receipt telemetry (extra diagnostic messages)"
      ],
      workerFailureVisible: true,
      newRoomStarted: true,
      touchInput: ownerInput,
      ownerPointer,
      secondPointer,
      touchReleased: true,
      mapSampling,
      activeRejoin,
      renderRecovery,
      workerInitializations: await host.evaluate(() => __reliable.workerInitializations),
      pointerEvents: guestTrace.pointerEvents,
      errors
    }
    await writeFile(`${output}/worker-recovery-touch.json`, JSON.stringify(result))
    summaries.push(result)
    console.log(JSON.stringify(result))
  } catch (error) {
    await writeFile(
      `${output}/worker-recovery-touch-failure.json`,
      JSON.stringify({
        message: errorMessage(error),
        stack: error instanceof Error ? error.stack : undefined,
        errors,
        host: await host.evaluate(() => globalThis.__reliable).catch(() => null),
        guest: await guest.evaluate(() => globalThis.__reliable).catch(() => null)
      })
    )
    throw error
  } finally {
    await context.close()
  }
}
try {
  for (const completionDelay of recoveryOnly ? [] : completions) {
    const context = await browser.newContext({ viewport: { width: 1000, height: 700 } }),
      host = await context.newPage(),
      guest = await context.newPage(),
      errors: BrowserError[] = []
    const before = await source()
    assert.deepEqual(before.hashes, expectedHashes, "served code must match the exact local candidate artifact")
    const choices: unknown[] = [],
      timeline: { role: Role; elapsed: number; status: string }[] = []
    try {
      await instrument(host, "host", errors)
      await instrument(guest, "guest", errors)
      await installTransportHooks(host, "host")
      await installTransportHooks(guest, "guest", completionDelay)
      await host.goto(base)
      await host.locator("#coop-host").click()
      await host.waitForFunction(
        () => document.querySelector<HTMLInputElement>("#coop-invite-link")?.value.includes("join="),
        null,
        { timeout: 90000 }
      )
      const invite = await host.locator("#coop-invite-link").inputValue()
      await guest.goto(invite)
      await guest.locator("#coop-join").click()
      await guest.waitForFunction(
        () =>
          (globalThis.__reliable.lastFrame?.tick ?? 0) > 0 ||
          document.querySelector<HTMLElement>("#coop-status")?.dataset.error === "true",
        null,
        { timeout: 90000 }
      )
      assert.ok(
        await guest.evaluate(() => (globalThis.__reliable.lastFrame?.tick ?? 0) > 0),
        defined(await guest.locator("#coop-status").textContent())
      )
      const start = Date.now()
      let previousDirection
      while (Date.now() - start < duration) {
        const elapsed = Date.now() - start,
          direction = Math.floor(elapsed / 3000) % 2 ? "ArrowLeft" : "ArrowRight"
        for (const [role, page] of [
          ["host", host],
          ["guest", guest]
        ] as const) {
          const choice = defined(page).locator('[data-choice="0"]')
          if (await choice.isVisible()) {
            const prior = await defined(page).evaluate(() => __reliable.lastFrame)
            await choice.click()
            await defined(page).waitForFunction(
              (round) =>
                globalThis.__reliable.lastFrame?.round !== round ||
                globalThis.__reliable.lastFrame?.choicePending === false,
              defined(prior).round,
              { timeout: 15000 }
            )
            choices.push({ role, elapsed, round: defined(prior).round, tick: defined(prior).tick, acknowledged: true })
          }
          if (direction !== previousDirection) {
            await defined(page).keyboard.up("ArrowLeft")
            await defined(page).keyboard.up("ArrowRight")
          }
          await defined(page).keyboard.down(
            role === "host" ? direction : direction === "ArrowRight" ? "ArrowLeft" : "ArrowRight"
          )
          const status = await defined(page).locator("#coop-status").textContent()
          if (status) timeline.push({ role, elapsed, status })
        }
        previousDirection = direction
        await guest.waitForTimeout(250)
      }
      for (const page of [host, guest]) {
        await page.keyboard.up("ArrowLeft")
        await page.keyboard.up("ArrowRight")
      }
      const hostTrace = await host.evaluate(() => __reliable),
        guestTrace = await guest.evaluate(() => __reliable)
      const appliedReceipts = guestTrace.arrivals.filter(
        (row) => row.receipt?.applied === true && Number.isInteger(row.receipt.seq) && row.receipt.seq > 0
      )
      assert.ok(
        guestTrace.inputs.some((row) => Number.isInteger(row.x) && (row.x !== 0 || row.y !== 0)),
        "guest inputs must reach the browser adapter"
      )
      if (completionDelay <= 200)
        assert.ok(
          appliedReceipts.length > 0,
          "host snapshots must return an applied-input receipt, not only show that an input was present"
        )
      assert.ok(
        appliedReceipts.every(
          (row) =>
            Number.isInteger(row.receipt.worldTick) &&
            Number.isInteger(row.inputTiming?.worldTick) &&
            row.receipt.worldTick <= row.inputTiming.worldTick &&
            row.receipt.worldTick <= row.tick &&
            row.admissionGuestLastSeq >= row.receipt.seq
        ),
        "applied receipts must be covered by the host ACK and no later than its authority tick"
      )
      const beforeReload = defined(hostTrace.lastFrame).tick
      await guest.reload()
      await host.waitForTimeout(600)
      const suspended = await host.locator("#coop-status").textContent()
      await guest.locator("#coop-join").click()
      await guest.waitForFunction(() => (globalThis.__reliable.lastFrame?.tick ?? 0) > 0, null, { timeout: 90000 })
      await guest.waitForTimeout(1500)
      const rejoined = await guest.evaluate(() => __reliable.lastFrame),
        after = await source()
      assert.deepEqual(
        after.hashes,
        expectedHashes,
        "served code must remain byte-for-byte equal to the local candidate artifact"
      )
      const delivery = snapshotDelivery(hostTrace.snapshotSends, hostTrace.snapshotAcks, start),
        workerInputCoverage = inputCoverage(hostTrace.inputResolutions, hostTrace.inputRejections),
        motion = motionOracle(guestTrace.renders, start),
        lag = authorityLag(hostTrace.inputResolutions, guestTrace.renders, start),
        sourceStable = JSON.stringify(before.hashes) === JSON.stringify(after.hashes)
      const result: NetworkReport = {
        nativeSendTraceFile: `${output}/native-sends-${completionDelay}.json`,
        completionDelay,
        sendDelayMode,
        observationDelay,
        measurement: { loopStartWall: start, warmupMs: 5000, measuredFromWall: start + 5000 },
        workerInitializations: hostTrace.workerInitializations,
        durationMs: Date.now() - start,
        sourceBefore: before,
        sourceAfter: after,
        expectedSourceHashes: expectedHashes,
        sourceImportClosure: artifactClosure.imports,
        sourceStable,
        sourceExact: true,
        runtimeOverrides: [
          ...seedOverrides,
          "UI/renderer/input telemetry",
          "worker advanced-step receipt telemetry (extra diagnostic messages)",
          "snapshot application receipt and prediction-stall telemetry",
          `guest inbound callback delay ${observationDelay} ms`,
          ...(completionDelay ? [`guest send delay ${completionDelay} ms ${sendDelayMode} native call`] : [])
        ],
        authorityLag: lag,
        motion,
        workerInputCoverage,
        delivery,
        predictionBlocks: guestTrace.predictionBlocks,
        errors,
        choices,
        timeline,
        host: hostTrace,
        guest: guestTrace,
        reload: {
          beforeReload,
          suspended,
          rejoined,
          sameInvitation: invite === (await host.locator("#coop-invite-link").inputValue())
        }
      }
      await writeFile(
        `${output}/native-sends-${completionDelay}.json`,
        JSON.stringify({ host: hostTrace.nativeSends, guest: guestTrace.nativeSends })
      )
      result.nativeSendTraceFile = `${output}/native-sends-${completionDelay}.json`
      await writeFile(`${output}/completion-${completionDelay}.json`, JSON.stringify(result))
      const badStatus = timeline.filter((x) => /queue is full|failed|could not|disconnected/i.test(x.status))
      const summary: {
        hostTick: number | undefined
        guestTick: number | undefined
        workerErrors: unknown[]
        workerFailures: unknown[]
        [key: string]: unknown
      } = {
        completionDelay,
        sendDelayMode,
        qualification: completionDelay <= 200 ? "interactive-regression" : "bounded-overload-only",
        sourceStable: result.sourceStable,
        sourceExact: result.sourceExact,
        hostTick: hostTrace.lastFrame?.tick,
        guestTick: guestTrace.lastFrame?.tick,
        guestDisplayTick: guestTrace.renders.at(-1)?.timing?.displayWorldTick,
        authorityLag: lag,
        motion,
        workerInputCoverage,
        delivery,
        predictionBlocks: guestTrace.predictionBlocks,
        appliedInputReceipts: appliedReceipts.length,
        nativeSendTraceFile: result.nativeSendTraceFile,
        nativeSendCounts: { host: hostTrace.nativeSends.length, guest: guestTrace.nativeSends.length },
        errors,
        workerErrors: [...hostTrace.workerErrors, ...guestTrace.workerErrors],
        workerFailures: [...hostTrace.workerFailures, ...guestTrace.workerFailures],
        badStatus,
        choices: choices.length,
        reload: result.reload
      }
      summaries.push(summary)
      console.log(JSON.stringify(summary))
      assert.equal(result.sourceStable, true, "candidate changed during diagnostic")
      assert.deepEqual(errors, [])
      assert.deepEqual(summary.workerErrors, [])
      assert.deepEqual(summary.workerFailures, [])
      assert.deepEqual(badStatus, [])
      if (completionDelay === 0 || completionDelay === 200) {
        assert.ok(
          workerInputCoverage.nonneutralAppliedSteps > 0,
          "eligible phase-zero worker steps must apply nonneutral guest input"
        )
        assert.ok(
          workerInputCoverage.appliedRatio >= 0.5,
          `fewer than half of eligible gameplay steps applied guest input: ${workerInputCoverage.appliedRatio}`
        )
        assert.ok(
          motion.host.samples >= 100,
          "remote host motion oracle needs at least 100 eligible post-warmup frame pairs"
        )
        assert.equal(
          motion.host.violationCount,
          0,
          `remote host motion exceeded 4 units/wall-tick plus 1 unit tolerance: ${JSON.stringify(motion.host.violations)}`
        )
        assert.ok(
          lag.activePhaseZeroMs >= 15000,
          "the lag sample must include sustained active gameplay, not only terminal frames"
        )
        assert.ok(
          lag.measuredMs >= 10000 && lag.samples >= 100,
          "phase-zero lag must be sampled after the warmup window"
        )
        assert.ok(lag.maxTicks <= 60, `guest authority lag exceeded 60 ticks: ${lag.maxTicks}`)
        assert.ok(lag.p95Ticks <= 30, `guest authority lag p95 exceeded 30 ticks: ${lag.p95Ticks}`)
        assert.ok(
          lag.windows.every((window) => window.maxTicks <= 60 && window.p95Ticks <= 30),
          "every five-second active window must satisfy the lag bounds"
        )
      }
      assert.ok((summary.hostTick ?? 0) > 100 && (summary.guestTick ?? 0) > 100, "both roles advance")
      assert.ok(defined(rejoined).tick >= beforeReload, "reload resumes same world")
      assert.equal(result.reload.sameInvitation, true)
    } catch (error) {
      await writeFile(
        `${output}/failure-${completionDelay}.json`,
        JSON.stringify({
          message: errorMessage(error),
          stack: error instanceof Error ? error.stack : undefined,
          errors,
          choices,
          timeline,
          host: await host.evaluate(() => globalThis.__reliable).catch(() => null),
          guest: await guest.evaluate(() => globalThis.__reliable).catch(() => null)
        })
      )
      throw error
    } finally {
      await context.close()
    }
  }
  await failureRecoveryAndTouch()
  await writeFile(
    `${output}/summary.json`,
    JSON.stringify(
      {
        kind: "fixed-input actual-Iroh diagnostics; not formal proof",
        scope: recoveryOnly
          ? "worker recovery and mobile touch only; network matrix not rerun"
          : "network matrix plus worker recovery and mobile touch",
        summaries
      },
      null,
      2
    )
  )
} finally {
  await browser.close()
}
