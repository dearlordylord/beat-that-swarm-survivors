# Co-op bot retrospective v1 — development runs only

## Scope and provenance

This review uses only `/tmp/coop-pop-v1-dev25/run-{0..3}.jsonl` and `/tmp/coop-pop-v1-dev100/run-{0..3}.jsonl` (seeds 100–103). I did not inspect validation or final-cohort runs. These are four paired development seeds, not an independent qualification set.

Both campaigns report revision `18f9e09b75b9cc31238a1e2011efe49f86802c8c`, the same criteria hash, game-context hash, runner hash, setup (`fresh-fresh-stage0-standard`), style (`resource-memory-pair`), and policy hash (`9b63e95df0d72d6e60786995671e97c08aae52c91a41031753e46b4046a91279`). Both use the same fixed `bend-resource-memory-v1` policy for each player, native execution, and no classifier or learning. The manifests mark the builds dirty; these results identify that frozen experimental snapshot, not a claim about a clean current checkout. The intended game-axis difference is `extraPercent=100` versus `extraPercent=25`.

Every run contains 120 samples at ticks 0, 60, …, 7140 and a terminal summary at tick 7200 (120 seconds); all eight outcomes are `horizon`. Initial setup is the fresh stage-0 profile: both players are character 0, meta 0, arcana 0, with the same starter weapon and no passive ranks. `xp`, `xpNeed`, and `level` are read from the shared run state. `uncollectedBaseXp` is the sum of currently live XP-pile values at that observation, not total XP created or a collection-efficiency rate.

## Progression comparison

| Seed | extra 100: final level; first level 2; final shared XP/need; uncollected base XP; kills | extra 25: final level; first level 2; final shared XP/need; uncollected base XP; kills |
|---:|---|---|
| 100 | 3; tick 3120; 28/53; 186; 128 | 4; tick 2400; 11/61; 351; 226 |
| 101 | 2; tick 6840; 16/46; 216; 136 | 3; tick 3780; 44/53; 195; 138 |
| 102 | 3; tick 2220; 26/53; 371; 221 | 4; tick 1920; 25/61; 406; 263 |
| 103 | 1; not reached; 12/20; 326; 178 | 2; tick 3540; 26/46; 230; 147 |

On these four paired seeds, extra 25 finishes one level higher in all four runs (mean final level 3.25 versus 2.25), reaches level 2 in 4/4 rather than 3/4, and records 774 total kills versus 663. The observed uncollected base-XP total is 1182 versus 1099; it is higher in two seeds and lower in two. Since the runs do not report total XP generated, that terminal pile value cannot establish that either bot collected XP more or less efficiently. Kills, shared level, and HP are outcome summaries, not an attribution of damage or XP source.

This supports the narrow observation that the extra-25 game arm had better shared level progression in these development runs. It does not show a complete run, a win-rate change, or that the bot caused the difference. All runs are censored at the same 120-second horizon and none ended in a defeat.

## Player proximity and hostile-pressure samples

Player separation is Euclidean distance between the two logged positions. Each run has 120 one-second-spaced observations. “Within 1” is a near-coincidence threshold; “within 32” is approximately the initial spawn separation. Counts below are sampled observations, not continuous dwell-time measurements.

| Seed | extra 100: samples within 1 / 32 | extra 25: samples within 1 / 32 |
|---:|---:|---:|
| 100 | 114 / 116 | 87 / 112 |
| 101 | 112 / 115 | 112 / 116 |
| 102 | 107 / 113 | 85 / 113 |
| 103 | 58 / 109 | 94 / 117 |
| **All four** | **391/480 (81.5%) / 453/480 (94.4%)** | **378/480 (78.8%) / 458/480 (95.4%)** |

The longest consecutive run of samples within 1 world unit is 114 observations for extra 100 (seed 100; 113 seconds between its first and last observation) and 98 for extra 25 (seed 101; 97 seconds between endpoints). Within 32 units, the longest runs are 114 and 115 observations respectively. In seed 103 specifically, extra 25 has 94 samples within 1 unit versus 58 for extra 100, while both arms are usually within 32. Across seeds, the near-coincidence counts move in both directions. Therefore the traces confirm that the players often travel very close together, but do not show that the extra-25 setting generally caused that behavior.

