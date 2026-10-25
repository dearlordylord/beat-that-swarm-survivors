# Cooperative presentation integration review — cycle 3

Reviewed the working tree based on `3ef7bdc3ca12316f34258e1045529da45bebcd0a`. This is an independent integration review of lifecycle, delivery, presentation and clock wiring; it does not establish network delivery or universal browser correctness.

## Confirmed defect, repaired

**A new confirmed hit could disappear before the first animation frame.** The presentation adapter initially attached its effect-history ledger inside `sample()`. If snapshot A introduced an empty journal and snapshot B added a new hit before the first render, that first render attached to B and classified its new hit as historical. Advancing beyond its due tick never displayed it. The same ordering was possible after an epoch reset.

The actual-adapter regression failed before the fix. The adapter now calls Bend `HitEffects.receive` during each accepted snapshot intake. The first journal establishes the history baseline; subsequent journals in that epoch preserve the ledger. A hit received between initial intake and first render remains eligible when presentation reaches its timestamp. Rejected snapshots still cannot change the ledger.

Validation: `coop-playback-wire-check.mjs` passes **141 checks**, including the failing two-snapshots-before-first-RAF sequence, using freshly emitted HitEffects and the actual adapter at `--stack_size=192`. The check also covers stale/duplicate cache rejection and exact base-observation metadata. This is executed integration evidence, separate from Bend kernel checks.

## Other reviewed boundaries

- Snapshot delivery has one native writer, at most eight application-unacknowledged observations, and one replaceable pending payload. Native completion clears only the writer. A matching token and an observation actually in flight are required for cumulative application acknowledgment. The browser verifies that the selected Bend observation matches its pending payload before sending.
- Transport/reconnect resets delivery state; asynchronous completion handlers capture both run and connection incarnations. Worker reconnect preserves the world and resets the guest input lane. Lost transport pauses the run. Connection and transport generation checks prevent old callbacks from admitting a replacement guest's messages.
- Movement admission precedes prediction advancement. Local projectile animation uses a separate Bend client clock, so exhausted movement credit does not freeze an already released visual. Neither clock advances simulation by a JavaScript floating-point accumulator on the guest path.
- The presentation adapter rejects stale frames before changing raw caches, journals or metadata. Bodies use the selected **base observation's** metadata, while all remote combat positions use one sampled cohort. The cross-frame metadata fallback is limited to corpse lookup.

No second concrete integration blocker was found in these paths. Real Iroh/browser qualification remains necessary. An application ACK follows parsing, admission and synchronous UI presentation; it does **not** certify that a later canvas animation frame has completed. Presentation failures are reported separately.

## Reviewed source SHA-256

All paths below are under `examples/survivors/`:

```text
coop-browser.mjs        2787bdbfdc4164db07e2e4130c0d73dea16c7d45c784d5aee6f05e9da770ccd5
coop-worker.mjs         097eaf26721460af268380cc9808b359997fbca240dd7e0d8f1f91fec3f16a95
coop-presentation.mjs   27ae3edd6aa67107715b4c15d1c7872af3681a5734f20a18f0ed634f947dbd48
coop-snapshot-flow.bend e80d90c13ca1347ad8a25a11ad79ecd44164f09b5aed11e836dfb8a3eca194c7
coop-hit-effects.bend   c35488691a1419fee17f5b240cb18b137b0d0d8f936d73be6c3f1565a8b1dfca
```

## Final touch qualification correction

The later candidate-12 touch failure was a harness mistake. Chromium's [GenerateTouchEvents implementation](https://github.com/chromium/chromium/blob/main/content/browser/devtools/protocol/input_handler.cc) releases the IDs supplied to `touchEnd`; an empty list releases all remaining points. Sending `[first]` therefore released the owner. Chromium 153.0.8010.12 reproduced this with actual pointer events. The corrected harness releases the second finger first and asserts actual pointer IDs before checking preserved movement, then releases the owner and checks neutral input. Production UI was unchanged.

The corrected recovery-only run passed: injected worker failure visible, new room connected, second-finger release preserved movement, owner release stopped it. `/tmp/coop-candidate12-recovery/worker-recovery-touch.json` records the events and source hashes; those hashes exactly match all three candidate-12 network scenarios. Network scenarios were not rerun for this harness-only correction.

## Final independent IO pass after candidate 15

