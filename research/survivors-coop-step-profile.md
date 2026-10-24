# Shared-world step profile, 2026-10-24

A real two-browser run rendered at 60 FPS but advanced only 36 simulation ticks
in 5.014 seconds. Profiling the generated JavaScript separated the authoritative
Bend step from observation and rendering. The slowdown was in the step.

## Mechanism and changes

V8 sampling of the original generated core attributed approximately 5.8 seconds
of self samples to `pickup_radius` and 2.8 seconds to garbage collection in the
short diagnostic. `owned_row` eagerly resolved the collector six times for every
pool row, including rows carrying no pickup events. The same per-player owned
row list was constructed twice. Collector resolution repeatedly walked both
players' passive lists.

The Bend core now resolves a collector once only when a row contains XP, gold,
healing, chest or relic events. It builds each player's owned rows once and
reuses them for totals and kill bookkeeping. The player's detached run view is
also resolved once per owned-row traversal.

The profile also exposed eager evaluation of all camera exclusion checks for
existing bodies. `team_spawn_fresh` now branches before those checks. Actual
newborns, including boss resets, retain the same admission checks against the
finalized living-player camera positions.

A second profile found the weapon request loop walking eight logical slots for
all 24 owners, including unowned weapons. It now skips those owners before the
slot loop, preserving the Arcana 4 reactive weapon-19 exception even when that
weapon is unowned. Allocation order, budgets, occupied slots and provenance are
unchanged.

## Diagnostic results

Linux arm64, Node 24.20.0. Other workspace backend qualification was active during
some runs; these are local diagnostics rather than a general hardware guarantee.
Timing surrounds quiet Bend calls, excluding world hashing and rendering.

| Comparison | Original core | Candidate core |
| --- | ---: | ---: |
| Interleaved 35 ticks, first 5 excluded: median step | 150.10 ms | 17.48 ms |
| Same run: total of 30 measured steps | 4668.15 ms | 574.58 ms |
| Same run: median observation, 10 calls | 0.89 ms | 0.80 ms |

The candidate alone advanced all 80 requested ticks in phase 0. With its first
20 ticks excluded, 60 quiet steps took 850.16 ms total: median 13.36 ms,
minimum 10.72 ms and maximum 23.37 ms. This is an early-game workload, not a
qualification of every late-game horde or the complete browser/network loop.

## Behavior evidence

The exact preserved original and candidate generated cores received the same
35 movement commands. Complete authoritative state hashes matched at every
tick, without excluding columns, allocator state, routing, player components or
reward state. Both players' observations also matched exactly.

An independent original request enumerator compares all ordered requests across
720 fixtures: 12 Arcana choices, three invulnerability values, five tick values,
unowned/full weapon sets, and clear/full lock masks. All comparisons passed.
The permanent enumerator lives in the test-only `coop-solo-oracle.bend` and does
not call the optimized owner filter.

Final release qualification additionally runs the shared-world accepted-command
replay, direct co-op mechanics, effects, complete-state solo schedule oracle,
and actual two-browser Iroh smoke checks. Their current results belong in the
co-op validation report, rather than being inferred from this short profile.

## Artifact identity

Diagnostic originals were preserved before candidate emission in
`/tmp/bendvy-coop-step-profile/baseline`; generated outputs are untracked.

| Artifact | SHA-256 |
| --- | --- |
| Original generated Game | `1c07b99cb74efe94b374d30d08701495c5780bd585c21c4543f20251fbab6e66` |
| Original generated core | `f12d01f4d5165794d8c703f2af6010cbe6f057350f09fab30249ec38cab42a77` |
| Candidate generated Game | `65e8f3ededad996ec0ae39837613fa9373e2cc7567bf836c5f627ff82f8657d4` |
| Candidate generated core | `c08ecae8d824ed096317b2af6a62e9b75850fda590f1228280438a52f1853291` |
| Candidate `game.bend` | `bf95864fe27ae0e93bb1db3eb5ba5cd9d205e0ce47833815f71322c6f755ef5e` |
| Candidate `coop-core.bend` | `6f3d25fec341da413b2a164e9cb30d4fd19b453138427b9f1c497f8e1398d1cd` |

The original authored-source fingerprint was not captured by the ordinary web
build, so the original generated-artifact hashes are the precise baseline
identity. The diagnostic scripts, V8 profiles and generated modules remain under
`/tmp/bendvy-coop-step-profile` for inspection during this session.
