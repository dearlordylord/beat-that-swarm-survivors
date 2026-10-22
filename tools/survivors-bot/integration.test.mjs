import assert from 'node:assert/strict';
import Game from '../../examples/survivors/dist/bot-actions.mjs';
import { runBot } from './runner.mjs';

// Real public Bend transitions, deliberately fake classifier: proves integration,
// not live backend behavior or gameplay intelligence. No injected game state.
// Offscreen spawning delays first contact; allow 20 simulated seconds for a natural reward.
let preview, committed = 0;
const kinds = new Set();
const observedGame = { ...Game, choose(state, index) {
  const result = Game.choose(state, index), frame = JSON.parse(result.frame);
  assert.ok(preview, 'Every classifier choice has an engine preview');
  for (const key of ['hp', 'maxHp', 'gold', 'weapons', 'passives']) assert.deepEqual(frame[key], preview[key], 'Immediate preview matches actual public choice: ' + key);
  committed++; return result;
} };
const summary = await runBot(observedGame, { mode: 'jev', profile: 'advanced', ticks: 1200, runId: 'offline-real-engine', maxUpgradeRequests: 50, maxGoalRequests: 0, decisions: 'upgrades', classify: async (request) => {
  kinds.add(request.kind);
  assert.equal(request.snapshot.engineMechanics.available, true);
  assert.equal(request.snapshot.engineMechanics.source, 'Bend game functions');
  const candidate = request.candidates.at(-1);
  preview = candidate.effect.enginePreview;
  return { runId: request.runId, decisionSeq: request.decisionSeq, candidatesHash: request.candidatesHash, selectedCandidateId: candidate.id, model: 'offline-fake' };
} });
assert.equal(summary.tick, 1200);
assert.ok(committed >= 1, 'Actual natural progression must reach a classified upgrade: ' + JSON.stringify(summary));
assert.equal(summary.successes.upgrade, committed);
assert.equal(summary.fallbacks, 0);
assert.deepEqual([...kinds], ['upgrade']);
console.log('BOT INTEGRATION PASS: real Bend simulation, natural rewards, fake classifier, exact preview/public-choice agreement; ' + JSON.stringify(summary));
