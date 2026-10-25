import Base
import pickup-state.bend as Pickup
import enemy-spatial.bend as Space
import persistent-xp.bend as Xp
import loot-placement.bend as Placement
import body-index.bend as Index

# This phase policy consumes explicit pickup observations and ordered death drops.
# It owns no ECS storage and never transports XP through a health-shaped value.
type Drop is Data: Drop{amount: U32,x: F32,y: F32}
type Inventory is Data: Inventory{free: List<&2,U32>,accumulator: Maybe<&2,Pickup.State>,distance: F32,marked: Bool}
type Batch is Data: Batch{free: List<&2,U32>,accumulator: Maybe<&2,Pickup.State>,updates: Index.Index<Pickup.State>,overflow: U32}
def distance(+x: F32,+y: F32,+px: F32,+py: F32) -> F32: ((x - px) * (x - px) + (y - py) * (y - py) : F32)
def selected(choose: Bool,state: Pickup.State,nextDistance: F32,marked: Bool,inventory: Inventory) -> Inventory:
  match choose inventory:
    case False{} inventory: inventory
    case True{} Inventory{free,_,_,_}: Inventory{free,Some{state},nextDistance,marked}
def inspect(+state: Pickup.State,+px: F32,+py: F32,inventory: Inventory) -> Inventory:
  match state inventory:
    case Pickup.State{_,Pickup.Payload{_,slot,_,False{}}} Inventory{free,accumulator,distance,marked}: Inventory{slot <> free,accumulator,distance,marked}
    case Pickup.State{Space.Spatial{+x,+y,_,_},Pickup.Payload{Pickup.Xp{_,+isAccumulator},_,_,True{}}} Inventory{+free,+accumulator,+oldDistance,+marked}:
      selected(Bool.and(Bool.not(marked),Bool.or(isAccumulator,F32.is_lt(oldDistance,distance(x,y,px,py)))),state,distance(x,y,px,py),isAccumulator,Inventory{free,accumulator,oldDistance,marked})
    case _ inventory: inventory
def inventory(rows: List<&2,Pickup.State>,+px: F32,+py: F32,accumulator: Inventory) -> Inventory:
  match rows:
    case []: accumulator
    case head <> tail: inventory(tail,px,py,inspect(head,px,py,accumulator))
def existing_or_new(existing: Maybe<&2,Pickup.State>,fresh: Pickup.State) -> Maybe<&2,Pickup.State>:
  match existing:
    case Some{state}: Some{state}
    case None{}: Some{fresh}
def append_drop(+drop: Drop,+generation: U32,batch: Batch) -> Batch:
  match drop batch:
    case Drop{amount,_,_} Batch{[],accumulator,updates,overflow}: Batch{[],accumulator,updates,Xp.merge(overflow,amount)}
    case Drop{amount,x,y} Batch{+slot <> free,accumulator,updates,overflow}:
      +fresh: Pickup.State = Pickup.State{Space.Spatial{Placement.place(x),Placement.place(y),0,6.0},Pickup.Payload{Pickup.Xp{amount,False{}},slot,generation,True{}}}
      Batch{free,existing_or_new(accumulator,fresh),Index.insert(~Pickup.State,updates,slot,fresh),overflow}
def append_drops(drops: List<&2,Drop>,+generation: U32,batch: Batch) -> Batch:
  match drops:
    case []: batch
    case head <> tail: append_drops(tail,generation,append_drop(head,generation,batch))
def merge_overflow(merge: Bool,state: Pickup.State,incoming: U32) -> Pickup.State:
  match merge state:
    case True{} Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{Pickup.Xp{amount,_},slot,generation,True{}}}: Pickup.State{Space.Spatial{Placement.place(x),Placement.place(y),age,radius},Pickup.Payload{Pickup.Xp{Xp.merge(amount,incoming),True{}},slot,generation,True{}}}
    case _ state: state
def updated(+state: Pickup.State,+updates: Index.Index<Pickup.State>,+chosen: U32,+overflow: U32) -> Pickup.State:
  merge_overflow(Bool.and(U32.is_eq(Pickup.slot(state),chosen),U32.is_lt(0,overflow)),Index.get(~Pickup.State,updates,Pickup.slot(state),state),overflow)
def apply(rows: List<&2,Pickup.State>,+updates: Index.Index<Pickup.State>,+chosen: U32,+overflow: U32) -> List<&2,Pickup.State>:
  match rows:
    case []: []
    case head <> tail: updated(head,updates,chosen,overflow) <> apply(tail,updates,chosen,overflow)
def finished(rows: List<&2,Pickup.State>,batch: Batch) -> List<&2,Pickup.State>:
  match batch:
    case Batch{_,Some{chosen},updates,overflow}: apply(rows,updates,Pickup.slot(chosen),overflow)
    case Batch{_,None{},_,_}: rows
def route_inventory(drops: List<&2,Drop>,+rows: List<&2,Pickup.State>,generation: U32,inventory: Inventory) -> List<&2,Pickup.State>:
  match inventory:
    case Inventory{free,accumulator,_,_}: finished(rows,append_drops(drops,generation,Batch{List.reverse(&2,U32,free),accumulator,Index.Empty{},0}))
def route(drops: List<&2,Drop>,+rows: List<&2,Pickup.State>,generation: U32,px: F32,py: F32) -> List<&2,Pickup.State>:
  route_inventory(drops,rows,generation,inventory(rows,px,py,Inventory{[],None{},(0.0 - 1.0 : F32),False{}}))
