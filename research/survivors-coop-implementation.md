# Shared-world browser co-op

Implementation target: `master`, following the sparse ECS merge `7b26d84`.
This is the implementation contract, not a connectivity qualification report.
It supersedes the open questions in the earlier multiplayer research.

## Decisions

Two browser participants share one Bend ECS world. The host browser owns the
simulation; Iroh carries authenticated bytes, using relays in browsers. Neither
participant installs software. The solo compatibility interface uses the same
core with one participant. JavaScript and Rust provide IO and presentation only.

Shared match state includes clock, RNG, stage, mode, XP, level and earned gold.
Player components own identity, position, health, equipment and modifiers.
A world tick executes each world system once, with both players' commands.
Preserve existing solo system order and its pre-movement gameplay views.

Enemies pursue the nearest living player, breaking ties by stable PlayerId.
Contact checks consider every living player. Spawn admission excludes every
living player's camera. Existing shared pool budgets remain; no automatic
player-count difficulty scaling, friendly fire or player collision is added.

All pickups require physical proximity, including solo coins and healing.
Nearest eligible player collects, with PlayerId as the tie-breaker. Healing
belongs to that collector. Shared XP and gold credit once, using that collector's
Growth or Greed. Aggregate raw amounts by collector within a tick before integer
multipliers, preserving solo rounding. Damage precedes healing as in solo.

Levels pause the whole world and require an independent choice from each living
participant. Chests pause the world and require only their collector's choice.
Reward rounds have monotonic IDs; stale and duplicate choices cannot apply.
Chest-before-level ordering remains. Confirmed guest departure removes their
outstanding choice. Network control continues while gameplay is paused.

Co-op death is final; solo Revival remains. A dead host character continues
hosting. Host exit ends the session, without migration. Guest departure removes
the guest; no mid-run rejoin or equipment redistribution in this initial scope.
The minimap shows teammates and does not pause co-op.

Gold is a shared earned total. Each participant receives their entitlement once
in their own local profile, keyed by run and player. Dead connected players
remain eligible. The initial simple policy saves only a completed match receipt: leaving early or
losing the host does not bank an unfinished run. This deliberately omits partial
settlement; the UI never fabricates a terminal result from a disconnect.

## Initial network policy

Authenticated transport identity maps to an assigned player; a payload does not
grant player ownership. Strictly increasing command sequences suppress duplicates
and old reordered commands. Latest admitted movement applies on the next eligible
authoritative tick, with applied tick/sequence acknowledgments. Movement becomes
neutral after 18 admission ticks without a fresh update. Intended ticks are
observations, not a promise of rollback. Admission time continues across reward
pauses. Replay uses the accepted command log, not zero-delay intended inputs.

The host clock runs independently of rendering with bounded catch-up. Browser
suspension remains possible; do not simulate accumulated minutes on resume.
Host stall and connection loss are distinct from a character's death.

## Qualification required

Before claiming playable co-op: one-player compatibility, true shared-world
owner/modifier routing, physical pickup and exactly-once XP/gold, reward barriers,
death/disconnect, deterministic delivery/replay checks, and two actual Iroh browser
contexts. Transport success alone does not qualify gameplay. Cross-device and
native/browser determinism require separate evidence.

## Consultation

Astra reviewed the architecture and recommended explicit legacy adapters,
identity-preserving combat aggregation and independent reward control transitions.
[Poncle's online FAQ](https://poncle.games/vs-online-faq) describes group gold and
independent progression saving. Collector Greed is our explicit simple policy;
the FAQ does not specify that calculation.
