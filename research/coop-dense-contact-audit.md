# Dense co-op contact journal audit

## Finding

The 512-event journal limit currently applies after Core has built and encoded
the entire contact list. A two-player late-game state can exercise the path
with 8,000 area contacts in one tick: each player can schedule eight weapon 11
shots, and the two-player spawn budget can admit 500 regular enemies. The
contacts are cosmetic records; this path does not change combat authority.

## Source path and reachable bounds

- [`game.bend`](../examples/survivors/game.bend) prepares the firing plan and
  contacts. `projectile_amount` caps each volley at eight; `scheduled_shot`
  selects the volley at the weapon cooldown. Weapon 11 creates age-zero,
  one-tick area fields. A rank-8 weapon with rank-5 passive index 4 schedules
  eight shots on the firing tick.
- [`party-difficulty.bend`](../examples/survivors/party-difficulty.bend) scales
  the solo spawn budget by the number of living players and clamps it to
  `Pools.max_regular_enemies() == 500`. [`pools.bend`](../examples/survivors/pools.bend)
  defines that cap. At tick 10,801 the solo `active_limit` has reached 300;
  two players can therefore reach the 500-enemy cap.
- [`coop-core.bend`](../examples/survivors/coop-core.bend) calls
  `Game.contact_team`, then `journal_team`, then `journal_clock`. The latter
  serializes every contact into the Core frame.
- [`coop-worker.mjs`](../examples/survivors/coop-worker.mjs) parses that frame
  locally and only then calls `HitJournal.ingest`. The oversized Core frame is
  not itself sent over the peer transport; the bounded journal is published
  afterward.

## Measurement

The dense fixture generated sixteen projectiles through `Game.team_shot_spawn`
for two `PlayerView`s, prepared the team through `Game.contact_team`, and
counted events from `Core.journal_team`. It used 500 valid enemy body snapshots
clustered within the fields and ran at tick 10,802. It did not replay a full ECS
world history to accumulate those bodies; the geometry and contact-journal
functions are the production functions.

The firing request check used weapon 11 at level 8, passive rank 5 at index 4,
and a tick with `tick % cooldown == 1`. `Game.shot_requests` selected eight
logical slots per player; the spawned fields had age 0, life 1 and pierce
9999. All 500 targets were inside the overlapping field areas.

On the existing compiled modules (`coop-core.mjs` SHA-256
`0e7da6d823a532f32ed02f3c916b03bd0e55bb709e0ba94d58d6aaebe742c716`,
`game.mjs` SHA-256
`4ce30b1744c1c77c7894149cc4a1bcf81ccfb0018db0936e0184387b31f00328`):

| Prepared contacts | Frame bytes | `journal_team` median | `journal_clock` median | `JSON.parse` median | `HitJournal.ingest` |
| ---: | ---: | ---: | ---: | ---: | --- |
| 8,000 | 2,388,539 | 8.87 ms | 19.71 ms | 9.48 ms | `RangeError: Maximum call stack size exceeded` |
| 4,800 | 1,489,339 | 4.80 ms | 12.49 ms | 3.99 ms | 3,818 ms median; retained 512 |

These are local Node timings on the existing artifact, not browser or
publication-build performance claims. The 8,192-contact case (512 targets) is
above the configured 500 regular-enemy cap; the reachable dense case measured
here is 8,000.

## Narrow correction

The working implementation caps contacts before `Journal.native_events`
serializes them. It preserves the journal's current suffix and event order,
includes `contactsOmitted` in the Core frame, and adds that count to the
journal's existing `State.overflow` counter through `ingest_capped`. This keeps
the state shape and combat/world execution unchanged while bounding the frame
and event list received by the worker.

## Capped-path validation

[`coop-dense-contact-check.mjs`](../examples/survivors/coop-dense-contact-check.mjs)
rebuilds the same 500-target, 16-field prepared team in code and asserts all
8,000 source contacts before capping. It checks that `journal_clock` emits the
exact last 512 records in the original order with `contactsOmitted == 7488`,
that the Core packet state is structurally unchanged, and that capped ingest
preserves IDs/lifetimes, counts overflow, and does not replay duplicates. A
separate `--stack_size=192 --journal-only` invocation caps 8,000 generated
events, exercises a prior full 512-event journal followed by the new bounded
suffix, and passes without stack growth. The fixture constructs valid snapshots
and calls the production spawn/contact/journal functions; it does not replay a
full game history.

On fresh temporary modules from the capped source, the 8,000-event path emitted
512 events plus `contactsOmitted=7488`. The Core frame fell from 2,388,539 to
152,954 bytes. This run measured `journal_clock` at 2.70 ms and frame parsing at
0.60 ms. Capped ingestion of 512 real event IDs measured 61.17 ms median,
reported by the check as above 16.7 ms without a timing failure gate. The
weapon-11 burst that generated this fixture has a 600-tick cooldown. The cap
removes the multi-megabyte frame and the observed unbounded-ingest stack failure;
it does not make the bounded deduplication work a few milliseconds.

