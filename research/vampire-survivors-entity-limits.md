# Vampire Survivors: entity-count limits

The local comparison below describes the example before the pool revision (commit `6c5acd9`). The current layout is in [pools.bend](../examples/survivors/pools.bend).

Checked: 2026-10-23. This concerns poncle's original game, not clones. Version context: the official October 16 announcement identifies **1.16.111** as stable and 1.17.108 as the PC public beta; the update for other platforms is still rolling out. The numbers below therefore cannot be called verified limits for all current platforms. [Official poncle announcements](https://steamcommunity.com/app/1794680/announcements/?l=english).

## What the sources support

| Category | Reported limit | Evidence status |
| --- | --- | --- |
| XP on the ground | After **more than 400** Experience Gems, new individual gems stop dropping; XP accumulates in one red gem. This compresses XP rather than losing it. The source wording does not establish an exact array size of 400. | **Secondary source:** [community wiki, Experience Gem](https://vampire.survivors.wiki/w/Experience_Gem). No numerical first-party confirmation was found in the public materials reviewed. |
| Ordinary enemies | At **300 or more living enemies**, periodic spawning stops; bosses and map-event enemies continue appearing. Thus 300 is a spawner threshold, not a proven hard limit on total entity count. | **Secondary source:** [community wiki, Enemies](https://vampire.survivors.wiki/w/Enemies). |
| Curse / Charm / Gold Finger | The Curse page separately reports an enemy-count limit of **500** regardless of Curse/Charm; Gold Finger temporarily sets the number of spawning enemies to 500. | **Secondary sources:** [Curse](https://vampire.survivors.wiki/w/Curse), [Gold Finger](https://vampire-survivors.fandom.com/wiki/Gold_Finger). The relationship between this 500, boss/event exceptions and an exact version is unproven; two wiki descriptions cannot be merged into one confirmed allocator cap. |
| Player projectiles | The wiki describes **Pool limit as a weapon property**: for example, Magic Wand — **60**, King Bible — **50**. This supports distinct weapon pools; no confirmed total limit for all player projectiles was found. | **Secondary sources:** [Weapons](https://vampire-survivors.fandom.com/wiki/Weapons), [Magic Wand](https://vampire-survivors.fandom.com/wiki/Magic_Wand), [King Bible](https://vampire-survivors.fandom.com/wiki/King_Bible). Pool sharing across weapon copies/players is not established here. |
| Hostile projectiles | No reliable overall numerical limit was found. | An open question, not “unlimited.” |
| Independent actors / companions | No single original category corresponding to custom `actors` was established. One specific first-party limit exists: patch 1.15 fixed Astarte's maximum of **10 followers**, previously incorrectly 4. | **Primary source:** [poncle, Update 1.15 — list of fixes, June 6](https://steamcommunity.com/app/1794680/announcements/?l=english). This is a limit for a specific character/DLC, not the whole world. |

## Stages and modes

Not every wave parameter is a storage limit. For example, Mad Forest has separate starting spawns, enemy minimum and spawn interval; Hyper changes the enemy-minimum multiplier from x1 to x1.25. The Bat Swarm event has a separate batch of 50 enemies. These are population/spawn parameters compatible with exceptions to the 300 rule, not evidence of another global capacity. [Community wiki, Mad Forest](https://vampire.survivors.wiki/w/Mad_Forest), [wave table](https://vampire-survivors.fandom.com/wiki/Mad_Forest).

## Comparison with the example

Authoritative application limits are defined in [pools.bend](../examples/survivors/pools.bend), weapon allocation in [projectile-pool.bend](../examples/survivors/projectile-pool.bend), and XP/spawn integration in [game.bend](../examples/survivors/game.bend). This report does not keep a duplicate of local capacities, ranges or algorithms.

Historical comparison conclusion: application limits must not be presented as Bendvy limits or confirmed parity with the original game. Such a comparison must distinguish weapon pools, spawner thresholds and total capacity.

Evidence conclusion: public first-party materials supplied current version context and a specific follower limit. The main 400/300/500 figures and weapon pools remain secondary wiki information without a pinned build. An exact parity contract requires a separate reproducible measurement of a selected legal build/platform; this document claims no such measurement.

## Implication for changes to the example

Capacity changes require checks of weapon behavior, XP conservation and dense scenes. Increasing storage alone does not establish preservation of these properties and is not a performance measurement. Revision results are recorded in the [pool report](shared-projectile-pool.md).
