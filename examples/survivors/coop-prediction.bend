import Base
import player-movement.bend as M
import coop-session.bend as S

# Display-only local movement history. It cannot change an ECS world, damage,
# pickups, XP or rewards. Cumulative consumed counts make repeated ACKs safe.
type Segment is Data: Segment{seq: U32,x: U32,y: U32,steps: U32,consumed: U32}
type State is Data: State{x: F32,y: F32,distance: F32,enabled: Bool,segments: List<&2,Segment>,age: U32,observation: U32}
type Replay is Data: Replay{point: M.Point,remaining: U32}
def horizon() -> U32: M.horizon()
def allowed(phase: U32,hp: U32,connected: Bool) -> Bool: Bool.and(connected,Bool.and(U32.is_eq(phase,0),U32.is_gt(hp,0)))
def fresh(x: F32,y: F32,distance: F32,enabled: Bool) -> State: State{x,y,distance,enabled,[],0,0}
def view(state: State) -> M.Point:
  match state:
    case State{x,y,_,_,_,_,_}: M.Point{x,y}
def command_new(allowed: Bool,+state: State,seq: U32,x: U32,y: U32) -> State:
  match allowed state:
    case True{} State{px,py,distance,enabled,segments,age,observation}: State{px,py,distance,enabled,Segment{seq,x,y,0,0} <> List.take(&2,Segment,segments,63n),age,observation}
    case False{} _: state
def newest(rows: List<&2,Segment>) -> U32:
  match rows:
    case []: 0
    case Segment{seq,_,_,_,_} <> _: seq
def command(+state: State,+seq: U32,+x: U32,+y: U32) -> State:
  match state:
    case State{px,py,distance,enabled,+segments,age,observation}: command_new(Bool.and(U32.is_gt(seq,newest(segments)),Bool.and(U32.is_le(x,2),U32.is_le(y,2))),State{px,py,distance,enabled,segments,age,observation},seq,x,y)
def tick_point(+distance: F32,enabled: Bool,+age: U32,observation: U32,segments: List<&2,Segment>,point: M.Point) -> State:
  match point:
    case M.Point{x,y}: State{x,y,distance,enabled,segments,(age + 1 : U32),observation}
def tick_allowed(allowed: Bool,+state: State) -> State:
  match allowed state:
    case True{} State{px,py,+distance,+enabled,Segment{seq,+x,+y,+steps,consumed} <> tail,+age,observation}:
      tick_point(distance,enabled,age,observation,Segment{seq,x,y,U32.min((steps + 1 : U32),65535),consumed} <> tail,M.move_point(px,py,distance,S.axis(x),S.axis(y)))
    case True{} State{px,py,distance,enabled,[],age,observation}: State{px,py,distance,enabled,[],(age + 1 : U32),observation}
    case False{} _: state
def tick(+state: State) -> State:
  match state:
    case State{_,_,_,enabled,_,age,_}: tick_allowed(Bool.and(enabled,U32.is_lt(age,horizon())),state)
def remaining(+total: U32,consumed: U32) -> U32: (total - U32.min(total,consumed) : U32)
def acknowledged_row(+seq: U32,+reported: U32,+expired: Bool,row: Segment,+tail: List<&2,Segment>) -> List<&2,Segment>:
  match row:
    case Segment{+id,+x,+y,+steps,+prior}:
      +consumed = U32.max(prior,reported)
      +aligned = U32.max(steps,consumed)
      Bool.pick(List<&2,Segment>,Bool.pick(Bool,expired,U32.is_gt(id,seq),U32.is_ge(id,seq)),Bool.pick(Segment,U32.is_eq(id,seq),Segment{id,x,y,aligned,Bool.pick(U32,expired,aligned,consumed)},Segment{id,x,y,steps,prior}) <> tail,tail)
def acknowledge(rows: List<&2,Segment>,+seq: U32,+consumed: U32,+expired: Bool) -> List<&2,Segment>:
  match rows:
    case []: []
    case row <> rest: acknowledged_row(seq,consumed,expired,row,acknowledge(rest,seq,consumed,expired))
def move_steps(fuel: Nat,+distance: F32,+dx: F32,+dy: F32,point: M.Point) -> M.Point:
  match fuel point:
    case 0n point: point
    case 1n+rest M.Point{x,y}: move_steps(rest,distance,dx,dy,M.move_point(x,y,distance,dx,dy))
def replay_segment(+distance: F32,segment: Segment,state: Replay) -> Replay:
  match segment state:
    case Segment{_,x,y,steps,consumed} Replay{point,+budget}:
      +count = U32.min(budget,remaining(steps,consumed))
      Replay{move_steps(U32.to_nat(count),distance,S.axis(x),S.axis(y),point),(budget - count : U32)}
def replay(rows: List<&2,Segment>,+distance: F32,state: Replay) -> Replay:
  match rows:
    case []: state
    case row <> rest: replay(rest,distance,replay_segment(distance,row,state))
def replayed(+distance: F32,+segments: List<&2,Segment>,observation: U32,state: Replay) -> State:
  match state:
    case Replay{M.Point{x,y},left}: State{x,y,distance,True{},segments,(horizon() - left : U32),observation}
def reconciled_history(+observation: U32,x: F32,y: F32,+distance: F32,+segments: List<&2,Segment>) -> State:
  replayed(distance,segments,observation,replay(List.reverse(&2,Segment,segments),distance,Replay{M.Point{x,y},horizon()}))
def reconcile_enabled(prior: Bool,+state: State,+observation: U32,x: F32,y: F32,distance: F32,receipt: S.Receipt) -> State:
  match prior state receipt:
    case True{} State{_,_,_,_,segments,_,_} S.Receipt{seq,steps,_,_,expired}: reconciled_history(observation,x,y,distance,acknowledge(segments,seq,steps,expired))
    case False{} _ _: State{x,y,distance,True{},[],0,observation}
def reconcile_new(allowed: Bool,+state: State,+observation: U32,+x: F32,+y: F32,+distance: F32,+enabled: Bool,receipt: S.Receipt) -> State:
  match allowed state enabled:
    case False{} _ _: state
    case True{} _ False{}: State{x,y,distance,False{},[],0,observation}
    case True{} State{px,py,priorDistance,+prior,segments,age,oldObservation} True{}: reconcile_enabled(prior,State{px,py,priorDistance,prior,segments,age,oldObservation},observation,x,y,distance,receipt)
def observation_newer(state: State,observation: U32) -> Bool:
  match state:
    case State{_,_,_,_,_,_,prior}: U32.is_gt(observation,prior)
def reconcile(+state: State,+observation: U32,x: F32,y: F32,distance: F32,enabled: Bool,receipt: S.Receipt) -> State:
  reconcile_new(observation_newer(state,observation),state,observation,x,y,distance,enabled,receipt)
