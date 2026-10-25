# Survivors — requirements

A Vampire Survivors clone as a Bendvy ECS example. Published BendHub dependency setup is described in the [root README](../../README.md).

## Mandatory user requirement

The original content set must match the richness of the original Vampire Survivors. This requires variety in decisions, interactions, build development, enemies and replayability; the number of catalog entries alone does not satisfy it. The initial small content set is an intermediate stage, not a finished result. Exact copies of the original names, graphics and content are not required. Multiplayer is excluded. The user approved English for the game; the interface and catalog are implemented in English, while correspondence remains in Russian.

## Gameplay scope

The original catalog must support different strategies through weapons, evolutions, unions, passive upgrades and arcana. Characters must influence build choices, and stages must differ in wave schedules, hazards and objectives. Build development includes upgrade selection, rerolling, skipping and banishing; run modifiers and the challenge configuration must change the conditions of play. Primary sources and diversity criteria are in [REFERENCE_SCOPE.md](REFERENCE_SCOPE.md). The implemented catalog is in [menu-catalog.bend](menu-catalog.bend), and gameplay rules are in [game.bend](game.bend), [projectile.bend](projectile.bend) and [encounters.bend](encounters.bend).

Between runs: permanent upgrades, content unlocks, a collection and achievements. The complete loop is character and stage selection → combat → build development → defeat or victory → rewards → the next run.

Before completion, verify mechanical variety and a complete loop accessible to the user; the catalog alone does not establish parity with the original.

## Bend and ECS

Bend owns the state and executes authoritative rules for movement, combat, hits, loot, experience, upgrade selection, evolutions, enemy spawning and run completion. Following the user's clarification on 2026-10-22, the main version is implemented entirely in Bend: native window, rendering, input, audio, menus and a file-backed profile. The previous browser version is retained for comparison and testing. The launcher rebuilds local sources on startup on macOS Apple Silicon.

Use a real Bendvy world, typed components, system queries with declared access, linear state ownership and explicit structural boundaries. A large object with a type switch is not a sufficient ECS demonstration. Separate independent movement and combat state where this gives systems meaningful independent access. The example uses published BendHub modules without modifying or copying the ECS core.

## Completion checks

Check Bend→ESM compilation, catalog integrity and agreement between mechanics and descriptions, slot limits, leveling, evolutions, bosses, defeat and victory, a long run without identifier exhaustion, profile persistence and the browser interface. Validation includes a real browser and an independent comparison of the implementation against this specification and repository standards. Do not present unverified properties as proven.

## Native version and wave pressure

[pools.bend](pools.bend) defines capacities and identifier allocation; [projectile-pool.bend](projectile-pool.bend) defines shot allocation. Model capacity is not a performance promise.

XP tuning must produce meaningful build decisions. XP, reward and selection-queue rules belong to [game.bend](game.bend); loot presentation policy belongs to [loot-visual.bend](loot-visual.bend). Tuning goals and evaluation limits are in [BALANCE.md](BALANCE.md).

Opening waves must create noticeable pressure immediately; density, composition and danger increase throughout the run. Movement and build development must affect survival. After dawn in normal mode, a dangerous pursuer appears and ends the run through actual death; reaching dawn preserves completion credit. Endless mode excludes this pursuer.

Custom towers and rescuable wisps are excluded: they do not spawn, deal damage or award XP, gold or healing. Demonstrate ECS through gameplay entities and systems without adding these mechanics.

Deeper balance tuning must use reproducible scenarios, different builds and movement strategies, followed by a separate user assessment. Current tuning is not claimed to be numerically equivalent to Vampire Survivors.

Executed checks, observations and their limits are recorded in [VALIDATION.md](VALIDATION.md).

## Map and boundaries

World geometry and boundaries are defined in [arena.bend](arena.bend), and relic placement in [game.bend](game.bend). The pause map must help navigation and finding objectives while preserving the priority of an open reward choice. It is not an enemy radar.

Enemies must spawn offscreen, while movement and knockback must keep their complete visual footprint inside the world. Corners must still allow contact combat. Enlarging the world must not require traversing the entire map during rendering. Related properties and proof boundaries are described in [spawn-policy/README.md](spawn-policy/README.md).
