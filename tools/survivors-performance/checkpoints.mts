import { createHash } from "node:crypto"
import { execFileSync } from "node:child_process"
import { readFile, writeFile, mkdir } from "node:fs/promises"
import { dirname, resolve } from "node:path"
import { pathToFileURL } from "node:url"
import { gzipSync, gunzipSync } from "node:zlib"

interface Scenario {
  character: number
  seed: number
  tick: number
  steps: number
  dx: number
  dy: number
}
interface Summary {
  tick: number
  phase: number
  enemies: number
  projectiles: number
  pickups: number
  weapons: number[]
}
interface Checkpoint {
  format: "survivors-checkpoint-v1"
  provenance: {
    moduleSha256: string
    revision: string
    sourceDiffSha256: string
    bendVersion: string
    dependenciesSha256: string
  }
  scenario: Scenario
  stateJson: string
  stateSha256: string
  initial: { digest: string; summary: Summary }
  expected: { digest: string; summary: Summary }
}
interface Engine {
  moduleSha256: string
  start(character: number, seed: number): unknown
  advance(state: unknown, dx: number, dy: number): unknown
  observe(state: unknown): unknown
}
interface WindowResult {
  state: unknown
  observation: unknown
  advanceMs: number
  observeMs: number
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
}
function record(value: unknown): Record<string, unknown> {
  if (!isRecord(value)) throw Error("Expected an object")
  return value
}
function number(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) throw Error("Expected a finite number")
  return value
}
function text(value: unknown): string {
  if (typeof value !== "string") throw Error("Expected a string")
  return value
}
function callable(value: unknown): value is (...args: unknown[]) => unknown {
  return typeof value === "function"
}
function operation(exports: Record<string, unknown>, name: string) {
  const value = exports[name]
  if (!callable(value)) throw Error(`Engine is missing ${name}`)
  return value
}
function validateJson(value: unknown, ancestors: WeakSet<object>): void {
  if (value === null || typeof value === "string" || typeof value === "boolean") return
  if (typeof value === "number" && Number.isFinite(value)) return
  if (typeof value !== "object" || ancestors.has(value)) throw Error("Checkpoint contains a non-JSON value or cycle")
  if (
    !Array.isArray(value) &&
    Object.getPrototypeOf(value) !== Object.prototype &&
    Object.getPrototypeOf(value) !== null
  )
    throw Error("Checkpoint contains a non-plain object")
  if (Object.getOwnPropertySymbols(value).length) throw Error("Checkpoint contains symbol keys")
  ancestors.add(value)
  if (Array.isArray(value)) {
    if (Object.keys(value).some((key) => !/^(0|[1-9][0-9]*)$/.test(key)))
      throw Error("Checkpoint contains an array property")
    for (const entry of value) validateJson(entry, ancestors)
  } else {
    for (const descriptor of Object.values(Object.getOwnPropertyDescriptors(value))) {
      if (descriptor.get || descriptor.set || !descriptor.enumerable)
        throw Error("Checkpoint contains an accessor or hidden field")
      const entry: unknown = descriptor.value
      validateJson(entry, ancestors)
    }
  }
  ancestors.delete(value)
}
export function json(value: unknown): string {
  validateJson(value, new WeakSet())
  const result = JSON.stringify(value)
  if (result === undefined) throw Error("Checkpoint is not serializable")
  return result
}
function sha(value: string | Buffer): string {
  return createHash("sha256").update(value).digest("hex")
}
function list(value: unknown): unknown[] {
  const rows: unknown[] = []
  let row = record(value)
  while (row.$ === "Con") {
    rows.push(row.head)
    row = record(row.tail)
  }
  if (row.$ !== "Nil") throw Error("Invalid Bend list")
  return rows
}
function summary(observation: unknown): Summary {
  const value = record(observation),
    run = record(value.run),
    session = record(run.session),
    player = record(run.player)
  return {
    tick: number(session.tick),
    phase: number(session.phase),
    enemies: list(value.enemies).length,
    projectiles: list(value.projectiles).length,
    pickups: list(value.pickups).length,
    weapons: list(player.weapons).map(number)
  }
}
function packet(value: unknown): unknown {
  const result = record(value)
  if (result.$ !== "Packet") throw Error(`Simulation failed: ${json(result)}`)
  if (record(result.state).$ !== "State") throw Error("Invalid simulation state")
  return result.state
}
function observed(value: unknown): { state: unknown; observation: unknown } {
  const result = record(value)
  if (record(result.state).$ !== "State") throw Error("Invalid observed state")
  summary(result.observation)
  return { state: result.state, observation: result.observation }
}
export async function loadEngine(modulePath: string): Promise<Engine> {
  const path = resolve(modulePath),
    moduleSha256 = sha(await readFile(path))
  const url = pathToFileURL(path)
  url.searchParams.set("checkpointModule", moduleSha256)
  const loaded: unknown = await import(url.href)
  const exports = record(record(loaded).default)
  const start = operation(exports, "start_seed"),
    advance = operation(exports, "advance_live"),
    observe = operation(exports, "observe")
  return { moduleSha256, start: (character, seed) => start(character, 0, seed), advance, observe }
}
function window(engine: Engine, initial: unknown, scenario: Scenario, steps = scenario.steps): WindowResult {
  let state = initial,
    observation: unknown,
    advanceMs = 0,
    observeMs = 0
  for (let i = 0; i < steps; i++) {
    let started = performance.now()
    const advanced = engine.advance(state, scenario.dx, scenario.dy)
    advanceMs += performance.now() - started
    state = packet(advanced)
    started = performance.now()
    const raw = engine.observe(state)
    observeMs += performance.now() - started
    const value = observed(raw)
    state = value.state
    observation = value.observation
  }
  return { state, observation, advanceMs, observeMs }
}
function command(cwd: string, executable: string, args: string[]): string {
  try {
    return execFileSync(executable, args, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim()
  } catch {
    return "unavailable"
  }
}
async function provenance(modulePath: string, moduleSha256: string): Promise<Checkpoint["provenance"]> {
  const cwd = dirname(resolve(modulePath)),
    root = command(cwd, "git", ["rev-parse", "--show-toplevel"])
  let dependenciesSha256 = "unavailable"
  if (root !== "unavailable") {
    try {
      dependenciesSha256 = sha(await readFile(resolve(root, "bendhub-dependencies.json")))
    } catch {}
  }
  return {
    moduleSha256,
    revision: command(cwd, "git", ["rev-parse", "HEAD"]),
    sourceDiffSha256: sha(command(root === "unavailable" ? cwd : root, "git", ["diff", "HEAD", "--", "."])),
    bendVersion: command(cwd, "bend", ["version"]),
    dependenciesSha256
  }
}
export async function captureCheckpoint(modulePath: string, output: string, scenario: Scenario): Promise<Checkpoint> {
  const engine = await loadEngine(modulePath)
  let state = packet(engine.start(scenario.character, scenario.seed))
  for (let i = 0; i < scenario.tick; i++) state = packet(engine.advance(state, scenario.dx, scenario.dy))
  const initial = observed(engine.observe(state)),
    stateJson = json(initial.state),
    initialSummary = summary(initial.observation)
  if (initialSummary.tick !== scenario.tick || initialSummary.phase !== 0)
    throw Error("Capture did not reach the requested active tick")
  const expected = window(engine, initial.state, scenario),
    expectedSummary = summary(expected.observation)
  if (expectedSummary.tick !== scenario.tick + scenario.steps || expectedSummary.phase !== 0)
    throw Error("Replay window did not advance every requested tick in active gameplay")
  const checkpoint: Checkpoint = {
    format: "survivors-checkpoint-v1",
    provenance: await provenance(modulePath, engine.moduleSha256),
    scenario,
    stateJson,
    stateSha256: sha(stateJson),
    initial: { digest: sha(json(initial.observation)), summary: initialSummary },
    expected: { digest: sha(json(expected.observation)), summary: expectedSummary }
  }
  await mkdir(dirname(resolve(output)), { recursive: true })
  await writeFile(output, gzipSync(json(checkpoint)))
  return checkpoint
}
function parseSummary(value: unknown): Summary {
  const row = record(value)
  if (!Array.isArray(row.weapons)) throw Error("Invalid checkpoint loadout")
  return {
    tick: number(row.tick),
    phase: number(row.phase),
    enemies: number(row.enemies),
    projectiles: number(row.projectiles),
    pickups: number(row.pickups),
    weapons: row.weapons.map(number)
  }
}
function parseScenario(value: unknown): Scenario {
  const row = record(value)
  return {
    character: integer(row.character, 0, 7),
    seed: integer(row.seed, 0, 4294967295),
    tick: integer(row.tick, 0, 37000),
    steps: integer(row.steps, 1, 37000),
    dx: number(row.dx),
    dy: number(row.dy)
  }
}
export async function readCheckpoint(path: string): Promise<Checkpoint> {
  const raw: unknown = JSON.parse(gunzipSync(await readFile(path)).toString("utf8")),
    row = record(raw)
  if (row.format !== "survivors-checkpoint-v1") throw Error("Unknown checkpoint format")
  const p = record(row.provenance),
    initial = record(row.initial),
    expected = record(row.expected)
  const result: Checkpoint = {
    format: row.format,
    provenance: {
      moduleSha256: text(p.moduleSha256),
      revision: text(p.revision),
      sourceDiffSha256: text(p.sourceDiffSha256),
      bendVersion: text(p.bendVersion),
      dependenciesSha256: text(p.dependenciesSha256)
    },
    scenario: parseScenario(row.scenario),
    stateJson: text(row.stateJson),
    stateSha256: text(row.stateSha256),
    initial: { digest: text(initial.digest), summary: parseSummary(initial.summary) },
    expected: { digest: text(expected.digest), summary: parseSummary(expected.summary) }
  }
  if (sha(result.stateJson) !== result.stateSha256) throw Error("Checkpoint state checksum mismatch")
  return result
}
export function measureWindow(engine: Engine, checkpoint: Checkpoint, compatibleCandidate = false) {
  if (engine.moduleSha256 !== checkpoint.provenance.moduleSha256 && !compatibleCandidate)
    throw Error("Module hash differs; recapture or explicitly use --compatible-candidate")
  const started = performance.now(),
    restored: unknown = JSON.parse(checkpoint.stateJson),
    restoreMs = performance.now() - started
  const initial = observed(engine.observe(restored))
  if (
    sha(json(initial.observation)) !== checkpoint.initial.digest ||
    json(summary(initial.observation)) !== json(checkpoint.initial.summary)
  )
    throw Error("Restored initial observation differs")
  const result = window(engine, initial.state, checkpoint.scenario),
    end = summary(result.observation)
  if (json(end) !== json(checkpoint.expected.summary) || sha(json(result.observation)) !== checkpoint.expected.digest)
    throw Error("Replay result differs; the checkpoint is not compatible with this candidate")
  return {
    restoreMs,
    advanceMs: result.advanceMs,
    observeMs: result.observeMs,
    totalMs: result.advanceMs + result.observeMs,
    end,
    errors: 0
  }
}
function integer(value: unknown, minimum: number, maximum: number): number {
  const n = typeof value === "string" && /^\d+$/.test(value) ? Number(value) : number(value)
  if (!Number.isSafeInteger(n) || n < minimum || n > maximum)
    throw Error(`Expected an integer from ${minimum} to ${maximum}`)
  return n
}
function required(value: string | undefined): string {
  if (value === undefined) throw Error("Missing argument")
  return value
}
function statistics(values: number[]) {
  const sorted = [...values].sort((a, b) => a - b),
    middle = sorted[Math.floor(sorted.length / 2)]
  if (middle === undefined) throw Error("No measurements")
  return { median: middle, minimum: sorted[0], maximum: sorted.at(-1) }
}
export async function compareCheckpoints(
  left: { checkpoint: string; module: string },
  right: { checkpoint: string; module: string },
  runs = 5,
  compatibleCandidate = false
) {
  const variants = await Promise.all(
    [left, right].map(async (entry) => ({
      ...entry,
      fixture: await readCheckpoint(entry.checkpoint),
      engine: await loadEngine(entry.module)
    }))
  )
  const baseline = variants[0]
  if (!baseline) throw Error("Missing comparison variant")
  for (const entry of variants) {
    for (const key of ["seed", "tick", "steps", "dx", "dy"]) {
      if (record(entry.fixture.scenario)[key] !== record(baseline.fixture.scenario)[key])
        throw Error("Comparison scenarios must share seed, tick, steps and input; characters may differ")
    }
    measureWindow(entry.engine, entry.fixture, compatibleCandidate)
  }
  const rows: ({ run: number; variant: number } & ReturnType<typeof measureWindow>)[] = []
  for (let run = 0; run < runs; run++) {
    for (const index of run % 2 ? [1, 0] : [0, 1]) {
      const entry = variants[index]
      if (!entry) throw Error("Missing comparison variant")
      rows.push({ run: run + 1, variant: index, ...measureWindow(entry.engine, entry.fixture, compatibleCandidate) })
    }
  }
  return {
    format: "survivors-checkpoint-comparison-v1",
    runtime: { node: process.version, platform: process.platform, arch: process.arch },
    runs,
    variants: variants.map((entry, index) => ({
      module: entry.module,
      provenance: entry.fixture.provenance,
      candidateModuleSha256: entry.engine.moduleSha256,
      scenario: entry.fixture.scenario,
      initial: entry.fixture.initial.summary,
      expected: entry.fixture.expected.summary,
      timings: Object.fromEntries(
        ["restoreMs", "advanceMs", "observeMs", "totalMs"].map((key) => [
          key,
          statistics(rows.filter((row) => row.variant === index).map((row) => number(record(row)[key])))
        ])
      )
    })),
    rows
  }
}
async function main(args: string[]) {
  const [action, ...rest] = args
  if (action === "capture") {
    const [module, output] = rest,
      options = new Map<string, string>()
    for (let i = 2; i < rest.length; i += 2) options.set(required(rest[i]), required(rest[i + 1]))
    for (const key of options.keys())
      if (!["--character", "--seed", "--tick", "--steps"].includes(key)) throw Error(`Unknown option ${key}`)
    const fixture = await captureCheckpoint(required(module), required(output), {
      character: integer(options.get("--character") ?? "0", 0, 7),
      seed: integer(options.get("--seed") ?? "12345", 0, 4294967295),
      tick: integer(options.get("--tick") ?? "600", 0, 37000),
      steps: integer(options.get("--steps") ?? "120", 1, 37000),
      dx: 1,
      dy: 0
    })
    process.stdout.write(
      json({
        output,
        provenance: fixture.provenance,
        scenario: fixture.scenario,
        initial: fixture.initial.summary,
        expected: fixture.expected.summary
      }) + "\n"
    )
  } else if (action === "compare") {
    const [leftFixture, leftModule, rightFixture, rightModule] = rest
    let runs = 5,
      compatibleCandidate = false
    for (let i = 4; i < rest.length; i++) {
      if (rest[i] === "--compatible-candidate") compatibleCandidate = true
      else if (rest[i] === "--runs") {
        runs = integer(required(rest[++i]), 1, 100)
      } else throw Error(`Unknown option ${rest[i]}`)
    }
    const report = await compareCheckpoints(
      { checkpoint: required(leftFixture), module: required(leftModule) },
      { checkpoint: required(rightFixture), module: required(rightModule) },
      runs,
      compatibleCandidate
    )
    process.stdout.write(json(report) + "\n")
  } else
    throw Error(
      "Usage: checkpoints.mts capture MODULE OUTPUT [--character N --seed N --tick N --steps N] | compare FIXTURE MODULE FIXTURE MODULE [--runs N] [--compatible-candidate]"
    )
}
if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  main(process.argv.slice(2)).catch((error) => {
    process.stderr.write(String(error) + "\n")
    process.exitCode = 1
  })
}
