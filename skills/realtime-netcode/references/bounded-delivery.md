# Delivery, playback and qualification

Read this branch for send-queue overflow, steadily aging snapshots, motion
pacing failures or a reliability review. These are contracts and diagnostic
choices; the numeric limits of the Survivors example are not universal defaults.

## Identify what completed

Keep these receipts separate:

| Event | What it establishes |
| --- | --- |
| Local stream finish | The local sender handed over bytes; obsolete state may still accumulate below this boundary. |
| QUIC byte acknowledgement | Delivery of stream bytes, not application parsing or gameplay application. |
| Snapshot application receipt | The named connection/observation passed decoding and admission. State whether synchronous UI adoption or actual canvas drawing is included. |
| Applied-input receipt | The host consumed that command at its assigned simulation tick. |

Instrument preparation-to-application-receipt delay, native write duration and
actual worker input resolution separately. An admission sequence alone cannot
establish that movement happened. Never retarget an already accepted command to
make a late-input test pass.

## Budget the shared lane

Model the service time of the real shared transport, including control traffic.
Two individually bounded queues can jointly starve a 60 Hz producer. Prefer a
single prepared packet carrying an input batch and the latest cumulative receipt
when that fits the protocol. One writer owns the entire packet. Its completion
uses the stored child IDs, preserves newer pending work and checks the connection
incarnation; failure fences the whole writer.

Use a finite application-unacknowledged snapshot window and one replaceable
latest pending snapshot. Size the window from measured acknowledgement turnover
and required cadence, with jitter headroom. A one-packet stop-and-wait policy
bounds backlog but can make remote motion unusably sparse. Compression may
reduce delivery cost; measure bytes and latency rather than inferring throughput
from fast local writes.

Align the sender's outstanding window with the receiver's admission capacity.
Serialize compressed snapshot decoding with explicit job and byte limits. Plain
handshake/control traffic can bypass that queue. Complete integrity checking
before admission and acknowledgement. On reconnect, replace the queue and fence
both successful and failed old completions. A cap on collected decompressed
output does not necessarily bound the browser inflater's internal allocations.

## Control the presentation clock

A scheduled rAF timestamp can be old when its callback runs. Compare scheduled
time, callback entry, sampling, local processing and draw entry before weakening
a motion bound. Read the actual monotonic clock at the intended sampling boundary.
Consume elapsed time once across timer, input and render callers.

A continuously running interpolation clock needs a convergence policy as well
as continuity. A late initial anchor or an underrun can leave a permanent excess
buffer if both producer and consumer then run at the same rate. A bounded rate
adjustment outside a deadband can remove that excess while keeping actors,
confirmed projectiles and contact effects on one timeline. Preserve fractional
credit, clamp to available authority, and discard hold time while buffering.
Count history-eviction recovery seeks separately; rate correction does not prove
that seeks never happen. Do not accelerate local input or local shot animation
because the remote presentation clock is catching up.

Distinguish initial priming from starvation recovery. Requiring the full initial
buffer after every underrun can amplify a producer gap into prolonged lag.
If recovery uses faster playback, pin its entry/exit hysteresis, maximum rate
and reset paths as explicit policy. Preserve a failed arrival/sample trace and
replay the emitted core against the same worker clock. A last-sample interval
can itself span background suspension; cap resume credit separately. Treat a
faster cosmetic clock as a visible tradeoff and recheck actual draw-time motion,
not only its counterfactual clock trace.

## Bind visual evidence to its lifetime

A preview's existence ledger is not proof that its canonical shot terminated.
Hide a canonical shot while its matching preview is drawable, or under a matching
confirmed terminal receipt. An unconfirmed expired preview must yield to a live
canonical shot. Distinguish terminal finite projectiles, continuing pierce and
area effects.

Use the same displayed target lifetime and pose for the shot endpoint and its
impact. If that target is absent, use one declared canonical fallback; do not
use an old tombstone for one and current authority for the other. Attach a
cosmetic journal consumer at the first accepted journal of the epoch, not at a
later first render. When playback crosses an unseen hit during recovery, start
its bounded effect lifetime once instead of silently skipping or replaying it.

## Bound cosmetic work before serialization

Apply cosmetic retention limits before constructing JSON or sending snapshots.
A bounded receiver journal cannot prevent a producer from allocating an enormous
raw contact frame. Count omitted cosmetic receipts separately; never cap the
authoritative damage, pickups or rewards to make the transport smaller.

A fixed 512-item budget can still miss a frame budget when each item scans all
previous long identifiers. Profile actual lifetime IDs and duplicate batches.
An exact string trie can carry membership through the batch without probabilistic
hash collisions. Prove equality to the original FIFO deduplication reference,
including arbitrary existing rows, rather than only proving the index in isolation.

## Accept evidence at the right boundary

Measure lag during active gameplay and in several windows. Equal final ticks
after death can hide seconds of earlier backlog. Count actual applied worker
steps, neutral streaks, late rejections, buffer holds, recovery seeks and motion
violations. Separate interactive-network scenarios from bounded-overload tests;
late commands draining intact do not establish playability.

Pin the exact served artifacts and source hashes. Run multiple independent
review/fix/validation cycles, retain counterexamples, and recheck the affected
paths. A formal law that delegates to an opaque helper cannot reject a constant
empty helper. Pin the helper or narrow the claim. When a large import graph
exceeds the fixed proof budget, extract a small shared policy used by production;
do not raise the limit or prove a disconnected copy. Report typed adaptation,
ECS execution, serialization validity and device behavior outside that proof's
actual scope.

The worked counterexamples and primary engine references are recorded in
[the acceptance record](../../../research/coop-reliability-plan.md),
[the delivery audit](../../../research/coop-snapshot-delivery-audit.md), and
[the compression audit](../../../research/coop-snapshot-compression-audit.md).
