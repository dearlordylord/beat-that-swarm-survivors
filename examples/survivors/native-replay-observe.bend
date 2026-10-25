import run-state.bend as RS
import Base
import game.bend as G
import pools.bend as PL
import entity-role.bend as GRole
import bendvy-ecs-core@0.1.0.1/world.bend as W
import bendvy-ecs-core@0.1.0.1/column.bend as Col
import bendvy-ecs-core@0.1.0.1/lifecycle.bend as L
import bendvy-ecs-core@0.1.0.1/change_tick.bend as Tick
import bendvy-ecs-core@0.1.0.1/clock_state.bend as Clock
import bendvy-ecs-core@0.1.0.1/entity_allocator.bend as A
import bendvy-ecs-core@0.1.0.1/entity_key.bend as K
import bendvy-ecs-core@0.1.0.1/deferred_command.bend as Deferred

# Development-only exact observer. It returns the same affine owners.
# Every float is its raw U32 bit pattern; lifecycle metadata is not normalized.
def fbits(value: F32) -> String: U32.show(F32.bits(value))
def join(rows: List<&2,String>) -> String:
  match rows:
    case []: ""
    case value <> []: value
    case value <> rest: value ++ "," ++ join(rest)
def array(rows: List<&2,String>) -> String: "[" ++ join(rows) ++ "]"
def nums(rows: List<&2,U32>) -> String:
  match rows:
    case []: ""
    case value <> []: U32.show(value)
    case value <> rest: U32.show(value) ++ "," ++ nums(rest)
def u32s(rows: List<&2,U32>) -> String: "[" ++ nums(rows) ++ "]"
def codes(text: String) -> List<&2,U32>:
  match text:
    case SNil{}: []
    case SCon{Chr{code},rest}: code <> codes(rest)
def tick(value: Tick.Tick) -> String:
  match value:
    case Tick.Tick{epoch,low}: "[" ++ Nat.show(epoch) ++ "," ++ U32.show(low) ++ "]"
def ticks(rows: List<&2,Tick.Tick>) -> String:
  match rows:
    case []: ""
    case value <> []: tick(value)
    case value <> rest: tick(value) ++ "," ++ ticks(rest)
def maybe_tick(value: Maybe<&2,Tick.Tick>) -> String:
  match value:
    case None{}: "null"
    case Some{value}: tick(value)
def stamp(value: L.Stamp) -> String:
  match value:
    case L.Stamp{added,changed}: array([maybe_tick(added),maybe_tick(changed)])
def body(value: G.Body) -> String:
  match value:
    case G.Body{x,y,kind,variant,hp,maximum,age,seed,radius}: array([fbits(x),fbits(y),U32.show(kind),U32.show(variant),U32.show(hp),U32.show(maximum),U32.show(age),U32.show(seed),fbits(radius)])
def vitals(value: G.Vitals) -> String:
  match value:
    case G.Vitals{health,maximum}: array([U32.show(health),U32.show(maximum)])
def motion(value: G.Motion) -> String:
  match value:
    case G.Motion{vx,vy,life,pierce,visited,slow,burn,owner,slot}: array([fbits(vx),fbits(vy),U32.show(life),U32.show(pierce),u32s(visited),U32.show(slow),U32.show(burn),U32.show(owner),U32.show(slot)])
def offer(value: G.Offer) -> String:
  match value:
    case G.Offer{kind,id,level}: array([U32.show(kind),U32.show(id),U32.show(level)])
def snapshot_row(value: G.Snapshot) -> String:
  match value:
    case G.Snapshot{b,m}: array([body(b),motion(m)])
def bodies_items(rows: List<&2,G.Body>) -> String:
  match rows:
    case []: ""
    case value <> []: body(value)
    case value <> rest: body(value) ++ "," ++ bodies_items(rest)
def bodies(rows: List<&2,G.Body>) -> String: "[" ++ bodies_items(rows) ++ "]"
def offers_items(rows: List<&2,G.Offer>) -> String:
  match rows:
    case []: ""
    case value <> []: offer(value)
    case value <> rest: offer(value) ++ "," ++ offers_items(rest)
def offers(rows: List<&2,G.Offer>) -> String: "[" ++ offers_items(rows) ++ "]"
def snapshots_items(rows: List<&2,G.Snapshot>) -> String:
  match rows:
    case []: ""
    case value <> []: snapshot_row(value)
    case value <> rest: snapshot_row(value) ++ "," ++ snapshots_items(rest)
