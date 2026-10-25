# 18 — independent review of the cross-entity access audit

**Date:** 2026-10-20. Read report 12 and current public declarations/consumers in Bendvy. Read-only review: no applications, tests or builds were run. The goal was to verify API wording, not repeat execution evidence.

## Result

Report 12's main conclusion about a generic relation join is supported when narrowed to a direct transition from the current entity to components of an arbitrary outgoing target inside one standard query body. An ordinary setter writes the current row; a relation row exposes detached handles through a read-only capability; the standard relation provider reads the inverse for an already supplied target and queues relate/unrelate operations.

There are two important caveats. First, the standard hierarchy helper can take a root, traverse descendants and run an ordinary component query over them as current rows. This is specialized tree traversal from a predetermined root, not a generic source-row → outgoing-target join. Second, report 12 describes combined entity-component/resource access too broadly: public `recognized-query-declaration` already provides `write + resource_write + pair`, and `recognized-app-component.add` registers this callback through the ordinary App runner. This is a narrow canonical surface for component writes and a whole owned resource; custom Ops and separate phases are unnecessary for this combination. The separate selected-resource-field factory remains its own path, and this does not establish the ergonomics of arbitrary query/resource combinations.

## Basis and limits of the review

The narrow conclusion is supported: an ordinary row writer is not a universal outgoing-target join. Specialized hierarchy traversal must not be hidden by this generalization. The broad claim that component + global resource is impossible through ordinary App was corrected; Sparse is a source-level counterexample.

Definitions and consumer bodies remain in the sources:

- [ordinary declarations](../../../bendvy/src/ecs/ordinary-query-declaration.bend),
  [Compose](../../../bendvy/src/ecs/compose.bend),
  [recognized declaration](../../../bendvy/src/ecs/recognized-query-declaration.bend).
- [Relation query](../../../bendvy/src/ecs/relation-query.bend),
  [relation App](../../../bendvy/src/ecs/ordinary-app-relation.bend),
  [hierarchy query](../../../bendvy/src/ecs/ordinary-app-hierarchy-query.bend).
- [Scheduled health](../../../bendvy/examples/scheduled-health/README.md),
  [user simulation](../../../bendvy/examples/user-simulation/README.md),
  [Sparse](../../../bendvy/test-fixtures/connected-performance/sparse-motion64/README.md).

The audit does not duplicate signatures, registration algorithms or the call graph. The inspected arena source had SHA-256
`45e8845e68489094dd2707d45ee437f07325646ed28fbfc82f955432bddd5730`,
which differed from the published digest in [CHECKS.md](../../../bendvy/examples/arena/CHECKS.md). The mismatch limits the receipt's freshness and does not by itself establish a failure.

## Report clarification

[Report 12](12-cross-entity-access-audit.md) must retain the narrow boundary: supported component + whole-resource composition is not a gap; hierarchy traversal is a specialized exception; generic outgoing-target joins and late structural barriers require separate consideration. A digest mismatch limits execution evidence rather than proving that source cannot execute.

**Audit limits:** no compiler, tests, fixture or game were run. Contracts are therefore supported by types, implementations and consumer descriptions; current compilation, runtime results and performance are not revalidated here. Raw/custom Ops and arbitrary query adapters allow broader behavior, so absence claims concern the standard closed surfaces, not the language's absolute expressiveness.
