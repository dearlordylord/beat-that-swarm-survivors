import Base
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
type Token is Data: Token{}
type PickupToken is Data: PickupToken{}
type TrajectoryToken is Data: TrajectoryToken{}
type StatusToken is Data: StatusToken{}
type RoleToken is Data: RoleToken{}
type MovementRoster is Data:
  MovementPrepared{handles: List<&2,W.Handle<Schema>>}
type CandidateRoster is Data:
  CandidatesPrepared{projectiles: List<&2,W.Handle<Schema>>,pool: List<&2,W.Handle<Schema>>}
type BodyRest is Type: BodyRest{vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Components.Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>}
type VitalRest is Type: VitalRest{bodies: Col.Column<Schema,Components.Body>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Components.Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>}
type TrajectoryRest is Type: TrajectoryRest{bodies: Col.Column<Schema,Components.Body>,vitals: Col.Column<Schema,Components.Vitals>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Components.Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>}
type StatusRest is Type: StatusRest{bodies: Col.Column<Schema,Components.Body>,vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,pickups: Col.Column<Schema,Components.Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>}
type RoleRest is Type: RoleRest{bodies: Col.Column<Schema,Components.Body>,vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Components.Pickup>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>}
type Store is Type: Store{bodies: Col.Column<Schema,Components.Body>,vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Components.Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>}
def take(store: Store) -> BodyRest & Col.Column<Schema,Components.Body>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}: (BodyRest{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces},bodies)
def put(rest: BodyRest,bodies: Col.Column<Schema,Components.Body>) -> Store:
  match rest:
    case BodyRest{vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}
def project(value: Components.Body) -> Components.Body & Components.Body:
  match value:
    case Components.Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}: (Components.Body{x,y,kind,variant,hp,maxHp,age,seed,radius},Components.Body{x,y,kind,variant,hp,maxHp,age,seed,radius})
def family() -> C.Family<Schema,Store,BodyRest,Components.Body,Components.Body,Token,take,put,project>: C.Family{"body"}
def take_vitals(store: Store) -> VitalRest & Col.Column<Schema,Components.Vitals>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}: (VitalRest{bodies,motions,statuses,pickups,roles,movement,candidates,players,spaces},vitals)
def put_vitals(rest: VitalRest,vitals: Col.Column<Schema,Components.Vitals>) -> Store:
  match rest:
    case VitalRest{bodies,motions,statuses,pickups,roles,movement,candidates,players,spaces}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}
def project_vitals(value: Components.Vitals) -> Components.Vitals & Components.Vitals:
  match value:
    case Components.Vitals{+health,+maximum}: (Components.Vitals{health,maximum},Components.Vitals{health,maximum})
def vital_family() -> C.Family<Schema,Store,VitalRest,Components.Vitals,Components.Vitals,VitalToken,take_vitals,put_vitals,project_vitals>: C.Family{"vitals"}
def take_trajectory(store: Store) -> TrajectoryRest & Col.Column<Schema,Components.Trajectory>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}: (TrajectoryRest{bodies,vitals,statuses,pickups,roles,movement,candidates,players,spaces},motions)
def put_trajectory(rest: TrajectoryRest,motions: Col.Column<Schema,Components.Trajectory>) -> Store:
  match rest:
    case TrajectoryRest{bodies,vitals,statuses,pickups,roles,movement,candidates,players,spaces}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}
def project_trajectory(value: Components.Trajectory) -> Components.Trajectory & Components.Trajectory:
  match value:
    case Components.Trajectory{+vx,+vy,+life,+pierce,+visited,+ownerBase,+logicalSlot}: (Components.Trajectory{vx,vy,life,pierce,visited,ownerBase,logicalSlot},Components.Trajectory{vx,vy,life,pierce,visited,ownerBase,logicalSlot})
def trajectory_family() -> C.Family<Schema,Store,TrajectoryRest,Components.Trajectory,Components.Trajectory,TrajectoryToken,take_trajectory,put_trajectory,project_trajectory>: C.Family{"trajectory"}
def take_status(store: Store) -> StatusRest & Col.Column<Schema,Components.Status>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}: (StatusRest{bodies,vitals,motions,pickups,roles,movement,candidates,players,spaces},statuses)
def put_status(rest: StatusRest,statuses: Col.Column<Schema,Components.Status>) -> Store:
  match rest:
    case StatusRest{bodies,vitals,motions,pickups,roles,movement,candidates,players,spaces}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}
def project_status(value: Components.Status) -> Components.Status & Components.Status:
  match value:
    case Components.Status{+slow,+burn}: (Components.Status{slow,burn},Components.Status{slow,burn})
