import { createHash, randomUUID } from 'node:crypto';
import { buildUpgradeDecision, resolveCandidate, buildGoalDecision, resolveGoalCandidate } from './context.mjs';
import { createPlanner, planMovement, advisePlanner } from './planner.mjs';

export function heuristicUpgrade(frame) {
  const weapons = [4, 19, 10, 0, 2, 17], passives = [11, 1, 6, 2, 0, 7];
  const score = (o) => {
    if ([3, 5].includes(o.kind)) return 1000;
    if (o.kind === 0 && weapons.includes(o.id)) return (o.id === 4 ? 260 : 170) + (frame.weapons[o.id] > 0 ? 30 : 0) - weapons.indexOf(o.id);
    if (o.kind === 1 && passives.includes(o.id)) return 210 - passives.indexOf(o.id) * 5 + (frame.passives[o.id] === 0 ? 20 : 0);
    if (o.kind === 2) return frame.hp < frame.maxHp * 0.7 ? 300 : 10;
    return o.kind === 4 ? 5 : -100;
  };
  if (!frame.offers.length) throw new Error('Pending reward has no actual offers');
  return frame.offers.reduce((best, o, i) => score(o) > score(frame.offers[best]) ? i : best, 0);
}

export function steering(frame, target, mechanics = {}) {
  const enemies = frame.bodies.filter((b) => b[2] === 0 && b[4] > 0);
  const nearest = enemies.reduce((best, b) => Math.hypot(b[0] - frame.px, b[1] - frame.py) < Math.hypot(best[0] - frame.px, best[1] - frame.py) ? b : best, enemies[0] ?? [frame.px + 300, frame.py]);
  const stats=mechanics.current?.weaponStats ?? [];
  const closeOnly=enemies.length>0 && stats.length>0 && stats.every(w=>w.selfFieldRadius>0);
  const aura=closeOnly ? Math.max(...stats.map(w=>w.selfFieldRadius)) : 0;
  const desired=closeOnly ? Math.max((nearest[8]??12)+26,aura+(nearest[8]??12)-6) : 220;
  const nx = frame.px - nearest[0], ny = frame.py - nearest[1], nd = Math.max(1, Math.hypot(nx, ny));
  let dx = target ? target.x - frame.px : nx / nd * (closeOnly ? Math.max(-30,Math.min(30,desired-nd)) : Math.max(0, 220-nd)) * 6 + ny / nd * (closeOnly?12:35) + (1800 - frame.px) * 0.05;
  let dy = target ? target.y - frame.py : ny / nd * (closeOnly ? Math.max(-30,Math.min(30,desired-nd)) : Math.max(0, 220-nd)) * 6 - nx / nd * (closeOnly?12:35) + (1800 - frame.py) * 0.05;
  for (const b of frame.bodies) {
    if (![0, 7].includes(b[2])) continue;
    const x = frame.px - b[0], y = frame.py - b[1], d = Math.max(1, Math.hypot(x, y));
    const avoidance=closeOnly && b[2]===0 ? (b[8]??12)+26 : 140;
    const force=Math.max(0,avoidance-d)*(closeOnly && b[2]===0 ? 12 : 4);
    dx += x / d * force; dy += y / d * force;
  }
  dx += (frame.px < 200 ? 1000 : 0) - (frame.px > 3400 ? 1000 : 0);
  dy += (frame.py < 200 ? 1000 : 0) - (frame.py > 3400 ? 1000 : 0);
  const length = Math.max(1, Math.hypot(dx, dy));
  return [dx / length, dy / length];
}

