# Pickup and reward migration (GH7)

The gameplay path stores `Pickup.Payload` separately from canonical spatial
state and immutable slot identity. Tagged XP, gold, healing, chest and relic
payloads carry their actual reward values. The runtime has no pickup amount or
generation interpretation through health fields.

`Pickup.State` is an immutable phase observation. Enemy/relic loot keeps its
shared spatial column throughout occupancy; the persistent XP pool has its own
spatial membership. The pickup query reads spatial state, payload and identity;
the lifecycle query writes spatial state and payload, and enemy/relic lifecycle
also writes the explicit enemy-slot phase. Co-op assigns each collected reward
to one eligible collector and reduces shared progression once.

Typed enemy death rewards feed non-XP payload creation or the persistent XP
pool. The pool preserves ascending free-slot allocation, the first marked
accumulator, otherwise the farthest pile with stable tie order, U32 wrapping
merge, and the accumulator's position/generation/age. New locations use the
existing placement policy. Boss proposals still precede occupied-loot updates;
a rejected fresh spawn retains loot age, clears enemy status, and cannot collect.

Native rendering, browser rendering/maps, playback metadata and controller goals
consume typed pickup observations. Named frame pickups expose `slot`,
`generation`, `active`, geometry and tagged `item`; they expose no `hp` or
`maxHp` aliases. Audio pickup cues use authoritative progression totals. Playback
carries a boolean liveness fact and an explicit pickup lifetime, separately from
reward values.

## Evidence

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
  subsequent collection: XP, gold, healing, no repeated grant, typed death
  handoffs, rejected occupied-slot turns and two-player shared XP allocation.
  It is part of the fresh-emission co-op reliability procedure.
- Native XP rendering passes six size/color checks, including marked overflow;
  its five-pile capture remains outside source under
  `/tmp/issue7-native-loot-capture/experience-piles.ppm`.
- The corrected native co-op runner typechecks with separate session and player
  authority. Its existing metrics executable passes 18 classification cases;
  an actual native run reaches tick 60 with valid population/XP fields in
  `/tmp/issue7-offline-coop-run.jsonl`.
- `pickup_qualification.py` validates current raw payload membership, tagged
  values, occupancy/phase and spatial facts, joining physical handles to
  canonical identities without assuming index equals identity. Five focused
  tests include nonmatching handles, malformed payloads/phases and authority
  mutations. Six actual raw checkpoints pass; raw XP amount and generation
  mutations change the exported facts.
- A temporary pre-integration oracle compared 300 seeded pure pool scenarios
  with the frozen implementation exactly. This supports pool-policy continuity;
  actual storage wiring is covered by the separate checks above.

Combined GH5/6/7 qualification owns complete current-schema validation, strict
same-schema replay, frozen-baseline comparison, all entrypoint checks and final
review. Individual local receipts do not replace those combined gates. Generated
modules, binaries, captures and profiles remain outside tracked source. No
package pin, pool budget or gameplay balance changed.