def snapshots(rows: List<&2,G.Snapshot>) -> String: "[" ++ snapshots_items(rows) ++ "]"
def run(value: G.Run) -> String:
  match value:
    case G.Run{RS.Session{phase,tick,xp,need,level,kills,gold,seed,stage,bosses,mode,enemyKinds,relicCollected},RS.PlayerState{px,py,hp,maximum,character,weapons,passives,invuln,arcana,meta,revivals,rerolls,banishes,skips,bannedWeapons,bannedPassives}}: array([U32.show(phase),U32.show(tick),fbits(px),fbits(py),U32.show(hp),U32.show(maximum),U32.show(xp),U32.show(need),U32.show(level),U32.show(kills),U32.show(gold),U32.show(character),u32s(weapons),u32s(passives),U32.show(invuln),U32.show(seed),U32.show(stage),U32.show(arcana),U32.show(meta),U32.show(revivals),U32.show(bosses),U32.show(mode),U32.show(rerolls),U32.show(banishes),U32.show(skips),U32.show(bannedWeapons),U32.show(bannedPassives),u32s(enemyKinds),U32.show(relicCollected)])
def maybe_value(~T: Data,~show: T -> String,value: Maybe<&2,T>) -> String:
  match value:
    case None{}: "null"
    case Some{value}: show(value)
def column_finish(~C: Type,+id: U32,value: String,result: Col.Column<G.Schema,C> & L.Stamp) -> Col.Column<G.Schema,C> & String:
  match result:
    case (column,metadata): (column,array([U32.show(id),value,stamp(metadata)]))
def column_value(~C: Type,~V: Data,~show: V -> String,+id: U32,result: Col.Column<G.Schema,C> & Maybe<&2,V>) -> Col.Column<G.Schema,C> & String:
  match result:
    case (column,value): column_finish(~C,id,maybe_value(~V,~show,value),Col.lifecycle(~G.Schema,~C,column,id))
# Keep traversal tail-recursive: nested per-row continuations overflow the JS
# host stack on an ordinary initialized world before the first full comparison.
def column_row_accumulated(~C: Type,reversed: List<&2,String>,result: Col.Column<G.Schema,C> & String) -> Col.Column<G.Schema,C> & List<&2,String>:
  match result:
    case (column,text): (column,text <> reversed)
def column_rows_loop(~C: Type,~V: Data,~project: C -> C & V,~show: V -> String,fuel: Nat,+id: U32,state: Col.Column<G.Schema,C> & List<&2,String>) -> Col.Column<G.Schema,C> & String:
  match fuel state:
    case 0n Tuple{column,reversed}: (column,join(List.reverse(&2,String,reversed)))
    case 1n+rest Tuple{column,reversed}: column_rows_loop(~C,~V,~project,~show,rest,(id + 1 : U32),column_row_accumulated(~C,reversed,column_value(~C,~V,~show,id,Col.view(~G.Schema,~C,~V,~project,column,id))))
def column_rows(~C: Type,~V: Data,~project: C -> C & V,~show: V -> String,fuel: Nat,id: U32,column: Col.Column<G.Schema,C>) -> Col.Column<G.Schema,C> & String:
  column_rows_loop(~C,~V,~project,~show,fuel,id,(column,[]))
def roster_handle(value: W.Handle<G.Schema>) -> String:
  match value:
    case W.Handle{namespace,K.EntityKey{id,generation}}: array([U32.show(namespace),U32.show(id),U32.show(generation)])
def roster_handles(rows: List<&2,W.Handle<G.Schema>>) -> String:
  match rows:
    case []: ""
    case value <> []: roster_handle(value)
    case value <> rest: roster_handle(value) ++ "," ++ roster_handles(rest)
def movement_roster(value: G.MovementRoster) -> String:
  match value:
    case G.MovementPrepared{handles}: "[" ++ roster_handles(handles) ++ "]"
# Physical columns retain their actual membership and change stamps. Logical
# Motion is a derived compatibility view only: no unified component/stamp exists.
def trajectory(value: G.Trajectory) -> String:
  match value:
    case G.Trajectory{vx,vy,life,pierce,visited,owner,slot}: array([fbits(vx),fbits(vy),U32.show(life),U32.show(pierce),u32s(visited),U32.show(owner),U32.show(slot)])
