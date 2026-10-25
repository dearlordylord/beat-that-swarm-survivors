# Survivors overloaded-state removal: baseline contract

This contract was fixed before changing gameplay contracts for issues 3–9.
The baseline gameplay source is clean `master` commit
`01b4164612cd6e37d39aa75b16fab2dd253ebb0d`. The original user's worktree has
unrelated edits; those are excluded, not silently described as committed source.
The baseline worktree adds development tools and repairs the replay observer's
eight-field Store patterns to preserve the ninth, authoritative player column.
It does not change gameplay. The receipt identifies the exact observer patch,
authored source closure, compiler, dependency manifest, commands and artifacts.

## Reproduction and artifact boundary

The local preserved artifact directory is
`/tmp/bendvy-survivors-ecs-baseline-01b4164`. It holds a source archive,
compiled native replay, freshly emitted game/co-op/common modules, numeric input
traces, raw observations, semantic facts and hashes. These are qualification
artifacts, not example dependencies. The compact receipt is tracked; binaries,
raw captures and caches are not.

Build native replay with `bend examples/survivors/native-replay.bend -o OUTPUT`.
Emit game, co-op-core and native-replay-common to `.mjs` files with the same
compiler. Run `qualification-trace-capture.mjs COMMON GAME HISTORICAL_TRACE OUT
1200` to freeze current public inputs, and pass `6000 true` for the stationary
terminal scenario. Historical traces supply movement only: their upgrade timing
does not match current master and is not reused as an alleged current oracle.
The trace recorder reads actual phases and chooses currently offered index 0.

Run native replay with `NIGHTFALL_REPLAY_TRACE=TRACE` and
`NIGHTFALL_REPLAY_CHECKPOINT_EVERY=300`, with runtime arguments
`+RTS --threads 1 -RTS`. Export named semantic facts using
`qualification_projection.py RAW --output FACTS`. The exporter validates the
physical old schema first, then exercises mutations of actual source observations
for damage, XP, generation and status. A clock-only representation control must
remain semantically equal. Native output retains exact F32 bits.

Run `qualification-coop-capture.mjs CORE OUTPUT` for the fixed seed-100 two-player
public start/join/step/choose/disconnect journey. It captures actual player records
by loading ECS handles and also retains the complete Core state: allocator,
player references, player-column values and lifecycle stamps beyond the pooled
actor IDs. The existing pooled-actor validator is **solo-only** and does not claim
to validate these extra co-op entities. The analytic contact/birth production
fixtures supplement public journeys for deliberate contaminated-status reuse.

## Semantic contract and closed exclusions

Candidate slices emit the same named gameplay facts from their authoritative
components. No production compatibility layer is needed to export test facts.
Compare exact run facts, visible entity order, phase snapshot order, offers,
pending rewards, role-specific health/status, damage/trajectory, pickup
amount/generation/occupancy, namespace, allocator identities and issued order.
Co-op comparison additionally preserves shared state, actual personal state,
connected flags, references, offers/rewards and observable frame/contact results.
Keep raw physical observations and strict current-schema replay in each slice.

The only cross-schema exclusions are enumerated by the exporter: outer timing
and timing/digest summary records; actual clocks/stamps; physical column/routing
representation; redundant Body health/XP copies where separate components own
the value; and unused Motion portions on roles without that component. These
exclusions never apply to ordinary same-schema replay. Unknown/missing fields
must not be normalized away. A new target schema needs its own physical
validator, not a blanket exclusion for all components. The temporary exporter
is retired after final old/new qualification; retained receipts do not require
permanent support for the old schema.

## Initial access matrix

This is the observed current permission surface, not the desired one. Broad
Body grants are precisely the responsibility leak being removed.

