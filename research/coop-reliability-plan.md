# Co-op reliability acceptance

This work starts at `5aff253`. The user requested both reported bugs fixed,
permanent regression protection, independent subagent reviews and several
review/fix/validation cycles against industry practice. Product source remains
Bend; browser code performs device, rendering and transport IO.

## Confirmed failures

- With 300 ms added observation delay, a host reversal replaced a roughly
  47-tick open-loop combat forecast: host world x jumped 242.5 units in 21.5 ms;
  the same living enemy moved 45.22 units on the correction.
- Sustained per-tick guest sends filled the 16-message transport queue and closed
  a valid party. The reported production failure occurred at world tick 428.
- Candidate 1 (six ticks of guessed remote movement, whole-frame crossfade)
  failed: host jump fell to 30, but an enemy still jumped 42.19; old-frame
  blending was almost continuous. A 32-second run avoided queue overflow but
  displayed an authoritative state 450 ticks behind the host. It is not a
  releasable fix. Its unused source is removed rather than shipped.

## Architecture for the next cycle

- Keep host-authoritative ECS execution and exact target-tick guest input.
- Keep cheap local movement prediction. Reserve bounded input capacity before
  assigning/predicting a command; batch FIFO commands with one native write in
  flight. Backpressure is a recoverable scheduling condition.
- Show remote players, enemies and confirmed projectiles from one bounded
  authoritative snapshot interpolation timeline. There is no full-world future
  replay in snapshot intake or frame construction.
- Anticipate only local visual shots. Capture the displayed muzzle at birth,
  match stable shot lifetimes, and never change authoritative HP, XP or rewards.
- Confirm contact effects only from host resolver receipts. Match source and
  target lifetimes; target-relative contact mapping is shared by visual shot
  endpoint and impact. Late effects have an explicit bounded fallback.
- Hit receipts are recent cosmetic evidence, not the durable outcome ledger.
  Canonical outcomes remain in host state/snapshots. Cosmetic expiry/overflow is
  explicit and counted; a reconnect must not replay old effects.

The industry comparison and primary references are in
[the architecture audit](coop-reliability-industry-audit.md).

## Regression obligations

| Boundary | Required evidence |
| --- | --- |
| Input flow | Journal <=64 including in-flight; <=62 movement plus two control slots; batch <=32; FIFO and unchanged target ticks; one flight; stale callbacks cannot clear a new connection; no predicted unsent tick. Slow 200/600 ms writes eventually drain accepted commands unchanged without fatal overflow. |
| Snapshot delivery | At most sixteen application-unacknowledged observations, one native writer, one latest pending payload; matching cumulative processed ACKs; receipt coalescing and epoch fences. With the 1 MiB transport limit, snapshots retain at most 16 MiB in flight plus one pending payload. |
| Snapshot display | <=8 retained frames and payloads; monotonic local clock and remote cursor; one bracket/alpha for all remote actors; no interpolation across generations/death; no premature birth; bounded recovery after gaps; no replay proportional to snapshot age. |
| Local shots | Muzzle equals displayed owner at birth; released shots do not follow later owner movement; attached effects do; same SpawnId does not create a second shot; anticipation cannot award damage or progression. |
| Contacts | Same prepared authoritative resolver supplies selection and receipt; finite/AoE, newborn bypass, death/loot position, edge and pool reuse cases; one lifetime-bound point for endpoint/effect; duplicate, early and late receipts handled explicitly. |
| Browser IO | Actual Iroh join/rejoin, start/stop/reverse, touch ownership, delayed/jittered delivery, slow outbound writes, long play, new party after error, worker failure and visible diagnostics. |
| Resources | Small-stack traversal checks; dense actor/shot/event fixtures; bounded receive/send/presentation histories; intake age and processing cost measured separately from injected network delay. |

## Review cycles

1. Reproduce the old behavior; draft and blindly read back the laws; run first
   candidate. Record counterexamples instead of weakening acceptance.
2. Replace the failed architecture, run adversarial model and actual-IO
   regressions; independently review spec, standards and operational pitfalls.
3. Correct every material review finding, rerun affected regressions and an
   independent industry review; prepare a fresh immutable release and verify
   the deployed revision.

Kernel proofs establish their stated pure contracts. Mutants probe whether those
contracts reject concrete wrong implementations. Executed adapters and browser
checks establish different, bounded evidence; none substitutes for the others.

## Cycle 2 findings (integration, not release acceptance)

