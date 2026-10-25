// IO only: authenticated Iroh bytes. Bend owns message parsing and game admission.
export const MAX_FRAME_BYTES = 1024 * 1024;
export const MAX_PENDING_MESSAGES = 16;
export const MAX_PENDING_BYTES = 4 * MAX_FRAME_BYTES;
const initialized = new Map();
async function defaultFactory(callback, moduleUrl) {
  let loading = initialized.get(moduleUrl);
  if (!loading) {
    loading = import(moduleUrl).then(async module => { await module.default(); return module.Transport; });
    initialized.set(moduleUrl, loading);
    loading.catch(() => { if (initialized.get(moduleUrl) === loading) initialized.delete(moduleUrl); });
  }
  return (await loading).create(callback);
}
export class CoopTransport {
  #transport; #callback; #queue = Promise.resolve();
  #epoch = 0; #closed = false; #connected = false; #peer = '';
  #pending = 0; #pendingBytes = 0;
  static async create(callback, { moduleUrl = new URL('./iroh/iroh_transport.js', import.meta.url).href,
    transportFactory = event => defaultFactory(event, moduleUrl) } = {}) {
    const channel = new CoopTransport(callback);
    channel.#transport = await transportFactory(event => channel.#event(event));
    return channel;
  }
  constructor(callback) { this.#callback = callback; }
  endpointId() { return this.#transport?.endpointId() || ''; }
  invitation() { return this.#transport.invitation(); }
  join(ticket) {
    if (this.#closed) return Promise.reject(Error('Transport is closed.'));
    return this.#transport.join(ticket);
  }
  snapshot() {
    return { endpoint: this.endpointId(), peer: this.#peer, connected: this.#connected,
      closed: this.#closed, connectionEpoch: this.#epoch,
      pendingSends: this.#pending, pendingBytes: this.#pendingBytes };
  }
  #emit(event) { this.#callback({ ...event, connectionEpoch: this.#epoch, state: this.snapshot() }); }
  #reset() { this.#epoch++; this.#pending = 0; this.#pendingBytes = 0; this.#queue = Promise.resolve(); }
  #event(event) {
    if (this.#closed) return;
    if (event.type === 'connected') {
      this.#reset(); this.#connected = true; this.#peer = event.peerId;
    }
    if (event.type === 'disconnected') {
      this.#reset(); this.#connected = false; this.#peer = '';
    }
    if (event.type === 'message') {
      if (!this.#connected || event.peerId !== this.#peer) return;
      if (!(event.bytes instanceof Uint8Array) || event.bytes.byteLength > MAX_FRAME_BYTES) {
        this.#emit({ type: 'error', message: 'Invalid transport frame.' }); return;
      }
      this.#emit({ ...event, bytes: event.bytes.slice() });
    } else this.#emit(event);
  }
  send(payload, { confirmDelivery = false } = {}) {
    if (this.#closed || !this.#connected) return Promise.reject(Error('No peer is connected.'));
    if (typeof payload === 'string') payload = new TextEncoder().encode(payload);
    if (!(payload instanceof Uint8Array)) return Promise.reject(TypeError('Expected bytes or UTF-8 text.'));
    if (payload.byteLength > MAX_FRAME_BYTES) return Promise.reject(Error('Transport frame exceeds 1 MiB.'));
    if (this.#pending >= MAX_PENDING_MESSAGES || this.#pendingBytes + payload.byteLength > MAX_PENDING_BYTES)
      return Promise.reject(Error('Transport send queue is full.'));
    const bytes = payload.slice(), epoch = this.#epoch, peer = this.#peer;
    this.#pending++; this.#pendingBytes += bytes.byteLength;
    const operation = this.#queue.then(async () => {
      if (this.#closed || !this.#connected || epoch !== this.#epoch) throw Error('Connection changed before sending.');
      await this.#transport.send(bytes,confirmDelivery);
      if (this.#closed || epoch !== this.#epoch) throw Error('Connection changed while sending.');
      return { peerId: peer, connectionEpoch: epoch, byteLength: bytes.byteLength };
    }).finally(() => {
      if (epoch === this.#epoch) { this.#pending--; this.#pendingBytes -= bytes.byteLength; }
    });
    this.#queue = operation.catch(() => {});
    return operation;
  }
  disconnectPeer() {
    if (!this.#closed) this.#transport?.disconnectPeer();
  }
  close() {
    if (this.#closed) return;
    this.#closed = true; this.#connected = false; this.#peer = ''; this.#reset();
    this.#transport?.close(); this.#emit({ type: 'closed' });
  }
}
