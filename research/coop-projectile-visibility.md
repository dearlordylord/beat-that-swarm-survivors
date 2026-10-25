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

## Confirmed hit / displayed geometry mismatch (public 4a)

A subsequent player report concerns projectile/monster contact, not birth origin.
The prior birth and flight-speed gates do not cover this contract. Clean public
revision `4a14c4200c10d39d364726ca81edbf9c9d38a4b7` reproduced it with default Mira
for both players. Read-only worker instrumentation captured every authoritative
step's bodies/trajectories. No extra world step or world query was executed.

The impact diagnostic accepts a causal example only when an enemy loses health
(or changes into loot), exactly one projectile has contact geometry, that shot
belongs to the guest, no host projectile is a contact candidate, and the shot
with a single remaining pierce simultaneously becomes dormant. All 12 selected
examples in this cohort met those conditions; 7 were on screen.

One clean example:

| Measurement | Authoritative step 386 | Last guest draw 16 ms before confirmed monster disappearance |
| --- | --- | --- |
| Enemy identity |41, HP 9→0 |41 |
| Projectile generation |`1:361:0:1` |`1:361:0:1` |
| Center distance |10.514 |64.355 |
| Combined collision radius |13.125 |13.125 |
| Gap between circles |−2.611 (overlap) |51.230 (separate) |

The authoritative circles already overlap at the beginning of the step. An
independent compiled Bend `projectile-contact.bend` check returns `Hit(time=0)`;
this is a geometry measurement, not a claim that newer swept-contact source had
already been deployed in 4a. Another example after the guest stopped moving had
an authoritative overlap at 0.951 distance while its displayed circles were 25.081
units apart 20.7 ms before disappearance. This is too large to be an ordinary
single-frame Spark movement of at most 7.5 units.

There were no floating damage-label creation events: these early enemies have
9 HP and the Spark deals 11, so they disappear rather than retain a lower HP row.
The observed inconsistency is the projectile/recipient endpoint and death timing,
not a misplaced damage number.

Artifact: `/tmp/bendvy-coop-projectile-impacts-public-kills/same-context.json`,
`confirmedContacts` and the corresponding per-step/per-render rows. This heavily
instrumented cohort is evidence about geometry, not a performance benchmark.

The public site changed during the first delayed comparison probe. Its results
are excluded from the clean 4a comparison. The harness now checks release source
fingerprints before and after each run and discards mixed-source cohorts. Further
qualification uses a frozen local candidate rather than a moving public deploy.

## Coherent combat contract gate

`COOP_PROJECTILE_COMBAT_CONTRACT=1` validates the new combat presentation metadata:

- All enemy/player-projectile/hostile-projectile rows carry the same cohort tick.
- Every declared sweep witness agrees with compiled Bend `Contact.sweep`, its
  impact-time circles overlap, and its shot/target birth identities are valid.
- Witness history is at most 4 ticks; point contacts are checked separately from
  swept contacts, without requiring a knocked-back enemy's later endpoint to
  remain inside the original impact circle.
- Where a prior rendered tick exists within the same canonical anchor, witness
  start positions resolve to the named actor lifetimes and their exact geometry.
- A pure readonly compiled-Bend probe verifies that empty input history renders
  the fresh canonical combat scene exactly, matching authoritative combat bodies.
- Existing noncombat pickup/relic/effect presentation is preserved at the
  controller boundary.

Birth-origin and input-latency requirements remain. Flight jumps within an
unchanged canonical anchor remain rejected. Changes at an explicit canonical
anchor are recorded separately, since correcting a misprediction is distinct
from translating a bullet in response to player input; their size is reported
rather than silently hidden. No new combat-contract pass is claimed until the
candidate runs these gates.

Impact capture additionally uses `COOP_PROJECTILE_IMPACTS=1` and
`COOP_CONTACT_MODULE=/absolute/path/to/emitted-projectile-contact.mjs`.
The contact helper is emitted from the existing Bend source, with no new package:

```sh
bend examples/survivors/projectile-contact.bend -o /tmp/projectile-contact.mjs
COOP_PROJECTILE_IMPACTS=1 COOP_CONTACT_MODULE=/tmp/projectile-contact.mjs \
  COOP_PROJECTILE_ENFORCE=0 node examples/survivors/coop-projectiles-browser.mjs
```

## Coherent-candidate preruns are NOT original-bug closure

The initial local coherent-combat probes had `impacts=false` and therefore
`confirmedGuestContacts=0`, `displayedConfirmedContacts=0`. Their 28/19 contact
counts were **predicted witnesses only**. They established internal cohort/contact
geometry, lifetime checks and zero-history canonical adoption; they did not
establish correspondence with actual host hits. They must not be reported as an
overall fix or overall gameplay PASS.

They also left a material smoothness failure: the 800 ms observation-delay probe
recorded 18 canonical projectile corrections, maximum 203.988 world units. Naming a
jump “canonical” does not make it smooth or bounded. No decay/bounded-correction
claim is established by these probes.

### Read-only classification of the five largest residuals

All cases below are guest-owned (`owner=1`) Spark projectiles (`kind=1`, weapon 0).
Ordinary travel is conservatively bounded by `7.5 × ageDelta`; the residual column
is a lower bound on displacement that cannot be explained by that time advance.
The Spark homes; this bound does not assume a constant direction.

| Generation / physical seed | Before→after position | Age change | Authority / cohort ticks before→after | Pending steps before→after | Actual displacement | Maximum ordinary travel | Residual lower bound |
| --- | --- | --- | --- | --- | --- | --- | --- |
|`1:81:0:2` /517 |(7434.027,7189.0366)→(7291.9272,7042.685)|17→21|48/98→51/102|50→51|203.988|30|173.988|
|`1:41:0:1` /515 |(7268.214,7162.692)→(7255.6094,7125.273)|5→10|22/46→26/51|24→25|39.485|37.5|1.985|
|`1:41:0:1` /515 |(7254.375,7110.324)→(7245.7847,7080.318)|12→16|26/53→29/57|27→28|31.211|30|1.211|
|`1:41:0:1` /515 |(7244.751,7065.354)→(7237.032,7035.304)|18→22|29/59→32/63|30→31|31.026|30|1.026|
|`1:41:0:1` /515 |(7236.1475,7020.3306)→(7229.187,6990.256)|24→28|32/65→35/69|33→34|30.870|30|0.870|

Receipt sequence is 0 in every listed before/after observation. Pending steps are
derived from the exact scene tick minus its canonical authority tick, not guessed
from wall time. Source: `/tmp/bendvy-coop-combat-candidate-delayed/correction-residuals.json`.

The largest jump is not mainly a four-tick aging jump: at least 173.988 units
(85.3% of its 203.988 displacement) require a different reconstructed trajectory or
birth origin. The generation is not present in either canonical source snapshot:
its birth tick 81 is later than both anchors 48/51. Both speculative states have no
contact events; enemy lifetimes 95/14/39 remain alive with unchanged HP. Their
canonical positions move only a few units between anchors. This rules out a hit,
knockback or a newly applied damage effect as the cause. Before rebase, the
projectile's last measured one-age displacement was approximately (+7.4723,−0.6444),
heading right; the reconstructed point jumps strongly left/up. Exact selected aim
IDs were not captured, so a particular nearest-target branch is not asserted.

### Verified causal clock mismatch, without claiming input-delay injection

The control delays received observations by 800 ms, **not input commands**. Guest
Right keydown occurred at 1621.9 ms on the guest clock. Converted to that same clock,
the actual host spawned generation `1:41:0:1` at 1392.10 ms, 229.8 ms **before the key
was pressed**, at (7232,7200). The guest first rendered that same generation at
1933.3 ms from its moved-player context `(7279.5,7200)`.

