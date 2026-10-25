import { decodeControlFrame } from "./coop-control-frame.mts"
import { bendModule } from "../bend-module.mts"
import { resolve } from "node:path"
import { pathToFileURL } from "node:url"
import { defined } from "./host-values.mts"
import assert from "node:assert/strict"
import {
  decodeSnapshot,
  encodeSnapshot,
  SnapshotDecoder,
  MAX_SNAPSHOT_RAW_BYTES,
  MAX_SNAPSHOT_COMPRESSED_BYTES,
  MAX_SNAPSHOT_DECODE_JOBS,
  MAX_SNAPSHOT_DECODE_QUEUE_BYTES
} from "./coop-snapshot-codec.mts"
const { default: Connection } = await bendModule<BendABI.CoopConnection.API>()(
  pathToFileURL(resolve(process.argv[2] || "examples/survivors/dist/web/dist/coop-connection.mjs")).href,
  ["encode_action", "decode"]
)
// Node Web Streams check for the browser-compatible snapshot byte codec.

assert.equal(typeof CompressionStream, "function")
assert.equal(typeof DecompressionStream, "function")
let checks = 0
const check = (condition: unknown, message: string) => {
  assert.ok(condition, message)
  checks++
}
const equalBytes = (actual: unknown, expected: unknown, message: string) => {
  assert.deepEqual(actual, expected, message)
  checks++
}
const textEncoder = new TextEncoder()
const textDecoder = new TextDecoder("utf-8", { fatal: true })
const MAGIC = Uint8Array.of(0x42, 0x53, 0x5a, 0x31)
function concatenate(left: Uint8Array, right: Uint8Array) {
  const output = new Uint8Array(left.byteLength + right.byteLength)
  output.set(left, 0)
  output.set(right, left.byteLength)
  return output
}
async function gzip(bytes: Uint8Array) {
  const source = new ReadableStream({
    start(controller) {
      controller.enqueue(bytes)
      controller.close()
    }
  })
  const output = await new Response(source.pipeThrough(new CompressionStream("gzip"))).arrayBuffer()
  return new Uint8Array(output)
}
function deferred() {
  return Promise.withResolvers<void>()
}
async function until(predicate: () => boolean, message: string) {
  for (let attempt = 0; attempt < 30; attempt++) {
    if (predicate()) return
    await new Promise((resolve) => setImmediate(resolve))
  }
  assert.fail(message)
}
const scene = {
  tick: 18420,
  phase: 3,
  players: [
    { id: 0, x: 128.25, y: 96.5, hp: 82, maxHp: 100, weapon: "wand", level: 4 },
    { id: 1, x: 164.75, y: 112.0, hp: 67, maxHp: 100, weapon: "knife", level: 3 }
  ],
  enemies: Array.from({ length: 900 }, (_, id) => ({
    id,
    kind: id % 7,
    x: (id % 91) * 13.25,
    y: (id % 67) * 9.5,
    hp: 40 + (id % 61),
    maxHp: 100,
    radius: 8.5,
    seed: id % 127,
    generation: Math.floor(id / 127),
    state: id % 19 === 0 ? "attacking" : "moving",
    target: id % 2,
    velocity: { x: (id % 5) - 2, y: (id % 3) - 1 }
  })),
  projectiles: Array.from({ length: 220 }, (_, id) => ({
    id,
    owner: id % 2,
    x: (id % 43) * 5.5,
    y: (id % 37) * 4.25,
    vx: 2.5,
    vy: -1.25,
    radius: 4,
    life: 29,
    pierce: 1
  }))
}
const sceneText = JSON.stringify(scene)
const sceneBytes = textEncoder.encode(sceneText)
const sceneEncoded = await encodeSnapshot(textEncoder.encode(sceneText))
check(
  sceneBytes.byteLength >= 100000 && sceneBytes.byteLength <= MAX_SNAPSHOT_RAW_BYTES,
  "repeated snapshot fixture is a bounded ~100 KB scene"
)
equalBytes(sceneEncoded.subarray(0, MAGIC.byteLength), MAGIC, "encoded frames use BSZ1")
check(sceneEncoded.byteLength < sceneBytes.byteLength / 2, "gzip materially shrinks a repeated scene")
equalBytes(await decodeSnapshot(sceneEncoded), sceneBytes, "scene bytes round-trip exactly")
check(
  textDecoder.decode(await decodeSnapshot(sceneEncoded)) === sceneText,
  "compressed scene remains strict UTF-8 JSON"
)
// Deterministic generated text samples exercise UTF-8 widths and mixed content.
const alphabet = [
  "a",
  "\u0000",
  "\n",
  "\u007f",
  "\u0080",
  "\u07ff",
  "\u0800",
  "\ud7ff",
  "\ue000",
  "\uffff",
  "é",
  "Ω",
  "中",
  "🛰",
  "𝄞",
  "e\u0301"
]
for (let seed = 1; seed <= 40; seed++) {
  let state = (seed * 2654435761) >>> 0
  const parts = []
  const length = 1 + ((seed * 37) % 257)
  for (let index = 0; index < length; index++) {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0
    parts.push(alphabet[state % alphabet.length])
  }
  const text = parts.join("")
  const raw = textEncoder.encode(text)
  const frame = await encodeSnapshot(textEncoder.encode(text))
  equalBytes(await decodeSnapshot(frame), raw, `UTF-8 byte round-trip seed ${seed}`)
  check(textDecoder.decode(await decodeSnapshot(frame)) === text, `UTF-8 text round-trip seed ${seed}`)
}
const control = textEncoder.encode(Connection.encode_action({ $: "SendHello", version: 1, token: 42 }))
assert.deepEqual(decodeControlFrame(control, Connection.decode), {
  $: "Some",
  value: { $: "Hello", version: 1, token: 42 }
})
const actions: BendABI.CoopConnection.Action[] = [
  { $: "HelloAckAndSetup", version: 1, token: 42 },
  { $: "SendReadyAck", token: 42, observation: 9 },
  { $: "StartAndConfirm", token: 42 },
  { $: "CloseConnection", reason: { $: "ProtocolError" } }
]
for (const action of actions) {
  const text = Connection.encode_action(action)
  assert.deepEqual(decodeControlFrame(textEncoder.encode(text), Connection.decode), Connection.decode(text))
  assert.equal(Connection.decode(text).$, "Some")
}
const plainJson = textEncoder.encode('{"kind":"frame","tick":17}')
for (const bytes of [control, plainJson, textEncoder.encode("BSA1|9|17")])
  await assert.rejects(decodeSnapshot(bytes), /magic/i)
