import test from 'node:test';
import assert from 'node:assert/strict';
import { runBot, steering } from './runner.mjs';

// Deliberately tiny fake affine world: these tests exercise orchestration,
// not actual game balance. actions.test.mjs separately drives real Bend.
function toyGame({ queued = false } = {}) {
  const consumed = new WeakSet(); let lastTick = 0, chosen = 0;
  const initial = { tick: 0, phase: 0, px: 1800, py: 1800, hp: 70, maxHp: 70, xp: 0, xpNeed: 100, level: 1, kills: 0, gold: 0, character: 0, arcana: 0, stage: 0, mode: 0, runLength: 36000, rerolls: 3, banishes: 3, skips: 3, weapons: [1, ...Array(23).fill(0)], passives: Array(18).fill(0), bodies: [], offers: [] };
  const offers = [{ kind: 0, id: 0, level: 2 }, { kind: 1, id: 7, level: 1 }];
  const take = (state) => { assert.ok(!consumed.has(state), 'An owned state cannot be reused'); consumed.add(state); return structuredClone(state.frame); };
  const packet = (frame) => { lastTick = frame.tick; return { $: 'Packet', state: { frame }, frame: JSON.stringify(frame) }; };
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

test('self-field-only builds approach attack reach, retreat from contact and retain projectile avoidance',()=>{
 const frame={px:1800,py:1800,bodies:[[2000,1800,0,0,10,10,0,1,12]]};
 const close={current:{weaponStats:[{id:4,rank:1,selfFieldRadius:46.125}]}};
 assert.ok(steering(frame,null,close)[0]>0,'Aura-only bot approaches enemies outside actual field reach');
 assert.ok(steering({...frame,bodies:[[1200,1800,0,0,10,10,0,1,12]]},null,close)[0]<0,'Seek the actual far-left enemy rather than a synthetic target');
 assert.ok(steering(frame,null)[0]<0,'Default ranged kiting remains unchanged');
 assert.ok(steering({...frame,bodies:[[1820,1800,0,0,10,10,0,1,12]]},null,close)[0]<0,'Avoid body contact');
 assert.ok(steering({...frame,bodies:[[2000,1800,0,0,10,10,0,1,12],[1810,1800,7,0,10,10,0,704,6]]},null,close)[0]<0,'Dodge close hostile shots even while seeking attack range');
 const mixed={current:{weaponStats:[{selfFieldRadius:46},{selfFieldRadius:0}]}};
 assert.ok(steering(frame,null,mixed)[0]<0,'Mixed/ranged builds retain kiting');
});


test('explicit U32 seeds reach the engine and invalid or unsupported seeds fail before play',async()=>{
 const game=toyGame();let received;
 game.fresh_start_seed=seed=>{received=seed;return game.fresh_start()};
 const result=await runBot(game,{ticks:5,seed:987654,mode:'heuristic'});
 assert.equal(received,987654);assert.equal(result.seed,987654);
 await assert.rejects(runBot(toyGame(),{seed:1,ticks:1}),/explicit seed control/);
 for(const seed of [-1,2**32,NaN,1.2]) await assert.rejects(runBot(toyGame(),{seed,ticks:1}),/U32 seed/);
});


test('packet observation consumes one affine owner and preserves legacy replay outcomes',async()=>{
 const baseline=await runBot(toyGame({queued:true}),{ticks:8,mode:'jev',runId:'reuse',classify:async r=>answer(r,1)});
 const game=toyGame({queued:true}),legacyObserve=game.observe;
 let packets=0;
 game.observed_packet=packet=>{
  assert.equal(packet.$,'Packet');packets++;
  const observed=legacyObserve(packet.state);
  assert.equal(observed.frame,packet.frame,'Catalog and mechanics correspond to this exact transition frame');
  return {...observed,frame:packet.frame};
 };
 game.observe=()=>assert.fail('The existing Packet must not be observed/serialized a second time');
 const actual=await runBot(game,{ticks:8,mode:'jev',runId:'reuse',classify:async r=>{
  if(r.kind==='goal')assert.ok(r.candidates.every(c=>c.goal.observedTick===r.snapshot.facts.tick));
  return answer(r,1);
 }});
 assert.equal(packets,1+actual.tick+actual.choices,'One observation for initial state and every actual transition');
 for(const key of ['lastFrameHash','tick','phase','hp','level','kills','choices','firstRewardTick'])assert.deepEqual(actual[key],baseline[key],key);
});

test('a failing packet observer is rejected without falling back to a second owner access',async()=>{
 const game=toyGame();
 game.observed_packet=()=>({$:'ObserveFailed'});
 game.observe=()=>assert.fail('Fallback is allowed only when the packet API is absent');
 await assert.rejects(runBot(game,{ticks:1}),/Bend observation failed/);
});