def status(value: G.Status) -> String:
  match value:
    case G.Status{slow,burn}: array([U32.show(slow),U32.show(burn)])
def pickup(value: G.Pickup) -> String:
  match value:
    case G.Pickup{amount,generation,variant,active}: array([U32.show(amount),U32.show(generation),U32.show(variant),U32.show(Bool.to_u32(active))])
def role(value: GRole.Role) -> String:
  match value:
    case GRole.EnemySlot{}: "\"EnemySlot\""
    case GRole.RelicSlot{}: "\"RelicSlot\""
    case GRole.PlayerProjectileSlot{}: "\"PlayerProjectileSlot\""
    case GRole.HostileProjectileSlot{}: "\"HostileProjectileSlot\""
    case GRole.XpSlot{}: "\"XpSlot\""
    case GRole.OutsideSlot{}: "\"OutsideSlot\""
def candidate_roster(projectile: Bool,value: G.CandidateRoster) -> String:
  match projectile value:
    case True{} G.CandidatesPrepared{projectiles,_}: "[" ++ roster_handles(projectiles) ++ "]"
    case False{} G.CandidatesPrepared{_,pool}: "[" ++ roster_handles(pool) ++ "]"
def logical_motion_value(trajectory: Maybe<&2,G.Trajectory>,status: Maybe<&2,G.Status>) -> G.Motion:
  match trajectory status:
    case Some{trajectory} Some{status}: G.logical_motion(trajectory,status)
    case Some{trajectory} None{}: G.logical_motion(trajectory,G.empty_status())
    case None{} Some{status}: G.logical_motion(G.empty_trajectory(),status)
    case None{} None{}: G.empty_motion()
type LogicalColumns is Type: LogicalColumns{trajectories: Col.Column<G.Schema,G.Trajectory>,statuses: Col.Column<G.Schema,G.Status>}
def logical_row_status(id: U32,trajectories: Col.Column<G.Schema,G.Trajectory>,value: Maybe<&2,G.Trajectory>,result: Col.Column<G.Schema,G.Status> & Maybe<&2,G.Status>) -> LogicalColumns & String:
  match result:
    case (statuses,status): (LogicalColumns{trajectories,statuses},array([U32.show(id),motion(logical_motion_value(value,status)),"null"]))
def logical_row_trajectory(+id: U32,statuses: Col.Column<G.Schema,G.Status>,result: Col.Column<G.Schema,G.Trajectory> & Maybe<&2,G.Trajectory>) -> LogicalColumns & String:
  match result:
    case (trajectories,value): logical_row_status(id,trajectories,value,Col.view(~G.Schema,~G.Status,~G.Status,~G.project_status,statuses,id))
def logical_row(+id: U32,columns: LogicalColumns) -> LogicalColumns & String:
  match columns:
    case LogicalColumns{trajectories,statuses}: logical_row_trajectory(id,statuses,Col.view(~G.Schema,~G.Trajectory,~G.Trajectory,~G.project_trajectory,trajectories,id))
def logical_row_accumulated(reversed: List<&2,String>,result: LogicalColumns & String) -> LogicalColumns & List<&2,String>:
  match result:
    case (columns,value): (columns,value <> reversed)
def logical_rows(fuel: Nat,+id: U32,state: LogicalColumns & List<&2,String>) -> LogicalColumns & String:
  match fuel state:
    case 0n Tuple{columns,reversed}: (columns,join(List.reverse(&2,String,reversed)))
    case 1n+rest Tuple{columns,reversed}: logical_rows(rest,(id + 1 : U32),logical_row_accumulated(reversed,logical_row(id,columns)))
def logical_store_done(b: Col.Column<G.Schema,G.Body>,v: Col.Column<G.Schema,G.Vitals>,p: Col.Column<G.Schema,G.Pickup>,r: Col.Column<G.Schema,GRole.Role>,movement: G.MovementRoster,candidates: G.CandidateRoster,players: Col.Column<G.Schema,G.PlayerRecord>,result: LogicalColumns & String) -> G.Store & String:
  match result:
    case (LogicalColumns{t,s},text): (G.Store{b,v,t,s,p,r,movement,candidates,players},text)
