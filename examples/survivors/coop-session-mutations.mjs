import assert from 'node:assert/strict';
import { readFile,mkdtemp,writeFile,copyFile,rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { dirname,join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
const app=dirname(fileURLToPath(import.meta.url));
const source=await readFile(join(app,'coop-session.bend'),'utf8');
const policyLine=source.split('\n').find(line=>line.includes('Bool.and(Bool.not(ended),Bool.and(Bool.or(U32.is_eq(peer,0),connected)'));
assert.ok(policyLine,'policy definition disappeared');
const mutations=[
  ['policy rejects everything',policyLine,'      False{}'],
  ['duplicate admitted','U32.is_gt(seq,last_seq(lane_at(player,host,guest)))','U32.is_ge(seq,last_seq(lane_at(player,host,guest)))'],
  ['owner check bypassed','U32.is_eq(peer,player)','True{}'],
  ['input expires one tick late','(clock - received : U32),18','(clock - received : U32),19'],
  ['reject all fresh input','receive_decided(valid_command(state,peer,command),state,command)','receive_decided(False{},state,command)'],
];
const directory=await mkdtemp(join(tmpdir(),'bendvy-coop-mutants-'));
try {
  for(const [i,[name,before,after]] of mutations.entries()) {
    assert.ok(source.includes(before),`mutation target disappeared: ${name}`);
    const work=join(directory,String(i));
    await (await import('node:fs/promises')).mkdir(work);
    const src=join(work,'coop-session.bend');
    await writeFile(src,source.replaceAll(before,after));
    const compilation=spawnSync(process.env.BEND||'bend',[src,'-o',join(work,'coop-session.mjs')],{encoding:'utf8',timeout:10000});
    assert.equal(compilation.status,0,`${name}: mutant must compile\n${compilation.stderr}`);
    for(const module of ['coop-protocol','coop-network-emulator'])await copyFile(join(process.env.COOP_TEST_DIST,`${module}.mjs`),join(work,`${module}.mjs`));
    const result=spawnSync(process.execPath,['--test',join(app,'coop-session.test.mjs')],{encoding:'utf8',timeout:30000,env:{...process.env,COOP_TEST_DIST:work}});
    assert.notEqual(result.status,0,`${name}: mutant survived`);
    assert.match(result.stdout,/fail [1-9]/,`${name}: test suite did not execute\n${result.stderr}`);
    console.log(`KILLED ${name}`);
  }
} finally { await rm(directory,{recursive:true,force:true}); }
