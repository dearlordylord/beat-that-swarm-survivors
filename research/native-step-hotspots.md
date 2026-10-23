> Historical source-backed hypotheses. Acceptance is recorded in [native-step-results.md](native-step-results.md); this note is not a performance claim.

# Native game-step hotspots: source-backed candidate shortlist

Status: read-only analysis, 2026-10-23. No candidate code, compilation or timing was performed for this note. The fixed replay owner must establish the native baseline before measuring any of these candidates. This note uses the research skill's primary-source method; its author is already the delegated research worker.

## Evidence and scope

The inspected consumer is [game.bend](../examples/survivors/game.bend), particularly lines 501–505, 529–531, 602–609, 619–727 and 779–791. Generated code is [final-native.c](/workspace/formal-proofs/bend-games/research/native-bots-20261022/final-native.c). Historical native sampling and its limitations are recorded in [native-profile-analysis.json](/workspace/formal-proofs/bend-games/research/native-bots-20261022/native-profile-analysis.json).

The first instrumented native profile attributed 26.70% self time to `term_drop`, 14.52% to generic closure application, 6.17% to `span_fade`, 4.52% to reference-count wrappers, and 3.74% to two atomic helpers. These are shared runtime mechanisms, **not a measured game-only breakdown**. Generated preserve-none tail calls make many gprof callers appear spontaneous. The policy subsequently changed and the Patricia index was adopted, so these historical percentages cannot rank the current game-only replay numerically.

## What repeats in each game tick

`execute` runs projectile, movement, combat and lifecycle queries in that order. Each selector reads Body for every populated entity. The normal game has 1004 populated entities, so these selectors account for **4016 Body reads per tick**. This follows from `selected_projectile`, `selected_enemy`, `selected_pool` and their four `Q.each` callsites, not an extrapolated timing.

Let N be the number of live enemy-kind rows selected for movement. The fixed ordinary pool has 224 projectile/hostile slots, 780 combat/lifecycle slots (512 enemy/relic plus 268 actors/XP), and 524 non-XP combat slots. Consequently the source-level successful access counts are:

| Operation | Reads per tick | Writes per tick |
|---|---:|---:|
| Body | 5800 + N | 1004 + N |
| Motion | 748 + N | 1004 |
| Vitals | 524 | 780 |
| Total | 7072 + 2N | 2788 + N |

These counts assume the ordinary fully populated world, successful access, and no early query failure. They include selector reads. They do not count handle enumeration, transaction commits, index construction or rendering. They are useful workload structure, not profiler call counts.

The published [component.get implementation](/tmp/bendvy-ecs-examples-cold-hub/0xf435da9e535b3846d643dad16580e35f/component.bend:62) calls `W.valid`, reconstructs the returned world, then enters `get_world`, splits the family column from Store, projects the payload, restores Store and reconstructs World again. [compose.get](/tmp/bendvy-ecs-examples-cold-hub/0xf435da9e535b3846d643dad16580e35f/compose.bend:49) additionally threads Tx and Frame. In generated C, former `spin_419` at line 38814 of `/tmp/nightfall-native-first.c` explicitly rebuilds a 9-field Store and 17-field World before the validation continuation. Custom-heap allocation and reference counting are relevant even without libc malloc samples.

## Candidate 1: freeze combat-derived stats once per tick

Recommended first consumer patch. Introduce immutable `CombatStats` containing luck rank and exact existing knock/pull coefficients. Derive it from the same frozen `Args.run` once immediately before the combat `Q.each`. Carry it through a private `CombatContext{args,stats}` to cached combat implementations. Keep existing exported Args/Run layouts and helper signatures as wrappers around the same implementation, to avoid breaking external fixtures or adding a second formula source.