export async function runBot(Game, {
  mode = 'heuristic', profile = 'fresh', ticks = 1800, decisions = 'both', seed = 12345,
  maxUpgradeRequests = 6, maxGoalRequests = 2, timeoutMs = 2000,
  classify, emit = () => {}, runId = randomUUID(),
} = {}) {
  if (!['heuristic', 'jev'].includes(mode) || !['fresh', 'advanced'].includes(profile) || !['upgrades', 'both'].includes(decisions)) throw new Error('Invalid bot mode/profile/decision policy');
  for (const [name, n, max] of [['ticks', ticks, 37000], ['maxUpgradeRequests', maxUpgradeRequests, 50], ['maxGoalRequests', maxGoalRequests, 50], ['timeoutMs', timeoutMs, 10000]]) if (!Number.isSafeInteger(n) || n < (name === 'ticks' || name === 'timeoutMs' ? 1 : 0) || n > max) throw new Error('Invalid bounded option: ' + name);
  if (maxUpgradeRequests + maxGoalRequests > 50) throw new Error('At most 50 classifier requests per run');
  if (mode === 'jev' && typeof classify !== 'function') throw new Error('Explicit classifier dependency required');
  if(!Number.isSafeInteger(seed)||seed<0||seed>0xffffffff) throw new Error('Invalid U32 seed');
  const accept = (packet) => {
    if (packet.$ !== 'Packet') throw new Error('Bend simulation rejected a transition');
    // Each transition already serialized this frame. Consume that Packet once
    // instead of asking G.packet to serialize the same owned world again.
    const observed = typeof Game.observed_packet === 'function'
      ? Game.observed_packet(packet) : Game.observe(packet.state);
    if (observed.$ !== 'Observed') throw new Error('Bend observation failed');
    if (typeof observed.mechanics !== 'string') throw new Error('Rebuild bot facade: engine mechanics are required');
    const frame = JSON.parse(observed.frame);
    if (!Number.isFinite(frame.px) || !Number.isFinite(frame.py) || frame.hp > frame.maxHp) throw new Error('Invalid Bend observation');
    return { state: observed.state, frame, catalog:JSON.parse(observed.actions), engineMechanics:JSON.parse(observed.mechanics) };
  };
  const startSeed=profile==='fresh'?Game.fresh_start_seed:Game.advanced_start_seed;
  if(!startSeed && seed!==12345) throw new Error('Rebuild bot facade for explicit seed control');
  let current = accept(startSeed ? startSeed(seed) : profile === 'fresh' ? Game.fresh_start() : Game.advanced_start());
  let sequence = 0, nextGoalTick = 1, lastAdviceTick = -300, choices = 0, goals = 0, fallbacks = 0, waitMs = 0, maxLiving = 0, firstRewardTick = null;
  const plannerMemory=createPlanner();
  const calls = { upgrade: 0, goal: 0 }, successes = { upgrade: 0, goal: 0 }, history = [];
  const meta = profile === 'fresh' ? 0 : 364304237, started = performance.now();
  emit({ type: 'start', runId, mode, profile, decisions, ticks, maxUpgradeRequests, maxGoalRequests, timeoutMs, seed, seedControl: startSeed?'explicit U32 seed':'legacy fixed seed', initial: { hp: current.frame.hp, character: current.frame.character, arcana: current.frame.arcana } });
  async function select(request, resolve, fallback, catalog) {
    let selected = fallback, source = 'heuristic', reason;
    const ceiling = request.kind === 'upgrade' ? maxUpgradeRequests : maxGoalRequests;
    let answer;
    if (mode === 'jev' && request.candidates.length > 1 && calls[request.kind] < ceiling) {
      calls[request.kind]++;
      const start = performance.now();
      try {
        answer = await classify(request, { timeoutMs });
        selected = resolve(request, answer, current.frame, catalog);
        source = 'classifier'; successes[request.kind]++;
      } catch (error) {
        reason = ['timeout', 'missing-credential', 'provider-unavailable', 'invalid-request'].includes(error?.code) ? error.code : 'invalid-or-stale-response';
        source = 'fallback'; fallbacks++;
      }
      waitMs += performance.now() - start;
    } else if (mode === 'jev') {
      source = request.candidates.length === 1 ? 'only-legal-candidate' : 'budget-fallback';
      if (source === 'budget-fallback') fallbacks++;
    }
    if(request.kind==='goal' && source==='classifier' && !advisePlanner(plannerMemory,selected.id)) throw new Error('Selected goal is not a current planner candidate');
    emit({ type: 'decision', request, result: { source, reason, selected, response: answer && { selectedCandidateId: answer.selectedCandidateId, model: answer.model, latencyMs: answer.latencyMs, usage: answer.usage, probabilities: answer.probabilities } } });
    return selected;
  }
  // Bound choice processing as well as simulation ticks: no infinite menu loop.
  for (let fuel = 0; fuel < ticks * 4 + 100 && current.frame.tick < ticks && ![3, 4].includes(current.frame.phase); fuel++) {
    const {frame,catalog,engineMechanics}=current;
    maxLiving = Math.max(maxLiving, frame.bodies.filter((b) => b[2] === 0 && b[4] > 0).length);
    if (history.length === 0 || frame.tick - history.at(-1).tick >= 30 || history.at(-1).hp !== frame.hp) history.push({ tick: frame.tick, hp: frame.hp });
    while (history.length > 32) history.shift();
    if ([1, 2].includes(frame.phase)) {
      firstRewardTick ??= frame.tick;
      const options = { runId, decisionSeq: ++sequence, meta, history, engineMechanics };
      const request = buildUpgradeDecision(frame, options);
      const index = await select(request, (r, a, f) => resolveCandidate(r, a, f, options), heuristicUpgrade(frame));
      history.push({ tick: frame.tick, hp: frame.hp, action: 'choose_upgrade', offer: frame.offers[index] });
      const state = current.state; current.state = undefined;
      current = accept(Game.choose(state, index)); choices++;
      continue;
    }
    let spatial=planMovement(plannerMemory,frame,catalog,engineMechanics);
    const urgent=['target-gone','damage','stuck'].includes(spatial.reason) && frame.tick-lastAdviceTick>=60;
    if (mode==='jev' && decisions === 'both' && (frame.tick >= nextGoalTick || urgent) && spatial.candidates.length>=2) {
      const options = { runId, decisionSeq: ++sequence, meta, history, engineMechanics,planner:spatial };
      const request = buildGoalDecision(frame, catalog, options);
      const fallback=spatial.chosen?.goal ?? null;
      const goal = await select(request, (r, a, f, c) => resolveGoalCandidate(r, a, f, c, options), fallback, catalog);
      spatial=planMovement(plannerMemory,frame,catalog,engineMechanics); goals++;
      history.push({ tick: frame.tick, hp: frame.hp, action: 'choose_goal', goal: goal?.kind??'retain_combat', target: goal?.target??null });
      nextGoalTick = frame.tick + 300; lastAdviceTick=frame.tick;
    }
    const target=spatial.target;
    const [dx, dy] = steering(frame, target, engineMechanics);
    const state = current.state; current.state = undefined;
    current = accept(Game.advance(state, dx, dy));
  }
  const f = current.frame;
  maxLiving = Math.max(maxLiving, f.bodies.filter((b) => b[2] === 0 && b[4] > 0).length);
  const summary = { type: 'summary', runId, mode, profile, decisions, seed, tick: f.tick, simulatedSeconds: f.tick / 60, phase: f.phase, hp: f.hp, level: f.level, xp:f.xp, xpNeed:f.xpNeed, uncollectedBaseXp:f.bodies.filter(b=>b[2]===2).reduce((sum,b)=>sum+b[4],0), xpPiles:f.bodies.filter(b=>b[2]===2).length, kills: f.kills, gold: f.gold, evolvedWeapons: f.weapons.filter((rank) => rank >= 9).length, choices, goals, firstRewardTick, maxLiving, classifierAttempts: calls, successes, fallbacks, classifierWaitMs: waitMs, wallMs: performance.now() - started, outcome: [3, 4].includes(f.phase) ? 'terminal' : 'bounded-observation', planner:{knownResources:Object.keys(plannerMemory.objects).length,clusters:plannerMemory.clusters.length,current:plannerMemory.current?.clusterId??null}, lastFrameHash: createHash('sha256').update(JSON.stringify(f)).digest('hex') };
  emit(summary);
  return summary;
}
