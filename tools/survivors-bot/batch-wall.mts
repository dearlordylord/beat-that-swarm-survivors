import { validateOptions } from "./batch.mts"
import { parseArgs } from "node:util"
const { values } = parseArgs({
  options: {
    count: { type: "string" },
    ticks: { type: "string" },
    workers: { type: "string" },
    seed: { type: "string" },
    profile: { type: "string" },
    "wall-seconds": { type: "string" }
  }
})
const options = validateOptions({
  ...(values.count === undefined ? {} : { count: Number(values.count) }),
  ...(values.ticks === undefined ? {} : { ticks: Number(values.ticks) }),
  ...(values.workers === undefined ? {} : { workers: Number(values.workers) }),
  ...(values.seed === undefined ? {} : { seed: Number(values.seed) }),
  ...(values.profile === undefined ? {} : { profile: values.profile }),
  ...(values["wall-seconds"] === undefined ? {} : { wallSeconds: Number(values["wall-seconds"]) })
})
console.log(options.wallSeconds + 5)
