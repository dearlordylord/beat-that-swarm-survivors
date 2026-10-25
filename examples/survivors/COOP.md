# Browser co-op

Open `coop.html` from the Survivors web build. On the first browser choose your
survivor, arcana, stage and mode, then **Host a run**. Copy the invitation link to
the second player. They choose their own survivor and arcana and press **Join run**.
No installation is needed. Keep the host page open; browser transport uses Iroh
relays. Opening the map is local and never pauses the match.

Move with WASD, arrow keys or the touch pad. Attacks are automatic. Shared XP
level-ups pause the world while each living player chooses; a chest pauses for its
collector. A fallen character stays out while the other survivor continues.

At the shared match's terminal result, the existing Bend progression module saves
the local player's result to this browser's profile, keyed by shared run ID and
player ID. Repeated terminal observations do not award it twice. Equipment history
uses the same Bend observer as solo. Leaving early or losing the host is not a
terminal settlement receipt; an aborted session shows “Session ended” without
awarding accumulated gold or wins. This UI does not invent rewards for those cases.

`coop-ui.mjs` handles presentation and device input. It receives authoritative
frames from `coop-browser.mjs`; it does not advance gameplay. The renderer draws
all observed players and marks distant teammates on the map.

[Co-op presentation](coop-presentation.mjs) interpolates received positions using its configured display buffer.
It never predicts beyond the newest observation, and never changes the frames
used for rewards, progression, audio or the HUD. New/recycled actors and large
position jumps snap to their observed positions.

## Local development

From the repository root, install the browser build prerequisites described in
[README.md](README.md), then run `node examples/survivors/launch.mjs`. Open
the co-op URL printed by the launcher. The launcher builds current sources every time.
Remote browser clients require HTTPS; use the public site for invitations between
devices. Native solo launch remains independent of Node and the Iroh toolchain.

## Checks

Run `bash examples/survivors/check.sh` from the repository root for the
[proof and mutation gates](coop-session-README.md) and JavaScript host checks.
The [browser smoke check](coop-browser-smoke.mjs) accepts the served co-op URL
through `COOP_URL`; it requires Playwright and uses real public relays.

The initial browser check uses two isolated contexts on one machine. It verifies
shared-world input, map behavior and guest departure; it does not qualify different
physical networks or native/browser floating-point agreement. Browser suspension
can stall the host; no migration, whole-world rollback or mid-run rejoin is provided.

## Guest input response

Guest input is sampled on the next fixed 60 Hz tick. Each numbered tick is
predicted once and sent through Iroh; the host consumes at most one queued tick
per world step and acknowledges its exact number. Reconciliation repeats only
the remaining ticks, rather than estimating durations between heartbeats.
A small Bend core predicts only your displayed position and camera. The world still
confirms damage, pickups, XP and rewards. Remote actors retain interpolation.
A known reward pause or death disables prediction. Its history/horizon are bounded;
it freezes when it cannot safely extend the forecast. Reload both peers after
updating to a different host protocol version.

`check-coop-prediction.sh` is included in the ordinary `check.sh`: kernel laws,
negative mutations, movement comparisons and IO/controller checks.
`node examples/survivors/coop-latency-browser.mjs` measures actual input-to-render
response at RTT 100/250/500 ms, including release, reversal, reconciliation and a
real Bend reward pause. See [the evidence](../../research/survivors-coop-input-latency.md).
`node examples/survivors/coop-jitter-browser.mjs` additionally records every drawn
position during sustained movement, reversal and release, with delayed and
uneven packet delivery. It checks corrections and trajectory continuity; a fast
first response and eventual convergence alone are insufficient.
