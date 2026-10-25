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

The initial browser check uses two isolated contexts on one machine. It verifies
shared-world input, map behavior and guest departure; it does not qualify different
physical networks or native/browser floating-point agreement. Browser suspension
can stall the host; no migration, whole-world rollback or mid-run rejoin is provided.

## Guest input response

Guest input is sampled on the next fixed 60 Hz tick. Each numbered tick is
predicted once and sent through Iroh; the host consumes at most one queued tick
per world step and acknowledges its exact number. Reconciliation repeats only
the remaining ticks, rather than estimating durations between heartbeats.
A small Bend core predicts your displayed position, camera and own weapon visuals. The world still
confirms damage, pickups, XP and rewards. Remote actors retain interpolation.
A known reward pause or death disables prediction. Its history/horizon are bounded;
it freezes when it cannot safely extend the forecast. Reload both peers after
updating to a different host protocol version.

The proof and mutation gates are included in `check.sh`.

Own weapons use detached Bend forecasts with the same spawning and trajectory
helpers as the host. They replay the same pending input ticks as the player.
Each visual shot has a semantic identity (player, birth tick, base weapon and
volley slot), independent of its physical pool slot. A continuing shot retains
its displayed trajectory across observations; a new target snapshot must not
recreate its past flight. Its birth identity is stored separately from visual
age: a burst of authoritative clock updates cannot advance its flight a second
time. Only local fixed ticks advance an already displayed shot. Remote weapons
remain received observations.

These forecasts use the latest observed enemy geometry. They never resolve
damage, pickups, XP or rewards. The small replay/guard/identity/continuity policy
kernel has checked laws and negative mutations; the shared Game adapters are
qualified by runtime tests, rather than a claim that the entire game is proved.

Historical browser observations are recorded in [the research](../../research/coop-projectile-visibility.md).

## Co-op hall

The Co-op tab shares the Moon Seal shell, expedition card and Bend-backed
selection pickers with the solo menu. Its setup is prerendered by Astro.

Create room fixes the host setup and immediately opens an invitation dialog.
Share opens the device share sheet when available; Copy invitation link provides
clipboard feedback or a selectable link. The room starts when the guest joins.
An invitation URL opens the guest entry directly, with Survivor and Arcana
choices and one Join party action; it never offers Create room. Close room
releases the connection and restores setup editing.

The accepted menu study was variant B (separate Co-op hall in the shared menu).
The throwaway study and its local server have been removed.

## Requested follow-ups

After the SEO/share-card work:

- Completed: touch control now selects all eight keyboard directions with a neutral centre. The input mapping has a neutral centre and eight direction sectors.
- Revisit the two-player limit. It is currently in the session and one-peer transport adapter, not merely the Co-op hall. Support more guests and make the actual capacity clear in the UI. Remind the user after the touch-control task.
