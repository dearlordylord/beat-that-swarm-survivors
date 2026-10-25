// Actual emitted Bend ABI and its one network admission boundary.
import assert from 'node:assert/strict';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {gameFrame,coreFrame,projectileFrame} from './observations.mjs';
import {admitSnapshot} from './snapshot-envelope.mjs';

const directory = resolve(process.argv[2]);
const load = async name => (await import(pathToFileURL(resolve(directory,`${name}.mjs`)))).default;
const [Game,Core,Session,Journal,Local] = await Promise.all(
  ['game','coop-core','coop-session','coop-hit-journal','coop-local-projectiles'].map(load));
const solo = Game.start_seed(0,0,12345);
assert.equal(solo.frame.$,'Some');
assert.equal(solo.frame.value.$,'Observation');
const frame = gameFrame(solo.frame);
assert.equal(frame.tick,0);assert.equal(frame.px,7200);assert.ok(Array.isArray(frame.bodies));
assert.equal(gameFrame(Game.quiet_packet(solo.state).frame),null,'quiet differs from a complete observation');

const started = Core.core_start(0,0,12345);
assert.equal(coreFrame(Core.quiet(started.state).frame),null);
const observed = Core.core_observe(started.state,0);
assert.equal(observed.frame.value.$,'Display');
const coop = coreFrame(observed.frame);
assert.equal(coop.tick,0);assert.equal(coop.players.length,1);assert.equal(coop.combatForecast.$,'Scene');
const clock = Core.core_clock(observed.state);
assert.equal(clock.frame.value.$,'Clock');
assert.deepEqual(coreFrame(clock.frame),{tick:0,phase:0,advanced:false,contacts:{$:'Nil'},contactsOmitted:0});
assert.deepEqual(projectileFrame(Local.render_frame(Local.empty(),1,0,{$:'Nil'})),{shots:[],contacts:[],corpses:[]});

const envelope = {type:'frame',connectionVersion:1,token:7,initial:true,frame:{...coop,runId:'fixture'},
  admission:Session.fresh(1),receipt:Session.receipt_fresh(),observationSeq:1,
  contactJournal:Journal.fresh(7),inputTiming:{worldTick:0,lastRejected:null}};
assert.equal(admitSnapshot(envelope),envelope,'network checks admit atomically without cloning the frame again');
for (const corrupt of [
  v=>{v.frame.hp=-1;},v=>{v.frame.tick=0x100000000;},v=>{v.frame.px=Infinity;},
  v=>{v.frame.players[0].alive=1;},v=>{v.frame.bodies=[[0,0,0]];},
  v=>{v.frame.combatForecast.$='Unknown';},v=>{delete v.frame.combatForecast.directions;},
  v=>{v.contactJournal.events={$:'Nil',extra:true};},v=>{v.receipt.applied=1;},
  v=>{v.inputTiming.lastRejected={reason:1};},v=>{v.frame.extra=true;},
]) {
  const bad=structuredClone(envelope);corrupt(bad);assert.throws(()=>admitSnapshot(bad));
}
const tooDeep=structuredClone(envelope);
for(let i=0;i<100;i++)tooDeep.frame.combatForecast.births={$: 'Fork',sample:0,mask:1,
  zero:tooDeep.frame.combatForecast.births,one:{$:'Empty'}};
assert.throws(()=>admitSnapshot(tooDeep),RangeError);
console.log('PASS emitted typed observations: full/quiet/clock, direct projectile render, strict network admission');
