// Browser IO: Iroh, input, worker scheduling and presentation. No simulation here.
import Protocol from './dist/coop-protocol.mjs';
import Prediction from './dist/coop-prediction.mjs';
import WeaponForecast from './dist/coop-weapon-prediction.mjs';
import WeaponReconcile from './dist/coop-weapon-reconcile.mjs';
import { CoopTransport } from './coop-transport.mjs';
import { CoopUI } from './coop-ui.mjs';
let transport, worker, role, sessionId, sequence = 0, tick = 0, epoch = 0;
let runId = '', receivedFrame = false, stalled = false;
let input = {x:0,y:0}, inputTimer, lastFrameAt = 0, connected = false;
let latestSnapshot, sendingSnapshot = false;
const pendingCommands = new Set(), MAX_COMMANDS = 64, MAX_COMMAND_BYTES = 160;
let deliverySequence = 0;
let prediction, predictionRun, predictionStage, predictionRound, authorityFrame, predictionAt = 0, predictionRemainder = 0;
let weaponForecast, weaponPresentation, weaponPresentationState, weaponPresentationSeeds;
const PREDICTION_STEP = 1000 / 60;
const bendBool = value => Boolean(value);
function advancePrediction(now = performance.now()) {
  if (role !== 'guest' || !prediction) return;
  // rAF timestamps may precede a performance.now() sampled by a message handler.
  // Never rewind the shared local clock and count that interval twice.
  now = Math.max(now,predictionAt);
  predictionRemainder += Math.min(4 * PREDICTION_STEP,now - predictionAt);
  predictionAt = now;
  let count = 0;
  while (predictionRemainder >= PREDICTION_STEP && count++ < 4) {
    if (prediction.enabled && prediction.age < Prediction.horizon() && connected) {
      sendAction({$:'MovementTick',round:predictionRound ?? 0,
        x:Math.sign(input.x)+1,y:Math.sign(input.y)+1});
      prediction = Prediction.tick(prediction);
      if (weaponForecast) weaponForecast = WeaponForecast.advance(weaponForecast,
        Math.sign(input.x)+1,Math.sign(input.y)+1);
    }
    predictionRemainder -= PREDICTION_STEP;
  }
}
function reconcilePrediction(envelope) {
  const frame = envelope.frame, now = performance.now();
  if (prediction && !Prediction.observation_newer(prediction,envelope.observationSeq)) return false;
  const reset = !prediction || predictionRun !== frame.runId || predictionStage !== frame.stage
    || predictionRound !== (frame.roundId ?? 0);
  const wasEnabled = !reset && prediction.enabled === true;
  if (reset) {
    prediction = Prediction.fresh(frame.px, frame.py, frame.stepDistance, bendBool(frame.predictionAllowed));
    predictionRun = frame.runId; predictionStage = frame.stage; predictionRound = frame.roundId ?? 0;
    predictionAt = now; predictionRemainder = 0;
  } else advancePrediction(now);
  const receipt = envelope.receipt || {$:'Receipt',seq:0,steps:0,x:1,y:1,expired:false};
  prediction = Prediction.reconcile(prediction,envelope.observationSeq,frame.px,frame.py,
    frame.stepDistance,bendBool(frame.predictionAllowed),receipt);
  if (prediction.observation !== envelope.observationSeq) return false;
  authorityFrame = frame;
  const freshWeapons = frame.predictionAllowed && frame.weaponForecast
    ? WeaponForecast.forecast(WeaponForecast.receive(frame.weaponForecast),prediction) : null;
  weaponForecast = freshWeapons && weaponForecast && !reset && wasEnabled
    ? WeaponReconcile.rebase(weaponForecast,freshWeapons) : freshWeapons;
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
  if (predicting && weaponForecast) {
    if (weaponPresentationState !== weaponForecast) {
      weaponPresentationState = weaponForecast;
      weaponPresentation = JSON.parse(WeaponForecast.render(weaponForecast));
      weaponPresentationSeeds = new Set(weaponPresentation.ownSeeds);
    }
    // Replace only this player's weapon visuals. Remote shots, enemies, damage
    // and pickups remain the received/interpolated authoritative observation.
    bodies = (frame.bodies || []).filter(body => body[2] !== 1 || !weaponPresentationSeeds.has(body[7]))
      .concat(weaponPresentation.bodies);
  }
  return {...frame,bodies,px:predicting ? point.x : authorityFrame.px,py:predicting ? point.y : authorityFrame.py,
    players:frame.players?.map(player => player.id === authorityFrame.ownPlayerId && own
      ? {...player,...own,px:predicting ? point.x : own.px,py:predicting ? point.y : own.py} : player)};
}
function postCommand(text, player) {
  if (!worker || pendingCommands.size >= MAX_COMMANDS) return false;
  const deliveryId = ++deliverySequence;
  pendingCommands.add(deliveryId);
  worker.postMessage({type:'command',player,text,deliveryId});
  return true;
}
function refuseGuest(message) {
  connected = false; transport?.close();
  worker?.postMessage({type:'disconnect'});
  ui.status(message,{error:true});
}
const decoder = new TextDecoder('utf-8', {fatal:true});
const random = () => crypto.getRandomValues(new Uint32Array(1))[0];
function command(action) {
  const seq = ++sequence;
  if (role === 'guest' && prediction && action.$ === 'MovementTick')
    prediction = Prediction.command(prediction,seq,action.x,action.y);
  return Protocol.encode({$: 'Command', session:sessionId, player:role === 'host' ? 0 : 1,
    seq, intendedTick:tick, action});
}
function sendAction(action) {
  if (role === 'host' ? !worker : !connected) return;
  const text = command(action);
  if (role === 'host') {
    if (!postCommand(text,0) && action.$ === 'Choice') {
      ui.setChoicePending(false); ui.status('Host is busy. Please choose again.');
    }
  } else {
    const generation = epoch;
    transport.send(text).catch(error => {
      if (generation !== epoch) return;
      if (action.$ === 'Choice') ui.setChoicePending(false);
      if (action.$ === 'MovementTick') {
        connected = false; prediction = null; authorityFrame = null; weaponForecast = null;
        clearInterval(inputTimer); transport?.close();
      }
      ui.status(error.message,{error:true});
    });
  }
}
async function flushSnapshot() {
  if (sendingSnapshot || !connected || role !== 'host') return;
  sendingSnapshot = true;
  const generation = epoch, channel = transport;
  try {
    while (latestSnapshot && connected && generation === epoch) {
      const message = latestSnapshot; latestSnapshot = null;
      await channel.send(JSON.stringify(message));
    }
  } catch (error) { if (generation === epoch && connected) ui.status(error.message,{error:true}); }
  finally { if (generation === epoch) sendingSnapshot = false; }
}
async function connect(kind, ticket, setup, invitation = {}) {
  cleanup(); const generation = epoch; role = kind; ui.role(kind); sequence = 0;
  if (kind === 'host') runId = crypto.randomUUID?.() || Array.from(crypto.getRandomValues(new Uint32Array(4)), n => n.toString(16).padStart(8,'0')).join('');
  const requestedSession = invitation.session ?? new URL(location.href).searchParams.get('session');
  if (kind === 'guest' && requestedSession === null) throw Error('Open the complete invitation link.');
  sessionId = kind === 'host' ? random() : Number(requestedSession);
  if (!Number.isInteger(sessionId) || sessionId < 0 || sessionId > 0xffffffff)
    throw Error('Open the complete invitation link.');
  ui.status('Connecting to Iroh…',{busy:true});
  const created = await CoopTransport.create(event => {
    if (generation !== epoch) return;
    if (event.type === 'connected') {
      connected = true; lastFrameAt = performance.now();
      ui.status(kind === 'host' ? 'Guest connected. Preparing shared world…' : 'Connected. Waiting for the host…');
      if (kind === 'guest') transport.send(command({$:'Setup', character:setup.character,
        arcana:setup.arcana, meta:setup.meta, allowedWeapons:setup.allowedWeapons})).catch(showError);
      inputTimer = setInterval(() => {
        if (kind === 'guest') advancePrediction();
        else sendAction({$:'Movement',x:Math.sign(input.x)+1,y:Math.sign(input.y)+1});
      }, 50);
    } else if (event.type === 'message') {
      try {
        if (kind === 'host' && event.bytes.byteLength > MAX_COMMAND_BYTES) {
          refuseGuest('Guest command exceeded the transport limit. The guest was disconnected.'); return;
        }
        const text = decoder.decode(event.bytes);
        if (kind === 'host') {
          if (!postCommand(text,1)) refuseGuest('Guest command queue overflowed. The guest was disconnected.');
        }
        else {
          const envelope = JSON.parse(text);
          if (envelope.type !== 'frame') return;
          if (envelope.predictionModel !== 'input-ticks-weapons-v1' || !Number.isInteger(envelope.observationSeq) || !envelope.receipt
              || typeof envelope.frame?.predictionAllowed !== 'boolean') {
            cleanup(); ui.status('Reload both pages and create a new invitation to use the current host version.',{error:true}); return;
          }
          if (!reconcilePrediction(envelope)) return;
          lastFrameAt = performance.now(); tick = envelope.frame.tick;
          if (!receivedFrame || stalled) ui.status('');
          receivedFrame = true; stalled = false;
          ui.present(envelope.frame);
        }
      } catch (error) { showError(error); }
    } else if (event.type === 'disconnected') {
      connected = false; prediction = null; authorityFrame = null; weaponForecast = null;
      if (kind !== 'host') clearInterval(inputTimer);
      if (kind === 'host') { transport?.close(); worker?.postMessage({type:'disconnect'}); ui.status('Guest left. The run continues.'); }
      else ui.status('Host disconnected. Session ended.',{error:true});
    } else if (event.type === 'error') ui.status(event.message,{error:true});
  });
  if (generation !== epoch) { created.close(); return; }
  transport = created;
  if (kind === 'host') {
    worker = new Worker('./coop-worker.mjs',{type:'module'});
    worker.onmessage = event => {
      if (generation !== epoch) return;
      const message = event.data;
      if (message.type === 'command-consumed') pendingCommands.delete(message.deliveryId);
      else if (message.type === 'frame') { tick = message.frame.tick; ui.present({...message.frame,runId}); }
      else if (message.type === 'remote-frame') {
        latestSnapshot = {type:'frame',predictionModel:'input-ticks-weapons-v1',frame:{...message.frame,runId},admission:message.admission,receipt:message.receipt,observationSeq:message.observationSeq}; flushSnapshot();
      } else if (message.type === 'guest-input-overflow' || message.type === 'guest-protocol-mismatch') {
        refuseGuest(message.type === 'guest-input-overflow'
          ? 'Guest input queue overflowed. The guest was disconnected.'
          : 'Reload both pages and create a new invitation to use the current guest version.');
      } else if (message.type === 'ready') {
        const link = new URL(location.href); link.search = '';
        link.searchParams.set('session',String(sessionId)); link.searchParams.set('join',transport.invitation());
        ui.invitation(link.href); ui.status('Send the invitation. Keep this host tab open.');
      } else if (message.type === 'started') ui.status('');
      else if (message.type === 'error') showError(Error(message.message));
    };
    worker.onerror = event => { if (generation === epoch) showError(Error(event.message || 'Host worker failed.')); };
    worker.postMessage({type:'init',session:sessionId,seed:random(),setup});
  } else await transport.join(ticket);
}
function showError(error) { ui.status(error.message || String(error),{error:true}); console.error(error); }
function cleanup() {
  epoch++; pendingCommands.clear(); receivedFrame = false; stalled = false;
  prediction = null; authorityFrame = null; weaponForecast = null; weaponPresentation = null;
  weaponPresentationState = null; weaponPresentationSeeds = null; predictionRun = null; predictionRound = null; predictionAt = 0; predictionRemainder = 0;
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
  if (role === 'guest' && connected && !stalled && performance.now() - lastFrameAt > 5000) {
    stalled = true; ui.status('Host is stalled. Keep the host browser active.',{error:true});
  }
},1000);
addEventListener('pagehide',cleanup);
