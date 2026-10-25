import Base
import pickup-state.bend as Pickup
import enemy-combat.bend as Enemy
import game-components.bend as Components
import enemy-spatial.bend as Space
import entity-role.bend as Role
import bendvy-ecs-core@0.1.0.1/world.bend as W
import bendvy-ecs-core@0.1.0.1/column.bend as Col
import bendvy-ecs-core@0.1.0.1/component.bend as C

# Application-owned schema adapter: columns, family/rest wiring and ownership.
# Systems, query plans and access contracts remain beside behavior in game.
type Schema is Data: Schema{}
type VitalToken is Data: VitalToken{}
type PickupToken is Data: PickupToken{}
type TrajectoryToken is Data: TrajectoryToken{}
type StatusToken is Data: StatusToken{}
type RoleToken is Data: RoleToken{}
type MovementRoster is Data:
  MovementPrepared{handles: List<&2,W.Handle<Schema>>}
type CandidateRoster is Data:
  CandidatesPrepared{projectiles: List<&2,W.Handle<Schema>>,pool: List<&2,W.Handle<Schema>>}
type VitalRest is Type: VitalRest{motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Pickup.Payload>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>,enemyPhases: Col.Column<Schema,Enemy.Phase>,identities: Col.Column<Schema,Components.Identity>,shots: Col.Column<Schema,Components.ShotPayload>}
type TrajectoryRest is Type: TrajectoryRest{vitals: Col.Column<Schema,Components.Vitals>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Pickup.Payload>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>,enemyPhases: Col.Column<Schema,Enemy.Phase>,identities: Col.Column<Schema,Components.Identity>,shots: Col.Column<Schema,Components.ShotPayload>}
type StatusRest is Type: StatusRest{vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,pickups: Col.Column<Schema,Pickup.Payload>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>,enemyPhases: Col.Column<Schema,Enemy.Phase>,identities: Col.Column<Schema,Components.Identity>,shots: Col.Column<Schema,Components.ShotPayload>}
type RoleRest is Type: RoleRest{vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Pickup.Payload>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>,enemyPhases: Col.Column<Schema,Enemy.Phase>,identities: Col.Column<Schema,Components.Identity>,shots: Col.Column<Schema,Components.ShotPayload>}
type StoreFields is Type: StoreFields{vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Pickup.Payload>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>,enemyPhases: Col.Column<Schema,Enemy.Phase>,identities: Col.Column<Schema,Components.Identity>,shots: Col.Column<Schema,Components.ShotPayload>}
# The recursive carrier keeps handle validation independent of the storage layout.
# Access adapters open the actual owner and always return the canonical Owned form.
type Store is Type:
  Owned{state: StoreFields}
  Wrapped{inner: Store}
def unseal(store: Store) -> StoreFields:
  match store:
    case Owned{state}: state
    case Wrapped{inner}: unseal(inner)
def take_vitals_fields(store: StoreFields) -> VitalRest & Col.Column<Schema,Components.Vitals>:
  match store:
    case StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: (VitalRest{motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots},vitals)
def take_vitals(store: Store) -> VitalRest & Col.Column<Schema,Components.Vitals>: take_vitals_fields(unseal(store))
def put_vitals(rest: VitalRest,vitals: Col.Column<Schema,Components.Vitals>) -> Store:
  match rest:
    case VitalRest{motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: Owned{StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}}
def project_vitals(value: Components.Vitals) -> Components.Vitals & Components.Vitals:
  match value:
    case Components.Vitals{+health,+maximum}: (Components.Vitals{health,maximum},Components.Vitals{health,maximum})
def vital_family() -> C.Family<Schema,Store,VitalRest,Components.Vitals,Components.Vitals,VitalToken,take_vitals,put_vitals,project_vitals>: C.Family{"vitals"}
def take_trajectory_fields(store: StoreFields) -> TrajectoryRest & Col.Column<Schema,Components.Trajectory>:
  match store:
    case StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: (TrajectoryRest{vitals,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots},motions)
def take_trajectory(store: Store) -> TrajectoryRest & Col.Column<Schema,Components.Trajectory>: take_trajectory_fields(unseal(store))
def put_trajectory(rest: TrajectoryRest,motions: Col.Column<Schema,Components.Trajectory>) -> Store:
  match rest:
    case TrajectoryRest{vitals,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: Owned{StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}}
