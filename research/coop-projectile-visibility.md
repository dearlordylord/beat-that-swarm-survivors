# Guest projectile birth is behind the displayed player

## Reproduction

Public revision: `5c172fe648a912505bf04f8136d40f5e71a806bf`.
Both players use the default Mira (character 0, weapon 0). The test runs the actual
public browser game over actual Iroh, instruments only received observations and
renderer entry points, holds Right for 4 seconds, reverses Left for 3 seconds, and releases.

The guest's projectiles exist in the authoritative world, are sent, are received,
and reach the on-screen projectile renderer. The failure is their birth origin:
the player is predicted into the present while its projectiles are displayed at
the authoritative position from the past.

| Scenario | Authoritative frames with guest shots | Received frames with guest shots | Guest on-screen projectile calls |
| --- | --- | --- | --- |
| Same browser context, two pages |116|116|525|
| Isolated browser contexts |117|117|482|
| Same context, injected 800 ms observation delay |129|128|583|

Headless Chromium reports both pages as `visible`, including after `bringToFront`.
These runs do **not** reproduce a physically minimized or background browser tab.
The controlled delayed-observation case retains real Iroh but adds 800 ms to the
received-message callback. It is explicitly a delay experiment, not evidence
about the browser's hidden-tab scheduling policy.

## Exact samples

With no injected delay, same-context draw tick 121 has a newborn guest projectile:

- Projectile seed 513, age 0, world position `(7477,7200)`.
- Displayed guest position `(7527,7200)`.
- Authoritative guest position `(7479.5,7200)`.
- Birth is 50 world units behind the visible player, approximately 333 ms of movement.
- It is only 2.5 units from the authoritative player, the expected single-step offset.

With 800 ms controlled observation delay, draw tick 201 shows the same failure at
exactly one second of travel:

- Projectile seed 513, age 0, world position `(7554.5,7200)`.
- Displayed guest position `(7704.5,7200)`.
- Authoritative guest position `(7554.5,7200)`.
- Birth gap 150 world units at 150 units/s: 1 second.

This separates missing rendering from a stale origin. The rendered camera and
own player use prediction, but projectile birth geometry remains authoritative
past geometry. Existing in-flight projectiles must not be continuously translated
with subsequent player movement: the recording includes a direction reversal so
such dragging can be inspected separately from the birth defect.

## Harness

`examples/survivors/coop-projectiles-browser.mjs` captures:

- Host worker local frames and remote frames, including projectile bodies.
- Guest received frames and receipt metadata.
- Every actual renderer draw and projectile call, world/screen coordinates,
  displayed/authoritative player positions, body age, seed, and variant.
- New generations identified by a seed's age reset; only age 0 births while
  prediction is ahead participate in the birth-origin regression assertion.
- Input events and visibility transitions, plus screenshots.

Default regression requires that guest shots exist at every observation boundary,
reach the on-screen renderer, and that at least two moving newborns appear within
8 world units of the displayed guest. The latter limit is configurable; it allows
more than the observed 2.5 unit spawn-step offset while rejecting the reproduced
42.5–150 unit delay gap. It does not assert the future position of an already flying
ballistic projectile.

```sh
PLAYWRIGHT_MODULE=/path/to/playwright/index.mjs \
  node examples/survivors/coop-projectiles-browser.mjs
COOP_PROJECTILE_DELAY_MS=800 PLAYWRIGHT_MODULE=/path/to/playwright/index.mjs \
  node examples/survivors/coop-projectiles-browser.mjs
```

Use `COOP_URL` for a local candidate and `COOP_QA_DIR` for captures.
`COOP_PROJECTILE_ENFORCE=0` records a failing baseline without reporting a pass.
Optional cases `throttled` and `frozen` are explicit controls, not hidden-tab claims.

Baseline artifacts:

- `/tmp/bendvy-coop-projectiles-origins/same-context.json`
- `/tmp/bendvy-coop-projectiles-isolated/isolated.json`
- `/tmp/bendvy-coop-projectiles-delayed/same-context.json`

For forecast candidates, projectile rows carry a semantic generation string in
column 9 and an explicit owner in column 10. The harness uses those fields without
numeric casts; physical seed parity is only the old-version fallback. Age remains
column 6. It also checks that a default Spark's in-flight displacement fits its
7.5 units/fixed-tick speed and elapsed draw time (one tick of quantization plus
one unit tolerance), including the input reversal. The core's stronger exact law
must separately establish that turning the player does not translate an already
flying ballistic projectile.

The birth-origin gate was actually run red against the public version:
`/tmp/bendvy-coop-projectiles-red` reports two moving age 0 births and a maximum
40 unit distance, rejecting the 8 unit limit after all create/send/receive/draw checks
passed.

## First forecast candidate

