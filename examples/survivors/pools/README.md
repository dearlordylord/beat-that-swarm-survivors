# Entity pools

The authoritative allocation layout and admission limits are in
[`pools.bend`](../pools.bend). These are application choices, not Bendvy limits.
The reference investigation is in the [limits report](../../../research/vampire-survivors-entity-limits.md).

Implementation sources:

- [`projectile-pool.bend`](../projectile-pool.bend): shared projectile assignment.
- [`game.bend`](../game.bend): world integration, spawn admission and XP routing.
- [`persistent-xp.bend`](../persistent-xp.bend): persistent XP decisions.
- [`loot-visual.bend`](../loot-visual.bend): pickup appearance.

[`LAWS.bend`](LAWS.bend) declares configuration and role-partition properties;
[`PROOF.bend`](PROOF.bend) supplies their proofs. Projectile assignment has
[separate laws and checks](../projectile-pool/README.md), and pickup appearance
has [visual laws](../loot-visual/LAWS.bend). These properties do not establish
whole-game equivalence or runtime performance.
