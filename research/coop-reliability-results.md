# Browser co-op reliability results

Candidate 17 passed the complete repository gate and actual-Iroh matrix on
2026-10-25. Independent final review approved the declared bounded criteria. Publication
must rebuild current committed source and verify the tested runtime hashes.
The baseline was `5aff25371637f14dca5bfa879968b630344edd22`; parallel menu commits
are preserved outside the network review scope.

## Why it jerked, and what changed

The browser guessed future host movement and combat, then replaced that world
when authority arrived. A host reversal invalidated the guess for the player,
monsters and shots together. Remote players, monsters, confirmed projectiles
and impacts now share one bounded authoritative interpolation timeline. Only
local movement and cosmetic shots are anticipated; damage and progression
remain host-owned Bend ECS execution. Stable lifetimes prevent pooled entities
from inheriting an old actor's trajectory.

Per-tick input and separate acknowledgement traffic competed through native
sends. A completed local write did not mean the guest had parsed or applied a
snapshot. One bounded composite client writer now carries input batches and
the latest cumulative receipt. SnapshotFlow owns sixteen application-unacknowledged
observations, one native writer and one replaceable pending payload. Epochs
fence old success and failure callbacks; serial bounded gzip decoding verifies
complete frames before admission. These are distinct transport and application
receipts, not interchangeable delivery guarantees.

Clock bugs amplified jitter. Sampling uses actual monotonic time after expensive
preparation, once per painted frame; opening the map does not sample again.
Priming and starvation recovery have separate rules. Ordinary playback uses
60/66 Hz; a hysteretic emergency mode permits 84 Hz briefly to remove excess
buffering. Resume credit is capped at 33,334 microseconds, including after a
background gap. This is a visible cosmetic speed tradeoff; authoritative physics
and local input/shot clocks keep their own budgets. A saved failed trace rejects
the old policy without changing the lag or motion thresholds.

Confirmed contact receipts come from the same prepared resolver as damage.
The shot endpoint and effect use the same displayed target lifetime and pose,
or the same canonical fallback. Cosmetic emission is capped before JSON, while
all authoritative outcomes are retained. Exact string indexing replaces repeated
long-ID scans and is proved equal to the original FIFO deduplication reference.
Worker and rendering failures remain visible with copyable diagnostics. A failed
draw pauses rendering without killing its scheduler; a new room resumes drawing
without a page reload.

## Qualification

The complete `examples/survivors/check.sh` exited zero: **50/50 proof entrypoints**,
**354/354 semantic mutants rejected**, freshly emitted model and adapter checks,
dense contacts, native geometry, capability controls and replay-tool checks.
New core scopes include 72 Playback laws, 27 exact-set laws and 84 Journal laws.
The clock's 39,442 executed checks include the retained producer-gap trace,
45/30 Hz producers and long-background resume.

The actual-Iroh Chromium matrix used default characters, worker seed **1729**,
32 seconds of scripted input, 300 ms additional observation delay and the
following delay before each guest native send. The seed and thresholds were
fixed before the run. Lag is measured against actual advanced host-worker ticks.

| Extra native-send delay | Lag p95 / max, ticks | Applied / eligible worker steps | Remote-host motion violations | History recoveries | Meaning |
| --- | --- | --- | --- | --- | --- |
| 0 ms | 28 / 29 | 1077 / 1147 (93.9%) | 0 | 0 | Interactive regression passed |
| 200 ms | 26 / 27 | 818 / 1169 (70.0%) | 0 | 0 | Interactive regression passed |
| 600 ms | 42 / 49 | 0 / 784 | 0 | 0 | Bounded overload only; not playable |

Every measured five-second window met the unchanged 30-tick p95 bound in the
0/200 cases. Applied-step coverage is not the fraction of all commands delivered,
and late rejections still occur. Recovery checks passed active phase-zero guest
reload with fresh input application, two-touch ownership/release, map sampling,
visible worker and renderer failures, and new-room rendered frames without
reloading the host page. All 41 served files in the static import closure matched
the frozen artifact before and after the scenarios.

The retained [qualification data](coop-reliability-qualification.json) contains
metrics, tested artifact hashes and gate evidence. The [dense audit](coop-dense-contact-audit.md)
records the real 8,000-contact geometry: exact suffix 512, 7,488 omitted cosmetic
receipts, unchanged Core state, and a 152,954-byte frame instead of 2.38 MB.
Indexed journal operations measured about 2–7 ms in those bounded cases;
constructing all 8,000 raw receipts still measured one 28.517 ms burst. That
remains a possible one-frame stutter, not a whole-game 60 FPS qualification.

## Review cycles and lessons

The [acceptance plan](coop-reliability-plan.md) retains rejected candidates.
Independent reviews found defects in both implementation and evidence: a lag
oracle comparing two delayed displays, an omitted codec in the import closure,
a renderer failure that permanently stopped RAF, and underrun/refill amplification.
Their counterexamples were retained and affected paths rechecked. See the
[standards](coop-reliability-standards-review.md),
[spec](coop-reliability-spec-review.md),
[integration](coop-reliability-integration-review.md),
[architecture](coop-reliability-architecture-review.md) and
[final](coop-reliability-final-review.md) reviews.

The [industry audit](coop-reliability-industry-audit.md) links primary engine
documentation. The reusable lessons are separate clocks and receipts, bounded
work at the producer boundary, immutable input target ticks, stable actor
lifetimes, one coherent remote timeline, explicit starvation recovery and
measurement against simulation authority. They are saved in the repository-local
[networking skill](../skills/realtime-netcode/SKILL.md); it is not installed globally.

## Reproduce and interpret

```sh
BEND=/home/node/.bend/bin/bend bash examples/survivors/check.sh
```

The [browser harness](../tools/survivors-bot/coop-reliability-browser-check.mjs)
uses an existing Playwright/Chromium installation and a frozen built site.
Set `COOP_TEST_SEED=1729` for the qualified world. It retains exact measurement
start, worker initialization seeds and parsed static-import closure hashes.

Kernel proofs establish the stated pure Bend policies; the mutants are permanent
regressions run by the normal gate. Neither proves browser scheduling, transport
availability or the whole game. Typed adapters, dense geometry and actual-Iroh
traces supply separate finite evidence. The
[local projectile boundary](coop-local-projectiles-proof-boundary.md) records
the integration scope explicitly. Chromium mobile emulation is not physical
Safari/iPhone qualification. A slow or suspended host can still cause holds;
there is no host migration. Arbitrary networks, all weapons on every device
and unbounded session duration are not established.
