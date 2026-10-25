# 12 - audit access between entities in the current Bendvy

**Date of review:** 2026-10-20. I checked the sources and saved read-only reports; I didn’t run the code or tests.

## Conclusion

Bendvy supports batch writing across multiple rows of the same component family and a separate public recognized-App path that combines the current entity's writer with a global resource record in a single query transaction. But a normal component writer only addresses the current row entity. Relation-query can return detached target/source handles, however its view is read-only; explicit entry to another handle goes through a deferred command and a barrier. Therefore, the standard App API still does not provide a short canonical path to “find a related object, read its components and atomically change both sides.”

The line is not between “there is a resource API” and “there is no resource API”, but between the canonical closed composition and arbitrary query combinations. `recognized-query-declaration` provides `write`, `resource_write` and `pair`, and `recognized-app-component.add` registers such a runner in the executable App. This narrow route covers the component + share; it doesn't promise all ordinary query combinators or adapters for arbitrary selectors. Relation target joins and other custom grants still require a separate, verifiable path.

The most direct scenarios for the existing API from the studied candidates are a batch hit of a Magicka-like spell on several health entities and a push-chain Baba Is You on one `GridPosition` family. The FTL-like generic power is not a space: it can be combined with a crew component via a recognized pair; dynamic crew→room lookup and recording of associated room components remains a phase/custom-query issue. The interaction of SS14-like actor + tool + door most clearly reveals the lack of a regular inter-entity join.

## API Boundary Sources

Definitions and access algorithms are not duplicated in this report. Sources:

- [Component/query capabilities](../../../bendvy/src/ecs/capabilities.bend),
  [Compose](../../../bendvy/src/ecs/compose.bend) and
  [recognized declarations](../../../bendvy/src/ecs/recognized-query-declaration.bend).
- [Relation query](../../../bendvy/src/ecs/relation-query.bend),
  [ordinary relation entry](../../../bendvy/src/ecs/ordinary-app-relation.bend) and
  [hierarchy query](../../../bendvy/src/ecs/ordinary-app-hierarchy-query.bend).
- [Regular App](../../../bendvy/docs/reference/ordinary-app.md) and
  [transaction implementation](../../../bendvy/src/ecs/transaction.bend).

The audit conclusion is to distinguish between same-row composition, special traversal adapters and the general outgoing-target join. You cannot infer the overall atomicity of a subsequent structural barrier from the existence of an immediate writes transaction. To select a game slice, it is the required action limit that is important, and not the number of factories.

## Applying to four slices

| Scenario from candidates | Realistic template in Bendvy | Assessing the current API |
|---|---|---|
| **SS14-like actor → tool → door** ([hypothesis 07](07-space-station.md)) | Before updating, allow interaction in the plan: actor/tool/door handles, accessibility check and selected result. For repeatable changes to one family, use batch query. For the missing door component - explicit-target deferred insert and barrier; for door/actor/tool ​​of different types you need separate typed passes or a custom composite adapter. | The most inconvenient of the four bundles: communication/containment, access to target components, and interfamily atomicity. To say that these things are impossible would be too strong: the parts can be assembled at a low level; The standard ordinary row query does not supply them. |
| **FTL-like crew → room + general power** ([hypothesis 08](08-modular-ships.md)) | Changing components within the crew family, together with the general power resource, fits into recognized `pair(write, resource_write)` as one App runner/transaction. But closed selector does not select an arbitrary crew by handle from the team. For a known room, incoming inverse gives the crew; outgoing assignment can be obtained from the detached relation view/plan. If the action also changes the room component, the target row still needs to be prepared/updated with another typed pass or custom relation adapter; relation changes become visible on the barrier. | Good match for family crew update + global power; average for a full crew→room cycle. The limiter here is not a resource, but the selection of one target crew/room through a dynamic relation and the entry of another component family. Phasing is suitable if the rules of the game allow this commit/barrier order. |
| **Magicka-like AoE spell → multiple Health/Wet targets** ([hypothesis 04](04-systemic-sandbox.md)) | The contact phase builds a `Args` list of affected handles/effects in advance; one `Health` query applies damage to all eligible targets transactionally. Installation of a new optional `Wet`/`Burning` component goes structural command/barrier after the effect is calculated. | Good for the ECS slice itself when separating the hit-plan and structural phase. The projectile→caster connection for attribution can be read-only snapshot or nested in advance in plan; dynamic target-follow inside `Health` callback remains inconvenient. You cannot promise all-or-none between damage and late insertion failure. |
| **Baba Is You push-chain → many GridPosition** ([hypothesis 10](10-rule-puzzles.md)) | At the beginning of the move, calculate the full valid push chain and the new `GridPosition` of each handle. Apply it one traversal over the `GridPosition`-family with a plan in `Args`; if the chain is blocked, do not create a change plan. Derivatives `Stop/Push/Win` trait additions/removals - a separate structural phase after scanning the rules. | The most natural multi-entity direct-write example: no connection is needed, and all immediate row writes are of the same family. We need an access handle for scheduled matching and a separate barrier phase for changing the composition of components. |

Magicka and Baba illustrate an important difference. A batch transaction is suitable for immediate data of the same type (`Health`, `GridPosition`). If each target requires insertion/removal of different optional components, this is already a structural batch with barrier semantics, and not the same atomic operation.

## Consumers and freshness of evidence

[Scheduled health](../../../bendvy/examples/scheduled-health/README.md), [user simulation](../../../bendvy/examples/user-simulation/README.md), [arena](../../../bendvy/examples/arena/README.md) and [Sparse](../../../bendvy/test-fixtures/connected-performance/sparse-motion64/README.md) were read as sources. Their bodies and plans are not recounted here; this audit did not re-run them.

Historical evidence of user simulation recorded 23 JS checkpoints from 2026-10-17. Arena's published digest `game.bend` `d53f351e3b8b53df5d84489458a087de228eee505a276285b450711dab0762b8` did not match the read `45e8845e68489094dd2707d45ee437f07325646ed28fbfc82f955432bddd5730`. This is a freshness limitation of evidence, not proof of execution error. [Recorded tests](../../../bendvy/examples/arena/CHECKS.md). Relation delivery artifact was missing from the read checkout; his past qualification cannot be equated with the new executed consumer.

## Specific limitation and stopping criterion

The key missing standard ergonomic unit is not the “relation API” in general, but the composition: *current entity → outgoing relation target → query target components → journaled target write in the same transaction*. The second missing part is taking the results of the structural barrier into one all-or-nothing operation with immediate entity/resource writes. Sources confirm deferred commands and notices, but not such a general commit transaction.

For the first clone, a Baba-like kernel remains the most direct way to show multi-row write of one family; Magicka is also a good fit and can transactionally update a shared resource in the same recognized query. FTL becomes noticeably more viable if the slice is limited to crew-family + global power processing and a specific relation-driven target update can be moved into the phase. If the main input is an order to the selected crew member, and the main result changes the associated room entity, you need to prototype the selector/relation adapter before committing the choice. Consider this slice a blocker only if such a requirement determines the outcome of the game or a late failure of the barrier should cancel the already committed values.

## Revision after checking recognized API

The original version too broadly declared component + global resource as an ordinary App. Sparse refutes this finding for supported closed composition. The clarification does not eliminate the separate issue of an arbitrary target join, nor does it turn successive registrations into a single all-or-nothing operation. A specific supported surface should be checked against the associated sources, and not against the historical list of functions in Markdown.
