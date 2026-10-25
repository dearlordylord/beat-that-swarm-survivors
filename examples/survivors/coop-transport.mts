export type NativeEvent =
  | { type: "connected" | "disconnected"; peerId: string }
  | { type: "message"; peerId: string; bytes: Uint8Array }
  | { type: "error"; message: string }
  | { type: "closed" }
export interface NativeTransport {
  endpointId(): string
  invitation(): string
  join(ticket: string): Promise<unknown>
  send(bytes: Uint8Array, confirmDelivery: boolean): Promise<unknown>
  disconnectPeer(): void
  close(): void
}
export type NativeCallback = (event: NativeEvent) => void
export type TransportFactory = (callback: NativeCallback) => Promise<NativeTransport>
interface NativeFactory {
  create: TransportFactory
}
export interface TransportState {
  endpoint: string
  peer: string
  connected: boolean
  closed: boolean
  connectionEpoch: number
  pendingSends: number
  pendingBytes: number
}
export type TransportEvent = NativeEvent & { connectionEpoch: number; state: TransportState }
export type TransportCallback = (event: TransportEvent) => void
interface TransportOptions {
  moduleUrl?: string
  transportFactory?: TransportFactory
}
// IO only: authenticated Iroh bytes. Bend owns message parsing and game admission.
export const MAX_FRAME_BYTES = 1024 * 1024
export const MAX_PENDING_MESSAGES = 16
export const MAX_PENDING_BYTES = 4 * MAX_FRAME_BYTES
const initialized = new Map<string, Promise<NativeFactory>>()
async function defaultFactory(callback: NativeCallback, moduleUrl: string) {
  let loading = initialized.get(moduleUrl)
  if (!loading) {
    loading = import(moduleUrl).then(async (module) => {
      await module.default()
      return module.Transport
    })
    initialized.set(moduleUrl, loading)
    loading.catch(() => {
      if (initialized.get(moduleUrl) === loading) initialized.delete(moduleUrl)
    })
  }
  return (await loading).create(callback)
}
export class CoopTransport {
  #transport!: NativeTransport
  #callback: TransportCallback
  #queue: Promise<unknown> = Promise.resolve()
  #epoch = 0
  #closed = false
  #connected = false
  #peer = ""
  #pending = 0
  #pendingBytes = 0
  static async create(
    callback: TransportCallback,
    {
      moduleUrl = new URL("./iroh/iroh_transport.js", import.meta.url).href,
      transportFactory = (event) => defaultFactory(event, moduleUrl)
    }: TransportOptions = {}
  ) {
    const channel = new CoopTransport(callback)
    channel.#transport = await transportFactory((event) => channel.#event(event))
    return channel
  }
  constructor(callback: TransportCallback) {
    this.#callback = callback
  }
  endpointId() {
    return this.#transport?.endpointId() || ""
  }
  invitation() {
    return this.#transport.invitation()
  }
  join(ticket: string) {
    if (this.#closed) return Promise.reject(Error("Transport is closed."))
    return this.#transport.join(ticket)
  }
  snapshot(): TransportState {
    return {
      endpoint: this.endpointId(),
      peer: this.#peer,
      connected: this.#connected,
      closed: this.#closed,
      connectionEpoch: this.#epoch,
      pendingSends: this.#pending,
      pendingBytes: this.#pendingBytes
    }
  }
  #emit(event: NativeEvent) {
    this.#callback({ ...event, connectionEpoch: this.#epoch, state: this.snapshot() })
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
    if (!this.#closed) this.#transport?.disconnectPeer()
  }
  close() {
    if (this.#closed) return
    this.#closed = true
    this.#connected = false
    this.#peer = ""
    this.#reset()
    this.#transport?.close()
    this.#emit({ type: "closed" })
  }
}
