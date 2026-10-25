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

Guest input is sampled on fixed 60 Hz steps. Each command has an immutable
`targetWorldTick`, distinct from its transport sequence. The host applies it
only at that world tick; missing inputs resolve to neutral and late inputs are
explicitly rejected rather than moved to another tick. Reconciliation replays
every world tick, including neutral gaps, from the new authoritative anchor.

The client keeps a monotonic display cursor ahead of authority, using a bounded
lead selected from the Setup command round trip and a margin. Ordinary snapshots
do not renumber pending inputs or advance that display cursor. If authority
catches it, an explicit resync establishes a new interval; it is recorded in
`predictionTiming`. A bounded forecast freezes when it cannot extend safely.
A detached Bend forecast predicts player positions and known combat actors. The
authoritative world still confirms damage, pickups, XP and rewards. Pickups and
other noncombat presentation retain received observations.
A known reward pause or death disables prediction. Its history/horizon are bounded;
it freezes when it cannot safely extend the forecast. Reload both peers after
updating to a different host protocol version.

The proof and mutation gates are included in `check.sh`.

The combat forecast uses one scene clock for known enemies and friendly/hostile
projectiles. It calls shared Bend spawning, movement, swept-contact and status
helpers, retains true visited-contact lists, and predicts future volleys for all
observed living players using their current loadouts and observed input hints.
Future remote input changes and new enemy births remain unknown. Shot
identity includes player, birth tick, base weapon and volley slot, separately
from a recycled physical slot and visual age.

Every accepted observation replaces canonical geometry and replays the pending
input suffix. It cannot retain an old projectile trajectory indefinitely. Player
HP, pickups, XP and rewards remain authoritative; forecast contacts never commit
those outcomes. The pure adoption/replay/contact-policy kernels have checked
laws and negative mutations. Runtime comparisons qualify the Game adapters and
browser wiring; this is not a proof of the entire game or network scheduler.

Normal-connection manual observations match captured authoritative contacts and
keep responsive movement. This does not establish correctness for arbitrary
network conditions: future input and births remain unknown, and the +800 ms
observation-delay control still exposes corrections. Internally valid predicted
contacts alone do not establish that a host-confirmed hit was displayed. See the
evidence below for the measured scope and remaining limits.

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

## Netcode reference

The repository-only [netcode skill](../../skills/realtime-netcode/SKILL.md)
records the timing, prediction, identity and contact checks. It is not installed
as a global skill. See also the [patterns research](../../research/netcode-time-and-prediction-patterns.md)
and [existing skills and reading](../../research/existing-netcode-skills-and-reading.md).
