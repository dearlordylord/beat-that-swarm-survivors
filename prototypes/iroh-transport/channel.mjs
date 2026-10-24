// Reusable IO/lifecycle adapter. Bend owns the application protocol; Iroh owns bytes.
import init, { Transport } from './wasm/iroh_transport.js';
import { ProtocolSession } from './core-adapter.mjs';
let initialized;
export function initialize() { return initialized ||= init().catch(error => { initialized = undefined; throw error; }); }
export class BendIrohChannel {
  #protocol = new ProtocolSession();
  #transport; #callback; #queue = Promise.resolve(); #pending = 0;
  #epoch = 0; #closed = false; #connected = false; #peer = '';
  #encoder = new TextEncoder(); #decoder = new TextDecoder('utf-8', { fatal: true });
  constructor(callback) { this.#callback = callback; }
  static async create(callback) {
    await initialize();
    const channel = new BendIrohChannel(callback);
    channel.#transport = await Transport.create(event => channel.#event(event));
    return channel;
  }
  endpointId() { return this.#transport?.endpointId() || ''; }
  invitation() { return this.#transport.invitation(); }
  join(invitation) { return this.#transport.join(invitation); }
  snapshot() { return { endpoint: this.endpointId(), peer: this.#peer, connected: this.#connected,
    closed: this.#closed, connectionEpoch: this.#epoch, pendingSends: this.#pending, protocol: this.#protocol.snapshot() }; }
  #emit(event) { this.#callback({ ...event, state: this.snapshot() }); }
  #newEpoch() { this.#epoch++; this.#pending = 0; this.#queue = Promise.resolve(); this.#protocol.reset(); }
  #event(event) {
    if (this.#closed) return;
    if (event.type === 'connected') { this.#newEpoch(); this.#connected = true; this.#peer = event.peerId; }
    if (event.type === 'disconnected') { this.#newEpoch(); this.#connected = false; this.#peer = ''; }
    if (event.type === 'message') {
      try {
        const message = this.#protocol.receive(this.#decoder.decode(event.bytes));
        this.#emit({ type: message.accepted ? 'received' : 'rejected', ...message, peerId: event.peerId });
      } catch (error) { this.#emit({ type: 'error', message: 'Invalid UTF-8 transport payload: ' + error.message }); }
    } else this.#emit(event);
  }
  send(text) {
    if (this.#closed || !this.#connected) return Promise.reject(Error('No peer is connected.'));
    if (this.#pending >= 16) return Promise.reject(Error('Send queue is full. Wait for pending sends.'));
    const epoch = this.#epoch; this.#pending++;
    const operation = this.#queue.then(async () => {
      if (this.#closed || epoch !== this.#epoch || !this.#connected) throw Error('Connection changed before sending.');
      const message = this.#protocol.send(text);
      if (!message.accepted) { this.#emit({ type: 'rejected', ...message }); throw Error('Bend refused this message: ' + message.reason); }
      await this.#transport.send(this.#encoder.encode(message.wire));
      if (epoch !== this.#epoch || this.#closed) throw Error('Connection changed while sending.');
      this.#emit({ type: 'sent', seq: message.seq, text: message.text });
      return message;
    }).finally(() => { if (epoch === this.#epoch) this.#pending--; });
    this.#queue = operation.catch(() => {});
    return operation;
  }
  close() {
    if (this.#closed) return;
    this.#closed = true; this.#connected = false; this.#peer = ''; this.#newEpoch();
    this.#transport?.close(); this.#emit({ type: 'closed' });
  }
}
