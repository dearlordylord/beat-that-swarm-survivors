# Browser progression boundary

`../menu-progression.bend` owns the browser profile defaults, normalization,
requirements, upgrade prices, purchase eligibility and transitions, weapon
availability, setup validation, observed weapon history, run rewards and
achievement awards. The version-1 JSON save format and storage key are retained.
It imports only Base, so the menu does not load the simulation or renderer.

`../progression.mjs` transports generic JSON-shaped values and reads/writes
localStorage. It does not calculate gameplay prices, thresholds, eligibility,
loadout validity or rewards. The supplied catalog is generated from Bend.

The generic value codec belongs to [progression.mjs](../progression.mjs) and
[menu-progression.bend](../menu-progression.bend). Numeric transport and save
normalization must preserve the distinction between representing values and
deciding game rules; their exact coercion behavior belongs to the sources and
[contract checks](contract.test.mjs).

Run from the repository root:

```sh
BEND=bend bash examples/survivors/menu-progression/test.sh
```

The [laws](LAWS.bend) establish only that rejected upgrade/unlock decisions return no
replacement profile, already-recorded signatures leave the whole profile
unchanged, and arcana availability follows membership in the supplied catalog.
They do not prove successful-purchase debit arithmetic, decimal arithmetic,
catalog provenance, or permanent deduplication beyond the history retained by
the implementation. The proof gate uses the independent `--verdict` checker.
Three deliberate implementation mutants must fail at their corresponding law.
A duplicate-reward mutant is detected through the actual emitted transition.
Its unrestricted symbolic proof mutation exceeded the 10 CPU-second budget,
so it is not reported as a proof-mutation rejection.

Runtime contract checks cover 500 generated nested transport round trips,
floating-point extremes, save normalization idempotence, large counters,
fractional survival, malformed saves, successful and rejected purchases, every
upgrade rank, bit packing, weapon-history retention and duplicate run rewards.
During migration, 150 deterministic profile fixtures also matched the previous
JavaScript implementation across every catalog upgrade/unlock decision,
weapon availability, run recording and achievements; that temporary reference
is not retained as another gameplay implementation.
