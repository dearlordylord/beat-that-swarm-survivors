import { defined, object, text } from "../../examples/survivors/host-values.mts"
import type { Job } from "./batch.mts"
import { parentPort, workerData } from "node:worker_threads"
import { runBot } from "./runner.mts"
// This entry point deliberately has no provider import or network dependency.
const port = defined(parentPort)
const { default: Game }: { default: BendABI.BotActions.API } = await import(text(object(workerData).bundleURL))
if (typeof Game.fresh_start_seed !== "function" || typeof Game.advanced_start_seed !== "function")
  throw new Error("Seeded facade required")
port.on("message", async (job: Job) => {
  const started = performance.now()
  try {
    const summary = await runBot(Game, {
      mode: "heuristic",
      profile: job.profile,
      seed: job.seed,
      ticks: job.ticks,
      decisions: "both",
      maxUpgradeRequests: 0,
      maxGoalRequests: 0,
      runId: job.runId,
      emit: () => {}
    })
    if (Object.values(summary.classifierAttempts).some((n) => n !== 0)) throw new Error("Offline invariant violated")
    port.postMessage({
      index: job.index,
      seed: job.seed,
      profile: job.profile,
      status: "completed",
      elapsedMs: performance.now() - started,
      summary
    })
  } catch {
    port.postMessage({
      index: job.index,
      seed: job.seed,
      profile: job.profile,
      status: "exception",
      elapsedMs: performance.now() - started
    })
  }
})
