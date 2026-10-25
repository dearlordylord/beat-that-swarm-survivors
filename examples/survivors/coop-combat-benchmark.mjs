#!/usr/bin/env node
// Diagnostic fixtures only. Physics always comes from compiled Bend modules.
import { performance } from 'node:perf_hooks';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const args = process.argv.slice(2);
if (![0, 2].includes(args.length) || (args.length && args[0] !== '--variant')) {
  throw new Error('Usage: node coop-combat-benchmark.mjs [--variant ballistic|mixed-area]');
}
const variant = args[1] ?? 'ballistic';
if (!['ballistic', 'mixed-area'].includes(variant)) throw new Error(`Unknown variant: ${variant}`);
const moduleDir = process.env.COOP_LATENCY_MODULE_DIR
  ? pathToFileURL(`${resolve(process.env.COOP_LATENCY_MODULE_DIR)}/`)
  : new URL('./dist/web/dist/', import.meta.url);
const combatUrl = process.env.COOP_COMBAT_MODULE
  ? (/^file:/.test(process.env.COOP_COMBAT_MODULE)
    ? new URL(process.env.COOP_COMBAT_MODULE)
    : pathToFileURL(resolve(process.env.COOP_COMBAT_MODULE)))
  : new URL('coop-combat-prediction.mjs', moduleDir);
const [{ default: Core }, { default: C }, { default: P }, { default: S }] = await Promise.all([
  import(new URL('coop-core.mjs', moduleDir)),
  import(combatUrl),
  import(new URL('coop-prediction.mjs', moduleDir)),
  import(new URL('coop-session.mjs', moduleDir)),
]);
const list = values => values.reduceRight((tail, head) => ({ $: 'Con', head, tail }), { $: 'Nil' });
const array = values => {
  const result = [];
  for (let node = values; node.$ === 'Con'; node = node.tail) result.push(node.head);
  return result;
};

// Keep these setup operations and coordinates identical to the original frozen
// /tmp/bendvy-combat-perf.mjs diagnostic. The mixed variant changes pierce only.
let state = Core.core_join(Core.core_start(0, 0, 1).state, 0, 0, 0).state;
state = Core.core_step(state, 0, 0, 0, 0).state;
const initial = Core.core_observe(state, 1).observation.forecast;
const source = array(initial.snapshots).find(snapshot => snapshot.$ === 'ProjectileSnapshot');
if (!source) throw new Error('Fixture bootstrap has no projectile snapshot');
const enemies = Array.from({ length: 400 }, (_, i) => ({
  $:'EnemySnapshot',enemy:{$:'State',identity:i,archetype:1,
    spatial:{$:'Spatial',x:7000+(i%20)*40,y:6800+Math.floor(i/20)*40,age:1,radius:8},
    vitals:{$:'Vitals',health:100000,maximum:100000},
    status:{$:'Status',slow:{$:'Slow',ticks:0,frozen:false},burn:{$:'Burn',ticks:0,sourcePlayer:{$:'None'}}}},
}));
const shots = Array.from({ length: 100 }, (_, i) => ({
  $:'ProjectileSnapshot',projectile:{$:'State',identity:512+i,side:{$:'PlayerShot'},
    spatial:{$:'Spatial',x:6200+(i%10)*10,y:6200+Math.floor(i/10)*10,age:1,radius:5},
    payload:{$:'ShotPayload',weapon:0,damage:11,active:true},
    trajectory:{$:'Trajectory',vx:7.5,vy:0,life:1000,
      pierce:variant==='mixed-area'&&i%4===0?9999:50,visited:list([]),weaponOwner:0,
      logicalSlot:Math.floor(i/2)%8,sourcePlayer:{$:'Some',value:i%2}}},
}));
const scene = C.receive(C.initialize(1, initial.tick, initial.players, list([...enemies, ...shots])), S.fresh(123));
const own = array(scene.players).find(player => player.id === 1).run;
let input = P.fresh(own.player.px, own.player.py, 2.5, true, scene.tick, 0);
for (let i = 1; i <= 30; i++) input = P.tick(P.command(input, i, 2, 1));
const forecastMs = [];
let warmupForecastMs;
let warmupLiveSnapshots;
for (let i = 0; i < 5; i++) {
  const started = performance.now();
  const forecast = C.forecast(scene, input);
  const elapsed = performance.now() - started;
  if (i) forecastMs.push(elapsed);
  else {
    warmupForecastMs = elapsed;
    warmupLiveSnapshots = array(forecast.snapshots).length;
  }
}
const stepMs = [];
for (let i = 0; i < 7; i++) {
  const started = performance.now();
  C.advance(scene, 2, 1);
  stepMs.push(performance.now() - started);
}
// Upper middle of four forecasts, matching the original diagnostic exactly.
const medianForecastMs = forecastMs.toSorted((a, b) => a - b)[2];
const medianStepMs = stepMs.toSorted((a, b) => a - b)[3];
console.log(JSON.stringify({
  schemaVersion: 1, variant, enemies: 400, knownShots: 100,
  ballisticShots: variant === 'ballistic' ? 100 : 75,
  areaShots: variant === 'ballistic' ? 0 : 25,
  pendingTicks: 30, snapshotHz: 20, localStepHz: 60,
  moduleDir: moduleDir.href, combatModule: combatUrl.href,
  warmupForecastMs, warmupLiveSnapshots, forecastMs, stepMs,
  medianForecastMs, medianStepMs,
  estimatedCpuMsPerSecond: medianForecastMs * 20 + medianStepMs * 60,
  scope: 'Single diagnostic fixture on this host; no performance acceptance or statistical speed claim. No rendering or per-tick JSON serialization.',
}, null, 2));
