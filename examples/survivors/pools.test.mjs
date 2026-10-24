import assert from "node:assert/strict";
import { stat } from "node:fs/promises";
import { pathToFileURL } from "node:url";

const artifact = process.env.SURVIVORS_POOLS_ARTIFACT
  ? pathToFileURL(process.env.SURVIVORS_POOLS_ARTIFACT)
  : new URL("./dist/game.mjs", import.meta.url);
assert.ok((await stat(artifact)).mtimeMs >= (await stat(new URL("./pools.bend", import.meta.url))).mtimeMs,
  "Rebuild stale pool configuration");
const { default: exports } = await import(artifact.href);
const get = name => {
  const fn = exports[`pools:${name}`] ?? exports[name];
  assert.equal(typeof fn,"function",`missing pool API ${name}`);
  return fn;
};
const expected = {
  enemy_count:512,enemy_end:512,relic_seed:511,
  player_start:512,player_count:512,player_end:1024,
  hostile_start:1024,hostile_count:32,hostile_end:1056,
  actor_start:1056,actor_count:0,actor_end:1056,
  xp_start:1056,xp_count:400,xp_end:1456,total_count:1456,
  owner_count:24,logical_count:8,normal_enemy_cap:300,max_regular_enemies:500,
};
for(const [name,value] of Object.entries(expected)) assert.equal(get(name)(),value,name);
const roles = ["is_enemy_pool","is_player_shot","is_hostile","is_actor","is_xp"];
const bounds = [[0,512],[512,1024],[1024,1056],[1056,1056],[1056,1456]];
const flag = value => value === true || value?.$ === "True";
const counts = Array(5).fill(0);
for(const seed of [...Array(1458).keys(),1467,1468,0x7fffffff,0xffffffff]) {
  let total=0;
  for(let role=0;role<roles.length;role++) {
    const actual=flag(get(roles[role])(seed));
    assert.equal(actual,seed>=bounds[role][0]&&seed<bounds[role][1],`${roles[role]}(${seed})`);
    total+=Number(actual);
    if(seed<1456) counts[role]+=Number(actual);
  }
  assert.equal(total,Number(seed<1456),`complete disjoint partition ${seed}`);
  assert.equal(flag(get("is_enemy")(seed)),seed<512);
}
assert.deepEqual(counts,[512,512,32,0,400]);
assert.equal(get("actor_start")(),get("actor_end")(),"removed actor interval is empty");
assert.equal(get("actor_end")(),get("xp_start")(),"XP reclaims the old actor boundary immediately");
for(const seed of [1056,1060,1067,1068,1455]) {
  assert.equal(flag(get("is_actor")(seed)),false,`no actor placeholder ${seed}`);
  assert.equal(flag(get("is_xp")(seed)),true,`former actor identity routes to XP ${seed}`);
}
const caps=[60,60,70,40,50,60,60,50,60,40,60,60,60,60,60,60,60,60,60,40,40,40,50,60];
for(let base=0;base<24;base++) assert.equal(get("weapon_cap")(base),caps[base],`weapon ${base}`);
for(const base of [24,25,100,0xffffffff]) assert.equal(get("weapon_cap")(base),0);
console.log("Survivors pool layout: disjoint exhaustive ranges, no actor identities, exact capacities and 24 weapon caps pass");
