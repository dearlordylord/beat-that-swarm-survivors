import type { Spec, Fields } from "./observation-schema.mts"
import type { SnapshotEnvelope } from "./coop-boundary.mts"
import { defined, object } from "./host-values.mts"
// The one untrusted snapshot boundary. Local Bend results never call this parser.
import { roots, schema } from "./observation-schema.generated.mts"

const MAX_ROWS = 16384
function record(fields: Fields, value: unknown, state: { nodes: number }, depth: number) {
  const row = object(value)
  const keys = Object.keys(row)
  if (keys.length !== fields.length || fields.some(([key]) => !Object.hasOwn(row, key)))
    throw TypeError("Unexpected snapshot fields.")
  for (const [key, type] of fields) check(type, row[key], state, depth + 1)
}
function check(type: Spec, value: unknown, state: { nodes: number }, depth = 0) {
  if (--state.nodes < 0 || depth > 96) throw RangeError("Snapshot structure is too large.")
  if (typeof type === "string") {
    if (
      type === "bool"
        ? typeof value !== "boolean"
        : type === "string"
          ? typeof value !== "string"
          : typeof value !== "number" ||
            !Number.isFinite(value) ||
            (type === "f32"
              ? !Number.isFinite(Math.fround(value))
              : !Number.isInteger(value) || value < 0 || value > (type === "u32" ? 0xffffffff : 2 ** 48 - 1))
    )
      throw TypeError(`Invalid snapshot ${type}.`)
  } else if (type.ref) {
    const row = object(value)
    const variants = defined(schema[type.ref])
    if (typeof row.$ !== "string" || !Object.hasOwn(variants, row.$))
      throw TypeError("Invalid Bend constructor in snapshot.")
    record([["$", { literal: row.$ }], ...defined(variants[row.$])], value, state, depth)
  } else if (type.list) {
    let count = 0,
      node = value
    while (object(node).$ === "Con") {
      if (++count > MAX_ROWS) throw RangeError("Snapshot list is too large.")
      record(
        [
          ["$", { literal: "Con" }],
          ["head", type.list],
          ["tail", { unchecked: true }]
        ],
        node,
        state,
        depth
      )
      node = object(node).tail
    }
    record([["$", { literal: "Nil" }]], node, state, depth)
  } else if (type.array) {
    if (!Array.isArray(value) || value.length > MAX_ROWS) throw TypeError("Invalid snapshot array.")
    for (const item of value) check(type.array, item, state, depth + 1)
  } else if (type.tuple) {
    if (!Array.isArray(value) || value.length !== type.tuple.length) throw TypeError("Invalid body tuple.")
    type.tuple.forEach((item, index) => check(item, value[index], state, depth + 1))
  } else if (type.record) {
    record(type.record, value, state, depth)
  } else if (Object.hasOwn(type, "literal")) {
    if (value !== type.literal) throw TypeError("Invalid snapshot kind.")
  } else if (type.nullable) {
    if (value !== null) check(type.nullable, value, state, depth + 1)
  } else if (!type.unchecked) throw TypeError("Unsupported snapshot schema.")
}
function fields(ref: { ref: string }): Fields {
  return defined(Object.values(defined(schema[ref.ref]))[0])
}
function presentation(type: Spec): Spec {
  if (typeof type === "string") return type
  if (type.ref === "GameBody") return { tuple: fields({ ref: defined(type.ref) }).map(([, field]) => field) }
  if (type.ref === "GameOffer" || type.ref === "CoopCoreObservedPlayer")
    return { record: fields({ ref: defined(type.ref) }) }
  return type
}
const frameFields: (readonly [string, Spec])[] = [...fields(roots.game), ...fields(roots.details)].map(
  ([key, type]) => [key, typeof type !== "string" && type.list ? { array: presentation(type.list) } : type]
)
frameFields.push(["runId", "string"])
const timing: Spec = {
  record: [
    ["worldTick", "u32"],
    [
      "lastRejected",
      { nullable: { record: ["reason", "seq", "targetWorldTick", "worldTick"].map((key) => [key, "u32"]) } }
    ]
  ]
}
const envelope: Spec = {
  record: [
    ["type", { literal: "frame" }],
    ["connectionVersion", "u32"],
    ["token", "u32"],
    ["initial", "bool"],
    ["frame", { record: frameFields }],
    ["admission", roots.admission],
    ["receipt", roots.receipt],
    ["observationSeq", "u32"],
    ["contactJournal", roots.journal],
    ["inputTiming", timing]
  ]
}

function isSnapshot(value: unknown): value is SnapshotEnvelope {
  check(envelope, value, { nodes: 1024 * 1024 })
  return true
}
export function admitSnapshot(value: unknown): SnapshotEnvelope {
  if (isSnapshot(value)) return value
  throw TypeError("Invalid snapshot")
}
