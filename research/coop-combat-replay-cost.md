# Cooperative combat replay: dense Node CPU profile

One diagnostic run; no production edits, rebuild, heap snapshot, or performance acceptance. The emitted Scene predates the F32 hydration correction; its physics path is the requested frozen diagnostic subject. Source references describe the inspected algorithm, not proof that later live edits match this emission.

Fixture: 400 enemies, 100 known projectiles, 30 pending ticks; five forecasts (first warmup) and seven one-step probes. Profile wall-sample span 3771.2 ms, 1650 samples. Forecast median 652.63 ms, single-step median 21.28 ms. At the requested 20 snapshots/s plus 60 local steps/s the arithmetic estimate is 14.33 seconds of main-thread work per second. This is an overload diagnostic, not a statistical speed claim; previous unprofiled 793 ms is not a controlled baseline.

| Function | Self % | Inclusive % |
|---|---:|---:|
| `$game_at` | 21.98 | 24.91 |
| `$game_effect_indexed_hits` | 18.62 | 19.53 |
| `$game_effect_indexed_killer` | 15.55 | 16.02 |
| `(garbage collector)` | 11.7 | 11.7 |
| `$projectile_contact_contacts` | 5.09 | 5.17 |
| `$game_nearest` | 2.92 | 2.95 |
| `word_to_u32` | 2.86 | 2.86 |
| `$game_collisions` | 2.55 | below top40 |
| `(program)` | 1.71 | below top40 |
| `$body_index_find_item_3` | 1.43 | below top40 |

`effect_apply_indexed` / `effect_apply_multiple` account for 66.26% inclusive; `effect_gather` 44.30%. `contact_team` is 3.63% inclusive, `Contact.contacts` 5.17%, nearest 2.95%. V8 optimization/inlining causes incomplete/asymmetric parent attribution; overlapping inclusive columns must not be summed. Self costs are the stronger prioritization evidence. The profile includes startup/warmup and the seven step probes, not exclusively steady-state forecast.

## Algorithmic work and allocations

`game.bend:1221` effect_indexed_hits filters the entire hit list by originating player for every enemy. With E=400, H=100, P=2 that is P×E×H=80,000 plan inspections per tick before newly spawned plans. The emitted JS reconstructs a HitPlan object even for rejected entries and a Cons for retained entries: approximately 80,000 HitPlan objects and 40,000 retained Cons cells per tick when the two owner buckets partition these hits. This is a static allocation-site count, not a measured allocation census. Index lookups also occur on every inspected hit.

`effect_apply_multiple` computes effect_indexed_killer twice for each enemy (killer attribution and luck-source stats). At these sizes that is 80,000 additional list visits/tick, with two hit_recipient expressions per visit. It also executes collisions on each owner-filtered list: roughly another 40,000 hit visits. Passive rank lookups via game.at are repeated inside effect_one_effects and luck; rank16 list traversal and identical stat arithmetic recur even for zero knock. These are the measured dominant paths. GC is 11.70% self; CPU profiling alone cannot assign its bytes to a particular constructor.

`contact_team` scans approximately 100×400=40,000 ballistic shot/target pairs/tick, invokes exact swept contacts, and keeps deterministic impact-time/seed order. At 30 replay ticks that is 1.2 million pairs/forecast before additional births. The contact solver is real work but does not explain most current CPU cost. Existing projectiles/contact planning/witness construction can independently recompute projectile next state and nearest aim. nearest is only 2.95% inclusive here.

There is no per-replay-tick JSON serialization in this benchmark. It calls forecast/advance and never render/native_scene; only initial core_observe parse and final scalar report use JSON. Witness computation still runs: step_witnesses rebuilds target geometry twice, builds snapshot/target indices, and recomputes shot next/nearest for accepted targets. Witnesses are absent from the top40 profile entries, so blaming witness JSON for this measurement is unsupported.

## Concrete optimization order, preserving the full cohort

