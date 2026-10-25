# Co-op candidate 2: independent architecture review

Reviewed 2026-10-25 against baseline `5aff25371637f14dca5bfa879968b630344edd22` and the actively edited working tree. HEAD at report capture was `3ef7bdc3ca12316f34258e1045529da45bebcd0a`; this is not a clean release review. Scope: browser/worker adapters, interpolation, client clocks, bounded input flow, local projectile anticipation, contact playback, hit journal, and native transport generation fencing. This review read source; it did not run a new real-Iroh qualification. The acceptance source is [the reliability plan](coop-reliability-plan.md). The old final recommendation in [the industry audit](coop-reliability-industry-audit.md) describes rejected candidate 1 and is not implementation authority.

## Blocking findings

### P1: a mistaken provisional contact can hide the still-live authoritative projectile

In `coop-local-projectiles.bend`, `predict_target`/`pending_step` hold a single-pierce preview at its provisional recipient, then expire it after eight animation ticks and four fade ticks. `KnownShot` survives for 64 presentation ticks; `should_show_authoritative` hides the same authoritative identity even after the preview disappeared. Snapshot data is consulted for pool planning, but does not adopt a continuing authoritative trajectory or distinguish an unconfirmed preview retirement from a confirmed terminal contact. The check at `coop-local-projectiles-check.mjs:86` currently explicitly expects this unconditional suppression.

Reproduction: show a nearby enemy A in the delayed combat sample; the host kills A before the actual local shot reaches it. The local preview stops on A, expires, and remains in `known`. The host projectile with the same identity continues toward B for more than 200 ms. The rendered scene now has neither the preview nor the still-live authoritative projectile. A later terminal receipt can arrive after the visual was removed and cannot recover the missing flight. Conversely, a canonical shot whose birth was skipped during prediction resynchronization has no local muzzle binding and falls back to its delayed canonical origin.

Required correction: make authoritative spawn/lifetime adoption explicit. Distinguish speculative retirement from authoritative terminal retirement. A continuing matched authoritative shot must retain or regain one visual representative, with bounded positional reconciliation, and a newly observed local birth needs an explicit origin policy. Test false provisional recipient, delayed terminal receipt, prediction-cursor jump over a weapon birth, and pool reuse. Assert one visible representative for a confirmed living lifetime, rather than only absence of duplicate identities. Root forwarded this finding to the module owner during review.

### P2: first-due late contact effects are computed but discarded by the browser adapter

`coop-browser.mjs` calls `LocalProjectiles.play_effects`, whose effects start at the current presentation tick, then ignores `visual.contacts` returned by `LocalProjectiles.render`. The rendered `combatImpacts` instead come exclusively from `ContactPlayback.fx_recent`, which expires by event tick. This avoids duplicate effects during ordinary playback but drops the intended late fallback.

Concrete trace: presentation is at tick 119; snapshot-history recovery moves it to 130; an unseen retained receipt names tick 124. `HitJournal.play_sample` emits that receipt for the first time at 130. `LocalProjectiles.play_effects` creates `started=130`, but `ContactPlayback.fx_recent(event,130)` is false because the receipt is six ticks old. Consequently no effect reaches the renderer. All values are inside the journal's 64-tick history window; this is not an expired or duplicate receipt.

Required correction: one shared effect ledger for both roles, starting the bounded four-tick display lifetime when a receipt first becomes due. Reuse the existing lifetime-aware target-relative point function. Repeated snapshots must not restart the effect; attach/rejoin must skip history. Test samples 119 → 130 → 131 with event tick 124, assert one effect and bounded expiry, then repeat the journal and reuse the target slot. Root approved a separate small Bend effect ledger after this independent finding; its subsequent implementation is a follow-up, not evidence from this review.

### P1 qualification gap: the browser diagnostic does not reject the original failure classes

`tools/survivors-bot/coop-reliability-browser-check.mjs` captures render positions and timing but only requires both role ticks to exceed 100, no errors, and successful reload. It does not assert bounded authority age, same-lifetime position continuity, guest applied movement, or a recovery bound. A connected session with an immobile guest, repeated late-input refusals, an enemy correction jump, or a 450-tick receive backlog can satisfy those assertions.

Its before/after hash list also omits the new playback, clock, input-flow, projectile, contact and journal emitted modules, and the presentation adapter. Therefore `sourceStable` is not sufficient evidence that candidate 2 stayed unchanged during the run.

Required qualification: hash the actual loaded candidate closure or immutable packaged manifest; assert render/arrival/host age separately; measure same-generation enemy and host displacement against elapsed time; record input reservations, arrival, accepted/applied/rejected target ticks and resynchronizations; assert actual guest direction changes. Exercise sustained 200/600 ms writes, a real delay before native send (the existing hook delays completion after native send), delayed/jittered observations, and render suspension. Report performance distributions and rejection/recovery rates; connectedness alone is insufficient.

## Corrected during review

