import Base
import combat-policy.bend as Combat
import music.bend as Music
import arena.bend as A
import projectile.bend as P
import encounters.bend as E
import spawn-policy.bend as S
import spawn-lifecycle.bend as SL
import persistent-xp.bend as X
import body-index.bend as BI
import pools.bend as PL
import movement-membership.bend as MM
import entity-role.bend as Role
import projectile-pool.bend as SP
import loot-visual.bend as LV
import pickup-policy.bend as PickupPolicy
import bendvy-ecs-core@0.1.0.1/world.bend as W
import bendvy-ecs-core@0.1.0.1/column.bend as Col
import bendvy-ecs-core@0.1.0.1/component.bend as C
import bendvy-ecs-core@0.1.0.1/commands.bend as Cmd
import bendvy-ecs-core@0.1.0.1/transaction.bend as T
import bendvy-ecs-core@0.1.0.1/compose.bend as Q
import bendvy-ecs-core@0.1.0.1/capabilities.bend as Cap

type Schema is Data: Schema{}
# Frame kinds: enemy0, player shot1, XP2, gold3, heal4, chest5, hostile shot7.
# Dormant8 never renders. Health and XP payload fields are presentation views;
# Vitals and Pickup are their independent authoritative components.
type Body is Data: Body{x: F32,y: F32,kind: U32,variant: U32,hp: U32,maxHp: U32,age: U32,seed: U32,radius: F32}
type Vitals is Data: Vitals{health: U32,maximum: U32}
type VitalToken is Data: VitalToken{}
type Token is Data: Token{}
# Detached update payload shared by the live pure helpers and snapshots.
# Authoritative storage separates projectile trajectory from enemy status.
type Motion is Data: Motion{vx: F32,vy: F32,life: U32,pierce: U32,visited: List<&2,U32>,slow: U32,burn: U32,ownerBase: U32,logicalSlot: U32}
type Trajectory is Data: Trajectory{vx: F32,vy: F32,life: U32,pierce: U32,visited: List<&2,U32>,ownerBase: U32,logicalSlot: U32}
type Status is Data: Status{slow: U32,burn: U32}
type Pickup is Data: Pickup{amount: U32,generation: U32,variant: U32,active: Bool}
type PickupToken is Data: PickupToken{}
type TrajectoryToken is Data: TrajectoryToken{}
type StatusToken is Data: StatusToken{}
type RoleToken is Data: RoleToken{}
# Derived routing metadata contains only issued identities, never gameplay data.
type MovementRoster is Data:
  MovementPrepared{handles: List<&2,W.Handle<Schema>>}
type CandidateRoster is Data:
  CandidatesPrepared{projectiles: List<&2,W.Handle<Schema>>,pool: List<&2,W.Handle<Schema>>}
type BodyRest is Type: BodyRest{vitals: Col.Column<Schema,Vitals>,motions: Col.Column<Schema,Trajectory>,statuses: Col.Column<Schema,Status>,pickups: Col.Column<Schema,Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,PlayerRecord>}
type VitalRest is Type: VitalRest{bodies: Col.Column<Schema,Body>,motions: Col.Column<Schema,Trajectory>,statuses: Col.Column<Schema,Status>,pickups: Col.Column<Schema,Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,PlayerRecord>}
type TrajectoryRest is Type: TrajectoryRest{bodies: Col.Column<Schema,Body>,vitals: Col.Column<Schema,Vitals>,statuses: Col.Column<Schema,Status>,pickups: Col.Column<Schema,Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,PlayerRecord>}
type StatusRest is Type: StatusRest{bodies: Col.Column<Schema,Body>,vitals: Col.Column<Schema,Vitals>,motions: Col.Column<Schema,Trajectory>,pickups: Col.Column<Schema,Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,PlayerRecord>}
type RoleRest is Type: RoleRest{bodies: Col.Column<Schema,Body>,vitals: Col.Column<Schema,Vitals>,motions: Col.Column<Schema,Trajectory>,statuses: Col.Column<Schema,Status>,pickups: Col.Column<Schema,Pickup>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,PlayerRecord>}
type Store is Type: Store{bodies: Col.Column<Schema,Body>,vitals: Col.Column<Schema,Vitals>,motions: Col.Column<Schema,Trajectory>,statuses: Col.Column<Schema,Status>,pickups: Col.Column<Schema,Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,PlayerRecord>}
def take(store: Store) -> BodyRest & Col.Column<Schema,Body>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}: (BodyRest{vitals,motions,statuses,pickups,roles,movement,candidates,players},bodies)
def put(rest: BodyRest,bodies: Col.Column<Schema,Body>) -> Store:
  match rest:
    case BodyRest{vitals,motions,statuses,pickups,roles,movement,candidates,players}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}
def project(value: Body) -> Body & Body:
  match value:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}: (Body{x,y,kind,variant,hp,maxHp,age,seed,radius},Body{x,y,kind,variant,hp,maxHp,age,seed,radius})
def family() -> C.Family<Schema,Store,BodyRest,Body,Body,Token,take,put,project>: C.Family{"body"}
def take_vitals(store: Store) -> VitalRest & Col.Column<Schema,Vitals>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}: (VitalRest{bodies,motions,statuses,pickups,roles,movement,candidates,players},vitals)
def put_vitals(rest: VitalRest,vitals: Col.Column<Schema,Vitals>) -> Store:
  match rest:
    case VitalRest{bodies,motions,statuses,pickups,roles,movement,candidates,players}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}
def project_vitals(value: Vitals) -> Vitals & Vitals:
  match value:
    case Vitals{+health,+maximum}: (Vitals{health,maximum},Vitals{health,maximum})
def vital_family() -> C.Family<Schema,Store,VitalRest,Vitals,Vitals,VitalToken,take_vitals,put_vitals,project_vitals>: C.Family{"vitals"}
def take_trajectory(store: Store) -> TrajectoryRest & Col.Column<Schema,Trajectory>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}: (TrajectoryRest{bodies,vitals,statuses,pickups,roles,movement,candidates,players},motions)
def put_trajectory(rest: TrajectoryRest,motions: Col.Column<Schema,Trajectory>) -> Store:
  match rest:
    case TrajectoryRest{bodies,vitals,statuses,pickups,roles,movement,candidates,players}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}
def project_trajectory(value: Trajectory) -> Trajectory & Trajectory:
  match value:
    case Trajectory{+vx,+vy,+life,+pierce,+visited,+ownerBase,+logicalSlot}: (Trajectory{vx,vy,life,pierce,visited,ownerBase,logicalSlot},Trajectory{vx,vy,life,pierce,visited,ownerBase,logicalSlot})
def trajectory_family() -> C.Family<Schema,Store,TrajectoryRest,Trajectory,Trajectory,TrajectoryToken,take_trajectory,put_trajectory,project_trajectory>: C.Family{"trajectory"}
def take_status(store: Store) -> StatusRest & Col.Column<Schema,Status>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}: (StatusRest{bodies,vitals,motions,pickups,roles,movement,candidates,players},statuses)
def put_status(rest: StatusRest,statuses: Col.Column<Schema,Status>) -> Store:
  match rest:
    case StatusRest{bodies,vitals,motions,pickups,roles,movement,candidates,players}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}
def project_status(value: Status) -> Status & Status:
  match value:
    case Status{+slow,+burn}: (Status{slow,burn},Status{slow,burn})
def status_family() -> C.Family<Schema,Store,StatusRest,Status,Status,StatusToken,take_status,put_status,project_status>: C.Family{"status"}
type PickupRest is Type: PickupRest{bodies: Col.Column<Schema,Body>,vitals: Col.Column<Schema,Vitals>,motions: Col.Column<Schema,Trajectory>,statuses: Col.Column<Schema,Status>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster,players: Col.Column<Schema,PlayerRecord>}
def take_pickup(store: Store) -> PickupRest & Col.Column<Schema,Pickup>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}: (PickupRest{bodies,vitals,motions,statuses,roles,movement,candidates,players},pickups)
def put_pickup(rest: PickupRest,pickups: Col.Column<Schema,Pickup>) -> Store:
  match rest:
    case PickupRest{bodies,vitals,motions,statuses,roles,movement,candidates,players}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}
def project_pickup(value: Pickup) -> Pickup & Pickup:
  match value:
    case Pickup{+amount,+generation,+variant,+active}: (Pickup{amount,generation,variant,active},Pickup{amount,generation,variant,active})
def pickup_family() -> C.Family<Schema,Store,PickupRest,Pickup,Pickup,PickupToken,take_pickup,put_pickup,project_pickup>: C.Family{"pickup"}
def take_role(store: Store) -> RoleRest & Col.Column<Schema,Role.Role>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}: (RoleRest{bodies,vitals,motions,statuses,pickups,movement,candidates,players},roles)
def put_role(rest: RoleRest,roles: Col.Column<Schema,Role.Role>) -> Store:
  match rest:
    case RoleRest{bodies,vitals,motions,statuses,pickups,movement,candidates,players}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}
def project_role(value: Role.Role) -> Role.Role & Role.Role:
  match value:
    case Role.EnemySlot{}: (Role.EnemySlot{},Role.EnemySlot{})
    case Role.RelicSlot{}: (Role.RelicSlot{},Role.RelicSlot{})
    case Role.PlayerProjectileSlot{}: (Role.PlayerProjectileSlot{},Role.PlayerProjectileSlot{})
    case Role.HostileProjectileSlot{}: (Role.HostileProjectileSlot{},Role.HostileProjectileSlot{})
    case Role.XpSlot{}: (Role.XpSlot{},Role.XpSlot{})
    case Role.OutsideSlot{}: (Role.OutsideSlot{},Role.OutsideSlot{})
def role_family() -> C.Family<Schema,Store,RoleRest,Role.Role,Role.Role,RoleToken,take_role,put_role,project_role>: C.Family{"role"}
def empty_motion() -> Motion: Motion{0.0,0.0,0,0,[],0,0,0,0}
def empty_trajectory() -> Trajectory: Trajectory{0.0,0.0,0,0,[],0,0}
def empty_status() -> Status: Status{0,0}
def trajectory_of(motion: Motion) -> Trajectory:
  match motion:
    case Motion{vx,vy,life,pierce,visited,_,_,owner,slot}: Trajectory{vx,vy,life,pierce,visited,owner,slot}
def status_of(motion: Motion) -> Status:
  match motion:
    case Motion{_,_,_,_,_,slow,burn,_,_}: Status{slow,burn}
def logical_motion(trajectory: Trajectory,status: Status) -> Motion:
  match trajectory status:
    case Trajectory{vx,vy,life,pierce,visited,owner,slot} Status{slow,burn}: Motion{vx,vy,life,pierce,visited,slow,burn,owner,slot}
# Geometry/frame transport is reconstructed from Pickup before XP behavior.
# Stored Body copies never decide the amount, generation, marker or occupancy.
def pickup_from_body(body: Body) -> Pickup:
  match body:
    case Body{_,_,kind,variant,amount,generation,_,_,_}: Pickup{amount,generation,variant,U32.is_eq(kind,2)}
def pickup_body(body: Body,pickup: Pickup) -> Body:
  match body pickup:
    case Body{x,y,_,_,_,_,age,seed,radius} Pickup{amount,generation,variant,active}: Body{x,y,Bool.pick(U32,active,2,8),variant,amount,generation,age,seed,radius}
def empty(unit: Unit) -> Store: Store{Col.empty_indexed(~Schema,~Body),Col.empty_indexed(~Schema,~Vitals),Col.empty_indexed(~Schema,~Trajectory),Col.empty_indexed(~Schema,~Status),Col.empty_indexed(~Schema,~Pickup),Col.empty_indexed(~Schema,~Role.Role),MovementPrepared{[]},CandidatesPrepared{[],[]},Col.empty_indexed(~Schema,~PlayerRecord)}
def World() -> Type: W.World<Schema,Store,Unit,Unit>
def routing_world(result: World() & Unit) -> World():
  match result:
    case (world,_): world
# Setup writes components before prepare_movement_roster completes the world.
# Gameplay queries consume prepared handles; lifecycle refreshes active rows.
def populate_result(result: C.Replacement<World(),Body>) -> World():
  match result:
    case C.Replaced{world,_}: world
    case C.ReplaceRejected{world,_,_}: world
def populate_body(world: World(),handle: W.Handle<Schema>,body: Body) -> World():
  populate_result(C.structural_replace(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,family(),world,handle,Some{body}))
def vital_populated(result: C.Replacement<World(),Vitals>) -> World():
  match result:
    case C.Replaced{world,_}: world
    case C.ReplaceRejected{world,_,_}: world
def status_populated(result: C.Replacement<World(),Status>) -> World():
  match result:
    case C.Replaced{world,_}: world
    case C.ReplaceRejected{world,_,_}: world
def trajectory_populated(result: C.Replacement<World(),Trajectory>) -> World():
  match result:
    case C.Replaced{world,_}: world
    case C.ReplaceRejected{world,_,_}: world
def role_populated(result: C.Replacement<World(),Role.Role>) -> World():
  match result:
    case C.Replaced{world,_}: world
    case C.ReplaceRejected{world,_,_}: world
def populate_enemy(world: World(),+handle: W.Handle<Schema>,body: Body) -> World():
  match body:
    case Body{_,_,_,_,hp,maxHp,_,_,_}: status_populated(C.structural_replace(~Schema,~Store,~Unit,~Unit,~StatusRest,~Status,~Status,~StatusToken,~take_status,~put_status,~project_status,status_family(),vital_populated(C.structural_replace(~Schema,~Store,~Unit,~Unit,~VitalRest,~Vitals,~Vitals,~VitalToken,~take_vitals,~put_vitals,~project_vitals,vital_family(),world,handle,Some{Vitals{hp,maxHp}})),handle,Some{empty_status()}))
def populate_projectile(world: World(),handle: W.Handle<Schema>) -> World():
  trajectory_populated(C.structural_replace(~Schema,~Store,~Unit,~Unit,~TrajectoryRest,~Trajectory,~Trajectory,~TrajectoryToken,~take_trajectory,~put_trajectory,~project_trajectory,trajectory_family(),world,handle,Some{empty_trajectory()}))
def pickup_populated(result: C.Replacement<World(),Pickup>) -> World():
  match result:
    case C.Replaced{world,_}: world
    case C.ReplaceRejected{world,_,_}: world
def populate_pickup(world: World(),handle: W.Handle<Schema>,body: Body) -> World():
  pickup_populated(C.structural_replace(~Schema,~Store,~Unit,~Unit,~PickupRest,~Pickup,~Pickup,~PickupToken,~take_pickup,~put_pickup,~project_pickup,pickup_family(),world,handle,Some{pickup_from_body(body)}))
def populate_components(role: Role.Role,world: World(),handle: W.Handle<Schema>,body: Body) -> World():
  match role:
    case Role.EnemySlot{}: populate_enemy(world,handle,body)
    case Role.RelicSlot{}: populate_enemy(world,handle,body)
    case Role.PlayerProjectileSlot{}: populate_projectile(world,handle)
    case Role.HostileProjectileSlot{}: populate_projectile(world,handle)
    case Role.XpSlot{}: populate_pickup(world,handle,body)
    case _: world
def initial_role(body: Body) -> Role.Role:
  match body:
    case Body{_,_,_,_,_,_,_,seed,_}: Role.assigned(seed)
def populate_shared(world: World(),+handle: W.Handle<Schema>,+body: Body) -> World():
  populate_components(initial_role(body),role_populated(C.structural_replace(~Schema,~Store,~Unit,~Unit,~RoleRest,~Role.Role,~Role.Role,~RoleToken,~take_role,~put_role,~project_role,role_family(),populate_body(world,handle,body),handle,Some{initial_role(body)})),handle,body)
def populate_all(world: World(),handle: W.Handle<Schema>,body: Body) -> World(): populate_shared(world,handle,body)
def populate(world: World(),handle: W.Handle<Schema>,body: Body) -> World(): populate_all(world,handle,body)
def spawn_finish(result: T.Tx<World(),Unit> & W.Reservation<Schema>) -> World():
  match result:
    case (T.Tx{world,_,commands,_,_},W.Reserved{_}): Cmd.enqueue(~Schema,~Store,~Unit,~Unit,world,commands)
    case (T.Tx{world,_,_,_,_},W.ReservationRejected{_}): world
def spawn(world: World(),body: Body) -> World():
  spawn_finish(Cmd.tx_spawn(~Schema,~Store,~Unit,~Unit,~Body,~populate,T.begin(~World(),~Unit,world),body))
# Enemy slots recycle independently of the persistent XP pool.
# Detached kind2 Body transports baseXP/generation for frame and pure helpers;
# the live Pickup component supplies those values before behavior executes.
# Weapons and progression are immutable run data; entity updates use checked queries.
type Run is Data: Run{phase: U32,tick: U32,px: F32,py: F32,hp: U32,maxHp: U32,xp: U32,xpNeed: U32,level: U32,kills: U32,gold: U32,character: U32,weapons: List<&2,U32>,passives: List<&2,U32>,invuln: U32,seed: U32,stage: U32,arcana: U32,meta: U32,revivals: U32,bosses: U32,mode: U32,rerolls: U32,banishes: U32,skips: U32,bannedWeapons: U32,bannedPassives: U32,enemyKinds: List<&2,U32>,relicCollected: U32}
# Player records are authoritative ECS payloads, separate from pooled actors.
# Run is the detached compatibility view consumed by existing pure systems.
type PlayerRecord is Data: PlayerRecord{id: U32,run: Run,connected: Bool}
type PlayerToken is Data: PlayerToken{}
type PlayerRest is Type: PlayerRest{bodies: Col.Column<Schema,Body>,vitals: Col.Column<Schema,Vitals>,motions: Col.Column<Schema,Trajectory>,statuses: Col.Column<Schema,Status>,pickups: Col.Column<Schema,Pickup>,roles: Col.Column<Schema,Role.Role>,movement: MovementRoster,candidates: CandidateRoster}
def take_players(store: Store) -> PlayerRest & Col.Column<Schema,PlayerRecord>:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}: (PlayerRest{bodies,vitals,motions,statuses,pickups,roles,movement,candidates},players)
def put_players(rest: PlayerRest,players: Col.Column<Schema,PlayerRecord>) -> Store:
  match rest:
    case PlayerRest{bodies,vitals,motions,statuses,pickups,roles,movement,candidates}: Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players}
def project_player(value: PlayerRecord) -> PlayerRecord & PlayerRecord:
  match value:
    case PlayerRecord{+id,+run,+connected}: (PlayerRecord{id,run,connected},PlayerRecord{id,run,connected})
def player_family() -> C.Family<Schema,Store,PlayerRest,PlayerRecord,PlayerRecord,PlayerToken,take_players,put_players,project_player>: C.Family{"player"}
type Offer is Data: Offer{kind: U32,id: U32,level: U32}
type Snapshot is Data: Snapshot{body: Body,motion: Motion}
type State is Type: State{world: World(),run: Run,bodies: List<&2,Body>,offers: List<&2,Offer>,snapshots: List<&2,Snapshot>,pending: List<&2,U32>}
type Packet is Type: Packet{state: State,frame: String}
  Failed{error: String}
def at(values: List<&2,U32>,index: U32) -> U32:
  match values index:
    case Nil{} _: 0
    case Con{head,_} 0: head
    case Con{_,tail} index: at(tail,(index - 1 : U32))
def bump(values: List<&2,U32>,index: U32) -> List<&2,U32>:
  match values index:
    case Nil{} _: []
    case Con{head,tail} 0: (head + 1 : U32) <> tail
    case Con{head,tail} index: head <> bump(tail,(index - 1 : U32))
def set_at(values: List<&2,U32>,index: U32,+value: U32) -> List<&2,U32>:
  match values index:
    case Nil{} _: []
    case Con{_,rest} 0: value <> rest
    case Con{head,rest} index: head <> set_at(rest,(index - 1 : U32),value)
def dec(+value: U32) -> U32: U32.sub(value,U32.min(value,1))
def distance2(+x: F32,+y: F32,+px: F32,+py: F32) -> F32: ((x - px) * (x - px) + (y - py) * (y - py) : F32)
def close(x: F32,y: F32,px: F32,py: F32,+radius: F32) -> Bool: F32.is_le(distance2(x,y,px,py),(radius * radius : F32))
# Music observes the world at host audio cadence, never in the ECS tick.
def music_weight(+variant: U32) -> U32:
  (1 + 3 * Bool.to_u32(U32.is_le(20,variant)) + 32 * Bool.to_u32(U32.is_eq(variant,30)) + Bool.to_u32(Bool.or(U32.is_eq(variant,4),Bool.or(U32.is_eq(variant,12),U32.is_eq(variant,19)))) : U32)
def music_body_pressure(kind: U32,+variant: U32,+range: F32) -> U32:
  match kind:
    case 0: (music_weight(variant) * (3 * Bool.to_u32(F32.is_le(range,102400.0)) + 27 * Bool.to_u32(F32.is_le(range,10000.0))) : U32)
    case 7: ((1 + 7 * Bool.to_u32(U32.is_eq(variant,30))) * (35 * Bool.to_u32(F32.is_le(range,57600.0)) + 80 * Bool.to_u32(F32.is_le(range,6400.0))) : U32)
    case _: 0
def music_pressure(rows: List<&2,Body>,+px: F32,+py: F32) -> U32:
  match rows:
    case []: 0
    case Body{x,y,kind,variant,_,_,_,_,_} <> rest: U32.min(1000,(music_body_pressure(kind,variant,distance2(x,y,px,py)) + music_pressure(rest,px,py) : U32))
def music_danger(hp: U32,maxHp: U32,+px: F32,+py: F32,rows: List<&2,Body>) -> U32:
  Music.danger(hp,maxHp,music_pressure(rows,px,py))