def logical_store(store: G.Store) -> G.Store & String:
  match store:
    case G.Store{b,v,t,s,p,r,movement,candidates,players}: logical_store_done(b,v,p,r,movement,candidates,players,logical_rows(PL.total_nat(),1,(LogicalColumns{t,s},[])))
def observed_column_done(~C: Type,~Rest: Type,~put: Rest -> Col.Column<G.Schema,C> -> G.Store,rest: Rest,result: Col.Column<G.Schema,C> & String) -> G.Store & String:
  match result:
    case (column,text): (put(rest,column),text)
def observed_column_split(~C: Type,~V: Data,~Rest: Type,~put: Rest -> Col.Column<G.Schema,C> -> G.Store,~project: C -> C & V,~show: V -> String,result: Rest & Col.Column<G.Schema,C>) -> G.Store & String:
  match result:
    case (rest,column): observed_column_done(~C,~Rest,~put,rest,column_rows(~C,~V,~project,~show,PL.total_nat(),1,column))
def observed_column(~C: Type,~V: Data,~Rest: Type,~take: G.Store -> Rest & Col.Column<G.Schema,C>,~put: Rest -> Col.Column<G.Schema,C> -> G.Store,~project: C -> C & V,~show: V -> String,store: G.Store) -> G.Store & String:
  observed_column_split(~C,~V,~Rest,~put,~project,~show,take(store))
def store_logical(bs: String,vs: String,ts: String,ss: String,ps: String,rs: String,result: G.Store & String) -> G.Store & String:
  match result:
    case (G.Store{b,v,t,s,p,r,+movement,+candidates,players},ms): (G.Store{b,v,t,s,p,r,movement,candidates,players},"{\"bodies\":[" ++ bs ++ "],\"vitals\":[" ++ vs ++ "],\"motions\":[" ++ ms ++ "],\"trajectories\":[" ++ ts ++ "],\"statuses\":[" ++ ss ++ "],\"pickups\":[" ++ ps ++ "],\"roles\":[" ++ rs ++ "],\"movementCandidates\":" ++ movement_roster(movement) ++ ",\"projectileCandidates\":" ++ candidate_roster(True{},candidates) ++ ",\"poolCandidates\":" ++ candidate_roster(False{},candidates) ++ "}")
def store_role(bs: String,vs: String,ts: String,ss: String,ps: String,result: G.Store & String) -> G.Store & String:
  match result:
    case (owner,rs): store_logical(bs,vs,ts,ss,ps,rs,logical_store(owner))
def store_pickup(bs: String,vs: String,ts: String,ss: String,result: G.Store & String) -> G.Store & String:
  match result:
    case (owner,ps): store_role(bs,vs,ts,ss,ps,observed_column(~GRole.Role,~GRole.Role,~G.RoleRest,~G.take_role,~G.put_role,~G.project_role,~role,owner))
def store_status(bs: String,vs: String,ts: String,result: G.Store & String) -> G.Store & String:
  match result:
    case (owner,ss): store_pickup(bs,vs,ts,ss,observed_column(~G.Pickup,~G.Pickup,~G.PickupRest,~G.take_pickup,~G.put_pickup,~G.project_pickup,~pickup,owner))
def store_trajectory(bs: String,vs: String,result: G.Store & String) -> G.Store & String:
  match result:
    case (owner,ts): store_status(bs,vs,ts,observed_column(~G.Status,~G.Status,~G.StatusRest,~G.take_status,~G.put_status,~G.project_status,~status,owner))
def store_vitals(bs: String,result: G.Store & String) -> G.Store & String:
  match result:
    case (owner,vs): store_trajectory(bs,vs,observed_column(~G.Trajectory,~G.Trajectory,~G.TrajectoryRest,~G.take_trajectory,~G.put_trajectory,~G.project_trajectory,~trajectory,owner))
def store_body(result: G.Store & String) -> G.Store & String:
  match result:
    case (owner,bs): store_vitals(bs,observed_column(~G.Vitals,~G.Vitals,~G.VitalRest,~G.take_vitals,~G.put_vitals,~G.project_vitals,~vitals,owner))
def store(value: G.Store) -> G.Store & String:
  store_body(observed_column(~G.Body,~G.Body,~G.BodyRest,~G.take,~G.put,~G.project,~body,value))
