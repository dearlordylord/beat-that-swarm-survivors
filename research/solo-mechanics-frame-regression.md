# Solo frame regression: unnecessary crowd scans

The themed mod introduced an unconditional snapshot scan in
`game.prepared_projectile`. Every player projectile slot, including dormant and
ordinary slots, counted nearby enemies before `Shot.prepare` selected its mechanic.
Contact planning prepared the same projectile twice. The player pool has 512 slots.
The pre-fix browser CPU profile identified this traversal and garbage collection
as major costs. The loadout SVG update is already guarded by its signature and
did not explain the steady-frame regression.

The fix counts enemies only for unresolved Ink fields and reuses the prepared
value in contact planning. Other attack types still call `Shot.prepare` with zero:
fan turnaround and the resolved Ink pulse transition must continue to run.
No simulation frequency, sprite fidelity, canvas resolution or ability rule changes.

## Qualification

Measured on this Linux ARM64 development host with 12 logical CPUs. Initial load
average was 2.57. No CPU throttle was applied. This is not an iPhone or Safari
measurement, and it does not establish a native or multiplayer speedup.
The pre-fix simulation is the gameplay code at `a1756a6`; the original fork base
`963cc82` was inspected to locate the newly introduced scan, not benchmarked.

| Workload | Before | After |
| --- | --- | --- |
| Seeded 600-step solo simulation plus observations | median 9,303.8 ms; range 9,209.7–9,592.1 | median 3,153.3 ms; range 3,090.2–3,291.8 |
| Browser callback p50 (median across five runs) | 11.0 ms; range 10.7–11.6 | 4.7 ms; range 4.5–5.0 |
| Browser callback p95 (median across five runs) | 14.7 ms; range 12.5–21.3 | 9.2 ms; range 7.0–10.1 |

The simulation test warmed each compiled module for 60 steps, then alternated
five fresh 600-step runs per variant with seed 12345, character 0, and rightward
input. Every advancement succeeded, reached tick 600 in active phase 0, and
produced the exact same final observation SHA-256:
`93626f9dfe5e9bf83548eb5ba79325c4cae2bc803e9926793fcfe2eb84e68a93`.
This measures simulation and observation work, excluding rendering and network.
The removed repeated snapshot traversal is the identified limiter.

The browser comparison used the same built frontend with the before/after
compiled simulation substituted at its ordinary module URL. It alternated five
fresh contexts per variant at a 390×844 viewport, DPR 2, and mobile layout in
headless Chromium. After 30 warmup ticks, each context measured 3.5 seconds of
rightward gameplay. All ten contexts advanced the world and reported zero page
errors. Animation callback duration includes simulation, rendering calls, audio
updates and HUD work, but excludes subsequent compositor work and frame waiting.
Both variants remained near the 60 Hz display limit on this host; callback time
is not a claim of increased displayed FPS. Measurements did not run under the
CPU profiler. Separate Bend checks ran during part of the simulation comparison;
the browser comparison ran without those checks or a build in parallel.

Raw JSON measurements, the diagnostic CPU profile and local harness scripts are
retained outside tracked source in `/workspace/survivors-performance-report`.
The full mechanic policy, integration and review checks pass after the change.