# Early growth is quick; quadratic later costs prevent serial upgrade interruptions.
def next_xp_need(+level: U32) -> U32: (40 + level * 6 + level * level / 3 : U32)
def enemy_at(point: S.Point,+seed: U32,+tick: U32,+variant: U32,+stage: U32,+curse: U32) -> Body:
  match point:
    case S.Point{x,y}: Body{x,y,0,variant,(U32.max(E.health(variant,tick,stage),(10000000 * Bool.to_u32(U32.is_eq(variant,30)) : U32)) * (100 + curse) / 100 : U32),(U32.max(E.health(variant,tick,stage),(10000000 * Bool.to_u32(U32.is_eq(variant,30)) : U32)) * (100 + curse) / 100 : U32),0,seed,E.radius(variant)}
# Entity seeds remain stable pool identities; run entropy changes only spawn placement.
def enemy_new_seed(+slot: U32,+entropy: U32,+tick: U32,px: F32,py: F32,+variant: U32,stage: U32,curse: U32) -> Body:
  enemy_at(S.choose((slot + (entropy - 12345) * 31 : U32),tick,px,py,E.radius(variant)),slot,tick,variant,stage,curse)
# Ordinary waves use a 300 baseline; Curse may raise admission up to 500.
def active_limit(+tick: U32) -> U32: U32.min(PL.normal_enemy_cap(),(96 + tick / 50 : U32))
def initial_body(+slot: U32) -> Body: Body{0.0,0.0,8,slot,0,0,slot,slot,0.0}
def boot_pool(remaining: Nat,+slot: U32,world: World()) -> World():
  match remaining:
    case 0n: world
    case 1n+rest: boot_pool(rest,(slot + 1 : U32),spawn(world,initial_body(slot)))
# Bootstrap/setup snapshots use real allocator-visible handles and checked Role.
# Only allocation interprets numeric ranges; systems select immutable composition.
# Lifecycle later refreshes active membership during its existing traversal.
def movement_roster_store(handles: List<&2,W.Handle<Schema>>,store: Store) -> Store & Unit:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,_,candidates,players}: (Store{bodies,vitals,motions,statuses,pickups,roles,MovementPrepared{handles},candidates,players},Unit{})
def movement_roster_save(world: World(),handles: List<&2,W.Handle<Schema>>) -> World():
  routing_world(W.with_store(~Schema,~Store,~Unit,~Unit,~Unit,movement_roster_store(handles),world))
def movement_roster_keep(selected: Bool,handle: W.Handle<Schema>,reversed: List<&2,W.Handle<Schema>>) -> List<&2,W.Handle<Schema>>:
  match selected:
    case True{}: handle <> reversed
    case False{}: reversed
def role_active(role: Role.Role,body: Body) -> Bool:
  match body:
    case Body{_,_,kind,_,_,_,_,_,_}: MM.active_role(role,kind)
type RoutingCapture is Data: RoutingCapture{projectiles: List<&2,W.Handle<Schema>>,pool: List<&2,W.Handle<Schema>>,active: List<&2,W.Handle<Schema>>}
def routing_capture_store(capture: RoutingCapture,store: Store) -> Store & Unit:
  match capture store:
    case RoutingCapture{projectiles,pool,active} Store{bodies,vitals,motions,statuses,pickups,roles,_,_,players}: (Store{bodies,vitals,motions,statuses,pickups,roles,MovementPrepared{List.reverse(&2,W.Handle<Schema>,active)},CandidatesPrepared{List.reverse(&2,W.Handle<Schema>,projectiles),List.reverse(&2,W.Handle<Schema>,pool)},players},Unit{})
def routing_capture_keep(+role: Role.Role,+handle: W.Handle<Schema>,active: Bool,capture: RoutingCapture) -> RoutingCapture:
  match capture:
    case RoutingCapture{projectiles,pool,movement}: RoutingCapture{movement_roster_keep(Role.projectile(role),handle,projectiles),movement_roster_keep(Role.pool(role),handle,pool),movement_roster_keep(active,handle,movement)}
def routing_capture_body_active(role: Role.Role,result: C.Access<Body>) -> Bool:
  match result:
    case C.Found{body}: role_active(role,body)
    case _: False{}
def routing_capture_body(+role: Role.Role,handle: W.Handle<Schema>,capture: RoutingCapture,result: World() & C.Access<Body>) -> World() & RoutingCapture:
  match result:
    case (world,body): (world,routing_capture_keep(role,handle,routing_capture_body_active(role,body),capture))
def routing_capture_role(+handle: W.Handle<Schema>,capture: RoutingCapture,result: World() & C.Access<Role.Role>) -> World() & RoutingCapture:
  match result:
    case (world,C.Found{role}): routing_capture_body(role,handle,capture,C.get(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,family(),world,handle))
    case (world,_): (world,capture)
def routing_capture_collect(handles: List<&2,W.Handle<Schema>>,state: World() & RoutingCapture) -> World():
  match handles state:
    case [] Tuple{world,capture}: routing_world(W.with_store(~Schema,~Store,~Unit,~Unit,~Unit,routing_capture_store(capture),world))
    case Con{+handle,rest} Tuple{world,capture}: routing_capture_collect(rest,routing_capture_role(handle,capture,C.get(~Schema,~Store,~Unit,~Unit,~RoleRest,~Role.Role,~Role.Role,~RoleToken,~take_role,~put_role,~project_role,role_family(),world,handle)))
def routing_capture_visible(result: World() & List<&2,W.Handle<Schema>>) -> World():
  match result:
    case (world,handles): routing_capture_collect(handles,(world,RoutingCapture{[],[],[]}))
def prepare_movement_roster(world: World()) -> World():
  routing_capture_visible(W.handles(~Schema,~Store,~Unit,~Unit,world))
def body_json(body: Body) -> String:
  match body:
    case Body{x,y,kind,variant,hp,maxHp,age,seed,radius}: "[" ++ F32.show(x) ++ "," ++ F32.show(y) ++ "," ++ U32.show(kind) ++ "," ++ U32.show(variant) ++ "," ++ U32.show(hp) ++ "," ++ U32.show(maxHp) ++ "," ++ U32.show(age) ++ "," ++ U32.show(seed) ++ "," ++ F32.show(radius) ++ "]"
def rows_json(rows: List<&2,Body>) -> String:
  match rows:
    case []: ""
    case body <> []: body_json(body)
    case body <> rest: body_json(body) ++ "," ++ rows_json(rest)
def nums_json(rows: List<&2,U32>) -> String:
  match rows:
    case []: ""
    case n <> []: U32.show(n)
    case n <> rest: U32.show(n) ++ "," ++ nums_json(rest)
def offer_json(offer: Offer) -> String:
  match offer:
    case Offer{kind,id,level}: "{\"kind\":" ++ U32.show(kind) ++ ",\"id\":" ++ U32.show(id) ++ ",\"level\":" ++ U32.show(level) ++ "}"
def offers_json(rows: List<&2,Offer>) -> String:
  match rows:
    case []: ""
    case o <> []: offer_json(o)
    case o <> rest: offer_json(o) ++ "," ++ offers_json(rest)
def visible_bodies(rows: List<&2,Body>) -> List<&2,Body>:
  match rows:
    case []: []
    case Body{_,_,8,_,_,_,_,_,_} <> rest: visible_bodies(rest)
    case body <> rest: body <> visible_bodies(rest)
def world_size() -> F32: A.size()
def world_center() -> F32: A.center()
def world_margin() -> F32: A.player_min()
def relic_x(stage: U32) -> F32: U32.to_f32(at([10800,7200,3600,7200,10080],stage))
def relic_y(stage: U32) -> F32: U32.to_f32(at([7200,3600,7200,10800,9360],stage))
def run_length(mode: U32) -> U32:
  match mode:
    case 3: 18000
    case _: 36000
