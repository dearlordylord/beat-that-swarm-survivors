> Historical source-backed hypotheses. Acceptance is recorded in [native-step-results.md](native-step-results.md); this note is not a performance claim.

# Native ECS step: owner reconstruction options

Research only, 2026-10-23. Core checkout: `/workspace/formal-proofs/bendvy`, HEAD `2989f2aaba624a1a62523bf092efcdecea7e84d7`. Game checkout: `/workspace/formal-proofs/bendvy-ecs-native-step-20261023`. Deadline for the parent experiment remains 10:28:26 UTC. No core checkout or installed Hub package was changed. No timing or native compilation was performed for this note.

## Recommendation

First test the small generic `component.get` fusion prepared as `/tmp/native-step-20261023/core-fused-read.patch`. It retains all validation and the exact storage/projector operations while removing intermediate `World` construction. It addresses every current selector read as well as reads inside callbacks. It does **not** eliminate `Store.take/put`, column owner transport, transaction wrappers, or write journals. The reported profile attribution is a hypothesis input, not a measured speedup for this patch.

Keep a game-specific `owned_compose.each_fields` adapter as a later, larger candidate. This existing public API can preserve opaque capabilities and exact writes, but entering/leaving only selected rows leaves the four complete selector scans unchanged. Existing compact recognized execution is also published, but its supported declaration constructors do not express the game's custom selectors directly.

## Actual call map

The game executes four distinct transactions: projectile, movement, combat, lifecycle. Each calls `Q.each`; each selector calls `Q.get` for `Body` before deciding by kind and pool seed. The pool has 1004 live ECS slots, including dormant gameplay slots. Projectile selection admits seed range 512..735; pool selection admits 736+ and seeds below 512; movement additionally requires enemy kind 0. Keep these predicates and pass order exact. [Game selectors and plans](/workspace/formal-proofs/bendvy-ecs-native-step-20261023/examples/survivors/game.bend:600), [four-pass execution](/workspace/formal-proofs/bendvy-ecs-native-step-20261023/examples/survivors/game.bend:778).

Ordinary read stack:

```text
Q.each -> W.handles -> Q.run_handles_acc -> original selector
Q.get -> C.tx_get -> C.get
  W.valid -> W.checked -> W.checked_namespace -> A.checked -> World
  C.get_allowed -> C.get_world
    take(Store) -> C.get_store -> Col.view(project) -> put(Rest,Column)
    W.with_store_finish -> World
  C.tx_get_join -> Tx -> Q.read_join -> Frame
```

The callback then performs further capability reads on the same ordinary frame; setters use `C.tx_set`, stamped replacement and the undo journal. [Ordinary frame and getters](/workspace/formal-proofs/bendvy/src/ecs/compose.bend:17), [component getter](/workspace/formal-proofs/bendvy/src/ecs/component.bend:60), [transaction getter](/workspace/formal-proofs/bendvy/src/ecs/component.bend:235), [validation](/workspace/formal-proofs/bendvy/src/ecs/world.bend:139), [column projection](/workspace/formal-proofs/bendvy/src/ecs/column.bend:464), [transaction setter](/workspace/formal-proofs/bendvy/src/ecs/component.bend:323).

`C.read`/`project_handle` in profile names should be mapped back through generated qualified symbols; those are not the literal current public function names in `component.bend`. Source inspection establishes the read chain above, not a numeric attribution for it.

## Candidate A: fused generic component read

The external patch changes only the implementation of existing `C.get`, retaining its public signature. It adds two component-private implementation helpers:

1. Match `World` and `Handle` once; compare runtime namespaces.
2. Foreign namespace: return the complete original owners plus `MissingEntity`, without allocator slot access or schema-lens calls.
3. Matching namespace: call the exact existing `A.checked(allocator,key,1)`; this retains full generation and live-state validation.
4. Invalid/stale/inactive key: return the checked allocator and all other original owners plus `MissingEntity`.
5. Live key: invoke the same `take(store)`, `get_store`, `Col.view(project)` and `put`; reconstruct `World` once with every original non-store field.

No index arithmetic, family parameter types, payload kinds, capability constructors, call order of lenses/projectors, allocator mode, clocks, events, commands, trace, registrations or failure distinctions change. `ComponentAbsent` remains distinct from invalid entity. A present projection may legally return an updated affine owner; the patch preserves it by retaining `Col.view` exactly. This is why replacing the operation with a detached `Data` cache would not be a general substitute.

The external staged core source passed the normal parser/type/affine wrapper: `/tmp/native-step-20261023/core-fused-sourcecheck.log`. This is **not** backend or mathematical refinement qualification. No installed package bytes were overwritten. Actual adoption requires a separately identified core change and published package version; the example must continue importing a declared Hub distribution.

### Acceptance and proof needs

