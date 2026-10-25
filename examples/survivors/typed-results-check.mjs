#!/usr/bin/env node
// Exercise the production result/observation boundary through real transitions.
import assert from 'node:assert/strict';
import {resolve, join} from 'node:path';
import {pathToFileURL} from 'node:url';
const directory = resolve(process.argv[2]);
const [{default:Game},{default:GameEncoder},{default:Core},{default:CoopEncoder}] =
  await Promise.all(['game','game-encoder','coop-core','coop-encoder'].map(name =>
    import(pathToFileURL(join(directory, name + '.mjs')))));
function typed(packet, tag) {
  assert.equal(packet.$, tag);
  assert.equal(Object.hasOwn(packet, 'frame'), false, 'simulation must not serialize');
  return packet;
}
assert.equal(Object.keys(Game).some(name => name.endsWith('_quiet')), false,
  'one typed simulation API replaces quiet variants');
let packet = typed(Game.start_seed(0,0,12345), 'Packet');
let observed = GameEncoder.observe(packet.state);
assert.deepEqual(observed.state, packet.state, 'observation preserves owned world');
let frame = JSON.parse(observed.frame);
assert.equal(frame.tick, 0);
assert.equal(frame.hp, packet.state.run.hp);
packet = typed(Game.advance(observed.state,1,0), 'Packet');
observed = GameEncoder.observe(packet.state);
frame = JSON.parse(observed.frame);
assert.equal(frame.tick, 1);
assert.equal(frame.px, packet.state.run.px);
assert.deepEqual(Game.observed_packet, undefined);
let core = typed(Core.core_start(0,0,100), 'CorePacket');
assert.equal(core.observation.$, 'NoObservation');
assert.equal(CoopEncoder.encode(core.observation).$, 'None');
core = typed(Core.core_join(core.state,1,0,0), 'CorePacket');
const beforeView = core.state;
const view = typed(Core.core_observe(beforeView,1), 'CorePacket');
assert.equal(view.observation.$, 'ViewObservation');
assert.deepEqual(view.state, beforeView, 'co-op observation preserves world');
const encoded = CoopEncoder.encode(view.observation);
assert.equal(encoded.$, 'Some');
const coopFrame = JSON.parse(encoded.value);
assert.equal(coopFrame.ownPlayerId, 1);
assert.equal(coopFrame.players.length, 2);
assert.equal(coopFrame.combatForecast.$, 'Scene');
const rejected = Core.core_join(view.state,0,0,0);
assert.equal(rejected.$, 'CoreRejected');
assert.deepEqual(rejected.state, view.state, 'rejection retains state');
assert.equal(Object.hasOwn(rejected,'frame'), false);
const step = typed(Core.core_step(rejected.state,1,0,0,1), 'CorePacket');
assert.equal(step.observation.$, 'StepObservation');
assert.equal(step.observation.advanced, true);
assert.equal(step.observation.tick, 1);
const stepFrame = JSON.parse(CoopEncoder.encode(step.observation).value);
assert.equal(stepFrame.advanced, true);
assert.equal(stepFrame.tick, 1);
assert.deepEqual(stepFrame.contacts, step.observation.contacts);
const pausedState = {...step.state,shared:{...step.state.shared,phase:1}};
const paused = typed(Core.core_step(pausedState,1,0,0,1), 'CorePacket');
assert.equal(paused.observation.advanced,false);
assert.deepEqual(paused.state,pausedState);
assert.deepEqual(JSON.parse(CoopEncoder.encode(paused.observation).value),
  {tick:1,phase:1,advanced:false});
assert.deepEqual(Game.seeded_packet({$:'Failed',error:'fixture'},1),
  {$:'Failed',error:'fixture'}, 'failure propagates without encoding');
console.log('TYPED RESULTS PASS: solo/co-op, observations, steps, rejection, failure');