def project_trajectory(value: Components.Trajectory) -> Components.Trajectory & Components.Trajectory:
  match value:
    case Components.Trajectory{+vx,+vy,+life,+pierce,+visited,+ownerBase,+logicalSlot,+sourcePlayer}: (Components.Trajectory{vx,vy,life,pierce,visited,ownerBase,logicalSlot,sourcePlayer},Components.Trajectory{vx,vy,life,pierce,visited,ownerBase,logicalSlot,sourcePlayer})
def trajectory_family() -> C.Family<Schema,Store,TrajectoryRest,Components.Trajectory,Components.Trajectory,TrajectoryToken,take_trajectory,put_trajectory,project_trajectory>: C.Family{"trajectory"}
def take_status_fields(store: StoreFields) -> StatusRest & Col.Column<Schema,Components.Status>:
  match store:
    case StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: (StatusRest{vitals,motions,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots},statuses)
def take_status(store: Store) -> StatusRest & Col.Column<Schema,Components.Status>: take_status_fields(unseal(store))
def put_status(rest: StatusRest,statuses: Col.Column<Schema,Components.Status>) -> Store:
  match rest:
    case StatusRest{vitals,motions,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: Owned{StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}}
def project_status(value: Components.Status) -> Components.Status & Components.Status:
  match value:
    case Components.Status{+slow,+burn}: (Components.Status{slow,burn},Components.Status{slow,burn})
def status_family() -> C.Family<Schema,Store,StatusRest,Components.Status,Components.Status,StatusToken,take_status,put_status,project_status>: C.Family{"status"}
type PickupRest is Type: PickupRest{vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>,enemyPhases: Col.Column<Schema,Enemy.Phase>,identities: Col.Column<Schema,Components.Identity>,shots: Col.Column<Schema,Components.ShotPayload>}
def take_pickup_fields(store: StoreFields) -> PickupRest & Col.Column<Schema,Pickup.Payload>:
  match store:
    case StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: (PickupRest{vitals,motions,statuses,roles,movement,candidates,players,spaces,enemyPhases,identities,shots},pickups)
def take_pickup(store: Store) -> PickupRest & Col.Column<Schema,Pickup.Payload>: take_pickup_fields(unseal(store))
def put_pickup(rest: PickupRest,pickups: Col.Column<Schema,Pickup.Payload>) -> Store:
  match rest:
    case PickupRest{vitals,motions,statuses,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: Owned{StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}}
def project_pickup(value: Pickup.Payload) -> Pickup.Payload & Pickup.Payload:
  match value:
    case Pickup.Payload{+item,+generation,+active}: (Pickup.Payload{item,generation,active},Pickup.Payload{item,generation,active})
def pickup_family() -> C.Family<Schema,Store,PickupRest,Pickup.Payload,Pickup.Payload,PickupToken,take_pickup,put_pickup,project_pickup>: C.Family{"pickup"}
def take_role_fields(store: StoreFields) -> RoleRest & Col.Column<Schema,Role.Role>:
  match store:
    case StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: (RoleRest{vitals,motions,statuses,pickups,movement,candidates,players,spaces,enemyPhases,identities,shots},roles)
def take_role(store: Store) -> RoleRest & Col.Column<Schema,Role.Role>: take_role_fields(unseal(store))
def put_role(rest: RoleRest,roles: Col.Column<Schema,Role.Role>) -> Store:
  match rest:
    case RoleRest{vitals,motions,statuses,pickups,movement,candidates,players,spaces,enemyPhases,identities,shots}: Owned{StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}}
def project_role(value: Role.Role) -> Role.Role & Role.Role:
  match value:
    case Role.EnemySlot{}: (Role.EnemySlot{},Role.EnemySlot{})
    case Role.RelicSlot{}: (Role.RelicSlot{},Role.RelicSlot{})
    case Role.PlayerProjectileSlot{}: (Role.PlayerProjectileSlot{},Role.PlayerProjectileSlot{})
    case Role.HostileProjectileSlot{}: (Role.HostileProjectileSlot{},Role.HostileProjectileSlot{})
    case Role.XpSlot{}: (Role.XpSlot{},Role.XpSlot{})
    case Role.OutsideSlot{}: (Role.OutsideSlot{},Role.OutsideSlot{})