Reuse the ordinary [query-composition consumer](/workspace/formal-proofs/bendvy/examples/query-composition/check.sh), its independent [oracle](/workspace/formal-proofs/bendvy/examples/query-composition/expected.json), and [authority controls](/workspace/formal-proofs/bendvy/scripts/query-controls.py). The consumer exercises multiple families with affine payloads, rollback/retry, foreign-world collision and structural visibility; inspect its existing coverage before adding fixtures. The small [health-decay consumer](/workspace/formal-proofs/bendvy/examples/health-decay/check.sh) is an initial cheap ordinary witness, not complete qualification.

Focused differential obligations for old/new `C.get`: foreign namespace must skip allocator and lens access; invalid/stale/reserved/non-live keys must skip all storage lenses; valid missing slot returns `ComponentAbsent`; present slot returns identical detached view and returned actual payload owner; custom affine `Store` rest and resource owners survive; lifecycle stamps/clock/events/pending commands/registration metadata remain identical; reads following earlier transactional writes observe them. Use actual issued foreign/reused handles, not invented literals. Reuse existing undeclared-access, cross-schema, read-to-write and abstract-owner confinement controls. A reached mutant removing namespace or generation validation must fail the actual consumer.

A universal preservation argument would relate the existing `W.valid -> C.get_allowed` branches to the fused branches, for arbitrary `Type` Store/payload/resource and the supplied lenses. It must not assume every `Owner -> Owner & view` preserves the original owner: affine typing alone allows replacement or dropping. The patch instead executes the same owner-returning functions in the same permitted branches. New law approval/proof follows the core workflow if formal laws are added; parser/typecheck alone proves none of these equations. [Core review criteria](/workspace/formal-proofs/bendvy/CODING_STANDARDS.md:1), [workflow](/workspace/formal-proofs/bendvy/docs/agent-workflow.md:1).

## Candidate B: public owned-row game adapter

Published `bendvy-ecs-core@0.1.0.1` already includes `owned_compose.bend` and `owned_optimized_compose.bend`. They are public trusted schema-adapter surfaces. `each_fields` accepts closed capabilities, the existing selector, an `enter : Q.Frame -> RowOwner`, a `leave : RowOwner -> Q.Frame`, and the unchanged universally quantified gameplay body. Internally it keeps ordinary enumeration, transaction finish, row order, rollback and failure handling. [Definition](/workspace/formal-proofs/bendvy/src/ecs/owned-compose.bend:101).

Concrete projectile integration shape, with analogous substitutions for the other three passes:

```text
Owned.each_fields(
  ~Schema,~Store,~Unit,~Unit,~ProjectileOpsType,~RowOwner,
  ~Args,~Error,~EntityRow,
  ~projectile_owned_caps(),~selected_projectile,~row_enter,~row_leave,
  ~projectile_system,args,world)
```

The game schema would own `RowOwner` containing the actual Body/Vitals/Motion columns, allocator, runtime namespace/current handle, error/cursor, and an opaque remainder containing all other World/Tx owners. `row_enter` splits once for each selected row. Schema-defined read adapters perform the same namespace-first `A.checked(...,1)` plus direct `Col.view` on the owned column, then return the complete row owner. They avoid rebuilding Store and World on each callback read. Write adapters call `row_leave -> existing Q.set -> row_enter`; this keeps exact clock advancement, displaced payloads, inverse journal closures, first-error handling, and stamps. Gameplay still receives only `Ops(H)` and opaque `H`, never `RowOwner` or columns.

The **original selector functions stay exact**, as do four independent passes and setter calls, including writes whose new `Data` equals old `Data`. This preserves query membership/order and change stamps. It also means approximately 4×1004 selector reads still use ordinary `Q.Frame` and reconstruct World/Store. The adapter's extra entry/exit transport can offset callback savings; benchmark before adoption. It cannot safely promise gains from replacing `C.tx_set` with raw column writes or skipping unchanged writes.

Existing source-bound historical qualification: [owned-field regression receipt](/workspace/formal-proofs/bendvy/benchmarks/evidence/frontier-owned-fields-prepared-regression/receipt.json) records the prior adapter's 110 complete outputs; [implementation report](/workspace/formal-proofs/bendvy/docs/reports/parity-frontier-implementation.md:140) records 14 backend pairs/23 checkpoints, confinement controls and a reached restoration mutant. Those archived adapter source files are not present at their old `experiments/public-optimized-compose/workshop` paths in this checkout. Current core has subsequently changed for epoch-aware execution scopes, so these receipts are design/test guidance, **not** fresh qualification of a new game port. Current [Sparse affine payload consumer](/workspace/formal-proofs/bendvy/test-fixtures/connected-performance/sparse-motion64/consumer/s-perf/canonical-api-v1/sparse-runtime-v1/motion.bend:24) is a reusable example of typed storage lenses, affine projections and narrow capability bodies; it now uses the recognized provider rather than `each_fields`.

## Existing compact recognized path and limits

