type NativeEvent =
  | { type: "connected" | "disconnected" | "ready" | "connecting"; peerId: string }
  | { type: "message"; peerId: string; bytes: Uint8Array }
  | { type: "error"; message: string }
  | { type: "closed" }
interface NativeTransport {
  endpointId(): string
  invitation(): string
  join(ticket: string): Promise<unknown>
  send(bytes: Uint8Array, confirmDelivery: boolean): Promise<unknown>
  disconnectPeer(): void
  close(): void
}
type NativeCallback = (event: NativeEvent) => void
interface NativeFactory {
  create: (callback: NativeCallback) => Promise<NativeTransport>
}
interface TransportState {
  endpoint: string
  peer: string
  connected: boolean
  closed: boolean
  connectionEpoch: number
  pendingSends: number
  pendingBytes: number
}
export type TransportEvent = NativeEvent & { connectionEpoch: number; state: TransportState }
type TransportCallback = (event: TransportEvent) => void
// IO only: authenticated Iroh bytes. Bend owns message parsing and game admission.
const MAX_FRAME_BYTES = 1024 * 1024
const MAX_PENDING_MESSAGES = 16
const MAX_PENDING_BYTES = 4 * MAX_FRAME_BYTES
let initialized: Promise<NativeFactory> | undefined
function parseNativeEvent(value: unknown): NativeEvent {
  if (typeof value !== "object" || value === null || !("type" in value))
    throw TypeError("Invalid native transport event.")
  switch (value.type) {
    case "connected":
    case "disconnected":
    case "ready":
    case "connecting":
      if ("peerId" in value && typeof value.peerId === "string") return { type: value.type, peerId: value.peerId }
      break
    case "message":
      if (
        "peerId" in value &&
        typeof value.peerId === "string" &&
        "bytes" in value &&
        value.bytes instanceof Uint8Array
      )
        return { type: "message", peerId: value.peerId, bytes: value.bytes }
      break
    case "error":
      if ("message" in value && typeof value.message === "string") return { type: "error", message: value.message }
      break
    case "closed":
      return { type: "closed" }
  }
  throw TypeError("Invalid native transport event.")
}
function nativeMethod(owner: object, name: string): (...args: unknown[]) => unknown {
  const method: unknown = Reflect.get(owner, name)
  if (typeof method !== "function") throw TypeError(`Missing native transport method: ${name}.`)
  return (...args) => {
    const result: unknown = Reflect.apply(method, owner, args)
    return result
  }
}
function parseNativeTransport(value: unknown): NativeTransport {
  if (typeof value !== "object" || value === null) throw TypeError("Invalid native transport.")
  const endpointId = nativeMethod(value, "endpointId"),
    invitation = nativeMethod(value, "invitation"),
    join = nativeMethod(value, "join"),
    send = nativeMethod(value, "send"),
    disconnectPeer = nativeMethod(value, "disconnectPeer"),
    close = nativeMethod(value, "close")
  function text(result: unknown): string {
    if (typeof result !== "string") throw TypeError("Invalid native transport text.")
    return result
  }
  return {
    endpointId: () => text(endpointId()),
    invitation: () => text(invitation()),
    join: async (ticket) => join(ticket),
    send: async (bytes, confirmDelivery) => send(bytes, confirmDelivery),
    disconnectPeer: () => {
      disconnectPeer()
    },
    close: () => {
      close()
    }
  }
}
async function defaultFactory(callback: NativeCallback) {
  let loading = initialized
  if (!loading) {
    const moduleUrl = new URL("./iroh/iroh_transport.js", import.meta.url).href
    loading = import(moduleUrl).then(async (value: unknown): Promise<NativeFactory> => {
      if (typeof value !== "object" || value === null || !("default" in value) || !("Transport" in value))
        throw TypeError("Invalid native transport module.")
      await nativeMethod(value, "default")()
      const transport = value.Transport
      if (typeof transport !== "function" && (typeof transport !== "object" || transport === null))
        throw TypeError("Invalid native transport factory.")
      const create = nativeMethod(transport, "create")
      return {
        create: async (event) => parseNativeTransport(await create((raw: unknown) => event(parseNativeEvent(raw))))
      }
    })
    initialized = loading
    void loading.catch(() => {
      if (initialized === loading) initialized = undefined
    })
  }
  return (await loading).create(callback)
}
export class CoopTransport {
  #transport: NativeTransport
  #callback: TransportCallback
  #queue: Promise<unknown> = Promise.resolve()
  #epoch = 0
  #closed = false
  #connected = false
  #peer = ""
  #pending = 0
  #pendingBytes = 0
  static async create(callback: TransportCallback) {
    const pendingEvents: NativeEvent[] = []
    let deliver: NativeCallback = (event) => {
      pendingEvents.push(event)
    }
    const transport = await defaultFactory((event) => deliver(event))
    const channel = new CoopTransport(transport, callback)
    deliver = (event) => channel.#event(event)
    for (const event of pendingEvents) channel.#event(event)
    return channel
  }
  private constructor(transport: NativeTransport, callback: TransportCallback) {
    this.#transport = transport
    this.#callback = callback
  }
  invitation() {
    return this.#transport.invitation()
  }
  join(ticket: string) {
    if (this.#closed) return Promise.reject(Error("Transport is closed."))
    return this.#transport.join(ticket)
  }
  #snapshot(): TransportState {
    return {
      endpoint: this.#transport.endpointId(),
      peer: this.#peer,
      connected: this.#connected,
      closed: this.#closed,
      connectionEpoch: this.#epoch,
      pendingSends: this.#pending,
      pendingBytes: this.#pendingBytes
    }
  }
  #emit(event: NativeEvent) {
    this.#callback({ ...event, connectionEpoch: this.#epoch, state: this.#snapshot() })
  }
  #reset() {
    this.#epoch++
    this.#pending = 0
    this.#pendingBytes = 0
    this.#queue = Promise.resolve()
  }
  #event(event: NativeEvent) {
    if (this.#closed) return
    if (event.type === "connected") {
      this.#reset()
      this.#connected = true
      this.#peer = event.peerId
    }
    if (event.type === "disconnected") {
      this.#reset()
      this.#connected = false
      this.#peer = ""
    }
    if (event.type === "message") {
      if (!this.#connected || event.peerId !== this.#peer) return
      if (!(event.bytes instanceof Uint8Array) || event.bytes.byteLength > MAX_FRAME_BYTES) {
        this.#emit({ type: "error", message: "Invalid transport frame." })
        return
      }
      this.#emit({ ...event, bytes: event.bytes.slice() })
    } else this.#emit(event)
  }
  send(payload: unknown, { confirmDelivery = false }: { confirmDelivery?: boolean } = {}) {
    if (this.#closed || !this.#connected) return Promise.reject(Error("No peer is connected."))
    if (typeof payload === "string") payload = new TextEncoder().encode(payload)
    if (!(payload instanceof Uint8Array)) return Promise.reject(TypeError("Expected bytes or UTF-8 text."))
    if (payload.byteLength > MAX_FRAME_BYTES) return Promise.reject(Error("Transport frame exceeds 1 MiB."))
    if (this.#pending >= MAX_PENDING_MESSAGES || this.#pendingBytes + payload.byteLength > MAX_PENDING_BYTES)
      return Promise.reject(Error("Transport send queue is full."))
    const bytes = payload.slice(),
      epoch = this.#epoch,
      peer = this.#peer
    this.#pending++
    this.#pendingBytes += bytes.byteLength
    const operation = this.#queue
      .then(async () => {
        if (this.#closed || !this.#connected || epoch !== this.#epoch) throw Error("Connection changed before sending.")
        await this.#transport.send(bytes, confirmDelivery)
        if (this.#closed || epoch !== this.#epoch) throw Error("Connection changed while sending.")
        return { peerId: peer, connectionEpoch: epoch, byteLength: bytes.byteLength }
      })
      .finally(() => {
        if (epoch === this.#epoch) {
          this.#pending--
          this.#pendingBytes -= bytes.byteLength
        }
      })
    this.#queue = operation.catch(() => {})
    return operation
  }
  disconnectPeer() {
    if (!this.#closed) this.#transport.disconnectPeer()
  }
  close() {
    if (this.#closed) return
    this.#closed = true
    this.#connected = false
    this.#peer = ""
    this.#reset()
    this.#transport.close()
    this.#emit({ type: "closed" })
  }
}
