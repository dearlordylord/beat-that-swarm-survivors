// Browser scheduling and message IO only. Bend owns admission and the shared world.
import Game from './dist/coop-core.mjs';
import Session from './dist/coop-session.mjs';
import Protocol from './dist/coop-protocol.mjs';
import InputQueue from './dist/coop-input-queue.mjs';
let core, session, timer, last = 0, accumulator = 0, active = false;
let lastSnapshot = 0, observationSeq = 0, lastPhase;
let guestReceipt = Session.receipt_fresh(), guestQueue = InputQueue.fresh(0,0);
let currentRound = 0, currentPhase = 0, currentWorldTick = 0, guestEligible = false;
let lastInputRejection = null, connectionEpoch = 0, awaitingSetup = false;
const STEP = 1000 / 60;
function packet(result) {
  if (result.state) core = result.state;
  if (result.$ === 'CoreFailed') throw Error(result.message);
  if (result.$ === 'CoreRejected') { postMessage({type:'rejected',message:result.message}); return null; }
  const frame = result.frame ? JSON.parse(result.frame) : null;
  if (Number.isInteger(frame?.tick)) currentWorldTick = frame.tick;
  return frame;
}
function publish(remote = true) {
  const observation = ++observationSeq;
  const local = packet(Game.core_observe(core, 0));
  currentPhase = local.phase ?? currentPhase;
  const round = local.roundId ?? currentRound;
  if (round !== currentRound || currentPhase !== 0) guestQueue = InputQueue.fresh(round,currentWorldTick);
  currentRound = round;
  postMessage({type:'frame', frame:local});
  if (remote) {
    const guest = packet(Game.core_observe(core, 1));
    guestEligible = guest.predictionAllowed === true;
    if (!guestEligible) guestQueue = InputQueue.fresh(currentRound,currentWorldTick);
    postMessage({type:'remote-frame', frame:guest, admission:session, receipt:guestReceipt, observationSeq:observation,connectionEpoch,inputTiming:{worldTick:currentWorldTick,lastRejected:lastInputRejection}});
  }
}
function accept(text, peer) {
  const decoded = Protocol.decode(text);
  if (decoded.$ !== 'Some') return;
  const command = decoded.value;
  if (peer === 1 && awaitingSetup && command.action.$ !== 'Setup') return;
  const admission = Session.receive(session, peer, command);
  session = admission.state;
  if (!admission.accepted) return;
  const action = command.action;
  if (action.$ === 'Movement' && peer === 1) {
    postMessage({type:'guest-protocol-mismatch',connectionEpoch}); return;
  } else if (action.$ === 'MovementTick' && peer === 1) {
    const admission = InputQueue.push_active(guestQueue,currentPhase,guestEligible,action.round,command.seq,command.intendedTick,action.x,action.y);
    if (!admission.accepted) {
      lastInputRejection = {reason:admission.reason,seq:command.seq,targetWorldTick:command.intendedTick,worldTick:currentWorldTick};
      postMessage({type:'input-rejected',...lastInputRejection});
    }
    if (admission.reason === 8) {
      session = Session.disconnect(1,session);
      packet(Game.core_disconnect(core,1)); guestQueue = InputQueue.fresh(currentRound,currentWorldTick);
      postMessage({type:'guest-input-overflow',connectionEpoch}); publish(false); return;
    }
    guestQueue = admission.state;
  } else if (action.$ === 'Choice') {
    packet(Game.core_choose(core, peer, action.round, action.index));
    publish();
  } else if (action.$ === 'Setup' && peer === 1 && awaitingSetup) {
    const joined = Game.core_attach(core, action.character, action.meta, action.arcana, action.allowedWeapons);
    packet(joined);
    if (joined.$ !== 'CorePacket') return;
    awaitingSetup = false;
    active = true;
    last = performance.now(); accumulator = 0;
    postMessage({type:'started',connectionEpoch});
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
    const pending = InputQueue.take_at(guestQueue,currentWorldTick+1);
    const input = pending.tick.$ === 'Some' ? pending.tick.value : null;
    const frame = packet(Game.core_step(core,move.x0,move.y0,
      input ? Session.axis(input.x) : 0,input ? Session.axis(input.y) : 0));
    if (frame?.advanced) {
      if (pending.state.worldTick !== frame.tick) throw Error('Input clock disagreed with the authoritative game step.');
      guestQueue = pending.state;
      guestReceipt = InputQueue.receipt(frame.tick,pending.tick);
      session = Session.applied(frame.tick, session);
    }
    if (frame && frame.phase !== lastPhase) { lastPhase = frame.phase; lastSnapshot = now; publish(); }
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
        observationSeq = 0; lastPhase = undefined; guestReceipt = Session.receipt_fresh();
        currentRound = 0; currentPhase = 0; currentWorldTick = 0; guestEligible = false; guestQueue = InputQueue.fresh(0,0); lastInputRejection = null;
        const s = message.setup;
        connectionEpoch = 0; awaitingSetup = false;
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
      case 'connected':
        connectionEpoch = message.connectionEpoch;
        active = false; accumulator = 0; awaitingSetup = true;
        session = Session.reconnect(session);
        guestQueue = InputQueue.fresh(currentRound,currentWorldTick);
        guestReceipt = Session.receipt_fresh(); lastInputRejection = null;
        break;
      case 'command':
        if (message.player === 0 || message.connectionEpoch === connectionEpoch) accept(message.text, message.player);
        break;
      case 'disconnect':
        connectionEpoch = message.connectionEpoch ?? connectionEpoch;
        active = false; accumulator = 0; awaitingSetup = false;
        guestQueue = InputQueue.fresh(currentRound,currentWorldTick); guestEligible = false;
        session = Session.disconnect(1, session);
        // Connection loss is suspension, not player death or reward forfeiture.
        publish(false); break;
      case 'stop': clearInterval(timer); active = false; close(); break;
    }
  } catch (error) { clearInterval(timer); active = false; postMessage({type:'error', message:error.message, stack:error.stack}); }
  finally {
    if (event.data.type === 'command') postMessage({type:'command-consumed',deliveryId:event.data.deliveryId});
  }
};
