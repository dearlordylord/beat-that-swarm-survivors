# Abstraction-layer audit of Survivors

Source snapshot: local working directory on 2026-10-25. This is an architectural code review, not a performance measurement or an estimate of hours saved. Unrelated uncommitted changes were already present and were not touched.

## Conclusion

The overall separation is appropriate: gameplay rules and policies live in Bend, while native and browser code handles launch, input, profile storage, presentation and transport. The main tension is not that the application implements an ECS adapter—this is inevitable for a specific game schema—but that the adapter, gameplay decisions, state projections and JSON contract share the same large modules. The first practical goal is to make these boundaries visible and local, rather than move rules out of Bend or turn every file into a separate layer.

## Existing layer map

- **Shared ECS core:** the example imports published `bendvy-ecs-core@0.1.0.1`; version and content hash are pinned in the [manifest](../bendhub-dependencies.json). The local checkout does not contain this package's sources, as required by the [project instructions](../AGENTS.md). Bendvy's official README describes typed components, queries and declared read/write access, and its example shows the application defining `Ops`, access capabilities and a query plan ([Bendvy README](https://github.com/dearlordylord/bendvy/blob/master/README.md#code-example)). That README tracks mutable `master`, so it gives an API overview rather than replacing the exact pinned version's source.
- **Gameplay rules:** many policies are pure and extracted into small Bend modules: damage in [combat-policy.bend](../examples/survivors/combat-policy.bend), spawn-admission geometry in [spawn-policy.bend](../examples/survivors/spawn-policy.bend), allocation and limits in [pools.bend](../examples/survivors/pools.bend), network prediction in [coop-prediction.bend](../examples/survivors/coop-prediction.bend). This is an appropriate level for decisions requiring reuse and verification independently of windows, networking and ECS storage.
- **Application and ECS schema:** slot-role → component mappings, concrete `Store`, `Family`, capability sets and query plans belong to the example. A shared library cannot know what `Vitals` means in this game, which components `XpSlot` requires or what pool limits apply. This is application wiring even when technically involved.
- **Hosts:** [native.bend](../examples/survivors/native.bend) drives the native event loop, UI, clocks and IO; browser modules display frames and read browser input. In [progression.mts](../examples/survivors/progression.mts), profile serialization and JSON-to-Bend conversion are separate from decisions: purchases, unlocks and setup validation call a compiled Bend module. Co-op [coop-worker.mts](../examples/survivors/coop-worker.mts) schedules steps, handles worker messages and calls the Bend session model. These are good boundaries: adapters pass inputs and results while authoritative decisions remain in Bend.

## Main findings and their cost

### 1. ECS wiring is justified but sits beside gameplay logic

The first roughly 200 lines of [game.bend](../examples/survivors/game.bend#L31) define `Store`, rest types and repeated `take`/`put`/`project`/`Family` component bindings. The same module then contains movement/combat rules, system callbacks, query plans, entity composition, game transitions and statistics collection. Capability contracts and plans, including projectile and movement plans, sit beside behavior ([game.bend](../examples/survivors/game.bend#L799), [game.bend](../examples/survivors/game.bend#L815), [game.bend](../examples/survivors/game.bend#L810)).

Repeated `take`/`put` is not an arbitrary game rule: it connects concrete game columns to Bendvy's generic API and is necessary application work. With the current placement, changing a rule requires navigating ECS wiring inside the same 1,881-line module; adding a component affects repeated rest structures, families and empty storage. Separate `MovementRoster` and `CandidateRoster` are derived handle lists for system selection, yet also reside in `Store` beside game columns ([game.bend](../examples/survivors/game.bend#L49), [game.bend](../examples/survivors/game.bend#L146), [game.bend](../examples/survivors/game.bend#L291)). Query-preparation details consequently become part of the world type exposed to other modules.

**Action:** as a first low-risk step, extract the schema, `Family` wiring, capabilities, plans and prepared-roster mechanics into one `game-ecs.bend` module/submodule. Export the `World` type and narrow operations such as “update enemies”; keep pure policies in their own modules. This reduces mixed concepts and limits propagation of Store details. Do not move schema-specific bindings into generic Bendvy: they are application responsibilities.

### 2. Parallel DTOs are useful but blur the source of truth

`Body` contains `hp/maxHp` and fields used for presentation/frame transport, whereas `Vitals` is a separate authoritative component; the file's comment explicitly says so. Similarly, gameplay `Motion` combines trajectory and status stored separately as `Trajectory` and `Status`; conversion functions sit near the schema ([game.bend](../examples/survivors/game.bend#L35), [game.bend](../examples/survivors/game.bend#L39), [game.bend](../examples/survivors/game.bend#L126)). `State` also carries `World` and `bodies`/`snapshots` lists; a system accumulator builds these records from query results for subsequent stages and external observation ([game.bend](../examples/survivors/game.bend#L227), [game.bend](../examples/survivors/game.bend#L1123)).

This is not necessarily accidental duplication: grouped records suit pure functions and snapshots, while detached projections help at network/presentation boundaries. However, one type mixes persistent ECS state with derived views. Developers must remember which field is authoritative on each path; otherwise a callback or new consumer may accidentally use copied `Body.hp`/XP rather than `Vitals`/`Pickup`. The code already needs to emphasize that XP values in `Body` do not decide behavior and come from `Pickup` ([game.bend](../examples/survivors/game.bend#L138), [game.bend](../examples/survivors/game.bend#L207)).

**Action:** when next changing this model, separate persistent ECS components from `EntityView`/frame DTOs and name conversion boundaries. Retain DTOs for pure mechanics or snapshots where needed, but do not pass display fields into an authoritative decision function. Check component ↔ DTO transitions on selected lifecycle/replay cases. Do not remove `bodies` and `snapshots` lists before identifying which prediction, combat-planning and renderer consumers need them.

### 3. Frame JSON leaks into the gameplay API

`Game.Packet` combines typed state with `frame: String`; `packet_extra` manually serializes almost the entire game summary, offers and body arrays to JSON inside `game.bend` ([game.bend](../examples/survivors/game.bend#L227), [game.bend](../examples/survivors/game.bend#L318), [game.bend](../examples/survivors/game.bend#L354)). Native code uses `quiet_packet` with an empty string, while browser and co-op worker parse `packet.frame` through `JSON.parse` ([game.bend](../examples/survivors/game.bend#L1828), [browser.mts](../examples/survivors/browser.mts#L184), [coop-worker.mts](../examples/survivors/coop-worker.mts#L35)). Additional multiplayer projection/player serialization resides in [coop-core.bend](../examples/survivors/coop-core.bend#L199), mixing shared-world rules/orchestration with the wire view.

Serialization in Bend is justified: the browser receives Bend results through JS, and native launch does not depend on Node. The problem is interface placement and shape: JSON fields and names are embedded in the game module's API, while typed consumers bypass them through special empty serialization. Changing a frame field affects gameplay and the wire contract together.

**Action:** extract Bend observation/encoding modules (`game-frame.bend`, with separate co-op observation) and pass them a typed view. Keep encoding in Bend to preserve native execution; do not move game rules into JS. Separate frames from simulation results so quiet/native consumers do not create a dummy string field.

## Order of work

1. Isolate frame projection/JSON encoding—the clearest actual cross-layer seam, directly affecting browser and worker interfaces.
2. Group ECS storage/query wiring in the world module. Repetition will remain, but the boundary between generic mechanism and gameplay mechanics will become clear.
3. Clarify authoritative components and derived DTOs at the next lifecycle change; do not start a large rewrite before inventorying `Body`, `Motion` and `Snapshot` consumers.
4. Preserve current small policy modules and host adapters: the inspected sample showed no evidence of balance, spawning or networking decisions moving into browser UI/transport. UI naturally reads phase/offers for display; selection acceptance and final rewards remain Bend decisions.

This report proposes no API changes to the published ECS package and does not evaluate runtime performance. That requires separate measurements.

## Sources

- Local sources and READMEs are cited beside each conclusion; line numbers identify specific code locations.
- [Pinned BendHub dependency](../bendhub-dependencies.json) records `bendvy-ecs-core@0.1.0.1` and content hash `0xf435da9e535b3846d643dad16580e35f`.
- [Official Bendvy README](https://github.com/dearlordylord/bendvy/blob/master/README.md) describes the shared ECS API direction and demonstrates application-level access bindings; the current branch is not the source of the pinned hash.
