# Cross-review: Space Station 14 vs. Streets of Rogue for maximum ECS exposure

**Question.** Does a *Streets of Rogue* (SoR) one-block mission beat the *Space Station 14* (SS14) engineer slice as an ECS showcase, once source-code evidence is separated from game-design suitability? This is a design review, not an implementation or benchmark. It follows the [selection contract](00-evaluation-contract.md): maximum ECS exposure and best first clone are different decisions.

## Decision

For the stated priority—**show as many distinct ECS mechanisms working together as possible, even if this is not the fastest MVP—SS14 remains the stronger candidate**. That conclusion comes from the games' mechanic surfaces: station actors, tools, containers, machinery, damage, environment, power and shift outcome naturally cross several independent system families. The original SS14 code is useful evidence that these seams exist in a real game, but “the source uses ECS” is not itself a reason to choose the game. A mechanically similar ECS consumer could be designed around a game whose original implementation used another architecture.

**SoR is the stronger single-player mission choice.** Its first-party description makes player-chosen approaches the point of each mission, and its solo mode preserves that loop. A one-block SoR clone retains more of its original play pattern than a solo engineer scenario retains of SS14's multiplayer role-play. That is a meaningful win for suitability, not proof that SoR has greater ECS breadth. SoR wins the comparison if the priority changes to a recognizable, closed, solo immersive-sim slice; it could also win the ECS comparison if implementation demonstrates shared, independently queried capabilities rather than encoding each approach in mission or `EntityKind` branches.

These recommendations are conditional by objective, not a combined score. The contract's ordinals are omitted here because the uncertain question is how much a proposed ECS mapping would really reuse—not how many source-confirmed game features can be counted.

## Evidence confidence is not design suitability

| Question | *Streets of Rogue* | SS14 |
|---|---|---|
| What do first-party sources establish? | High confidence in solo-capable play, procedural city setting, mission goals, and the advertised trait/item/environment approaches. Matt Dabrowski also says SoR 1's level structure supported small gameplay slices. | High confidence in the game's round-based multiplayer role-play identity and, separately, the documented RobustToolbox ECS model. |
| What can be audited in game code? | No SoR gameplay-source audit was available in this review. The sources establish mechanics, not entity storage, system boundaries, or whether reported AI is modular. | The pinned SS14 and RobustToolbox source audit recorded in [study 07](07-space-station.md) shows components, entity systems, cross-system calls and concrete hybrid-service boundaries. This raises confidence in the mapping; it does not prove a Bendvy clone should copy the engine's architecture. |
| How much of the game's central loop survives a small solo slice? | A mission with a selected character capability and several real ways to complete it is already a natural unit of solo play. A single block still loses run/city breadth. | A solo station-emergency can retain engineering, damage control, life support and evacuation, but the official description places role-play, crew/enemy jobs, and player-created outcomes at the heart of a multiplayer round. Removing other players is a larger change to the premise. |
| What could falsify the ECS case? | One shared interaction resolver with a pile of trait/item/target branches could produce the visible alternatives without demonstrating independent composition. | A linear scripted checklist could also pass through many components while no entity is genuinely reused across the station's systems. The specialized atmosphere, network and topology solvers could dominate the work. |

The asymmetry in source access must not be turned into a design ranking: it is easy to be more certain about SS14's intended system boundaries because its source is public. Conversely, the SoR Steam description's “complex AI” wording does not reveal whether its implementation is expensive, modular or reusable. Treat SS14's evidence as confidence in an ECS mapping and SoR's developer materials as confidence in the player's choice loop.

## What SoR's primary sources actually say