def key(value: K.Key) -> String:
  match value:
    case K.EntityKey{id,generation}: array([U32.show(id),U32.show(generation)])
def keys(rows: List<&2,K.Key>) -> String:
  match rows:
    case []: ""
    case value <> []: key(value)
    case value <> rest: key(value) ++ "," ++ keys(rest)
def allocator_phase(value: A.Phase) -> String:
  match value:
    case A.Consumed{}: "0"
    case A.Pending{}: "1"
    case A.Live{}: "2"
    case A.DeadRetained{}: "3"
    case A.Free{}: "4"
def slot(value: A.Slot) -> String:
  match value:
    case A.Slot{generation,phase}: array([U32.show(generation),allocator_phase(phase)])
def slot_accumulated(reversed: List<&2,String>,result: Array<A.Slot> & A.Slot) -> Array<A.Slot> & List<&2,String>:
  match result:
    case (rows,value): (rows,slot(value) <> reversed)
def slots_loop(fuel: Nat,+index: U32,state: Array<A.Slot> & List<&2,String>) -> Array<A.Slot> & String:
  match fuel state:
    case 0n Tuple{rows,reversed}: (rows,join(List.reverse(&2,String,reversed)))
    case 1n+rest Tuple{rows,reversed}: slots_loop(rest,(index + 1 : U32),slot_accumulated(reversed,Array.get(A.Slot,rows,index)))
def slots(fuel: Nat,index: U32,rows: Array<A.Slot>) -> Array<A.Slot> & String:
  slots_loop(fuel,index,(rows,[]))
def allocator_finish(+next: U32,+high: U32,+capacity: U32,+depth: Nat,+free: List<&2,U32>,+order: List<&2,K.Key>,result: Array<A.Slot> & String) -> A.Allocator & String:
  match result:
    case (rows,text): (A.Allocator{next,high,rows,capacity,depth,free,order},array([U32.show(next),U32.show(high),U32.show(capacity),Nat.show(depth),u32s(free),"[" ++ keys(order) ++ "]","[" ++ text ++ "]"]))
def allocator(value: A.Allocator) -> A.Allocator & String:
  match value:
    case A.Allocator{next,high,rows,+capacity,depth,free,order}: allocator_finish(next,high,capacity,depth,free,order,slots(U32.to_nat(capacity),0,rows))
def clock(value: Clock.State) -> String:
  match value:
    case Clock.State{now,scopes}: array([tick(now),"[" ++ ticks(scopes) ++ "]"])
def strings(rows: List<&2,String>) -> String:
  match rows:
    case []: ""
    case value <> []: u32s(codes(value))
    case value <> rest: u32s(codes(value)) ++ "," ++ strings(rest)
def registration(value: W.RegistrationMeta) -> String:
  match value:
    case W.RegistrationMeta{id,name,access}: array([U32.show(id),u32s(codes(name)),"[" ++ strings(access) ++ "]"])
def registrations(rows: List<&2,W.RegistrationMeta>) -> String:
  match rows:
    case []: ""
    case value <> []: registration(value)
    case value <> rest: registration(value) ++ "," ++ registrations(rest)
def world_allocator(+namespace: U32,store: G.Store,resource: Unit,+events: List<&2,Unit>,pending: List<Deferred.Command<G.World()>>,+regs: List<&2,W.RegistrationMeta>,+next: U32,+time: Clock.State,pendingCount: U32,result: A.Allocator & String) -> G.World() & String:
  match result:
    case (alloc,text): (W.World{namespace,alloc,store,resource,events,pending,regs,next,time},"{\"namespace\":" ++ U32.show(namespace) ++ ",\"allocator\":" ++ text ++ ",\"clock\":" ++ clock(time) ++ ",\"events\":" ++ Nat.show(List.length(&2,Unit,events)) ++ ",\"pendingCommands\":" ++ U32.show(pendingCount) ++ ",\"registrations\":[" ++ registrations(regs) ++ "],\"nextSystemId\":" ++ U32.show(next) ++ "}")
def world_counted(result: G.World() & U32) -> G.World() & String:
  match result:
    case (W.World{namespace,alloc,store,resource,events,pending,regs,next,time},count): world_allocator(namespace,store,resource,events,pending,regs,next,time,count,allocator(alloc))
