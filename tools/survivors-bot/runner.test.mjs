import test from 'node:test';
import assert from 'node:assert/strict';
import { runBot, continuingGoal } from './runner.mjs';

// Deliberately tiny fake affine world: these tests exercise orchestration,
// not actual game balance. actions.test.mjs separately drives real Bend.
function toyGame({ queued = false } = {}) {
  const consumed = new WeakSet(); let lastTick = 0, chosen = 0;
  const initial = { tick: 0, phase: 0, px: 1800, py: 1800, hp: 70, maxHp: 70, xp: 0, xpNeed: 100, level: 1, kills: 0, gold: 0, character: 0, arcana: 0, stage: 0, mode: 0, runLength: 36000, rerolls: 3, banishes: 3, skips: 3, weapons: [1, ...Array(23).fill(0)], passives: Array(18).fill(0), bodies: [], offers: [] };
  const offers = [{ kind: 0, id: 0, level: 2 }, { kind: 1, id: 7, level: 1 }];
  const take = (state) => { assert.ok(!consumed.has(state), 'An owned state cannot be reused'); consumed.add(state); return structuredClone(state.frame); };
  const packet = (frame) => { lastTick = frame.tick; return { $: 'game.Packet', state: { frame }, frame: JSON.stringify(frame) }; };
  return {
    get tick() { return lastTick; },
    fresh_start: () => packet(structuredClone(initial)), advanced_start: () => packet(structuredClone(initial)),
    observe(state) {
      const frame = take(state);
      const actions = ['north', 'east', 'south', 'west'].map((name, i) => ({ id: 't' + frame.tick + ':move_' + name + ':' + name, kind: 'move_' + name, target: { x: frame.px + [0, 160, 0, -160][i], y: frame.py + [-160, 0, 160, 0][i] }, distance: 160, observedTick: frame.tick, executable: false, safety: 'unassessed' }));
      const mechanics = { source: 'offline toy fixture, not Bend rules', current: { hp: frame.hp }, offers: frame.offers.map((offer, offerIndex) => ({ offerIndex, offer, after: { hp: frame.hp } })) };
      return { $: 'Observed', state: { frame }, frame: JSON.stringify(frame), actions: JSON.stringify(actions), mechanics: JSON.stringify(mechanics) };
    },
    advance(state, dx, dy) {
      const frame = take(state); frame.tick++; frame.px += dx * 2.5; frame.py += dy * 2.5;
      if (frame.tick === 2) { frame.phase = 1; frame.offers = offers; }
      return packet(frame);
    },
    choose(state, index) {
      const frame = take(state); assert.ok(index >= 0 && index < frame.offers.length);
      chosen++; frame.level++; frame.phase = queued && chosen === 1 ? 1 : 0; frame.offers = frame.phase === 1 ? offers : [];
      return packet(frame);
    },
  };
}
const answer = (r, i = 0) => ({ runId: r.runId, decisionSeq: r.decisionSeq, candidatesHash: r.candidatesHash, selectedCandidateId: r.candidates[i].id, model: 'offline-fake' });

test('both real decision paths choose legal IDs; simulation stays paused while classifying', async () => {
  const game = toyGame(), records = [], seen = [];
  const result = await runBot(game, { mode: 'jev', ticks: 5, runId: 'test', emit: (r) => records.push(r), classify: async (request) => {
    seen.push(request.kind); const tick = game.tick; await Promise.resolve(); assert.equal(game.tick, tick); return answer(request, 1);
  } });
  assert.deepEqual(seen, ['goal', 'upgrade']); assert.equal(result.tick, 5);
  assert.deepEqual(result.successes, { upgrade: 1, goal: 1 }); assert.equal(result.fallbacks, 0);
  assert.ok(records.filter((r) => r.type === 'decision').every((r) => r.result.source === 'classifier'));
});

test('invalid response falls back; zero budgets make no classifier calls', async () => {
  const records = [];
  const result = await runBot(toyGame(), { mode: 'jev', ticks: 5, runId: 'bad', emit: (r) => records.push(r), classify: async (r) => ({ ...answer(r), selectedCandidateId: 'invented' }) });
  assert.equal(result.fallbacks, 2); assert.equal(result.choices, 1); assert.deepEqual(result.successes, { upgrade: 0, goal: 0 });
  const capped = await runBot(toyGame(), { mode: 'jev', ticks: 5, maxUpgradeRequests: 0, maxGoalRequests: 0, classify: () => assert.fail('No calls allowed') });
  assert.equal(capped.fallbacks, 2); assert.deepEqual(capped.classifierAttempts, { upgrade: 0, goal: 0 });
});

test('same-tick queued rewards receive different sequences and candidate IDs', async () => {
  const requests = [];
  await runBot(toyGame({ queued: true }), { mode: 'jev', decisions: 'upgrades', ticks: 5, classify: async (r) => { requests.push(r); return answer(r); } });
  assert.equal(requests.length, 2); assert.equal(requests[0].snapshot.facts.tick, requests[1].snapshot.facts.tick);
  assert.notEqual(requests[0].decisionSeq, requests[1].decisionSeq); assert.notEqual(requests[0].candidates[0].id, requests[1].candidates[0].id);
});

test('heuristic mode never invokes inference and invalid budgets fail before simulation', async () => {
  const result = await runBot(toyGame(), { mode: 'heuristic', ticks: 5, classify: () => assert.fail('Offline mode') });
  assert.deepEqual(result.classifierAttempts, { upgrade: 0, goal: 0 });
  await assert.rejects(runBot(toyGame(), { maxUpgradeRequests: 49, maxGoalRequests: 2 }), /At most 50/);
});

test('a reused entity slot or activation cancels an old spatial plan', () => {
  const goal = { id: 't1:approach_ward:744:11:0:7', kind: 'approach_ward', target: { x: 2000, y: 1800 } };
  const plan = { goal, tick: 1, until: 121 };
  const frame = { tick: 3, px: 1800, py: 1800, bodies: [[2000, 1800, 11, 0, 100, 160, 9, 744, 12]] };
  assert.deepEqual(continuingGoal(plan, frame, [{ ...goal, id: 't3:approach_ward:744:11:0:9' }]), goal.target);
  assert.equal(continuingGoal(plan, { ...frame, bodies: [[2000, 1800, 11, 0, 100, 160, 0, 744, 12]] }, [goal]), null);
  assert.equal(continuingGoal(plan, { ...frame, bodies: [[2000, 1800, 11, 1, 100, 160, 9, 744, 12]] }, []), null);
});

test('a static relic persists across ticks but collection invalidates its goal', () => {
  const goal = { id: 't1:approach_relic:511:9:0:0', kind: 'approach_relic', target: { x: 2400, y: 1800 } };
  const plan = { goal, tick: 1, until: 121 };
  const frame = { tick: 20, px: 1800, py: 1800, bodies: [[2400, 1800, 9, 0, 0, 0, 0, 511, 12]] };
  assert.deepEqual(continuingGoal(plan, frame, [{ ...goal, id: 't20:approach_relic:511:9:0:0' }]), goal.target);
  assert.equal(continuingGoal(plan, { ...frame, bodies: [] }, []), null);
});