def wave_tick(+mode: U32,tick: U32) -> U32: (tick * (1 + Bool.to_u32(U32.is_eq(mode,3))) : U32)
def packet_extra(state: State,extra: String) -> Packet:
  match state:
    case State{world,Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,+pending}:
      Packet{State{world,Run{phase,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending},"{\"worldSize\":" ++ F32.show(A.size()) ++ ",\"worldMargin\":" ++ F32.show(A.player_min()) ++ ",\"relicCollected\":" ++ U32.show(relicCollected) ++ ",\"relicX\":" ++ F32.show(relic_x(stage)) ++ ",\"relicY\":" ++ F32.show(relic_y(stage)) ++ ",\"runLength\":" ++ U32.show(run_length(mode)) ++ ",\"enemiesKilled\":[" ++ nums_json(enemyKinds) ++ "],\"mode\":" ++ U32.show(mode) ++ ",\"rerolls\":" ++ U32.show(rerolls) ++ ",\"banishes\":" ++ U32.show(banishes) ++ ",\"skips\":" ++ U32.show(skips) ++ ",\"stage\":" ++ U32.show(stage) ++ ",\"arcana\":" ++ U32.show(arcana) ++ ",\"revivalsUsed\":" ++ U32.show(revivals) ++ ",\"bossesKilled\":" ++ U32.show(bosses) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"px\":" ++ F32.show(px) ++ ",\"py\":" ++ F32.show(py) ++ ",\"hp\":" ++ U32.show(hp) ++ ",\"maxHp\":" ++ U32.show(maxHp) ++ ",\"xp\":" ++ U32.show(xp) ++ ",\"xpNeed\":" ++ U32.show(need) ++ ",\"level\":" ++ U32.show(level) ++ ",\"kills\":" ++ U32.show(kills) ++ ",\"gold\":" ++ U32.show(gold) ++ ",\"character\":" ++ U32.show(character) ++ ",\"weapons\":[" ++ nums_json(weapons) ++ "],\"passives\":[" ++ nums_json(passives) ++ "],\"offers\":[" ++ offers_json(offers) ++ "],\"bodies\":[" ++ rows_json(visible_bodies(bodies)) ++ "]" ++ extra ++ "}"}
def packet(state: State) -> Packet: packet_extra(state,"")
def meta_max(id: U32) -> U32:
  match id:
    case 3: 3
    case 9: 2
    case _: 5
def meta_rank(+meta: U32,+id: U32) -> U32: U32.min(meta_max(id),(U32.shrn(meta,U32.to_nat((id * 3 : U32))) % 8 : U32))
def starter(character: U32) -> U32: at([0,1,4,8,2,10,15,21],(character % 8 : U32))
def character_health(character: U32) -> U32:
  match character:
    case 4: 125
    case _: 100
def initial_health(+character: U32,+meta: U32) -> U32: (character_health(character) * (100 + meta_rank(meta,1) * 10) / 100 : U32)
def stat_bonus(+arcana: U32,+wanted: U32) -> F32: U32.to_f32(Bool.to_u32(U32.is_eq(arcana,wanted)))
def speed_bonus(+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> F32:
  ((1.0 + U32.to_f32(at(passives,5)) * 0.10 + U32.to_f32(meta_rank(meta,5)) * 0.05 + 0.15 * U32.to_f32(Bool.to_u32(U32.is_eq(character,1))) + 0.30 * stat_bonus(arcana,10)) * (1.0 - 0.15 * stat_bonus(arcana,2)) : F32)
def configured(run: Run,+selectedStage: U32,+selectedArcana: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,_,_,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}:
      Run{phase,tick,px,py,F32.to_u32((U32.to_f32(initial_health(character,meta)) * (1.0 - 0.30 * stat_bonus(selectedArcana,0) + 0.25 * stat_bonus(selectedArcana,9)) : F32)),F32.to_u32((U32.to_f32(initial_health(character,meta)) * (1.0 - 0.30 * stat_bonus(selectedArcana,0) + 0.25 * stat_bonus(selectedArcana,9)) : F32)),xp,need,level,kills,gold,character,weapons,passives,invuln,seed,U32.min(selectedStage,4),U32.min(selectedArcana,11),meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def configure_with(~emit: State -> Packet,state: State,+stageChoice: U32,+arcanaChoice: U32) -> Packet:
  match state:
    case State{world,Run{+phase,0,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: emit(State{world,configured(Run{phase,0,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},stageChoice,arcanaChoice),bodies,offers,snapshots,pending})
    case state: emit(state)
def configure(state: State,stage: U32,arcana: U32) -> Packet: configure_with(~packet,state,stage,arcana)
def period(id: U32) -> U32:
  match id:
    case 0: 40
    case 1: 30
    case 2: 90
    case 3: 14
    case 4: 24
    case 5: 120
    case 6: 70
    case 7: 110
    case 8: 80
    case 9: 65
    case 10: 100
    case 11: 600
    case +id: (35 + (id % 6) * 13 : U32)
def lucky_kind(+seed: U32,+luck: U32) -> U32:
  (2 + Bool.to_u32(U32.is_eq((seed % U32.max(3,(1700 / (100 + luck * 10) : U32)) : U32),0)) + 2 * Bool.to_u32(Bool.and(Bool.not(U32.is_eq((seed % U32.max(3,(1700 / (100 + luck * 10) : U32)) : U32),0)),U32.is_eq((seed % U32.max(7,(4100 / (100 + luck * 10) : U32)) : U32),0))) : U32)
def normal_loot(+seed: U32) -> U32:
  (2 + Bool.to_u32(U32.is_eq((seed % 17 : U32),0)) + 2 * Bool.to_u32(Bool.and(Bool.not(U32.is_eq((seed % 17 : U32),0)),U32.is_eq((seed % 41 : U32),0))) : U32)
def loot_kind(+seed: U32,+variant: U32) -> U32:
  match variant:
    case 20: 5
    case 21: 5
    case 22: 5
    case 23: 5
    case 24: 5
    case 25: 5
    case 26: 5
    case 27: 5
    case 28: 5
    case 29: 5
    case _: normal_loot(seed)
type HitPlan is Data: HitPlan{shot: U32,weapon: U32,damage: U32,x: F32,y: F32,radius: F32,area: Bool,targets: List<&2,U32>}
type Args is Data: Args{run: Run,bodies: List<&2,Body>,dx: F32,dy: F32,snapshots: List<&2,Snapshot>,hits: List<&2,HitPlan>}
def empty_shot_plan() -> SP.Plan: SP.Plan{BI.Empty{},0}
type Row is Data: Row{body: Body,hit: U32,xp: U32,gold: U32,heal: U32,chest: U32,killed: U32,relic: U32}
type Error is Data: MissingBody{}
type Ops<-H: Type> is Type: Ops{body: Cap.Read<H,Body>,vitals: Cap.Write<H,Vitals,Vitals>,status: Cap.Write<H,Status,Status>}
def OpsType(H: Type) -> Type: Ops<H>
def body_cap(~H: Type,ops: Ops<H>) -> Cap.Read<H,Body>:
  match ops:
    case Ops{body,_,_}: body
def vital_cap(~H: Type,ops: Ops<H>) -> Cap.Write<H,Vitals,Vitals>:
  match ops:
    case Ops{_,vitals,_}: vitals
def status_cap(~H: Type,ops: Ops<H>) -> Cap.Write<H,Status,Status>:
  match ops:
    case Ops{_,_,status}: status
def loot_collected(found: Bool,+body: Body,+kind: U32,+amount: U32) -> Row:
  match found body:
    case False{} body: Row{body,0,0,0,0,0,0,0}
    case True{} Body{+x,+y,_,+variant,_,+maxHp,_,+seed,_}: Row{Body{x,y,8,variant,X.remaining(True{},amount),maxHp,0,seed,0.0},0,X.credited(U32.is_eq(kind,2),amount),(amount * Bool.to_u32(U32.is_eq(kind,3)) : U32),(25 * Bool.to_u32(U32.is_eq(kind,4)) : U32),Bool.to_u32(U32.is_eq(kind,5)),0,0}
def pickup_radius(+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> F32:
  (24.0 * (1.0 + U32.to_f32(at(passives,8)) * 0.25 + U32.to_f32(meta_rank(meta,6)) * 0.15 + stat_bonus(arcana,6) + 0.50 * U32.to_f32(Bool.to_u32(U32.is_eq(character,7)))) : F32)
# Age and item kind never authorize collection: only physical reach does.
def pickup_admission(x: F32,y: F32,px: F32,py: F32,radius: F32,age: U32,kind: U32) -> Bool:
  PickupPolicy.admission(x,y,px,py,radius,age,kind)
def loot_update(body: Body,run: Run) -> Row:
  match body run:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius} Run{_,_,+px,+py,_,_,_,_,_,_,_,+character,_,+passives,_,_,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}:
      loot_collected(pickup_admission(x,y,px,py,pickup_radius(passives,meta,arcana,character),age,kind),Body{x,y,kind,variant,hp,maxHp,(age + 1 : U32),seed,radius},kind,Bool.pick(U32,U32.is_eq(kind,2),hp,(2 + U32.min(4,(variant / 4 : U32)) : U32)))
def enemy_result_at(+hp: U32,+x: F32,+y: F32,+variant: U32,+maxHp: U32,+age: U32,+seed: U32,+radius: F32,+px: F32,+py: F32) -> Row:
  match hp:
    case 0: Row{Body{x,y,loot_kind(seed,variant),variant,0,maxHp,0,seed,6.0},0,0,0,0,0,1,0}
    case +hp: Row{Body{x,y,0,variant,hp,maxHp,age,seed,radius},(Bool.to_u32(close(x,y,px,py,(radius + 10.0 : F32))) * (1 + 1000 * Bool.to_u32(U32.is_eq(variant,30))) : U32),0,0,0,0,0,0}
def enemy_result(+hp: U32,x: F32,y: F32,+variant: U32,+maxHp: U32,+age: U32,+seed: U32,+radius: F32,+px: F32,+py: F32) -> Row:
  enemy_result_at(hp,A.constrain(x,radius),A.constrain(y,radius),variant,maxHp,age,seed,radius,px,py)
def enemy_update(body: Body,run: Run) -> Row:
  match body run:
    case Body{+x,+y,_,+variant,+hp,+maxHp,+age,+seed,+radius} Run{_,_,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,+enemyKinds,+relicCollected}: Row{Body{x,y,0,variant,hp,maxHp,age,seed,radius},(Bool.to_u32(close(x,y,px,py,(radius + 10.0 : F32))) * (1 + 1000 * Bool.to_u32(U32.is_eq(variant,30))) : U32),0,0,0,0,0,0}
def admit_enemy(admission: S.Admission,candidate: Body,previous: Body) -> Row:
  match admission:
    case S.Admit{}: Row{candidate,0,0,0,0,0,0,0}
    case S.Reject{}: Row{previous,0,0,0,0,0,0,0}
def candidate_enemy(candidate: Body,previous: Body,px: F32,py: F32) -> Row:
  match candidate:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}:
      admit_enemy(S.admission(x,y,px,py,radius),Body{x,y,kind,variant,hp,maxHp,age,seed,radius},previous)
def dormant_spawn(active: Bool,+seed: U32,+entropy: U32,+tick: U32,+px: F32,+py: F32,+variant: U32,+stage: U32,+curse: U32,+body: Body) -> Row:
  match active:
    case True{}: candidate_enemy(enemy_new_seed(seed,entropy,tick,px,py,variant,stage,curse),body,px,py)
    case False{}: Row{body,0,0,0,0,0,0,0}
# Spawn cadence rejects five of six slots before evaluating wave limits or
# passive ranks. Variant and curse are only materialized for admitted spawns.
def dormant_admitted(active: Bool,+seed: U32,+body: Body,run: Run) -> Row:
  match active run:
    case False{} _: Row{body,0,0,0,0,0,0,0}
    case True{} Run{_,+tick,+px,+py,_,_,_,_,_,_,_,+character,_,+passives,_,+rng,+stage,+arcana,_,_,_,+mode,_,_,_,_,_,_,_}:
      dormant_spawn(True{},seed,(rng - tick + 1 : U32),wave_tick(mode,tick),px,py,E.variant(stage,wave_tick(mode,tick),seed),stage,(at(passives,14) * 10 + 35 * Bool.to_u32(U32.is_eq(mode,1)) + 20 * Bool.to_u32(U32.is_eq(arcana,5)) + 15 * Bool.to_u32(U32.is_eq(character,6)) : U32),body)
def dormant_scheduled(scheduled: Bool,+seed: U32,+body: Body,+run: Run) -> Row:
  match scheduled run:
    case False{} _: Row{body,0,0,0,0,0,0,0}
    case True{} Run{_,+tick,_,_,_,_,_,_,_,_,_,_,_,+passives,_,_,_,+arcana,_,_,_,+mode,_,_,_,_,_,_,_}:
      dormant_admitted(U32.is_lt((seed % PL.player_start() : U32),U32.min(PL.max_regular_enemies(),(active_limit(wave_tick(mode,tick)) * (100 + at(passives,14) * 10 + 35 * Bool.to_u32(U32.is_eq(mode,1)) + 20 * Bool.to_u32(U32.is_eq(arcana,5))) / 100 : U32))),seed,body,run)
def dormant(body: Body,+run: Run) -> Row:
  match body run:
    case Body{+x,+y,_,+variant,_,+maxHp,+age,+seed,_} Run{_,+tick,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}:
      dormant_scheduled(U32.is_eq(((tick + seed) % 6 : U32),0),seed,Body{x,y,8,variant,0,maxHp,(age + 1 : U32),seed,0.0},run)
def update_body(body: Body,run: Run) -> Row:
  match body:
    case Body{+x,+y,0,+variant,+hp,+maxHp,+age,+seed,+radius}: enemy_update(Body{x,y,0,variant,hp,maxHp,age,seed,radius},run)
    case Body{+x,+y,8,+variant,+hp,+maxHp,+age,+seed,+radius}: dormant(Body{x,y,8,variant,hp,maxHp,age,seed,radius},run)
    case body: loot_update(body,run)
def boss_variant(finale: Bool,tick: U32,stage: U32) -> U32:
  match finale:
    case True{}: 30
    case False{}: (20 + stage * 2 + ((tick / 7200) % 2) : U32)
def update_selected(boss: Bool,finale: Bool,+body: Body,+run: Run,+seed: U32,+entropy: U32,+tick: U32,+px: F32,+py: F32,+stage: U32) -> Row:
  match boss:
    case True{}: candidate_enemy(enemy_new_seed(seed,entropy,tick,px,py,boss_variant(finale,tick,stage),stage,0),body,px,py)
    case False{}: update_body(body,run)
def update(body: Body,run: Run) -> Row:
  match body run:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius} Run{+phase,+tick,+px,+py,+playerHp,+playerMax,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+rng,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}:
      update_selected(Bool.and(U32.is_eq(seed,0),Bool.and(U32.is_lt(0,tick),Bool.or(Bool.and(Bool.or(U32.is_lt(wave_tick(mode,tick),36000),U32.is_eq(mode,2)),U32.is_eq((wave_tick(mode,tick) % 7200 : U32),0)),Bool.or(U32.is_eq(wave_tick(mode,tick),34200),U32.is_eq(wave_tick(mode,tick),36000))))),Bool.and(Bool.not(U32.is_eq(mode,2)),U32.is_eq(wave_tick(mode,tick),36000)),Body{x,y,kind,variant,hp,maxHp,age,seed,radius},Run{phase,tick,px,py,playerHp,playerMax,xp,need,level,kills,gold,character,weapons,passives,invuln,rng,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},seed,(rng - tick + 1 : U32),wave_tick(mode,tick),px,py,stage)
type EntityRow is Data: EntityRow{row: Row,motion: Motion}
# Spatial snapshots are only observations; Q capabilities own all three components.
type Aim is Data: Aim{x: F32,y: F32,id: U32,distance: F32}
def prefer_aim(closer: Bool,+x: F32,+y: F32,+id: U32,+distance: F32,rest: Aim) -> Aim:
  match closer:
    case True{}: Aim{x,y,id,distance}
    case False{}: rest
def aim_distance(aim: Aim) -> F32:
  match aim:
    case Aim{_,_,_,distance}: distance
def nearest(rows: List<&2,Body>,+x: F32,+y: F32,+best: Aim) -> Aim:
  match rows:
    case []: best
    case Body{+tx,+ty,0,_,_,_,_,+seed,_} <> rest: nearest(rest,x,y,prefer_aim(F32.is_lt(distance2(x,y,tx,ty),aim_distance(best)),tx,ty,seed,distance2(x,y,tx,ty),best))
    case _ <> rest: nearest(rest,x,y,best)
def contains(rows: List<&2,U32>,+id: U32) -> Bool:
  match rows:
    case []: False{}
    case head <> rest: Bool.or(U32.is_eq(head,id),contains(rest,id))
def add_contact(hit: Bool,seed: U32,rest: List<&2,U32>) -> List<&2,U32>:
  match hit:
    case True{}: seed <> rest
    case False{}: rest
def contacts(rows: List<&2,Body>,+x: F32,+y: F32,+radius: F32,+visited: List<&2,U32>) -> List<&2,U32>:
  match rows:
    case []: []
    case Body{+tx,+ty,0,_,_,_,_,+seed,+r} <> rest: add_contact(Bool.and(Bool.not(contains(visited,seed)),close(x,y,tx,ty,(radius + r : F32))),seed,contacts(rest,x,y,radius,visited))
    case _ <> rest: contacts(rest,x,y,radius,visited)
def planned_targets(unlimited: Bool,+pierce: U32,+bodies: List<&2,Body>,+x: F32,+y: F32,+radius: F32,+visited: List<&2,U32>) -> List<&2,U32>:
  match unlimited:
    case True{}: []
    case False{}: List.take(&2,U32,contacts(bodies,x,y,radius,visited),U32.to_nat(pierce))
def append_hit_plan(active: Bool,+seed: U32,+id: U32,+damage: U32,+x: F32,+y: F32,+radius: F32,+pierce: U32,+visited: List<&2,U32>,+bodies: List<&2,Body>,tail: List<&2,HitPlan>) -> List<&2,HitPlan>:
  match active:
    case False{}: tail
    case True{}: HitPlan{seed,id,damage,x,y,radius,U32.is_le(9999,pierce),planned_targets(U32.is_le(9999,pierce),pierce,bodies,x,y,radius,visited)} <> tail
def plan_hits(rows: List<&2,Snapshot>,+bodies: List<&2,Body>) -> List<&2,HitPlan>:
  match rows:
    case []: []
    case Snapshot{Body{+x,+y,1,+id,+damage,_,+age,+seed,+radius},Motion{_,_,+life,+pierce,+visited,_,_,_,_}} <> rest: append_hit_plan(Bool.and(P.active_hit(id,age),Bool.and(U32.is_lt(0,life),U32.is_lt(0,pierce))),seed,id,damage,x,y,radius,pierce,visited,bodies,plan_hits(rest,bodies))
    case _ <> rest: plan_hits(rest,bodies)
# Frozen targeting inputs contain enemies only. XP, shots and dormant
# bodies remain in the full frame/snapshots, without multiplying aim/contact work.
def enemy_geometry(rows: List<&2,Body>) -> List<&2,Body>:
  match rows:
    case []: []
    case Body{+x,+y,0,+variant,+hp,+maxHp,+age,+seed,+radius} <> rest: Body{x,y,0,variant,hp,maxHp,age,seed,radius} <> enemy_geometry(rest)
    case _ <> rest: enemy_geometry(rest)
def combat_args_enemies(run: Run,+enemies: List<&2,Body>,dx: F32,dy: F32,+snapshots: List<&2,Snapshot>) -> Args:
  Args{run,enemies,dx,dy,snapshots,plan_hits(snapshots,enemies)}
def combat_args(run: Run,bodies: List<&2,Body>,dx: F32,dy: F32,snapshots: List<&2,Snapshot>) -> Args:
  combat_args_enemies(run,enemy_geometry(bodies),dx,dy,snapshots)
def select_hit_targets(selected: Bool,targets: List<&2,U32>) -> List<&2,U32>:
  match selected:
    case True{}: targets
    case False{}: []
def hit_targets(rows: List<&2,HitPlan>,+seed: U32) -> List<&2,U32>:
  match rows:
    case []: []
    case HitPlan{+shot,_,_,_,_,_,_,+targets} <> rest: List.append(&2,U32,select_hit_targets(U32.is_eq(shot,seed),targets),hit_targets(rest,seed))
def cooldown_for(+id: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> U32:
  U32.max(6,F32.to_u32((U32.to_f32(period(id)) * F32.max(0.12,(1.0 - U32.to_f32(at(passives,1)) * 0.07 - U32.to_f32(meta_rank(meta,4)) * 0.03 - 0.20 * stat_bonus(arcana,1) - 0.10 * U32.to_f32(Bool.to_u32(U32.is_eq(character,5))) + 0.15 * stat_bonus(arcana,3) : F32)) : F32)))
def area_bonus(+passives: List<&2,U32>,+arcana: U32,+level: U32) -> F32:
  ((1.0 + U32.to_f32(at(passives,2)) * 0.10 + 0.35 * stat_bonus(arcana,2) + 0.15 * stat_bonus(arcana,11) + U32.to_f32(level) * 0.025) * (1.0 - 0.15 * stat_bonus(arcana,1)) * (1.0 + 0.35 * U32.to_f32(Bool.to_u32(U32.is_le(9,level)))) : F32)
def duration_bonus(+passives: List<&2,U32>,+arcana: U32) -> F32: (1.0 + U32.to_f32(at(passives,3)) * 0.15 + 0.50 * stat_bonus(arcana,7) : F32)
def projectile_speed(+passives: List<&2,U32>,+arcana: U32) -> F32: ((1.0 + U32.to_f32(at(passives,12)) * 0.15 + 0.50 * stat_bonus(arcana,8)) * (1.0 - 0.20 * stat_bonus(arcana,7)) : F32)
def weapon_damage(+id: U32,+level: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> U32:
  F32.to_u32((U32.to_f32((5 + level * 3 + id % 4 * 2 : U32)) * (1.0 + U32.to_f32(at(passives,0)) * 0.10 + U32.to_f32(meta_rank(meta,0)) * 0.05 + 0.35 * stat_bonus(arcana,0) + 0.15 * stat_bonus(arcana,8) + 0.10 * U32.to_f32(Bool.to_u32(U32.is_eq(character,0))) + 0.20 * U32.to_f32(Bool.to_u32(U32.is_eq(character,6)))) * (1.0 - 0.15 * stat_bonus(arcana,4)) * (1.0 + (0.20 + U32.to_f32(at(passives,14)) * 0.05) * U32.to_f32(Bool.to_u32(Bool.and(U32.is_eq(arcana,5),Bool.or(U32.is_eq(id,9),U32.is_eq(id,11)))))) * (1.0 + 1.2 * U32.to_f32(Bool.to_u32(U32.is_le(9,level)))) : F32))
def dormant_entity(+x: F32,+y: F32,+seed: U32) -> EntityRow: EntityRow{Row{Body{x,y,8,0,0,0,0,seed,0.0},0,0,0,0,0,0,0},empty_motion()}
def shot_created(+id: U32,+seed: U32,+damage: U32,shot: P.Shot) -> EntityRow:
  match shot:
    case P.Shot{+x,+y,+vx,+vy,+radius,+life,+pierce}: EntityRow{Row{Body{x,y,1,id,damage,damage,0,seed,radius},0,0,0,0,0,0,0},Motion{vx,vy,life,pierce,[],0,0,0,0}}
def direction_x(+dx: F32,+dy: F32) -> F32: ((dx + U32.to_f32(Bool.to_u32(F32.is_lt((dx * dx + dy * dy : F32),0.01)))) / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32)
def direction_y(+dx: F32,+dy: F32) -> F32: (dy / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32)
def union_base(+id: U32) -> U32: at([0,1,2,3,4,6],id)
def union_partner(+id: U32) -> U32: at([5,13,15,23,19,17],id)
def secondary_weapon(+id: U32) -> U32: at([5,13,15,23,19,0,17,20,9,23,5,17,4,8,17,2,6,14,9,4,3,5,20,5],id)
def choose_id(select: Bool,yes: U32,no: U32) -> U32:
  match select:
    case True{}: yes
    case False{}: no
def effective_weapon(+base: U32,+level: U32,+slot: U32) -> U32:
  choose_id(Bool.and(U32.is_le(10,level),U32.is_eq((slot % 3 : U32),2)),at([16,23,3,18,20,14],Combat.lose(level,10)),choose_id(Bool.and(U32.is_le(10,level),U32.is_eq((slot % 2 : U32),1)),union_partner(Combat.lose(level,10)),choose_id(Bool.and(U32.is_le(9,level),U32.is_eq((slot % 2 : U32),1)),secondary_weapon(base),choose_id(Bool.and(U32.is_eq(base,21),U32.is_eq((slot % 2 : U32),1)),0,base))))
def familiar_x(+id: U32,+owner: U32,+slot: U32,+px: F32,+tick: U32) -> F32:
  (px + E.choose_float(Bool.and(U32.is_eq(owner,21),Bool.not(U32.is_eq(id,21))),(F32.cos((U32.to_f32(tick) * 0.035 + U32.to_f32(slot) * 0.3926991 : F32)) * 80.0 : F32),0.0) : F32)
def familiar_y(+id: U32,+owner: U32,+slot: U32,+py: F32,+tick: U32) -> F32:
  (py + E.choose_float(Bool.and(U32.is_eq(owner,21),Bool.not(U32.is_eq(id,21))),(F32.sin((U32.to_f32(tick) * 0.035 + U32.to_f32(slot) * 0.3926991 : F32)) * 80.0 : F32),0.0) : F32)
def aim_direction_x(+dx: F32,+dy: F32,+px: F32,+py: F32,+tx: F32,+ty: F32) -> F32:
  E.choose_float(F32.is_lt((dx * dx + dy * dy : F32),0.01),P.aim_x(px,py,tx,ty),direction_x(dx,dy))
def aim_direction_y(+dx: F32,+dy: F32,+px: F32,+py: F32,+tx: F32,+ty: F32) -> F32:
  E.choose_float(F32.is_lt((dx * dx + dy * dy : F32),0.01),P.aim_y(px,py,tx,ty),direction_y(dx,dy))
def shot_spawn_aim(+owner: U32,fire: Bool,+seed: U32,+id: U32,+slot: U32,+level: U32,+run: Run,+dx: F32,+dy: F32,aim: Aim) -> EntityRow:
  match fire run aim:
    case False{} _ _: dormant_entity(0.0,0.0,seed)
    case True{} Run{_,+tick,+px,+py,_,_,_,_,_,_,_,+character,_,+passives,_,_,_,+arcana,+meta,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected} Aim{+tx,+ty,_,_}:
      shot_created(id,seed,weapon_damage(id,level,passives,meta,arcana,character),P.spawn(id,level,(slot * 2 : U32),familiar_x(id,owner,slot,px,tick),familiar_y(id,owner,slot,py,tick),tx,ty,aim_direction_x(dx,dy,px,py,tx,ty),aim_direction_y(dx,dy,px,py,tx,ty),projectile_speed(passives,arcana),area_bonus(passives,arcana,level),duration_bonus(passives,arcana)))
# Ballistic volleys rotate through the whole pool; long-lived fields keep their slots.
def rotates_pool(id: U32) -> Bool:
  match id:
    case 3: False{}
    case 4: False{}
    case 7: False{}
    case 9: False{}
    case 19: False{}
    case 20: False{}
    case 21: False{}
    case 22: False{}
    case _: True{}
def projectile_amount(+base: U32,+level: U32,+passives: List<&2,U32>,+arcana: U32) -> U32:
  U32.min(8,(1 + at(passives,4) + level / 3 + Bool.to_u32(U32.is_eq(arcana,3)) + Bool.to_u32(U32.is_eq(base,21)) : U32))
def volley_slot(+base: U32,+slot: U32,+amount: U32,+tick: U32,+cooldown: U32) -> Bool:
  U32.is_lt(choose_id(rotates_pool(base),((slot + 8 - (tick / cooldown * amount) % 8) % 8 : U32),slot),amount)
def scheduled_shot_owned(owned: Bool,+base: U32,+slot: U32,+level: U32,+passives: List<&2,U32>,+tick: U32,+meta: U32,+arcana: U32,+character: U32) -> Bool:
  match owned:
    case False{}: False{}
    case True{}: Bool.and(volley_slot(base,slot,projectile_amount(base,level,passives,arcana),tick,cooldown_for(base,passives,meta,arcana,character)),U32.is_eq((tick % cooldown_for(base,passives,meta,arcana,character) : U32),1))
def scheduled_shot(+base: U32,+slot: U32,+level: U32,+passives: List<&2,U32>,+tick: U32,+meta: U32,+arcana: U32,+character: U32) -> Bool:
  scheduled_shot_owned(U32.is_lt(0,level),base,slot,level,passives,tick,meta,arcana,character)
# Physical slots are independent of weapon ownership and logical spread slots.
type ShotInventory is Data: ShotInventory{occupied: BI.Index<Bool>,counts: List<&2,U32>,locks: List<&2,U32>}
def empty_owner_counts() -> List<&2,U32>: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
def inventory_add(alive: Bool,+seed: U32,+owner: U32,+slot: U32,inventory: ShotInventory) -> ShotInventory:
  match alive inventory:
    case False{} inventory: inventory
    case True{} ShotInventory{occupied,+counts,+locks}: ShotInventory{BI.insert(~Bool,occupied,seed,True{}),bump(counts,owner),set_at(locks,owner,U32.or(at(locks,owner),U32.shln(1,U32.to_nat(U32.min(7,slot)))))}
def shot_inventory(rows: List<&2,Snapshot>,inventory: ShotInventory) -> ShotInventory:
  match rows:
    case []: inventory
    case Snapshot{Body{_,_,1,_,_,_,_,+seed,_},Motion{_,_,+life,+pierce,_,_,_,+owner,+slot}} <> rest: shot_inventory(rest,inventory_add(Bool.and(PL.is_player_shot(seed),Bool.and(U32.is_lt(0,life),U32.is_lt(0,pierce))),seed,owner,slot,inventory))
    case _ <> rest: shot_inventory(rest,inventory)
def free_slot(available: Bool,seed: U32,rest: List<&2,U32>) -> List<&2,U32>:
  match available:
    case True{}: seed <> rest
    case False{}: rest
def free_shot_slots(fuel: Nat,+seed: U32,+occupied: BI.Index<Bool>) -> List<&2,U32>:
  match fuel:
    case 0n: []
    case 1n+rest: free_slot(Bool.not(BI.get(~Bool,occupied,seed,False{})),seed,free_shot_slots(rest,(seed + 1 : U32),occupied))
def request_if(fire: Bool,owner: U32,slot: U32,level: U32,tail: List<&2,SP.Request>) -> List<&2,SP.Request>:
  match fire:
    case False{}: tail
    case True{}: SP.Request{owner,slot,level} <> tail
def requested_slot(+owner: U32,+slot: U32,+level: U32,+passives: List<&2,U32>,+tick: U32,+meta: U32,+arcana: U32,+character: U32,+invuln: U32,+locks: U32,tail: List<&2,SP.Request>) -> List<&2,SP.Request>:
  request_if(Bool.and(Bool.or(rotates_pool(owner),U32.is_eq(U32.and(locks,U32.shln(1,U32.to_nat(slot))),0)),Bool.or(scheduled_shot(owner,slot,level,passives,tick,meta,arcana,character),Bool.and(U32.is_eq(arcana,4),Bool.and(U32.is_eq(owner,19),Bool.and(U32.is_eq(slot,0),Bool.and(U32.is_lt(30,invuln),U32.is_eq((tick % 12 : U32),0))))))),owner,slot,level,tail)
def request_slots(fuel: Nat,+owner: U32,+slot: U32,+run: Run,+locks: U32,tail: List<&2,SP.Request>) -> List<&2,SP.Request>:
  match fuel run:
    case 0n _: tail
    case 1n+rest Run{_,+tick,_,_,_,_,_,_,_,_,_,+character,+weapons,+passives,+invuln,_,_,+arcana,+meta,_,_,_,_,_,_,_,_,_,_}: requested_slot(owner,slot,at(weapons,owner),passives,tick,meta,arcana,character,invuln,locks,request_slots(rest,owner,(slot + 1 : U32),Run{0,tick,0.0,0.0,0,0,0,0,0,0,0,character,weapons,passives,invuln,0,0,arcana,meta,0,0,0,0,0,0,0,0,[],0},locks,tail))
def owner_requests_needed(needed: Bool,+owner: U32,run: Run,locks: List<&2,U32>,tail: List<&2,SP.Request>) -> List<&2,SP.Request>:
  match needed:
    case False{}: tail
    case True{}: request_slots(8n,owner,0,run,at(locks,owner),tail)
def owner_requests(+owner: U32,+run: Run,locks: List<&2,U32>,tail: List<&2,SP.Request>) -> List<&2,SP.Request>:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,weapons,_,_,_,_,arcana,_,_,_,_,_,_,_,_,_,_,_}: owner_requests_needed(Bool.or(U32.is_lt(0,at(weapons,owner)),Bool.and(U32.is_eq(arcana,4),U32.is_eq(owner,19))),owner,run,locks,tail)
def shot_requests(fuel: Nat,+owner: U32,+run: Run,+locks: List<&2,U32>) -> List<&2,SP.Request>:
  match fuel:
    case 0n: []
    case 1n+rest: owner_requests(owner,run,locks,shot_requests(rest,((owner + 1) % PL.owner_count() : U32),run,locks))
def shot_plan_inventory(+run: Run,inventory: ShotInventory) -> SP.Plan:
  match run inventory:
    case Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+kinds,+relic} ShotInventory{occupied,counts,locks}: SP.allocate(free_shot_slots(U32.to_nat(PL.player_count()),PL.player_start(),occupied),counts,PL.caps(),shot_requests(24n,(tick % PL.owner_count() : U32),Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,kinds,relic},locks))
def prepare_shot_plan(args: Args) -> SP.Plan:
  match args:
    case Args{run,_,_,_,snapshots,_}: shot_plan_inventory(run,shot_inventory(snapshots,ShotInventory{BI.Empty{},empty_owner_counts(),empty_owner_counts()}))
def with_shot_owner(row: EntityRow,+owner: U32,+slot: U32) -> EntityRow:
  match row:
    case EntityRow{row,Motion{vx,vy,life,pierce,visited,slow,burn,_,_}}: EntityRow{row,Motion{vx,vy,life,pierce,visited,slow,burn,owner,slot}}

# Resolve the complete firing predicate before preparing a projectile. Most
# unowned/unscheduled slots stay dormant and need neither aim nor materialization.
def shot_spawn_ready(fire: Bool,+seed: U32,+base: U32,+slot: U32,+level: U32,args: Args) -> EntityRow:
  match fire args:
    case False{} _: dormant_entity(0.0,0.0,seed)
    case True{} Args{Run{_,+tick,+px,+py,_,_,_,_,_,_,_,+character,+weapons,+passives,_,_,_,+arcana,+meta,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+dx,+dy,_,_}:
      shot_spawn_aim(base,True{},seed,effective_weapon(base,level,slot),slot,level,Run{0,tick,px,py,0,0,0,0,0,0,0,character,weapons,passives,0,0,0,arcana,meta,0,0,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},dx,dy,nearest(bodies,px,py,Aim{(px + 180.0 : F32),py,0,10000000.0}))
def shot_surviving(alive: Bool,+x: F32,+y: F32,+id: U32,+damage: U32,+age: U32,+seed: U32,+radius: F32,+vx: F32,+vy: F32,+life: U32,+pierce: U32,+visited: List<&2,U32>) -> EntityRow:
  match alive:
    case True{}: EntityRow{Row{Body{x,y,1,id,damage,damage,age,seed,radius},0,0,0,0,0,0,0},Motion{vx,vy,life,pierce,visited,0,0,0,0}}
    case False{}: dormant_entity(x,y,seed)
def shot_contacted(+id: U32,+age: U32,+seed: U32,+damage: U32,+visited: List<&2,U32>,+newHits: List<&2,U32>,shot: P.Shot) -> EntityRow:
  match shot:
    case P.Shot{+x,+y,+vx,+vy,+radius,+life,+pierce}:
      shot_surviving(Bool.and(U32.is_lt(0,life),U32.is_lt((U32.from_nat(List.length(&2,U32,newHits)) * Bool.to_u32(Bool.and(P.active_hit(id,age),U32.is_lt(pierce,9999))) : U32),pierce)),x,y,id,damage,(age + 1 : U32),seed,radius,vx,vy,life,Combat.lose(pierce,(U32.from_nat(List.length(&2,U32,newHits)) * Bool.to_u32(Bool.and(P.active_hit(id,age),U32.is_lt(pierce,9999))) : U32)),List.append(&2,U32,visited,newHits))
def shot_advanced(+id: U32,+age: U32,+seed: U32,+damage: U32,+oldX: F32,+oldY: F32,+oldRadius: F32,+bodies: List<&2,Body>,+visited: List<&2,U32>,+hits: List<&2,HitPlan>,shot: P.Shot) -> EntityRow:
  shot_contacted(id,age,seed,damage,visited,hit_targets(hits,seed),shot)
def ballistic(id: U32) -> Bool:
  match id:
    case 3: False{}
    case 4: False{}
    case 5: False{}
    case 7: False{}
    case 9: False{}
    case 11: False{}
    case 19: False{}
    case 20: False{}
    case 21: False{}
    case 22: False{}
    case _: True{}
def reflected(enabled: Bool,shot: P.Shot) -> P.Shot:
  match enabled shot:
    case False{} shot: shot
    case True{} P.Shot{+x,+y,+vx,+vy,+radius,+life,+pierce}: P.Shot{F32.clamp(x,20.0,(A.size() - 20.0 : F32)),F32.clamp(y,20.0,(A.size() - 20.0 : F32)),(vx * E.choose_float(Bool.or(F32.is_lt(x,20.0),F32.is_lt((A.size() - 20.0 : F32),x)),(0.0 - 1.0 : F32),1.0) : F32),(vy * E.choose_float(Bool.or(F32.is_lt(y,20.0),F32.is_lt((A.size() - 20.0 : F32),y)),(0.0 - 1.0 : F32),1.0) : F32),radius,life,pierce}
def shot_step_aim(body: Body,motion: Motion,args: Args,aim: Aim) -> EntityRow:
  match body motion args aim:
    case Body{+x,+y,_,+id,+damage,_,+age,+seed,+radius} Motion{+vx,+vy,+life,+pierce,+visited,_,_,_,_} Args{Run{_,+tick,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,+arcana,_,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,_,_,+snapshots,+hits} Aim{+tx,+ty,_,_}:
      shot_advanced(id,age,seed,damage,x,y,radius,bodies,visited,hits,reflected(Bool.and(U32.is_eq(arcana,8),ballistic(id)),P.step(id,(age + 1 : U32),P.Shot{x,y,vx,vy,radius,life,pierce},px,py,tx,ty)))
def nearest_from_args(args: Args,+x: F32,+y: F32) -> Aim:
  match args:
    case Args{_,bodies,_,_,+snapshots,+hits}: nearest(bodies,x,y,Aim{(x + 180.0 : F32),y,0,10000000.0})
type Collision is Data: Collision{damage: U32,slow: U32,burn: U32,pull: U32,knock: U32,pullX: F32,pullY: F32}
def slow_factor(+slow: U32) -> F32: E.choose_float(U32.is_le(65536,slow),0.0,E.choose_float(U32.is_lt(0,slow),0.35,1.0))
def cool_status(+slow: U32) -> U32: (dec((slow % 65536 : U32)) + 65536 * Bool.to_u32(Bool.and(U32.is_le(65536,slow),U32.is_lt(1,(slow % 65536 : U32)))) : U32)
def collision_add(hit: Bool,+id: U32,+damage: U32,+cx: F32,+cy: F32,tail: Collision) -> Collision:
  match hit tail:
    case False{} tail: tail
    case True{} Collision{+d,+s,+b,+p,+k,+sumX,+sumY}: Collision{(d + damage : U32),U32.max(s,(90 * Bool.to_u32(Bool.or(U32.is_eq(P.status(id),1),U32.is_eq(P.status(id),2))) + 65536 * Bool.to_u32(U32.is_eq(P.status(id),2)) : U32)),U32.max(b,(120 * Bool.to_u32(U32.is_eq(P.status(id),3)) : U32)),(p + Bool.to_u32(U32.is_eq(P.status(id),4)) : U32),(k + Bool.to_u32(U32.is_eq(P.status(id),5)) : U32),(sumX + cx * U32.to_f32(Bool.to_u32(U32.is_eq(P.status(id),4))) : F32),(sumY + cy * U32.to_f32(Bool.to_u32(U32.is_eq(P.status(id),4))) : F32)}
def hit_recipient(area: Bool,+targets: List<&2,U32>,+target: U32,+x: F32,+y: F32,+radius: F32,+tx: F32,+ty: F32,+r: F32) -> Bool:
  match area:
    case True{}: close(x,y,tx,ty,(radius + r : F32))
    case False{}: contains(targets,target)
def collisions(rows: List<&2,HitPlan>,+x: F32,+y: F32,+radius: F32,+target: U32) -> Collision:
  match rows:
    case []: Collision{0,0,0,0,0,0.0,0.0}
    case HitPlan{_,+id,+damage,+tx,+ty,+r,+area,+targets} <> rest: collision_add(hit_recipient(area,targets,target,x,y,radius,tx,ty,r),id,damage,tx,ty,collisions(rest,x,y,radius,target))
def lucky_row(row: Row,+luck: U32) -> Row:
  match row:
    case Row{Body{+x,+y,+kind,+variant,0,+maxHp,+age,+seed,+radius},+hit,+xp,+gold,+heal,+chest,1,+relic}: Row{Body{x,y,choose_id(U32.is_lt(variant,20),lucky_kind(seed,luck),kind),variant,0,maxHp,age,seed,radius},hit,xp,gold,heal,chest,1,0}
    case row: row
def pull_x(+x: F32,+y: F32,+sumX: F32,+sumY: F32,+count: U32) -> F32:
  ((sumX / U32.to_f32(U32.max(1,count)) - x) / F32.max(1.0,F32.sqrt(distance2(x,y,(sumX / U32.to_f32(U32.max(1,count)) : F32),(sumY / U32.to_f32(U32.max(1,count)) : F32)))) : F32)
def pull_y(+x: F32,+y: F32,+sumX: F32,+sumY: F32,+count: U32) -> F32:
  ((sumY / U32.to_f32(U32.max(1,count)) - y) / F32.max(1.0,F32.sqrt(distance2(x,y,(sumX / U32.to_f32(U32.max(1,count)) : F32),(sumY / U32.to_f32(U32.max(1,count)) : F32)))) : F32)
def enemy_applied_effects(+oldX: F32,+oldY: F32,row: Row,motion: Motion,collision: Collision,run: Run) -> EntityRow:
  match row motion collision run:
    case Row{Body{+x,+y,0,+variant,+hp,+maxHp,+age,+seed,+radius},_,_,_,_,_,_,+relic} Motion{_,_,_,_,_,+slow,+burn,_,_} Collision{+damage,+s,+b,+pull,+knock,+pullX,+pullY} Run{_,+tick,+px,+py,_,_,_,_,_,_,_,_,_,+passives,_,_,_,+arcana,_,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}:
      EntityRow{lucky_row(enemy_result(Combat.lose(hp,(damage + (2 + 2 * Bool.to_u32(U32.is_eq(arcana,7))) * Bool.to_u32(Bool.and(U32.is_lt(0,burn),U32.is_eq((tick % 30 : U32),0))) : U32)),(oldX + (x - oldX) * slow_factor(U32.max(slow,s)) + (oldX - px) / F32.max(1.0,F32.sqrt(distance2(oldX,oldY,px,py))) * U32.to_f32(knock) * (6.0 * (1.0 + U32.to_f32(at(passives,16)) * 0.15 + 0.75 * stat_bonus(arcana,11)) : F32) + pull_x(oldX,oldY,pullX,pullY,pull) * U32.to_f32(pull) * (3.0 + 4.0 * stat_bonus(arcana,11)) : F32),(oldY + (y - oldY) * slow_factor(U32.max(slow,s)) + (oldY - py) / F32.max(1.0,F32.sqrt(distance2(oldX,oldY,px,py))) * U32.to_f32(knock) * (6.0 * (1.0 + U32.to_f32(at(passives,16)) * 0.15 + 0.75 * stat_bonus(arcana,11)) : F32) + pull_y(oldX,oldY,pullX,pullY,pull) * U32.to_f32(pull) * (3.0 + 4.0 * stat_bonus(arcana,11)) : F32),variant,maxHp,age,seed,radius,px,py),at(passives,10)),Motion{0.0,0.0,0,0,[],U32.max(cool_status(slow),s),U32.max(dec(burn),(b * (1 + Bool.to_u32(U32.is_eq(arcana,7))) : U32)),0,0}}
    case row motion _ _: EntityRow{row,motion}
# Dawn's pursuer takes damage but cannot be frozen, slowed or displaced.
def immune_motion(immune: Bool,motion: Motion) -> Motion:
  match immune motion:
    case True{} Motion{vx,vy,life,pierce,visited,_,burn,_,_}: Motion{vx,vy,life,pierce,visited,0,burn,0,0}
    case False{} motion: motion
def immune_collision(immune: Bool,collision: Collision) -> Collision:
  match immune collision:
    case True{} Collision{damage,_,burn,_,_,_,_}: Collision{damage,0,burn,0,0,0.0,0.0}
    case False{} collision: collision
def enemy_applied(+oldX: F32,+oldY: F32,row: Row,motion: Motion,collision: Collision,run: Run) -> EntityRow:
  match row:
    case Row{Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius},hit,xp,gold,heal,chest,killed,relic}: enemy_applied_effects(oldX,oldY,Row{Body{x,y,kind,variant,hp,maxHp,age,seed,radius},hit,xp,gold,heal,chest,killed,relic},immune_motion(U32.is_eq(variant,30),motion),immune_collision(U32.is_eq(variant,30),collision),run)
def relic_result(collected: Bool,+stage: U32,+px: F32,+py: F32) -> EntityRow:
  match collected:
    case True{}: EntityRow{Row{Body{px,py,8,0,0,0,0,PL.relic_seed(),0.0},0,50,75,0,0,0,1},empty_motion()}
    case False{}: EntityRow{Row{Body{relic_x(stage),relic_y(stage),9,stage,0,0,0,PL.relic_seed(),18.0},0,0,0,0,0,0,0},empty_motion()}
def relic_run(run: Run) -> EntityRow:
  match run:
    case Run{_,_,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,+stage,_,_,_,_,_,_,_,_,_,_,_,0}: relic_result(close(px,py,relic_x(stage),relic_y(stage),30.0),stage,px,py)
    case _: dormant_entity(0.0,0.0,PL.relic_seed())
def relic_entity(args: Args) -> EntityRow:
  match args:
    case Args{run,_,_,_,_,_}: relic_run(run)
# A reused slot starts a new incarnation: old slows, burns and hits belong
# to the previous occupant and must never move or damage the admitted spawn.
def newborn_entity(result: Row & Motion) -> EntityRow:
  (row,motion) = result
  EntityRow{row,motion}
def xp_amount(body: Body) -> U32:
  match body:
    case Body{_,_,2,_,amount,_,_,_,_}: amount
    case _: 0
def xp_entity(body: Body,args: Args) -> EntityRow:
  match body args:
    case Body{+x,+y,2,+variant,+amount,+generation,+age,+seed,+radius} Args{run,_,_,_,_,_}: EntityRow{loot_update(Body{x,y,2,variant,amount,generation,age,seed,radius},run),empty_motion()}
    case Body{+x,+y,_,+variant,_,+generation,+age,+seed,_} _: dormant_entity(x,y,seed)
def intent_fire(intent: E.Intent) -> Bool:
  match intent:
    case E.Intent{_,_,fire}: fire
def nearest_shooter(rows: List<&2,Body>,+x: F32,+y: F32,+best: Aim) -> Aim:
  match rows:
    case []: best
    case Body{+tx,+ty,0,+variant,_,_,+age,+seed,_} <> rest: nearest_shooter(rest,x,y,prefer_aim(Bool.and(intent_fire(E.intent(variant,age,tx,ty,x,y)),F32.is_lt(distance2(x,y,tx,ty),aim_distance(best))),tx,ty,seed,distance2(x,y,tx,ty),best))
    case _ <> rest: nearest_shooter(rest,x,y,best)
def hostile_created(fire: Bool,+seed: U32,+px: F32,+py: F32,aim: Aim) -> EntityRow:
  match fire aim:
    case True{} Aim{+x,+y,_,_}: EntityRow{Row{Body{x,y,7,0,8,8,0,seed,6.0},0,0,0,0,0,0,0},Motion{((px - x) / F32.max(1.0,F32.sqrt(distance2(x,y,px,py))) * 3.5 : F32),((py - y) / F32.max(1.0,F32.sqrt(distance2(x,y,px,py))) * 3.5 : F32),240,1,[],0,0,0,0}}
    case False{} _: dormant_entity(0.0,0.0,seed)
def hostile_spawn(+seed: U32,args: Args) -> EntityRow:
  match args:
    case Args{Run{_,+tick,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,_,_,+snapshots,+hits}: hostile_created(Bool.and(U32.is_lt((seed - PL.hostile_start() : U32),U32.min(PL.hostile_count(),(2 + tick / 1800 : U32))),Bool.and(U32.is_eq((tick % 12 : U32),((seed - PL.hostile_start()) % 12 : U32)),F32.is_lt(aim_distance(nearest_shooter(bodies,px,py,Aim{0.0,0.0,0,10000000.0})),10000000.0))),seed,px,py,nearest_shooter(bodies,px,py,Aim{0.0,0.0,0,10000000.0}))
def hostile_advance(alive: Bool,+body: Body,+motion: Motion,+args: Args) -> EntityRow:
  match alive body motion args:
    case False{} Body{_,_,_,_,_,_,_,+seed,_} _ args: hostile_spawn(seed,args)
    case True{} Body{+x,+y,_,+variant,+damage,+maxHp,+age,+seed,+radius} Motion{+vx,+vy,+life,+pierce,+visited,+slow,+burn,_,_} Args{Run{_,+tick,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},_,_,_,+snapshots,+hits}: EntityRow{Row{Body{(x + vx : F32),(y + vy : F32),7,variant,damage,maxHp,(age + 1 : U32),seed,radius},(Bool.to_u32(close(x,y,px,py,(radius + 10.0 : F32))) * (1 + 1000 * Bool.to_u32(U32.is_eq(variant,30))) : U32),0,0,0,0,0,0},Motion{vx,vy,dec(life),pierce,visited,slow,burn,0,0}}
def hostile_step(body: Body,motion: Motion,args: Args) -> EntityRow:
  match motion:
    case Motion{+vx,+vy,+life,+pierce,+visited,+slow,+burn,_,_}: hostile_advance(U32.is_lt(0,life),body,Motion{vx,vy,life,pierce,visited,slow,burn,0,0},args)
# Each pass has an independently checked access contract. Read capabilities cannot write.
def missing_row() -> EntityRow: EntityRow{Row{Body{0.0,0.0,8,0,0,0,0,0,0.0},0,0,0,0,0,0,0},empty_motion()}
def Frame() -> Type: Q.Frame<Schema,Store,Unit,Unit>
def selected_role(mode: U32,role: Role.Role) -> Bool:
  match mode:
    case 0: Role.projectile(role)
    case 1: Role.enemy(role)
    case 2: Role.pool(role)
    case _: False{}
def selected_role_observed(mode: U32,result: Frame() & C.Access<Role.Role>) -> Frame() & Bool:
  match result:
    case (frame,C.Found{role}): (frame,selected_role(mode,role))
    case (frame,_): (frame,False{})
def selected_enemy_body(result: Frame() & C.Access<Body>) -> Frame() & Bool:
  match result:
    case (frame,C.Found{Body{_,_,kind,_,_,_,_,_,_}}): (frame,U32.is_eq(kind,0))
    case (frame,_): (frame,False{})
def selected_enemy_admitted(result: Frame() & Bool) -> Frame() & Bool:
  match result:
    case (frame,True{}): selected_enemy_body(Q.get(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family(),frame))
    case (frame,False{}): (frame,False{})
def selected_projectile(frame: Frame()) -> Frame() & Bool: selected_role_observed(0,Q.get(~Schema,~Store,~Unit,~Unit,~RoleRest,~Role.Role,~Role.Role,~RoleToken,~take_role,~put_role,~project_role,~role_family(),frame))
def selected_enemy(frame: Frame()) -> Frame() & Bool: selected_enemy_admitted(selected_role_observed(1,Q.get(~Schema,~Store,~Unit,~Unit,~RoleRest,~Role.Role,~Role.Role,~RoleToken,~take_role,~put_role,~project_role,~role_family(),frame)))
def selected_pool(frame: Frame()) -> Frame() & Bool: selected_role_observed(2,Q.get(~Schema,~Store,~Unit,~Unit,~RoleRest,~Role.Role,~Role.Role,~RoleToken,~take_role,~put_role,~project_role,~role_family(),frame))

# Projectile updates own geometry and trajectory, with no health/status grant.
type ProjectileOps<-H: Type> is Type: ProjectileOps{body: Cap.Write<H,Body,Body>,trajectory: Cap.Write<H,Trajectory,Trajectory>,role: Cap.Read<H,Role.Role>}
def ProjectileOpsType(H: Type) -> Type: ProjectileOps<H>
def projectile_body_cap(~H: Type,ops: ProjectileOps<H>) -> Cap.Write<H,Body,Body>:
  match ops:
    case ProjectileOps{body,_,_}: body
def projectile_trajectory_cap(~H: Type,ops: ProjectileOps<H>) -> Cap.Write<H,Trajectory,Trajectory>:
  match ops:
    case ProjectileOps{_,trajectory,_}: trajectory
def projectile_role_cap(~H: Type,ops: ProjectileOps<H>) -> Cap.Read<H,Role.Role>:
  match ops:
    case ProjectileOps{_,_,role}: role
def projectile_write(~H: Type,~ops: ProjectileOps<H>,ctx: H,row: EntityRow) -> H & (T.Outcome<Error> & EntityRow):
  match row:
    case EntityRow{Row{+body,+hit,+xp,+gold,+heal,+chest,+killed,+relic},+motion}: (Cap.set(~H,~Trajectory,~Trajectory,~projectile_trajectory_cap(~H,ops),Cap.set(~H,~Body,~Body,~projectile_body_cap(~H,ops),ctx,body),trajectory_of(motion)),(T.Success{},EntityRow{Row{body,hit,xp,gold,heal,chest,killed,0},motion}))
def projectile_plan() -> Q.Plan<Schema,Store,Unit,Unit,ProjectileOpsType>: Q.Plan{ProjectileOps{Q.write_family(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family()),Q.write_family(~Schema,~Store,~Unit,~Unit,~TrajectoryRest,~Trajectory,~Trajectory,~TrajectoryToken,~take_trajectory,~put_trajectory,~project_trajectory,~trajectory_family()),Q.read_family(~Schema,~Store,~Unit,~Unit,~RoleRest,~Role.Role,~Role.Role,~RoleToken,~take_role,~put_role,~project_role,~role_family())},selected_projectile}

# Movement reads status and writes geometry. It has no health writer or status writer.
type MoveOps<-H: Type> is Type: MoveOps{body: Cap.Write<H,Body,Body>,status: Cap.Read<H,Status>}
def MoveOpsType(H: Type) -> Type: MoveOps<H>
def move_body_cap(~H: Type,ops: MoveOps<H>) -> Cap.Write<H,Body,Body>:
  match ops:
    case MoveOps{body,_}: body
def move_status_cap(~H: Type,ops: MoveOps<H>) -> Cap.Read<H,Status>:
  match ops:
    case MoveOps{_,status}: status
def moved_intent(body: Body,intent: E.Intent,+factor: F32) -> Body:
  match body intent:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius} E.Intent{+vx,+vy,_}: Body{A.constrain((x + vx * factor : F32),radius),A.constrain((y + vy * factor : F32),radius),kind,variant,hp,maxHp,(age + 1 : U32),seed,radius}
def move_body(body: Body,motion: Motion,args: Args) -> Body:
  match body motion args:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius} Motion{_,_,_,_,_,+slow,_,_,_} Args{Run{_,+tick,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,+mode,_,_,_,_,_,+enemyKinds,+relicCollected},_,_,_,_,+hits}: moved_intent(Body{x,y,kind,variant,hp,maxHp,age,seed,radius},E.intent(variant,age,x,y,px,py),(E.choose_float(U32.is_eq(variant,30),1.0,slow_factor(slow)) * (1.10 + F32.min(0.60,(U32.to_f32(tick) / 60000.0 : F32)) + F32.min(4.0,(U32.to_f32(age) / 120.0 : F32)) * U32.to_f32(Bool.to_u32(U32.is_eq(variant,30)))) : F32))
def move_plan() -> Q.Plan<Schema,Store,Unit,Unit,MoveOpsType>: Q.Plan{MoveOps{Q.write_family(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family()),Q.read_family(~Schema,~Store,~Unit,~Unit,~StatusRest,~Status,~Status,~StatusToken,~take_status,~put_status,~project_status,~status_family())},selected_enemy}

def movement_roster_read(store: Store) -> Store & MovementRoster:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,+movement,candidates,players}: (Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players},movement)
def write_row(~H: Type,~ops: Ops<H>,ctx: H,row: EntityRow) -> H & (T.Outcome<Error> & EntityRow):
  match row:
    case EntityRow{Row{Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius},+hit,+xp,+gold,+heal,+chest,+killed,+relic},+motion}:
      (Cap.set(~H,~Status,~Status,~status_cap(~H,ops),Cap.set(~H,~Vitals,~Vitals,~vital_cap(~H,ops),ctx,Vitals{hp,maxHp}),status_of(motion)),(T.Success{},EntityRow{Row{Body{x,y,kind,variant,hp,maxHp,age,seed,radius},hit,xp,gold,heal,chest,killed,relic},motion}))
