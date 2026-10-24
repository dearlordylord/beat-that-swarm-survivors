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
  actor_start:1056,actor_count:12,actor_end:1068,
  xp_start:1068,xp_count:400,xp_end:1468,total_count:1468,
  owner_count:24,logical_count:8,normal_enemy_cap:300,max_regular_enemies:500,
};
for(const [name,value] of Object.entries(expected)) assert.equal(get(name)(),value,name);
const roles = ["is_enemy_pool","is_player_shot","is_hostile","is_actor","is_xp"];
const bounds = [[0,512],[512,1024],[1024,1056],[1056,1068],[1068,1468]];
const flag = value => value === true || value?.$ === "True";
const counts = Array(5).fill(0);
for(const seed of [...Array(1470).keys(),0xffffffff]) {
  let total=0;
  for(let role=0;role<roles.length;role++) {
    const actual=flag(get(roles[role])(seed));
    assert.equal(actual,seed>=bounds[role][0]&&seed<bounds[role][1],`${roles[role]}(${seed})`);
    total+=Number(actual);
    if(seed<1468) counts[role]+=Number(actual);
  }
  assert.equal(total,Number(seed<1468),`complete disjoint partition ${seed}`);
  assert.equal(flag(get("is_enemy")(seed)),seed<512);
}
assert.deepEqual(counts,[512,512,32,12,400]);
const caps=[60,60,70,40,50,60,60,50,60,40,60,60,60,60,60,60,60,60,60,40,40,40,50,60];
for(let base=0;base<24;base++) assert.equal(get("weapon_cap")(base),caps[base],`weapon ${base}`);
for(const base of [24,25,100,0xffffffff]) assert.equal(get("weapon_cap")(base),0);
console.log("Survivors pool layout: disjoint exhaustive ranges, exact capacities and 24 weapon caps pass");
