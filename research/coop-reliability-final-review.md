# Independent reliability review — candidate 17 verdict

Reviewed 2026-10-25. **Approved for the declared bounded release criteria; no remaining blocker found in the reviewed delivery, clock, lifecycle, artifact-identity and receipt-boundary scope.** This verdict applies to candidate 17's frozen artifact and evidence, not arbitrary networks, physical Safari/iOS, every game seed or universal 60 FPS. It supersedes the candidate 15 disposition below; earlier failures remain historical evidence. HitEffects and SnapshotReceipts core policies remain excluded from this reviewer's independent core claim because this reviewer authored them.

## Artifact and executed gate

Independently inspected `/tmp/coop-reliability-final17-complete-check.log`, `/tmp/coop-candidate17-full/summary.json`, all three `completion-*.json` traces, the recovery artifact, the current affected source and harness. The complete gate log contains **50/50 proof files passed**, **354/354 semantic mutants rejected**, fresh emitted-module checks, native geometry, capability checks and replay tests. Its runtime script emits into a fresh temporary directory and checks source fingerprints before/after; it does not use a stale `dist` as its model-test input. This review inspected that execution evidence rather than rerunning the entire gate.

All **41** before/after/expected runtime hashes agree with `examples/survivors/dist/web`, and all four scenarios use the same map. Every discovered relative static ESM import is hashed; dynamic worker/WASM entrypoints are explicit seeds. Current handwritten runtime `.mjs` files match the artifact. The build identifies dirty revision `3ef7bdc3ca12316f34258e1045529da45bebcd0a`, build time `2026-10-25T12:39:13.313Z`. Commit/release packaging must preserve or freshly verify this tested source snapshot; the dirty artifact must not be described as an already-tested clean commit.

The network harness records the declared seed override **1729** in every actual worker initialization, along with the originally requested random seed. This is deterministic fixture evidence, not coverage over all random runs. It also records the exact measurement start, eliminating the earlier approximate warmup reconstruction.

## Independent browser-trace readback

All cases inject 300 ms before guest message callbacks; 0/200/600 ms is additional delay before each guest native send. The oracle uses wall timestamps emitted inside the authoritative worker, with round matching. Independent recomputation from raw worker and guest rows exactly matches every reported lag sample count, maximum, p95 and five-second-window p95.

| Send delay | Worker-lag p95 / max | Five-second-window p95 values | Applied / eligible worker steps | Host-motion violations / eligible pairs |
| --- | --- | --- | --- | --- |
| 0 ms | 28 / 29 ticks | 28, 26, 28, 26 | 1,077 / 1,147 = 93.9% | 0 / 1,023 |
| 200 ms | 26 / 27 ticks | 27, 26, 26, 26 | 818 / 1,169 = 70.0% | 0 / 956 |
| 600 ms | 42 / 49 ticks | 45, 43, 41, 42 | 0 / 784 = 0% | 0 / 911 |

Applied counts were independently recounted. The unchanged motion check uses actual renderer-entry intervals and `4 × elapsed wall ticks + 1 world unit`; a raw-record cross-check found no violations in any case. There are zero recorded history-recovery transitions in these runs. The 0/200 cases satisfy the declared lag/window, motion and applied-step thresholds. Coverage percentages describe eligible worker steps, **not percentages of all transmitted commands delivered**. The 200 ms case still has 252 late rejections and eight buffer entries. Its success does not establish uninterrupted movement. Enemy motion remains diagnostic rather than universally speed-bounded.

The 600 ms case stays **bounded overload only** despite zero motion violations: guest movement is never applied, lag exceeds the playable threshold, and it has 24 buffer entries. No unexpected page/worker errors appear in the network matrix. Window depth reaches, but does not exceed, 16 in the delayed cases.

## Clock and receipt fixes

Source readback confirms explicit `Priming/Holding/Playing/Boosting` states, initial guest buffer 6, established-stream refill 1, emergency entry above `delay + 4`, exit at or below `delay + 1`, and maximum rate 84 Hz. Resume credit is capped at **33,334 microseconds**, including after a long callback absence; history loss resets to Priming. Remote actors, confirmed trajectories and contacts retain one shared timeline; local input clocks are not accelerated. Candidate 16 exposed the underflow recovery counterexample: overall p95 34, maximum 37 and final-window p95 37. The 39,442-check emitted playback run preserves that exact former failing trace as a regression, now p95 27 with window values **27/27/30**, and includes slow-producer diagnostics. At sustained 45/30 Hz it explicitly records 25%/50% stationary samples with no boost: this controller does not promise smoothness when the producer is slow. The emergency mode trades up to 40% faster visual progression for shorter recovery; it does not alter authoritative physics.

