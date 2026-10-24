import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

// Differential birth oracle: old bank identities define logical owner/ordinal
// only. The candidate receives explicit metadata and a different physical ID;
// complete birth state is compared, with its two new Motion metadata fields
// asserted separately. This does not qualify shared request planning/saturation.
const [baselinePath, candidatePath] = process.argv.slice(2);
assert.ok(baselinePath && candidatePath, 'Pass baseline-game.mjs and candidate-game.mjs');
assert.notEqual(resolve(baselinePath), resolve(candidatePath), 'The oracle and candidate must be separate artifacts');
const [{ default: baseline }, { default: candidate }] = await Promise.all([
  import(pathToFileURL(resolve(baselinePath)).href),
  import(pathToFileURL(resolve(candidatePath)).href),
]);
const namespace = module => typeof module.shot_spawn === 'function' ? '' : 'game:';
const api = (module, name) => {
  const value = module[namespace(module) + name];
  assert.equal(typeof value, 'function', `Artifact must expose ${name}`);
  return value;
};
const list = values => values.reduceRight((tail, head) => ({ $: 'Con', head, tail }), { $: 'Nil' });
const plain = value => Array.isArray(value) ? value.map(plain) : value && typeof value === 'object'
  ? Object.fromEntries(Object.entries(value).map(([key, entry]) => [key, plain(entry)])) : value;
const emptyPassives = Array(18).fill(0);
const upgradedPassives = [3, 4, 5, 2, 2, 1, 3, 0, 4, 2, 0, 1, 2, 0, 3, 0, 0, 0];
const profiles = [
  { passives: emptyPassives, meta: 0, arcana: 0, character: 0 },
  { passives: upgradedPassives, meta: 364304237, arcana: 3, character: 5 },
];
const geometries = [
  [],
  [[1950, 1760, 7], [1700, 1900, 9]],
  [[1900, 1800, 41], [1700, 1800, 12], [1800, 1900, 77]], // equal-distance ties preserve input order
];
function args(module, level, tick, profile, geometry, direction, invuln = 0) {
  const bodies = geometry.map(([x, y, seed]) => ({ $: 'Body', x, y, kind: 0, variant: seed % 31, hp: 30, maxHp: 30, age: 18, seed, radius: 12 }));
  const run = { $: 'Run', phase: 0, tick, px: 1800, py: 1800,
    hp: 91, maxHp: 120, xp: 13, xpNeed: 125, level: 3, kills: 17, gold: 23,
    character: profile.character, weapons: list(Array(24).fill(level)), passives: list(profile.passives),
    invuln, seed: 100, stage: 2, arcana: profile.arcana, meta: profile.meta,
    revivals: 2, bosses: 1, mode: 1, rerolls: 3, banishes: 4, skips: 5,
    bannedWeapons: 6, bannedPassives: 7, enemyKinds: list([2, 5]), relicCollected: 1 };
  return { $: 'Args', run, bodies: list(bodies), dx: direction[0], dy: direction[1], snapshots: list([]), hits: list([]) };
}
let comparisons = 0, scheduledComparisons = 0, fired = 0, dormant = 0;
const outputHash = createHash('sha256');
function compare(seed, level, tick, profile, geometry, direction, invuln = 0) {
  const base = Math.floor((seed - 512) / 8), slot = (seed - 512) % 8;
  const schedule = module => api(module, 'scheduled_shot')(base, slot, level, list(profile.passives), tick, profile.meta, profile.arcana, profile.character);
  const expectedSchedule = schedule(baseline), actualSchedule = schedule(candidate);
  assert.equal(actualSchedule, expectedSchedule, `scheduled_shot base=${base} slot=${slot} rank=${level} tick=${tick} arcana=${profile.arcana}`);
  if (level === 0) assert.equal(actualSchedule, false, 'An unowned ordinary scheduled shot stays false; retaliation is separate');
  scheduledComparisons++;
  const expected = plain(api(baseline, 'shot_spawn')(seed, args(baseline, level, tick, profile, geometry, direction, invuln)));
  const physicalSeed = 1023 - (seed - 512);
  const fire = actualSchedule || (profile.arcana === 4 && base === 19 && slot === 0 && invuln > 30 && tick % 12 === 0);
  const actual = plain(api(candidate, 'shot_spawn_assigned')(physicalSeed,
    args(candidate, level, tick, profile, geometry, direction, invuln),
    fire ? {$:'Some',value:{$:'Request',owner:base,slot,level}} : {$:'None'}));
  const metadata = { ownerBase: actual.motion.ownerBase, logicalSlot: actual.motion.logicalSlot };
  assert.deepEqual(metadata, actual.row.body.kind === 1 ? {ownerBase:base,logicalSlot:slot} : {ownerBase:0,logicalSlot:0},
    'Birth records logical metadata independently of the physical pool slot');
  const legacyShape = structuredClone(actual);
  delete legacyShape.motion.ownerBase;delete legacyShape.motion.logicalSlot;
  legacyShape.row.body.seed=seed;
  assert.deepEqual(legacyShape, expected, `shot_spawn seed=${seed} rank=${level} tick=${tick} arcana=${profile.arcana} invuln=${invuln}`);
  assert.equal(actual.$, 'EntityRow');
  if (actual.row.body.kind === 1) fired++; else { assert.equal(actual.row.body.kind, 8); dormant++; }
  outputHash.update(JSON.stringify(actual)); comparisons++;
  return actual;
}
const directions = [[0, 0], [.7, -.4], [3, -2]];
// Every player-shot slot, all weapon ranks 0..9 and union ranks 10..15.
// Cooldown-boundary and adjacent unscheduled ticks come from the baseline API.
for (let level = 0; level <= 15; level++) for (const profile of profiles) for (let seed = 512; seed < 704; seed++) {
  const base = Math.floor((seed - 512) / 8);
  const cooldown = api(baseline, 'cooldown_for')(base, list(profile.passives), profile.meta, profile.arcana, profile.character);
  for (let turn = 0; turn < 8; turn++) compare(seed, level, 1 + cooldown * turn, profile,
    geometries[(turn + base) % geometries.length], directions[(turn + level) % directions.length]);
  compare(seed, level, 2 + cooldown * 2, profile, geometries[seed % geometries.length], directions[level % directions.length]);
}
// Thorn retaliation must survive rank-zero gating; strict invulnerability and
// tick/slot edges also exercise cases where the ordinary scheduled shot is false.
for (const level of [0, 1, 9]) for (const invuln of [0, 30, 31, 70]) for (const tick of [0, 1, 11, 12, 13, 23, 24, 25]) for (const seed of [512, 664, 665]) {
  compare(seed, level, tick, { ...profiles[0], arcana: 4 }, geometries[tick % geometries.length], [0, 0], invuln);
}
const thorn = compare(664, 0, 12, { ...profiles[0], arcana: 4 }, geometries[2], [0, 0], 31);
assert.equal(thorn.row.body.kind, 1, 'Unowned Thorn still fires for Arcana 4 retaliation');
assert.ok(fired > 0 && dormant > 0);
const hash = path => createHash('sha256').update(readFileSync(path)).digest('hex');
console.log(JSON.stringify({ test: 'explicit-shot-birth-differential', comparisons, scheduledComparisons, fired, dormant,
  outputSha256: outputHash.digest('hex'), baselineSha256: hash(baselinePath), candidateSha256: hash(candidatePath) }));
