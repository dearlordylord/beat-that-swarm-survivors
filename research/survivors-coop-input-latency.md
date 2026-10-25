# Co-op input response

The original guest waited for a round trip: a 50 ms input timer, host simulation,
20 Hz observations, then a 50 ms display buffer. Rendering/simulation FPS did not
measure that delay. The old browser smoke checked eventual host movement, so it
could pass with an unresponsive guest.

## Contract and implementation

A changed direction is dispatched immediately; the timer remains a heartbeat.
Bend predicts only the local player's display position through the same movement
helper used by authoritative movement. JavaScript supplies clock/input/transport
and applies the resulting point to presentation, after world interpolation.
Damage, pickups, XP, gold, weapons and reward choices remain host-authoritative.

Prediction records up to 64 input segments. Receipts describe the sequence and
number of actually consumed simulation steps, independently of received input.
Reconciliation starts from the authoritative position, consumes acknowledged
history once and replays the remainder chronologically. Older observations cannot
rewind the display. Expired input removes the acknowledged segment, preventing
its direction from restarting on later snapshots.

Prediction is allowed only for a connected living player in phase zero. A known
pause/death clears history; resume starts fresh. The horizon is 60 local steps,
including replayed pending steps. This leaves room for the tested 500 ms RTT and
snapshot interval while bounding speculative movement. No whole-world rollback
or client-side gameplay simulation was added. Spawn admission/candidate placement
must reserve the bounded predicted camera lead in co-op; solo geometry is unchanged.

## Laws first

The initial law draft was independently back-translated and rejected: fresh-state
examples did not protect an existing history, and ACK idempotence alone admitted
"discard everything". The revised contract specifies the exact arbitrary-state
transitions, ACK filtering/counter alignment, chronological replay, phase gate,
finite horizon and expiry behavior. Sixteen prediction laws and three spawn-policy laws pass the Bend kernel
with `--verdict`. This proves the stated discrete transitions, not browser wall
clock scheduling or an arbitrary network SLA.

Falsification before proof found two actual candidate defects: a lower repeated
ACK could reduce consumed steps, and a retained expired segment could move again
on the next local tick. Both have dedicated laws and regression cases.

The regular check suite also exercises the IO boundary: immediate dispatch without
advancing a timer, receipts only after advanced steps, ordered observations across
same-tick pauses, and immutable authority when applying display prediction.

## Controlled browser observations

`coop-latency-browser.mjs` uses the real Bend Worker, UI and Renderer with an
explicitly delayed byte link. These are input-to-render observations, not an Iroh
network benchmark. Both outbound and inbound paths contribute to the configured RTT.

| RTT | Old start | Old reverse | Old stop | Candidate start | Candidate reverse | Candidate stop |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 100 ms | 340 ms | 246 ms | 306 ms | 21.7 ms | 19.0 ms | 39.4 ms |
| 250 ms | 460 ms | 395 ms | 452 ms | 21.0 ms | 27.3 ms | 36.1 ms |
| 500 ms | 653 ms | 633 ms | 697 ms | 8.2 ms | 28.3 ms | 32.9 ms |

All candidate motion appeared before the authoritative ACK. Camera lag and final
position error were zero. A real Bend XP fixture opened the global reward pause;
held input produced zero motion after the paused observation arrived. The test
fails above 50 ms first motion/reversal, 84 ms stopping, or one unit of final error.
Fifteen typed negative controls compile successfully and are rejected by the
corresponding proof/helper checks. The gate is part of the regular `check.sh`.

These bounds apply to the tested healthy browser scheduling and RTT scenarios;
exhausting the prediction horizon intentionally freezes local forecasting.

Development artifacts: `/tmp/bendvy-coop-latency-baseline` and
`/tmp/bendvy-coop-latency-candidate`. The actual Iroh smoke remains a separate gate.

## Final regression cohort

The frozen implementation also passes final real-render measurements: start/reverse
15.6/22.1 ms at RTT100,8.7/7.6 ms at RTT250,5.3/5.4 ms at RTT500; stopping
42.6/39.2/35.7 ms. Artifacts: `/tmp/bendvy-coop-latency-final`. A review additionally
found and fixed duplicate observation admission and a missed pause/resume snapshot:
Bend's strict observation gate runs before any display-clock changes, and a new
reward-round ID invalidates pre-pause prediction history even when snapshots were
coalesced. Both have controller regression tests.

Final functional checks pass effects159, solo948/request720, mechanics14, replay5,
the complete main check suite and original Session compatibility; native C
`native-test` passes43 assertions. The co-op-only spawn padding intentionally changes
co-op positions, so old-geometry baseline equality is not presented as a release gate.
