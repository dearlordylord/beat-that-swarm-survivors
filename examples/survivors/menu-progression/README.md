# Browser progression boundary

`../menu-progression.bend` owns the browser profile defaults, normalization,
requirements, upgrade prices, purchase eligibility and transitions, weapon
availability, setup validation, observed weapon history, run rewards and
achievement awards. The version-1 JSON save format and storage key are retained.
It imports only Base, so the menu does not load the simulation or renderer.

`../progression.mjs` transports generic JSON-shaped values and reads/writes
localStorage. It does not calculate gameplay prices, thresholds, eligibility,
loadout validity or rewards. The supplied catalog is generated from Bend.

The value transport keeps integer/rational values exact with decimal limbs when
Bend's immediate Nat representation would overflow. It preserves finite JSON
numbers, including small fractional saved survival values and counters above
the F32 exact-integer range. Non-finite host values become null. The host codec
converts exact returned ratios to JavaScript numbers; it does not decide any
game rule. Generic numeric coercion accepts ordinary decimal strings in saved
numeric fields; malformed values normalize to zero or their field default.
Historical coercion of hexadecimal/exponent strings is not a supported save
format. Ordinary JSON numeric exponent notation is supported by the transport.

Run from the repository root:

```sh
BEND=bend bash examples/survivors/menu-progression/test.sh
```

The four laws establish only that rejected upgrade/unlock decisions return no
replacement profile, already-recorded signatures leave the whole profile
unchanged, and arcana availability follows membership in the supplied catalog.
They do not prove successful-purchase debit arithmetic, decimal arithmetic,
catalog provenance, or permanent deduplication: the existing history retains
100 run signatures. The proof gate uses the independent `--verdict` checker.
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
