// Browser IO: Iroh, input, worker scheduling and presentation. No simulation here.
import Protocol from './dist/coop-protocol.mjs';
import Connection from './dist/coop-connection.mjs';
import Prediction from './dist/coop-prediction.mjs';
import CombatForecast from './dist/coop-combat-prediction.mjs';
import { CoopTransport } from './coop-transport.mjs';
import { CoopUI } from './coop-ui.mjs';
let transport, worker, role, sessionId, sequence = 0, tick = 0, epoch = 0;
let runId = '', stalled = false;
let input = {x:0,y:0}, inputTimer, lastFrameAt = 0, connected = false;
let latestSnapshot, sendingSnapshot = false;
const pendingCommands = new Set(), MAX_COMMANDS = 64, MAX_COMMAND_BYTES = 160;
let deliverySequence = 0, connectionEpoch = 0, connectDeadline;
let connectionState = Connection.fresh({$:'Guest'}), selectedSetup, hostFrame;
let prediction, predictionRun, predictionStage, predictionRound, authorityFrame, predictionAt = 0, predictionRemainder = 0;
let predictionLead = 4, lastRoundTripMs = 0, lastPredictionResync, authorityInputTiming;
const sentCommandTimes = new Map();
let combatForecast, combatPresentation, combatPresentationState;
const PREDICTION_STEP = 1000 / 60;
const bendBool = value => Boolean(value);
function advancePrediction(now = performance.now()) {
  if (role !== 'guest' || !prediction || !Connection.running(connectionState)) return;
  // rAF timestamps may precede a performance.now() sampled by a message handler.
  // Never rewind the shared local clock and count that interval twice.
  now = Math.max(now,predictionAt);
  predictionRemainder += Math.min(4 * PREDICTION_STEP,now - predictionAt);
  predictionAt = now;
  let count = 0;
  while (predictionRemainder >= PREDICTION_STEP && count++ < 4) {
    if (Prediction.can_tick(prediction) && connected) {
      sendAction({$:'MovementTick',round:predictionRound ?? 0,
        x:Math.sign(input.x)+1,y:Math.sign(input.y)+1});
      prediction = Prediction.tick(prediction);
      if (combatForecast) combatForecast = CombatForecast.advance(combatForecast,
        Math.sign(input.x)+1,Math.sign(input.y)+1);
    }
    predictionRemainder -= PREDICTION_STEP;
  }
}
function observeRoundTrip(envelope,now) {
  const acknowledged = envelope.admission?.guest?.lastSeq;
  if (!Number.isInteger(acknowledged)) return;
  const sentAt = sentCommandTimes.get(acknowledged);
  if (sentAt !== undefined) lastRoundTripMs = Math.max(0,now-sentAt);
  // Sample first: the first eligible frame must include its Setup round trip.
  for (const seq of sentCommandTimes.keys()) if (seq <= acknowledged) sentCommandTimes.delete(seq);
}
function reconcilePrediction(envelope) {
  const frame = envelope.frame, now = performance.now();
  if (prediction && !Prediction.observation_newer(prediction,envelope.observationSeq)) return false;
  observeRoundTrip(envelope,now);
  const reset = !prediction || predictionRun !== frame.runId || predictionStage !== frame.stage
    || predictionRound !== (frame.roundId ?? 0);
  const wasEnabled = !reset && prediction.enabled === true;
  if (reset || !wasEnabled) predictionLead = Prediction.lead(Math.ceil(lastRoundTripMs));
  if (reset) {
    prediction = Prediction.fresh(frame.px,frame.py,frame.stepDistance,bendBool(frame.predictionAllowed),frame.tick,predictionLead);
    predictionRun = frame.runId; predictionStage = frame.stage; predictionRound = frame.roundId ?? 0;
    predictionAt = now; predictionRemainder = 0;
  } else advancePrediction(now);
  const resync = !reset && wasEnabled && frame.predictionAllowed && Prediction.resync_needed(prediction,frame.tick);
  const previousDisplayWorldTick = prediction.displayWorldTick;
  prediction = Prediction.reconcile(prediction,envelope.observationSeq,frame.tick,frame.px,frame.py,
    frame.stepDistance,bendBool(frame.predictionAllowed),predictionLead);
  if (resync) lastPredictionResync = Object.freeze({reason:'authority-caught-display-cursor',
    previousDisplayWorldTick,anchorWorldTick:frame.tick,displayWorldTick:prediction.displayWorldTick,lead:predictionLead});
  else if (reset) lastPredictionResync = null;
  if (prediction.observation !== envelope.observationSeq) return false;
  authorityFrame = frame; authorityInputTiming = envelope.inputTiming;
  // Each accepted authority frame is a new canonical cohort anchor. Previous
  // speculative trajectories may not override current contacts or enemy state.
  const combatAnchor = frame.predictionAllowed && frame.combatForecast
    ? CombatForecast.with_diagnostics(CombatForecast.receive(frame.combatForecast,envelope.admission),
      new URL(location.href).searchParams.has('combatTrace')) : null;
  combatForecast = combatAnchor
    ? CombatForecast.rebase(!reset && wasEnabled && combatForecast ? combatForecast : combatAnchor,combatAnchor,prediction) : null;
  if (!frame.predictionAllowed || !wasEnabled) { predictionAt = now; predictionRemainder = 0; }
  return true;
}
function displayFrame(frame, now) {
  if (role !== 'guest' || !authorityFrame) return frame;
  advancePrediction(now);
  const point = prediction ? Prediction.view(prediction) : {x:authorityFrame.px,y:authorityFrame.py};
  const own = authorityFrame.players?.find(player => player.id === authorityFrame.ownPlayerId);
  const predicting = authorityFrame.predictionAllowed;
  let bodies = frame.bodies;
  let predictedPlayers, combatDiagnostics;
  if (predicting && combatForecast) {
    if (combatPresentationState !== combatForecast) {
      combatPresentationState = combatForecast;
      combatPresentation = JSON.parse(CombatForecast.render(combatForecast));
    }
    // Enemies and every known projectile are rendered from one Bend cohort
    // clock. Pickups, rewards and durable gameplay remain authoritative.
    bodies = (frame.bodies || []).filter(body => ![0,1,7].includes(body[2]))
      .concat(combatPresentation.bodies);
    predictedPlayers = new Map(combatPresentation.players.map(player => [player.id,player]));
    // Display-only evidence belongs to this exact Bend cohort sample. It is not
    // passed to authoritative progression, rewards, audio or the network.
    combatDiagnostics = Object.freeze({tick:combatPresentation.tick,contacts:combatPresentation.contacts,
      assumptions:combatPresentation.assumptions,predictedCohort:combatPresentation.predictedCohort});
  }
  const predictionTiming = prediction ? Object.freeze({anchorWorldTick:prediction.anchorWorldTick,
    displayWorldTick:prediction.displayWorldTick,lead:predictionLead,roundTripMs:lastRoundTripMs,resync:lastPredictionResync,server:authorityInputTiming}) : undefined;
  return {...frame,bodies,combatPresentation:combatDiagnostics,predictionTiming,px:predicting ? point.x : authorityFrame.px,py:predicting ? point.y : authorityFrame.py,
    players:frame.players?.map(player => {
      const projected = predictedPlayers?.get(player.id);
      const authoritative = player.id === authorityFrame.ownPlayerId && own ? {...player,...own} : player;
      if (projected) return {...authoritative,px:projected.px,py:projected.py};
      return player.id === authorityFrame.ownPlayerId && own
        ? {...authoritative,px:predicting ? point.x : own.px,py:predicting ? point.y : own.py} : player;
    })};
}