The runner defines `nearEnemies` as living enemy bodies within radius 120 of a player. At both-player sample snapshots that count is zero in 402/480 observations for extra 100 and 381/480 for extra 25. This is a sparse proximity proxy: a zero at a sampled instant says nothing about enemies between samples, attacks already in flight, or damage pressure over the interval.

## What the policy code does and does not coordinate

In [`offline-coop-batch.bend`](../examples/survivors/offline-coop-batch.bend), `Progress` carries separate `m0` and `m1` memories; the runner projects each player separately, then calls `Policy.movement(m0, p0, rows)` and `Policy.movement(m1, p1, rows)` on the same shared body list before applying both directions in one co-op step. So the bots have separate histories but observe the same world.

In [`offline-policy.bend`](../examples/survivors/offline-policy.bend), `Memory` stores one current `Choice`, prior XP object keys, and prepared candidates. The planner groups live XP by a 120-unit grid cell, sums cluster reward, plans routes, and retains a still-valid current goal. It replans on a cadence of 30 world ticks or when state such as damage, stuck movement, or goal invalidation requires it. The planner's `reserve` keeps one current-goal candidate, one non-XP candidate, and one cardinal fallback in that bot's local candidate pool while removing duplicates from the same pool; it is not a reservation shared with the teammate. `movement` receives no player index or teammate memory, and its steering avoidance considers enemies and other hostile bodies, not a separation vector from the other player.

This is a concrete coordination gap, not evidence of a defect in the single-player policy. The two controllers can independently rank the same XP cluster and follow similar enemy-avoidance motion, especially with identical starting builds. The position trace alone cannot distinguish that from two different goals that happen to be nearby, shared movement pressure, or another cause. There is no selected-goal identity, reservation, or decision timestamp in the current JSONL, and one-second snapshots can miss multiple replans.

## Retrospective decision and bounded next bot experiment

The existing data is enough to choose and test a cooperative-coordination hypothesis, but not enough to attribute the overlap to duplicate XP targeting or to justify changing the algorithm on that causal claim. First add **optional diagnostic-only Bend telemetry** to a separate bot-diagnostic build; keep game logic and `extraPercent=25` fixed. Emit only when either player's selected-goal signature changes (after both per-player movement decisions for that tick), plus a final segment close, coalescing unchanged signatures instead of serializing the world every frame. Include:

- tick and both player positions;
- for each player: selected goal kind, stable target key, XP cluster cell when applicable, target coordinates, selected score, path length, and risk;
- the best reachable *different* XP cluster and its score/path cost, when one exists;
- pair flags for “same XP cluster” and distance, with the interval start tick for the preceding unchanged signature.

This exposes whether the controllers actually chose the same XP resource and whether a useful alternative existed, while keeping telemetry bounded to decision/assignment changes. It does not require a classifier, network call, or full per-frame world dump. A missing alternative is meaningful: reservation should not force a detour when there is no viable other cluster.

If the telemetry shows repeated same-cluster assignments while another reasonably competitive reachable cluster exists, test one deterministic candidate: the control arm keeps policy v1 for both players; in the candidate arm, player 0 keeps policy v1 and player 1 excludes player 0's active XP cluster when selecting its own XP goal, falls back to sharing when no reachable alternative exists, and retains its assignment until the normal invalidation/replan rules apply. Keep the existing route and enemy-risk planner. This is a bounded **bot-axis** trial: freeze the extra-25 game hash/context, setup, horizon, and native runner; change only player 1's XP-cluster selection. Compare candidate versus frozen policy v1 on development seeds 100–103 only, treating those already-open seeds as iteration evidence, not qualification. Do not inspect validation or final cohorts for this retrospective.

The next decision should be based on target-overlap telemetry and shared progression together, not separation alone. If both players already select different XP clusters during close travel, this reservation candidate has no supported mechanism and should not be implemented; inspect the measured target and route data first.

## Local evidence inspected

- Development receipts: `/tmp/coop-pop-v1-dev25/run-{0..3}.jsonl`, `/tmp/coop-pop-v1-dev100/run-{0..3}.jsonl`, and their two `manifest.json` files.
- Policy and native runner: [`offline-policy.bend`](../examples/survivors/offline-policy.bend), [`offline-coop-batch.bend`](../examples/survivors/offline-coop-batch.bend).
- No source files, game logic, policy, or experimental cohorts were modified or run for this retrospective.