1. Build immutable per-tick owner hit buckets and player combat context once. Keep each bucket in exactly original HitPlan order, retain duplicates and origin fallback, and pass cached scalar rank16/luck/arcana-derived values into the same formulas without regrouping F32 operations. This removes P×E repeated full-list filtering/object reconstruction, not effects or contacts. Preserve player iteration order and existing burn-source/tie rules.
2. Compute indexed killer once per enemy and reuse its id for both ownership and luck. Avoid duplicate predicates within a killer visit only after confirming exact eager/lazy behavior and no effect changes. A stronger target-hit index can remove most enemy×hit scans: nonarea membership comes from actual plan.targets; area candidates must be filtered with the exact effects recipient geometry, then original plan order restored. **Effects use original oldX/oldY plus radius from updated Row; Contact.Target moved endpoint/radius is not automatically equivalent.** Empty hit subsets must still execute burn/cooldown/immune_motion/status/death logic.
3. Reuse a single tick geometry/trajectory bundle across contact_team, projectile progression and witnesses, including the same nearest aim and exact sweep result/time. Keep all live targets, finite pierce, visited ids, stable tie ordering, and all witness birth/generation stamps. A conservative swept AABB/grid broad phase can later reduce candidate pairs without dropping any exact contact, including unlimited area plans and endpoint motions; do not introduce fixed candidate caps.
4. Cache replay prefix results only while the complete canonical anchor/session/command prefix is identical. A new server anchor must invalidate stale geometry/status/visited results and replay every unacknowledged input. This does not remove the cost of a fresh 30-input replay at 20Hz and cannot substitute for the above fixes.

Validation should compare all resulting players/snapshots/status/visited/births/ordered witnesses against the unchanged path, including area edge geometry, multihit order, duplicate ids, owner fallback, immunity, burn-only empty subsets and fresh canonical replacement. No shorter horizon, enemy cap, contact omission, or reduced snapshot frequency is proposed.

Artifacts: `/tmp/bendvy-combat-profile/*.cpuprofile`, `summary.json`, `analyze.py`; raw fixture `/tmp/bendvy-combat-perf.mjs`, report `/tmp/bendvy-combat-perf.json`.


## Recipient-index candidate: next profile

A second read-only diagnostic uses the **identical original fixture script**, replacing only the C module import with `/tmp/bendvy-combat-optimized.mjs` and report output path. No rebuild or physics change by this reviewer. CPU work was serialized with root; no concurrent perf workload was reported. The single run completed in 0.87 s (including startup), forecast median **101.70 ms** (four post-warmup observations), step median **3.830 ms**. At 20 snapshots/s plus 60 local steps/s this still estimates **2.264 main-thread seconds/second**. The worker's earlier 150.9 ms is a separate uncontrolled observation, not a contradiction or a qualified speed ratio.

| Remaining function | Self % | Inclusive % |
|---|---:|---:|
| projectile_contact.contacts |22.82|23.62|
| game.nearest |9.85|10.13|
| garbage collector |6.69|6.69|
| game.hit_targets |3.83|outside top40|
| game.at |2.74|outside top40|
| game.free_shot_slots |2.05|outside top40|
| game.contact_targets |1.27|outside top40|

`make_team` is 28.48% inclusive, `contact_plans` 22.97%, `contact_team` 21.10%, `contact_shot_targets` 18.19%. Inclusive numbers overlap and V8 inlining gives asymmetric attribution. Startup compilation is 3.18% self in this short profile. Effects are no longer the dominant measured cost. Moving-target reconstruction repeated three times exists, but its directly attributed 1.27% self does not justify prioritizing it over the remaining all-pairs contact traversal.

The emitted contacts worker at optimized.mjs:2699 eagerly evaluates `contains(visited,seed)`, `sweep(...)`, and recursion before calling `collect`. Thus even a visited target still runs the sweep, although collect will discard it. Moving the visited branch before sweep preserves the exact output by construction and avoids that wasted work. It will not solve this particular initially-empty-visited sparse fixture alone. `contains` also evaluates recursive tail even after a match through eager Bool.or; a real short-circuit preserves membership semantics.

