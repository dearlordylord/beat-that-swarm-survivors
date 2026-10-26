import { at } from "./host-values.mts"
// Generic bounded snapshot bytes. This module does not inspect game fields.
export const MAX_SNAPSHOT_RAW_BYTES = 1024 * 1024
export const MAX_SNAPSHOT_COMPRESSED_BYTES = 1024 * 1024
export const MAX_SNAPSHOT_DECODE_JOBS = 16
export const MAX_SNAPSHOT_DECODE_QUEUE_BYTES = 16 * 1024 * 1024

const HEADER = Uint8Array.of(0x42, 0x53, 0x5a, 0x31) // BSZ1
const HEADER_BYTES = HEADER.byteLength
const GZIP_SIGNATURE = [0x1f, 0x8b]
const INPUT_CHUNK_BYTES = 1024

const CRC32_TABLE = (() => {
  const table = new Uint32Array(256)
  for (let index = 0; index < table.length; index++) {
    let value = index
    for (let bit = 0; bit < 8; bit++) value = value & 1 ? 0xedb88320 ^ (value >>> 1) : value >>> 1
    table[index] = value >>> 0
  }
  return table
})()

function isBytes(value: unknown): value is Uint8Array {
  return value instanceof Uint8Array
}

function streamBytes(bytes: Uint8Array) {
  let offset = 0
  return new ReadableStream<Uint8Array<ArrayBuffer>>({
    pull(controller) {
      if (offset >= bytes.byteLength) {
        controller.close()
        return
      }
      const end = Math.min(offset + INPUT_CHUNK_BYTES, bytes.byteLength)
      controller.enqueue(Uint8Array.from(bytes.subarray(offset, end)))
      offset = end
    }
  })
}

async function collectBounded(stream: ReadableStream<unknown>, limit: number, label: string) {
  const reader = stream.getReader()
  const chunks = []
  let size = 0
  try {
    for (;;) {
      const { done, value } = await reader.read()
      if (done) break
      if (!isBytes(value)) throw new TypeError(`${label} stream produced non-byte data.`)
      if (value.byteLength > limit - size) throw new RangeError(`${label} exceeds ${limit} bytes.`)
      size += value.byteLength
      chunks.push(value)
    }
  } catch (error) {
    try {
      await reader.cancel(error)
    } catch {}
    throw error
  } finally {
    try {
      reader.releaseLock()
    } catch {}
  }

  const output = new Uint8Array(size)
  let offset = 0
  for (const chunk of chunks) {
    output.set(chunk, offset)
    offset += chunk.byteLength
  }
  return output
}

function startsWithReservedMagic(bytes: Uint8Array) {
  return bytes.byteLength >= 3 && bytes[0] === HEADER[0] && bytes[1] === HEADER[1] && bytes[2] === HEADER[2]
}

function hasGzipAt(bytes: Uint8Array, offset: number) {
  return (
    bytes.byteLength >= offset + 2 &&
    at(bytes, offset) === GZIP_SIGNATURE[0] &&
    at(bytes, offset + 1) === GZIP_SIGNATURE[1]
  )
}

function assertSnapshotHeader(bytes: Uint8Array) {
  if (!startsWithReservedMagic(bytes)) throw new TypeError("Compressed snapshot has an invalid BSZ1 magic header.")
  if (bytes.byteLength < HEADER_BYTES) throw new TypeError("Compressed snapshot header is truncated.")
  if (bytes[3] !== HEADER[3]) throw new TypeError("Compressed snapshot version is unsupported.")
}

function readU32LE(bytes: Uint8Array, offset: number) {
  return (
    (at(bytes, offset) |
      (at(bytes, offset + 1) << 8) |
      (at(bytes, offset + 2) << 16) |
      (at(bytes, offset + 3) << 24)) >>>
    0
  )
}

function crc32(bytes: Uint8Array) {
  let value = 0xffffffff
  for (let index = 0; index < bytes.byteLength; index++)
    value = at(CRC32_TABLE, (value ^ at(bytes, index)) & 0xff) ^ (value >>> 8)
  return (value ^ 0xffffffff) >>> 0
}

function gzipMetadata(bytes: Uint8Array) {
  if (bytes.byteLength < 18) throw new TypeError("Compressed snapshot is truncated.")
  if (!hasGzipAt(bytes, 0) || bytes[2] !== 8 || (at(bytes, 3) & 0xe0) !== 0)
    throw new TypeError("Compressed snapshot has an invalid gzip header.")

  const trailer = bytes.byteLength - 8
  return { crc: readU32LE(bytes, trailer), rawBytes: readU32LE(bytes, trailer + 4) }
}

function assertRawLimit(size: number) {
  if (size > MAX_SNAPSHOT_RAW_BYTES) throw new RangeError(`Snapshot exceeds ${MAX_SNAPSHOT_RAW_BYTES} raw bytes.`)
}