| Source-confirmed fact | Direct evidence | Safe design inference | Not established by this source |
|---|---|---|---|
| The game describes specific mission goals that can be completed through character traits, items and the environment. It gives examples: a doctor can use chloroform/tranquilizer darts, a bartender can talk past guards, and a soldier can use force. | [Matt Dabrowski / tinyBuild's Steam page](https://store.steampowered.com/app/512900/Streets_of_Rogue/), “About This Game.” | A single mission can make the player pick an approach and observe consequences. The proposed ECS version can represent these as reusable capabilities and interactions. | That each option is implemented by a different component, query or system in the original. The source does not describe those internals. |
| The game is described as a functioning, procedurally generated city, with AI-controlled inhabitants carrying out daily activities. The page calls out hacking and says the player need not kill anyone. | [Same developer/publisher page](https://store.steampowered.com/app/512900/Streets_of_Rogue/), description and feature list. | A fixed authored block can stand in for one playable level while keeping an NPC and object ecology. Hacking, stealth and nonlethal routes are appropriate choices to model. | A particular AI architecture, exact perception model, simulation schedule, or the engineering effort behind the marketing phrase “super-advanced AI.” |
| The store lists single-player as well as local/online co-op and PvP modes. | [Same Steam page](https://store.steampowered.com/app/512900/Streets_of_Rogue/), feature list. | Removing co-op from an initial clone does not remove the game's solo play mode. | That multiplayer never affects design or balancing, or that co-op has no player-facing value. |
| The developer calls SoR 1's structure “simple” and level-based, and says it lent itself to small vertical slices; he contrasts it with SoR 2's open world and broader systems. | [Matt Dabrowski, official Steam announcement, 18 July 2024](https://steamcommunity.com/games/512900/announcements/detail/4354501493553620255), paragraph about pre-release builds. | A level-scale prototype is a developer-endorsed scale for iteration. | That one arbitrary screenful/block is a complete SoR clone, or that the proposed vault objective below is in the original game. It is a clone slice we design, not a recovered mission. |

This is strong first-party evidence for a *player-facing* systemic design and a weak basis for claims about original runtime structure. “The game includes components” would be an unsupported statement; “this mission design can be expressed through reusable components” is a design proposal.

## Strongest case for each candidate

### Why SoR could win

SoR puts the human choice unusually close to the simulation: choose a character with a capability, inspect a goal and local situation, then decide how to approach it. Hacking, nonlethal takedowns, conversation and direct force are not merely additional subsystems; they change what the player can do to the same guard, door, camera or objective. The result is legible after a short session: the same mission can end through different courses of action. This is excellent for showing composition if abilities are represented as actual capabilities that make entities match different systems.

The most favorable one-block slice is: select one of a few small character kits, enter one authored city block, retrieve a mission item from a secured room, and leave through an exit. The block contains a guard, a civilian, a locked door, a terminal, a camera and the item. Keep at least three valid approaches:

1. **Hack** a terminal to disable the camera and unlock a door.
2. **Use a nonlethal item** to incapacitate a guard, then take and carry the objective.
3. **Distract or talk past** the guard and take the objective without a fight.

Direct force can be a fourth route if the small slice already has common health, damage and alarm behavior. Win by exiting with the item; lose by being incapacitated or letting the level's alarm/failure pressure close the route. The latter loss condition is a proposed slice rule, not a claim about the exact original mission flow.

Three concrete composition proofs can use only generic immersive-sim behavior—no station-specific atmosphere, power-network or crew-duty systems:

* `Stunnable` and timed `Unconscious` behavior are shared by player and NPC actors. The expiry system sees all unconscious actors; player-control and NPC-intent systems separately query conscious actors with their respective control capability. A guard-only stun branch is a failed proof.
* A `Hackable` capability can appear on both a camera and a door/terminal, while `Disabled` and `Unlocked` are independent results consumed by surveillance, traversal and objective systems. The hacking attempt is validated against the target's actual capabilities; “if camera then disable, if door then open” inside one resolver is a failed proof.
* A committed `SecurityAlert` can have independent readers: NPC intent changes, the mission's escalation rule advances, and the UI/log explains the new state. Camera detection and a failed/violent action can produce the same fact. The alarm is not allowed to complete or roll back the action by being an observer-only event.

These proofs reduce the risk that SoR's alternatives are only handcrafted mission branches. They also show the limit: they establish some reusable ECS systems, but do not by themselves produce SS14's broader containment, damage/destruction, environmental and round-lifecycle surface.

### Why SS14 still wins maximum breadth

SS14's advantage is not that its reference engine has “ECS” in its name. It is the way the game's mechanics connect domains:

* The same tool can be queried against a user, tool and target; target capabilities determine what operation can run. A repair/construct interaction has a real validation and cancellation point.
* Destruction spans targets from different families and can cause damage, effects, spills/material outcomes and entity/container cleanup.
* A crew member participates in movement, damage, hands/containment, breathing/environment exposure, tools and round outcome. Doors and machinery may participate in movement, damage, airtightness, interaction and power.
* Network/atmosphere, containment and component lifetime give relations and deletion real consequences. These expose useful lifecycle and ordering questions, although some of the underlying machinery lives in specialized services rather than in pure ECS queries.

Those are several independent cross-family systems even in a small station section. By contrast, the one-block SoR scene is naturally centered on actors, props and mission interaction; its alternative routes can be implemented as handcrafted scripts if the ECS model is not enforced. SS14 therefore exposes more distinct ECS mechanisms at once, while also carrying far more work that ECS cannot supply.

The source audit in [study 07](07-space-station.md) is intentionally qualified. Its specific examples are pinned to `space-station-14` commit `971889f18a6b5f14b926d139ba3910b2872e14de` and RobustToolbox commit `536b8ca955a361330990398e99282272aac974c1`. Robust documents data/marker components and behavior in entity systems, but it also has specialized managers. The pinned container implementation's TODO about making its manager component ECS-native is evidence of that hybrid boundary. SS14's atmospheric and power work also depends on network/topology solvers; those algorithmic systems are not ECS value added.

## What a one-block SoR slice loses—and what it must retain

The one-block cut retains the **local mission loop**, provided it retains a selectable character capability, an explicit goal, multiple operational routes and a visible outcome. That is a faithful *slice of SoR*, not a faithful small-scale copy of the entire game. It loses or compresses:

* the procedural multi-level city and variation across runs;
* progression through a larger city/level sequence toward a run-ending goal;
* the broad character/trait and item catalogue, which is part of replaying different approaches;
* interactions with the wider city and consequences beyond this block (this review does not rely on a claim about any particular long-term social-persistence system);
* co-op/PvP modes and the broader “city full of denizens” scale.

If the slice fixes one character and one route, it has removed the most important player choice and is no longer a useful SoR clone. If it fixes one block but keeps a loadout choice and three tested routes through the same goal, the unit is justified by the developer's level-based vertical-slice statement. However, this has not yet proven that the goal can be met through reusable ECS semantics: scripted routes could fake that result.

SS14's compact engineer emergency has the inverse tradeoff. It preserves tools, station machinery, environmental danger and evacuation, but loses the multiplayer social and antagonist-driven round that the official description calls central. Its breadth is mechanically deeper; its tiny slice is less representative of the social game. Neither candidate gets “recognizable clone” credit merely for having a mission/round-shaped win condition.

## Transfer semantics for Bendvy

Do not port event syntax by name. Robust's immediate `RaiseLocalEvent` dispatches to local subscribers; its entity-targeted form reaches one entity's applicable components and supports cancellable interactions. Robust has a separate `QueueLocalEvent` path for queued work. `SharedToolSystem` uses synchronous validation with user/tool/target participants, which is how an interaction can be vetoed before applying the effect. The implementation evidence and pinned references are in [study 07's event audit](07-space-station.md#directed-event-semantics-do-not-port-as-buffered-events).

Bendvy's current [`Data` event contract](../../../bendvy/docs/parity/typed-data-events.md) is a buffered stream with independent reader cursors, and publication is controlled by the committing system transaction. That stream is not a synchronous callback or request/reply mechanism. For either clone, represent a hack, talk, item-use or attack attempt as an input/intent; validate it in the owning action system and return an explicit result before world state changes. On success, commit component/relation changes and publish facts such as `CameraDisabled`, `DoorUnlocked` or `SecurityAlert`. Objective, AI, UI and log readers may then observe those committed facts independently. Do not publish a win banner or audio before commit: external output does not roll back with the world.

For SoR, this makes the `SecurityAlert` example useful: independent readers have distinct work after the action succeeds. The hacking action itself still requires a direct result path so the player gets correct success/failure immediately. For SS14, it similarly preserves the difference between a cancellable tool-use attempt and post-action facts like an item repaired or a breach sealed. The mapping is based on the documented source/target event semantics, not a demand that Bendvy mimic Robust's API.

## Adversarial read and criteria check

**Can one short array-of-structs loop run the SoR block?** Yes. A small object table and an action resolver could process movement, hacking and status with a handful of branches. The player sees the same route choices. ECS benefits the library only if the guard/player status, item ownership and target interactions are genuinely selected by independent component queries; route variety alone is not proof.

**Can one short loop run the SS14 slice?** A hard-coded engineer vignette can also be an array of records and a checklist. It earns more ECS value only when new repairable/damageable/containable entities plug into shared queries, and its effects reach independent environment, damage and outcome systems. It has more such seams, but costs much more host and solver work to make them convincing.

**Is complexity hidden outside ECS?** Yes, for both. SoR requires enough NPC perception/intent, line of sight, collision, level interaction and balancing for alternatives to be credible; broad trait/item content can become the project. SS14 adds grid/collision, atmosphere, network power, construction, content/UI and possibly multiplayer. More entity systems do not make those services free. SoR's advertised AI feature is not a code audit; SS14's source confirms some integration seams but does not mean atmosphere is a component loop.

**Do the player choices survive?** SoR: yes, if loadout plus three viable approaches survive on one block; no, if the prototype ships one prescribed route. SS14: an engineer must weigh sealing an environmental hazard against repairing power/evacuating, but a solo worker has no player-to-player role conflict. The solo slice is recognizable as a technical station emergency, not as the complete social station game.

**Would another candidate be a better counterexample?** FTL is stronger than SoR for a bounded ship run with explicit pause/crew orders/power/target choices; the sources reviewed emphasize those tactical choices more than SoR's free-form character/item/environment approaches. Baba is stronger for the most visible “player action changes which entities match which behavior” demonstration, but its room has fewer relationships and interacting physical domains. RimWorld/DF can exceed both in world-state variety, but labor scheduling and pathfinding can become specialized global algorithms. None of these claims implies those commercial games internally use ECS.

## Three competitor-source checks

These checks validate factual claims in [08](08-modular-ships.md), [10](10-rule-puzzles.md) and [03](03-colony.md); they do not edit those reports.

1. **FTL (08): supported with a source-scope caveat.** Subset Games' [official Steam description](https://store.steampowered.com/app/212680/FTL_Faster_Than_Light/) says a combat situation can be met by rerouting power to engines, powering weapons or boarding; it explicitly lists giving crew orders, distributing ship power, targeting weapons and pausing combat. This supports a bounded tactical choice and crew/system interaction. That copy alone does not establish the full crew-to-room job model; keep detailed room-duty claims grounded in gameplay-specific sources rather than treating those feature bullets as proof.
2. **Baba Is You (10): confirmed, but not ECS evidence.** Creator Arvi Teikari's [GDC slides](https://media.gdcvault.com/gdc2020/presentations/Reading%20the%20rules_Teikari_Arvi.pdf) describe the rule blocks, ask which objects have a rule, and state that the game was mostly implemented in Lua with tables important. The report correctly calls this query-shaped semantics, not an ECS implementation. The exact game-development tool claim should be attributed to the Steam page; the GDC material documents Lua/table use for the rule system, not necessarily the entire shipped game.
3. **RimWorld (03): confirmed, with the version/scope limit intact.** Ludeon's [Update 1.6 announcement](https://ludeon.com/blog/2025/06/announcing-odyssey-and-update-1-6/) calls out late-game colony performance and says pathfinding is now batched and multithreaded. This is a concrete solver-cost warning for the production game. It does not show that a small authored colony slice needs multithreaded pathfinding, and the report already preserves that distinction.

The earlier corridor wording question attached to 08 was resolved by the coordinator's note in [study 07](07-space-station.md#three-competitor-claims-checked-against-primary-sources); this review does not re-open it.

## Source boundaries

* Game-design facts for SoR: Matt Dabrowski / tinyBuild, [*Streets of Rogue* Steam page](https://store.steampowered.com/app/512900/Streets_of_Rogue/) and [official development announcement](https://steamcommunity.com/games/512900/announcements/detail/4354501493553620255).
* SS14 premise: Space Wizards, [About Space Station 14](https://spacestation14.com/about/about/). ECS design: [official ECS guide](https://docs.spacestation14.com/en/robust-toolbox/ecs.html). Code observations and pins: [study 07](07-space-station.md).
* Bendvy event/transaction constraints: [`typed-data-events.md`](../../../bendvy/docs/parity/typed-data-events.md) and [`SPEC.md`](../../../bendvy/docs/SPEC.md).
* This review proposes an ECS mapping; it makes no claim about SoR's internal architecture and reports no code, benchmark, or performance result.
