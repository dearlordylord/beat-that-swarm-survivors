> Historical source-backed hypotheses. Acceptance is recorded in [native-step-results.md](native-step-results.md); this note is not a performance claim.

# Native game-step hotspots: source-backed candidate shortlist

Status: read-only analysis, 2026-10-23. No candidate code, compilation or timing was performed for this note. The fixed replay owner must establish the native baseline before measuring any of these candidates. This note uses the research skill's primary-source method; its author is already the delegated research worker.

## Evidence and scope

The inspected consumer is [game.bend](../examples/survivors/game.bend); historical
source-specific conclusions belong to the generated artifact and report for that
snapshot: [final-native.c](/workspace/formal-proofs/bend-games/research/native-bots-20261022/final-native.c)
and [native-profile-analysis.json](/workspace/formal-proofs/bend-games/research/native-bots-20261022/native-profile-analysis.json).

The first instrumented native profile attributed 26.70% self time to `term_drop`, 14.52% to generic closure application, 6.17% to `span_fade`, 4.52% to reference-count wrappers, and 3.74% to two atomic helpers. These are shared runtime mechanisms, **not a measured game-only breakdown**. Generated preserve-none tail calls make many gprof callers appear spontaneous. The policy subsequently changed and the Patricia index was adopted, so these historical percentages cannot rank the current game-only replay numerically.

## Source authority

The historical query and access hypotheses came from
[`game.bend`](../examples/survivors/game.bend) and the pinned distribution's
`compose.bend`, `component.bend`, `world.bend` and `column.bend`. Resolve the
package through [`bendhub-dependencies.json`](../bendhub-dependencies.json).
Pool capacities and query structure have changed since inspection; consult
those sources instead of reusing source-derived counts from this note.

## Candidate 1: freeze combat-derived stats once per tick

The proposed hypothesis was to share immutable combat-derived values over one
simulation tick rather than repeat their derivation for each enemy. Its value
depends on whether saved arithmetic exceeds representation and transport costs.
The precise arithmetic and reached callback belong to
[game.bend](../examples/survivors/game.bend), not to a second recipe here.

Safety conditions:

- Preserve every F32 expression's grouping and explicit rounding boundary; precompute exactly the existing coefficient subexpressions.
- Rebuild after each tick's run is selected; do not persist the cache across upgrades or reward application.
- Preserve all Q plans, selectors, access order, unconditional writes, transaction metadata and lifecycle routing.
- Production Q.each must reach the cached implementation; wrappers that recalculate per enemy would defeat the patch.

Validation: full helper differential across rank/status/collision combinations, fixed native replay observation and component/metadata comparison. Historical V8 attribution put about 4.84% total self time in `at` called by enemy effects; that is context only, not a native benefit estimate.

## Candidate 2: share exact repeated local enemy geometry

A smaller, independent consumer patch. Introduce a local immutable geometry result that computes the common player-distance denominator and slow factor once, then feed the exact original X and Y arithmetic. Do not change control flow or omit zero-valued effects.

The inspected generated C retained repeated distance and slow-factor work.
Current arithmetic belongs to [`game.bend`](../examples/survivors/game.bend);
this note does not maintain a parallel expression specification.

Safety conditions:

- Keep F32 operations and order within each result unchanged. Sharing an identical pure subexpression is preferable to algebraic reassociation.
- Do not introduce `if knock == 0` or `if pull == 0` as part of this patch: omitted NaN/Infinity arithmetic and signed-zero changes would expand the semantic argument.
- Preserve opaque row/motion fields and final condition selection exactly.

This candidate may lose to allocation overhead if the generated compiler materializes a temporary record. Inspect C to require scalarized results or use explicit extra scalar parameters. Measure independently from candidate 1 to identify whether the small arithmetic saving survives its representation cost.

## Candidate 3: fuse validation and component read reconstruction in core

The proposed core hypothesis was reduced owner reconstruction without changing
component access authority or observable results. It requires stronger affine
owner and refusal evidence than the consumer-local candidates. The historical
patch and qualification are identified in [the core options report](core-native-step-options.md).

Required safeguards:

- Preserve arbitrary affine Type component/resource payloads; no Data-only shortcut.
- Keep namespace, generation, liveness, undeclared-access and read/write authority checks in their original observable order.
- Verify missing/absent/stale/foreign handles, payload preservation, rollback journals, stamps, Changed metadata and full successful replay.
- Do not edit the installed package cache or switch examples to a source checkout. A retained core candidate needs a real new BendHub publication and matching example pin/content hash before delivery.

Avoid a new game-side side table that duplicates authoritative ECS state: it would make the demo bypass the very access path being evaluated. Also avoid repeating the old opaque-projector candidate without a new native-specific hypothesis: its historical JavaScript cohort was worse, as recorded in the previous performance research.

## Proposed order

Establish exact native replay validity and game-only baseline. Try candidate 1, then candidate 2 independently. Reprofile the accepted consumer result before undertaking candidate 3. Report each timing only for its frozen workload; none of the source-level operation counts constitutes a speedup claim.
