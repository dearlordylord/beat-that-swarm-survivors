# Networked projectiles and AoE: existing solutions

Separate Luna Max research using primary documentation and source code. It does not block the game fix. Each report distinguishes library behavior from conclusions for Bend/Iroh and states the search limits.

| Area | Report | What to look for |
| --- | --- | --- |
| Unity Netcode for Entities | [Unity](netcode-solutions-unity.md) | Ticked commands, partial rollback, GhostGroup, spawn matching, collision history |
| Unreal GAS | [Unreal](netcode-solutions-unreal-gas.md) | PredictionKey, server-side AoE, GameplayEffects/Cues, saved moves |
| Photon Fusion / FishNet | [Fusion and FishNet](netcode-solutions-fusion-fishnet.md) | Projectile presentation options, predicted spawning, lag compensation |
| Bevy / Lightyear / Avian | [Bevy](netcode-solutions-bevy-lightyear.md) | Input buffering, remote prediction, pre-spawn identity, physics and rollback |
| GGPO / GGRS | [Rollback](netcode-solutions-ggpo-ggrs.md) | Full save/load/advance, input delay, prediction window, replay-safe effects |
| Source / Valve | [Source](netcode-solutions-source-valve.md) | Hitscan rewind versus projectiles, radius damage, history boundaries |
| Open-source networked games | [SS14, Veloren, OpenRA](netcode-solutions-open-games.md) | Real projectile → contact → damage paths and resetting contacts during replay |
| Validation | [Tools and scenarios](netcode-solutions-testing.md) | Network simulators, SyncTest, temporal contracts, observation cost |
| AoE and spatial queries | [AoE queries](netcode-solutions-aoe-queries.md) | Box2D, Rapier, Unity: broad phase, exact resolver, recipient ordering |
| Clocks and buffers | [Time synchronization](netcode-solutions-clocks.md) | Tick lead, jitter buffers, smooth clock correction, pausing and overload |

This is a survey of mechanisms, not a proposal to port the example to another engine. An existing transport does not define the game's timing, damage or prediction rules.
