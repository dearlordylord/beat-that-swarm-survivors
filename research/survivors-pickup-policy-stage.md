# Pickup migration: pure policy stage

Status: prerequisite work for GH7, not a completed gameplay migration.

The pure pickup module defines tagged XP, gold, healing, chest and relic
payloads, explicit occupancy and lifetime generation, scoped collection rewards,
and immutable spatial observations. XP amount and generation have no health
aliases. The authoritative shared slot identity remains the identity component;
the immutable pickup observation projects its number without storing it again
in the pickup payload.

The XP pool module accepts ordered explicit death drops and pickup observations.
It preserves ascending free-slot allocation, the first marked accumulator,
otherwise the farthest pile with stable tie order, ordinary U32 merge behavior,
and the selected accumulator's existing location/generation/age. New pile
locations use the existing placement policy.

The pickup encoder emits named objects with a tagged `item` payload. No pickup
wire field is named `hp` or `maxHp`.

## Verified before ECS integration

- Freshly emitted collection/pool/encoder checks pass for all reward kinds,
  one-time collection, stable generation, free-slot allocation, marked/farthest
  overflow, tie ordering and unsigned wraparound.
- An external temporary oracle compared 300 seeded pool scenarios against the
  existing production batch function. Every resulting pickup spatial value,
  amount, active state, accumulator marker and generation matched exactly.
  The compatibility-shaped fixtures exist only in the temporary oracle; they
  are not runtime readers or maintained pickup inputs.
- Two source mutants compile and are rejected by the focused checks: dropping
  overflow credit and replacing a new pile generation with zero.
- The BendHub dependency audit passes after initializing the existing pinned
  proof-library submodule. No dependency pin changed.

Artifacts are outside source under `/tmp/issue7-pure`,
`/tmp/issue7-pure-equivalence.mjs`, and the mutation directories recorded by
`/tmp/issue7-pure-mutation-receipt.json`.

## Remaining GH7 work after the enemy handoff is available

1. Store only the explicit pickup payload in the pickup column. Read canonical
   identity and shared spatial state through declared query contracts. Extend
   spatial membership to XP slots; enemy/relic slots retain their actual spatial
   state while occupied by loot.
2. Consume typed enemy death rewards, including non-XP loot. Preserve relic
   placement and collection coordinates as well as XP pooling/admission.
3. Add typed pickup snapshot and row cases and named frame pickup observations;
   remove every pickup reconstruction through the remaining actor aggregate.
4. Migrate native drawing/maps, browser drawing/maps, co-op allocation and
   playback metadata, bot/offline inputs, audio observations, and exact replay
   output together. Remove the former health-slot interpretation from the wire.
5. Prove applicable concrete transitions after the decision/law mapping is
   checked; add production integration and capability controls and run strict
   current-schema plus frozen-baseline comparisons. The pure stage does not
   establish that the new policies are connected to gameplay yet.
