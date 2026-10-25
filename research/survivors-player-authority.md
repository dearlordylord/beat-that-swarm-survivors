# Survivors player and session authority

The solo owner is `Run{session, player}`. Co-op stores the session once in
`CoreState.shared`; the ECS player column stores only
`PlayerRecord{id, player, connected}`. The two payload types live in the pure
run-state domain module and do not import ECS, encoding, or a host.

| Authority | Facts | Writers |
| --- | --- | --- |
| Session | phase, tick, XP, XP threshold, level, kills, gold, seed, stage, bosses, mode, encountered enemy kinds, collected relic | Match setup, one shared step reduction, reward-round coordination, reward gold, disconnect termination |
| PlayerState | position, health and maximum, character, weapons, passives, invulnerability, arcana, meta, revivals, rerolls, banishes, skips, banned weapons and passives | Player setup, that player's personal step outcome, that player's accepted upgrade |
| PlayerRecord membership | player ID, connected | Player allocation and disconnect handling |

The session is not copied into persistent player records. A personal step
returns only `PlayerState`; it cannot overwrite shared XP or rewards. Co-op
accumulates earned XP, gold, and chest events separately and reduces shared
progression once. It no longer calls the solo finalizer with fabricated XP,
threshold, or revival values.

## Immutable inputs and observations

| Value | Source and construction | Validity and consumers | Writeback |
| --- | --- | --- | --- |
| Player step context | Current session paired with the actual player payload; the step tick is explicitly advanced during preparation | One prepared world step; movement, combat, targeting, allocation and personal outcome calculation | Only the explicit personal outcome is persisted |
| PlayerView | Step context, sampled directions and explicit connection eligibility | One prepared step; eligibility determines targeting, firing, collection and spawn pressure | Never persisted |
| Effect source context | Every player's real step context and eligibility, including disconnected owners | One contact/effect pass; existing projectiles retain their originating loadout, while disconnected players are not living targets | Never persisted |
| PlayerSnapshot | Current session paired with personal state and membership | One received prediction anchor; detached prediction can advance its own snapshot copies | Never written to the ECS |
| Spectator context | Observer's context with presentation camera coordinates selected from a living connected player | One observation; rendering only | Never persisted |

Disconnection changes membership, not health. The step cohort retains owner
stats for projectiles already in flight; a separate eligibility bit excludes
disconnected players from active decisions. Detached prediction follows the
same rule. Its initial clock comes from the explicit session tick, not the
first player's record.

The native profile result and browser frame remain observations of these
authorities. The current forecast codec serializes the nested session/player
context and the distinct `PlayerSnapshot` tag. There is no reader for the former
flat run or authoritative-record-as-forecast layout.

## Scope

This change preserves legitimate run/session ownership and spectator views.
It does not split every personal field into an ECS component, redesign reward
policy, or change pool limits. Actor component migration is owned by its
separate tickets.