- Independent architecture review found that an expired unconfirmed local shot
  could keep hiding the canonical projectile through its spawn-ID ledger. The
  visibility contract now distinguishes a drawable preview from a confirmed
  terminal receipt; speculative expiry returns presentation to authority.
- Standards review falsified the overflow counter: removing one of 513 rows
  reported zero. Exact removed-row accounting replaces the reversed comparison.
- Adapter review found that same-lifetime HP/age/radius metadata came from the
  oldest retained map. Rendering now selects the sampled base observation.
- A two-shot nonlinear dying-target fixture falsified the first terminal-path
  reconstruction. Every contact now samples the one selected target trajectory
  at its own impact time, preserving endpoint/target agreement.
- A recovery jump from remote tick 119 to 130 skipped a previously unseen
  contact at 124. A common effect ledger starts its bounded display lifetime
  when the event first becomes due, instead of silently losing it.
- Composition of two 500-hit batches exposed stack depth in the journal's seen
  history, beyond the original one-batch dense check.
- Actual Iroh runs with delayed observations and 200/600 ms send completions
  avoided fatal queues and rejoined, but accumulated roughly 490 ticks of
  authority lag. This is a failed candidate despite those passing checks.
  Native QUIC finish is not application consumption; snapshot replacement must
  wait for a receipt after guest parsing, admission and presentation. The new
  Bend snapshot-flow machine owns one flight and one latest pending snapshot.
- A transport-delivery-confirmed experiment caught up by its final sample, but
  the run had already ended. That final equality is insufficient evidence of
  bounded in-run lag; the retained browser check must measure active gameplay.

Parallel landing-menu commits `afc4546` and `3ef7bdc` belong to other work and are
preserved; they are not part of the network fix or its claimed review coverage.

## Cycle 3 findings (not yet accepted)

The stronger active-gameplay check rejected stop-and-wait application receipts:
with 300 ms observation delay and no extra outbound delay, active-game p95 lag
was 50 ticks (bound 30), despite equal final ticks after death. A bounded window
of eight application-unacknowledged observations replaces stop-and-wait, while
keeping one native writer and one latest pending payload. Cumulative receipts
free completed observations; native completion releases only the writer.
Guest receipt sends also coalesce, so a slow return path cannot queue one ACK
per snapshot ahead of movement.

Independent integration review also found a first-render race: attaching the
FX consumer to the latest journal on its first render could mark newly arrived
hits as already seen. Attachment now occurs on the first accepted journal of an
epoch, before later arrivals, with a red/green actual-adapter regression.

## Cycle 4–7 observations

- Eight outstanding snapshots alone did not meet the lag oracle: the full native
  Scene JSON still cost roughly 95 KB per packet. Native write completion was
  fast (p95 about 1 ms), so it did not measure receiver freshness. A compressed
  snapshot experiment reduced active display lag from p95 55 to 25–26 ticks
  with the same 300 ms injected observation delay. The generic browser codec
  leaves game fields untouched and validates complete gzip before admission.
- The motion oracle then found two pacing violations: the presentation cursor
  advanced 33.3 ms while draw entries were only 15.6/10.7 ms apart. The scheduled
  rAF timestamp was stale after a delayed callback. Sampling performance.now()
  at callback entry passed the next run: 1,004 remote-host pairs, zero violations,
  and zero history-eviction recovery entries. This is bounded Chromium evidence,
  not physical-device/Safari qualification.
- The 200 ms outbound-write case correctly failed because no nonzero guest
  command was actually applied, despite a healthy connection. A 16-command
  batch cannot sustain 60 Hz when input and cumulative receipts share a slow
  serialized lane. Batch and journal budgets are being dimensioned against the
  combined lane rather than treating each queue independently.
- The strict kernel gate rejected the first LocalProjectiles proof layout:
  merely importing Game exceeded the unchanged 10 CPU-second budget. Splitting
  proof files did not solve it. Actual shared Game-free policy must be proved;
  Game planning/typed adaptation remains executed integration evidence. An
  unbounded standalone proof run is not recorded as a passing project gate.

## Cycles 8–15: evidence corrected before acceptance

Independent review rejected the earlier browser evidence because its lag oracle
compared against the host's interpolated display, rather than the worker's actual
simulation clock. It also found that the served-code identity check omitted a
static codec import. The retained harness now timestamps actual advanced worker
steps and discovers the full static ESM closure with a JavaScript parser.
Neither acceptance threshold was relaxed.