Host frame 54 was generated at 1607.4 ms, before the keydown, and correctly had
receipt 0. Frame 58 was generated at 1669.9 ms with receipt 3 (neutral); frame 61 at 1718.5 ms
had receipt 6 (Right) and player x 7239.5. These traces do not support an 800 ms input
arrival stall. They demonstrate that new client movement ticks are replayed into
world/ability intervals that had already elapsed before the input existed.
The host world advances while the input FIFO is empty; the predictor treats
unacknowledged movement ticks as the next world ticks. Those are different clocks.

## Strict confirmed-hit gate before time migration

`COOP_PROJECTILE_IMPACTS=1` now defaults to the confirmed-contact contract. A real
host HP drop/kill plus uniquely attributable single-pierce projectile removal
must match an actual rendered witness with **exact world tick and exact
`(shot, shotBirth, target, targetBirth)` identities**. Its four sweep endpoints,
radius and contact time are compared to the authoritative path, with only small
serialization tolerances. Missing/wrong-target/wrong-tick contacts fail; there is
no canonical-rebase exemption. Nearby ticks are recorded diagnostically rather
than accepted as matches. This gate is separate from predicted contact truth.

## Strict confirmed-contact baseline remains RED

The first strict local normal run captured 12 actual guest contacts. Eleven had
an exact rendered contact with matching world tick, lifetimes and path; one did
not. The missing event is not merely a shifted image:

- Authoritative guest shot 515, birth 361, kills enemy 62/birth 4 at tick 395.
- The guest instead rendered that shot hitting enemy 8/birth 10 at tick 389.
- Read-only host snapshots show why: the host's own future shot 512/birth 361
  uniquely kills enemy 8 at tick 387 (`Contact.sweep` time 0.3627547). Both enemy
  and single-pierce host shot become dormant in that step.
- The false guest prediction was built from canonical anchor 338. That anchor
  contains only the already existing host shot 514/birth 321. The model explicitly
  omitted future host auto-fire (`remoteFutureBirths=false`), leaving enemy 8
  incorrectly alive until the guest shot reached it. On the real host, that
  guest shot passes the dead enemy 8 and reaches enemy 62.

Thus the first wrong-recipient case has a directly observed missing-remote-volley
mechanism. It should not be attributed wholesale to input timing. The separate
clock/birth reconstruction evidence above still applies to the 204 unit correction.

Normal artifact: `/tmp/bendvy-coop-combat-confirmed-normal/same-context.json`;
precise enemy 8kill: `enemy8-death.json` in the same directory. The strict normal
run is **FAIL**, not an overall fix, despite 22 internally valid predicted witnesses.
The elapsed-time flight check also observed bursts, and host progress was 52.54 Hz
under this instrumentation. These are not isolated-engine performance results.

The already running 800 ms delayed strict baseline completed before the subsequent
pause request: 19 actual contacts, 16 exact lifetime/tick witnesses, 12 exact path
matches, 7 failures (three missing exact contacts, four path/time differences).
One missing contact had the same lifetime only at tick+1; it was recorded, not
accepted. Path differences ranged 0.044–0.874 world units; they are distinct from the
wrong-recipient failure. Host progress was 59.22 Hz. Artifact:
`/tmp/bendvy-coop-combat-confirmed-delayed/same-context.json`. Before/after SHA256
hashes of all eleven critical served modules matched in both strict baselines.

The full native Scene was not retained by the original observer. A compact,
honest reconstruction source is available at
`/tmp/bendvy-coop-combat-confirmed-normal/anchor338-observed.json`: 101 active
body/motion rows in original order, actual player positions/health, compiled
artifact hashes, and the false/real contact records. It explicitly lists missing
full PlayerRun and omitted visited/slow/burn fields; it must not be described as
an exact native Scene dump. A synthetic production regression can combine those
observations with the known default Mira loadout and explicit status assumptions.

### World-time + all-known-player-volley candidate: strict browser baseline remains RED

The next frozen local build (`/tmp/bendvy-combat-worldtime-build.log`, preview43251) was tested sequentially with actual Iroh. Both URLs retained `?combatTrace=1`; the zero-input probe used `Prediction.fresh(px,py,distance,true,frame.tick,0)`. The declared remote future-fire assumption is now `current-loadout-and-held-input`, with `remoteFutureBirths:true`. Eleven served module hashes remained identical before and after each run. These measurements include heavy read-only contact tracing and are not isolated engine throughput benchmarks.