The complete gate also passes the exact-string trie theorem, including arbitrary trie representations, and journal equivalence/duplicate-event fixtures. `Core.journal_clock` now caps contact rows **before JSON serialization**, then the worker accounts for source omissions through `ingest_capped`. The supplied dense check processes 8,000 source contacts into **512 emitted contacts + 7,488 omitted**, produces a **152,954-byte** frame, preserves canonical Core state/geometry, and passes the small-stack receipt checks. Fresh log medians for bounded ingest/collect/play paths are approximately **2.3–5.3 ms**. These measurements address the former oversized-frame/stack-overflow boundary; they do not prove a complete dense game frame fits 16.7 ms. The same log records raw source-contact construction at 16.823 ms before additional work, and a prior audit reported about 28.5 ms. Dense-world stutter remains a disclosed performance risk; overflow intentionally omits cosmetic witnesses and counts them.

Late sampling remains after expensive local preparation; opening the map uses the cached painted frame. Source and recovery evidence confirm map counts **28 → 28 → 28**, without consuming an extra sample. A renderer exception is made visible and drawing is suppressed for the failed session while RAF scheduling survives; a new room resets the failure and draws again.

## Lifecycle qualification and remaining limits

Recovery evidence contains only the two deliberately injected exceptions. It verifies visible worker failure and renderer failure, a new room without reloading the host page, nine new-run draws after renderer failure, two-pointer touch ownership/release, map behavior, and active phase-zero rejoin. The active world pauses at **28**, rejoins the same run/round/invitation at **28**, advances to **43**, and applies fresh nonneutral guest sequence **2** at tick **39**.

This is Chromium/CDP mobile emulation with actual Iroh IO and declared test hooks. Physical Safari/iOS, long sessions, broader jitter/loss and seed coverage, arbitrary dense gameplay cost, and all-weapon visual correctness are not established. The code/proof/runtime evidence is consistent with the existing [industry comparison](coop-reliability-industry-audit.md) and [compression audit](coop-snapshot-compression-audit.md); neither those sources nor finite queue caps are a universal availability guarantee. No additional blocker was found against the stated bounded criteria.

---

# Independent reliability review — current disposition

## Candidate 15: approved for the declared bounded criteria

Reviewed 2026-10-25. **No remaining blocker was found within this review's delivery, clock, presentation-order, lifecycle and evidence scope. Candidate 15 meets the declared 0/200 ms regression criteria.** This is not an approval of arbitrary networks or all combat/performance paths; the separate capsule/contact performance audit remains outside this review. HitEffects and SnapshotReceipts core policies remain excluded from this reviewer's independent core claim because this reviewer authored them.

Inspected the actual files in `/tmp/coop-candidate15-late-sample/`: `summary.json`, `completion-0.json`, `completion-200.json`, `completion-600.json`, and `worker-recovery-touch.json`. The summary is written only after all scenarios and their assertions finish. Its scope is the full network matrix plus recovery/touch, not a recovery-only rerun. The frozen artifact remains `examples/survivors/dist/web`, dirty revision `3ef7bdc3ca12316f34258e1045529da45bebcd0a`, now built at `2026-10-25T11:06:50.891Z`.

### Disposition of the candidate 12 blockers

1. **Worker-clock oracle: resolved.** The harness timestamps advanced steps inside the host worker with `Date.now()`, recording the actual `worldTick` and round. The oracle now compares each guest draw with the most recent applicable worker step, not the host's interpolated display. Independent joins over raw worker/guest records reproduce p95 **28/28/44** and maxima **29/29/47** for 0/200/600 ms. The independent cutoff used first positive guest arrival plus five seconds, admitting one additional sample per case; reported percentiles and maxima were unchanged. Worker timestamps are monotone in these traces. Every asserted five-second active window in the 0/200 cases satisfies the unchanged 30-tick p95 bound.
2. **Codec/import identity: resolved.** A JavaScript syntax parser discovers the relative static ESM dependency closure without evaluating modules; dynamic worker/WASM entries remain explicit seeds. All recorded dependencies have hashes. All **41 files**, including the codec, match the current frozen artifact; before/after/expected maps agree across the network scenarios, and recovery uses the same map. Codec SHA-256 is `a172541a90c1c255e07ad9cb619428626233404edb634b170d40c1a32909c1e0`. This closes the former omission for the new runs; it does not retroactively upgrade candidate 12.

### Verified result and limits

All network cases still inject 300 ms before guest message callbacks. The following delay is additional waiting before each guest native send; it is not a claim about universal RTT tolerance.

| Send delay | Actual applied / eligible worker steps | True worker-lag p95 / max | Host-motion violations | Buffer entries / history recoveries |
| --- | --- | --- | --- | --- |
| 0 ms | 1,007 / 1,075 = 93.7% | 28 / 29 ticks | 0 / 868 pairs | 1 / 0 |
| 200 ms | 469 / 866 = 54.2% | 28 / 29 ticks | 0 / 926 pairs | 1 / 0 |
| 600 ms | 0 / 782 = 0% | 44 / 47 ticks | 3, diagnostic only | 14 / 3 |

