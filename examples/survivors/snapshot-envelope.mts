import type { WireSchema, WireSpec } from "./network-schema.mts"
import { networkSchema } from "./network-schema.generated.mts"
import { at, defined, object, rows, list } from "./host-values.mts"
import { decodeCbor, encodeCbor, MAX_CBOR_CONTAINER_LENGTH } from "./cbor.mts"

const schema: WireSchema = networkSchema
const root: WireSpec = { ref: "CoopNetwork.Snapshot" }
function primitive(type: string, value: unknown) {
  if (
    type === "bool"
      ? typeof value !== "boolean"
      : type === "string"
        ? typeof value !== "string"
        : typeof value !== "number" ||
          !Number.isFinite(value) ||
          (type === "f32"
            ? !Number.isFinite(Math.fround(value))
            : type === "f64"
              ? false
              : !Number.isInteger(value) || value < 0 || value > (type === "u32" ? 0xffffffff : 2 ** 48 - 1))
  )
    throw TypeError(`Invalid snapshot ${type}.`)
  return typeof value === "number" && value === 0 ? 0 : value
}
function wire(spec: WireSpec, value: unknown): unknown {
  if (typeof spec === "string") return primitive(spec, value)
  if ("list" in spec) return rows(value as BendList<unknown>).map((item) => wire(spec.list, item))
  const row = object(value)
  if ("maybe" in spec) return row.$ === "None" ? [] : [wire(spec.maybe, row.value)]
  const variants = defined(schema[spec.ref])
  const index = variants.findIndex(([tag]) => tag === row.$)
  if (index < 0) throw TypeError("Invalid snapshot constructor.")
  return [index, ...at(variants, index)[1].map(([key, type]) => wire(type, row[key]))]
}
function trusted(spec: WireSpec, value: unknown): unknown {
  if (typeof spec === "string") return primitive(spec, value)
  if (!Array.isArray(value) || value.length > MAX_CBOR_CONTAINER_LENGTH) throw TypeError("Invalid snapshot sequence.")
  if ("list" in spec) return list(value.map((item) => trusted(spec.list, item)))
  if ("maybe" in spec) {
    if (value.length === 0) return { $: "None" }
    if (value.length === 1) return { $: "Some", value: trusted(spec.maybe, value[0]) }
    throw TypeError("Invalid snapshot optional value.")
  }
  const variants = defined(schema[spec.ref])
  const variant: unknown = value[0]
  if (typeof variant !== "number" || !Number.isInteger(variant) || variant < 0 || variant >= variants.length)
    throw TypeError("Invalid snapshot variant.")
  const [tag, fields] = at(variants, variant)
  if (value.length !== fields.length + 1) throw TypeError("Invalid snapshot field count.")
  return Object.fromEntries([["$", tag], ...fields.map(([key, type], index) => [key, trusted(type, value[index + 1])])])
}
export function snapshotValues(snapshot: BendABI.CoopNetwork.Snapshot): unknown {
  return wire(root, snapshot)
}
export function encodeSnapshotValues(snapshot: BendABI.CoopNetwork.Snapshot): Uint8Array {
  return encodeCbor(snapshotValues(snapshot))
}
export function admitSnapshot(value: unknown): BendABI.CoopNetwork.Snapshot {
  const snapshot = trusted(root, value) as BendABI.CoopNetwork.Snapshot
  if (snapshot.connectionVersion !== 1) throw TypeError("Unsupported snapshot connection version.")
  if (snapshot.runId.length > 256) throw RangeError("Snapshot run identity is too large.")
  const players = rows(snapshot.view.players)
  if (
    players.length < 1 ||
    players.length > 2 ||
    new Set(players.map((player) => player.id)).size !== players.length ||
    players.some((player) => player.id > 1) ||
    !players.some((player) => player.id === snapshot.view.own)
  )
    throw TypeError("Invalid snapshot players.")
  if (rows(snapshot.contactJournal.events).length > 512) throw RangeError("Snapshot contact history is too large.")
  return snapshot
}
export function decodeSnapshotValues(bytes: Uint8Array): BendABI.CoopNetwork.Snapshot {
  return admitSnapshot(decodeCbor(bytes))
}