For every ordinary tick, the known 100 ballistic shots still traverse all 400 moving targets (40,000 pairs; 1.2 million pairs per 30-input replay). At Contact.contacts the JIT attributes inlined geometric arithmetic and recursion to the enclosing function; the separately named sweep function is only 0.80% self, so that small number does not mean geometry is free. Miss/Hit return objects are allocation sites on this path; this CPU profile is not an allocation-byte census.

Next concrete candidates:

1. Share one exact per-shot aim/next-trajectory value between contact planning, actual projectile progression, and witness construction. Currently contact_shot_plan invokes nearest_from_args; projectile progression and witnesses can repeat nearest and the same pure next-state calculation. Preserve owner-specific run, current tick, exact old snapshot geometry and all subsequent pierce/life/visited consumption. Do not reuse across canonical anchors or different command/session revisions.
2. Add a conservative swept spatial broad phase or swept interval rejection **before** exact Contact.sweep. Candidate targets must be a superset of every contact the current F32 solver could accept, not a fixed nearest-N subset. Preserve visited exclusions, finite-pierce selection, exact accepted time bits and seed tie ordering. Test F32 rounding/cancellation, large coordinates, overlap, stationary/fast opposing motion, grazing and radius edge cases; fall back to the exact full path for unsafe numeric inputs. A mathematical geometric AABB proof alone is insufficient if it does not account for the existing floating-point solver's behavior.
3. Share the prepared moving-target geometry and snapshot/target indices across make_team and step_witnesses. Build once per coherent tick; do not mix old/new positions or substitute moved endpoint geometry for effect oldX/oldY. Reuse geometry after exact equality is established, rather than removing witnesses or active actors.
4. hit_targets (3.83% self) rescans hit plans during projectile consumption: retain an ordered per-shot hit-index beside the existing per-target recipient index, using the same duplicate/first-match semantics as the source.

With the observed local-step cost, only approximately 38.5 ms per forecast remains within a 1000 ms/s budget at 20 Hz. This is an arithmetic target, not a promised result. Neither snapshot-rate reduction nor a shorter pending-input horizon is proposed.

Second-run artifacts: `/tmp/bendvy-combat-profile-optimized/*.cpuprofile`, `summary.json`, `analyze.py`, `/tmp/bendvy-combat-perf-optimized-profile.mjs`, `/tmp/bendvy-combat-perf-optimized-profile.json`.


## Repo-owned reproduction

The fixture now lives at `examples/survivors/coop-combat-benchmark.mjs`. From the repository root, using already emitted Bend modules:

```sh
timeout 60 node examples/survivors/coop-combat-benchmark.mjs --variant ballistic
```

To select the exact external candidate while retaining the same supporting module directory:

```sh
timeout 60 env COOP_COMBAT_MODULE=/tmp/bendvy-combat-optimized.mjs COOP_LATENCY_MODULE_DIR="$PWD/examples/survivors/dist/web/dist" node examples/survivors/coop-combat-benchmark.mjs --variant ballistic
```

The separately labeled mixed-area diagnostic changes **only** every fourth projectile's pierce from 50 to 9999 (25 area fields, 75 ballistic shots), preserving all original coordinates, damage, radii, velocities, owners, seeds, 400 enemies and 30 inputs:

```sh
timeout 60 node examples/survivors/coop-combat-benchmark.mjs --variant mixed-area
```

The module directory override is an absolute or relative filesystem directory; the combat override accepts a filesystem path or file URL. Defaults use `examples/survivors/dist/web/dist`. Physics is imported compiled Bend; JavaScript constructs fixtures and clocks calls only. No compiler runs and no files are written by the benchmark. It emits one JSON document to stdout, including raw samples and selected module URLs. Retain the original sample design: five forecasts, first warmup excluded from the four-sample upper-middle median, then seven one-step probes. Mixed-area observations are a distinct workload and must never be pooled with ballistic timings. Syntax checking passed; this repo-owned version was **not executed** while another worker owned the performance window. Neither command asserts a performance PASS.


