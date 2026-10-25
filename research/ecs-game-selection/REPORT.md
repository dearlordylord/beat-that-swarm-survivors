# Which game to clone to demonstrate Bendvy ECS

**Research completed.** 2026-10-21, 00:33:48–01:33:52 UTC: 1 hour 00 minutes 04 seconds before the final synthesis was recorded. Ten separate Luna/max researchers worked in two waves of five available worker slots, followed by cross-review and follow-up tasks for the same authors. All materials are in `bend-games`; Bendvy was inspected without modification.

## Recommendation — single-player only

**User clarification after the research: multiplayer is excluded.** This is a mandatory selection constraint. The previous SS14 recommendation is withdrawn; its sources remain an architectural reference. Early independent reports retain the original comparison conditions.

**My main choice is now Streets of Rogue.** One city block with an objective, guards, doors, terminals and items can preserve several ways to complete a mission: stealth, hacking, using items or combat. The original's single-player mode preserves this loop. [Developer description](https://store.steampowered.com/app/512900/Streets_of_Rogue/), [single-player systemic games research](14-singleplayer-immersive-sim.md), [matched gameplay interactions](28-mission-matched-interaction.md).

ECS is demonstrated through capabilities shared by characters, items and the environment: movement, health, ownership, statuses, locking, power, perception and event reactions. This is a proposed decomposition of mechanics for our clone; the original engine's architecture has not been established. Structs, enums and flags are acceptable: independent system responsibilities matter, not marker-component counts.

The closest alternatives:

- **RimWorld** — for autonomous simulation first: needs, work priorities, reservations, hauling, production and combat. It is a strong competitor in ECS breadth; a more complex scheduler does not make it worse by itself. Choose it if colony management is more interesting than direct character actions.
- **Cosmoteer** — to make composition visible through ship construction: modules, crew, supply, damage and changes in connectivity. Construction tools, geometry and navigation remain substantial separate work.
- **FTL** — for a more bounded tactical simulation of crew and subsystems. It needs a short run with decisions between encounters, not just one battle.
- **Baba Is You** — for a compact, direct demonstration of changing behavior through rules, with less breadth in relations and lifecycles.

Prioritizing SoR is an expert choice of a single-player format with broad interactions, not a proven absolute maximum. If “demonstrate ECS” primarily means regular bulk queries, swarm/shapez remain separate candidates. Speed and parallelism were not measured here. [Alternative interpretation](22-data-oriented-counterargument.md).

## Why the others do not become the overall winner

| Direction | What it demonstrates best | Constraint / reason for selection |
|---|---|---|
| **SS14** | Shared capabilities across object classes, tools/containers/states/hazards, roles and causal chains | Excluded as a cloning target: no multiplayer. Retained as an architectural reference |
| **Streets of Rogue** | Several ways to complete a mission through actors, items and the environment | Main choice under the single-player constraint; AI and interactions must retain independent system responsibilities |
| **RimWorld / Dwarf Fortress** | Needs, jobs, items, relations, production and combat | Job/reservation/path solvers can dominate the work, like station power/atmosphere solvers. Without a runtime audit, we cannot claim they are monolithic or integrate with ECS worse than SS14 |
| **Cosmoteer** | Objects assembled from modules, crew/supply, changing topology under destruction | Must preserve construction and its consequences; geometry, connectivity, physics and navigation are separate difficult tasks |
| **FTL** | Crew–room–system–ship relations, power, repairs, hazards and phase order | The clearest bounded ship option, but less dynamic composition across entity families; one battle is insufficient for a full run loop |
| **Baba Is You** | Rule changes literally enable/disable properties and participation in systems | Best compact demonstration of dynamic composition, but few natural relations and a narrow set of gameplay domains |
| **Magicka / Noita** | Shared effects and statuses across targets, spell composition | Magicka is strong for the combat core; Noita's material simulation is a separate grid problem, not evidence for ECS |
| **Brotato / Vampire Survivors** | Bulk lifecycles, weapons, effects, drops; Brotato also has waves/a shop | Already close to the existing arena. More enemies alone do not demonstrate deeper architecture |
| **Factorio / Mindustry / shapez** | Production, building components, network dependencies; shapez has direct filter-system source examples | Much complexity lies in transport lines, networks, grids and routing, for which ECS does not replace a specialized model |
| **RTS** | Ownership, orders, economy, production, combat | Navigation/avoidance and, at full scope, synchronization; a small squad battle loses distinctive RTS mechanics |
| **Tower defense** | Explicit phases, tower/enemy/projectile intersections, upgrades and statuses | Without deep shared capabilities it becomes an arena on a grid; weaker on its own than station/ship relations |
| **Opus Magnum / contraptions** | Machine phases, part relations, repeated execution | A machine interpreter, molecular geometry or physics becomes the main task |

This is a qualitative comparison, not measurements or a performance ranking. RimWorld and Cosmoteer are serious competitors in breadth; primary materials do not establish one winner by the proportion of logic expressed through independent queries. SS14's historical priority applied before multiplayer was excluded; the current gameplay choice is SoR. [Skeptical synthesis review](20-synthesis-skeptical-review.md). Rankings change with the goal: Baba leads in clarity of dynamic properties, FTL in bounded relational simulation, SS14 in breadth of intersecting mechanics. Do not replace the user's “maximum ECS” goal with minimum development time. [Criteria](00-evaluation-contract.md), [independent ranking](17-independent-ranking.md).

Marker-component counts do not determine quality either. Enums, bitflags, composite components and derived rule tables can all be valid ECS designs. A local `match` on a spell element is acceptable; a single handler owning all unrelated game responsibilities is suspect. Baba is therefore valuable for mutable semantics, not mandatory tag insertion/removal for every wall. [Granularity audit](23-component-granularity-audit.md), [data-oriented workload counterargument](22-data-oriented-counterargument.md).