def role_family() -> C.Family<Schema,Store,RoleRest,Role.Role,Role.Role,RoleToken,take_role,put_role,project_role>: C.Family{"role"}
type SpatialToken is Data: SpatialToken{}
type SpatialRest is Type: SpatialRest{vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Pickup.Payload>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,enemyPhases: Col.Column<Schema,Enemy.Phase>,identities: Col.Column<Schema,Components.Identity>,shots: Col.Column<Schema,Components.ShotPayload>}
def take_spatial_fields(store: StoreFields) -> SpatialRest & Col.Column<Schema,Space.Spatial>:
  match store:
    case StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: (SpatialRest{vitals,motions,statuses,pickups,roles,movement,candidates,players,enemyPhases,identities,shots},spaces)
def take_spatial(store: Store) -> SpatialRest & Col.Column<Schema,Space.Spatial>: take_spatial_fields(unseal(store))
def put_spatial(rest: SpatialRest,spaces: Col.Column<Schema,Space.Spatial>) -> Store:
  match rest:
    case SpatialRest{vitals,motions,statuses,pickups,roles,movement,candidates,players,enemyPhases,identities,shots}: Owned{StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}}
def project_spatial(value: Space.Spatial) -> Space.Spatial & Space.Spatial:
  match value:
    case Space.Spatial{+x,+y,+age,+radius}: (Space.Spatial{x,y,age,radius},Space.Spatial{x,y,age,radius})
def spatial_family() -> C.Family<Schema,Store,SpatialRest,Space.Spatial,Space.Spatial,SpatialToken,take_spatial,put_spatial,project_spatial>: C.Family{"enemy-spatial"}
def empty(unit: Unit) -> Store: Owned{StoreFields{Col.empty_indexed(~Schema,~Components.Vitals),Col.empty_indexed(~Schema,~Components.Trajectory),Col.empty_indexed(~Schema,~Components.Status),Col.empty_indexed(~Schema,~Pickup.Payload),Col.empty_indexed(~Schema,~Role.Role),MovementPrepared{[]},CandidatesPrepared{[],[]},Col.empty_indexed(~Schema,~Components.PlayerRecord),Col.empty_indexed(~Schema,~Space.Spatial),Col.empty_indexed(~Schema,~Enemy.Phase),Col.empty_indexed(~Schema,~Components.Identity),Col.empty_indexed(~Schema,~Components.ShotPayload)}}
def World() -> Type: W.World<Schema,Store,Unit,Unit>
type PlayerToken is Data: PlayerToken{}
type PlayerRest is Type: PlayerRest{vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Pickup.Payload>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,spaces: Col.Column<Schema,Space.Spatial>,enemyPhases: Col.Column<Schema,Enemy.Phase>,identities: Col.Column<Schema,Components.Identity>,shots: Col.Column<Schema,Components.ShotPayload>}
def take_players_fields(store: StoreFields) -> PlayerRest & Col.Column<Schema,Components.PlayerRecord>:
  match store:
    case StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: (PlayerRest{vitals,motions,statuses,pickups,roles,movement,candidates,spaces,enemyPhases,identities,shots},players)
def take_players(store: Store) -> PlayerRest & Col.Column<Schema,Components.PlayerRecord>: take_players_fields(unseal(store))
def put_players(rest: PlayerRest,players: Col.Column<Schema,Components.PlayerRecord>) -> Store:
  match rest:
    case PlayerRest{vitals,motions,statuses,pickups,roles,movement,candidates,spaces,enemyPhases,identities,shots}: Owned{StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}}
def project_player(value: Components.PlayerRecord) -> Components.PlayerRecord & Components.PlayerRecord:
  match value:
    case Components.PlayerRecord{+id,+player,+connected}: (Components.PlayerRecord{id,player,connected},Components.PlayerRecord{id,player,connected})
def player_family() -> C.Family<Schema,Store,PlayerRest,Components.PlayerRecord,Components.PlayerRecord,PlayerToken,take_players,put_players,project_player>: C.Family{"player"}

