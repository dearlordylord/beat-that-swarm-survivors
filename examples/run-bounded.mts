import { spawn, spawnSync } from "node:child_process"
import { constants } from "node:os"
interface ProcessRow {
  pid: number
  parent: number
  start: string
  depth: number
}
function errorCode(error: unknown): unknown {
  return typeof error === "object" && error !== null && "code" in error ? error.code : undefined
}
function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error)
}
// Portable check timeout, including separately detached compiler descendants.
// Cancellation snapshots only the owned subtree still connected at cancellation;
// a daemon already reparented beforehand cannot be recovered from POSIX ps.

const [seconds, command, ...args] = process.argv.slice(2)
if (!command || !Number.isFinite(Number(seconds)) || !(Number(seconds) > 0))
  throw Error("Usage: run-bounded.mts SECONDS COMMAND [ARGS...]")
const invocation = JSON.stringify([command, ...args])
const context = `command=${invocation} cwd=${JSON.stringify(process.cwd())}`
const child = spawn(command, args, { stdio: "inherit", detached: process.platform !== "win32" })
let timedOut = false,
  requestedSignal: NodeJS.Signals = "SIGTERM",
  escalation: ReturnType<typeof setTimeout> | undefined,
  cleaning = false
const owned = new Map<number, ProcessRow>()
const stopped = new Set<number>()
function processes() {
  const result = spawnSync("ps", ["-axo", "pid=,ppid=,lstart="], { encoding: "utf8", timeout: 1000 })
  if (result.error || result.status !== 0)
    throw Error(
      `Process inspection failed: command=["ps","-axo","pid=,ppid=,lstart="] exit=${result.status} signal=${result.signal} error=${result.error ? errorMessage(result.error) : "none"}\nstdout:\n${result.stdout ?? ""}\nstderr:\n${result.stderr ?? ""}`
    )
  return new Map<number, ProcessRow>(
    result.stdout
      .trim()
      .split("\n")
      .flatMap<[number, ProcessRow]>((line) => {
        const match = line.trim().match(/^(\d+)\s+(\d+)\s+(.+)$/)
        return match
          ? [[Number(match[1]), { pid: Number(match[1]), parent: Number(match[2]), start: match[3] ?? "", depth: 0 }]]
          : []
      })
  )
}
function snapshot() {
  const rows = processes()
  // The immediate child is still owned by Node. After it exits, retain only
  // recorded identities; never adopt a replacement process with the same PID.
  const pid = child.pid,
    record = pid === undefined ? undefined : rows.get(pid)
  if (pid !== undefined && record && child.exitCode === null && child.signalCode === null && !owned.has(pid))
    owned.set(pid, record)
  let changed = true
  while (changed) {
    changed = false
    for (const row of rows.values()) {
      const parent = owned.get(row.parent),
        liveParent = rows.get(row.parent)
      if (!owned.has(row.pid) && parent && liveParent?.start === parent.start) {
        owned.set(row.pid, { ...row, depth: parent.depth + 1 })
        changed = true
      }
    }
  }
  return rows
}
function signalOwned(signal: NodeJS.Signals, rows: Map<number, ProcessRow>) {
  for (const record of [...owned.values()].sort((a, b) =>
    signal === "SIGSTOP" ? a.depth - b.depth : b.depth - a.depth
  )) {
    if (rows.get(record.pid)?.start !== record.start) continue
    try {
      process.kill(record.pid, signal)
      if (signal === "SIGSTOP") stopped.add(record.pid)
      if (signal === "SIGKILL") stopped.delete(record.pid)
    } catch (error) {
      if (errorCode(error) !== "ESRCH") throw error
    }
  }
}
function fallback(signal: NodeJS.Signals) {
  // Once the direct child has exited, its PID/group ID may be reused. Known
  // descendants are handled separately through their recorded identities.
  if (!child.pid || child.exitCode !== null || child.signalCode !== null) return
  try {
    if (process.platform === "win32") {
      child.kill(signal)
    } else {
      process.kill(-child.pid, signal)
    }
  } catch (error) {
    if (errorCode(error) !== "ESRCH") throw error
  }
}
function finishCleanup() {
  clearTimeout(escalation)
  try {
    if (process.platform === "win32") fallback("SIGKILL")
    else {
      // Freeze recorded processes before the final scan so their descendants
      // cannot escape by forking while their ancestors are being terminated.
      for (let pass = 0; pass < 3; pass++) signalOwned("SIGSTOP", snapshot())
      signalOwned("SIGKILL", snapshot())
    }
  } catch (error) {
    console.error(errorMessage(error))
    // A failed later ps scan must not strand descendants we already froze.
    // These PIDs were identity-checked immediately before their SIGSTOP.
    for (const pid of stopped) {
      try {
        process.kill(pid, "SIGKILL")
      } catch (failure) {
        if (errorCode(failure) !== "ESRCH") console.error(errorMessage(failure))
      }
    }
    // If inspection fails before any freeze, only the child's private group
    // can be killed safely; unstopped stale PIDs might have been reused.
    fallback("SIGKILL")
  }
  process.exitCode = timedOut ? 124 : 128 + (constants.signals[requestedSignal] ?? 0)
}
function cancel(signal: NodeJS.Signals, timeout = false) {
  if (cleaning) return
  cleaning = true
  timedOut = timeout
  clearTimeout(timer)
  if (!timeout) {
    requestedSignal = signal
    console.error(`Check canceled: ${context} signal=${signal} timeout=false`)
  }
  try {
    if (process.platform === "win32") {
      fallback(timeout ? "SIGKILL" : signal)
    } else {
      signalOwned(signal, snapshot())
    }
  } catch (error) {
    console.error(errorMessage(error))
    fallback(timeout ? "SIGKILL" : signal)
  }
  // Keep this timer even if the immediate child exits: detached descendants
  // remain our responsibility after their parent has disappeared.
  if (timeout) finishCleanup()
  else escalation = setTimeout(finishCleanup, 250)
}
const timer = setTimeout(
  () => {
    console.error(`Check exceeded ${seconds} seconds: ${context} timeout=true wallLimitSeconds=${seconds}`)
    cancel("SIGSTOP", true)
  },
  Number(seconds) * 1000
)
child.once("error", (error) => {
  clearTimeout(timer)
  console.error(`Check could not start: ${context} timeout=false error=${errorMessage(error)}`)
  process.exitCode = 1
})
child.once("exit", (code, signal) => {
  clearTimeout(timer)
  if (!cleaning) {
    process.exitCode = code ?? (signal ? 128 + (constants.signals[signal] ?? 0) : 1)
    if (process.exitCode !== 0)
      console.error(`Check failed: ${context} exit=${code} signal=${signal ?? "none"} timeout=false`)
  }
})
const cancellationSignals: NodeJS.Signals[] = ["SIGINT", "SIGTERM"]
for (const signal of cancellationSignals) process.once(signal, () => cancel(signal))
