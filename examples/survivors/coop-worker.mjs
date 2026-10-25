// Browser scheduling and message IO only. Bend owns admission and the shared world.
import Game from './dist/coop-core.mjs';
import Encoder from './dist/coop-encoder.mjs';
import Session from './dist/coop-session.mjs';
import InputQueue from './dist/coop-input-queue.mjs';
import Connection from './dist/coop-connection.mjs';
import ClientDelivery from './dist/coop-client-delivery.mjs';
import HitJournal from './dist/coop-hit-journal.mjs';
let core, session, timer, last = 0, accumulator = 0;
let gate = Connection.fresh({$:'Host'});
let lastSnapshot = 0, observationSeq = 0, lastPhase;
let guestReceipt = Session.receipt_fresh(), guestQueue = InputQueue.fresh(0,0);
let currentRound = 0, currentPhase = 0, currentWorldTick = 0, guestEligible = false;
let lastInputRejection = null, connectionEpoch = 0;
let contactJournal = HitJournal.fresh(0);
const STEP = 1000 / 60;
function applyConnection(output) {
  gate = output.state;
  const action = output.action;
  if (action.$ === 'StartAndConfirm') {
    last = performance.now(); lastSnapshot = last; accumulator = 0;
  }
  if (!['Nothing','PrepareWorld','PublishInitial'].includes(action.$))
    postMessage({type:'handshake-action',state:gate,action,connectionEpoch});
  return action;
}
function handshake(signal, eventEpoch = Connection.epoch(gate)) {
  return applyConnection(Connection.step(gate,eventEpoch,signal));
}
function reject(reason, error) {
  if (error) postMessage({type:'error',message:error.message,stack:error.stack,connectionEpoch,
    context:{worldTick:currentWorldTick,queueWorldTick:guestQueue.worldTick,round:currentRound,phase:currentPhase}});
  handshake({$:'Reject',reason:{$:reason}});
  accumulator = 0; guestEligible = false;
}
function packet(result) {
  if (result.state) core = result.state;
  if (result.$ === 'CoreFailed') throw Error(result.message);
  if (result.$ === 'CoreRejected') { postMessage({type:'rejected',message:result.message,connectionEpoch}); return null; }
  const encoded = Encoder.encode(result.observation);
  const frame = encoded.$ === 'Some' ? JSON.parse(encoded.value) : null;
  if (Number.isInteger(frame?.tick)) currentWorldTick = frame.tick;
  return frame;
}
function publish(remote = true, initial = false) {
  const observation = ++observationSeq;
  const local = packet(Game.core_observe(core, 0));
  currentPhase = local.phase ?? currentPhase;
  const round = local.roundId ?? currentRound;
  if (round !== currentRound || currentPhase !== 0) guestQueue = InputQueue.fresh(round,currentWorldTick);
  currentRound = round;
  postMessage({type:'frame',frame:local,observationSeq:observation,contactJournal,connectionReady:Connection.running(gate)});
  if (remote) {
    const guest = packet(Game.core_observe(core, 1));
    guestEligible = guest.predictionAllowed === true;
    if (!guestEligible) guestQueue = InputQueue.fresh(currentRound,currentWorldTick);
    const publication = initial ? handshake({$:'Prepared',observation}) : null;
    if (initial && publication.$ !== 'PublishInitial') return;
    postMessage({type:'remote-frame',frame:guest,admission:session,receipt:guestReceipt,
      observationSeq:observation,connectionEpoch,token:Connection.epoch(gate),initial,contactJournal,
      inputTiming:{worldTick:currentWorldTick,lastRejected:lastInputRejection}});
  }
}
function prepareWorld(action) {
  try {
    const joined = Game.core_attach(core,action.character,action.meta,action.arcana,action.allowedWeapons);
    packet(joined);
    if (joined.$ !== 'CorePacket') { reject('SetupFailed'); return; }
  } catch (error) { reject('SetupFailed',error); return; }
  // Observing is preparation, not permission to advance the world. Bend waits
  // for this exact observation's ReadyAck before it returns StartAndConfirm.
  try { publish(true,true); }
  catch (error) { reject('SnapshotFailed',error); }
}
function acceptCommand(command, peer) {
  const action = command.action;
  if (action.$ === 'Choice' && !Connection.running(gate)) {
    postMessage({type:'choice-unavailable',player:peer,connectionEpoch}); return;
  }
  if (peer === 1 && action.$ !== 'Setup' && !Connection.running(gate)) return;
  const admission = Session.receive(session,peer,command);
  session = admission.state;
  if (!admission.accepted) return;
  if (action.$ === 'Movement' && peer === 1) {
    reject('ProtocolError'); return;
  } else if (action.$ === 'MovementTick' && peer === 1) {
    const admission = InputQueue.push_active(guestQueue,currentPhase,guestEligible,action.round,command.seq,command.intendedTick,action.x,action.y);
    if (!admission.accepted) {
      lastInputRejection = {reason:admission.reason,seq:command.seq,targetWorldTick:command.intendedTick,worldTick:currentWorldTick};
      postMessage({type:'input-rejected',...lastInputRejection,connectionEpoch});
    }
    if (admission.reason === 8) {
      guestQueue = InputQueue.fresh(currentRound,currentWorldTick);
      reject('ProtocolError'); return;
    }
    guestQueue = admission.state;
  } else if (action.$ === 'Choice') {
    packet(Game.core_choose(core,peer,action.round,action.index));
    publish();
  } else if (action.$ === 'Setup' && peer === 1) {
    // The model decides both compatibility of a premature legacy Setup and
    // whether a duplicate Setup can request world preparation.
    if (handshake({$:'Setup'}).$ === 'PrepareWorld') prepareWorld(action);
  }
}
function accept(text, peer) {
  const decoded = ClientDelivery.decode(text);
  if (decoded.$ !== 'Some') { if (peer === 1) reject('ProtocolError'); return; }
  for (let rows = decoded.value.commands; rows.$ === 'Con'; rows = rows.tail)
    acceptCommand(rows.head,peer);
}
function schedule() {
  const now = performance.now();
  // Discard suspend time; at most four fixed steps per scheduling turn.
  const elapsed = Math.min(4 * STEP,Math.max(0,now-last)); last = now;
  if (!Connection.running(gate)) { accumulator = 0; return; }
  accumulator += elapsed;
  let steps = 0;
  while (Connection.running(gate) && accumulator >= STEP && steps++ < 4) {
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
      session = Session.applied(frame.tick,session);
      contactJournal = HitJournal.ingest_capped(contactJournal,frame.tick,frame.contacts || {$:'Nil'},frame.contactsOmitted || 0);
    }
    if (frame && frame.phase !== lastPhase) { lastPhase = frame.phase; lastSnapshot = now; publish(); }
    accumulator -= STEP;
  }
  if (Connection.running(gate) && now-lastSnapshot >= 50) { lastSnapshot = now; publish(); }
}
onmessage = event => {
  try {
    const message = event.data;
    switch (message.type) {
      case 'init': {
        clearInterval(timer); gate = Connection.fresh({$:'Host'}); accumulator = 0;
        observationSeq = 0; lastPhase = undefined; guestReceipt = Session.receipt_fresh();
        currentRound = 0; currentPhase = 0; currentWorldTick = 0; guestEligible = false; guestQueue = InputQueue.fresh(0,0); lastInputRejection = null;
        const s = message.setup;
        connectionEpoch = 0;
        contactJournal = HitJournal.fresh(0);
        session = Session.fresh(message.session);
        packet(Game.core_start(s.character,s.meta,message.seed));
        packet(Game.core_configure(core,s.stage,s.mode,s.arcana));
        packet(Game.core_configure_unlocks(core,0,s.allowedWeapons));
        last = performance.now();
        timer = setInterval(() => {
          try { schedule(); }
          catch (error) { reject('RuntimeFailed',error); }
        },4);
        postMessage({type:'ready'});
        break;
      }
      case 'connected': {
        const transition = Connection.reconnect(gate,message.connectionEpoch);
        if (transition.action.$ !== 'SendHello') break;
        connectionEpoch = message.connectionEpoch;
        contactJournal = HitJournal.fresh(connectionEpoch);
        accumulator = 0;
        session = Session.reconnect(session);
        guestQueue = InputQueue.fresh(currentRound,currentWorldTick);
        guestReceipt = Session.receipt_fresh(); lastInputRejection = null;
        applyConnection(transition);
        break;
      }
      case 'handshake':
        if (message.connectionEpoch === connectionEpoch) handshake(message.signal,message.connectionEpoch);
        break;
      case 'command':
        if (message.player === 0 || message.connectionEpoch === connectionEpoch) accept(message.text,message.player);
        break;
      case 'disconnect':
        connectionEpoch = message.connectionEpoch ?? connectionEpoch;
        handshake({$:'Lost'}); accumulator = 0;
        guestQueue = InputQueue.fresh(currentRound,currentWorldTick); guestEligible = false;
        session = Session.disconnect(1,session);
        // Connection loss is suspension, not player death or reward forfeiture.
        publish(false); break;
      case 'stop': clearInterval(timer); close(); break;
    }
  } catch (error) { reject('RuntimeFailed',error); }
  finally {
    if (event.data.type === 'command') postMessage({type:'command-consumed',deliveryId:event.data.deliveryId});
  }
};