Applied-step counts were independently recounted from worker records. They measure coverage of eligible simulation steps, **not the percentage of sent commands accepted**. The 200 ms case passes the declared 50% criterion narrowly, still records 334 late rejections and prediction-horizon holds, and does not establish uninterrupted movement or all-command delivery. The motion oracle was independently recomputed from render records: it retains the original `4 × elapsed wall ticks + 1 world unit` allowance and finds zero violations at 0/200. Its timestamp is renderer entry, not a measurement of physical display scanout. Enemy motion remains diagnostic only. The 600 ms case has no unexpected fatal errors but has no applied guest input and visible recovery/motion failures: **bounded overload only, not playable or smooth co-op**.

Source readback confirms window **16**, one composite guest writer, serial decoder **16 jobs / 16 MiB**, 1 MiB per-frame/output admission, eight retained presentation frames, and 66 Hz catch-up above `delay + 1`. The current codec check independently passes **137 assertions**. These finite limits still do not bound every browser-native allocation or guarantee delivery availability.

Heavy local bootstrap/contact preparation now runs before the single fresh remote sample. The displayed confirmed cohort uses that late sample; the motion denominator remains actual renderer-entry wall time. Map opening uses the cached displayed frame rather than advancing presentation. The recovery artifact records map sample counts **27 → 27 → 27** through open/close, so it does not consume contact effects through an extra sample. Remaining post-sample work can still vary; these runs are evidence for the observed envelope, not a universal frame-pacing proof.

The earlier terminal-only reconnect limitation is now supplemented by an active scenario: phase-zero world suspends at tick **28**, rejoins the same run/round/invitation at **28**, reaches **43**, and applies fresh nonneutral guest sequence **2** at tick **40**. The same artifact confirms visible injected worker failure, successful new-room creation, distinct owner/second touch pointers, preservation of movement on second-pointer release, and neutral input on owner release. The sole recorded recovery error is the deliberate injected worker exception. This remains Chromium mobile emulation, not physical Safari/iOS qualification.

The historical candidate 12 findings and their original failed disposition follow unchanged. Long sessions, wider jitter/loss/background regimes, all-weapon contact geometry, physical devices and the separate performance audit require their own evidence; the present bounded approval does not subsume them.

---

# Independent reliability review — candidate 12

Reviewed 2026-10-25. **Acceptance remains blocked pending corrected instrumentation and new runtime evidence.** The code and supplied artifacts support bounded delivery and several successful interaction checks; they do not establish the required authoritative lag bound. The owner accepted both blockers below and is preparing a new candidate without relaxing the 30-tick oracle.

## Scope and identity

Inspected the frozen browser/worker integration, ClientDelivery, SnapshotFlow, Playback, Prediction, ClientClock, serial snapshot decoder, and presentation/contact integration. Reviewed the actual JSON in `/tmp/coop-candidate12-window/completion-{0,200,600}.json` and `/tmp/coop-candidate12-recovery/worker-recovery-touch.json`, plus the instrumentation that produced them. This reviewer authored HitEffects and SnapshotReceipts: their core policies are **excluded from the independent core-review claim**; their call-site ordering and lifecycle wiring were inspected.

The artifact is `examples/survivors/dist/web`, built from dirty revision `3ef7bdc3ca12316f34258e1045529da45bebcd0a`, with recorded build time `2026-10-25T10:33:03.502Z`. Every recorded hash matches that artifact, all three network cases have identical before/after/expected maps, and the recovery case has the same map. This is not a clean-commit qualification. The missing runtime dependency described below prevents treating those maps as a complete source-identity check.

## Blocking findings

1. **The lag oracle measures host display, not host authority.** `authorityLag(hostTrace.renders, guestTrace.renders, start)` compares rendered ticks. The host also passes through Playback interpolation (`delay_for(0)=3`), so its display is behind the worker. The reported p95 values 24/27 ticks therefore understate authoritative lag. As an independent cross-check, joining each phase-zero guest render to the last host `snapshotSends` row at or before its wall timestamp gives p95 **28/31/45** and maxima **29/35/49** for the 0/200/600 cases. A prepared snapshot tick is only a lower bound on the then-current authoritative tick. For 200 ms, 45 of 899 samples exceed 30; the p95 remains 31 when the approximate warmup cutoff moves forward by 20, 100, 500 or 1,000 ms. Thus this is not just a metric-label problem: even that lower bound fails the 30-tick requirement. Worker step telemetry currently lacks wall timestamps. Required closure: timestamp actual worker ticks, compute the oracle against that clock, and rerun without lowering the threshold.