Scope: browser/worker message chronology, transport and codec backpressure, reconnect epochs, and visible failures. This pass excludes the author's own playback/projection model proofs and the separate, still-changing dense-contact cap/index work. Earlier candidate-12 measurements used a rendered-host reference; they are not evidence for the corrected authoritative-clock threshold.

**Blocker found: presentation failure prevents rendering after retry.** `CoopUI.animate` requests the next animation frame only after preparation and drawing. A thrown renderer/presentation error skips that request. The browser correctly exposes the failure, but a subsequent room uses the same UI, and `reset()` does not restart animation. Executing the actual constructor callback with a one-shot draw failure left zero scheduled callbacks (`/tmp/coop-render-retry-gap.json`). This is a method-level reproduction; the passed worker-crash retry does not cover it. Require a rendering-loop restart fix and a browser retry regression before treating presentation-error recovery as complete.

Other reviewed IO boundaries remain consistent: decoding is serialized and bounded; decoded callbacks recheck run/connection incarnation after awaiting; disconnect closes the previous decoder; composite guest delivery coalesces movement and cumulative receipts; host compression/native writing stays within its application window. Application ACK remains admission evidence, not a canvas-completion acknowledgment. Preparation runs before one late presentation sample; opening the map reuses the displayed frame rather than consuming effects again. No second concrete IO blocker was identified.

Corrected candidate-15 evidence is `/tmp/coop-candidate15-late-sample/summary.json`, with automatic static-import closure hashes. At 0/200 ms injected send delay, true host-worker lag was p95 **28/28**, maximum **29/29** ticks; motion violations and eviction recoveries were zero. Applied-input coverage was **93.7%/54.2%**. The 200 ms result only narrowly clears the agreed 50% floor. At 600 ms, coverage was zero, three motion violations/recoveries occurred, and p95 lag was 44 ticks: this qualifies only bounded overload behavior, not playable networking. Active reload preserved tick 28/run/round, advanced to tick 43, and applied new guest input at tick 40. Map open/close kept the sample count at 27.

Reviewed IO source pins (SHA-256):

```text
coop-browser.mjs        181982a422a035954849def7ab321c81226699b8130b11995a5ed92e347adde5
coop-worker.mjs         c17385c9393143f7d0bdfe4e2cec36408da6324aeeeb25f4a6d6574b2ba2930e
coop-presentation.mjs   d9b15c89d6e4c0990d6721f80c2406860ad3c64c322ecd8fa8004c80a26ae738
coop-snapshot-codec.mjs a172541a90c1c255e07ad9cb619428626233404edb634b170d40c1a32909c1e0
coop-transport.mjs      58724e40962e1089110f53b36ab01f6d4608cef63f8e1c85a7e23940c5dae94f
coop-ui.mjs             1994cb051df7dcfb827f2a39f6696f3dc9617574e143f8d30f5d5b8d69856038
```

### Render-retry blocker resolved on build 16

Independently inspected the implementation and `/tmp/coop-candidate16-render-recovery/worker-recovery-touch.json`. The animation callback now requeues in `finally`, marks drawing failed before rethrowing to the visible diagnostic handler, and suppresses further drawing until session reset. `reset()` clears that failure flag. The reviewed UI SHA-256 is `73b52f34e17312c5c4a960447da703572e1c80ae1654854dacc16b0a29e38894`; it matches the tested artifact.

The actual-Iroh recovery run observed exactly one injected renderer failure, with `browser-view` source and a renderer/UI stack visible in the diagnostic. No draws occurred during the subsequent failed interval. Without reloading the host page, a new room produced **14 actual rendered frames**, advancing from world tick 0 to 1 under a different run ID. Only the explicitly injected worker and renderer errors were recorded. This closes the identified RAF-retry blocker.

The same run also passed worker failure/new-room recovery, touch ownership, unchanged map sampling count (27 → 27 → 27), and active guest reload: suspended/rejoined at tick 28, preserved run/round/invitation, advanced to tick 43, and applied fresh movement at tick 39. Its source-import closure includes the snapshot codec. This was a **recovery-only** qualification; the full corrected network matrix remains pending for the final frozen build after the separate proof work.

### Candidate-16 full matrix: diagnosed lag failure