type PickupOps<-H: Type> is Type: PickupOps{body: Cap.Read<H,Body>,pickup: Cap.Read<H,Pickup>}
def PickupOpsType(H: Type) -> Type: PickupOps<H>
def pickup_body_cap(~H: Type,ops: PickupOps<H>) -> Cap.Read<H,Body>:
  match ops:
    case PickupOps{body,_}: body
def pickup_payload_cap(~H: Type,ops: PickupOps<H>) -> Cap.Read<H,Pickup>:
  match ops:
    case PickupOps{_,pickup}: pickup
type PoolOps<-H: Type> is Type: PoolOps{role: Cap.Read<H,Role.Role>,enemy: Ops<H>,pickup: PickupOps<H>}
def PoolOpsType(H: Type) -> Type: PoolOps<H>
def pool_role_cap(~H: Type,ops: PoolOps<H>) -> Cap.Read<H,Role.Role>:
  match ops:
    case PoolOps{role,_,_}: role
def pool_enemy_caps(~H: Type,ops: PoolOps<H>) -> Ops<H>:
  match ops:
    case PoolOps{_,enemy,_}: enemy
def pool_pickup_caps(~H: Type,ops: PoolOps<H>) -> PickupOps<H>:
  match ops:
    case PoolOps{_,_,pickup}: pickup