Current `enemy_applied_effects` looks up passive 16 twice and passive 10 once for each ordinary enemy reaching its kind-0 arm. `at` visits index+1 list cells, so this is **45 list-cell visits per such enemy** (17 + 17 + 11), even when collision knock is zero. The constructor can perform 28 visits once per tick. Generated C retains both index-16 calls: `spin_36(...16ull)` at lines around 24338 and 24387, so this is not merely duplicated source syntax optimized away by C. Four separate `stat_bonus(arcana,11)` calls also remain in this C region.

Safety conditions:

- Preserve every F32 expression's grouping and explicit rounding boundary; precompute exactly the existing coefficient subexpressions.
- Rebuild after each tick's run is selected; do not persist the cache across upgrades or reward application.
- Preserve all Q plans, selectors, access order, unconditional writes, transaction metadata and lifecycle routing.
- Production Q.each must reach the cached implementation; wrappers that recalculate per enemy would defeat the patch.

Validation: full helper differential across rank/status/collision combinations, fixed native replay observation and component/metadata comparison. Historical V8 attribution put about 4.84% total self time in `at` called by enemy effects; that is context only, not a native benefit estimate.

## Candidate 2: share exact repeated local enemy geometry

A smaller, independent consumer patch. Introduce a local immutable geometry result that computes the common player-distance denominator and slow factor once, then feed the exact original X and Y arithmetic. Do not change control flow or omit zero-valued effects.

The existing source computes `F32.max(1,sqrt(distance2(oldX,oldY,px,py)))` twice and `slow_factor(max(slow,s))` twice in the same arm. Generated C still calls player `distance2` (`spin_120`) at lines 24329 and 24378, then applies sqrt/max twice. `pull_x` and `pull_y` independently compute the same centroid-distance denominator; that pair can later be represented by one `PullVector`, preserving the original component arithmetic.

Safety conditions:

- Keep F32 operations and order within each result unchanged. Sharing an identical pure subexpression is preferable to algebraic reassociation.
- Do not introduce `if knock == 0` or `if pull == 0` as part of this patch: omitted NaN/Infinity arithmetic and signed-zero changes would expand the semantic argument.
- Preserve opaque row/motion fields and final condition selection exactly.

This candidate may lose to allocation overhead if the generated compiler materializes a temporary record. Inspect C to require scalarized results or use explicit extra scalar parameters. Measure independently from candidate 1 to identify whether the small arithmetic saving survives its representation cost.

## Candidate 3: fuse validation and component read reconstruction in core

Higher-risk core patch, potentially larger native impact. Within the existing `component.get` implementation, consume the world once, validate the same namespace/generation/live state using the same affine allocator owner, then access/project/restore the requested column before constructing the final World. The existing rejected-handle branch must return the original owners and `MissingEntity`, without touching the column. The valid-but-absent branch must remain `ComponentAbsent`.

The goal is eliminating intermediate World/Store construction and corresponding reference-count work, **not eliminating component reads**, caching authority, reordering writes, skipping equal-value writes, or bypassing the capability API. Keep `tx_get` and Q Frame error/cursor behavior unchanged. The source-derived access counts above show why a per-access reduction could matter; the shared-runtime profile does not quantify the achievable saving.

Required safeguards:

- Preserve arbitrary affine Type component/resource payloads; no Data-only shortcut.
- Keep namespace, generation, liveness, undeclared-access and read/write authority checks in their original observable order.
- Verify missing/absent/stale/foreign handles, payload preservation, rollback journals, stamps, Changed metadata and full successful replay.
- Do not edit the installed package cache or switch examples to a source checkout. A retained core candidate needs a real new BendHub publication and matching example pin/content hash before delivery.

Avoid a new game-side side table that duplicates authoritative ECS state: it would make the demo bypass the very access path being evaluated. Also avoid repeating the old opaque-projector candidate without a new native-specific hypothesis: its historical JavaScript cohort was worse, as recorded in the previous performance research.

## Proposed order

Establish exact native replay validity and game-only baseline. Try candidate 1, then candidate 2 independently. Reprofile the accepted consumer result before undertaking candidate 3. Report each timing only for its frozen workload; none of the source-level operation counts constitutes a speedup claim.
