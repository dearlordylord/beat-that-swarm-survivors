# Guest movement jitter: reproduced and removed

The previous first-response and eventual-convergence checks passed while sustained
movement visibly moved backwards. They did not establish smoothness.

## Reproduction and cause

The baseline is the exact published Site19 archive for game revision
`184283bf7f6054bd0e27d20bdade3838e3008e3b`, extracted outside tracked source.
Both versions run the real compiled Bend worker, browser UI, and renderer in two
isolated contexts. Only the byte transport is replaced by a controlled ordered
link. This is not an Iroh transport benchmark.

The guest holds Right for 3.5 seconds, reverses Left for 800 ms, then releases.
Every actual `Renderer.draw` records player and camera positions. Sustained-motion
analysis excludes 300 ms after keydown and 100 ms before release. Full prediction
states are captured immediately before and after each reconciliation.

The old controller assigned independent durations to held-input heartbeats on the
guest and host. An ACK discarded predicted durations based on the host's different
clock and hard-replaced the displayed position. In the corrected ordered 100 ms
RTT/±40 ms jitter baseline, a snapshot at 1429.8 ms changed predicted x 7402 to 7394.5
inside reconciliation: a 7.5 unit backward jump while Right stayed held. The
snapshot's authoritative x was 7354.5 with Receipt(seq 21, steps 3). One ordinary
movement tick is 2.5 units. Camera displacement exactly matched the player jump,
so the entire scene visibly shifted.

The replacement sends one explicitly queued input per predicted fixed tick. The
host consumes each once and ACKs it only after its corresponding world step
advances. The guest replays the exact unconsumed ticks. No visual smoothing hides
position errors. A second independent fault was found by the frame-speed gate:
RAF timestamps could rewind a scheduler clock already advanced by a network
callback using `performance.now()`. The controller now clamps that clock
monotonically.

## Comparable results

Both columns use the same final ordered, batched delivery fixture and ±40 ms
injected delay variation. Each count includes both sustained directions.

| Nominal RTT ms | Old backward frames | Old largest backwards move | New backward frames | New largest reconciliation correction |
| --- | --- | --- | --- | --- |
|100|10|10|0|0|
|250|11|5|0|0|
|500|10|7.5|0|0|

On the final candidate, all three runs also had zero camera mismatch, zero
post-release position range, zero final authority error, zero advances beyond the
elapsed-tick budget, and no repeated-position frames during analysed motion.
Start/reversal response ranged 3.7–12.6 ms; release settled in 32.7–38.3 ms. Host
simulation remained 60 Hz. Pending predicted ticks peaked 25/29/48, below the 60 tick
horizon. Right traversals covered 465/465/467.5 units over approximately 3.1 seconds,
consistent with 150 world units/s.

Nominal RTT describes injected scheduling delay, not an assertion about actual
browser/driver roundtrip time. Measured guest-to-host command one-way p50/p95
was 99/142 ms, 171/208 ms, 305/358 ms respectively, including browser and test-driver
scheduling. The fixed-delay/no-jitter candidate cohort separately passed all
three RTTs with zero corrections/backwards motion/release drift.

Artifacts:

- Old version, final fixture: `/tmp/bendvy-coop-jitter-site19-ordered`.
- Final candidate, same fixture: `/tmp/bendvy-coop-jitter-final-confirmed`.
- Final candidate, fixed delays: `/tmp/bendvy-coop-jitter-final-steady`.
- First tick-ledger candidate's scheduler fault: `/tmp/bendvy-coop-jitter-fixed`.

## Fixture correction and regression gates

An initial jitter fixture used independent Node timers spaced 0.1 ms apart. That
spacing is below timer precision and did not preserve reliable-stream order.
A negative control recorded actual delivery indices 0,1,2,4,3,5,6,8,7,10,9…;
`/tmp/bendvy-coop-jitter-timer-control` proves the fixture error. Its variable-delay
results are excluded from the table and acceptance evidence.

The final fixture has a separate ordered pump per direction and asserts that
observed delivery indices form an exact send-order prefix. It batches already-due
messages into one browser evaluation, avoiding an artificial 60 CDP-roundtrips/s
throughput limit that previously pushed pending prediction to its horizon. Both
latency and sustained-jitter harnesses use this ordering discipline.

`examples/survivors/coop-jitter-browser.mjs` gates active gameplay, substantial
traversal in both directions, immediate response, local release timing, no
backward frames, no reconciliation position correction, an elapsed fixed-tick
movement bound, stable release, and final authority agreement. Zero-displacement
frames are recorded but not forbidden: rendering above 60 Hz legitimately repeats
fixed-tick positions. The separate input-latency test also requires the complete
send→host-consumed-receipt→received-ACK trace, first movement before that ACK,
and immobility after an actual Bend XP-triggered global pause.

```sh
PLAYWRIGHT_MODULE=/path/to/playwright/index.mjs \
  node examples/survivors/coop-jitter-browser.mjs
COOP_JITTER_MS=40 PLAYWRIGHT_MODULE=/path/to/playwright/index.mjs \
  node examples/survivors/coop-jitter-browser.mjs
PLAYWRIGHT_MODULE=/path/to/playwright/index.mjs \
  node examples/survivors/coop-latency-browser.mjs
```

`COOP_LATENCY_WEB_DIR` selects prepared web assets and `COOP_LATENCY_QA_DIR`
selects artifacts. `COOP_LATENCY_ENFORCE=0` collects a failing baseline without
smoothness acceptance; its summary explicitly records collection mode and no pass.

The final ordered input-latency harness also passed all three nominal RTTs after
the clock fix: start/reversal 22.0–25.5 ms, release 41.3–44.7 ms, zero final error,
zero camera mismatch, and no movement during the observed XP-triggered pause.
Every case recorded the actual consumed receipt and rendered its first motion
before that ACK arrived. Artifacts: `/tmp/bendvy-coop-latency-final-ordered`.