def status_family() -> C.Family<Schema,Store,StatusRest,Components.Status,Components.Status,StatusToken,take_status,put_status,project_status>: C.Family{"status"}
type PickupRest is Type: PickupRest{bodies: Col.Column<Schema,Components.Body>,vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>,spaces: Col.Column<Schema,Space.Spatial>}
def take_pickup(store: Store) -> PickupRest & Col.Column<Schema,Components.Pickup>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}: (PickupRest{bodies,vitals,motions,statuses,roles,movement,candidates,players,spaces},pickups)
def put_pickup(rest: PickupRest,pickups: Col.Column<Schema,Components.Pickup>) -> Store:
  match rest:
    case PickupRest{bodies,vitals,motions,statuses,roles,movement,candidates,players,spaces}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}
def project_pickup(value: Components.Pickup) -> Components.Pickup & Components.Pickup:
  match value:
    case Components.Pickup{+amount,+generation,+variant,+active}: (Components.Pickup{amount,generation,variant,active},Components.Pickup{amount,generation,variant,active})
def pickup_family() -> C.Family<Schema,Store,PickupRest,Components.Pickup,Components.Pickup,PickupToken,take_pickup,put_pickup,project_pickup>: C.Family{"pickup"}
def take_role(store: Store) -> RoleRest & Col.Column<Schema,Role.Role>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}: (RoleRest{bodies,vitals,motions,statuses,pickups,movement,candidates,players,spaces},roles)
def put_role(rest: RoleRest,roles: Col.Column<Schema,Role.Role>) -> Store:
  match rest:
    case RoleRest{bodies,vitals,motions,statuses,pickups,movement,candidates,players,spaces}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}
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
type SpatialRest is Type: SpatialRest{bodies: Col.Column<Schema,Components.Body>,vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Components.Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,Components.PlayerRecord>}
def take_spatial(store: Store) -> SpatialRest & Col.Column<Schema,Space.Spatial>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}: (SpatialRest{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players},spaces)
def put_spatial(rest: SpatialRest,spaces: Col.Column<Schema,Space.Spatial>) -> Store:
  match rest:
    case SpatialRest{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}
def project_spatial(value: Space.Spatial) -> Space.Spatial & Space.Spatial:
  match value:
    case Space.Spatial{+x,+y,+age,+radius}: (Space.Spatial{x,y,age,radius},Space.Spatial{x,y,age,radius})
def spatial_family() -> C.Family<Schema,Store,SpatialRest,Space.Spatial,Space.Spatial,SpatialToken,take_spatial,put_spatial,project_spatial>: C.Family{"enemy-spatial"}
def empty(unit: Unit) -> Store: Store{Col.empty_indexed(~Schema,~Components.Body),Col.empty_indexed(~Schema,~Components.Vitals),Col.empty_indexed(~Schema,~Components.Trajectory),Col.empty_indexed(~Schema,~Components.Status),Col.empty_indexed(~Schema,~Components.Pickup),Col.empty_indexed(~Schema,~Role.Role),MovementPrepared{[]},CandidatesPrepared{[],[]},Col.empty_indexed(~Schema,~Components.PlayerRecord),Col.empty_indexed(~Schema,~Space.Spatial)}
def World() -> Type: W.World<Schema,Store,Unit,Unit>
type PlayerToken is Data: PlayerToken{}
type PlayerRest is Type: PlayerRest{bodies: Col.Column<Schema,Components.Body>,vitals: Col.Column<Schema,Components.Vitals>,motions: Col.Column<Schema,Components.Trajectory>,statuses: Col.Column<Schema,Components.Status>,pickups: Col.Column<Schema,Components.Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,spaces: Col.Column<Schema,Space.Spatial>}
def take_players(store: Store) -> PlayerRest & Col.Column<Schema,Components.PlayerRecord>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}: (PlayerRest{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,spaces},players)
def put_players(rest: PlayerRest,players: Col.Column<Schema,Components.PlayerRecord>) -> Store:
  match rest:
    case PlayerRest{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,spaces}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players,spaces}
def project_player(value: Components.PlayerRecord) -> Components.PlayerRecord & Components.PlayerRecord:
  match value:
    case Components.PlayerRecord{+id,+player,+connected}: (Components.PlayerRecord{id,player,connected},Components.PlayerRecord{id,player,connected})
def player_family() -> C.Family<Schema,Store,PlayerRest,Components.PlayerRecord,Components.PlayerRecord,PlayerToken,take_players,put_players,project_player>: C.Family{"player"}
