import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, writeFile, copyFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
const core = await readFile(new URL('../menu-progression.bend', import.meta.url), 'utf8');
const bend = process.env.BEND || 'bend';
const mutations = [
  ['upgrade gate bypass', 'buy_upgrade', 'boolean(get(upgrade_status(profile,id,catalog),"canBuy"))', 'True{}', 'upgrade_rejected'],
  ['purchase gate bypass', 'purchase', 'boolean(get(purchase_status(profile,kind,id,catalog),"canBuy"))', 'True{}', 'purchase_rejected'],
  ['unknown arcana allowed', 'unlocked_kind', 'case "arcana": Bool.not(is_null(item(catalog,"arcana",id)))', 'case "arcana": True{}', 'arcana_catalog_membership'],
];
for (const [label, name, original, replacement, law] of mutations) test(`proof rejects ${label}`, async () => {
  const directory = await mkdtemp(join(tmpdir(), 'bend-menu-mutant-'));
  try {
    const matcher = new RegExp(`(def ${name}\\([^\\n]*\\n)([\\s\\S]*?)(?=\\ndef |$)`);
    let matched = false;
    const mutated = core.replace(matcher, (match, heading, body) => {
      assert.ok(body.includes(original), `${name} mutation reaches the actual decision`);
      matched = true; return heading + body.replace(original, replacement);
    });
    assert.ok(matched);
    await writeFile(join(directory, 'menu-progression.bend'), mutated);
    await mkdir(join(directory, 'menu-progression'));
    for (const file of ['LAWS.bend', 'PROOF.bend']) await copyFile(new URL(file, import.meta.url), join(directory, 'menu-progression', file));
    const result = spawnSync('bash', ['-c', 'ulimit -t 10; exec "$@"', 'bend-mutant', bend, join(directory, 'menu-progression/PROOF.bend'), '--check-only'], { encoding: 'utf8', timeout: 60000 });
    assert.equal(result.error, undefined);
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.match(result.stdout + result.stderr, new RegExp(`Laws\\.${law}`), 'Failure must be at the targeted law, not a parse/type error');
  } finally { await rm(directory, { recursive: true, force: true }); }
});

// The whole symbolic recording branch exceeds the proof mutation budget.
// Exercise this mutation through the actual compiled transition instead.
test('runtime contract rejects duplicate reward mutation', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'bend-menu-record-mutant-'));
  try {
    const original = 'pick(contains(sequence(get(profile,"recorded")),record_signature(frame)),JObject{["profile","added"],[profile,JSequence{[]}]},recording(profile,frame,catalog))';
    assert.ok(core.includes(original));
    const mutated = core.replace(original, 'pick(False{},JObject{["profile","added"],[profile,JSequence{[]}]},recording(profile,frame,catalog))');
    const source = join(directory, 'menu-progression.bend'), emitted = join(directory, 'menu-progression.mjs');
    await writeFile(source, mutated);
    const result = spawnSync(bend, [source, '-o', emitted], { encoding: 'utf8', timeout: 30000 });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    const [{ default: mutant }, bridge, catalog] = await Promise.all([
      import(new URL(`file://${emitted}`)), import('../progression.mjs'), import('../content.mjs')
    ]);
    const frame = bridge.toBend({ runId: 'duplicate-mutant', character: 0, stage: 0, tick: 60, phase: 3, gold: 10, kills: 1 });
    const definitions = bridge.toBend(catalog);
    const first = bridge.fromBend(mutant.record_run(mutant.fresh(), frame, definitions));
    const second = bridge.fromBend(mutant.record_run(bridge.toBend(first.profile), frame, definitions));
    assert.notDeepEqual(second.profile, first.profile, 'Duplicate reward mutant must violate the complete-profile idempotency contract');
    assert.equal(second.profile.gold, 20);
  } finally { await rm(directory, { recursive: true, force: true }); }
});
