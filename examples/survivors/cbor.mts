import { decode, encode, Tokenizer } from "cborg"
import type { DecodeOptions } from "cborg"

export const MAX_CBOR_CONTAINER_LENGTH = 16384
export const MAX_CBOR_DEPTH = 32
export const MAX_CBOR_TOKENS = 262144
export const MAX_CBOR_STRING_BYTES = 4096
const utf8 = new TextDecoder("utf-8", { fatal: true })
const options: DecodeOptions = {
  allowIndefinite: false,
  allowUndefined: false,
  allowBigInt: false,
  allowInfinity: false,
  allowNaN: false,
  rejectDuplicateMapKeys: true,
  retainStringBytes: true
}

export function encodeCbor(value: unknown): Uint8Array {
  return encode(value)
}

export function decodeCbor(bytes: Uint8Array): unknown {
  const source = new Tokenizer(bytes, options)
  const remaining: number[] = []
  let tokens = 0
  return decode(bytes, {
    ...options,
    tokenizer: {
      done: () => source.done(),
      pos: () => source.pos(),
      next() {
        if (++tokens > MAX_CBOR_TOKENS) throw RangeError("CBOR token budget exhausted.")
        while (remaining.length && remaining[remaining.length - 1] === 0) remaining.pop()
        if (remaining.length > MAX_CBOR_DEPTH) throw RangeError("CBOR nesting depth exceeded.")
        const parent = remaining.length - 1
        if (parent >= 0) remaining[parent] = (remaining[parent] ?? 0) - 1
        const token = source.next()
        const kind = token.type.name
        if (kind === "array") {
          const length: unknown = token.value
          if (typeof length !== "number" || !Number.isInteger(length) || length > MAX_CBOR_CONTAINER_LENGTH)
            throw RangeError("CBOR container is too large.")
          remaining.push(length)
          if (remaining.length > MAX_CBOR_DEPTH) throw RangeError("CBOR nesting depth exceeded.")
        } else if (kind === "string") {
          if (!token.byteValue || token.byteValue.byteLength > MAX_CBOR_STRING_BYTES)
            throw RangeError("CBOR string is too large.")
          utf8.decode(token.byteValue)
        } else if (!["uint", "negint", "float", "false", "true", "null"].includes(kind)) {
          throw TypeError("Disallowed CBOR type.")
        }
        return token
      }
    }
  })
}