type EnemyPhaseToken is Data: EnemyPhaseToken{}
type EnemyPhaseRest is Type: EnemyPhaseRest{vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Pickup.Payload>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>,identities: Col.Column<Schema,Components.Identity>,shots: Col.Column<Schema,Components.ShotPayload>}
def take_phase_fields(store: StoreFields) -> EnemyPhaseRest & Col.Column<Schema,Enemy.Phase>:
  match store:
    case StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: (EnemyPhaseRest{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,identities,shots},enemyPhases)
def take_phase(store: Store) -> EnemyPhaseRest & Col.Column<Schema,Enemy.Phase>: take_phase_fields(unseal(store))
def put_phase(rest: EnemyPhaseRest,enemyPhases: Col.Column<Schema,Enemy.Phase>) -> Store:
  match rest:
    case EnemyPhaseRest{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,identities,shots}: Owned{StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}}
def project_phase(value: Enemy.Phase) -> Enemy.Phase & Enemy.Phase:
  match value:
    case Enemy.Dormant{+archetype}: (Enemy.Dormant{archetype},Enemy.Dormant{archetype})
    case Enemy.ActiveEnemy{+archetype}: (Enemy.ActiveEnemy{archetype},Enemy.ActiveEnemy{archetype})
    case Enemy.OccupiedByLoot{+archetype}: (Enemy.OccupiedByLoot{archetype},Enemy.OccupiedByLoot{archetype})
def phase_family() -> C.Family<Schema,Store,EnemyPhaseRest,Enemy.Phase,Enemy.Phase,EnemyPhaseToken,take_phase,put_phase,project_phase>: C.Family{"enemy-phase"}

type IdentityToken is Data: IdentityToken{}
type IdentityRest is Type: IdentityRest{vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Pickup.Payload>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>,enemyPhases: Col.Column<Schema,Enemy.Phase>,shots: Col.Column<Schema,Components.ShotPayload>}
def take_identity_fields(store: StoreFields) -> IdentityRest & Col.Column<Schema,Components.Identity>:
  match store:
    case StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: (IdentityRest{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,shots},identities)
def take_identity(store: Store) -> IdentityRest & Col.Column<Schema,Components.Identity>: take_identity_fields(unseal(store))
def put_identity(rest: IdentityRest,identities: Col.Column<Schema,Components.Identity>) -> Store:
  match rest:
    case IdentityRest{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,shots}: Owned{StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}}
def project_identity(value: Components.Identity) -> Components.Identity & Components.Identity:
  match value:
    case Components.Identity{+slot}: (Components.Identity{slot},Components.Identity{slot})
def identity_family() -> C.Family<Schema,Store,IdentityRest,Components.Identity,Components.Identity,IdentityToken,take_identity,put_identity,project_identity>: C.Family{"enemy-identity"}

type ShotToken is Data: ShotToken{}
type ShotRest is Type: ShotRest{vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Pickup.Payload>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>,enemyPhases: Col.Column<Schema,Enemy.Phase>,identities: Col.Column<Schema,Components.Identity>}
def take_shot_fields(store: StoreFields) -> ShotRest & Col.Column<Schema,Components.ShotPayload>:
  match store:
    case StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}: (ShotRest{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities},shots)
def take_shot(store: Store) -> ShotRest & Col.Column<Schema,Components.ShotPayload>: take_shot_fields(unseal(store))
def put_shot(rest: ShotRest,shots: Col.Column<Schema,Components.ShotPayload>) -> Store:
  match rest:
    case ShotRest{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities}: Owned{StoreFields{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces,enemyPhases,identities,shots}}
def project_shot(value: Components.ShotPayload) -> Components.ShotPayload & Components.ShotPayload:
  match value:
    case Components.ShotPayload{+weapon,+damage,+active}: (Components.ShotPayload{weapon,damage,active},Components.ShotPayload{weapon,damage,active})
def shot_family() -> C.Family<Schema,Store,ShotRest,Components.ShotPayload,Components.ShotPayload,ShotToken,take_shot,put_shot,project_shot>: C.Family{"projectile-payload"}
