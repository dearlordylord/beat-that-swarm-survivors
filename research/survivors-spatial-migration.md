# Survivors spatial authority and movement slice

This is the issue 4 stage of the overloaded-state removal, not a claim that
all actor legacy has already been deleted. The preceding typed-result and
player/session authority changes are prerequisites. Their behavior remains
part of the frozen original-master qualification contract.

## Module ownership and dependency direction

- `enemy-spatial` owns pure `Spatial{x,y,age,radius}` and the enemy movement rule.
- `enemy-targets` owns immutable aiming targets (position/identity) and hostile
  firing sources (a target plus archetype/age). Aiming never receives health,
  damage or reward payloads; local aiming does not manufacture fake enemies.
- `game-components` owns pure payloads, including transitional actor payloads.
- `game-storage` imports pure component/role/spatial types and the published
  Bendvy package. It owns Schema, Store, columns, rest/token types, take/put,
  projection/family bindings and the affine World type.
- `game` imports those leaves and the storage adapter. Systems, their query
  plans and their capability accessors stay together beside behavior.
- Observation/encoding and native/browser/co-op consumers import the owners
  explicitly. There are no game-module aliases re-exporting moved types.

Pure movement types and rules import neither game, ECS, encoders nor hosts.
This extraction establishes the shared adapter boundary for subsequent actor
slices; final cleanup is not assigned a new wholesale storage rewrite.

## Authority and access

The `spaces` column has exactly the static EnemySlot/RelicSlot membership,
including dormant slots and non-XP loot occupying those slots. It is the only
source of their position, age and radius. Their stored transitional Body has
zero x/y/age/radius words. Projectile and persistent-XP slots do not acquire
this component during this slice.

| Operation | Reads | Writes |
| --- | --- | --- |
| Active enemy movement | Spatial; kind/variant metadata; Status.slow; nearest eligible player's step context | Spatial position and age; radius preserved |
| Frozen targeting/contact preparation | Incoming immutable spatial snapshot; variant/slow; target context; contact identity | Derived phase-only target paths |
| Unmigrated enemy combat | Current authoritative Spatial, Vitals and Status plus metadata | Vitals and Status; detached outcome for lifecycle |
| Enemy/relic lifecycle | Planned outcome and current spatial fallback, immutable issued identity | New Spatial and transitional metadata, with erased legacy geometry |

Movement cannot write Body, Vitals, Status, Pickup or identity. Its only writer
is Spatial. Age advances exactly once when an active enemy moves, even when
slow/freeze prevents displacement. Birth, despawn and loot transitions may
explicitly initialize/reset age as part of replacing an incarnation. Radius is
not modified by movement. Positive/negative controls exercise the actual
production accessors, not a parallel toy contract.

## Phase validity

Incoming State/Core snapshots describe the last completed simulation phase.
Contact preparation freezes before/after paths using the same pure spatial
step and player-selection rule used by movement. These target paths are valid
for the current tick only. Projectile processing then uses those frozen paths;
movement commits Spatial; combat applies effects afterwards; lifecycle commits
the outcome and publishes routing membership only on successful transaction.
A new successful outgoing snapshot replaces the prior phase view.

Args carries a named Targets phase value. Nearest-aim traversal reads only
Target records; hostile firing reads only Shooter records, retaining real
archetype/age admission. Both lists are projected once in source order. Local
projectile prediction creates aim-only targets directly. No health or XP word
enters those APIs.

The co-op prediction movement cache now contains Spatial values, rather than
complete enemy Body copies. It retains the same order and target identities.
Effects from the current contact pass do not retroactively alter its prepared
movement path. Reading current mutable ECS state in place of that immutable
phase input is not permitted by this contract.

## Deliberately temporary actor boundaries

Enemy combat still receives its existing detached aggregate at the explicit
`body_at_spatial` boundary in this intermediate stage. The aggregate is built
from authoritative spatial data; stored erased geometry is never consulted.
The enemy-combat ticket owns deleting this boundary and the remaining enemy
metadata reconstruction. Projectile and pickup tickets own their respective
unmigrated payloads. These are not supported compatibility APIs, new protocol
versions or additional authoritative copies.

Death-to-loot transitions keep spatial data in the enemy-slot component until
the loot lifecycle replaces it. Persistent-XP drops use the actual outcome
coordinates, not the erased stored metadata words. Relic slots retain the same
spatial membership even while dormant. This distinction prevents zeroed drop
positions or loss of a recycled slot's location.

## Replay evidence boundary

The native observer records the actual sparse spaces, including membership and
lifecycle stamps, and forces their values for the measured replay state. The
physical validator rejects missing/extra/out-of-order spatial rows, future or
invalid stamps, and any nonzero duplicate geometry in enemy Body storage.

Cross-schema qualification projects named spatial facts from this actual new
column, while ordinary same-schema replay still compares the entire original
payload, including all spatial words and stamps. The old logical shape is used
only inside the temporary development qualification adapter. Raw-source age
mutation must change the exported facts; damage/XP/generation/status controls
remain required. No new tolerance or recursive exclusion is introduced.

The affected optional native-pacing consumer also used removed controller APIs
on the incoming source. It now calls the existing avoidance policy and submits
its direction tuple through the public advance API; it remains an input-only
diagnostic and introduces no gameplay rule.

The compact qualification receipt records the commands and external artifacts.
Generated binaries, captures, compiler output and profiles remain outside source.
The finite scenarios and local age/radius laws are not a whole-game proof or a
performance acceptance claim; the bounded paired performance gate is issue 10.
