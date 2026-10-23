import Base
import game.bend as G
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
    case G.Motion{vx,vy,life,pierce,visited,slow,burn}: array([fbits(vx),fbits(vy),U32.show(life),U32.show(pierce),u32s(visited),U32.show(slow),U32.show(burn)])
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
    case G.Run{phase,tick,px,py,hp,maximum,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: array([U32.show(phase),U32.show(tick),fbits(px),fbits(py),U32.show(hp),U32.show(maximum),U32.show(xp),U32.show(need),U32.show(level),U32.show(kills),U32.show(gold),U32.show(character),u32s(weapons),u32s(passives),U32.show(invuln),U32.show(seed),U32.show(stage),U32.show(arcana),U32.show(meta),U32.show(revivals),U32.show(bosses),U32.show(mode),U32.show(rerolls),U32.show(banishes),U32.show(skips),U32.show(bannedWeapons),U32.show(bannedPassives),u32s(enemyKinds),U32.show(relicCollected)])
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
def column_join(~C: Type,first: String,result: Col.Column<G.Schema,C> & String) -> Col.Column<G.Schema,C> & String:
  match result:
    case (column,rest): (column,first ++ rest)
def column_next(~C: Type,first: Col.Column<G.Schema,C> & String,use: Col.Column<G.Schema,C> -> Col.Column<G.Schema,C> & String) -> Col.Column<G.Schema,C> & String:
  match first:
    case (column,text): column_join(~C,text,use(column))
def separator(last: Bool) -> String:
  match last:
    case True{}: ""
    case False{}: ","
def column_rows(~C: Type,~V: Data,~project: C -> C & V,~show: V -> String,fuel: Nat,+id: U32,column: Col.Column<G.Schema,C>) -> Col.Column<G.Schema,C> & String:
  match fuel:
    case 0n: (column,"")
    case 1n+ +rest: column_next(~C,column_value(~C,~V,~show,id,Col.view(~G.Schema,~C,~V,~project,column,id)),(column => column_join(~C,separator(Nat.is_eq(rest,0n)),column_rows(~C,~V,~project,~show,rest,(id + 1 : U32),column))))
def store_motion(b: Col.Column<G.Schema,G.Body>,v: Col.Column<G.Schema,G.Vitals>,bs: String,vs: String,result: Col.Column<G.Schema,G.Motion> & String) -> G.Store & String:
  match result:
    case (m,ms): (G.Store{b,v,m},"{\"bodies\":[" ++ bs ++ "],\"vitals\":[" ++ vs ++ "],\"motions\":[" ++ ms ++ "]}")
def store_vitals(b: Col.Column<G.Schema,G.Body>,m: Col.Column<G.Schema,G.Motion>,bs: String,result: Col.Column<G.Schema,G.Vitals> & String) -> G.Store & String:
  match result:
    case (v,vs): store_motion(b,v,bs,vs,column_rows(~G.Motion,~G.Motion,~G.project_motion,~motion,1004n,1,m))
def store_body(v: Col.Column<G.Schema,G.Vitals>,m: Col.Column<G.Schema,G.Motion>,result: Col.Column<G.Schema,G.Body> & String) -> G.Store & String:
  match result:
    case (b,bs): store_vitals(b,m,bs,column_rows(~G.Vitals,~G.Vitals,~G.project_vitals,~vitals,1004n,1,v))
def store(value: G.Store) -> G.Store & String:
  match value:
    case G.Store{b,v,m}: store_body(v,m,column_rows(~G.Body,~G.Body,~G.project,~body,1004n,1,b))
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
def slots_join(first: String,result: Array<A.Slot> & String) -> Array<A.Slot> & String:
  match result:
    case (rows,text): (rows,first ++ text)
def slots_next(result: Array<A.Slot> & A.Slot,use: Array<A.Slot> -> Array<A.Slot> & String) -> Array<A.Slot> & String:
  match result:
    case (rows,value): slots_join(slot(value),use(rows))
def slots(fuel: Nat,+index: U32,rows: Array<A.Slot>) -> Array<A.Slot> & String:
  match fuel:
    case 0n: (rows,"")
    case 1n+ +rest: slots_next(Array.get(A.Slot,rows,index),(rows => slots_join(separator(Nat.is_eq(rest,0n)),slots(rest,(index + 1 : U32),rows))))
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
    case G.Motion{vx,vy,life,pierce,visited,slow,burn}: fold_words(visited,fold_words([F32.bits(vx),F32.bits(vy),life,pierce,slow,burn],acc))
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
    case G.Run{phase,tick,px,py,hp,maximum,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: fold_words(enemyKinds,fold_words(passives,fold_words(weapons,fold_words([phase,tick,F32.bits(px),F32.bits(py),hp,maximum,xp,need,level,kills,gold,character,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,relicCollected],acc))))
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
def force_store_motion(b: Col.Column<G.Schema,G.Body>,v: Col.Column<G.Schema,G.Vitals>,result: Col.Column<G.Schema,G.Motion> & U32) -> G.Store & U32:
  match result:
    case (m,acc): (G.Store{b,v,m},acc)
def force_store_vitals(b: Col.Column<G.Schema,G.Body>,m: Col.Column<G.Schema,G.Motion>,result: Col.Column<G.Schema,G.Vitals> & U32) -> G.Store & U32:
  match result:
    case (v,acc): force_store_motion(b,v,force_column(~G.Motion,~G.Motion,~G.project_motion,~fold_motion,1004n,1,m,acc))
def force_store_body(v: Col.Column<G.Schema,G.Vitals>,m: Col.Column<G.Schema,G.Motion>,result: Col.Column<G.Schema,G.Body> & U32) -> G.Store & U32:
  match result:
    case (b,acc): force_store_vitals(b,m,force_column(~G.Vitals,~G.Vitals,~G.project_vitals,~fold_vitals,1004n,1,v,acc))
def force_store(value: G.Store) -> G.Store & U32:
  match value:
    case G.Store{b,v,m}: force_store_body(v,m,force_column(~G.Body,~G.Body,~G.project,~fold_body,1004n,1,b,2166136261))
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
