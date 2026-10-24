// Browser scheduling and message IO only. Bend owns admission and the shared world.
import Game from './dist/coop-core.mjs';
import Session from './dist/coop-session.mjs';
import Protocol from './dist/coop-protocol.mjs';
let core, session, timer, last = 0, accumulator = 0, active = false;
let lastSnapshot = 0;
const STEP = 1000 / 60;
function packet(result) {
  if (result.state) core = result.state;
  if (result.$ === 'CoreFailed') throw Error(result.message);
  if (result.$ === 'CoreRejected') { postMessage({type:'rejected',message:result.message}); return null; }
  return result.frame ? JSON.parse(result.frame) : null;
}
function publish(remote = true) {
  const local = packet(Game.core_observe(core, 0));
  postMessage({type:'frame', frame:local});
  if (remote) {
    const guest = packet(Game.core_observe(core, 1));
    postMessage({type:'remote-frame', frame:guest, admission:session});
  }
}
function accept(text, peer) {
  const decoded = Protocol.decode(text);
  if (decoded.$ !== 'Some') return;
  const command = decoded.value;
  const admission = Session.receive(session, peer, command);
  session = admission.state;
  if (!admission.accepted) return;
  const action = command.action;
  if (action.$ === 'Choice') {
    packet(Game.core_choose(core, peer, action.round, action.index));
    publish();
  } else if (action.$ === 'Setup' && peer === 1) {
    const joined = Game.core_join(core, action.character, action.meta, action.arcana);
    packet(joined);
    if (joined.$ !== 'CorePacket') return;
    const configured = Game.core_configure_unlocks(core, 1, action.allowedWeapons);
    packet(configured);
    if (configured.$ !== 'CorePacket') return;
    active = true;
    last = performance.now(); accumulator = 0;
    postMessage({type:'started'});
    publish();
  }
}
function schedule() {
  const now = performance.now();
  // Discard suspend time; at most four fixed steps per scheduling turn.
  accumulator += Math.min(4 * STEP, Math.max(0, now - last)); last = now;
  let steps = 0;
  while (active && accumulator >= STEP && steps++ < 4) {
    session = Session.clock(session);
    const move = Session.directions(session);
    const frame = packet(Game.core_step(core, move.x0, move.y0, move.x1, move.y1));
    if (frame?.advanced) session = Session.applied(frame.tick, session);
    accumulator -= STEP;
  }
  if (active && now - lastSnapshot >= 50) { lastSnapshot = now; publish(); }
}
onmessage = event => {
  try {
    const message = event.data;
    switch (message.type) {
      case 'init': {
        clearInterval(timer); active = false; accumulator = 0;
        const s = message.setup;
        session = Session.fresh(message.session);
        packet(Game.core_start(s.character, s.meta, message.seed));
        packet(Game.core_configure(core, s.stage, s.mode, s.arcana));
        packet(Game.core_configure_unlocks(core, 0, s.allowedWeapons));
        last = performance.now();
        timer = setInterval(() => {
          try { schedule(); }
          catch (error) { clearInterval(timer); active = false; postMessage({type:'error',message:error.message,stack:error.stack}); }
        }, 4);
        postMessage({type:'ready'});
        break;
      }
      case 'command': accept(message.text, message.player); break;
      case 'disconnect':
        session = Session.disconnect(1, session);
        packet(Game.core_disconnect(core, 1)); publish(false); break;
      case 'stop': clearInterval(timer); active = false; close(); break;
    }
  } catch (error) { clearInterval(timer); active = false; postMessage({type:'error', message:error.message, stack:error.stack}); }
  finally {
    if (event.data.type === 'command') postMessage({type:'command-consumed',deliveryId:event.data.deliveryId});
  }
};