| Production path | Actual reads | Actual writes | Decision/data use |
| --- | --- | --- | --- |
| Projectile query | Role; Body, Trajectory through write grants | Body, Trajectory | shot spawn, movement, damage, expiry, ownership and hit history |
| Enemy movement query | Status; Body through write grant | Body | coordinates and age; slow affects movement |
| Enemy combat pool query | Role, Body; Vitals/Status through write grants | Vitals, Status | health, effects, birth routing, damage and death outcome |
| XP pool query | Role, Body, Pickup | none in this query | pickup amount/generation and collection result |
| Non-XP loot lifecycle | Role; Body through write grant; entity handle | Body | commit death/loot/dormancy lifecycle |
| XP lifecycle | Role; Body/Pickup through write grants | Body, Pickup | accumulation, activation, amount, generation, view refresh |
| Prepared routing capture | issued handles, Role, Body | derived movement/candidate rosters | membership only; no gameplay authority |
| Co-op load/save players | actual player handles, PlayerRecord | PlayerRecord by structural replace | personal run and connected state |
| Solo/co-op orchestration | query results, run/shared/personal state, phase snapshots | cached views, stats, offers, pending rewards and next authoritative state | phase ordering and reward allocation |

The matrix must evolve with each owning slice. Movement must lose write access
to health, damage, reward and identity; age ownership must be stated explicitly.
Positive/negative controls must target the new actual accessors.

## Snapshot and consumer inventory

| Value | Source and construction | Validity and consumers | Refresh/write rule |
| --- | --- | --- | --- |
| State/Core bodies | completed entity query rows | next-step pure inputs, typed/native drawing and JSON frame | rebuilt on successful completion; never second health/XP authority |
| State/Core snapshots | completed entity rows with logical motion | next-step shot inventory, contact planning and effects origins; co-op prediction/forecast/journal | immutable phase input until next successful step |
| Contact targets/hit plans | incoming snapshots plus the same movement functions the ECS will execute | current tick only, ordered swept contacts and pierce selection | freeze before movement; effects do not feed back into this tick's path |
| Movement roster | issued live handles and roles | movement query selection | initial prepare and explicit routing refresh; contains no gameplay payload |
| Projectile/pool candidate rosters | issued handles, role and active-body membership | candidate queries in current simulation phase | refreshed at the explicit routing capture boundary |
| Team/Args/PlayerView | shared/personal run projections, inputs and phase snapshots | one step's planning, nearest-player targeting and owner selection | derive for step; do not persist as personal authority |
| Co-op observer run/forecast players | actual loaded PlayerRecords plus shared session facts | observer/spectator frame and prediction scene | derived per observation; do not delete legitimate spectator semantics |
| JSON frame / Core frame | typed state and observation projection | browser/renderer, worker, transport adapters and bot tools | currently emitted with packets; issue 3 makes encoding optional |
| Exact native observer | retained State plus actual columns/world metadata | development replay only | returns affine owners unchanged; current player-column gap covered by complementary co-op capture |

Observed execution dependency: incoming snapshots → shot allocation/contact
preparation → projectile query → enemy movement → enemy/pickup combat query →
XP/non-XP lifecycle commit → statistics and outgoing views. This is a baseline
semantic dependency to preserve, not a prohibition on equivalent reordering.

Consumers include native drawing/audio/profile results; browser renderer and
workers; co-op forecasts, journal/contact playback and snapshot codecs;
offline/bot controllers; native replay and comparison tools; capability fixtures;
and lifecycle laws/mutants. Each vertical slice migrates its own consumers and
strict replay checks. Final cleanup is not deferred consumer implementation.

## Bounded performance protocol

The primary metric is native replay's internal `replay-summary.windowMs` on the
fresh normal trace and the stationary trace (terminal if reached). Process wall
time is diagnostic; JSON checkpoint emission is outside the measured window.
Use the retained baseline binary and fresh candidate built with identical Bend,
C compiler, flags and published dependency. Runtime has one thread and no
`BENDRTS` override. If using CPU affinity, apply the same permitted CPU to both.

Final qualification uses three alternating-order reference/candidate pairs per
scenario (six pairs total), retaining every sample. A candidate/reference ratio
above 1 is a signal, not proof from a single sample. If the paired median is
above 1 and the observed reference/candidate ranges overlap, allow one additional
three-pair series to resolve noise. A slowdown with consistent paired direction
and separated sample ranges is confirmed and blocks acceptance. Unresolved
noise must be reported as inconclusive, never a passed no-slowdown claim.
Re-measure only to resolve noise or verify an actual regression fix. Background
load and CPU placement are recorded; no unrelated processes are stopped.

No whole-game proof, universal performance guarantee, real-network quality or
full balance qualification is claimed by this finite baseline.