def world(value: G.World()) -> G.World() & String:
  world_counted(W.pending_count(~G.Schema,~G.Store,~Unit,~Unit,value))
def metadata_join(componentText: String,result: G.World() & String) -> G.World() & String:
  match result:
    case (owner,text): (owner,"\"components\":" ++ componentText ++ ",\"metadata\":" ++ text)
def world_components(result: G.World() & String) -> G.World() & String:
  match result:
    case (owner,text): metadata_join(text,world(owner))
def snapshot_finish(+runValue: G.Run,+rows: List<&2,G.Body>,+off: List<&2,G.Offer>,+shots: List<&2,G.Snapshot>,+pending: List<&2,U32>,result: G.World() & String) -> G.State & String:
  match result:
    case (owner,text): (G.State{owner,runValue,rows,off,shots,pending},"{\"run\":" ++ run(runValue) ++ ",\"bodies\":" ++ bodies(rows) ++ ",\"offers\":" ++ offers(off) ++ ",\"snapshots\":" ++ snapshots(shots) ++ ",\"pending\":" ++ u32s(pending) ++ "," ++ text ++ "}")
def snapshot(value: G.State) -> G.State & String:
  match value:
    case G.State{owner,runValue,rows,off,shots,pending}: snapshot_finish(runValue,rows,off,shots,pending,world_components(W.with_store(~G.Schema,~G.Store,~Unit,~Unit,~String,store,owner)))

# Nonserializing completion barrier used ONCE per timed window, never per tick.
# Its rolling word value is observable but is not a correctness hash. Full exact
# observation remains outside the clock. Each native scalar must reach this
# result before the stop-clock continuation captures the U32 digest.
def mix(acc: U32,value: U32) -> U32: U32.xor((acc * 16777619 : U32),value)
def fold_words(rows: List<&2,U32>,acc: U32) -> U32:
  match rows:
    case []: acc
    case value <> rest: fold_words(rest,mix(acc,value))
def fold_tick(value: Tick.Tick,acc: U32) -> U32:
  match value:
    case Tick.Tick{epoch,low}: mix(mix(acc,U32.from_nat(epoch)),low)
def fold_maybe_tick(value: Maybe<&2,Tick.Tick>,acc: U32) -> U32:
  match value:
    case None{}: mix(acc,0)
    case Some{value}: fold_tick(value,mix(acc,1))
def fold_stamp(value: L.Stamp,acc: U32) -> U32:
  match value:
    case L.Stamp{added,changed}: fold_maybe_tick(changed,fold_maybe_tick(added,acc))
def fold_body(value: G.Body,acc: U32) -> U32:
  match value:
    case G.Body{x,y,kind,variant,hp,maximum,age,seed,radius}: fold_words([F32.bits(x),F32.bits(y),kind,variant,hp,maximum,age,seed,F32.bits(radius)],acc)
def fold_vitals(value: G.Vitals,acc: U32) -> U32:
  match value:
    case G.Vitals{health,maximum}: fold_words([health,maximum],acc)
def fold_offer(value: G.Offer,acc: U32) -> U32:
  match value:
    case G.Offer{kind,id,level}: fold_words([kind,id,level],acc)
def fold_motion(value: G.Motion,acc: U32) -> U32:
  match value:
    case G.Motion{vx,vy,life,pierce,visited,slow,burn,owner,slot}: fold_words(visited,fold_words([F32.bits(vx),F32.bits(vy),life,pierce,slow,burn,owner,slot],acc))
def fold_snapshot(value: G.Snapshot,acc: U32) -> U32:
  match value:
    case G.Snapshot{b,m}: fold_motion(m,fold_body(b,acc))
def fold_bodies(rows: List<&2,G.Body>,acc: U32) -> U32:
  match rows:
    case []: mix(acc,0)
    case value <> rest: fold_bodies(rest,fold_body(value,mix(acc,1)))
def fold_offers(rows: List<&2,G.Offer>,acc: U32) -> U32:
  match rows:
    case []: mix(acc,0)
    case value <> rest: fold_offers(rest,fold_offer(value,mix(acc,1)))
def fold_snapshots(rows: List<&2,G.Snapshot>,acc: U32) -> U32:
  match rows:
    case []: mix(acc,0)
    case value <> rest: fold_snapshots(rest,fold_snapshot(value,mix(acc,1)))