The first local Bend forecast candidate fixed the birth origin: 11 moving newborns
were at most 2.5 world units from the displayed guest. Host simulation remained
60.13 Hz and 637 frames were drawn during the probe. However, the in-flight speed
gate correctly rejected 18 jumps, including 2 while the player stood still.

For semantic generation `1:241:0:6`, age 13 position `(7779.9224,7278.4316)` became
age 14 position `(7716.027,7095.171)`16.7ms later:194.08units of displacement, versus
a 23.5 unit elapsed-time bound. Another stationary-player projectile jumped 81.9 units
at age 16→17. These are not rendering failures or ordinary input motion. Recreating
the forecast from each new authoritative anchor can choose a new target for an
already displayed predicted birth, changing that generation's trajectory.
The exact same-initial-frame turn-independence property alone does not cover this
cross-observation rebase case. Artifacts:
`/tmp/bendvy-coop-projectiles-candidate/same-context.json` (`flightJumps`).

## Rebased trajectory candidate: second failure exposed

Retaining existing semantic trajectories removed the large aim reversals, but a
second browser regression remained: network authority catch-up advanced a visual
projectile's age by the authority tick gap in addition to local elapsed ticks.
A generation `1:41:0:1` advanced age 19→28 in 23.6 ms, moving 67.5 units while the player
advanced only 2.5 units. The authoritative observation tick jumped 24→33 during
that short interval. There were 10 flight-speed violations in this run; births
still passed 11 cases at 2.5 units maximum distance.

The 800 ms delayed run also kept newborns within 2.5 units (10 moving births), while
its elapsed-time flight guard still failed. Both runs preserved 60 Hz host progress.
This failure occurs on a burst of authoritative observations and must not be
hidden by accepting smooth steady-state motion only. Artifacts:
`/tmp/bendvy-coop-projectiles-rebased` and
`/tmp/bendvy-coop-projectiles-rebased-delayed`.

## Final clock-fixed forecast candidate

Both real-Iroh browser scenarios now pass the same unchanged birth and flight
bounds, including the direction reversal and the startup observation burst.
The candidate retains each semantic projectile's birth decision and visual
trajectory across rebase; an authoritative tick jump does not advance its visual
age. Only the local fixed-step forecast advances an already displayed projectile.

| Scenario | Moving age 0 births | Largest birth distance | Flight comparisons | Flight-speed violations | On-screen own-shot calls | Host Hz |
| --- | --- | --- | --- | --- | --- | --- |
| Real Iroh, no injected delay |10|2.5|723|0|740|60.00|
| Real Iroh, added 800 ms observation delay |10|2.5|1270|0|1251|59.85|

There were no browser or worker errors. Both pages remained reported as visible;
this does not certify a physically minimized macOS host browser. The second case
specifically reproduces the large authoritative/predicted position gap while
verifying that newborn shots originate at the displayed player and existing
ballistics keep their elapsed-time speed through reconciliation.

Artifacts:

- `/tmp/bendvy-coop-projectiles-clockfixed/same-context.json`
- `/tmp/bendvy-coop-projectiles-clockfixed-delayed/same-context.json`

These are local candidate assets served from port 8792, not a claim that the public
site already contains the fix. Local build previews do not have a release
`version.json`; the harness records that metadata as unavailable instead of
mistaking an HTML fallback for release provenance. Fresh prepared deployment
assets still require the repository's publication guard.

## Release transport qualification

The first prepared-release latency run exposed excessive delay in its CDP test
link: transferring Uint8Arrays as arrays of individual numbers made a larger
forecast observation back up behind test-driver serialization. The same prepared
build passed unchanged thresholds after encoding the fixture bytes as base64:
at nominal 500 ms RTT plus ±40 ms ordered variation, both actual one-way p95s
were about 297 ms, pending input stayed below 40 ticks and reversal was 19 ms.
This was an instrumentation control, not a faster-game claim.

The production wire format was also reduced: the static 256-ID ownership list is
reconstructed by `WeaponPrediction.receive` in Bend instead of sent on every
observation. A startup metadata sample decreased from 9362 to 1670 bytes; decoding
restores all ownership IDs while preserving the run, shots, targets and births.
The runtime gate checks that omission and roundtrip.

Both fixture harnesses now transfer exact bytes as chunked base64 strings across
CDP and report actual delivery delays for both directions and maximum frame
size. Binary roundtrip controls covered 0, 256, 131073 and 1048576 bytes without
changes. Timings, ordering rules and acceptance thresholds were unchanged.

The compact candidate passed the full nominal RTT 100/250/500 ms plus ±40 ms
jitter cohort: zero backward frames, zero reconciliation jumps, zero release
drift and exact final position; pending input maxima 13/23/37, below the 60-tick
horizon. Actual frame one-way p95s were 96.5/171.0/297.7 ms. Artifacts:
`/tmp/bendvy-coop-jitter-base64-compact`.
