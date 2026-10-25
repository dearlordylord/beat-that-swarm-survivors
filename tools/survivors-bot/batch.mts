import { at, errorMessage } from "../../examples/survivors/host-values.mts"
import type { runBot } from "./runner.mts"
import { Worker } from "node:worker_threads"
import { availableParallelism } from "node:os"
import { parseArgs } from "node:util"
import { pathToFileURL } from "node:url"
import { randomUUID, createHash } from "node:crypto"
import { mkdirSync, readFileSync, writeFileSync, appendFileSync } from "node:fs"
interface BatchOptions {
  count: number
  ticks: number
  workers: number
  seed: number
  profile: string
  wallSeconds: number
}
export interface Job {
  index: number
  runId: string
  seed: number
  profile: string
  ticks: number
}
interface JobResult {
  index: number
  seed: number
  profile: string
  status: string
  elapsedMs?: number
  summary?: Awaited<ReturnType<typeof runBot>>
  ticks?: number | undefined
  mode?: string
}
interface PoolOptions {
  workers: number
  wallSeconds: number
  bundleURL: string | URL
  onResult?: (result: JobResult) => void
  signal?: AbortSignal
  workerURL?: URL
}

export function validateOptions(input: Partial<BatchOptions> = {}, cpus = availableParallelism()) {
  const o = { count: 1000, ticks: 1800, workers: 1, seed: 12345, profile: "fresh", wallSeconds: 300, ...input }
  const bounds: [Exclude<keyof BatchOptions, "profile">, number, number][] = [
    ["count", 1, 10000],
    ["ticks", 1, 37000],
    ["workers", 1, Math.min(8, cpus)],
    ["seed", 0, 4294967295],
    ["wallSeconds", 1, 86400]
  ]
  for (const [key, min, max] of bounds) {
    if (!Number.isSafeInteger(o[key]) || o[key] < min || o[key] > max) throw new Error("Invalid batch option: " + key)
  }
  if (!["fresh", "advanced", "both"].includes(o.profile)) throw new Error("Invalid batch profile")
  return o
}
export function makeJobs(options: BatchOptions, batchId: string): Job[] {
  return Array.from({ length: options.count }, (_, index) => ({
    index,
    runId: `${batchId}-${index}`,
    seed: (options.seed + index) >>> 0,
    profile: options.profile === "both" ? (index % 2 ? "advanced" : "fresh") : options.profile,
    ticks: options.ticks
  }))
}
export async function runPool(
  jobs: Job[],
  {
    workers,
    wallSeconds,
    bundleURL,
    onResult = () => {},
    signal,
    workerURL = new URL("./batch-worker.mts", import.meta.url)
  }: PoolOptions
) {
  let next = 0,
    stopReason: string | null = null
  const active = new Map<Worker, Job | null>(),
    results: JobResult[] = [],
    byIndex = new Map(jobs.map((job) => [job.index, job]))
  const { promise: done, resolve: finish } = Promise.withResolvers<void>()
  const record = (result: JobResult) => {
    const job = byIndex.get(result.index)
    const enriched = { ...result, ticks: job?.ticks, mode: "heuristic" }
    results.push(enriched)
    onResult(enriched)
  }
  const shutdown = (reason: string) => {
    if (stopReason) return
    stopReason = reason
    for (const [worker, job] of active) {
      if (job)
        record({
          index: job.index,
          seed: job.seed,
          profile: job.profile,
          status: reason === "wall-budget" ? "timeout" : "interrupted"
        })
      void worker.terminate()
    }
    finish()
  }
  const abort = () => shutdown("interrupted")
  signal?.addEventListener("abort", abort, { once: true })
  const timer = setTimeout(() => shutdown("wall-budget"), wallSeconds * 1000)
  const dispatch = (worker: Worker) => {
    if (stopReason) return
    if (next >= jobs.length) {
      active.delete(worker)
      void worker.terminate()
      if (!active.size) finish()
      return
    }
    const job = at(jobs, next++)
    active.set(worker, job)
    worker.postMessage(job)
  }
  const launch = () => {
    const worker = new Worker(workerURL, { workerData: { bundleURL } })
    active.set(worker, null)
    worker.on("message", (result: JobResult) => {
      if (stopReason) return
      const job = active.get(worker)
      if (!job || result.index !== job.index) return shutdown("worker-protocol-error")
      record(result)
      active.set(worker, null)
      dispatch(worker)
    })
    const workerFailed = () => {
      if (stopReason || !active.has(worker)) return
      const job = active.get(worker)
      if (job) record({ index: job.index, seed: job.seed, profile: job.profile, status: "exception" })
      active.delete(worker)
      // A module-load failure before online is a batch infrastructure failure.
      if (!job) return shutdown("worker-start-error")
      if (next < jobs.length) launch()
      else if (!active.size) finish()
    }
    worker.on("error", workerFailed)
    worker.on("exit", workerFailed)
    worker.once("online", () => dispatch(worker))
  }
  if (signal?.aborted) shutdown("interrupted")
  else for (let i = 0; i < Math.min(workers, jobs.length); i++) launch()
  await done
  clearTimeout(timer)
  signal?.removeEventListener("abort", abort)
  await Promise.all([...active.keys()].map((worker) => worker.terminate()))
  return {
    status: stopReason ?? (results.some((r) => r.status !== "completed") ? "completed-with-errors" : "complete"),
    requested: jobs.length,
    started: next,
    completed: results.filter((r) => r.status === "completed").length,
    failed: results.filter((r) => r.status === "exception").length,
    timedOut: results.filter((r) => r.status === "timeout").length,
    unstarted: jobs.length - next,
    results
  }
}
async function main() {
  const { values } = parseArgs({
    options: Object.fromEntries(
      ["count", "ticks", "workers", "seed", "profile", "wall-seconds"].map((key) => [key, { type: "string" }])
    )
  })
  const input = Object.fromEntries(
    Object.entries(values).map(([key, value]) => [
      key === "wall-seconds" ? "wallSeconds" : key,
      key === "profile" ? value : Number(value)
    ])
  )
  const options = validateOptions(input),
    batchId = randomUUID()
  const directory = new URL(`../../examples/survivors/dist/bot-batches/${batchId}/`, import.meta.url)
  mkdirSync(directory, { recursive: true })
  // Snapshot once: later builds must not change modules imported by queued workers.
  const bundleBytes = readFileSync(new URL("../../examples/survivors/dist/bot-actions.mjs", import.meta.url))
  const frozenBundle = new URL("simulation.mjs", directory)
  writeFileSync(frozenBundle, bundleBytes)
  const bundleURL = frozenBundle.href
  const files = [
    "../../examples/survivors/game.bend",
    "../../examples/survivors/bot-actions.bend",
    "../../examples/survivors/dist/bot-actions.mjs",
    "./runner.mts",
    "./context.mts",
    "./planner.mts",
    "./batch.mts",
    "./batch-worker.mts"
  ]
  const hashes = Object.fromEntries(
    files.map((file) => [
      file,
      createHash("sha256")
        .update(file.endsWith("/dist/bot-actions.mjs") ? bundleBytes : readFileSync(new URL(file, import.meta.url)))
        .digest("hex")
    ])
  )
  const manifest = {
    batchId,
    startedAt: new Date().toISOString(),
    status: "running",
    mode: "heuristic",
    networkRequests: 0,
    options,
    node: process.version,
    hashes,
    provenanceScope: "Selected sources and exact compiled bundle; not a complete import closure."
  }
  const manifestURL = new URL("manifest.json", directory)
  writeFileSync(manifestURL, JSON.stringify(manifest, null, 2))
  console.log("Batch: " + directory.pathname)
  const controller = new AbortController()
  const interrupt = () => controller.abort()
  process.once("SIGINT", interrupt)
  process.once("SIGTERM", interrupt)
  const { results: _results, ...summary } = await runPool(makeJobs(options, batchId), {
    ...options,
    bundleURL,
    signal: controller.signal,
    onResult: (result) =>
      appendFileSync(
        new URL("runs.jsonl", directory),
        JSON.stringify({ ...result, bundleSha256: hashes["../../examples/survivors/dist/bot-actions.mjs"] }) + "\n"
      )
  })
  process.removeListener("SIGINT", interrupt)
  process.removeListener("SIGTERM", interrupt)
  writeFileSync(manifestURL, JSON.stringify({ ...manifest, ...summary, finishedAt: new Date().toISOString() }, null, 2))
  console.log(JSON.stringify(summary))
  if (summary.status !== "complete") process.exitCode = 2
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href)
  main().catch((error: unknown) => {
    console.error("Batch failed: " + errorMessage(error))
    process.exitCode = 1
  })