def fold_run(value: G.Run,acc: U32) -> U32:
  match value:
    case G.Run{RS.Session{phase,tick,xp,need,level,kills,gold,seed,stage,bosses,mode,enemyKinds,relicCollected},RS.PlayerState{px,py,hp,maximum,character,weapons,passives,invuln,arcana,meta,revivals,rerolls,banishes,skips,bannedWeapons,bannedPassives}}: fold_words(enemyKinds,fold_words(passives,fold_words(weapons,fold_words([phase,tick,F32.bits(px),F32.bits(py),hp,maximum,xp,need,level,kills,gold,character,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,relicCollected],acc))))
def fold_present(~V: Data,~fold: V -> U32 -> U32,value: Maybe<&2,V>,acc: U32) -> U32:
  match value:
    case None{}: mix(acc,0)
    case Some{value}: fold(value,mix(acc,1))
def force_column_metadata(~C: Type,acc: U32,result: Col.Column<G.Schema,C> & L.Stamp) -> Col.Column<G.Schema,C> & U32:
  match result:
    case (column,metadata): (column,fold_stamp(metadata,acc))
def force_column_value(~C: Type,~V: Data,~fold: V -> U32 -> U32,+id: U32,acc: U32,result: Col.Column<G.Schema,C> & Maybe<&2,V>) -> Col.Column<G.Schema,C> & U32:
  match result:
    case (column,value): force_column_metadata(~C,fold_present(~V,~fold,value,acc),Col.lifecycle(~G.Schema,~C,column,id))
def force_column_next(~C: Type,result: Col.Column<G.Schema,C> & U32,use: Col.Column<G.Schema,C> -> U32 -> Col.Column<G.Schema,C> & U32) -> Col.Column<G.Schema,C> & U32:
  match result:
    case (column,acc): use(column)(acc)
def force_column(~C: Type,~V: Data,~project: C -> C & V,~fold: V -> U32 -> U32,fuel: Nat,+id: U32,column: Col.Column<G.Schema,C>,acc: U32) -> Col.Column<G.Schema,C> & U32:
  match fuel:
    case 0n: (column,acc)
    case 1n+rest: force_column_next(~C,force_column_value(~C,~V,~fold,id,mix(acc,id),Col.view(~G.Schema,~C,~V,~project,column,id)),(column => acc => force_column(~C,~V,~project,~fold,rest,(id + 1 : U32),column,acc)))
def fold_roster_handle(value: W.Handle<G.Schema>,acc: U32) -> U32:
  match value:
    case W.Handle{namespace,K.EntityKey{id,generation}}: mix(mix(mix(acc,namespace),id),generation)
def fold_roster_handles(rows: List<&2,W.Handle<G.Schema>>,acc: U32) -> U32:
  match rows:
    case []: acc
    case value <> rest: fold_roster_handles(rest,fold_roster_handle(value,acc))
def fold_movement_roster(value: G.MovementRoster,acc: U32) -> U32:
  match value:
    case G.MovementPrepared{handles}: fold_roster_handles(handles,mix(acc,1))
def fold_trajectory(value: G.Trajectory,acc: U32) -> U32:
  match value:
    case G.Trajectory{vx,vy,life,pierce,visited,owner,slot}: fold_words(visited,fold_words([F32.bits(vx),F32.bits(vy),life,pierce,owner,slot],acc))
def fold_status(value: G.Status,acc: U32) -> U32:
  match value:
    case G.Status{slow,burn}: fold_words([slow,burn],acc)
def fold_pickup(value: G.Pickup,acc: U32) -> U32:
  match value:
    case G.Pickup{amount,generation,variant,active}: fold_words([amount,generation,variant,Bool.to_u32(active)],acc)
def fold_role(value: GRole.Role,acc: U32) -> U32: fold_words(codes(role(value)),acc)
def fold_candidate_roster(value: G.CandidateRoster,acc: U32) -> U32:
  match value:
    case G.CandidatesPrepared{projectiles,pool}: fold_roster_handles(pool,mix(fold_roster_handles(projectiles,mix(acc,1)),2))
def force_column_done(~C: Type,~Rest: Type,~put: Rest -> Col.Column<G.Schema,C> -> G.Store,rest: Rest,result: Col.Column<G.Schema,C> & U32) -> G.Store & U32:
  match result:
    case (column,acc): (put(rest,column),acc)