## Actual browser attempt: overlapped, timings invalid

The first real-Iroh two-tab CDP attempt on `127.0.0.1:43251` attached profilers to the authoritative host worker, host main thread and guest main thread, with default combat diagnostics OFF and no IMPACTS. It started before explicit root START and overlapped another worker's benchmarks. **All timing, host-Hz, RAF and latency conclusions from this attempt are invalid.** Raw values remain in the receipt for audit, not performance claims. No rerun is authorized until explicit root START.

Artifact directory: `/tmp/bendvy-browser-cost-profile/`, including three CPU profiles, before/after served-asset hashes, minimal frame tick/timestamp and received-text-length samples, source receipt and `ANALYSIS-STATUS.json`. The script's local source/collection status was PASS, but the strict outer process owner returned exit0 with failure `child left owned descendants; no passing result`; its bounded cleanup ran. This is not a functional PASS. The ownership warning and overlapped data are retained.

Hypotheses only: the host worker spends most attributed work under Core.step / game_team_execute, with substantial GC, repeated game.at and ECS reads; the guest has a significant forecast path and future-volley shot_requests cost. Iroh/WASM inclusive stacks contain synchronous application receive/reconcile/forecast callbacks, so their inclusive share cannot be labeled pure networking overhead. These leads require a serialized rerun before quantitative interpretation.


## Serialized actual-browser profile, ROOT START

The repeat ran only after explicit ROOT START, after the worker's two clean benchmarks completed; root and worker reserved the CPU window and performed no heavy tests/builds during capture. The first overlapped attempt above remains invalid and retained. This repeat used actual Iroh, two tabs in one browser context on `http://127.0.0.1:43251/coop.html`, default diagnostics OFF, no combatTrace/IMPACTS, no injected network delay, and the latest already served coherent-world/future-volley build. Production code was not edited. Read-only route instrumentation adds only received frame timestamps, tick and existing string length; worker listeners record tick/timestamp and a separate RAF callback records timestamps. It does not clone or stringify full frames.

Startup/navigation/real relay connection and the first three guest snapshots were outside profiling. A further explicit 2-second warmup preceded the measurement. At the measurement boundary both host and guest had already observed 41 snapshots. The 10.13-second window held ArrowRight for4seconds, ArrowLeft for3seconds, with1second initial and2seconds final idle. Three simultaneous Chrome CPU profilers covered host authoritative worker, host main and guest main; profiler overhead itself is included. No unprofiled baseline was run, so these are diagnostic observations, not statistical capacity guarantees.

| Steady observation | Host | Guest |
|---|---:|---:|
| Snapshot/frame count |191|190|
| Authoritative tick advance per observed second |60.12|60.08|
| Snapshot interval median |51.1ms|52.3ms|
| RAF count |608|607|
| RAF interval median |16.7ms|16.7ms|
| RAF interval95th / maximum |16.8 /16.8ms|16.7 /16.8ms|

Guest frame text length averaged48,568 JavaScript string characters (range45,703–51,647), approximately0.91million characters/s in this sample. This is character count before parsing, **not** measured compressed network bytes or transport bandwidth.

| Actual thread/path | Wall-sample inclusive share | Self share where relevant |
|---|---:|---:|
| Host worker Core.core_step |40.75% (4128ms)|—|
| Host worker game_team_execute |37.58%|—|
| Host worker core_observe |2.06% (209ms)|—|
| Host worker publish (includesobserve) |3.10% (314ms)|—|
| Host worker GC |13.34%|13.34%|
| Host worker game.at |—|4.89%|
| Host worker effect_one_effects |—|4.48%|
| Host worker idle |36.82%|36.82%|
| Guest reconcilePrediction |8.01% (812ms)|—|
| Guest coherent replay forecast |6.75% (684ms)|—|
| Guest CoopUI.animate |6.60% (669ms)|—|
| Guest Combat.render / Scene serialization |1.49% (151ms)|—|
| Guest future-volley game_shot_requests |—|4.31%|
| Guest GC |1.98%|1.98%|
| Guest idle |43.16%|43.16%|
| Guest unattributed `(program)` |29.88%|29.88%|