The later full run failed the unchanged 200 ms lag gate: p95 **34**, maximum **37** ticks (`/tmp/coop-candidate16-full/completion-200.json`). Motion violations and eviction recoveries were zero; applied-input coverage was 54.7%. Independent trace analysis identifies an **underrun/refill amplification**, not elapsed-time clipping or history eviction.

Times below are relative to the first advanced host-worker step:

| Time | Observed event |
| --- | --- |
| 17.347 s | Host prepares observation 335 / tick 994, window depth 13. |
| 17.497 s | Host prepares observation 336 / tick 1000, depth 14: a 150 ms producer gap while below the 16-flight limit. |
| 17.718 s | Guest presentation reaches its latest tick 990 and enters buffering. |
| 17.736 s | Tick 994 is available, but four newer ticks do not satisfy the six-tick refill rule. Cursor remains 990. |
| 17.891–17.901 s | Tick 1000 arrives; buffering releases at cursor 990. Host has reached 1027, giving 37 whole ticks of lag. |
| 17.960–17.967 s | Subsequent arrivals reach tick 1011 while presentation is 994.382: 16.618 ticks behind its received anchor. |

The cursor held for approximately 183 ms, then could remove excess backlog at only six ticks per second. During the following second, median total lag was 34 ticks despite median network/authority-anchor lag returning to 21 ticks. This explains why the final active window failed after earlier windows passed.

Alternative explanations checked: the entire guest trace's largest actual sample-time gap was **32.7 ms**, far below the one-second elapsed cap. Around the onset, preparation peaked at 4 ms and post-sample processing at 14.1 ms. Host native writes took 0–1 ms and preparation-to-native-start approximately 2 ms. The producer gap coincided with host-worker step intervals of 37/48/27/31 ms. Existing telemetry cannot distinguish worker computation, scheduling contention or GC as the initial producer slowdown. It does show that increasing the application window would not fix this particular gap.

Candidate 15 and 16 used random world seeds; they are not paired workload measurements. The previous success therefore does not prove a regression in the new cap/index implementation. Preserve the failing trace, record/control the worker seed for subsequent comparisons, and examine refill/recovery pacing under a reproducible producer gap before choosing another candidate. No threshold or production code was changed during this diagnosis.

### Candidate17 bounded starvation recovery (offline/model evidence)

The retained clock trace is `examples/survivors/fixtures/coop-playback-producer-gap.json`: relative receipt/sample times, observation/tick IDs and the actual host-worker clock. No actor world data or playback implementation is embedded. The old emitted Bend policy reproduces overall lag p95 **34** and five-second windows **27/29/37**. The revised emitted Bend policy gives **27**, windows **27/27/30**, maximum32, without history eviction. Warmup is explicitly inferred from the first positive-tick receipt because candidate16 did not retain the harness loop-start; new browser records retain that exact timestamp and all host-worker initialization seeds. `COOP_TEST_SEED` optionally overrides only the host initialization seed and is explicitly recorded.

The controller now distinguishes initial priming from starvation. Initial/history-reset priming still waits6 ticks (3 on host); an established starved stream resumes after1. Recovery enters84Hz only above delay+4 ticks, stays latched until delay+1, and otherwise uses the existing60/66Hz controller. Waiting updates the monotonic timestamp; readiness spends at most33,334µs from the last sample interval, preserving fractional credit and discarding longer suspension debt. Reaching authority resets to Holding. These changes affect the shared remote presentation clock only.

Independent formula readbacks by root and terminal-journal reviewer preceded proof. The strict kernel passed72 laws;20 semantic mutants were rejected. Actual emitted-model diagnostics passed39,442 checks, including the retained failure, threshold equality, long/no-callback background waits,49-day/safe-integer timestamps, producer holes, bounded history, and whole-cohort interpolation. Slow45/30Hz production still produces stationary fractions25%/50%; emergency is never stuck on thin supply. This policy does not make a slow authority smooth.

This is consistent with [Mirror's separate catch-up/slowdown bands](https://github.com/MirrorNetworking/Mirror/blob/master/Assets/Mirror/Core/SnapshotInterpolation/SnapshotInterpolation.cs) and [snapshot-buffer latency/jitter tradeoffs](https://gafferongames.com/post/snapshot_interpolation/), rather than a claim that those implementations prescribe these constants. The actual browser motion/worker-lag gates remain unchanged. A fresh full real-Iroh matrix on the final artifact is still required; offline trace success is not deployment qualification.