def plan() -> Q.Plan<Schema,Store,Unit,Unit,PoolOpsType>: Q.Plan{PoolOps{Q.read_family(~Schema,~Store,~Unit,~Unit,~RoleRest,~Role.Role,~Role.Role,~RoleToken,~take_role,~put_role,~project_role,~role_family()),Ops{Q.read_family(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family()),Q.write_family(~Schema,~Store,~Unit,~Unit,~VitalRest,~Vitals,~Vitals,~VitalToken,~take_vitals,~put_vitals,~project_vitals,~vital_family()),Q.write_family(~Schema,~Store,~Unit,~Unit,~StatusRest,~Status,~Status,~StatusToken,~take_status,~put_status,~project_status,~status_family())},PickupOps{Q.read_family(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family()),Q.read_family(~Schema,~Store,~Unit,~Unit,~PickupRest,~Pickup,~Pickup,~PickupToken,~take_pickup,~put_pickup,~project_pickup,~pickup_family())}},selected_pool}

# Lifecycle dispatch keeps enemy geometry and XP payload grants separate while
# executing both bodies in the original enclosing transaction and row order.
type LifecycleOps<-H: Type> is Type: LifecycleOps{body: Cap.Write<H,Body,Body>,handle: Cap.ValueRead<H,W.Handle<Schema>>}
def LifecycleOpsType(H: Type) -> Type: LifecycleOps<H>
def loot_body_cap(~H: Type,ops: LifecycleOps<H>) -> Cap.Write<H,Body,Body>:
  match ops:
    case LifecycleOps{body,_}: body
def loot_handle_cap(~H: Type,ops: LifecycleOps<H>) -> Cap.ValueRead<H,W.Handle<Schema>>:
  match ops:
    case LifecycleOps{_,handle}: handle
type PickupLifecycleOps<-H: Type> is Type: PickupLifecycleOps{body: Cap.Write<H,Body,Body>,pickup: Cap.Write<H,Pickup,Pickup>}
def PickupLifecycleOpsType(H: Type) -> Type: PickupLifecycleOps<H>
def pickup_lifecycle_body_cap(~H: Type,ops: PickupLifecycleOps<H>) -> Cap.Write<H,Body,Body>:
  match ops:
    case PickupLifecycleOps{body,_}: body
def pickup_lifecycle_payload_cap(~H: Type,ops: PickupLifecycleOps<H>) -> Cap.Write<H,Pickup,Pickup>:
  match ops:
    case PickupLifecycleOps{_,pickup}: pickup
type LootOps<-H: Type> is Type: LootOps{role: Cap.Read<H,Role.Role>,enemy: LifecycleOps<H>,pickup: PickupLifecycleOps<H>}
def LootOpsType(H: Type) -> Type: LootOps<H>
def loot_role_cap(~H: Type,ops: LootOps<H>) -> Cap.Read<H,Role.Role>:
  match ops:
    case LootOps{role,_,_}: role
def loot_enemy_caps(~H: Type,ops: LootOps<H>) -> LifecycleOps<H>:
  match ops:
    case LootOps{_,enemy,_}: enemy
def loot_pickup_caps(~H: Type,ops: LootOps<H>) -> PickupLifecycleOps<H>:
  match ops:
    case LootOps{_,_,pickup}: pickup
# Carry the equality result into the recursive matcher so a hit never evaluates
# the remaining lookup. The first matching row wins, including duplicate IDs.
# Construct once per lifecycle tick. Insertion order matches the original scan,
# retaining the first occurrence of a seed and every opaque Body field.
def body_seed(body: Body) -> U32:
  match body:
    case Body{_,_,_,_,_,_,_,seed,_}: seed
def body_index_rows(rows: List<&2,EntityRow>,index: BI.Index<Body>) -> BI.Index<Body>:
  match rows:
    case []: index
    case EntityRow{Row{+body,_,_,_,_,_,_,_},_} <> rest: body_index_rows(rest,BI.insert(~Body,index,body_seed(body),body))
def body_index(rows: List<&2,EntityRow>) -> BI.Index<Body>: body_index_rows(rows,BI.Empty{})
def indexed_body(index: BI.Index<Body>,seed: U32,fallback: Body) -> Body:
  BI.get(~Body,index,seed,fallback)
type LifecycleCall is Data: LifecycleCall{role: Role.Role,index: BI.Index<Body>}
def loot_active_handle(~H: Type,result: H & W.Handle<Schema>) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  match result:
    case (ctx,handle): (ctx,(T.Success{},Some{handle}))
def loot_written(~H: Type,~ops: LifecycleOps<H>,active: Bool,ctx: H) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  match active:
    case False{}: (ctx,(T.Success{},None{}))
    case True{}: loot_active_handle(~H,Cap.value_read(~H,~W.Handle<Schema>,~loot_handle_cap(~H,ops),ctx))
def loot_write_body(~H: Type,~ops: LifecycleOps<H>,role: Role.Role,+body: Body,ctx: H) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  loot_written(~H,~ops,role_active(role,body),Cap.set(~H,~Body,~Body,~loot_body_cap(~H,ops),ctx,body))
def loot_observed_body(~H: Type,~ops: LifecycleOps<H>,role: Role.Role,index: BI.Index<Body>,+body: Body,ctx: H) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  match body:
    case Body{_,_,_,_,_,_,_,+seed,_}: loot_write_body(~H,~ops,role,indexed_body(index,seed,body),ctx)
def loot_observed(~H: Type,~ops: LifecycleOps<H>,role: Role.Role,index: BI.Index<Body>,result: H & C.Access<Body>) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  match result:
    case (ctx,C.Found{body}): loot_observed_body(~H,~ops,role,index,body,ctx)
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},None{}))
def enemy_lifecycle(~H: Type,~ops: LifecycleOps<H>,call: LifecycleCall,ctx: H) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  match call:
    case LifecycleCall{role,index}: loot_observed(~H,~ops,role,index,Cap.get(~H,~Body,~Body,~loot_body_cap(~H,ops),ctx))
def pickup_lifecycle_write(~H: Type,~ops: PickupLifecycleOps<H>,+body: Body,ctx: H) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  (Cap.set(~H,~Pickup,~Pickup,~pickup_lifecycle_payload_cap(~H,ops),Cap.set(~H,~Body,~Body,~pickup_lifecycle_body_cap(~H,ops),ctx,body),pickup_from_body(body)),(T.Success{},None{}))
def pickup_lifecycle_planned(~H: Type,~ops: PickupLifecycleOps<H>,index: BI.Index<Body>,+body: Body,ctx: H) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  match body:
    case Body{_,_,_,_,_,_,_,seed,_}: pickup_lifecycle_write(~H,~ops,indexed_body(index,seed,body),ctx)
def pickup_lifecycle_payload(~H: Type,~ops: PickupLifecycleOps<H>,index: BI.Index<Body>,body: Body,result: H & C.Access<Pickup>) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  match result:
    case (ctx,C.Found{pickup}): pickup_lifecycle_planned(~H,~ops,index,pickup_body(body,pickup),ctx)
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},None{}))
def pickup_lifecycle_observed(~H: Type,~ops: PickupLifecycleOps<H>,index: BI.Index<Body>,result: H & C.Access<Body>) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  match result:
    case (ctx,C.Found{body}): pickup_lifecycle_payload(~H,~ops,index,body,Cap.get(~H,~Pickup,~Pickup,~pickup_lifecycle_payload_cap(~H,ops),ctx))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},None{}))
def pickup_lifecycle(~H: Type,~ops: PickupLifecycleOps<H>,index: BI.Index<Body>,ctx: H) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>): pickup_lifecycle_observed(~H,~ops,index,Cap.get(~H,~Body,~Body,~pickup_lifecycle_body_cap(~H,ops),ctx))
def loot_dispatch(~H: Type,~ops: LootOps<H>,role: Role.Role,index: BI.Index<Body>,ctx: H) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  match role:
    case Role.XpSlot{}: Cap.invoke(~PickupLifecycleOpsType,~BI.Index<Body>,~(T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>),~pickup_lifecycle,~H,~loot_pickup_caps(~H,ops),index,ctx)
    case role: Cap.invoke(~LifecycleOpsType,~LifecycleCall,~(T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>),~enemy_lifecycle,~H,~loot_enemy_caps(~H,ops),LifecycleCall{role,index},ctx)
def loot_role_observed(~H: Type,~ops: LootOps<H>,index: BI.Index<Body>,result: H & C.Access<Role.Role>) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>):
  match result:
    case (ctx,C.Found{role}): loot_dispatch(~H,~ops,role,index,ctx)
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},None{}))
def loot_system(~H: Type,~ops: LootOps<H>,index: BI.Index<Body>,ctx: H) -> H & (T.Outcome<Error> & Maybe<&2,W.Handle<Schema>>): loot_role_observed(~H,~ops,index,Cap.read(~H,~Role.Role,~loot_role_cap(~H,ops),ctx))
def loot_plan() -> Q.Plan<Schema,Store,Unit,Unit,LootOpsType>: Q.Plan{LootOps{Q.read_family(~Schema,~Store,~Unit,~Unit,~RoleRest,~Role.Role,~Role.Role,~RoleToken,~take_role,~put_role,~project_role,~role_family()),LifecycleOps{Q.write_family(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family()),Q.handle_read(~Schema,~Store,~Unit,~Unit)},PickupLifecycleOps{Q.write_family(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family()),Q.write_family(~Schema,~Store,~Unit,~Unit,~PickupRest,~Pickup,~Pickup,~PickupToken,~take_pickup,~put_pickup,~project_pickup,~pickup_family())}},selected_pool}

def movement_roster_outputs(rows: List<&2,Maybe<&2,W.Handle<Schema>>>) -> List<&2,W.Handle<Schema>>:
  MM.outputs(~W.Handle<Schema>,rows)
# Publish membership only after the Body transaction succeeds. Failed traversal
# rolls back Body and retains the old roster; no partial output becomes a roster.
def lifecycle_done(+rows: List<&2,EntityRow>,result: Q.Executed<World(),Q.Error<Error>,Maybe<&2,W.Handle<Schema>>>) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},handles}: Q.Executed{movement_roster_save(world,movement_roster_outputs(handles)),T.Success{},rows}
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
# Batch XP routing: preserve exact drops while free, then one stable accumulator.
# Existing accumulator identity/coordinates/generation survive every merge.
type XpInventory is Data: XpInventory{free: List<&2,U32>,accumulator: Body,distance: F32,marked: Bool}
def xp_pool_keep(keep: Bool,row: EntityRow,rest: List<&2,EntityRow>) -> List<&2,EntityRow>:
  match keep:
    case True{}: row <> rest
    case False{}: rest
def xp_pool_filter(+row: EntityRow,+pool: Bool,rest: List<&2,EntityRow>) -> List<&2,EntityRow>:
  match row:
    case EntityRow{Row{Body{_,_,_,_,_,_,_,seed,_},_,_,_,_,_,_,_},_}: xp_pool_keep(Bool.or(Bool.and(PL.is_xp(seed),pool),Bool.and(Bool.not(PL.is_xp(seed)),Bool.not(pool))),row,rest)
def xp_pool_rows(rows: List<&2,EntityRow>,+pool: Bool) -> List<&2,EntityRow>:
  match rows:
    case []: []
    case +row <> rest: xp_pool_filter(row,pool,xp_pool_rows(rest,pool))
def xp_inventory_select(selected: Bool,+body: Body,distance: F32,marked: Bool,inventory: XpInventory) -> XpInventory:
  match selected inventory:
    case False{} inventory: inventory
    case True{} XpInventory{free,_,_,_}: XpInventory{free,body,distance,marked}
def xp_inventory_body(body: Body,+px: F32,+py: F32,inventory: XpInventory) -> XpInventory:
  match body inventory:
    case Body{_,_,8,_,_,_,_,seed,_} XpInventory{free,accumulator,distance,marked}: XpInventory{seed <> free,accumulator,distance,marked}
    case Body{+x,+y,2,+variant,+amount,+generation,+age,+seed,+radius} XpInventory{+free,+accumulator,+distance,+marked}: xp_inventory_select(Bool.and(Bool.not(marked),Bool.or(U32.is_eq(variant,1),F32.is_lt(distance,distance2(x,y,px,py)))),Body{x,y,2,variant,amount,generation,age,seed,radius},distance2(x,y,px,py),U32.is_eq(variant,1),XpInventory{free,accumulator,distance,marked})
    case _ inventory: inventory
def xp_inventory(rows: List<&2,EntityRow>,+px: F32,+py: F32,inventory: XpInventory) -> XpInventory:
  match rows:
    case []: inventory
    case EntityRow{Row{body,_,_,_,_,_,_,_},_} <> rest: xp_inventory(rest,px,py,xp_inventory_body(body,px,py,inventory))
type XpBatch is Data: XpBatch{free: List<&2,U32>,accumulator: Body,updates: BI.Index<Body>,overflow: U32}
def xp_accumulator_or_new(old: Body,fresh: Body) -> Body:
  match old:
    case Body{_,_,2,_,_,_,_,_,_}: old
    case _: fresh
def xp_batch_drop(+amount: U32,+x: F32,+y: F32,+tick: U32,batch: XpBatch) -> XpBatch:
  match batch:
    case XpBatch{[],accumulator,index,overflow}: XpBatch{[],accumulator,index,X.merge(overflow,amount)}
    case XpBatch{+seed <> free,accumulator,index,overflow}:
      +fresh : Body = Body{x,y,2,0,amount,tick,0,seed,6.0}
      XpBatch{free,xp_accumulator_or_new(accumulator,fresh),BI.insert(~Body,index,seed,fresh),overflow}
def xp_batch_events(events: List<&2,EntityRow>,+tick: U32,batch: XpBatch) -> XpBatch:
  match events:
    case []: batch
    case EntityRow{Row{Body{+x,+y,2,variant,_,_,_,_,_},_,_,_,_,_,1,_},_} <> rest: xp_batch_events(rest,tick,xp_batch_drop(X.drop_amount(variant),x,y,tick,batch))
    case _ <> rest: xp_batch_events(rest,tick,batch)
def xp_overflow_body(selected: Bool,body: Body,amount: U32) -> Body:
  match selected body:
    case True{} Body{px,py,2,_,old,generation,age,seed,radius}: Body{px,py,2,1,X.merge(old,amount),generation,age,seed,radius}
    case _ body: body
def xp_batch_body(+body: Body,+index: BI.Index<Body>,+selected: U32,+overflow: U32) -> Body:
  match body:
    case Body{_,_,_,_,_,_,_,+seed,_}: xp_overflow_body(Bool.and(U32.is_eq(seed,selected),U32.is_lt(0,overflow)),BI.get(~Body,index,seed,body),overflow)
def xp_batch_apply(rows: List<&2,EntityRow>,+index: BI.Index<Body>,+selected: U32,+overflow: U32) -> List<&2,EntityRow>:
  match rows:
    case []: []
    case EntityRow{Row{body,hit,xp,gold,heal,chest,killed,relic},motion} <> rest: EntityRow{Row{xp_batch_body(body,index,selected,overflow),hit,xp,gold,heal,chest,killed,relic},motion} <> xp_batch_apply(rest,index,selected,overflow)
def xp_batch_done(pool: List<&2,EntityRow>,batch: XpBatch) -> List<&2,EntityRow>:
  match batch:
    case XpBatch{_,Body{_,_,_,_,_,_,_,seed,_},index,overflow}: xp_batch_apply(pool,index,seed,overflow)
def xp_apply_inventory(+events: List<&2,EntityRow>,+pool: List<&2,EntityRow>,+tick: U32,inventory: XpInventory) -> List<&2,EntityRow>:
  match inventory:
    case XpInventory{free,accumulator,_,_}: xp_batch_done(pool,xp_batch_events(events,tick,XpBatch{List.reverse(&2,U32,free),accumulator,BI.Empty{},0}))
def xp_apply_events(+events: List<&2,EntityRow>,+pool: List<&2,EntityRow>,+tick: U32,+px: F32,+py: F32) -> List<&2,EntityRow>:
  xp_apply_inventory(events,pool,tick,xp_inventory(pool,px,py,XpInventory{[],Body{0.0,0.0,8,0,0,0,0,PL.xp_start(),0.0},(0.0 - 1.0 : F32),False{}}))
def xp_free_enemies(rows: List<&2,EntityRow>) -> List<&2,EntityRow>:
  match rows:
    case []: []
    case EntityRow{Row{Body{+x,+y,2,+variant,_,+maximum,_,+seed,_},+hit,+xp,+gold,+heal,+chest,1,+relic},motion} <> rest: EntityRow{Row{Body{x,y,8,variant,0,maximum,0,seed,0.0},hit,xp,gold,heal,chest,1,relic},motion} <> xp_free_enemies(rest)
    case row <> rest: row <> xp_free_enemies(rest)
def xp_route_rows_at(+rows: List<&2,EntityRow>,+tick: U32,px: F32,py: F32) -> List<&2,EntityRow>:
  List.append(&2,EntityRow,xp_free_enemies(xp_pool_rows(rows,False{})),xp_apply_events(rows,xp_pool_rows(rows,True{}),tick,px,py))
def xp_route_args(rows: List<&2,EntityRow>,args: Args) -> List<&2,EntityRow>:
  match args:
    case Args{Run{_,tick,px,py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_},_,_,_,_,_}: xp_route_rows_at(rows,tick,px,py)

# The trusted schema adapter narrows only enumeration; capabilities, selector,
# transaction finish, rollback and mixed allocator order remain the public query's.
def candidate_roster_read(store: Store) -> Store & CandidateRoster:
  match store:
    case Store{bodies,vitals,motions,statuses,pickups,roles,movement,+candidates,players}: (Store{bodies,vitals,motions,statuses,pickups,roles,movement,candidates,players},candidates)
def candidate_roster_handles(projectile: Bool,roster: CandidateRoster) -> List<&2,W.Handle<Schema>>:
  match projectile roster:
    case True{} CandidatesPrepared{projectiles,_}: projectiles
    case False{} CandidatesPrepared{_,pool}: pool
def candidate_query_ready(~Ops: Type -> Type,~A: Data,~Out: Data,~plan: Q.Plan<Schema,Store,Unit,Unit,Ops>,~body: @-H: Type -> @-caps: Ops(H) -> A -> H -> H & (T.Outcome<Error> & Out),args: A,world: World(),handles: List<&2,W.Handle<Schema>>) -> Q.Executed<World(),Q.Error<Error>,Out>:
  Q.reserved(~Schema,~Store,~Unit,~Unit,~Ops,~A,~Error,~Out,~plan,~body,args,None{},(world,handles))
def candidate_query_opened(~Ops: Type -> Type,~A: Data,~Out: Data,~plan: Q.Plan<Schema,Store,Unit,Unit,Ops>,~body: @-H: Type -> @-caps: Ops(H) -> A -> H -> H & (T.Outcome<Error> & Out),projectile: Bool,args: A,result: World() & CandidateRoster) -> Q.Executed<World(),Q.Error<Error>,Out>:
  match result:
    case (world,roster): candidate_query_ready(~Ops,~A,~Out,~plan,~body,args,world,candidate_roster_handles(projectile,roster))
def candidate_query(~Ops: Type -> Type,~A: Data,~Out: Data,~plan: Q.Plan<Schema,Store,Unit,Unit,Ops>,~body: @-H: Type -> @-caps: Ops(H) -> A -> H -> H & (T.Outcome<Error> & Out),projectile: Bool,args: A,world: World()) -> Q.Executed<World(),Q.Error<Error>,Out>:
  candidate_query_opened(~Ops,~A,~Out,~plan,~body,projectile,args,W.with_store(~Schema,~Store,~Unit,~Unit,~CandidateRoster,candidate_roster_read,world))

def xp_lifecycle(+projectiles: List<&2,EntityRow>,+rows: List<&2,EntityRow>,world: World()) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  lifecycle_done(List.append(&2,EntityRow,projectiles,rows),candidate_query(~LootOpsType,~BI.Index<Body>,~Maybe<&2,W.Handle<Schema>>,~loot_plan(),~loot_system,False{},body_index(rows),world))
def owned(rows: List<&2,U32>) -> U32:
  match rows:
    case []: 0
    case n <> rest: (Bool.to_u32(U32.is_lt(0,n)) + owned(rest) : U32)
def offer_candidate(allowed: Bool,+kind: U32,+id: U32,+level: U32) -> Offer:
  match allowed:
    case True{}: Offer{kind,id,(level + 1 : U32)}
    case False{}: Offer{2,0,1}
