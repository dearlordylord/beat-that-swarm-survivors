# Entity pools

`pools.bend` defines the application layout; these are not Bendvy limits.

| Pool | Slots | Use |
| --- | ---: | --- |
| Enemies and relic | 512 | 511 enemy identities and one stage relic |
| Player projectiles | 512 | Shared by equipped weapons |
| Hostile projectiles | 32 | Admission grows through the run |
| World actors | 12 | Eight wisps and four wards |
| Experience | 400 | Physical pickups with one overflow accumulator |

Ordinary wave admission grows to 300. Curse/run modifiers can raise it to 500.
Boss timing remains separate. Physical enemy capacity is distinct from wave
admission. These choices follow the reference investigation in
[the limits report](../../../research/vampire-survivors-entity-limits.md);
this is not an exact-version parity claim.

The projectile allocator counts live shots once, finds free physical identities,
then assigns firing requests under each weapon's budget. `Motion.ownerBase` and
`logicalSlot` preserve ownership and spread independently of the slot number.
Budgets range from 40 to 70; a ballistic weapon can retain several live volleys.
Persistent fields keep one live instance per logical position. Alive shots are
never overwritten. Saturated requests are dropped, with no deferred burst;
weapon priority rotates deterministically. Volley amount, spread and cooldown
rules remain unchanged.

XP routing preserves individual drop positions while there is space. At
saturation it selects one accumulator (preferring an existing marked one,
otherwise the farthest existing pile at the beginning of the tick). A newly
filled empty pool uses its first new pile. Overflow updates that pile once per
tick, preserving its seed, generation and position. Picking it up frees its
slot; later overflow selects another accumulator. No XP is credited without
physical pickup. Amounts use the existing U32 representation.

Blue/green/red tiers start at 1/5/10 XP; an overflow accumulator is always red.
Visual radius grows as `3 + sqrt(min(XP,100))/2`, capped at 8. Visual size does
not change pickup radius or contained XP. Both frontends use the Bend policy.

`LAWS.bend` / `PROOF.bend` check configuration and role partition. The pure
allocator has separate [laws and tests](../projectile-pool/README.md); the
[visual laws](../loot-visual/LAWS.bend) cover the size cap. Integration checks
exercise actual shot ownership/reclamation, physical pickup, XP conservation,
accumulator reuse, pool routing and modified enemy admission.
