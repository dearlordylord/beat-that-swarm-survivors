// IO representation adapter only. Protocol admission and state transitions are Bend.
import Core from './dist/core.mjs';
export class ProtocolSession {
  #state;
  constructor() { this.reset(); }
  reset() { this.#state = Core.fresh(); return this.snapshot(); }
  snapshot() {
    const {nextSeq,lastRemoteSeq,sent,received,rejected} = this.#state;
    return {nextSeq,lastRemoteSeq,sent,received,rejected};
  }
  send(text) {
    if (typeof text !== 'string') throw new TypeError('Protocol text must be a string.');
    const result = Core.send(this.#state,text); this.#state = result.state;
    const {accepted,wire,seq,reason} = result;
    return {accepted,wire,seq,text:result.text,reason,state:this.snapshot()};
  }
  receive(wire) {
    if (typeof wire !== 'string') throw new TypeError('Protocol wire must be a string.');
    const result = Core.receive(this.#state,wire); this.#state = result.state;
    const {accepted,seq,text,reason} = result;
    return {accepted,seq,text,reason,state:this.snapshot()};
  }
}