| Measurement | Normal Iroh | +800ms received observations |
| --- | ---: | ---: |
| Authoritative guest contacts | 9 | 3 |
| Exact lifetime + world-tick witnesses | 8 | 2 |
| Exact authoritative contact paths | 8 | 0 |
| Internally valid predicted witnesses | 21 | 25 |
| Canonical projectile speed-bound violations | 3 | 9 |
| Within-anchor speed-bound violations | 27 | 10 |
| Largest canonical displacement | 52.50 | 382.94 |
| Largest excess over wall-time flight bound | 13.42 | 269.44 |
| Moving age-zero births | 5 | 1 (insufficient coverage) |
| Maximum covered newborn origin distance | 2.5 | 0 |
| First Right key → positive displayed displacement | 254.2ms | 566.8ms |
| Host world progression under tracing | 31.99Hz | 39.71Hz |

Normal still misses the exact authoritative event `(tick224,shot515,birth161,target95,birth1)` entirely; no rendered witness exists for that shot lifetime. The delayed run has one missing event `(283,513,241,47,1)` and two matching identity/tick events with path errors0.321 and0.611units (contact-time errors0.035125 and0.004197). Exact path tolerance remains0.01units and0.001time. No acceptance threshold was relaxed.

The normal maximum residual is partly a clock-catchup problem: generation `1:81:0:2` advances age20→24/cohort101→105 in7.1ms at unchanged authoritative tick45, travelling29.416units against the16unit wall-time bound. Another same-anchor shot advances four physics ticks in7.2ms. All canonical corrections now face the same global elapsed-time flight bound; anchor changes are classified for diagnosis and provide no smoothness exemption. The delayed maximum382.94unit correction is unresolved. Internal cohort/contact geometry and noncombat preservation passing does not override these failures or prove the original confirmed-hit issue fixed.

Artifacts: `/tmp/bendvy-coop-worldtime-normal/same-context.json` and `/tmp/bendvy-coop-worldtime-delayed/same-context.json`; run logs share the corresponding prefix with `.log`. All probe browser contexts and browser processes closed after the runs. The harness additionally records future `predictionTiming` metadata and per-key movement responses for subsequent diagnosis; these two already-running captures retain their original fields and the response times above were derived directly from their recorded input/render timestamps.

## Normal gameplay observation without the heavy trace

A later lightweight, real-Iroh observation used diagnostics OFF, rare native
pre/post impact events, a bounded draw buffer and two screenshots. Seven served
module hashes were unchanged before and after. It observed host 60.30 ticks/s,
guest 59.93 FPS and eight input responses of 17.9–26.9 ms. Observer work measured
0.057 ms per host tick and 0.009 ms per guest frame.

Of 14 uniquely attributable authoritative guest hits, 12 occurred during captured
drawing. The shot and target at the exact preceding displayed world tick matched
authority within 0.000291 and 0.000309 world units respectively. The other two
hits preceded capture and have no display conclusion. This supports the normal
moving-guest case; it is not a guarantee for arbitrary delay or a replacement for
manual assessment. Screenshots show both players, projectiles and enemy HP bars.

The earlier normal missing witness224 was separately traced to a renderer jump
222→228: its debug TTL4 had already discarded224. Shot/target positions at217–222
matched authority within0.00024. Thus that missing diagnostic record does not
establish a wrong target. The +800ms canonical-correction observations above
remain unresolved; the lightweight normal run does not qualify that condition.

Artifacts: `/tmp/coop-impact-light-worldtime-report.md`,
`/tmp/coop-impact-light-worldtime.json`,
`/tmp/coop-impact-light-worldtime-analysis.json`, and
`/tmp/bendvy-coop-worldtime-normal/missing224-causal.json`.
This observed bundle precedes the separately qualified Game.at/AABB optimization;
source-specific final build verification remains necessary.
