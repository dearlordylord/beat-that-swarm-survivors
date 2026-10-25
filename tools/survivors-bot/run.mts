import { errorCode } from "../../examples/survivors/host-values.mts"
import { parseArgs } from "node:util"
import { mkdirSync, appendFileSync, readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { randomUUID, createHash } from "node:crypto"
import { runBot } from "./runner.mts"

const { values } = parseArgs({
  options: {
    seed: { type: "string", default: "12345" },
    mode: { type: "string", default: "heuristic" },
    profile: { type: "string", default: "fresh" },
    ticks: { type: "string", default: "1800" },
    decisions: { type: "string", default: "both" },
    "max-upgrade-requests": { type: "string", default: "6" },
    "max-goal-requests": { type: "string", default: "2" },
    "timeout-ms": { type: "string", default: "2000" },
    "inspect-actions": { type: "boolean", default: false },
    help: { type: "boolean", default: false }
  }
})
if (values.help) {
  console.log(
    "run.sh --mode heuristic|jev --profile fresh|advanced --decisions upgrades|both --ticks 1800 --seed 12345 --max-upgrade-requests 6 --max-goal-requests 2 --timeout-ms 2000 [--inspect-actions]"
  )
  process.exit(0)
}
try {
  const seed = Number(values.seed)
  if (!/^\d+$/.test(values.seed) || !Number.isSafeInteger(seed) || seed < 0 || seed > 0xffffffff)
    throw new Error("seed must be a U32 decimal integer")
  const { default: Game } = await import("../../examples/survivors/dist/bot-actions.mjs")
  if (values["inspect-actions"]) {
    if (!["fresh", "advanced"].includes(values.profile)) throw new Error("Invalid profile")
    const start = values.profile === "fresh" ? Game.fresh_start_seed(seed) : Game.advanced_start_seed(seed)
    if (start.$ !== "Packet") throw new Error("Bend start failed")
    const next = Game.advance(start.state, 0, 0)
    if (next.$ !== "Packet") throw new Error("Bend advance failed")
    const observed = Game.observe(next.state)
    if (observed.$ !== "Observed") throw new Error("Bend observation failed")
    const frame = JSON.parse(observed.frame)
    console.log(
      JSON.stringify(
        {
          profile: values.profile,
          seed,
          tick: frame.tick,
          upgradeOffers: frame.offers,
          goals: JSON.parse(observed.actions),
          mechanics: JSON.parse(observed.mechanics)
        },
        null,
        2
      )
    )
    process.exit(0)
  }
  const runId = randomUUID(),
    directory = new URL("../../examples/survivors/dist/bot-runs/", import.meta.url)
  mkdirSync(directory, { recursive: true })
  const receipt = fileURLToPath(new URL(runId + ".jsonl", directory))
  const files = [
    "../../examples/survivors/game.bend",
    "../../examples/survivors/bot-actions.bend",
    "../../examples/survivors/dist/bot-actions.mjs",
    "../../examples/survivors/content.mts",
    "./context.mts",
    "./provider.mts",
    "./runner.mts",
    "./planner.mts",
    "./package-lock.json"
  ]
  const hashes = Object.fromEntries(
    files.map((file) => [
      file,
      createHash("sha256")
        .update(readFileSync(new URL(file, import.meta.url)))
        .digest("hex")
    ])
  )
  appendFileSync(
    receipt,
    JSON.stringify({
      type: "provenance",
      node: process.version,
      hashes,
      modelAliasNote: "jev-latest is a mutable provider alias; no immutable weights identity is claimed."
    }) + "\n"
  )
  const classify = values.mode === "jev" ? (await import("./provider.mts")).classifyDecision : undefined
  console.log("Bot receipt: " + receipt)
  const summary = await runBot(Game, {
    mode: values.mode,
    profile: values.profile,
    decisions: values.decisions,
    seed,
    ticks: Number(values.ticks),
    maxUpgradeRequests: Number(values["max-upgrade-requests"]),
    maxGoalRequests: Number(values["max-goal-requests"]),
    timeoutMs: Number(values["timeout-ms"]),
    classify,
    runId,
    emit: (record) => appendFileSync(receipt, JSON.stringify(record) + "\n")
  })
  console.log(JSON.stringify(summary))
} catch (error) {
  console.error(
    "Bot run failed: " +
      (errorCode(error) === "ERR_MODULE_NOT_FOUND"
        ? "build the optional bot module and install its dependencies first (see README)."
        : "invalid options, observation, or simulation transition; inspect the local receipt.")
  )
  process.exitCode = 1
}