def offer_for(+roll: U32,+weapons: List<&2,U32>,+passives: List<&2,U32>) -> Offer:
  match roll:
    case +roll: offer_candidate(Bool.and(U32.is_lt(at(weapons,(roll % 24 : U32)),8),Bool.or(U32.is_lt(0,at(weapons,(roll % 24 : U32))),U32.is_lt(owned(weapons),6))),0,(roll % 24 : U32),at(weapons,(roll % 24 : U32)))
def passive_offer(+id: U32,+passives: List<&2,U32>) -> Offer:
  offer_candidate(Bool.and(U32.is_lt(at(passives,id),5),Bool.or(U32.is_lt(0,at(passives,id)),U32.is_lt(owned(passives),6))),1,id,at(passives,id))
def prefer_offer(valid: Bool,candidate: Offer,fallback: Offer) -> Offer:
  match valid:
    case True{}: candidate
    case False{}: fallback
def equipped_offer(weapons: List<&2,U32>,+index: U32) -> Offer:
  match weapons:
    case []: Offer{2,0,1}
    case +level <> rest: prefer_offer(Bool.and(U32.is_lt(0,level),U32.is_lt(level,8)),Offer{0,index,(level + 1 : U32)},equipped_offer(rest,(index + 1 : U32)))
def evolution_passive(+id: U32) -> U32: at([1,12,2,4,11,4,0,3,10,3,1,9,7,12,2,0,4,2,3,6,8,10,3,12],id)
def evolution_offer(weapons: List<&2,U32>,+index: U32,+passives: List<&2,U32>) -> Offer:
  match weapons:
    case []: Offer{4,0,50}
    case +level <> rest: prefer_offer(Bool.and(U32.is_eq(level,8),U32.is_lt(0,at(passives,evolution_passive(index)))),Offer{3,index,9},evolution_offer(rest,(index + 1 : U32),passives))
def make_offers(+seed: U32,+weapons: List<&2,U32>,+passives: List<&2,U32>) -> List<&2,Offer>:
  [equipped_offer(weapons,0),passive_offer(((seed * 7 + 3) % 18 : U32),passives),offer_for((seed % 24 : U32),weapons,passives)]
def union_offer(remaining: Nat,+id: U32,+weapons: List<&2,U32>,+fallback: Offer) -> Offer:
  match remaining:
    case 0n: fallback
    case 1n+rest: prefer_offer(Bool.and(Bool.and(U32.is_le(8,at(weapons,union_base(id))),U32.is_le(at(weapons,union_base(id)),9)),Bool.and(U32.is_le(8,at(weapons,union_partner(id))),U32.is_le(at(weapons,union_partner(id)),9))),Offer{5,id,(10 + id : U32)},union_offer(rest,(id + 1 : U32),weapons,fallback))
def chest_offers(+seed: U32,+weapons: List<&2,U32>,+passives: List<&2,U32>) -> List<&2,Offer>:
  [union_offer(6n,0,weapons,evolution_offer(weapons,0,passives)),evolution_offer(weapons,0,passives),Offer{4,0,50}]
def phase_offers(chest: Bool,+seed: U32,+weapons: List<&2,U32>,+passives: List<&2,U32>) -> List<&2,Offer>:
  match chest:
    case True{}: chest_offers(seed,weapons,passives)
    case False{}: make_offers(seed,weapons,passives)
def banned(+mask: U32,+id: U32) -> Bool: U32.is_lt(0,U32.and(mask,U32.shln(1,U32.to_nat(id))))
def filter_offer(offer: Offer,+bannedWeapons: U32,+bannedPassives: U32) -> Offer:
  match offer:
    case Offer{0,+id,+level}: prefer_offer(Bool.not(banned(bannedWeapons,id)),Offer{0,id,level},Offer{2,0,1})
    case Offer{1,+id,+level}: prefer_offer(Bool.not(banned(bannedPassives,id)),Offer{1,id,level},Offer{2,0,1})
    case offer: offer
def filter_offers(offers: List<&2,Offer>,+bannedWeapons: U32,+bannedPassives: U32) -> List<&2,Offer>:
  match offers:
    case []: []
    case offer <> rest: filter_offer(offer,bannedWeapons,bannedPassives) <> filter_offers(rest,bannedWeapons,bannedPassives)
def evolve_weapon(weapons: List<&2,U32>,+id: U32) -> List<&2,U32>:
  match weapons id:
    case Nil{} _: []
    case Con{+level,rest} 0: U32.min(9,(level + Bool.to_u32(U32.is_eq(level,8)) : U32)) <> rest
    case Con{level,rest} +id: level <> evolve_weapon(rest,(id - 1 : U32))
def upgrade(offer: Offer,run: Run) -> Run:
  match offer run:
    case Offer{0,+id,_} Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,bump(weapons,id),passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
    case Offer{5,+id,_} Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,U32.min(maxHp,(hp + 30 : U32)),maxHp,xp,need,level,kills,(gold + 50 : U32),character,set_at(set_at(weapons,union_partner(id),0),union_base(id),(10 + id : U32)),passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
    case Offer{3,+id,_} Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,U32.min(maxHp,(hp + 20 : U32)),maxHp,xp,need,level,kills,(gold + 25 : U32),character,evolve_weapon(weapons,id),passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
    case Offer{4,_,+amount} Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,(gold + amount : U32),character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
    case Offer{1,+id,_} Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,U32.min((maxHp + maxHp * 20 / (100 + at(passives,7) * 20) * Bool.to_u32(U32.is_eq(id,7)) : U32),(hp + maxHp * 20 / (100 + at(passives,7) * 20) * Bool.to_u32(U32.is_eq(id,7)) : U32)),(maxHp + maxHp * 20 / (100 + at(passives,7) * 20) * Bool.to_u32(U32.is_eq(id,7)) : U32),xp,need,level,kills,gold,character,weapons,bump(passives,id),invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
    case Offer{_,_,_} Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,U32.min(maxHp,(hp + 30 : U32)),maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def offer_at(offers: List<&2,Offer>,index: U32) -> Offer:
  match offers index:
    case Nil{} _: Offer{2,0,1}
    case Con{offer,_} 0: offer
    case Con{_,rest} index: offer_at(rest,(index - 1 : U32))
