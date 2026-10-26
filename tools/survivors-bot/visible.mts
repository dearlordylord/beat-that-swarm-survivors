import { parseObservation } from "./observations.mts"
import { object, errorCode, errorMessage, defined } from "../../examples/survivors/host-values.mts"
import type { Frame } from "../../examples/survivors/frame.mts"
import type { ChildProcess } from "node:child_process"
import { parseArgs } from "node:util"
import { mkdirSync, readFileSync, writeFileSync, renameSync, appendFileSync, existsSync } from "node:fs"
import { resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { spawn } from "node:child_process"
import { randomUUID, createHash } from "node:crypto"
import { setTimeout as delay } from "node:timers/promises"
import { makeVisibleController, encodeCommand } from "./visible-controller.mts"
const { values: v } = parseArgs({
  options: {
    seed: { type: "string", default: "12345" },
    mode: { type: "string", default: "heuristic" },
    profile: { type: "string", default: "fresh" },
    seconds: { type: "string", default: "120" },
    "max-upgrade-requests": { type: "string", default: "6" },
    "max-goal-requests": { type: "string", default: "2" },
    "timeout-ms": { type: "string", default: "2000" },
    binary: { type: "string", default: "examples/survivors/dist/nightfall-bot" },
    "receipts-dir": { type: "string" },
    help: { type: "boolean" }
  }
})
if (v.help) {
  console.log(
    "visible.sh --mode heuristic|jev --profile fresh|advanced --seconds 120 --seed 12345 --max-upgrade-requests 6 --max-goal-requests 2 --timeout-ms 2000"
  )
  process.exit(0)
}
const seed = Number(v.seed)
if (!/^\d+$/.test(v.seed) || !Number.isSafeInteger(seed) || seed < 0 || seed > 0xffffffff)
  throw new Error("seed must be a U32 decimal integer")
const seconds = Number(v.seconds)
if (!Number.isSafeInteger(seconds) || seconds < 1 || seconds > 900)
  throw new Error("seconds must be 1..900 wall seconds")
const runId = randomUUID(),
  base = v["receipts-dir"]
    ? resolve(v["receipts-dir"])
    : fileURLToPath(new URL("../../examples/survivors/dist/bot-runs/", import.meta.url))
mkdirSync(base, { recursive: true })
const session = resolve(base, runId)
mkdirSync(session, { mode: 0o700 })
const receipt = resolve(base, runId + ".jsonl"),
  binary = resolve(v.binary)
const emit = (record: unknown) =>
  appendFileSync(receipt, JSON.stringify({ ...object(record), wallTime: new Date().toISOString() }) + "\n")
const classify = v.mode === "jev" ? (await import("./provider.mts")).classifyDecision : undefined
const controller = makeVisibleController({
  runId,
  mode: v.mode,
  profile: v.profile,
  maxUpgradeRequests: Number(v["max-upgrade-requests"]),
  maxGoalRequests: Number(v["max-goal-requests"]),
  timeoutMs: Number(v["timeout-ms"]),
  classify,
  emit
})
const paths = [
  "examples/survivors/native-bot.bend",
  "examples/survivors/native.bend",
  "examples/survivors/game.bend",
  "examples/survivors/bot-actions.bend",
  "tools/survivors-bot/visible-controller.mts",
  "tools/survivors-bot/context.mts",
  "tools/survivors-bot/provider.mts",
  "tools/survivors-bot/visible.mts",
  "tools/survivors-bot/runner.mts",
  "tools/survivors-bot/planner.mts",
  "tools/survivors-bot/package-lock.json",
  "examples/survivors/content.mts",
  binary
]
const hashes = Object.fromEntries(paths.map((p) => [p, createHash("sha256").update(readFileSync(p)).digest("hex")]))
emit({
  type: "provenance",
  hashes,
  qualification: "Selected source hashes plus executed binary, not complete import closure.",
  modelAliasNote: "jev-latest is mutable."
})
emit({
  type: "start",
  runId,
  mode: v.mode,
  profile: v.profile,
  seed,
  execution: "native-window-lockstep",
  wallLimitSeconds: seconds,
  inference: "Simulation waits; native window remains responsive."
})
console.log("Visible bot receipt: " + receipt)
console.log("Journal: node tools/survivors-bot/journal.mts --receipt " + receipt)
let child: ChildProcess | undefined,
  exited: Promise<void> | undefined,
  done = false,
  sequence = 0,
  lastFrame: Frame | undefined,
  nativeExit: { code: number | null; signal: NodeJS.Signals | null; expected: boolean } | undefined,
  reason = "wall-limit",
  failure: unknown
const stop = () => {
  done = true
  reason = "interrupted"
  child?.kill("SIGTERM")
}
process.on("SIGINT", stop)
process.on("SIGTERM", stop)
try {
  const nativeEnv: NodeJS.ProcessEnv = {
    ...process.env,
    NIGHTFALL_BOT_SESSION: session,
    NIGHTFALL_BOT_PROFILE: v.profile,
    NIGHTFALL_BOT_SEED: String(seed)
  }
  // Managed launches use their own runtime defaults, without ambient RTS overrides.
  delete nativeEnv.BENDRTS
  const launched = spawn(binary, [], { cwd: session, env: nativeEnv, stdio: ["ignore", "inherit", "inherit"] })
  child = launched
  exited = new Promise<void>((resolveExit) => {
    launched.on("error", (e) => {
      failure = e
      done = true
      resolveExit()
    })
    launched.on("exit", (code, signal) => {
      nativeExit = { code, signal, expected: done }
      if (!done) {
        reason = code === 0 ? "window-closed" : "native-error"
        if (code !== 0 || signal !== null) failure = new Error("Unexpected native exit")
      }
      done = true
      resolveExit()
    })
  })
  const deadline = Date.now() + seconds * 1000
  while (!done && Date.now() < deadline) {
    if (existsSync(resolve(session, "closed.json"))) {
      reason = "window-closed"
      break
    }
    let observation
    try {
      observation = parseObservation(JSON.parse(readFileSync(resolve(session, "observation.json"), "utf8")))
    } catch (e) {
      if (errorCode(e) !== "ENOENT" && !(e instanceof SyntaxError)) throw e
      await delay(10)
      continue
    }
    if (observation.sequence === sequence) {
      await delay(10)
      continue
    }
    const command = await controller(observation)
    sequence = observation.sequence
    lastFrame = observation.frame
    if (!command) {
      reason = "terminal"
      break
    }
    if (done || Date.now() >= deadline) break
    const target = resolve(session, `command-${sequence}.txt`),
      temp = target + ".tmp"
    writeFileSync(temp, encodeCommand(command), { mode: 0o600 })
    renameSync(temp, target)
    emit({ type: "command", sequence, tick: defined(lastFrame).tick, command })
  }
  if (failure) throw failure
} catch (error) {
  const fields = typeof error === "object" && error !== null ? object(error) : {}
  const diagnostic = {
    message: errorMessage(error),
    stack: error instanceof Error ? error.stack : undefined,
    ...Object.fromEntries(
      ["code", "errno", "path", "syscall"].flatMap((key) => {
        const value = fields[key]
        return typeof value === "string" || typeof value === "number" ? [[key, value]] : []
      })
    ),
    command: [binary],
    nativeExit
  }
  console.error("Visible session failed", diagnostic)
  if (reason !== "native-error") reason = "controller-error"
  emit({ type: "error", reason: "Visible session failed; inspect native diagnostics.", diagnostic })
  process.exitCode = 1
} finally {
  if (child && exited) {
    done = true // Intentional cleanup must not relabel wall-limit/terminal as native failure.
    child.kill("SIGTERM")
    let timer: ReturnType<typeof setTimeout> | undefined
    await Promise.race([
      exited,
      new Promise<void>((r) => {
        timer = setTimeout(() => {
          child?.kill("SIGKILL")
          r()
        }, 2000)
      })
    ])
    clearTimeout(timer)
  }
  emit({
    type: "summary",
    runId,
    seed,
    outcome: reason,
    nativeExit,
    tick: lastFrame?.tick,
    hp: lastFrame?.hp,
    level: lastFrame?.level,
    kills: lastFrame?.kills,
    gold: lastFrame?.gold,
    phase: lastFrame?.phase
  })
  process.removeListener("SIGINT", stop)
  process.removeListener("SIGTERM", stop)
}
