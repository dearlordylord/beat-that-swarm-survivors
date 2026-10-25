# Enemy authority and lifetime boundary

Enemy combat uses `enemy-combat.bend` values assembled from canonical Spatial,
Vitals, Status, Phase and read-only issued slot identity. Neither active nor
sleeping enemies read a Body or Motion. The storage adapter owns component
families; the system's plans and capability accessors remain beside the actual
callbacks in `game.bend`.

| Operation | Reads | Writes |
| --- | --- | --- |
| Movement | Phase, Status, immutable eligible player context | Spatial |
| Enemy combat and admitted birth | Spatial, Vitals, Status, Phase, issued Identity; immutable prepared contacts and player effects | Spatial, Vitals, Status, Phase |
| Occupied enemy loot turn | Enemy decision's advance flag; pickup-specific payload and immutable collector context | Pickup lifecycle owns payload, Spatial and Phase |
| Enemy targeting | Immutable EnemySnapshot projected to narrow Targets | No ECS components |
| Presentation and prediction | Immutable EnemySnapshot with named health/maximum | No ECS components |

`OccupiedByLoot{archetype}` retains the enemy slot's archetype for the eventual
return to dormancy. A killed outcome carries a typed DeathReward with amount,
placement, archetype, identity and killer. The pickup vertical consumes this
handoff. Enemy combat cannot mutate Pickup payloads or projectile trajectories;
identity is read-only. Paired compiler controls exercise these actual accessors.

Pool bootstrap passes the semantic slot directly to a deferred spawn command.
It initializes Role, issued Identity and Spatial, then only the appropriate
actor payloads. It creates no universal Body as an initialization intermediate.

The proved law concerns `EnemyLife.birth(candidate)`: it preserves the admitted
candidate and constructs age zero, clean Status, zero contact damage and no
killer. It proves neither admission policy nor the whole query pipeline.
`enemy-birth-check.mjs` separately exercises the actual production admission
continuation; the contact oracle exercises fresh and existing incarnations
against the same prepared contact. A compiled wiring mutant that reuses dirty
status and prior contact data must fail the production fixture.

Native consumers read typed observations directly. Browser encoders emit named
enemy fields and preserve source actor order explicitly; no enemy health word
is interpreted as damage or reward data. The development physical observer
records Phase and Identity columns and their real stamps, alongside typed
snapshot fields. It does not synthesize a unified Motion column.