function assertCompressedLimit(size: number) {
  if (size > MAX_SNAPSHOT_COMPRESSED_BYTES)
    throw new RangeError(`Snapshot exceeds ${MAX_SNAPSHOT_COMPRESSED_BYTES} compressed bytes.`)
}

export async function encodeSnapshot(raw: unknown) {
  if (!isBytes(raw)) throw new TypeError("Snapshot input must be a Uint8Array.")
  assertRawLimit(raw.byteLength)

  const Compression = globalThis.CompressionStream
  if (typeof Compression !== "function") throw new Error("CompressionStream is unavailable.")
  const compressed = await collectBounded(
    streamBytes(raw).pipeThrough(new Compression("gzip")),
    MAX_SNAPSHOT_COMPRESSED_BYTES - HEADER_BYTES,
    "Compressed snapshot"
  )
  const output = new Uint8Array(HEADER_BYTES + compressed.byteLength)
  output.set(HEADER, 0)
  output.set(compressed, HEADER_BYTES)
  assertCompressedLimit(output.byteLength)
  return output
}

export async function decodeSnapshot(bytes: unknown) {
  if (!isBytes(bytes)) throw new TypeError("Snapshot input must be a Uint8Array.")
  assertCompressedLimit(bytes.byteLength)

  assertSnapshotHeader(bytes)

  const gzip = Uint8Array.from(bytes.subarray(HEADER_BYTES))
  const metadata = gzipMetadata(gzip)
  if (metadata.rawBytes > MAX_SNAPSHOT_RAW_BYTES)
    throw new RangeError(`Snapshot exceeds ${MAX_SNAPSHOT_RAW_BYTES} raw bytes.`)

  const Decompression = globalThis.DecompressionStream
  if (typeof Decompression !== "function") throw new Error("DecompressionStream is unavailable.")

  let raw
  try {
    raw = await collectBounded(
      streamBytes(gzip).pipeThrough(new Decompression("gzip")),
      MAX_SNAPSHOT_RAW_BYTES,
      "Decoded snapshot"
    )
  } catch (error) {
    if (error instanceof RangeError) throw error
    throw new TypeError("Compressed snapshot is invalid or truncated.")
  }

  if (raw.byteLength !== metadata.rawBytes) throw new TypeError("Compressed snapshot ISIZE does not match its output.")
  if (crc32(raw) !== metadata.crc) throw new TypeError("Compressed snapshot CRC does not match its output.")
  return raw
}

interface DecodeJob {
  bytes: Uint8Array
  resolve: (bytes: Uint8Array) => void
  reject: (error: unknown) => void
}
type Decode = (bytes: Uint8Array) => Promise<unknown>
export class SnapshotDecoder {
  #decode: Decode
  #jobs: DecodeJob[] = []
  #active: DecodeJob | null = null
  #closed = false
  #accepted = 0
  #compressedBytes = 0

  constructor({ decode = decodeSnapshot }: { decode?: Decode } = {}) {
    if (typeof decode !== "function") throw new TypeError("Snapshot decoder must be a function.")
    this.#decode = decode
  }

  async decode(bytes: unknown): Promise<Uint8Array> {
    if (this.#closed) throw new Error("Snapshot decoder is closed.")
    if (!isBytes(bytes)) throw new TypeError("Snapshot input must be a Uint8Array.")
    assertCompressedLimit(bytes.byteLength)

    assertSnapshotHeader(bytes)

    const copy = Uint8Array.from(bytes)
    if (
      this.#accepted >= MAX_SNAPSHOT_DECODE_JOBS ||
      copy.byteLength > MAX_SNAPSHOT_DECODE_QUEUE_BYTES - this.#compressedBytes
    )
      throw new RangeError("Snapshot decode queue is full.")

    this.#accepted++
    this.#compressedBytes += copy.byteLength
    const result = new Promise<Uint8Array>((resolve, reject) => {
      this.#jobs.push({ bytes: copy, resolve, reject })
    })
    this.#pump()
    return result
  }

  close() {
    if (this.#closed) return
    this.#closed = true
    for (const job of this.#jobs) {
      this.#accepted--
      this.#compressedBytes -= job.bytes.byteLength
      job.reject(new Error("Snapshot decode was canceled because the connection closed."))
    }
    this.#jobs = []
  }

  #pump() {
    if (this.#closed || this.#active || this.#jobs.length === 0) return
    const job = this.#jobs.shift()
    if (!job) return
    this.#active = job
    void (async () => {
      try {
        const decoded = await this.#decode(job.bytes)
        if (!isBytes(decoded)) throw new TypeError("Snapshot decoder returned non-byte data.")
        assertRawLimit(decoded.byteLength)
        job.resolve(decoded)
      } catch (error) {
        job.reject(error)
      } finally {
        this.#accepted--
        this.#compressedBytes -= job.bytes.byteLength
        this.#active = null
        this.#pump()
      }
    })()
  }
}
