> Historical source-backed hypotheses. Acceptance is recorded in [native-step-results.md](native-step-results.md); this note is not a performance claim.

# Native ECS step: owner reconstruction options

Research only, 2026-10-23. Core checkout: `/workspace/formal-proofs/bendvy`, HEAD `2989f2aaba624a1a62523bf092efcdecea7e84d7`. Game checkout: `/workspace/formal-proofs/bendvy-ecs-native-step-20261023`. Deadline for the parent experiment remains 10:28:26 UTC. No core checkout or installed Hub package was changed. No timing or native compilation was performed for this note.

## Recommendation

First test the small generic `component.get` fusion prepared as `/tmp/native-step-20261023/core-fused-read.patch`. It retains all validation and the exact storage/projector operations while removing intermediate `World` construction. It addresses every current selector read as well as reads inside callbacks. It does **not** eliminate `Store.take/put`, column owner transport, transaction wrappers, or write journals. The reported profile attribution is a hypothesis input, not a measured speedup for this patch.

Keep a game-specific `owned_compose.each_fields` adapter as a later, larger candidate. This existing public API can preserve opaque capabilities and exact writes, but entering/leaving only selected rows leaves the four complete selector scans unchanged. Existing compact recognized execution is also published, but its supported declaration constructors do not express the game's custom selectors directly.

## Source authority

The inspected game entry and selectors are in
[`game.bend`](../examples/survivors/game.bend). The query, getter, validation,
projection and transaction definitions belong to the pinned BendHub package;
resolve its identity through [`bendhub-dependencies.json`](../bendhub-dependencies.json).
This note does not maintain a second call graph or pool layout.

`C.read`/`project_handle` in historical profile names must be mapped through
that run's generated qualified symbols. Source inspection does not establish
numeric attribution.

## Candidate A: fused generic component read

The candidate implementation is retained in the source-bound patch
`/tmp/native-step-20261023/core-fused-read.patch`; its getter logic is not
repeated here. Its intended benefit was reduced owner reconstruction while
preserving the existing public signature and permitted owner-returning
operations. A detached Data cache would not be a general substitute for an
affine projector.

The external staged core source passed the normal parser/type/affine wrapper: `/tmp/native-step-20261023/core-fused-sourcecheck.log`. This is **not** backend or mathematical refinement qualification. No installed package bytes were overwritten. Actual adoption requires a separately identified core change and published package version; the example must continue importing a declared Hub distribution.

### Acceptance and proof needs

Reuse the ordinary [query-composition consumer](/workspace/formal-proofs/bendvy/examples/query-composition/check.sh), its independent [oracle](/workspace/formal-proofs/bendvy/examples/query-composition/expected.json), and [authority controls](/workspace/formal-proofs/bendvy/scripts/query-controls.py). The consumer exercises multiple families with affine payloads, rollback/retry, foreign-world collision and structural visibility; inspect its existing coverage before adding fixtures. The small [health-decay consumer](/workspace/formal-proofs/bendvy/examples/health-decay/check.sh) is an initial cheap ordinary witness, not complete qualification.

Focused differential obligations for old/new `C.get`: foreign namespace must skip allocator and lens access; invalid/stale/reserved/non-live keys must skip all storage lenses; valid missing slot returns `ComponentAbsent`; present slot returns identical detached view and returned actual payload owner; custom affine `Store` rest and resource owners survive; lifecycle stamps/clock/events/pending commands/registration metadata remain identical; reads following earlier transactional writes observe them. Use actual issued foreign/reused handles, not invented literals. Reuse existing undeclared-access, cross-schema, read-to-write and abstract-owner confinement controls. A reached mutant removing namespace or generation validation must fail the actual consumer.

A universal preservation argument would relate the original validation branches to the fused branches, for arbitrary `Type` Store/payload/resource and the supplied lenses. It must not assume every `Owner -> Owner & view` preserves the original owner: affine typing alone allows replacement or dropping. The patch instead executes the same owner-returning functions in the same permitted branches. New law approval/proof follows the core workflow if formal laws are added; parser/typecheck alone proves none of these equations. [Core review criteria](/workspace/formal-proofs/bendvy/CODING_STANDARDS.md:1), [workflow](/workspace/formal-proofs/bendvy/docs/agent-workflow.md:1).

## Candidate B: public owned-row game adapter

The public adapter definitions are in
[owned-compose.bend](../../bendvy/src/ecs/owned-compose.bend) and
[owned-optimized-compose.bend](../../bendvy/src/ecs/owned-optimized-compose.bend).
Their signatures and traversal logic are not duplicated here. Consumers must
resolve the published distribution declared in
[bendhub-dependencies.json](../bendhub-dependencies.json).

The proposed schema adapter would retain the original selectors, setters and
transaction boundaries while reducing owner transport inside selected rows.
The integration API belongs to the linked implementation, rather than an
uncompiled call template here. Ordinary selection would still traverse the
world, so entry/exit transport could offset callback savings. It cannot safely
promise gains from raw column writes or skipping unchanged writes.

