import Base
import ./coop-session.bend as S

# Each row is one fixed movement tick, not a held direction heartbeat.
# The host commits the Taken state only when its world step actually advanced.
type Tick is Data: Tick{seq: U32,x: U32,y: U32}
type State is Data: State{round: U32,last: U32,pending: List<&2,Tick>}
type Admission is Data: Admission{state: State,accepted: Bool}
type Taken is Data: Taken{state: State,tick: Maybe<&2,Tick>}
def fresh(round: U32) -> State: State{round,0,[]}
def full(state: State) -> Bool:
  match state:
    case State{_,_,pending}: Bool.not(Nat.is_lt(List.length(&2,Tick,pending),128n))
def allowed(state: State,round: U32,seq: U32,+x: U32,+y: U32) -> Bool:
  match state:
    case State{epoch,last,pending}: Bool.and(U32.is_eq(epoch,round),Bool.and(U32.is_gt(seq,last),Bool.and(Bool.and(U32.is_le(x,2),U32.is_le(y,2)),Nat.is_lt(List.length(&2,Tick,pending),128n))))
def push_decided(allowed: Bool,+state: State,+seq: U32,x: U32,y: U32) -> Admission:
  match allowed state:
    case False{} _: Admission{state,False{}}
    case True{} State{round,_,pending}: Admission{State{round,seq,List.append(&2,Tick,pending,[Tick{seq,x,y}])},True{}}
def push(+state: State,round: U32,+seq: U32,+x: U32,+y: U32) -> Admission: push_decided(allowed(state,round,seq,x,y),state,seq,x,y)
def accepted(admission: Admission) -> Bool:
  match admission:
    case Admission{_,accepted}: accepted
def admission_state(admission: Admission) -> State:
  match admission:
    case Admission{state,_}: state
def take(state: State) -> Taken:
  match state:
    case State{round,last,[]}: Taken{State{round,last,[]},None{}}
    case State{round,last,head <> tail}: Taken{State{round,last,tail},Some{head}}

# Called only after committing the corresponding advanced world step.
def receipt(previous: S.Receipt,tick: Maybe<&2,Tick>) -> S.Receipt:
  match tick:
    case None{}: previous
    case Some{Tick{seq,x,y}}: S.Receipt{seq,1,x,y,False{}}

def activity(phase: U32,enabled: Bool) -> Bool: Bool.and(U32.is_eq(phase,0),enabled)
def push_activity(active: Bool,+state: State,round: U32,seq: U32,x: U32,y: U32) -> Admission:
  match active:
    case False{}: Admission{state,False{}}
    case True{}: push(state,round,seq,x,y)
def push_active(state: State,phase: U32,enabled: Bool,round: U32,seq: U32,x: U32,y: U32) -> Admission: push_activity(activity(phase,enabled),state,round,seq,x,y)

def overflowed(state: State,phase: U32,enabled: Bool,round: U32,seq: U32,+x: U32,+y: U32) -> Bool:
  match state:
    case State{epoch,last,pending}: Bool.and(activity(phase,enabled),Bool.and(Bool.not(Nat.is_lt(List.length(&2,Tick,pending),128n)),Bool.and(U32.is_eq(epoch,round),Bool.and(U32.is_gt(seq,last),Bool.and(U32.is_le(x,2),U32.is_le(y,2))))))