def force_column_split(~C: Type,~V: Data,~Rest: Type,~put: Rest -> Col.Column<G.Schema,C> -> G.Store,~project: C -> C & V,~fold: V -> U32 -> U32,acc: U32,result: Rest & Col.Column<G.Schema,C>) -> G.Store & U32:
  match result:
    case (rest,column): force_column_done(~C,~Rest,~put,rest,force_column(~C,~V,~project,~fold,PL.total_nat(),1,column,acc))
def force_store_column(~C: Type,~V: Data,~Rest: Type,~take: G.Store -> Rest & Col.Column<G.Schema,C>,~put: Rest -> Col.Column<G.Schema,C> -> G.Store,~project: C -> C & V,~fold: V -> U32 -> U32,acc: U32,store: G.Store) -> G.Store & U32:
  force_column_split(~C,~V,~Rest,~put,~project,~fold,acc,take(store))
def force_store_routing(result: G.Store & U32) -> G.Store & U32:
  match result:
    case (G.Store{b,v,t,s,p,r,+movement,+candidates,players},acc): (G.Store{b,v,t,s,p,r,movement,candidates,players},fold_candidate_roster(candidates,fold_movement_roster(movement,acc)))
def force_store_role(result: G.Store & U32) -> G.Store & U32:
  match result:
    case (owner,acc): force_store_routing((owner,acc))
def force_store_pickup(result: G.Store & U32) -> G.Store & U32:
  match result:
    case (owner,acc): force_store_role(force_store_column(~GRole.Role,~GRole.Role,~G.RoleRest,~G.take_role,~G.put_role,~G.project_role,~fold_role,acc,owner))
def force_store_status(result: G.Store & U32) -> G.Store & U32:
  match result:
    case (owner,acc): force_store_pickup(force_store_column(~G.Pickup,~G.Pickup,~G.PickupRest,~G.take_pickup,~G.put_pickup,~G.project_pickup,~fold_pickup,acc,owner))
def force_store_trajectory(result: G.Store & U32) -> G.Store & U32:
  match result:
    case (owner,acc): force_store_status(force_store_column(~G.Status,~G.Status,~G.StatusRest,~G.take_status,~G.put_status,~G.project_status,~fold_status,acc,owner))
def force_store_vitals(result: G.Store & U32) -> G.Store & U32:
  match result:
    case (owner,acc): force_store_trajectory(force_store_column(~G.Trajectory,~G.Trajectory,~G.TrajectoryRest,~G.take_trajectory,~G.put_trajectory,~G.project_trajectory,~fold_trajectory,acc,owner))
def force_store_body(result: G.Store & U32) -> G.Store & U32:
  match result:
    case (owner,acc): force_store_vitals(force_store_column(~G.Vitals,~G.Vitals,~G.VitalRest,~G.take_vitals,~G.put_vitals,~G.project_vitals,~fold_vitals,acc,owner))
def force_store(value: G.Store) -> G.Store & U32:
  force_store_body(force_store_column(~G.Body,~G.Body,~G.BodyRest,~G.take,~G.put,~G.project,~fold_body,2166136261,value))
def force_world_clock(acc: U32,result: G.World() & Tick.Tick) -> G.World() & U32:
  match result:
    case (owner,time): (owner,fold_tick(time,acc))
def force_world(result: G.World() & U32) -> G.World() & U32:
  match result:
    case (owner,acc): force_world_clock(acc,W.clock(~G.Schema,~G.Store,~Unit,~Unit,owner))
def force_finish(+runValue: G.Run,+rows: List<&2,G.Body>,+off: List<&2,G.Offer>,+shots: List<&2,G.Snapshot>,+pending: List<&2,U32>,result: G.World() & U32) -> G.State & U32:
  match result:
    case (owner,acc): (G.State{owner,runValue,rows,off,shots,pending},fold_words(pending,fold_snapshots(shots,fold_offers(off,fold_bodies(rows,fold_run(runValue,acc))))))
def force(value: G.State) -> G.State & U32:
  match value:
    case G.State{owner,runValue,rows,off,shots,pending}: force_finish(runValue,rows,off,shots,pending,force_world(W.with_store(~G.Schema,~G.Store,~Unit,~Unit,~U32,force_store,owner)))