Percentages use each thread's complete sampled window, including idle, and overlap in inclusive ancestry; do not add nested rows or equate wall samples with hardware CPU counters. Host main was57.36% idle,29.92% unattributed program; its animate ancestry was3.10% inclusive. The dominant identified host path is actual authoritative ECS/game execution, not full observation JSON. `publish` also contains wrapper parse/transport message preparation; this profile does not isolate every native JSON.parse/stringify builtin individually. Guest rendering is bounded by measured animate ancestry, but native painting/driver work is not fully attributable from this CPU profile: the large `(program)` category is **not** proof that Iroh consumes that share. Iroh/WASM inclusive call chains include synchronous receive/reconcile/forecast callbacks and must not be interpreted as exclusive networking cost.

The clean normal run maintained60Hz observed world advancement and approximately60Hz RAF. This explains why the earlier IMPACTS-instrumented or overlapped32/23Hz observations cannot establish uninstrumented normal capacity. It does **not** establish800ms delayed-input performance, dense400-enemy Scene capacity, contact geometry correctness, or absence of visible jitter in those other conditions. The worker's separately serialized frozen ballistic/mixed diagnostics remain different workloads.

Remaining actionable leads: host game.at/effect_one_effects and repeated ECS plan/capability access still allocate/read on every authoritative row; caching immutable tick combat stats must preserve formulas, row order, writes and transaction metadata. On guest the new future-volley enumeration (`game_shot_requests`) is now an identified cost; share deterministic request-plan computation across identical tick/player/weapon context rather than omitting any known future volley. Observe/render JSON is real work but secondary here; avoid blaming it for most of the host loop without further evidence.

Both outer existing task_runner and browser subreaper completed PASS: primaryexit0, no owner failure, both adopted Chromium children reapednormally, remainingChildrenempty. Raw profiles and receipts: `/tmp/bendvy-browser-cost-profile-clean/`; offline analyzer `/tmp/analyze-actual-browser-cost.py`. Six key served source artifacts matched byte-for-byte before and after; their sorted-map SHA256 is `9a601c5bb69237f61900b8157e5116cb9fb92b37a294abc261533501355fe147`. The full per-file hashes, warmup counters, raw timestamps and original diagnostic assumptions are retained in receipt.json, with summaries perthread and window-summary.json. This is an actual serialized browser diagnostic, not a gameplay acceptance gate or performance PASS criterion.


## combatTrace-only split attempt: incomplete

Under a new explicit ROOT START, an isolated follow-up enabled **only** `combatTrace=1` on both host URL and guest invite URL, retaining the previous two-tab script, movement,2-second warmup and10-second intended profile window. IMPACTS and full-frame trace instrumentation remained absent. The30-second browser helper deadline expired before profile/collection files were produced. No phase progress markers were present, so the timeout cannot be assigned to relay startup, guest admission, Scene diagnostics or profiling. **There is no timing/Hz/function-cost result for this attempt.**

Artifacts `/tmp/bendvy-browser-cost-profile-diagnostics/` retain outer exit125/owned-descendant warning and the inner deadline/cleanup timeout. The enclosing ownership cleanup returned, the specific diagnostic Node PID was absent afterward, and no matching diagnostic Node process remained. No other processes were killed. The failure does not establish a performance regression; the passing normal profile above remains a distinct result. A new run requires explicit ROOT START, with startup progress and a startup allowance appropriate for variable real-Iroh connection time; no automatic retry was launched.