function postCommand(text, player) {
  if (!worker || pendingCommands.size >= MAX_COMMANDS) return false;
  const deliveryId = ++deliverySequence;
  pendingCommands.add(deliveryId);
  worker.postMessage({type:'command',player,text,deliveryId,connectionEpoch});
  return true;
}
const decoder = new TextDecoder('utf-8', {fatal:true});
const random = () => crypto.getRandomValues(new Uint32Array(1))[0];
function command(action) {
  const seq = ++sequence;
  const intendedTick = role === 'guest' && prediction && action.$ === 'MovementTick'
    ? Prediction.next_world_tick(prediction) : tick;
  if (role === 'guest') {
    sentCommandTimes.set(seq,performance.now());
    if (sentCommandTimes.size > 256) sentCommandTimes.delete(sentCommandTimes.keys().next().value);
  }
  if (role === 'guest' && prediction && action.$ === 'MovementTick')
    prediction = Prediction.command(prediction,seq,action.x,action.y);
  return Protocol.encode({$: 'Command', session:sessionId, player:role === 'host' ? 0 : 1,
    seq,intendedTick,action});
}
function signalConnection(signal, envelope) {
  if (role === 'host' && worker) {
    worker.postMessage({type:'handshake',connectionEpoch,signal});
    return;
  }
  const result = Connection.step(connectionState,Connection.epoch(connectionState),signal);
  connectionState = result.state;
  connectionAction(result.action,envelope);
}
function transportFailure(error) {
  console.error(error);
  signalConnection({$:'Reject',reason:{$:'TransportFailed'}});
}
function sendControl(action) {
  const generation = epoch, connection = connectionEpoch, channel = transport;
  return channel.send(Connection.encode_action(action)).catch(error => {
    if (generation === epoch && connection === connectionEpoch) transportFailure(error);
    throw error;
  });
}
function connectionAction(action, envelope) {
  switch (action.$) {
    case 'SendHello':
      sendControl(action).catch(() => {}); break;
    case 'HelloAckAndSetup': {
      const generation = epoch, connection = connectionEpoch;
      sendControl(action).then(() => {
        if (generation !== epoch || connection !== connectionEpoch || !connected) return;
        return transport.send(command({$:'Setup',character:selectedSetup.character,
          arcana:selectedSetup.arcana,meta:selectedSetup.meta,allowedWeapons:selectedSetup.allowedWeapons}));
      }).catch(error => { if (generation === epoch && connection === connectionEpoch) transportFailure(error); });
      break;
    }
    case 'PresentSnapshot': {
      try {
        if (!envelope?.frame || typeof envelope.frame.predictionAllowed !== 'boolean' || !envelope.receipt)
          throw Error('Invalid authoritative snapshot');
        if (!reconcilePrediction(envelope)) return;
        lastFrameAt = performance.now(); tick = envelope.frame.tick;
        if (stalled && Connection.running(connectionState)) ui.status('');
        stalled = false;
        ui.present(envelope.frame);
        if (!Connection.running(connectionState)) ui.setChoicePending(true);
        signalConnection({$:'SnapshotSeen',token:action.token,observation:action.observation});
      } catch (error) {
        console.error(error); signalConnection({$:'Reject',reason:{$:'SnapshotFailed'}});
      }
      break;
    }
    case 'SendReadyAck':
      sendControl(action).catch(() => {}); break;
    case 'StartAndConfirm':
      clearTimeout(connectDeadline);
      if (hostFrame) ui.present({...hostFrame,runId});
      ui.setChoicePending(false); ui.status('');
      sendControl(action).catch(() => {}); break;
    case 'GuestReady':
      clearTimeout(connectDeadline); predictionAt = performance.now(); predictionRemainder = 0;
      ui.setChoicePending(false); ui.status(''); break;
    case 'Suspend':
      ui.setChoicePending(true);
      ui.status(role === 'host' ? 'Waiting for your teammate to rejoin. The run is paused.'
        : 'Host disconnected. Rejoin using the invitation if the party is still open.',{error:role !== 'host'});
      break;
    case 'CloseConnection': {
      clearTimeout(connectDeadline); clearInterval(inputTimer);
      prediction = null; authorityFrame = null; combatForecast = null;
      ui.setChoicePending(false); ui.status(Connection.reason_text(action.reason),{error:true});
      const generation = epoch, connection = connectionEpoch, channel = transport;
      const closePeer = () => {
        if (generation !== epoch || connection !== connectionEpoch) return;
        if (role === 'host') channel?.disconnectPeer(); else channel?.close();
        connected = false;
      };
      if (connected && channel) {
        channel.send(Connection.encode_action(action),{confirmDelivery:true}).catch(() => {}).finally(closePeer);
      } else {
        closePeer();
        // Endpoint creation may still complete after its IO deadline.
        if (!channel) epoch++;
      }
      break;
    }
  }
}
function armConnectionDeadline() {
  clearTimeout(connectDeadline);
  const generation = epoch, connection = connectionEpoch;
  connectDeadline = setTimeout(() => {
    if (generation !== epoch || connection !== connectionEpoch) return;
    // The browser owns the IO deadline; it cannot rely on an unresponsive worker.
    const result = Connection.step(connectionState,Connection.epoch(connectionState),{$:'Timeout'});
    connectionState = result.state;
    if (role === 'host' && worker) worker.postMessage({type:'handshake',connectionEpoch,signal:{$:'Timeout'}});
    connectionAction(result.action);
  },45000);
}
function sendAction(action) {
  if (role === 'host' ? !worker : !connected || !Connection.running(connectionState)) {
    if (action.$ === 'Choice') ui.setChoicePending(false);
    return;
  }
  const text = command(action);
  if (role === 'host') {
    if (!postCommand(text,0) && action.$ === 'Choice') {
      ui.setChoicePending(false); ui.status('Host is busy. Please choose again.');
    }
  } else {
    const generation = epoch, connection = connectionEpoch;
    transport.send(text).catch(error => {
      if (generation === epoch && connection === connectionEpoch) transportFailure(error);
    });
  }
}
async function flushSnapshot() {
  if (sendingSnapshot || !connected || role !== 'host') return;
  sendingSnapshot = true;
  const generation = epoch, connection = connectionEpoch, channel = transport;
  try {
    while (latestSnapshot && connected && generation === epoch && connection === connectionEpoch) {
      const message = latestSnapshot; latestSnapshot = null;
      await channel.send(JSON.stringify(message));
    }
  } catch (error) { if (generation === epoch && connection === connectionEpoch && connected) ui.status(error.message,{error:true}); }
  finally { if (generation === epoch && connection === connectionEpoch) sendingSnapshot = false; }
}
async function connect(kind, ticket, setup, invitation = {}) {
  cleanup(); const generation = epoch; role = kind; ui.role(kind); sequence = 0; selectedSetup = setup;
  connectionState = Connection.fresh({$:kind === 'host' ? 'Host' : 'Guest'});
  if (kind === 'host') runId = crypto.randomUUID?.() || Array.from(crypto.getRandomValues(new Uint32Array(4)), n => n.toString(16).padStart(8,'0')).join('');
  const requestedSession = invitation.session ?? new URL(location.href).searchParams.get('session');
  if (kind === 'guest' && requestedSession === null) throw Error('Open the complete invitation link.');
  sessionId = kind === 'host' ? random() : Number(requestedSession);
  if (!Number.isInteger(sessionId) || sessionId < 0 || sessionId > 0xffffffff)
    throw Error('Open the complete invitation link.');
  ui.status('Connecting to Iroh…',{busy:true});
  armConnectionDeadline();
  try {
    const created = await CoopTransport.create(event => {
      if (generation !== epoch) return;
      if (event.type === 'connected') {
        connectionEpoch = event.connectionEpoch;
        connected = true; lastFrameAt = performance.now();
        clearInterval(inputTimer); latestSnapshot = null; sendingSnapshot = false;
        armConnectionDeadline();
        if (kind === 'host') {
          connectionState = Connection.state(Connection.reconnect(connectionState,connectionEpoch));
          worker?.postMessage({type:'connected',connectionEpoch});
        } else {
          const result = Connection.reconnect(connectionState,connectionEpoch);
          connectionState = result.state; connectionAction(result.action);
        }
        ui.status('Connected. Checking party compatibility…',{busy:true});
        inputTimer = setInterval(() => {
          if (kind === 'guest') advancePrediction();
          else sendAction({$:'Movement',x:Math.sign(input.x)+1,y:Math.sign(input.y)+1});
        }, 50);
      } else if (event.type === 'message') {
        try {
          if (kind === 'host' && event.bytes.byteLength > MAX_COMMAND_BYTES) {
            signalConnection({$:'Reject',reason:{$:'ProtocolError'}}); return;
          }
          const text = decoder.decode(event.bytes), control = Connection.decode(text);
          if (control.$ === 'Some') { signalConnection(control.value); return; }
          if (kind === 'host') {
            if (!postCommand(text,1)) signalConnection({$:'Reject',reason:{$:'ProtocolError'}});
          } else {
            const envelope = JSON.parse(text);
            if (envelope.type !== 'frame') return;
            const number = value => Number.isInteger(value) && value >= 0 && value <= 0xffffffff ? value : 0;
            signalConnection({$:'Frame',version:number(envelope.connectionVersion),
              token:number(envelope.token),observation:number(envelope.observationSeq)},envelope);
          }
        } catch (error) {
          console.error(error); signalConnection({$:'Reject',reason:{$:'ProtocolError'}});
        }
      } else if (event.type === 'disconnected') {
        connectionEpoch = event.connectionEpoch;
        connected = false; prediction = null; authorityFrame = null; combatForecast = null;
        clearInterval(inputTimer); latestSnapshot = null; sendingSnapshot = false;
        ui.clearInput();
        clearTimeout(connectDeadline);
        if (kind === 'host') worker?.postMessage({type:'disconnect',connectionEpoch});
        else signalConnection({$:'Lost'});
      } else if (event.type === 'error') transportFailure(Error(event.message));
    });
    if (generation !== epoch) { created.close(); return; }
    transport = created;
    if (kind === 'host') {
      worker = new Worker('./coop-worker.mjs',{type:'module'});
      worker.onmessage = event => {
        if (generation !== epoch) return;
        const message = event.data;
        if (message.type === 'command-consumed') pendingCommands.delete(message.deliveryId);
        else if (message.type === 'frame') {
          tick = message.frame.tick; hostFrame = message.frame;
          if (message.connectionReady || ui.frame) ui.present({...message.frame,runId});
          if (!message.connectionReady) ui.setChoicePending(true);
        }
        else if (message.type === 'remote-frame') {
          if (!connected || message.connectionEpoch !== connectionEpoch) return;
          latestSnapshot = {type:'frame',connectionVersion:Connection.protocol_version(),token:message.token,initial:message.initial,frame:{...message.frame,runId},admission:message.admission,receipt:message.receipt,inputTiming:message.inputTiming,observationSeq:message.observationSeq}; flushSnapshot();
        } else if (message.type === 'handshake-action') {
          if (message.connectionEpoch === connectionEpoch && Connection.reason(connectionState).$ === 'None') {
            connectionState = message.state; connectionAction(message.action);
          }
        } else if (message.type === 'choice-unavailable' && message.player === 0 && message.connectionEpoch === connectionEpoch) {
          ui.setChoicePending(false); ui.status('Waiting for your teammate to be ready.');
        } else if (message.type === 'ready') {
          clearTimeout(connectDeadline);
          const link = new URL(location.href); link.search = '';
          link.searchParams.set('session',String(sessionId)); link.searchParams.set('join',transport.invitation());
          ui.invitation(link.href); ui.status('Send the invitation. Keep this host tab open.');
        } else if (message.type === 'error') console.error(message.message);
      };
      worker.onerror = event => {
        if (generation !== epoch) return;
        console.error(event.message || 'Host worker failed');
        worker?.terminate(); worker = null;
        signalConnection({$:'Reject',reason:{$:'RuntimeFailed'}});
      };
      worker.postMessage({type:'init',session:sessionId,seed:random(),setup});
    } else await transport.join(ticket);
  } catch (error) {
    if (generation === epoch) transportFailure(error);
  }
}
function showError(error) { ui.status(error.message || String(error),{error:true}); console.error(error); }
function cleanup() {
  epoch++; connectionState = Connection.fresh({$:'Guest'}); hostFrame = null; clearTimeout(connectDeadline); connectionEpoch = 0; pendingCommands.clear(); sentCommandTimes.clear(); stalled = false;
  predictionLead = 4; lastRoundTripMs = 0; lastPredictionResync = null; authorityInputTiming = null;
  prediction = null; authorityFrame = null; combatForecast = null; combatPresentation = null;
  combatPresentationState = null; predictionRun = null; predictionRound = null; predictionAt = 0; predictionRemainder = 0;
  connected = false; clearInterval(inputTimer); latestSnapshot = null; sendingSnapshot = false;
  worker?.terminate(); worker = null; transport?.close(); transport = null;
  input = {x:0,y:0};
}
const ui = new CoopUI({
  onHost: setup => connect('host',null,setup).catch(showError),
  onJoin: (ticket,setup,invitation) => connect('guest',ticket,setup,invitation).catch(showError),
  onInput: value => {
    advancePrediction(); input = value;
    if (role === 'host')
      sendAction({$:'Movement',x:Math.sign(input.x)+1,y:Math.sign(input.y)+1});
  },
  onDisplay: displayFrame,
  onChoice: ({round,index}) => sendAction({$:'Choice',round,index}),
  onLeave: () => { cleanup(); ui.reset(); },
});
// A browser may suspend the host. Surface it; do not claim workers prevent it.
setInterval(() => {
  if (role === 'guest' && connected && Connection.running(connectionState) && !stalled && performance.now() - lastFrameAt > 5000) {
    stalled = true; ui.status('Host is stalled. Keep the host browser active.',{error:true});
  }
},1000);
addEventListener('pagehide',cleanup);
