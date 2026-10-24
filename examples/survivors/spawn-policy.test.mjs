import assert from "node:assert/strict";
import { stat } from "node:fs/promises";

const artifact = new URL("./dist/game.mjs", import.meta.url);
for (const source of ["game.bend", "spawn-policy.bend", "encounters.bend", "viewport.bend", "spawn-lifecycle.bend"])
  assert.ok((await stat(artifact)).mtimeMs >= (await stat(new URL(source, import.meta.url))).mtimeMs, `Rebuild stale ${source}`);
const { default: Game } = await import(artifact.href);
const choose = Game["spawn-policy:choose"];
const admit = Game["spawn-policy:admission"];
const accepted = (x, y, px, py, radius) => admit(x, y, px, py, radius).$ === "Admit";
assert.equal(typeof choose, "function", "Game must import the actual spawn policy");
let checked = 0;
const positions = [20, 20.125, 684, 1800, 2916, 3579.875, 3580];
for (let variant = 0; variant < 31; variant++) {
  const radius = Game["encounters:radius"](variant);
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
        // Independent actual native projection, including its asymmetric hero
        // anchor. App stretches this fixed Image at every window aspect ratio.
        const nativeX = Math.fround(Math.fround(Math.fround(point.x - px) * Math.fround(.65)) + 256);
        const nativeY = Math.fround(Math.fround(Math.fround(point.y - py) * Math.fround(.65)) + 210);
        const nativeEnvelope = extent * .65;
        assert.ok(nativeX + nativeEnvelope < 0 || nativeX - nativeEnvelope > 512 ||
          nativeY + nativeEnvelope < 0 || nativeY - nativeEnvelope > 512, context);
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
assert.deepEqual(Game.dormant_spawn(false, 17, 12345, 0, 1800, 1800, 0, 0, 0, dormant).body, dormant,
  "An inactive spawn slot remains dormant");
assert.deepEqual(Game.dormant_spawn(true, 17, 12345, 0, 1800, 1800, 0, 0, 0, dormant).body, safeCandidate,
  "An active spawn slot admits the actual offscreen candidate");
// Actual six-tick slot admission must populate all four approach directions.
const sides=new Set();
for(let tick=1;tick<=6;tick++) for(let seed=0;seed<96;seed++) {
  const row=Game.dormant_spawn((tick+seed)%6===0,seed,12345,tick,1800,1800,0,0,0,Game.initial_body(seed));
  if(row.body.kind!==0)continue;
  const dx=row.body.x-1800,dy=row.body.y-1800;
  sides.add(Math.abs(dx)>Math.abs(dy)?(dx>0?'east':'west'):(dy>0?'south':'north'));
}
assert.equal(sides.size,4,'Spawn side selection must not alias the six-tick admission cadence');
// Scheduled bosses and the final Reaper use the same real admission path.
const bossRun=Game.start(0,0).state.run;
for (const finale of [false,true]) for (let stage=0;stage<5;stage++) {
  const boss=Game.update_selected(true,finale,dormant,bossRun,0,12345,finale?36000:7200,20,20,stage).body;
  assert.equal(boss.kind,0);
  assert.equal(accepted(boss.x,boss.y,20,20,boss.radius),true);
}
console.log(`Spawn policy: ${checked} actual enemy placements, all 31 variants, arena edges/corners, strict complete-appearance admission passed.`);
// Exercise the native consumer's actual live advancement, not only the pure
// placement helper. Every enemy-pool slot is observed before and after every
// step; projection uses the post-step camera (the player moves during the step).
const bodyList = value => {
  const result=[];
  for(let node=value;node.$==='Con';node=node.tail) result.push(node.head);
  return result;
};
let liveSpawns=0;
for(const [px,py] of [[20,20],[20,3580],[1800,1800],[3580,20],[3580,3580]])
  for(const startTick of [0,21600,35994]) {
    let packet=Game.start_seed(0,0,12345);
    packet.state.run={...packet.state.run,px,py,tick:startTick};
    const seen=new Set();
    for(let step=0;step<6;step++) {
      const before=new Map(bodyList(packet.state.bodies).map(body=>[body.seed,body.kind]));
      packet=Game.advance_live(packet.state,step%2? -1:1,step%2?1:-1);
      assert.equal(packet.$,'Packet','actual live advance must succeed');
      const run=packet.state.run;
      for(const body of bodyList(packet.state.bodies)) {
        if(body.seed>=Game.pool_enemy_count() || body.kind!==0 || before.get(body.seed)===0) continue;
        const context=JSON.stringify({px,py,startTick,step,body,runPx:run.px,runPy:run.py});
        assert.equal(accepted(body.x,body.y,run.px,run.py,body.radius),true,context);
        const x=(body.x-run.px)*.65+256,y=(body.y-run.py)*.65+210;
        const envelope=(3*body.radius+24)*.65;
        assert.ok(x+envelope<0||x-envelope>512||y+envelope<0||y-envelope>512,context);
        seen.add(body.seed);liveSpawns++;
      }
    }
    if(startTick===21600) {
      // normal_entity reserves pool identity511 for relic_entity; it is not an
      // enemy slot even though the admission budget has a physical pool of512, including the reserved relic.
      assert.deepEqual([...seen].sort((a,b)=>a-b),Array.from({length:300},(_,i)=>i),
        'Normal dense fixture observes all 300 admitted enemies, including boss identity0');
      assert.notEqual(bodyList(packet.state.bodies).find(body=>body.seed===Game.pool_relic_seed())?.kind,0,
        'Reserved relic identity511 must never be counted as an enemy');
    }
  }
console.log(`Native live spawning: ${liveSpawns} actual non-enemy → enemy transitions checked against the post-step camera.`);
