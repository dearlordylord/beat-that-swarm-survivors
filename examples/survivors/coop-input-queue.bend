import Base
import ./coop-session.bend as S

# Transport sequence identifies a packet; targetWorldTick identifies its sole
# permitted gameplay step. A gap resolves to neutral without moving future input.
type Tick is Data: Tick{seq: U32,targetWorldTick: U32,x: U32,y: U32}
type State is Data: State{round: U32,last: U32,worldTick: U32,pending: List<&2,Tick>}
type Admission is Data: Admission{state: State,accepted: Bool,reason: U32}
type Taken is Data: Taken{state: State,tick: Maybe<&2,Tick>}
def fresh(round: U32,worldTick: U32) -> State: State{round,0,worldTick,[]}
def activity(phase: U32,enabled: Bool) -> Bool: Bool.and(U32.is_eq(phase,0),enabled)
def full(state: State) -> Bool:
  match state:
    case State{_,_,_,pending}: Bool.not(Nat.is_lt(List.length(&2,Tick,pending),128n))
def contains(rows: List<&2,Tick>,+target: U32) -> Bool:
  match rows:
    case []: False{}
    case Tick{_,world,_,_} <> tail: Bool.or(U32.is_eq(world,target),contains(tail,target))
# Reasons: accepted0, inactive1, epoch2, stale-sequence3, axes4, late5,
# too-far6, duplicate-world-slot7, full8. Refusal never modifies the queue.
def reason(state: State,phase: U32,enabled: Bool,round: U32,seq: U32,+target: U32,+x: U32,+y: U32) -> U32:
  match state:
    case State{epoch,last,+world,+pending}:
      Bool.pick(U32,Bool.not(U32.is_gt(target,world)),5,Bool.pick(U32,Bool.not(activity(phase,enabled)),1,Bool.pick(U32,Bool.not(U32.is_eq(epoch,round)),2,Bool.pick(U32,Bool.not(U32.is_gt(seq,last)),3,Bool.pick(U32,Bool.not(Bool.and(U32.is_le(x,2),U32.is_le(y,2))),4,Bool.pick(U32,U32.is_gt((target - world : U32),60),6,Bool.pick(U32,contains(pending,target),7,Bool.pick(U32,Bool.not(Nat.is_lt(List.length(&2,Tick,pending),128n)),8,0))))))))

def push_choice(allowed: Bool,+reason: U32,+state: State,+seq: U32,target: U32,x: U32,y: U32) -> Admission:
  match allowed state:
    case True{} State{round,_,world,pending}: Admission{State{round,seq,world,List.append(&2,Tick,pending,[Tick{seq,target,x,y}])},True{},0}
    case False{} _: Admission{state,False{},reason}
def push_decided(+reason: U32,state: State,seq: U32,target: U32,x: U32,y: U32) -> Admission:
  push_choice(U32.is_eq(reason,0),reason,state,seq,target,x,y)
def push_active(+state: State,phase: U32,enabled: Bool,round: U32,+seq: U32,+target: U32,+x: U32,+y: U32) -> Admission:
  push_decided(reason(state,phase,enabled,round,seq,target,x,y),state,seq,target,x,y)
def push(state: State,round: U32,seq: U32,target: U32,x: U32,y: U32) -> Admission:
  push_active(state,0,True{},round,seq,target,x,y)
def accepted(admission: Admission) -> Bool:
  match admission:
    case Admission{_,value,_}: value
def admission_state(admission: Admission) -> State:
  match admission:
    case Admission{state,_,_}: state
def admission_reason(admission: Admission) -> U32:
  match admission:
    case Admission{_,_,value}: value

def find_selected(same: Bool,row: Tick,tail: Maybe<&2,Tick>) -> Maybe<&2,Tick>:
  match same:
    case True{}: Some{row}
    case False{}: tail
def find_at(rows: List<&2,Tick>,+target: U32) -> Maybe<&2,Tick>:
  match rows:
    case []: None{}
    case Tick{seq,+world,x,y} <> tail: find_selected(U32.is_eq(world,target),Tick{seq,world,x,y},find_at(tail,target))
def keep_selected(keep: Bool,row: Tick,tail: List<&2,Tick>) -> List<&2,Tick>:
  match keep:
    case True{}: row <> tail
    case False{}: tail
def future(rows: List<&2,Tick>,+resolved: U32) -> List<&2,Tick>:
  match rows:
    case []: []
    case Tick{seq,+world,x,y} <> tail: keep_selected(U32.is_gt(world,resolved),Tick{seq,world,x,y},future(tail,resolved))
def next_allowed(state: State,+next: U32) -> Bool:
  match state:
    case State{_,_,+world,_}: Bool.and(U32.is_lt(world,4294967295),U32.is_eq(next,(world + 1 : U32)))
def take_selected(allowed: Bool,+state: State,+next: U32) -> Taken:
  match allowed state:
    case False{} _: Taken{state,None{}}
    case True{} State{round,last,_,+pending}: Taken{State{round,last,next,future(pending,next)},find_at(pending,next)}
# The caller commits this tentative state only after Core.advanced is true.
def take_at(+state: State,+next: U32) -> Taken: take_selected(next_allowed(state,next),state,next)

def receipt_selected(applied: Bool,seq: U32,+world: U32,x: U32,y: U32) -> S.Receipt:
  match applied:
    case True{}: S.Receipt{seq,world,x,y,True{}}
    case False{}: S.Receipt{0,world,1,1,False{}}
def receipt(+world: U32,tick: Maybe<&2,Tick>) -> S.Receipt:
  match tick:
    case None{}: S.Receipt{0,world,1,1,False{}}
    case Some{Tick{seq,target,x,y}}: receipt_selected(U32.is_eq(target,world),seq,world,x,y)
