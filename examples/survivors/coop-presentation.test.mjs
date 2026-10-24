import assert from 'node:assert/strict';
import test from 'node:test';
import { ObservationPresentation, interpolateObservations } from './coop-presentation.mjs';

const body = (x, seed = 7, kind = 0, age = 10, generation) => [x, 20, kind, 1, 80, 100, age, seed, 10, ...(generation === undefined ? [] : [generation])];
const frame = (tick, x, extra = {}) => ({ runId: 'run', ownPlayerId: 0, stage: 0, tick, px: x, py: 20,
  hp: 100, gold: 12, players: [{ id: 0, character: 0, px: x, py: 20, hp: 100 }], bodies: [body(x, 7, 0, tick)], ...extra });
const freeze = value => { if (value && typeof value === 'object') { Object.freeze(value); Object.values(value).forEach(freeze); } return value; };

test('interpolation moves only presentation coordinates without mutating authoritative observations', () => {
  const previous = freeze(frame(10, 10)), current = freeze(frame(13, 40, { hp: 75, gold: 25 }));
  const result = interpolateObservations(previous, current, .5);
  assert.equal(result.px, 25); assert.equal(result.players[0].px, 25); assert.equal(result.bodies[0][0], 25);
  assert.equal(result.hp, 75); assert.equal(result.gold, 25);
  assert.equal(previous.px, 10); assert.equal(current.px, 40); assert.equal(current.bodies[0][0], 40);
  assert.notEqual(result.players[0], current.players[0]); assert.notEqual(result.bodies[0], current.bodies[0]);
});

test('births, recycled identity, generation changes, age resets and teleports snap to observed positions', () => {
  const old = frame(10, 10);
  for (const changed of [body(40, 8), body(40, 7, 2), body(40, 7, 0, 1), body(40, 7, 0, 13, 2), body(1000)]) {
    const current = frame(13, 40, { bodies: [changed] });
    assert.equal(interpolateObservations(old, current, .5).bodies[0][0], changed[0]);
  }
  assert.equal(interpolateObservations(old, frame(13, 1000), .5).px, 1000);
  const born = frame(13, 40, { bodies: [body(40), body(70, 99)] });
  assert.equal(interpolateObservations(old, born, .5).bodies[1][0], 70);
});

test('ambiguous body identities never borrow another entity position', () => {
  const previous = frame(10, 10, { bodies: [body(10), body(20)] });
  const current = frame(13, 50, { bodies: [body(50)] });
  assert.equal(interpolateObservations(previous, current, .5).bodies[0][0], 50);
  assert.equal(interpolateObservations(frame(10, 10), frame(13, 50, { bodies: [body(50), body(70)] }), .5).bodies[1][0], 70);
});

test('player IDs, not array order, match participants; births and deaths do not interpolate', () => {
  const previous = frame(10, 10, { players: [{ id: 0, character: 0, px: 10, py: 20, hp: 100 }, { id: 1, character: 1, px: 80, py: 20, hp: 100 }] });
  const current = frame(13, 30, { players: [{ id: 1, character: 1, px: 100, py: 20, hp: 100 }, { id: 0, character: 0, px: 30, py: 20, hp: 100 }, { id: 2, px: 50, py: 20, hp: 100 }] });
  assert.deepEqual(interpolateObservations(previous, current, .5).players.map(player => player.px), [90, 20, 50]);
  current.players[0].hp = 0;
  assert.equal(interpolateObservations(previous, current, .5).players[0].px, 100);
});

test('50ms delayed display samples clamp to observations and never extrapolate', () => {
  const presentation = new ObservationPresentation();
  presentation.push(frame(10, 10), 100);
  presentation.push(frame(13, 40), 150);
  assert.equal(presentation.sample(150).px, 10);
  assert.equal(presentation.sample(175).px, 25);
  assert.equal(presentation.sample(200).px, 40);
  assert.equal(presentation.sample(5000).px, 40);
  assert.equal(interpolateObservations(frame(10, 10), frame(13, 40), -10).px, 10);
  assert.equal(interpolateObservations(frame(10, 10), frame(13, 40), 10).px, 40);
  const capped = new ObservationPresentation({ delayMs: 999 });
  assert.equal(capped.delayMs, 50);
});

test('new runs and rewound ticks reset display history rather than cross-match movement', () => {
  const presentation = new ObservationPresentation();
  presentation.push(frame(10, 10), 100);
  presentation.push(frame(1, 80, { runId: 'another' }), 150);
  assert.equal(presentation.sample(175).px, 80);
  presentation.push(frame(0, 120, { runId: 'another' }), 200);
  assert.equal(presentation.sample(200).px, 120);
  presentation.reset(); assert.equal(presentation.sample(200), null);
});
