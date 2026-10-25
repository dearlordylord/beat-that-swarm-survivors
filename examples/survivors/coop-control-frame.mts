const prefix = new TextEncoder().encode("BSC-HS1|")
const decoder = new TextDecoder("utf-8", { fatal: true })
const MAX_CONTROL_BYTES = 160
export function decodeControlFrame(
  bytes: Uint8Array,
  decode: (text: string) => BendMaybe<BendABI.CoopConnection.Signal>
): BendMaybe<BendABI.CoopConnection.Signal> {
  if (bytes.byteLength < prefix.byteLength || !prefix.every((value, index) => bytes[index] === value))
    return { $: "None" }
  if (bytes.byteLength > MAX_CONTROL_BYTES) throw new RangeError("Connection control is too large.")
  const control = decode(decoder.decode(bytes))
  if (control.$ !== "Some") throw new TypeError("Invalid connection control.")
  return control
}