Existing source-bound historical qualification: [owned-field regression receipt](/workspace/formal-proofs/bendvy/benchmarks/evidence/frontier-owned-fields-prepared-regression/receipt.json) records the prior adapter's 110 complete outputs; [implementation report](/workspace/formal-proofs/bendvy/docs/reports/parity-frontier-implementation.md:140) records 14 backend pairs/23 checkpoints, confinement controls and a reached restoration mutant. Those archived adapter source files are not present at their old `experiments/public-optimized-compose/workshop` paths in this checkout. Current core has subsequently changed for epoch-aware execution scopes, so these receipts are design/test guidance, **not** fresh qualification of a new game port. Current [Sparse affine payload consumer](/workspace/formal-proofs/bendvy/test-fixtures/connected-performance/sparse-motion64/consumer/s-perf/canonical-api-v1/sparse-runtime-v1/motion.bend:24) is a reusable example of typed storage lenses, affine projections and narrow capability bodies; it now uses the recognized provider rather than `each_fields`.

## Existing compact recognized path and limits

The recognized path is defined by
[declarations](../../bendvy/src/ecs/recognized-query-declaration.bend),
[runner](../../bendvy/src/ecs/recognized-system.bend) and
[ordinary entry](../../bendvy/src/ecs/recognized-app-component.bend).
Consult those implementations for supported composition and fallback behavior.

This is a useful precedent for a future core adapter with a closed opaque owner, but not a public drop-in replacement for arbitrary custom kind selectors. Importing internal frame types into gameplay or inventing a local shadow Hub module would bypass the intended surface. A broader recognized custom-filter/read API needs its own contract/authority evidence; it is larger than Candidate A.

## Avoided shortcuts

Do not cache across arbitrary `take/put/project` calls without an explicit preservation contract: their signatures permit meaningful owner transformation. Do not infer immutable membership or skip validation merely because the allocator did not change in one current game. Do not batch away write stamps, inverse journals, failure ordering or command visibility. Prepared columns/handoffs already exist, but their earlier performance experiments include regressions; their presence is not evidence of a gain here. All candidates need the fixed native replay workload and complete observation checks before timing claims.

## Package preparation reconciliation

Before applying Candidate A in the isolated core clone, compared all 365 `src/ecs` Bend files against installed Hub content `0xf435da9e535b3846d643dad16580e35f`, normalizing only import-line hyphens to distribution underscores and file names similarly. 363 match. The comparison receipts identify a missing installed module and a declaration mismatch; their implementation differences are recorded with the source artifacts rather than repeated here. These are not silently classified as equal.

The actual game's transitive Hub dependency closure contains 20 modules, including World/Component/Compose/Column/allocator/transaction. All 20 match the source baseline after that import-name normalization. Receipts: `/tmp/native-step-20261023/core-hub-closure-comparison.json` and `/tmp/native-step-20261023/game-hub-closure-comparison.json`. This supports a private, explicitly identified game replay candidate against the source patch; it does not establish that republishing the entire core checkout reproduces the existing package preparation. Any publication must reconcile those two inventory/preparation differences explicitly.

## Isolated Candidate A qualification, 2026-10-23

Applied only the fused read patch in `/workspace/formal-proofs/bendvy-native-step-20261023/src/ecs/component.bend`; candidate SHA `0f0c40fece94d36b68d83ef421fe7137a19c0d838c2310080c478da16562d7ff`. Ordinary sourcecheck passes. The frozen Workshop consumer produced identical JS/native output, all 23 committed complete checkpoints matching the independent oracle. Three existing positive authority controls passed. A fourth historical positive fixture was stale under the current EntityKey/World/Frame layout; the unmodified baseline rejects it too, so the original v2 receipt remains INCOMPLETE rather than being rewritten.

A successor frozen run repaired only that fixture and the corresponding opaque-frame refusal fixture to the current public constructors. Its seven remaining controls pass: current detached Frame creation plus refusal of undeclared access, read-to-write escalation, cross-schema use, affine-owner duplication, opaque-context reconstruction, and runtime capability templates. Receipts are `/tmp/native-step-20261023/ordinary-gates-v2-output/receipt.json` and `/tmp/native-step-20261023/ordinary-gates-v3-output/receipt.json`; independent launch review is `/tmp/native-step-20261023/core-fused-launch-review.md`. These qualify the narrow ordinary consumer/authority surface, not full repository correctness or game performance.

The next private game stage freezes the original game SHA `366aa0235e16813d798912473f465f6cba2fafa568636a939784c5383d7ac56f` and the completion-forced native replay driver. Fourteen local modules are copied unchanged except Hub import lines, which reference the actual isolated source checkout's 20 transitive core modules. `/tmp/native-step-20261023/core-game-first/SOURCE.json` records both source closures and each import rewrite. No example dependency or installed package is changed. Independent changed-scope launch review passed. The native build and first fresh1200 replay both passed under the owned 480-second outer bound: two complete checkpoints, every authoritative slot/stamp/world metadata field and F32 bit matched the baseline. Receipt: `/tmp/native-step-20261023/core-game-first/output/receipt.json`; captured generated C SHA `bf53e68afce492bb2323f0f3e3467be19b69cc0e971ddd59de2808c2fa1a882b`, native binary SHA `e18ed7c0a9a15bd67e571ee7a9da300a32ae129c1ca0a6b6d184bd1798a63c9d`. The remaining20 game fixtures and numerical performance qualification remain unrun; this result does not establish a speedup.