A temporary reverse-accumulator prototype matched original append order and
duplicate behavior for fresh, prior-full, and duplicate-containing inputs. It
reduced repeated list copying in the code shape but did not materially lower
the 512-row CPU time. Before the exact-string trie optimization, the check
measured fresh512 at 60.72 ms, prior-full512 plus new512 at 180.58 ms, duplicate
resend512 at 122.40 ms, and expiring512 at 0.031 ms. A separate fresh ingest
measurement changed from 64.42 ms to 63.03 ms with the reverse accumulator.
These timings are local Node measurements, not browser or publication-build
performance claims.

The exact-string trie prototype cut journal work in the same runtime check to
2.343 ms for fresh512, 3.588 ms for prior-full512 plus new512, 2.283 ms for a
duplicate resend, and 0.017 ms to expire512. The same prototype's indexed
playback reduced `collect` and `play_sample` from 61–184 ms to roughly 2–4 ms
in the dense fixture. These prototype timings are superseded for runtime
comparison by the fresh candidate-16 artifact measurements below.

## Candidate-16 runtime check (proof pending)

The updated dense check passed three times against the frozen candidate-16
modules in `examples/survivors/dist/web/dist`. Module SHA-256 values were:

- `coop-core.mjs`: `b5fd5b286decf17bdae25630cf112040abfe193a74cd5cd56ed6dd6d64e5e356`
- `game.mjs`: `4ce30b1744c1c77c7894149cc4a1bcf81ccfb0018db0936e0184387b31f00328`
- `coop-hit-journal.mjs`: `7679948ee749ce2a72d9352882ca57f5152f0e26c8e577fe758836d9967ce279`

All three runs retained the exact 512-event source suffix, counted 7,488
omissions, produced a 152,954-byte Core frame, preserved Core state, and passed
the `--stack_size=192` 8,000-row cap/ingest check. The check also asserts exact
event order and one-shot behavior for fresh, prior-512-plus-new-512, and
duplicate `collect`/`play_sample` cases. The values below are medians of seven
calls within each run; the table reports the median of those three run medians.

| Operation on 512 IDs | Fresh playback/journal | Prior 512 + new 512 | Duplicate resend |
| --- | ---: | ---: | ---: |
| Journal ingest | 3.179 ms | 6.080 ms | 3.004 ms |
| Arrival `collect` | 2.898 ms | 6.095 ms | 3.350 ms |
| Presentation `play_sample` | 2.942 ms | 5.933 ms | 3.263 ms |

Expiry medians were 0.019–0.038 ms across the three runs. Core `journal_clock`
measured 3.34–5.95 ms, and parsing the capped frame measured 0.60–0.70 ms.
`Core.journal_team` was timed once per run at 30.03 ms, 20.67 ms, and 20.35 ms
for the deliberately dense 8,000-contact burst. That isolated geometry/journal
burst can exceed a 16.7 ms frame budget; the fixture does not establish that it
causes a steady-state frame-rate failure. It is a residual stutter risk worth
profiling in a browser if this extreme late-game state is a target.

These measurements verify runtime behavior of the served candidate-16 modules;
the exact trie and journal proofs were still pending at measurement time. They
are not formal proof completion, browser performance, or whole-game FPS claims.

## Final-source runtime check (build 17)

After the exact trie and journal proof gates passed, the dense check passed once
against the frozen build-17 `dist/web/dist` modules. The measured module hashes
were:

- `coop-core.mjs`: `5fe6eadbc6562313879b0cec892d4ebdce9c686e2ae1a85bf23d6003d3fdc244`
- `game.mjs`: `4ce30b1744c1c77c7894149cc4a1bcf81ccfb0018db0936e0184387b31f00328`
- `coop-hit-journal.mjs`: `11a54581056860d9536449aa317cc83afb77ec73687e4ea3448811ee459b8085`
- `coop-playback.mjs`: `a6fb36f9a1126b844d25b31d4eed50430665670d15d6696a6671774f5715b15e`

The run again produced 8,000 prepared contacts, retained the exact 512-row
suffix, reported 7,488 omissions, emitted a 152,954-byte frame, preserved Core
state, and passed the `--stack_size=192` cap/ingest check. Ingest, arrival
`collect`, and presentation `play_sample` assertions passed for fresh,
prior-512-plus-new-512, and duplicate cases. Seven-call medians in this run
were:

| Operation on 512 IDs | Fresh | Prior 512 + new 512 | Duplicate resend |
| --- | ---: | ---: | ---: |
| Journal ingest | 3.297 ms | 6.618 ms | 3.349 ms |
| Arrival `collect` | 2.429 ms | 5.233 ms | 3.013 ms |
| Presentation `play_sample` | 2.511 ms | 5.433 ms | 2.918 ms |

Expiry was 0.022 ms; `journal_clock` was 4.604 ms and capped frame parsing was
0.672 ms. `Core.journal_team` took 28.517 ms in its single timed execution for
the saturated 8,000-contact fixture. This confirms the cap and indexed journal
paths, while leaving the rare raw-contact burst as a possible one-frame stutter
in this deliberately dense case. The measurement does not establish a
steady-state or browser frame-rate result.

The parent reports the final strict gates passed with 27 laws for the exact
string set, 84 for the hit journal, and 3 and 36 mutants respectively. This
section records one runtime check against those proof-complete build artifacts;
it is not a browser or whole-game FPS claim.