Research literature confirms that modularity/composition and query/access/conflict shape are different properties. It does not provide a universal ranking of ECS games or establish SS14's leadership in data-oriented execution. One object participating in several systems does not necessarily create an access conflict: the specific reads and writes matter. [Calibration against two primary papers](27-ecs-literature-calibration.md).

If the goal is to show composition directly on the game screen, Baba and Cosmoteer have a distinct advantage: rules or modules are part of the player's visible choices. This is an inference from published mechanics, not a comparative user study. A broad station model does not guarantee that clarity by itself. [Player-visible composition review](29-player-visible-composition.md).

## First Streets of Rogue slice

One block, one objective and an exit. Keep two genuinely different paths to the objective: for example, hack access, or disable a guard with an item and obtain a pass. These specific mission rules are our design, not a reconstruction of an original level. Shared systems must handle movement, statuses, health, item carrying, door state, guard reactions and objective checks.

The first technical check remains “character → item → target”: it will expose cross-entity access ergonomics and commit boundaries in the current Bendvy. [Detailed mission model](28-mission-matched-interaction.md).

## Historical station example — reference, not an implementation plan

Gameplay reference: a short shift with several interacting roles, a compact map and a threat allowing different solutions. If starting with a solo probe, call it an engineering scenario inspired by SS14, not a faithful clone.

Three scenes should demonstrate composition:

1. An engineer takes a tool from a container and repairs an airlock. The same tool model works with another repairable machine. The target's access/state changes, while information readers independently receive the committed result.
2. An injured character is healed with an item that can be passed or picked up. Ownership, use, consumption/item state and health are linked by the gameplay action; do not encode everything as one medic-role special case.
3. A breach changes the environment and forces a choice: isolation and rescue, or evacuation. Power, door closure, equipment and crew state change the outcome. The objective must not become one mandatory click sequence.

These are proposed demonstrations, not an approved specification or already executed checks. Full atmosphere, networking and a content catalog do not become available merely because ECS exists. The first technical probe may use two zones with simple pressure and a small power model, but that is an explicit environmental simplification, not a reproduction of the original physics. [Detailed analysis](07-space-station.md), [manual traces](15-finalists-gameplay-traces.md).

## Limits of the current Bendvy specifically

A separate source audit found a difference between claimed ECS expressiveness and convenience on the main App path. A current-row writer operates on the selected entity. A relation view may return a target, but this is not yet a standard mutable join to the target's components. An actor→tool→door action and writes across multiple entity families require a plan, phases or a broader typed adapter. Independent source audits checked these boundaries; the ergonomics of a future gameplay consumer remain untested. This motivates a future technical probe, not a proven impossibility. [Access audit](12-cross-entity-access-audit.md).

Important correction from independent review: a current-row component and a shared resource can already be combined through the supported `recognized.pair(write, resource_write)` and registered through ordinary App. Thus “power resource + crew component” is not itself a gap. The main issue is a general relation-target join and writing several related entities. Built-in hierarchy descendant traversal is another specialized path that must not be ignored. [Independent API review](18-api-audit-review.md).

A later barrier also cannot be treated as part of an earlier commit: a resource already spent is not automatically restored when later command application fails. Buffered events do not replace SS14's synchronous cancelable attempts, and a World snapshot is not a complete checkpoint of queues and readers. Independent systems and explicit boundaries must preserve gameplay meaning rather than expose technical intermediate states to the player.

The browser arena and ordinary App provide different parts of future integration: the former already has input/clock/Canvas and passing a new State between steps; the latter has registered systems and retains App between runs. Combining them remains application work. A typed input carrier, render DTO and external-effect delivery rule accounting for the committed prefix on late schedule failure are needed. CLI execution does not imply a ready native UI. [Host-boundary audit](25-host-interface-audit.md).

The same cross-entity complexity matters for the selected SoR; SS14 research helps analyze it without restoring the station as a target. If the goal is minimal adapters and a complete consumer of the current ordinary App, Baba or Magicka is a more reasonable first choice. Those are two different projects; the research does not present one as the other.

## What was checked and what remains unknown

Primary mechanic descriptions, public developer materials and selected open-project sources were inspected; current Bendvy documents and public APIs were read without modification. The ten initial reports contain alternatives, counterarguments and rejection criteria; authors then reviewed each other's conclusions. Citation errors and unsupported details were corrected, and examples/manual traces are explicitly separated from observations. [Coordination log](11-coordination-log.md).

No games, prototypes, compiler, tests or benchmarks were run. Actual ergonomics of the chosen game, integration cost, performance and gameplay-slice quality therefore remain unknown. For most commercial games, the ECS model is a proposed decomposition of mechanics. Even inspected SS14 sources do not establish that porting to affine Bend will be convenient or fast.

Comparing similar station and colony actions showed comparable actor/input/target/environment/outcome composition. Station tool repair is supported by source and a test; tying repairs to the airtightness of a particular barrier remains a clone proposal. In the colony, material consumption applies to reconstruction/blueprints, not automatically to ordinary repairs. This comparison states that difference explicitly; it does not prove SS14's superiority. [Station analysis](24a-station-matched-interaction.md), [colony analysis](24b-colony-matched-interaction.md). The SoR mission comparison supports its value as a single-player format, but does not prove better ECS payoff: actor–item–target interactions and AI/perception remain substantial work. [Mission analysis](28-mission-matched-interaction.md).

The next substantive step after selection is one end-to-end gameplay consumer with a real multi-entity action and independent observation of its result. This report does not start that implementation, change the API, approve new laws or resume the deferred performance campaign.