The initial browser read updated `predictionLead` only on reset or disabled-to-enabled transition, leaving a low startup lead in use after runtime RTT growth and cursor catch-up. Root subsequently connected `Prediction.choose_lead` before reconciliation and reported fresh runtime/mutation checks. This finding is not listed as still open; integrated slow-write gameplay remains part of the qualification obligation above.

## Boundaries that are structurally sound, with remaining limits

- Remote projection and interpolation no longer call full-world forecast replay. Local movement and local projectile anticipation are explicitly presentation concerns; neither owns shared HP or rewards.
- Input-flow capacity includes the in-flight batch, reserves control slots, preserves assigned target ticks, and fences completion by epoch and batch identity. At sustained 600 ms writes, a 16-command batch offers at most about 26.7 commands/second before timer overhead, below a 60 Hz input producer. Bounded backpressure must therefore reduce generation or reject expired target ticks. Do not interpret successful queue drainage as proof that all drained inputs were timely or applied.
- The native Iroh receive loop in `tools/iroh-transport/src/browser.rs` checks its connection generation before emitting messages and disconnects. An apparent missing generation check in the JavaScript message callback is therefore not by itself a demonstrated production reconnect bug. Delayed test callbacks should nevertheless be checked against their captured epoch; tests must not accidentally bypass the real fencing boundary.
- `Playback` bounds retained snapshots to eight and clamps to authority. On underrun it waits for the configured buffer, and on eviction it moves the cursor to the oldest retained tick. Those are explicit recovery transitions, not a proof of smooth recovery or stable delay under jitter/drift. The late-effect finding above arises at precisely this recovery boundary.
- The new local projectile module still performs a bounded startup replay of up to 54 local ticks and builds geometry/pool plans. This is smaller than world replay but should be measured with dense actual game inventories. Bounded lists do not imply a bounded frame duration: several paths scan visuals against canonical snapshots or receipts. No new CPU-cost measurement was performed in this review.
- Worker-to-browser `postMessage` publication has no explicit receive acknowledgment/coalescing boundary. Snapshot-buffer bounds apply after dispatch, not to queued browser messages. Measure native receipt, adapter intake and render separately before claiming the former 450-tick backlog is eliminated.

## Source capture

Relevant source SHA-256 values at 09:08:48 UTC, before the follow-up effect-ledger implementation:

| File | SHA-256 |
| --- | --- |
| `examples/survivors/coop-browser.mjs` | `5029d226201ec5039a7afb7ff95c0b7796731cfee59bf6b296ce560ca9afe222` |
| `examples/survivors/coop-local-projectiles.bend` | `ad64836197e5be83b06ec0477361926bae5a4afe07e19b6921320ce9b0208e2d` |
| `examples/survivors/coop-contact-playback.bend` | `a2b19dd4967e89b747dc427e58611c576dfce25f85ff2b0ef767cfbf9d2fb219` |
| `examples/survivors/coop-hit-journal.bend` | `bf00586017b6b43e62489a3b162ac1555a5cf4e3d12070a9be33ed1585c62b19` |
| `tools/survivors-bot/coop-reliability-browser-check.mjs` | `c8c88c8e47725b343df707bad2c2babe8a1a69eea6e6847edb64fcaf885acc02` |

This is an architecture/source review with falsifiable scenarios. It does not establish real-network reliability, smoothness, CPU budget or production readiness.

## Follow-up implementation and newly executed counterexample

After the independent review, root authorized this reviewer to implement only a small shared `coop-hit-effects.bend` ledger, its laws/proof, emitted-code checks and mutation manifest. The presentation/browser integration remains owned by root. This follow-up is implementation work and is not an independent review of its own integration.

The new check exposed an additional resource failure in the existing journal consumer: attach an empty epoch-1 journal at tick 99; consume 500 unique events at tick 100; then consume a journal containing 500 different events at tick 101. Each incoming journal is within the 512 cap. With freshly emitted Bend and `node --stack_size=192`, `J.play_sample` fails with `RangeError: Maximum call stack size exceeded` in `List.append`; the ordinary Node stack passes. The prior journal check exercised one dense batch and its repeated copy, not replacement by another dense batch. The journal owner received this reproducer and owns its fix. The complete fixture is in `coop-hit-effects-check.mjs`; no browser or world simulation is needed to reproduce it.

### Cycle 3: attachment must happen at accepted intake

A subsequent independent review found a race in the follow-up ledger: if the first accepted frame has an empty journal and a second frame contains a new hit before the first animation frame, attaching only during `advance` consumes the second frame's new hit as historical. The new `receive(state,journal)` attaches only the first accepted journal of an epoch and leaves all same-epoch arrivals unchanged. The presentation owner calls it at accepted snapshot intake; `advance` retains its safe fallback for callers that have not attached. New regression cases cover the initial-frame race, active-effect preservation, and the same race after rejoin. After the journal owner's stack fix, all 28 emitted-code checks pass with a 192 KiB Node stack, including the original dense 500+500 counterexample. These checks still do not substitute for adapter/browser execution.