Published `recognized_query_declaration.bend` offers `write`, `resource_write`, `pair`; `recognized_system.bend` runs a persistent compact frame across the row loop. Its shell hides unrelated World/Tx owners; reads route through `internal/query-read-session`, still calling the generic `C.get_store` lenses. Setters bridge back to ordinary `Q.set`. Trace-On App execution deliberately falls back to ordinary observed execution with the same authority. [Recognized declaration](/workspace/formal-proofs/bendvy/src/ecs/recognized-query-declaration.bend:13), [runner](/workspace/formal-proofs/bendvy/src/ecs/recognized-system.bend:26), [shell and bridge](/workspace/formal-proofs/bendvy/src/ecs/internal/compact-operational-frame.bend:15), [read session](/workspace/formal-proofs/bendvy/src/ecs/internal/query-read-session.bend:17), [ordinary App entry](/workspace/formal-proofs/bendvy/src/ecs/recognized-app-component.bend:37).

This is a useful precedent for a future core adapter with a closed opaque owner, but not a public drop-in replacement for arbitrary custom kind selectors. Importing internal frame types into gameplay or inventing a local shadow Hub module would bypass the intended surface. A broader recognized custom-filter/read API needs its own contract/authority evidence; it is larger than Candidate A.

## Avoided shortcuts

Do not cache across arbitrary `take/put/project` calls without an explicit preservation contract: their signatures permit meaningful owner transformation. Do not infer immutable membership or skip validation merely because the allocator did not change in one current game. Do not batch away write stamps, inverse journals, failure ordering or command visibility. Prepared columns/handoffs already exist, but their earlier performance experiments include regressions; their presence is not evidence of a gain here. All candidates need the fixed native replay workload and complete observation checks before timing claims.

## Package preparation reconciliation

Before applying Candidate A in the isolated core clone, compared all 365 `src/ecs` Bend files against installed Hub content `0xf435da9e535b3846d643dad16580e35f`, normalizing only import-line hyphens to distribution underscores and file names similarly. 363 match. `internal/machine-handler-events.bend` has no installed counterpart; `ordinary-query-declaration.bend` differs at `pair`, whose Hub body calls the already-defined `pair_parts` while source HEAD inlines the declaration constructor. These are not silently classified as equal.

The actual game's transitive Hub dependency closure contains 20 modules, including World/Component/Compose/Column/allocator/transaction. All 20 match the source baseline after that import-name normalization. Receipts: `/tmp/native-step-20261023/core-hub-closure-comparison.json` and `/tmp/native-step-20261023/game-hub-closure-comparison.json`. This supports a private, explicitly identified game replay candidate against the source patch; it does not establish that republishing the entire core checkout reproduces the existing package preparation. Any publication must reconcile those two inventory/preparation differences explicitly.

## Isolated Candidate A qualification, 2026-10-23

Applied only the fused read patch in `/workspace/formal-proofs/bendvy-native-step-20261023/src/ecs/component.bend`; candidate SHA `0f0c40fece94d36b68d83ef421fe7137a19c0d838c2310080c478da16562d7ff`. Ordinary sourcecheck passes. The frozen Workshop consumer produced identical JS/native output, all 23 committed complete checkpoints matching the independent oracle. Three existing positive authority controls passed. A fourth historical positive fixture was stale under the current EntityKey/World/Frame layout; the unmodified baseline rejects it too, so the original v2 receipt remains INCOMPLETE rather than being rewritten.

A successor frozen run repaired only that fixture and the corresponding opaque-frame refusal fixture to the current public constructors. Its seven remaining controls pass: current detached Frame creation plus refusal of undeclared access, read-to-write escalation, cross-schema use, affine-owner duplication, opaque-context reconstruction, and runtime capability templates. Receipts are `/tmp/native-step-20261023/ordinary-gates-v2-output/receipt.json` and `/tmp/native-step-20261023/ordinary-gates-v3-output/receipt.json`; independent launch review is `/tmp/native-step-20261023/core-fused-launch-review.md`. These qualify the narrow ordinary consumer/authority surface, not full repository correctness or game performance.

The next private game stage freezes the original game SHA `366aa0235e16813d798912473f465f6cba2fafa568636a939784c5383d7ac56f` and the completion-forced native replay driver. Fourteen local modules are copied unchanged except Hub import lines, which reference the actual isolated source checkout's 20 transitive core modules. `/tmp/native-step-20261023/core-game-first/SOURCE.json` records both source closures and each import rewrite. No example dependency or installed package is changed. Independent changed-scope launch review passed. The native build and first fresh1200 replay both passed under the owned 480-second outer bound: two complete checkpoints, every authoritative slot/stamp/world metadata field and F32 bit matched the baseline. Receipt: `/tmp/native-step-20261023/core-game-first/output/receipt.json`; captured generated C SHA `bf53e68afce492bb2323f0f3e3467be19b69cc0e971ddd59de2808c2fa1a882b`, native binary SHA `e18ed7c0a9a15bd67e571ee7a9da300a32ae129c1ca0a6b6d184bd1798a63c9d`. The remaining20 game fixtures and numerical performance qualification remain unrun; this result does not establish a speedup.
