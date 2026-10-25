import assert from 'node:assert/strict';
import test from 'node:test';
import { AudioEngine } from './audio.mjs';

const param = () => ({ value: 0, ramps: [], setValueAtTime() {}, exponentialRampToValueAtTime(...args) { this.ramps.push(args); }, setTargetAtTime() {} });
function context() {
  const nodes = [], gains = [];
  return { currentTime: 0, state: 'running', nodes, gains,
    createOscillator() { const node = { frequency: param(), connect() {}, disconnect() {}, start() {}, stop() {} }; nodes.push(node); return node; },
    createGain() { const gain = { gain: param(), connect() {}, disconnect() {} }; gains.push(gain); return gain; },
  };
}
test('construction creates no AudioContext; music budget cannot starve sound effects', () => {
  const engine = new AudioEngine();
  assert.equal(engine.context, null);
  engine.context = context(); engine.master = { gain: param() };
  engine.musicVoices = 32;
  engine._tone(440, 0.1, 0.05, 'square', 0, 0, 0, 'music');
  assert.equal(engine.context.nodes.length, 0);
  engine.event('shot');
  assert.equal(engine.context.nodes.length, 1);
  assert.equal(engine.sfxVoices, 1);
  engine.stop(true);
});
test('bar scheduling waits until30ms and commits only the latest target', () => {
  const engine = new AudioEngine();
  engine.context = context(); engine.master = { gain: param() }; engine.playing = true;
  engine.frame = { stage: 0 }; engine.step = 16; engine.nextNote = 0.1;
  const refreshes = [], notes = [];
  engine._refreshDanger = (now, force) => refreshes.push({ now, force });
  engine._note = note => notes.push(note);
  for (const target of [3, 0, 3, 0]) {
    engine.targetBand = target;
    engine._schedule();
    assert.equal(engine.step, 16, "No obsolete transition is queued before the bar");
  }
  assert.equal(engine.step, 16); assert.equal(notes.length, 0);
  engine.targetBand = 0; // A newer observation replaces the previous candidate transition.
  engine.context.currentTime = 0.08;
  engine._schedule();
  assert.ok(engine.step > 16);
  assert.equal(engine.activeBand, 0);
  assert.ok(refreshes.some(row => row.force === true));
  assert.ok(notes.length > 0);
  engine.stop(true);
});
test('pause cancels future notes and resumes their position without wallclock catchup', () => {
  const engine = new AudioEngine();
  engine.context = context(); engine.master = { gain: param() }; engine.step = 12;
  engine.scheduled = [{ step: 10, time: 0.05 }, { step: 11, time: 0.15 }];
  engine.context.currentTime = 0.1;
  engine.stop();
  assert.equal(engine.step, 11);
  assert.equal(engine.timer, null);
  engine.context.currentTime = 100;
  engine.update({ stage: 0 });
  assert.equal(engine.step, 11);
  assert.equal(engine.nextNote, 100.04);
  engine.setMuted(true);
  assert.equal(engine.step, 11);
  assert.equal(engine.playing, false);
  engine.stop(true);
  assert.equal(engine.step, 0);
});

test('music-only envelope level leaves established SFX gain unchanged', () => {
  const engine = new AudioEngine(); engine.context = context(); engine.master = { gain: param() };
  engine._tone(440, 0.1, 0.05, 'square');
  engine._tone(440, 0.1, 0.05, 'square', 0, 0, 0, 'music');
  assert.equal(engine.context.gains[0].gain.ramps[0][0], 0.05);
  assert.equal(engine.context.gains[1].gain.ramps[0][0], 0.2);
  engine.stop(true);
});

test('composition seed survives pause and theme boundary preserves tension', () => {
  const engine=new AudioEngine();
  engine.context=context();engine.master={gain:param()};engine.playing=true;
  engine.frame={stage:0};engine.musicSeed=123;engine.activeBand=2;engine.targetBand=2;
  engine.step=512;engine.nextNote=0;
  engine._refreshDanger=()=>{};engine._note=()=>{};
  engine._schedule();
  assert.equal(engine.activeBand,2,'Changing composition must not reset the arrangement');
  engine.stop();
  assert.equal(engine.musicSeed,123,'Pause keeps the run playlist');
});
