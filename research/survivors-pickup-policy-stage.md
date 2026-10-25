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

- Four approved laws pass kernel `--verdict`: exact collected-XP outcome,
  arbitrary inactive pickup inertness, wrapping overflow amount, and preserved
  overflow generation. Independent blind backtranslation preceded proof. These
  laws do not claim universal geometric admission, every non-XP transition, or
  all pool ordering rules.
- Three maintained semantic mutants typecheck and fail their named proof gates:
  lost collection XP, lost overflow amount, and replaced overflow generation.
- `pickup-state-check.mjs` exercises all reward kinds, one-time collection,
  generation, free-slot order, marked/farthest overflow, ties and wrapping.
- `pickup-wiring-check.mjs` exercises actual world lifecycle/query writes and
  subsequent collection: XP, gold, healing, no repeated grant, exact collection-to-idle
  reset and first inactive-turn reset, typed death
  handoffs, rejected occupied-slot turns and two-player shared XP allocation.
  It is part of the fresh-emission co-op reliability procedure.
- Native XP rendering passes six size/color checks, including marked overflow;
  its five-pile capture remains outside source under
  `/tmp/issue7-native-loot-capture/experience-piles.ppm`.
- Native pause-map markers traverse active typed pickup snapshots. The actual
  native UI fixture checks chest/relic coordinates, inactive chest exclusion and
  XP exclusion; the full UI run passes with a fresh map capture under
  `/tmp/issue7-native-map-data/map.ppm`.
- The solo batch summary counts active typed XP snapshots and sums their explicit
  amounts. The existing native metrics fixture preserves its 18 population cases
  and checks two active piles totaling 13 XP, excluding inactive/non-XP data. It
  executes the real summary writer and checks the full-run planner's chest
  readiness filter, including relative order and other actor snapshots.
- The corrected native co-op runner typechecks with separate session and player
  authority. Its existing metrics executable passes 18 classification cases;
  an actual native run reaches tick 60 with valid population/XP fields in
  `/tmp/issue7-offline-coop-run.jsonl`.
- `pickup_qualification.py` validates current raw payload membership, tagged
  values, occupancy/phase and spatial facts, joining physical handles to
  canonical identities without assuming index equals identity. Five focused
  tests include nonmatching handles, malformed payloads/phases and authority
  mutations. Six actual raw checkpoints pass; raw XP amount, generation, age and accumulator
  mutations change the exported facts.
- A temporary pre-integration oracle compared 300 seeded pure pool scenarios
  with the frozen implementation exactly. This supports pool-policy continuity;
  actual storage wiring is covered by the separate checks above.

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