2. **The runtime identity list omits the codec.** The harness's explicit file list excludes `coop-snapshot-codec.mjs`, although the browser imports it. The current frozen artifact and source both contain codec SHA-256 `4c80db2e4c0a6c30e9f514a7974258a1ecc78446133d43df78d2076b9390f7cd`, but that equality does not retroactively prove which bytes were served throughout the earlier runs. Required closure: include the relative ESM dependency closure in before/after/expected identity checks and rerun. The owner chose this stronger closure rather than qualifying away the omission.

## What the supplied runtime evidence establishes

All network cases inject 300 ms before the guest message callback; 0/200/600 denotes additional delay **before each guest native send**, not a universal RTT or packet-loss profile. Chromium runs last about 38–39 seconds including reconnect checks. Render metrics exclude a five-second warmup and cover roughly 16–18 seconds of active gameplay.

| Guest send delay | Applied / eligible worker steps, independently counted | Reported display-lag p95 | Host motion violations | Buffer entries / history recoveries |
| --- | --- | --- | --- | --- |
| 0 ms | 1,281 / 1,344 = 95.3% | 24 ticks | 0 / 954 pairs | 0 / 0 |
| 200 ms | 719 / 1,009 = 71.3% | 27 ticks | 0 / 896 pairs | 6 / 0 |
| 600 ms | 0 / 785 = 0% | 44 ticks | diagnostic only | 16 / 0 |

The 0/200 cases satisfy the existing applied-input and default-character motion checks, with no recorded unexpected page/worker errors. The 200 ms case still has 187 late input rejections and six buffer-entry transitions: it does not demonstrate uninterrupted 60 Hz input or an absence of pauses. Enemy motion is diagnostic only; the harness asserts no universal monster-speed bound. The 600 ms case is **bounded overload, not playable co-op**. Its maximum observed outstanding snapshot window is 12, with 1,490 prediction-horizon block observations and no applied guest input.

The recovery artifact records one deliberately injected worker failure, visible failure handling, successful creation of a new room, two distinct touch pointer IDs, second-pointer release followed by owner release, and neutral input after owner release. The test uses Chromium mobile emulation/CDP; it is not a physical iOS/Safari test. All three network-case reloads reconnect to **phase 3 at the unchanged terminal tick**. They establish same-invitation terminal-session reconnect, not active-gameplay resumption with new applied input. A stronger mid-run recovery claim needs its own phase-zero scenario.

## Architecture readback and remaining limits

- ClientDelivery owns one composite native flight. Prepare reserves both optional children together; completion matches the captured epoch/id and completes the captured child batch/receipt, preserving newer pending work. Failure freezes the composite. The host decodes the whole payload before processing its receipt; worker-inbox rejection produces an explicit failure rather than silent input loss. Native completion remains distinct from actual input application.
- SnapshotFlow admits twelve application-unacknowledged observations, one native writer and one replaceable pending payload. The decoder serializes twelve total jobs with a 12 MiB compressed queue limit and 1 MiB per-frame/output admission limit. Epoch transitions replace/close the queue; pre-await, post-await and rejection-path fences protect replacement connections. The independent current-code codec check passed 133 assertions. Output caps do not bound every browser-internal allocation.
- Remote actors, confirmed trajectories and contact playback share one interpolated sample. Prediction keeps immutable input target ticks, extends its cursor only forward within the bounded horizon, and does not turn a skipped interval into commands. Local projectile animation uses a separate bounded wall clock. No new blocking code defect was found in these inspected paths.
- Playback's 66 Hz catch-up outside its deadband is a bounded interpolation-time controller, not a change to authoritative physics. It still holds/refills on underflow. History has eight frames; eviction can still seek to the oldest retained frame after a large interruption. Zero recorded recoveries in these short cases is not proof that bursts or background suspension cannot trigger recovery.

These choices align with the separation of local prediction and remote interpolation discussed in the existing [industry audit](coop-reliability-industry-audit.md), and with [Mirror's interpolation timeline correction](https://mirror-networking.gitbook.io/docs/manual/components/network-transform/snapshot-interpolation). Browser compatibility and full-stream gzip validation remain subject to the [Compression Standard](https://compression.spec.whatwg.org/) and the [WebKit allocation qualification](https://docs.webkit.org/Deep%20Dive/Modules/CompressionStreams.html), detailed in the [codec audit](coop-snapshot-compression-audit.md).

Pure-law and mutation totals supplied by the owner are separate evidence, not independently rerun here; final runtime gate completion was still pending. The [local-projectile proof boundary](coop-local-projectiles-proof-boundary.md) explicitly excludes planner/ECS integration. This review does not establish all-weapon visual contact correctness, arbitrary network availability, long-session stability, or cross-browser/device readiness. Candidate 12 is not a final accepted artifact until the two blocking evidence defects are closed with new measurements.