assert.equal(decodeControlFrame(sceneEncoded, Connection.decode).$, "None")
assert.equal(decodeControlFrame(plainJson, Connection.decode).$, "None")
assert.throws(() => decodeControlFrame(textEncoder.encode("BSC-HS1|S|01"), Connection.decode), /invalid/i)
assert.throws(() => decodeControlFrame(textEncoder.encode("BSC-HS1|" + "0".repeat(160)), Connection.decode), /large/i)
checks += 16
await assert.rejects(encodeSnapshot(null), TypeError)
await assert.rejects(decodeSnapshot(new ArrayBuffer(2)), TypeError)
checks += 2
const wrongVersion = sceneEncoded.slice()
wrongVersion[3] = 0x32
await assert.rejects(decodeSnapshot(wrongVersion), /version/i)
checks++
const wrongMagic = sceneEncoded.slice()
wrongMagic[0] = defined(wrongMagic[0]) ^ 0x01
await assert.rejects(decodeSnapshot(wrongMagic), /magic/i)
checks++
await assert.rejects(decodeSnapshot(Uint8Array.of(0x42, 0x53, 0x5a)), /truncated/i)
checks++
await assert.rejects(
  decodeSnapshot(sceneEncoded.subarray(0, sceneEncoded.byteLength - 1)),
  /invalid|truncated|exceeds/i
)
checks++
const wrongCrc = sceneEncoded.slice()
wrongCrc[wrongCrc.byteLength - 8] = defined(wrongCrc[wrongCrc.byteLength - 8]) ^ 0x80
await assert.rejects(decodeSnapshot(wrongCrc), /invalid|crc/i)
checks++
const wrongISize = sceneEncoded.slice()
wrongISize[wrongISize.byteLength - 4] = defined(wrongISize[wrongISize.byteLength - 4]) ^ 0x01
await assert.rejects(decodeSnapshot(wrongISize), /invalid|isize/i)
checks++
await assert.rejects(encodeSnapshot(textEncoder.encode("x".repeat(MAX_SNAPSHOT_RAW_BYTES + 1))), RangeError)
checks++
const oversizedFrame = new Uint8Array(MAX_SNAPSHOT_COMPRESSED_BYTES + 1)
oversizedFrame.set(MAGIC)
await assert.rejects(decodeSnapshot(oversizedFrame), RangeError)
checks++
// The gzip trailer declares an over-limit output; the decoder must reject it
// before collecting decompressed bytes. The reader also enforces the cap if a
// hostile stream lies about ISIZE.
const bombRaw = new Uint8Array(MAX_SNAPSHOT_RAW_BYTES + 1)
const bombFrame = concatenate(MAGIC, await gzip(bombRaw))
check(
  bombFrame.byteLength < MAX_SNAPSHOT_COMPRESSED_BYTES,
  "over-limit gzip fixture stays compressed under the wire cap"
)
await assert.rejects(decodeSnapshot(bombFrame), RangeError)
checks++
const lyingRaw = new Uint8Array(MAX_SNAPSHOT_RAW_BYTES + 1)
const lyingFrame = concatenate(MAGIC, await gzip(lyingRaw))
lyingFrame.fill(0, lyingFrame.byteLength - 4)
lyingFrame[lyingFrame.byteLength - 4] = 1
await assert.rejects(decodeSnapshot(lyingFrame), /invalid|isize|crc|exceeds/i)
checks++
const queuedFrames = await Promise.all([1, 2, 3].map((value) => encodeSnapshot(textEncoder.encode(`queue-${value}`))))
const orderedStarts: Uint8Array[] = []
const orderedGates: ReturnType<typeof deferred>[] = []
const ordered = new SnapshotDecoder({
  decode: (bytes) =>
    new Promise((resolve) => {
      const index = orderedStarts.length
      orderedStarts.push(bytes)
      const gate = deferred()
      orderedGates.push(gate)
      void gate.promise.then(() => resolve(Uint8Array.of(index)))
    })
})
const orderedJobs = queuedFrames.map((frame) => ordered.decode(frame))
check(orderedStarts.length === 1, "only the active compressed decode starts")
assert.equal(decodeControlFrame(control, Connection.decode).$, "Some")
await assert.rejects(ordered.decode(control), /magic/i)
check(orderedStarts.length === 1, "plain control does not activate or occupy a compressed job")
for (let index = 0; index < orderedJobs.length; index++) {
  check(orderedStarts.length === index + 1, "compressed jobs start in FIFO order without overlap")
  defined(orderedGates[index]).resolve()
  equalBytes(await orderedJobs[index], Uint8Array.of(index), `queued decode result ${index}`)
  if (index + 1 < orderedJobs.length)
    await until(() => orderedStarts.length === index + 2, "next queued decode did not start")
}
ordered.close()
check(
  MAX_SNAPSHOT_DECODE_JOBS === 16 && MAX_SNAPSHOT_DECODE_QUEUE_BYTES === 16 * 1024 * 1024,
  "per-connection decoder bounds are sixteen total jobs and sixteen MiB"
)
const overflowResolvers: ((bytes: Uint8Array) => void)[] = []
const overflowCalls: Uint8Array[] = []
const blocked = new SnapshotDecoder({
  decode: (bytes) =>
    new Promise<Uint8Array>((resolve) => {
      overflowCalls.push(bytes)
      overflowResolvers.push(resolve)
    })
})
const fullSizeFrame = new Uint8Array(MAX_SNAPSHOT_COMPRESSED_BYTES)
fullSizeFrame.set(MAGIC)
const overflowJobs = Array.from({ length: MAX_SNAPSHOT_DECODE_JOBS }, () => blocked.decode(fullSizeFrame))
check(
  overflowJobs.length === 16 && overflowJobs.length * fullSizeFrame.byteLength === MAX_SNAPSHOT_DECODE_QUEUE_BYTES,
  "sixteen accepted one-MiB frames fill the exact sixteen-MiB active-plus-queued budget"
)
check(overflowCalls.length === 1, "one compressed job is active while fifteen wait")
await assert.rejects(blocked.decode(fullSizeFrame), /queue is full/i)
checks++
assert.equal(decodeControlFrame(control, Connection.decode).$, "Some")
await assert.rejects(blocked.decode(control), /magic/i)
for (let index = 0; index < overflowJobs.length; index++) {
  defined(overflowResolvers[index])(Uint8Array.of(index))
  equalBytes(await overflowJobs[index], Uint8Array.of(index), `bounded queue completion ${index}`)
  if (index + 1 < overflowJobs.length)
    await until(() => overflowCalls.length === index + 2, "bounded queue did not advance")
}
blocked.close()
const closeResolvers: ((bytes: Uint8Array) => void)[] = []
let closeDecodeCalls = 0
const oldConnection = new SnapshotDecoder({
  decode: () =>
    new Promise<Uint8Array>((resolve) => {
      closeDecodeCalls++
      closeResolvers.push(resolve)
    })
})
const activeOld = oldConnection.decode(queuedFrames[0])
const queuedOld1 = oldConnection.decode(queuedFrames[1]).then(
  () => null,
  (error: unknown) => error
)
const queuedOld2 = oldConnection.decode(queuedFrames[2]).then(
  () => null,
  (error: unknown) => error
)
const activeOldResult = activeOld.then(
  (value) => value,
  (error: unknown) => error
)
oldConnection.close()
check(
  (await queuedOld1) instanceof Error && (await queuedOld2) instanceof Error,
  "connection close cancels queued jobs"
)
check(closeDecodeCalls === 1, "close prevents queued jobs from activating")
const newConnection = new SnapshotDecoder({ decode: async () => Uint8Array.of(9) })
equalBytes(
  await newConnection.decode(queuedFrames[0]),
  Uint8Array.of(9),
  "a new connection decodes independently of the closed connection"
)
defined(closeResolvers[0])(Uint8Array.of(7))
equalBytes(await activeOldResult, Uint8Array.of(7), "active bounded decode is allowed to finish after close")
await assert.rejects(oldConnection.decode(control), /closed/i)
checks++
check(closeDecodeCalls === 1, "old queued work does not resume after the active job finishes")
newConnection.close()
console.log(
  JSON.stringify({
    status: "PASS",
    checks,
    sceneBytes: sceneBytes.byteLength,
    encodedSceneBytes: sceneEncoded.byteLength,
    compressionRatio: Number((sceneEncoded.byteLength / sceneBytes.byteLength).toFixed(3)),
    generatedUtf8Cases: 40,
    decoderQueueJobs: MAX_SNAPSHOT_DECODE_JOBS,
    decoderQueueBytes: MAX_SNAPSHOT_DECODE_QUEUE_BYTES,
    decoderQueueAcceptedAtLimit: overflowJobs.length,
    scope: "browser-compatible byte codec, CRC/ISIZE validation, bounded per-connection decode ordering"
  })
)
