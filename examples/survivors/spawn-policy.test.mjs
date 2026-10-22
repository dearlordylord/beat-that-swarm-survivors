import assert from "node:assert/strict";
import { stat } from "node:fs/promises";

const artifact = new URL("./dist/game.mjs", import.meta.url);
for (const source of ["game.bend", "spawn-policy.bend", "encounters.bend"])
  assert.ok((await stat(artifact)).mtimeMs >= (await stat(new URL(source, import.meta.url))).mtimeMs, `Rebuild stale ${source}`);
const { default: Game } = await import(artifact.href);
const choose = Game["spawn-policy.choose"];
const admit = Game["spawn-policy.admission"];
const accepted = (x, y, px, py, radius) => admit(x, y, px, py, radius).$ === "spawn-policy.Admit";
assert.equal(typeof choose, "function", "Game must import the actual spawn policy");
let checked = 0;
const positions = [20, 20.125, 684, 1800, 2916, 3579.875, 3580];
for (let variant = 0; variant < 31; variant++) {
  const radius = Game["encounters.radius"](variant);
  assert.ok(radius > 0 && radius <= 42, `footprint premise for variant ${variant}`);
  for (const px of positions) for (const py of positions)
    for (const seed of [0, 1, 2, 3, 17, 511, 0xffffffff])
      for (const tick of [0, 1, 21672, 0xffffffff]) {
        const point = choose(seed, tick, px, py, radius);
        const context = JSON.stringify({ variant, px, py, seed, tick, point });
        assert.ok(Number.isFinite(point.x) && Number.isFinite(point.y), context);
        assert.ok(point.x >= 20 && point.x <= 3580 && point.y >= 20 && point.y <= 3580, context);
        // Independent geometry oracle, covering a viewport as large as either
        // renderer supports and the entire sprite/shadow/health-bar envelope.
        const extent = 3 * radius + 24;
        assert.ok(Math.abs(point.x - px) > 512 + extent || Math.abs(point.y - py) > 512 + extent, context);
        assert.equal(accepted(point.x, point.y, px, py, radius), true, context);
        // The real construction used for ordinary enemies and bosses must use
        // this policy too; checking its result prevents a disconnected test.
        const body = Game.enemy_new(seed, tick, px, py, variant, 0, 0);
        assert.equal(body.x, point.x, context);
        assert.equal(body.y, point.y, context);
        // The camera moves in the same frame as spawning. Legal maximum
        // player displacement is 5.5 units/tick; test a conservative six.
        for (const [dx,dy] of [[6,0],[-6,0],[0,6],[0,-6]])
          assert.equal(accepted(point.x,point.y,px+dx,py+dy,radius),true,context);
        checked++;
      }
}
// Admission fails closed independently of candidate selection, including exact
// touching boundaries, arena violations and nonfinite positions.
for (const [x, y] of [[1800, 1800], [2336, 1800], [1264, 1800], [1800, 2336], [1800, 1264], [19, 1800], [3581, 1800], [1800, 19], [1800, 3581], [NaN, 1800], [Infinity, 1800]])
  assert.equal(accepted(x, y, 1800, 1800, 0), false, `reject ${x},${y}`);
assert.equal(accepted(2336.25, 1800, 1800, 1800, 0), true);
assert.equal(accepted(1263.75, 1800, 1800, 1800, 0), true);
const dormant = Game.initial_body(17);
const visibleCandidate = { ...Game.enemy_new(17, 0, 1800, 1800, 0, 0, 0), x: 1800, y: 1800 };
assert.deepEqual(Game.candidate_enemy(visibleCandidate, dormant, 1800, 1800).body, dormant,
  "The actual spawn mutation gate retains the dormant body for a visible candidate");
const safeCandidate = Game.enemy_new(17, 0, 1800, 1800, 0, 0, 0);
assert.deepEqual(Game.candidate_enemy(safeCandidate, dormant, 1800, 1800).body, safeCandidate,
  "The actual spawn mutation gate admits a safe candidate");
assert.deepEqual(Game.dormant_spawn(false, 17, 0, 1800, 1800, 0, 0, 0, dormant).body, dormant,
  "An inactive spawn slot remains dormant");
assert.deepEqual(Game.dormant_spawn(true, 17, 0, 1800, 1800, 0, 0, 0, dormant).body, safeCandidate,
  "An active spawn slot admits the actual offscreen candidate");
// Actual six-tick slot admission must populate all four approach directions.
const sides=new Set();
for(let tick=1;tick<=6;tick++) for(let seed=0;seed<96;seed++) {
  const row=Game.dormant_spawn((tick+seed)%6===0,seed,tick,1800,1800,0,0,0,Game.initial_body(seed));
  if(row.body.kind!==0)continue;
  const dx=row.body.x-1800,dy=row.body.y-1800;
  sides.add(Math.abs(dx)>Math.abs(dy)?(dx>0?'east':'west'):(dy>0?'south':'north'));
}
assert.equal(sides.size,4,'Spawn side selection must not alias the six-tick admission cadence');
// Scheduled bosses and the final Reaper use the same real admission path.
const bossRun=Game.start(0,0).state.run;
for (const finale of [false,true]) for (let stage=0;stage<5;stage++) {
  const boss=Game.update_selected(true,finale,dormant,bossRun,0,finale?36000:7200,20,20,stage).body;
  assert.equal(boss.kind,0);
  assert.equal(accepted(boss.x,boss.y,20,20,boss.radius),true);
}
console.log(`Spawn policy: ${checked} actual enemy placements, all 31 variants, arena edges/corners, strict complete-appearance admission passed.`);