The corrected candidate-15 actual-Iroh matrix passed the declared interactive
checks with 300 ms injected observation delay and 0/200 ms native-send delay.
It also exercised active phase-zero reconnect with fresh input application,
mobile touch ownership, map toggling without a second presentation sample, and
visible worker failure followed by a new party. The 600 ms case remains a
bounded-overload check with no applied guest movement, not playable co-op.
See the independent final review for measurements and scope.

## Dense combat counterexample after candidate 15

A separate review constructed real prepared geometry with sixteen area fields
and 500 monsters. Its 8,000 contacts produced a 2.38 MB raw frame and a journal
stack overflow. Applying a 512-entry journal limit after serialization was too
late. The next candidate caps cosmetic emission before JSON, records omitted
receipts separately, and retains the complete authoritative game result.
An exact string index replaces repeated long-ID scans while preserving the
original FIFO deduplication reference. This candidate requires its own strict
proof, dense geometry, tiny-stack and fresh-artifact browser checks before release.

## Final IO review counterexample: rendering failure recovery

The independent follow-up found that an exception in prepare/sample/draw could
stop the requestAnimationFrame chain permanently. Worker-failure recovery had
passed, but it did not cover this browser-rendering path. Starting another room
reset the UI without scheduling a new animation callback. The IO adapter now
schedules its successor in `finally`, rethrows the original error for visible
diagnostics, and suspends further drawing until session reset. The retained
browser scenario must verify actual new-run draws after a one-shot renderer
failure; receiving snapshots alone cannot establish recovery. This browser API
behavior is outside the pure Bend-law proof boundary.

## Candidate 16: full-matrix rejection after successful recovery

The strengthened recovery-only suite passed, including a visible renderer error
and new-room draws without reload. The later full matrix nevertheless rejected
the 200 ms case: overall true-worker lag p95 was 34 ticks, with 37 in the last
five-second window. The unchanged limit is 30. Zero motion violations and
54.7% applied-step coverage do not override this failure. The 0 ms case measured
28 ticks and passed its interactive checks. The suite stopped before 600 ms.

Independent replay exactly reproduced every recorded presentation cursor. A
150 ms producer gap caused underrun; six-tick refill held the cursor for 183 ms,
then resumed with ten ticks buffered. A following burst raised backlog to 16.6
ticks, which the 66 Hz controller drained too slowly. The sender window was not
full at that onset; no clock clamp, round pause or history eviction explains it.
The world seed was random and not captured, so this is not an equivalent-world
A/B attribution to the new journal implementation. Subsequent timing candidates
must retain this finite counterexample and preserve the acceptance threshold.

## Candidate 17 policy to validate

The clock now distinguishes Priming, Holding, Playing and Boosting. Startup and
history recovery retain the configured delay (guest six ticks, host three);
starvation resumes when at least one newer tick exists. Resumption spends only
its last monotonic sample interval, capped at 33,334 microseconds; background
silence cannot accumulate an unbounded resume credit.

Ordinary playback retains 60/66 Hz. Emergency catch-up enters above `delay + 4`
received ticks of backlog and stays at 84 Hz until backlog reaches `delay + 1`.
Starvation, recovery and stream reset clear that latch. This is an explicit
short-lived visual speed tradeoff, not a change to authoritative physics or
local input/shot clocks, and 84 is an engineering ceiling rather than an
industry-prescribed constant.

The exact capped counterfactual replay meets the unchanged clock oracle, but
that is not browser acceptance. Fresh emitted-model checks, fixed-budget proofs,
mutants, slow-producer/background scenarios and the full actual-Iroh matrix with
the unchanged draw-time motion and worker-clock lag bounds are still required.

### Frozen candidate-17 browser run

Before starting the next full actual-Iroh matrix, fix worker seed **1729** for
all scenarios via the harness's explicit initialization override. Keep default
characters, 32 seconds of scripted input, 300 ms injected observation delay and
0/200/600 ms delay before native guest sends. Retain the same worker-clock lag
and draw-time motion thresholds; 600 ms remains overload-only. Record exact
loop-start time, initial seeds and complete served import hashes. This fixed
seed improves repeatability; the separately retained candidate-16 random-world
clock failure remains a required regression and is not discarded.

The first general gate found two stale projection fixtures that assumed the
old no-credit ready frame. They now initialize an explicit Playing cursor for
their projection-only assertions. The original HP-zero interpolation and
future-hit-hidden/then-due assertions remain intact. The independent fresh
adapter rerun passed all 141 checks; no production policy changed for this fix.