def choose_unchecked_with(~emit: State -> Packet,state: State,+choice: U32) -> Packet:
  match state:
    case State{world,Run{0,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: emit(State{world,Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case State{world,run,+bodies,+offers,+snapshots,pending}: emit(State{world,upgrade(offer_at(offers,U32.min(choice,2)),run),bodies,[],snapshots,pending})
def choose_raw_with(~emit: State -> Packet,state: State,+choice: U32) -> Packet:
  match state:
    case State{world,Run{3,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: emit(State{world,Run{3,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case State{world,Run{4,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: emit(State{world,Run{4,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case state: choose_unchecked_with(~emit,state,choice)
type Totals is Data: Totals{hit: U32,xp: U32,gold: U32,heal: U32,chest: U32,kills: U32,bodies: List<&2,Body>,snapshots: List<&2,Snapshot>,relic: U32}
def choose_raw(state: State,choice: U32) -> Packet: choose_raw_with(~packet,state,choice)
def accumulate(rows: List<&2,EntityRow>,+hit: U32,+xp: U32,+gold: U32,+heal: U32,+chest: U32,+kills: U32,+bodies: List<&2,Body>,+snapshots: List<&2,Snapshot>,+relicTotal: U32) -> Totals:
  match rows:
    case []: Totals{hit,xp,gold,heal,chest,kills,bodies,snapshots,relicTotal}
    case EntityRow{Row{+body,+h,+x,+g,+he,+c,+k,+relic},+motion} <> rest: accumulate(rest,(hit + h : U32),(xp + x : U32),(gold + g : U32),(heal + he : U32),(chest + c : U32),(kills + k : U32),body <> bodies,Snapshot{body,motion} <> snapshots,(relicTotal + relic : U32))
def phase_for(dead: Bool,won: Bool,chest: Bool,levelup: Bool) -> U32:
  match dead won chest levelup:
    case True{} _ _ _: 3
    case _ True{} _ _: 4
    case _ _ True{} _: 2
    case _ _ _ True{}: 1
    case _ _ _ _: 0
def boss_kills(rows: List<&2,EntityRow>) -> U32:
  match rows:
    case []: 0
    case EntityRow{Row{Body{_,_,_,+variant,_,_,_,_,_},_,_,_,_,_,+killed,+relic},_} <> rest: (killed * Bool.to_u32(U32.is_le(20,variant)) + boss_kills(rest) : U32)
def earned_xp(+earned: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32) -> U32: (earned * (100 + at(passives,9) * 10 + at(passives,14) * 10 + meta_rank(meta,7) * 5 + 30 * Bool.to_u32(U32.is_eq(arcana,5))) / 100 : U32)
def player_damage(+hit: U32,+invuln: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> U32:
  Combat.contact_damage(hit,invuln,U32.max(1,Combat.lose(6,(at(passives,6) + meta_rank(meta,3) + 3 * Bool.to_u32(U32.is_eq(arcana,4)) + Bool.to_u32(U32.is_eq(character,3)) : U32))))
# Armor remains valuable, but crowd pressure cannot be reduced to one damage.
# The last minute is a deliberate lethal gauntlet rather than an empty victory lap.
def pressure_damage(+hit: U32,+tick: U32,+mode: U32,+invuln: U32,passives: List<&2,U32>,meta: U32,arcana: U32,character: U32) -> U32:
  Combat.contact_damage(hit,invuln,(player_damage(hit,invuln,passives,meta,arcana,character) + (tick / 3600 + U32.min(6,(hit / 3 : U32)) + U32.min(24,(Combat.lose(tick,Combat.lose(run_length(mode),3600)) / 150 : U32)) + 2000 * Bool.to_u32(U32.is_le(1000,hit))) : U32))
def revival_available(+hp: U32,+passives: List<&2,U32>,+meta: U32,+used: U32) -> Bool: Bool.and(U32.is_eq(hp,0),U32.is_lt(used,(meta_rank(meta,9) + at(passives,13) : U32)))
def revive_hp(revive: Bool,hp: U32,maxHp: U32) -> U32:
  match revive:
    case True{}: maxHp
    case False{}: hp
def remainder_xp(+xp: U32,+need: U32) -> U32: Combat.lose(xp,(need * Bool.to_u32(U32.is_le(need,xp)) : U32))
def reward_repeat(count: Nat,+kind: U32) -> List<&2,U32>:
  match count:
    case 0n: []
    case 1n+rest: kind <> reward_repeat(rest,kind)
def reward_extra(levelup: Bool,queue: List<&2,U32>) -> List<&2,U32>:
  match levelup:
    case True{}: 1 <> queue
    case False{}: queue
def reward_backlog(+chests: U32,levelup: Bool) -> List<&2,U32>:
  reward_extra(Bool.and(U32.is_lt(0,chests),levelup),reward_repeat(U32.to_nat(dec(chests)),2))
def finish_run_with(~emit: State -> Packet,world: World(),run: Run,+bodies: List<&2,Body>,+offers: List<&2,Offer>,snapshots: List<&2,Snapshot>,pending: List<&2,U32>) -> Packet: emit(State{world,run,bodies,offers,snapshots,pending})
def finish_values_with(~emit: State -> Packet,world: World(),run: Run,+bodies: List<&2,Body>,+totalXp: U32,+health: U32,+wasHit: U32,+chest: U32,+killed: U32,+coins: U32,+bossKills: U32,+snapshots: List<&2,Snapshot>,+relicEvent: U32) -> Packet:
  match run:
    case Run{_,+tick,+px,+py,_,+maxHp,_,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}:
      finish_run_with(~emit,world,Run{phase_for(Bool.and(Bool.and(U32.is_eq(health,0),Bool.not(revival_available(health,passives,meta,revivals))),Bool.or(U32.is_eq(mode,2),U32.is_lt(tick,run_length(mode)))),Bool.and(Bool.and(Bool.not(U32.is_eq(mode,2)),U32.is_le(run_length(mode),tick)),Bool.and(U32.is_eq(health,0),Bool.not(revival_available(health,passives,meta,revivals)))),U32.is_lt(0,chest),U32.is_le(need,totalXp)),tick,px,py,revive_hp(revival_available(health,passives,meta,revivals),health,maxHp),maxHp,remainder_xp(totalXp,need),(need + Combat.lose(next_xp_need(level),need) * Bool.to_u32(U32.is_le(need,totalXp)) : U32),(level + Bool.to_u32(U32.is_le(need,totalXp)) : U32),(kills + killed : U32),(gold + 300 * Bool.to_u32(Bool.and(U32.is_eq(mode,3),U32.is_eq(18000,tick))) + (50 + level * 5 + kills / 20) * Bool.to_u32(Bool.and(U32.is_eq(health,0),Bool.not(revival_available(health,passives,meta,revivals)))) + coins * (100 + at(passives,15) * 15 + at(passives,14) * 10 + 50 * Bool.to_u32(U32.is_eq(mode,1)) + meta_rank(meta,8) * 10 + 25 * Bool.to_u32(U32.is_eq(arcana,6))) / 100 : U32),character,weapons,passives,U32.max(dec(invuln),(45 * wasHit + 180 * Bool.to_u32(revival_available(health,passives,meta,revivals)) : U32)),(seed + 1 : U32),stage,arcana,meta,(revivals + Bool.to_u32(revival_available(health,passives,meta,revivals)) : U32),(bosses + bossKills : U32),mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,U32.max(relicCollected,relicEvent)},bodies,filter_offers(phase_offers(U32.is_lt(0,chest),(seed + level * 13 : U32),weapons,passives),bannedWeapons,bannedPassives),snapshots,reward_backlog(chest,U32.is_le(need,totalXp)))
def heal_after_damage(hp: U32,damage: U32,healing: U32,healingPercent: U32,maxHp: U32) -> U32:
  U32.min(maxHp,(Combat.lose(hp,damage) + healing * healingPercent / 100 : U32))
def add_killed_kind(known: Bool,+kind: U32,kinds: List<&2,U32>) -> List<&2,U32>:
  match known:
    case True{}: kinds
    case False{}: kind <> kinds
def killed_kinds(rows: List<&2,EntityRow>,+kinds: List<&2,U32>) -> List<&2,U32>:
  match rows:
    case []: kinds
    case EntityRow{Row{Body{_,_,_,+variant,_,_,_,_,_},_,_,_,_,_,1,+relic},_} <> rest: killed_kinds(rest,add_killed_kind(contains(kinds,variant),variant,kinds))
    case _ <> rest: killed_kinds(rest,kinds)
def run_kinds(run: Run) -> List<&2,U32>:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,kinds,+relicCollected}: kinds
def finish_stats_with(~emit: State -> Packet,world: World(),run: Run,totals: Totals,+bossKills: U32,+kinds: List<&2,U32>) -> Packet:
  match run totals:
    case Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected} Totals{+hit,+earned,+coins,+heal,+chest,+killed,+bodies,+snapshots,+relic}:
      finish_values_with(~emit,world,Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,kinds,relicCollected},bodies,(xp + earned_xp(earned,passives,meta,arcana) : U32),heal_after_damage(hp,(pressure_damage(hit,tick,mode,invuln,passives,meta,arcana,character) + E.hazard(stage,tick,px,py) * Bool.to_u32(U32.is_eq(invuln,0)) : U32),(heal + killed * Bool.to_u32(Bool.and(U32.is_eq((tick % 12 : U32),0),Bool.and(U32.is_eq(arcana,9),Bool.or(U32.is_lt(0,at(weapons,4)),U32.is_lt(0,at(weapons,19)))))) + (meta_rank(meta,2) + at(passives,11) + 2 * Bool.to_u32(U32.is_eq(arcana,9)) + Bool.to_u32(U32.is_eq(character,2))) * Bool.to_u32(U32.is_eq((tick % 60 : U32),0)) : U32),(100 + at(passives,17) * 20 + 30 * Bool.to_u32(U32.is_eq(arcana,10)) : U32),maxHp),Bool.to_u32(Bool.and(U32.is_lt(0,hit),U32.is_eq(invuln,0))),chest,killed,coins,bossKills,snapshots,relic)
def executed_with(~emit: State -> Packet,+run: Run,result: Q.Executed<World(),Q.Error<Error>,EntityRow>) -> Packet:
  match result:
    case Q.Executed{world,T.Success{},+rows}: finish_stats_with(~emit,world,run,accumulate(rows,0,0,0,0,0,0,[],[],0),boss_kills(rows),killed_kinds(rows,run_kinds(run)))
    case Q.Executed{_,T.Failure{_},_}: Failed{"ECS query failed"}
type effect_Player is Data: effect_Player{id: U32,run: Run}
type effect_EffectStats is Data: effect_EffectStats{tick: U32,x: F32,y: F32,passives: List<&2,U32>,arcana: U32,hp: U32}
def effect_stats(run: Run) -> effect_EffectStats:
  match run:
    case Run{_,tick,x,y,hp,_,_,_,_,_,_,_,_,passives,_,_,_,arcana,_,_,_,_,_,_,_,_,_,_,_}: effect_EffectStats{tick,x,y,passives,arcana,hp}
def effect_fallback_stats() -> effect_EffectStats: effect_EffectStats{0,0.0,0.0,[],0,0}
def effect_find_stats(players: List<&2,effect_Player>,+id: U32) -> effect_EffectStats:
  match players:
    case []: effect_fallback_stats()
    case effect_Player{+pid,run} <> rest: Bool.pick(effect_EffectStats,U32.is_eq(pid,id),effect_stats(run),effect_find_stats(rest,id))
# Projectile identity selects its immutable originating player, not its current
# nearest target. Low logical-slot bits retain the original spread identity.
def effect_source(snapshots: List<&2,Snapshot>,+shot: U32) -> U32:
  match snapshots:
    case []: 0
    case Snapshot{Body{_,_,_,_,_,_,_,+seed,_},Motion{_,_,_,_,_,_,_,_,slot}} <> rest: Bool.pick(U32,U32.is_eq(seed,shot),(slot / 65536 : U32),effect_source(rest,shot))
# Build once per world tick; shared-world callers use effect_apply_indexed to avoid
# scanning every snapshot for every enemy/projectile pair.
def effect_origin_index(snapshots: List<&2,Snapshot>) -> BI.Index<U32>:
  match snapshots:
    case []: BI.Empty{}
    case Snapshot{Body{_,_,_,_,_,_,_,seed,_},Motion{_,_,_,_,_,_,_,_,slot}} <> rest: BI.insert(~U32,effect_origin_index(rest),seed,(slot / 65536 : U32))
def effect_indexed_source(origins: BI.Index<U32>,shot: U32) -> U32: BI.get(~U32,origins,shot,0)
def effect_burn_duration(+burn: U32) -> U32: (burn % 65536 : U32)
def effect_burn_source(+burn: U32) -> U32: (burn / 65536 : U32)
def effect_pack_burn(+duration: U32,effect_source: U32) -> U32: (duration + 65536 * effect_source * Bool.to_u32(U32.is_lt(0,duration)) : U32)
def effect_cool_burn(+burn: U32) -> U32: effect_pack_burn(dec(effect_burn_duration(burn)),effect_burn_source(burn))
def effect_stronger_burn(+old: U32,+fresh: U32) -> U32:
  Bool.pick(U32,Bool.or(U32.is_lt(effect_burn_duration(old),effect_burn_duration(fresh)),Bool.and(U32.is_eq(effect_burn_duration(old),effect_burn_duration(fresh)),U32.is_lt(effect_burn_source(fresh),effect_burn_source(old)))),fresh,old)
def effect_source_hit(keep: Bool,row: HitPlan,tail: List<&2,HitPlan>) -> List<&2,HitPlan>:
  match keep:
    case True{}: row <> tail
    case False{}: tail
def effect_indexed_hits(rows: List<&2,HitPlan>,+origins: BI.Index<U32>,+id: U32) -> List<&2,HitPlan>:
  match rows:
    case []: []
    case HitPlan{+shot,+weapon,+damage,+x,+y,+radius,+area,+targets} <> rest: effect_source_hit(U32.is_eq(effect_indexed_source(origins,shot),id),HitPlan{shot,weapon,damage,x,y,radius,area,targets},effect_indexed_hits(rest,origins,id))

type effect_Effects is Data: effect_Effects{damage: U32,slow: U32,burn: U32,dx: F32,dy: F32}
def effect_one_effects(+oldX: F32,+oldY: F32,id: U32,collision: Collision,stat: effect_EffectStats) -> effect_Effects:
  match collision stat:
    case Collision{damage,slow,+burn,+pull,+knock,+sumX,+sumY} effect_EffectStats{_,+px,+py,+passives,+arcana,_}:
      effect_Effects{damage,slow,effect_pack_burn((burn * (1 + Bool.to_u32(U32.is_eq(arcana,7))) : U32),id),((oldX - px) / F32.max(1.0,F32.sqrt(distance2(oldX,oldY,px,py))) * U32.to_f32(knock) * (6.0 * (1.0 + U32.to_f32(at(passives,16)) * 0.15 + 0.75 * stat_bonus(arcana,11))) + pull_x(oldX,oldY,sumX,sumY,pull) * U32.to_f32(pull) * (3.0 + 4.0 * stat_bonus(arcana,11)) : F32),((oldY - py) / F32.max(1.0,F32.sqrt(distance2(oldX,oldY,px,py))) * U32.to_f32(knock) * (6.0 * (1.0 + U32.to_f32(at(passives,16)) * 0.15 + 0.75 * stat_bonus(arcana,11))) + pull_y(oldX,oldY,sumX,sumY,pull) * U32.to_f32(pull) * (3.0 + 4.0 * stat_bonus(arcana,11)) : F32)}
def effect_add_effects(left: effect_Effects,right: effect_Effects) -> effect_Effects:
  match left right:
    case effect_Effects{d,s,b,x,y} effect_Effects{d2,s2,b2,x2,y2}: effect_Effects{(d + d2 : U32),U32.max(s,s2),effect_stronger_burn(b,b2),(x + x2 : F32),(y + y2 : F32)}
def effect_gather(players: List<&2,effect_Player>,+hits: List<&2,HitPlan>,+origins: BI.Index<U32>,+oldX: F32,+oldY: F32,+radius: F32,+target: U32,+immune: Bool) -> effect_Effects:
  match players:
    case []: effect_Effects{0,0,0,0.0,0.0}
    case effect_Player{+id,run} <> rest: effect_add_effects(effect_one_effects(oldX,oldY,id,immune_collision(immune,collisions(effect_indexed_hits(hits,origins,id),oldX,oldY,radius,target)),effect_stats(run)),effect_gather(rest,hits,origins,oldX,oldY,radius,target,immune))
def effect_indexed_killer(rows: List<&2,HitPlan>,+origins: BI.Index<U32>,+x: F32,+y: F32,+radius: F32,+target: U32,+hp: U32,+fallback: U32) -> U32:
  match rows:
    case []: fallback
    case HitPlan{+shot,_,+damage,+tx,+ty,+r,+area,+targets} <> rest: Bool.pick(U32,Bool.and(hit_recipient(area,targets,target,x,y,radius,tx,ty,r),U32.is_le(hp,damage)),effect_indexed_source(origins,shot),effect_indexed_killer(rest,origins,x,y,radius,target,Combat.lose(hp,(damage * Bool.to_u32(hit_recipient(area,targets,target,x,y,radius,tx,ty,r)) : U32)),fallback))
def effect_stats_distance(+x: F32,+y: F32,stat: effect_EffectStats) -> F32:
  match stat:
    case effect_EffectStats{_,px,py,_,_,_}: distance2(x,y,px,py)
def effect_stats_living(stat: effect_EffectStats) -> Bool:
  match stat:
    case effect_EffectStats{_,_,_,_,_,hp}: U32.is_lt(0,hp)
def effect_nearest_target(players: List<&2,effect_Player>,+x: F32,+y: F32,+best: effect_EffectStats) -> effect_EffectStats:
  match players:
    case []: best
    case effect_Player{_,+run} <> rest: effect_nearest_target(rest,x,y,Bool.pick(effect_EffectStats,Bool.and(effect_stats_living(effect_stats(run)),Bool.or(Bool.not(effect_stats_living(best)),F32.is_lt(effect_stats_distance(x,y,effect_stats(run)),effect_stats_distance(x,y,best)))),effect_stats(run),best))
def effect_burn_damage(+burn: U32,stat: effect_EffectStats) -> U32:
  match stat:
    case effect_EffectStats{+tick,_,_,_,arcana,_}: ((2 + 2 * Bool.to_u32(U32.is_eq(arcana,7))) * Bool.to_u32(Bool.and(U32.is_lt(0,effect_burn_duration(burn)),U32.is_eq((tick % 30 : U32),0))) : U32)
def effect_effect_luck(stat: effect_EffectStats) -> U32:
  match stat:
    case effect_EffectStats{_,_,_,passives,_,_}: at(passives,10)
def effect_target_x(stat: effect_EffectStats) -> F32:
  match stat:
    case effect_EffectStats{_,x,_,_,_,_}: x
def effect_target_y(stat: effect_EffectStats) -> F32:
  match stat:
    case effect_EffectStats{_,_,y,_,_,_}: y
def effect_apply_resolved(+oldX: F32,+oldY: F32,row: Row,motion: Motion,effects: effect_Effects,+oldBurnDamage: U32,+luck: U32,+target: effect_EffectStats) -> EntityRow:
  match row motion effects:
    case Row{Body{+x,+y,0,+variant,+hp,+maximum,+age,+seed,+radius},_,_,_,_,_,_,_} Motion{_,_,_,_,_,+slow,+burn,_,_} effect_Effects{+damage,+freshSlow,+freshBurn,+dx,+dy}:
      EntityRow{lucky_row(enemy_result(Combat.lose(hp,(damage + oldBurnDamage : U32)),(oldX + (x - oldX) * slow_factor(U32.max(slow,freshSlow)) + dx : F32),(oldY + (y - oldY) * slow_factor(U32.max(slow,freshSlow)) + dy : F32),variant,maximum,age,seed,radius,effect_target_x(target),effect_target_y(target)),luck),Motion{0.0,0.0,0,0,[],U32.max(cool_status(slow),freshSlow),effect_stronger_burn(effect_cool_burn(burn),freshBurn),0,0}}
    case row motion _: EntityRow{row,motion}
def effect_with_killer(id: U32,row: EntityRow) -> EntityRow:
  match row:
    case EntityRow{Row{+body,+hit,+xp,+gold,+heal,+chest,1,+relic},Motion{vx,vy,life,pierce,visited,slow,burn,_,slot}}: EntityRow{Row{body,hit,xp,gold,heal,chest,1,relic},Motion{vx,vy,life,pierce,visited,slow,burn,id,slot}}
    case row: row
def effect_apply_multiple(+players: List<&2,effect_Player>,+oldX: F32,+oldY: F32,row: Row,motion: Motion,+hits: List<&2,HitPlan>,+origins: BI.Index<U32>) -> EntityRow:
  match row motion:
    case Row{Body{+x,+y,0,+variant,+hp,+maximum,+age,+seed,+radius},+hit,+xp,+gold,+heal,+chest,+killed,+relic} Motion{+vx,+vy,+life,+pierce,+visited,+slow,+burn,+owner,+slot}:
      effect_with_killer(effect_indexed_killer(hits,origins,oldX,oldY,radius,seed,hp,effect_burn_source(burn)),effect_apply_resolved(oldX,oldY,Row{Body{x,y,0,variant,hp,maximum,age,seed,radius},hit,xp,gold,heal,chest,killed,relic},immune_motion(U32.is_eq(variant,30),Motion{vx,vy,life,pierce,visited,slow,burn,owner,slot}),effect_gather(players,hits,origins,oldX,oldY,radius,seed,U32.is_eq(variant,30)),effect_burn_damage(burn,effect_find_stats(players,effect_burn_source(burn))),effect_effect_luck(effect_find_stats(players,effect_indexed_killer(hits,origins,oldX,oldY,radius,seed,hp,effect_burn_source(burn)))),effect_nearest_target(players,oldX,oldY,effect_fallback_stats())))
    case row motion: EntityRow{row,motion}
def effect_apply_indexed(+players: List<&2,effect_Player>,+oldX: F32,+oldY: F32,+row: Row,+motion: Motion,+hits: List<&2,HitPlan>,+origins: BI.Index<U32>) -> EntityRow:
  match players row:
    case effect_Player{0,run} <> [] Row{Body{+x,+y,+kind,+variant,+hp,+maximum,+age,+seed,+radius},+hit,+xp,+gold,+heal,+chest,+killed,+relic}: enemy_applied(oldX,oldY,Row{Body{x,y,kind,variant,hp,maximum,age,seed,radius},hit,xp,gold,heal,chest,killed,relic},motion,collisions(hits,oldX,oldY,radius,seed),run)
    case players row: effect_apply_multiple(players,oldX,oldY,row,motion,hits,origins)

type PlayerView is Data: PlayerView{id: U32,run: Run,dx: F32,dy: F32}
type Team is Data: Team{players: List<&2,PlayerView>,base: Args,plan: SP.Plan,origins: BI.Index<U32>}
def add_view(eligible: Bool,view: PlayerView,tail: List<&2,PlayerView>) -> List<&2,PlayerView>:
  match eligible:
    case True{}: view <> tail
    case False{}: tail
def run_phase(run: Run) -> U32:
  match run:
    case Run{phase,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: phase
def run_tick(run: Run) -> U32:
  match run:
    case Run{_,tick,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: tick
def run_px(run: Run) -> F32:
  match run:
    case Run{_,_,px,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: px
def run_py(run: Run) -> F32:
  match run:
    case Run{_,_,_,py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: py
def run_hp(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,hp,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: hp
def run_maxHp(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,maxHp,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: maxHp
def run_xp(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,xp,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: xp
def run_xpNeed(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,xpNeed,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: xpNeed
def run_level(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,level,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: level
def run_kills(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,kills,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: kills
def run_gold(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,gold,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: gold
def run_character(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,character,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: character
def run_weapons(run: Run) -> List<&2,U32>:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,weapons,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: weapons
def run_passives(run: Run) -> List<&2,U32>:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,passives,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: passives
def run_invuln(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,invuln,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: invuln
def run_seed(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,seed,_,_,_,_,_,_,_,_,_,_,_,_,_}: seed
def run_stage(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,stage,_,_,_,_,_,_,_,_,_,_,_,_}: stage
def run_arcana(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,arcana,_,_,_,_,_,_,_,_,_,_,_}: arcana
def run_meta(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,meta,_,_,_,_,_,_,_,_,_,_}: meta
def run_revivals(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,revivals,_,_,_,_,_,_,_,_,_}: revivals
def run_bosses(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,bosses,_,_,_,_,_,_,_,_}: bosses
def run_mode(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,mode,_,_,_,_,_,_,_}: mode
def run_rerolls(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,rerolls,_,_,_,_,_,_}: rerolls
def run_banishes(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,banishes,_,_,_,_,_}: banishes
def run_skips(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,skips,_,_,_,_}: skips
def run_bannedWeapons(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,bannedWeapons,_,_,_}: bannedWeapons
def run_bannedPassives(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,bannedPassives,_,_}: bannedPassives
def run_enemyKinds(run: Run) -> List<&2,U32>:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,enemyKinds,_}: enemyKinds
def run_relicCollected(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,relicCollected}: relicCollected
def with_phase(run: Run,value: U32) -> Run:
  match run:
    case Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{value,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_tick(run: Run,value: U32) -> Run:
  match run:
    case Run{+phase,_,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,value,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_xp(run: Run,value: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,_,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,py,hp,maxHp,value,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_xpNeed(run: Run,value: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,_,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,py,hp,maxHp,xp,value,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_level(run: Run,value: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,_,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,value,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_gold(run: Run,value: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,_,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,value,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_seed(run: Run,value: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,_,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,value,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_hp(run: Run,value: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,_,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,py,value,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_invuln(run: Run,value: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,_,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,value,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_revivals(run: Run,value: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,_,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,value,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_px(run: Run,value: F32) -> Run:
  match run:
    case Run{+phase,+tick,_,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,value,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_py(run: Run,value: F32) -> Run:
  match run:
    case Run{+phase,+tick,+px,_,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,value,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_relicCollected(run: Run,value: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,_}: Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,value}
def view_run(view: PlayerView) -> Run:
  match view:
    case PlayerView{_,run,_,_}: run
def first_view(views: List<&2,PlayerView>,fallback: Run) -> PlayerView:
  match views:
    case []: PlayerView{0,fallback,0.0,0.0}
    case +first <> rest: Bool.pick(PlayerView,U32.is_lt(0,run_hp(view_run(first))),first,first_view(rest,fallback))
def view_id(view: PlayerView) -> U32:
  match view:
    case PlayerView{id,_,_,_}: id
def view_args(view: PlayerView,base: Args) -> Args:
  match view base:
    case PlayerView{_,run,dx,dy} Args{_,bodies,_,_,snapshots,hits}: Args{run,bodies,dx,dy,snapshots,hits}
def nearest_view(views: List<&2,PlayerView>,+x: F32,+y: F32,+best: PlayerView) -> PlayerView:
  match views:
    case []: best
    case +candidate <> rest: nearest_view(rest,x,y,Bool.pick(PlayerView,PickupPolicy.prefer(run_hp(view_run(candidate)),run_hp(view_run(best)),distance2(x,y,run_px(view_run(candidate)),run_py(view_run(candidate))),distance2(x,y,run_px(view_run(best)),run_py(view_run(best))),view_id(candidate),view_id(best)),candidate,best))
def team_nearest(+team: Team,+x: F32,+y: F32) -> PlayerView:
  match team:
    case Team{+players,Args{run,_,_,_,_,_},_,origins}: nearest_view(players,x,y,first_view(players,run))
def team_view_id(views: List<&2,PlayerView>,+id: U32,fallback: PlayerView) -> PlayerView:
  match views:
    case []: fallback
    case +view <> rest: Bool.pick(PlayerView,U32.is_eq(view_id(view),id),view,team_view_id(rest,id,fallback))
def team_for_id(+team: Team,id: U32) -> PlayerView:
  match team:
    case Team{+players,Args{run,_,_,_,_,_},_,origins}: team_view_id(players,id,first_view(players,run))
def team_base(team: Team) -> Args:
  match team:
    case Team{_,base,_,origins}: base
def team_args(+team: Team,view: PlayerView) -> Args: view_args(view,team_base(team))
def pickup_eligible(+x: F32,+y: F32,view: PlayerView) -> Bool:
  match view:
    case PlayerView{_,+run,_,_}: PickupPolicy.living_contact(run_hp(run),close(x,y,run_px(run),run_py(run),pickup_radius(run_passives(run),run_meta(run),run_arcana(run),run_character(run))))
def pickup_candidates(views: List<&2,PlayerView>,+x: F32,+y: F32) -> List<&2,PlayerView>:
  match views:
    case []: []
    case +view <> rest: add_view(pickup_eligible(x,y,view),view,pickup_candidates(rest,x,y))
def collector_ready(+team: Team,+x: F32,+y: F32,+candidates: List<&2,PlayerView>) -> PlayerView:
  nearest_view(candidates,x,y,first_view(candidates,view_run(team_nearest(team,x,y))))
def collector(+team: Team,+x: F32,+y: F32) -> PlayerView:
  match team:
    case Team{players,_,_,_}: collector_ready(team,x,y,pickup_candidates(players,x,y))
def own_snapshot(row: Snapshot,+id: U32,+tail: List<&2,Snapshot>) -> List<&2,Snapshot>:
  match row:
    case Snapshot{+body,Motion{+vx,+vy,+life,+pierce,+visited,+slow,+burn,+owner,+slot}}: Bool.pick(List<&2,Snapshot>,U32.is_eq((slot / 65536 : U32),id),Snapshot{body,Motion{vx,vy,life,pierce,visited,slow,burn,owner,(slot % 65536 : U32)}} <> tail,tail)
def own_snapshots(rows: List<&2,Snapshot>,+id: U32) -> List<&2,Snapshot>:
  match rows:
    case []: []
    case +row <> rest: own_snapshot(row,id,own_snapshots(rest,id))
def parity_slots(rows: List<&2,U32>,+id: U32) -> List<&2,U32>:
  match rows:
    case []: []
    case +seed <> rest: free_slot(U32.is_eq((seed % 2 : U32),id),seed,parity_slots(rest,id))
def assigned_plan(+id: U32,+run: Run,inventory: ShotInventory) -> SP.Plan:
  match inventory:
    case ShotInventory{occupied,counts,locks}: SP.allocate(parity_slots(free_shot_slots(U32.to_nat(PL.player_count()),PL.player_start(),occupied),id),counts,PL.caps(),shot_requests(24n,(run_tick(run) % PL.owner_count() : U32),run,locks))
def merge_assignments(index: BI.Index<SP.Request>,+id: U32,into: BI.Index<SP.Request>) -> BI.Index<SP.Request>:
  match index:
    case BI.Empty{}: into
    case BI.Item{seed,SP.Request{owner,slot,level}}: BI.insert(~SP.Request,into,seed,SP.Request{owner,(slot + id * 65536 : U32),level})
    case BI.Fork{_,_,zero,one}: merge_assignments(one,id,merge_assignments(zero,id,into))
def merge_player_plan(+id: U32,plan: SP.Plan,tail: SP.Plan) -> SP.Plan:
  match plan tail:
    case SP.Plan{index,count} SP.Plan{into,other}: SP.Plan{merge_assignments(index,id,into),(count + other : U32)}
def player_plan(view: PlayerView,snapshots: List<&2,Snapshot>) -> SP.Plan:
  match view:
    case PlayerView{+id,run,_,_}: assigned_plan(id,run,shot_inventory(own_snapshots(snapshots,id),ShotInventory{BI.Empty{},empty_owner_counts(),empty_owner_counts()}))
def team_plan_all(views: List<&2,PlayerView>,+snapshots: List<&2,Snapshot>) -> SP.Plan:
  match views:
    case []: empty_shot_plan()
    case +view <> rest: merge_player_plan(view_id(view),player_plan(view,snapshots),team_plan_all(rest,snapshots))

# Logical spread slot uses its high 16 bits for stable player identity. Physical
# projectile IDs and weapon IDs remain independent and retain solo encodings.
def team_shot_spawn(+team: Team,+seed: U32,request: Maybe<&2,SP.Request>) -> EntityRow:
  match request:
    case None{}: dormant_entity(0.0,0.0,seed)
    case Some{SP.Request{+owner,+slot,level}}: with_shot_owner(shot_spawn_ready(True{},seed,owner,(slot % 65536 : U32),level,team_args(team,team_for_id(team,(slot / 65536 : U32)))),owner,slot)
def team_shot_alive(alive: Bool,+team: Team,+body: Body,+motion: Motion,+seed: U32,+owner: U32,+slot: U32,+plan: SP.Plan) -> EntityRow:
  match alive body:
    case False{} _: team_shot_spawn(team,seed,SP.lookup(plan,seed))
    case True{} Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}: with_shot_owner(shot_step_aim(Body{x,y,kind,variant,hp,maxHp,age,seed,radius},motion,team_args(team,team_for_id(team,(slot / 65536 : U32))),nearest_from_args(team_base(team),x,y)),owner,slot)
def team_shot(team: Team,body: Body,trajectory: Trajectory) -> EntityRow:
  match team body trajectory:
    case Team{players,base,+plan,origins} Body{+x,+y,1,+variant,+hp,+maximum,+age,+seed,+radius} Trajectory{+vx,+vy,+life,+pierce,+visited,+owner,+slot}: team_shot_alive(Bool.and(U32.is_lt(0,life),U32.is_lt(0,pierce)),Team{players,base,plan,origins},Body{x,y,1,variant,hp,maximum,age,seed,radius},Motion{vx,vy,life,pierce,visited,0,0,owner,slot},seed,owner,slot,plan)
    case Team{players,base,+plan,origins} Body{_,_,_,_,_,_,_,+seed,_} _: team_shot_spawn(Team{players,base,plan,origins},seed,SP.lookup(plan,seed))
def team_projectile_role(role: Role.Role,+team: Team,+body: Body,trajectory: Trajectory) -> EntityRow:
  match role body:
    case Role.PlayerProjectileSlot{} body: team_shot(team,body,trajectory)
    case Role.HostileProjectileSlot{} Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}: hostile_step(Body{x,y,kind,variant,hp,maxHp,age,seed,radius},logical_motion(trajectory,empty_status()),team_args(team,team_nearest(team,x,y)))
    case _ _: missing_row()
def team_projectile_trajectory(~H: Type,~ops: ProjectileOps<H>,role: Role.Role,team: Team,body: Body,result: H & C.Access<Trajectory>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{trajectory}): projectile_write(~H,~ops,ctx,team_projectile_role(role,team,body,trajectory))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def team_projectile_body(~H: Type,~ops: ProjectileOps<H>,role: Role.Role,team: Team,result: H & C.Access<Body>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{body}): team_projectile_trajectory(~H,~ops,role,team,body,Cap.get(~H,~Trajectory,~Trajectory,~projectile_trajectory_cap(~H,ops),ctx))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def team_projectile_observed(~H: Type,~ops: ProjectileOps<H>,team: Team,result: H & C.Access<Role.Role>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{role}): team_projectile_body(~H,~ops,role,team,Cap.get(~H,~Body,~Body,~projectile_body_cap(~H,ops),ctx))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def team_projectile_system(~H: Type,~ops: ProjectileOps<H>,team: Team,ctx: H) -> H & (T.Outcome<Error> & EntityRow): team_projectile_observed(~H,~ops,team,Cap.read(~H,~Role.Role,~projectile_role_cap(~H,ops),ctx))
def team_move_status(~H: Type,~ops: MoveOps<H>,+team: Team,body: Body,result: H & C.Access<Status>) -> H & (T.Outcome<Error> & Unit):
  match body result:
    case Body{+x,+y,+kind,+variant,+hp,+maximum,+age,+seed,+radius} Tuple{ctx,C.Found{status}}: (Cap.set(~H,~Body,~Body,~move_body_cap(~H,ops),ctx,move_body(Body{x,y,kind,variant,hp,maximum,age,seed,radius},logical_motion(empty_trajectory(),status),team_args(team,team_nearest(team,x,y)))),(T.Success{},Unit{}))
    case _ Tuple{ctx,_}: (ctx,(T.Failure{MissingBody{}},Unit{}))
def team_move_body(~H: Type,~ops: MoveOps<H>,team: Team,result: H & C.Access<Body>) -> H & (T.Outcome<Error> & Unit):
  match result:
    case (ctx,C.Found{body}): team_move_status(~H,~ops,team,body,Cap.read(~H,~Status,~move_status_cap(~H,ops),ctx))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},Unit{}))
def team_move_system(~H: Type,~ops: MoveOps<H>,team: Team,ctx: H) -> H & (T.Outcome<Error> & Unit): team_move_body(~H,~ops,team,Cap.get(~H,~Body,~Body,~move_body_cap(~H,ops),ctx))

def team_spawn_view(+team: Team,+id: U32) -> PlayerView:
  +candidate = team_for_id(team,id)
  Bool.pick(PlayerView,U32.is_lt(0,run_hp(view_run(candidate))),candidate,team_nearest(team,run_px(view_run(candidate)),run_py(view_run(candidate))))
def team_body_view(+team: Team,body: Body) -> PlayerView:
  match body:
    case Body{+x,+y,8,_,_,_,_,+seed,_}: team_spawn_view(team,(seed % 2 : U32))
    case Body{+x,+y,0,_,_,_,_,_,_}: team_nearest(team,x,y)
    case Body{+x,+y,_,_,_,_,_,_,_}: collector(team,x,y)
def moved_run(view: PlayerView) -> Run:
  match view:
    case PlayerView{_,+run,+dx,+dy}: with_py(with_px(run,F32.clamp((run_px(run) + dx * (2.5 * speed_bonus(run_passives(run),run_meta(run),run_arcana(run),run_character(run)) : F32) / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),A.player_min(),A.player_max())),F32.clamp((run_py(run) + dy * (2.5 * speed_bonus(run_passives(run),run_meta(run),run_arcana(run),run_character(run)) : F32) / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),A.player_min(),A.player_max()))
def outside_players(views: List<&2,PlayerView>,+x: F32,+y: F32,+radius: F32) -> Bool:
  match views:
    case []: True{}
    case +view <> rest: Bool.and(Bool.or(U32.is_eq(run_hp(view_run(view)),0),S.admissible(x,y,run_px(moved_run(view)),run_py(moved_run(view)),radius)),outside_players(rest,x,y,radius))
def spawn_gate(allowed: Bool,previous: Body,row: EntityRow) -> EntityRow:
  match allowed:
    case True{}: row
    case False{}: EntityRow{Row{previous,0,0,0,0,0,0,0},empty_motion()}
def team_spawn_fresh(fresh: Bool,team: Team,+previous: Body,+result: EntityRow) -> EntityRow:
  match fresh team result:
    case False{} _ _: result
    case True{} Team{views,_,_,_} EntityRow{Row{Body{x,y,_,_,_,_,_,_,radius},_,_,_,_,_,_,_},_}: spawn_gate(outside_players(views,x,y,radius),previous,result)
def team_spawn_gate(+team: Team,+previous: Body,+result: EntityRow) -> EntityRow:
  match previous result:
    case Body{_,_,previousKind,_,_,_,previousAge,_,_} EntityRow{Row{Body{_,_,kind,_,_,_,age,_,_},_,_,_,_,_,_,_},_}: team_spawn_fresh(SL.fresh_transition(SL.is_newborn(previousKind,previousAge),SL.is_newborn(kind,age)),team,previous,result)
def effect_players(views: List<&2,PlayerView>) -> List<&2,effect_Player>:
  match views:
    case []: []
    case PlayerView{id,run,_,_} <> rest: effect_Player{id,run} <> effect_players(rest)
def team_enemy_applied(+team: Team,oldX: F32,oldY: F32,motion: Motion,routed: SL.Routed<Row>) -> EntityRow:
  match team routed:
    case _ SL.Fresh{row}: newborn_entity(SL.newborn(~Row,~Motion,row,empty_motion()))
    case Team{players,Args{_,_,_,_,_,hits},_,origins} SL.Existing{row}: effect_apply_indexed(effect_players(players),oldX,oldY,row,motion,hits,origins)
def team_enemy_updated(+team: Team,+body: Body,status: Status,+row: Row) -> EntityRow:
  match body row:
    case Body{oldX,oldY,previousKind,_,_,_,previousAge,_,_} Row{Body{_,_,kind,_,_,_,age,_,_},_,_,_,_,_,_,_}: team_enemy_applied(team,oldX,oldY,logical_motion(empty_trajectory(),status),SL.route(~Row,previousKind,previousAge,kind,age,row))
def team_enemy_role(role: Role.Role,+team: Team,+body: Body,status: Status) -> EntityRow:
  match role:
    case Role.RelicSlot{}: relic_entity(team_args(team,team_body_view(team,body)))
    case _: team_spawn_gate(team,body,team_enemy_updated(team,body,status,update(body,view_run(team_body_view(team,body)))))
def team_enemy_status(~H: Type,~ops: Ops<H>,role: Role.Role,+team: Team,body: Body,result: H & C.Access<Status>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{status}): write_row(~H,~ops,ctx,team_enemy_role(role,team,body,status))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def team_enemy_vitals(~H: Type,~ops: Ops<H>,role: Role.Role,team: Team,body: Body,result: H & C.Access<Vitals>) -> H & (T.Outcome<Error> & EntityRow):
  match body result:
    case Body{+x,+y,+kind,+variant,_,_,+age,+seed,+radius} Tuple{ctx,C.Found{Vitals{health,maximum}}}: team_enemy_status(~H,~ops,role,team,Body{x,y,kind,variant,health,maximum,age,seed,radius},Cap.get(~H,~Status,~Status,~status_cap(~H,ops),ctx))
    case _ Tuple{ctx,_}: (ctx,(T.Failure{MissingBody{}},missing_row()))
def team_enemy_body(~H: Type,~ops: Ops<H>,role: Role.Role,team: Team,result: H & C.Access<Body>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{body}): team_enemy_vitals(~H,~ops,role,team,body,Cap.get(~H,~Vitals,~Vitals,~vital_cap(~H,ops),ctx))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
type TeamEnemy is Data: TeamEnemy{role: Role.Role,team: Team}
def team_enemy_system(~H: Type,~ops: Ops<H>,call: TeamEnemy,ctx: H) -> H & (T.Outcome<Error> & EntityRow):
  match call:
    case TeamEnemy{role,team}: team_enemy_body(~H,~ops,role,team,Cap.read(~H,~Body,~body_cap(~H,ops),ctx))
def team_pickup_payload(~H: Type,+team: Team,+body: Body,result: H & C.Access<Pickup>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{pickup}): (ctx,(T.Success{},xp_entity(pickup_body(body,pickup),team_args(team,team_body_view(team,body)))))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def team_pickup_body(~H: Type,~ops: PickupOps<H>,team: Team,result: H & C.Access<Body>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{body}): team_pickup_payload(~H,team,body,Cap.read(~H,~Pickup,~pickup_payload_cap(~H,ops),ctx))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def team_pickup_system(~H: Type,~ops: PickupOps<H>,team: Team,ctx: H) -> H & (T.Outcome<Error> & EntityRow): team_pickup_body(~H,~ops,team,Cap.read(~H,~Body,~pickup_body_cap(~H,ops),ctx))
def team_pool_role(~H: Type,~ops: PoolOps<H>,team: Team,result: H & C.Access<Role.Role>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{Role.XpSlot{}}): Cap.invoke(~PickupOpsType,~Team,~(T.Outcome<Error> & EntityRow),~team_pickup_system,~H,~pool_pickup_caps(~H,ops),team,ctx)
    case (ctx,C.Found{role}): Cap.invoke(~OpsType,~TeamEnemy,~(T.Outcome<Error> & EntityRow),~team_enemy_system,~H,~pool_enemy_caps(~H,ops),TeamEnemy{role,team},ctx)
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def team_pool_system(~H: Type,~ops: PoolOps<H>,team: Team,ctx: H) -> H & (T.Outcome<Error> & EntityRow): team_pool_role(~H,~ops,team,Cap.read(~H,~Role.Role,~pool_role_cap(~H,ops),ctx))
def team_combat_done(+team: Team,projectiles: List<&2,EntityRow>,result: Q.Executed<World(),Q.Error<Error>,EntityRow>) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},rows}: xp_lifecycle(projectiles,xp_route_args(rows,team_base(team)),world)
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
def team_moved(+team: Team,projectiles: List<&2,EntityRow>,result: Q.Executed<World(),Q.Error<Error>,Unit>) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},_}: team_combat_done(team,projectiles,candidate_query(~PoolOpsType,~Team,~EntityRow,~plan(),~team_pool_system,False{},team,world))
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
def team_movement_scoped(+team: Team,world: World(),roster: MovementRoster) -> Q.Executed<World(),Q.Error<Error>,Unit>:
  match roster:
    case MovementPrepared{handles}: Q.reserved(~Schema,~Store,~Unit,~Unit,~MoveOpsType,~Team,~Error,~Unit,~move_plan(),~team_move_system,team,None{},(world,handles))
def team_movement_opened(team: Team,result: World() & MovementRoster) -> Q.Executed<World(),Q.Error<Error>,Unit>:
  match result:
    case (world,roster): team_movement_scoped(team,world,roster)
def team_projectiles_done(+team: Team,result: Q.Executed<World(),Q.Error<Error>,EntityRow>) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},rows}: team_moved(team,rows,team_movement_opened(team,W.with_store(~Schema,~Store,~Unit,~Unit,~MovementRoster,movement_roster_read,world)))
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
def team_execute(world: World(),+team: Team) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  team_projectiles_done(team,candidate_query(~ProjectileOpsType,~Team,~EntityRow,~projectile_plan(),~team_projectile_system,True{},team,world))

def living_views(views: List<&2,PlayerView>) -> List<&2,PlayerView>:
  match views:
    case []: []
    case +view <> rest: add_view(U32.is_lt(0,run_hp(view_run(view))),view,living_views(rest))
def full_player_inventory(+id: U32,+run: Run,all: ShotInventory,own: ShotInventory) -> SP.Plan:
  match all own:
    case ShotInventory{occupied,_,_} ShotInventory{_,counts,locks}: merge_player_plan(id,SP.allocate(free_shot_slots(U32.to_nat(PL.player_count()),PL.player_start(),occupied),counts,PL.caps(),shot_requests(24n,(run_tick(run) % PL.owner_count() : U32),run,locks)),empty_shot_plan())
def full_player_plan(view: PlayerView,+snapshots: List<&2,Snapshot>) -> SP.Plan:
  match view:
    case PlayerView{+id,run,_,_}: full_player_inventory(id,run,shot_inventory(snapshots,ShotInventory{BI.Empty{},empty_owner_counts(),empty_owner_counts()}),shot_inventory(own_snapshots(snapshots,id),ShotInventory{BI.Empty{},empty_owner_counts(),empty_owner_counts()}))
def plan_living(views: List<&2,PlayerView>,+snapshots: List<&2,Snapshot>) -> SP.Plan:
  match views:
    case []: empty_shot_plan()
    case view <> []: full_player_plan(view,snapshots)
    case views: team_plan_all(views,snapshots)
def team_plan(views: List<&2,PlayerView>,snapshots: List<&2,Snapshot>) -> SP.Plan: plan_living(living_views(views),snapshots)

def solo_team(+args: Args) -> Team:
  match args:
    case Args{+run,_,+dx,+dy,+snapshots,_}: Team{[PlayerView{0,run,dx,dy}],args,prepare_shot_plan(args),effect_origin_index(snapshots)}
def execute(world: World(),+args: Args) -> Q.Executed<World(),Q.Error<Error>,EntityRow>: team_execute(world,solo_team(args))
def advance_raw_with(~emit: State -> Packet,state: State,+dx: F32,+dy: F32) -> Packet:
  match state:
    case State{world,Run{0,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+snapshot,_,+snapshots,pending}:
      executed_with(~emit,Run{0,(tick + 1 : U32),F32.clamp((px + dx * (2.5 * speed_bonus(passives,meta,arcana,character) : F32) / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),A.player_min(),A.player_max()),F32.clamp((py + dy * (2.5 * speed_bonus(passives,meta,arcana,character) : F32) / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),A.player_min(),A.player_max()),hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},execute(world,combat_args(Run{0,(tick + 1 : U32),px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},snapshot,dx,dy,snapshots)))
    case state: emit(state)
def started_with(~emit: State -> Packet,+character: U32,+meta: U32,created: W.Creation<Schema,Store,Unit,Unit>) -> Packet:
  match created:
    case W.Created{_,world}: emit(State{prepare_movement_roster(W.barrier(~Schema,~Store,~Unit,~Unit,boot_pool(PL.total_nat(),0,world))),Run{0,0,A.center(),A.center(),(initial_health(character,meta) * 70 / 100 : U32),(initial_health(character,meta) * 70 / 100 : U32),0,20,1,0,0,character,bump([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],starter(character)),[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],0,12345,0,0,meta,0,0,0,3,3,3,0,0,[],0},[],[],[],[]})
    case W.CreateRejected{_,_}: Failed{"World creation refused"}
def started(character: U32,meta: U32,created: W.Creation<Schema,Store,Unit,Unit>) -> Packet: started_with(~packet,character,meta,created)
def start_with(~emit: State -> Packet,character: U32,meta: U32) -> Packet: started_with(~emit,U32.min(character,7),meta,W.create(~Schema,~Store,~Unit,~Unit,~empty,W.factory(),Unit{}))

def start(character: U32,meta: U32) -> Packet: start_with(~packet,character,meta)
def seeded_run(run: Run,+selectedSeed: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,_,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,selectedSeed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def seeded_packet_with(~emit: State -> Packet,packetValue: Packet,+selectedSeed: U32) -> Packet:
  match packetValue:
    case Packet{State{world,run,bodies,offers,snapshots,pending},_}: emit(State{world,seeded_run(run,selectedSeed),bodies,offers,snapshots,pending})
    case Failed{error}: Failed{error}
def start_seed_with(~emit: State -> Packet,character: U32,meta: U32,seed: U32) -> Packet: seeded_packet_with(~emit,start_with(~emit,character,meta),seed)

def start_seed(character: U32,meta: U32,seed: U32) -> Packet: start_seed_with(~packet,character,meta,seed)
def mode_configured(run: Run,+selected: U32) -> Run:
  match run:
    case Run{+phase,0,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: configured(Run{phase,0,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,choose_id(U32.is_eq(selected,3),0,meta),revivals,bosses,U32.min(selected,3),rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},stage,arcana)
    case run: run
def set_mode_with(~emit: State -> Packet,state: State,+selected: U32) -> Packet:
  match state:
    case State{world,Run{+phase,0,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: emit(State{world,mode_configured(Run{phase,0,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},selected),bodies,offers,snapshots,pending})
    case state: emit(state)
def set_mode(state: State,mode: U32) -> Packet: set_mode_with(~packet,state,mode)
def configure_unlocks_with(~emit: State -> Packet,state: State,+unlockedMask: U32) -> Packet:
  match state:
    case State{world,Run{+phase,0,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: emit(State{world,Run{phase,0,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,U32.or(bannedWeapons,U32.and(16777215,U32.xor(unlockedMask,16777215))),bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case state: emit(state)

def configure_unlocks(state: State,mask: U32) -> Packet: configure_unlocks_with(~packet,state,mask)
def reroll_seed(seed: U32) -> U32: (seed + 41 : U32)
def reroll(state: State) -> Packet:
  match state:
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,0,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,Run{1,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,0,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,_,+snapshots,pending}: packet(State{world,Run{1,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,reroll_seed(seed),stage,arcana,meta,revivals,bosses,mode,dec(rerolls),banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,filter_offers(make_offers(reroll_seed(seed),weapons,passives),bannedWeapons,bannedPassives),snapshots,pending})
    case state: packet(state)

def skip_raw(state: State) -> Packet:
  match state:
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,0,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,Run{1,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,0,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,_,+snapshots,pending}: packet(State{world,Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,(gold + 10 : U32),character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,dec(skips),bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,[],snapshots,pending})
    case state: packet(state)

def banish_offer(run: Run,offer: Offer) -> Run:
  match run offer:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected} Offer{0,+id,_}: Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,dec(banishes),skips,U32.or(bannedWeapons,U32.shln(1,U32.to_nat(id))),bannedPassives,enemyKinds,relicCollected}
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected} Offer{1,+id,_}: Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,dec(banishes),skips,bannedWeapons,U32.or(bannedPassives,U32.shln(1,U32.to_nat(id))),enemyKinds,relicCollected}
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected} _: Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}

def banish_raw(state: State,+choice: U32) -> Packet:
  match state:
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,0,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,Run{1,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,0,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,banish_offer(Run{1,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},offer_at(offers,U32.min(choice,2))),bodies,[],snapshots,pending})
    case state: packet(state)

# Deferred rewards are owned by the game state. The advance entry pauses;
# advance_live lets a host keep the arena running until the player opens a choice.
def pending_append(rows: List<&2,U32>,+kind: U32) -> List<&2,U32>:
  match rows:
    case []: [kind]
    case head <> rest: head <> pending_append(rest,kind)
def pending_add(active: Bool,rows: List<&2,U32>,kind: U32) -> List<&2,U32>:
  match active:
    case True{}: pending_append(rows,kind)
    case False{}: rows
def pending_join(left: List<&2,U32>,+right: List<&2,U32>) -> List<&2,U32>:
  match left:
    case []: right
    case head <> rest: head <> pending_join(rest,right)
def terminal_queue(terminal: Bool,pending: List<&2,U32>) -> List<&2,U32>:
  match terminal:
    case True{}: []
    case False{}: pending
# Native consumers keep typed state; presentation serializes only the final packet.
def quiet_packet(state: State) -> Packet: Packet{state,""}
def attach_pending_with(~emit: State -> Packet,result: Packet,pending: List<&2,U32>) -> Packet:
  match result:
    case Packet{State{world,+run,bodies,offers,snapshots,newPending},_}: emit(State{world,run,bodies,offers,snapshots,terminal_queue(U32.is_le(3,run_phase(run)),pending_join(pending,newPending))})
    case result: result
def advance(state: State,dx: F32,dy: F32) -> Packet:
  match state:
    case State{world,run,bodies,offers,snapshots,+pending}: attach_pending_with(~packet,advance_raw_with(~quiet_packet,State{world,run,bodies,offers,snapshots,[]},dx,dy),pending)
def advance_quiet(state: State,dx: F32,dy: F32) -> Packet:
  match state:
    case State{world,run,bodies,offers,snapshots,+pending}: attach_pending_with(~quiet_packet,advance_raw_with(~quiet_packet,State{world,run,bodies,offers,snapshots,[]},dx,dy),pending)
def reward_offers(run: Run,chest: Bool) -> List<&2,Offer>:
  match run:
    case Run{_,_,_,_,_,_,_,_,+level,_,_,_,+weapons,+passives,_,+seed,_,_,_,_,_,_,_,_,_,+bannedWeapons,+bannedPassives,_,_}: filter_offers(phase_offers(chest,(seed + level * 13 : U32),weapons,passives),bannedWeapons,bannedPassives)
def promote_ready_with(~emit: State -> Packet,ready: Bool,world: World(),+run: Run,bodies: List<&2,Body>,offers: List<&2,Offer>,snapshots: List<&2,Snapshot>,pending: List<&2,U32>) -> Packet:
  match ready pending:
    case True{} +kind <> rest: emit(State{world,with_phase(run,kind),bodies,reward_offers(run,U32.is_eq(kind,2)),snapshots,rest})
    case _ pending: emit(State{world,run,bodies,offers,snapshots,pending})
def promote_with(~emit: State -> Packet,result: Packet) -> Packet:
  match result:
    case Packet{State{world,+run,bodies,offers,snapshots,pending},_}: promote_ready_with(~emit,U32.is_eq(run_phase(run),0),world,run,bodies,offers,snapshots,pending)
    case result: result
def promote(result: Packet) -> Packet: promote_with(~packet,result)
def choose(state: State,choice: U32) -> Packet: promote(choose_raw(state,choice))
def skip(state: State) -> Packet: promote(skip_raw(state))
def banish(state: State,choice: U32) -> Packet: promote(banish_raw(state,choice))
def live_selected_with(~emit: State -> Packet,terminal: Bool,held: Bool,+oldPhase: U32,+oldLevel: U32,oldOffers: List<&2,Offer>,pending: List<&2,U32>,world: World(),+run: Run,bodies: List<&2,Body>,offers: List<&2,Offer>,snapshots: List<&2,Snapshot>) -> Packet:
  match terminal held:
    case True{} _: emit(State{world,run,bodies,[],snapshots,[]})
    case False{} True{}: emit(State{world,with_phase(run,oldPhase),bodies,oldOffers,snapshots,pending_add(Bool.or(U32.is_eq(run_phase(run),1),U32.is_eq(run_phase(run),2)),pending,run_phase(run))})
    case False{} False{}: emit(State{world,run,bodies,offers,snapshots,pending})
def live_result_with(~emit: State -> Packet,+oldPhase: U32,+oldLevel: U32,oldOffers: List<&2,Offer>,pending: List<&2,U32>,result: Packet) -> Packet:
  match result:
    case Packet{State{world,+run,bodies,+offers,snapshots,newPending},_}: live_selected_with(~emit,Bool.or(U32.is_eq(run_phase(run),3),U32.is_eq(run_phase(run),4)),Bool.or(U32.is_eq(oldPhase,1),U32.is_eq(oldPhase,2)),oldPhase,oldLevel,oldOffers,pending_join(pending,newPending),world,run,bodies,offers,snapshots)
    case result: result
def advance_live_with(~emit: State -> Packet,state: State,dx: F32,dy: F32) -> Packet:
  match state:
    case State{world,+run,bodies,+offers,snapshots,pending}: live_result_with(~emit,run_phase(run),run_level(run),offers,pending,advance_raw_with(~quiet_packet,State{world,with_phase(run,choose_id(Bool.or(U32.is_eq(run_phase(run),1),U32.is_eq(run_phase(run),2)),0,run_phase(run))),bodies,offers,snapshots,[]},dx,dy))

def advance_live(state: State,dx: F32,dy: F32) -> Packet: advance_live_with(~packet,state,dx,dy)
def advance_live_quiet(state: State,dx: F32,dy: F32) -> Packet: advance_live_with(~quiet_packet,state,dx,dy)

# Typed consumers omit presentation frames at every initialization/upgrade finish.
def start_quiet(character: U32,meta: U32) -> Packet: start_with(~quiet_packet,character,meta)
def start_seed_quiet(character: U32,meta: U32,seed: U32) -> Packet: start_seed_with(~quiet_packet,character,meta,seed)
def configure_quiet(state: State,stage: U32,arcana: U32) -> Packet: configure_with(~quiet_packet,state,stage,arcana)
def set_mode_quiet(state: State,mode: U32) -> Packet: set_mode_with(~quiet_packet,state,mode)
def configure_unlocks_quiet(state: State,mask: U32) -> Packet: configure_unlocks_with(~quiet_packet,state,mask)
def choose_quiet(state: State,choice: U32) -> Packet: promote_with(~quiet_packet,choose_raw_with(~quiet_packet,state,choice))

def xp_visual_radius(amount: U32) -> F32: LV.radius(amount)

def xp_pile_color(amount: U32,variant: U32) -> U32: LV.pile_color(amount,U32.is_eq(variant,1))
