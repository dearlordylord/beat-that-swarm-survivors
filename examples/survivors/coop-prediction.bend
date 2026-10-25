import Base
import ./player-movement.bend as M
import ./coop-session.bend as S

# A command identity is not a simulation clock. Every local input names one
# immutable world tick; replay includes neutral world ticks between inputs.
type Input is Data: Input{seq:U32,targetWorldTick:U32,x:U32,y:U32}
type Direction is Data: Direction{x:U32,y:U32}
type State is Data: State{x:F32,y:F32,distance:F32,enabled:Bool,inputs:List<&2,Input>,anchorWorldTick:U32,displayWorldTick:U32,observation:U32,lastCommandSeq:U32}
def horizon() -> U32: M.horizon()
# Restore the native F32 ABI after a JSON number crossed the JS host boundary.
def from_bits(value:U32) -> F32:
  match value:
    case U32{word}: F32{word}
def normalize(value:F32) -> F32: from_bits(F32.bits(value))
def lead(+roundTripMs:U32) -> U32: U32.min(54,((U32.min(roundTripMs,1000) * 60 + 999) / 1000 + 4 : U32))
def allowed(phase:U32,hp:U32,connected:Bool) -> Bool: Bool.and(connected,Bool.and(U32.is_eq(phase,0),U32.is_gt(hp,0)))
def after(+tick:U32,amount:U32) -> U32: (tick + U32.min(amount,(4294967295 - tick : U32)) : U32)
def world_count(anchor:U32,+display:U32) -> U32: U32.min(horizon(),(display - U32.min(display,anchor) : U32))
def direction_selected(found:Bool,x:U32,y:U32,tail:Direction) -> Direction:
  match found:
    case True{}: Direction{x,y}
    case False{}: tail
def input_at(rows:List<&2,Input>,+worldTick:U32) -> Direction:
  match rows:
    case []: Direction{1,1}
    case Input{_,target,x,y} <> tail: direction_selected(U32.is_eq(target,worldTick),x,y,input_at(tail,worldTick))
def advance_point(point:M.Point,distance:F32,direction:Direction) -> M.Point:
  match point direction:
    case M.Point{x,y} Direction{dx,dy}: M.move_point(x,y,distance,S.axis(dx),S.axis(dy))
def replay_position(fuel:Nat,+worldTick:U32,+rows:List<&2,Input>,+distance:F32,point:M.Point) -> M.Point:
  match fuel:
    case 0n: point
    case 1n+rest: replay_position(rest,after(worldTick,1),rows,distance,advance_point(point,distance,input_at(rows,after(worldTick,1))))
def placed(distance:F32,enabled:Bool,rows:List<&2,Input>,anchor:U32,display:U32,observation:U32,last:U32,point:M.Point) -> State:
  match point:
    case M.Point{x,y}: State{x,y,distance,enabled,rows,anchor,display,observation,last}
def fresh_prepared(x:F32,y:F32,+distance:F32,+enabled:Bool,+anchorWorldTick:U32,initialLead:U32) -> State:
  +display = Bool.pick(U32,enabled,after(anchorWorldTick,U32.min(initialLead,54)),anchorWorldTick)
  placed(distance,enabled,[],anchorWorldTick,display,0,0,replay_position(U32.to_nat(world_count(anchorWorldTick,display)),anchorWorldTick,[],distance,M.Point{x,y}))
def fresh(x:F32,y:F32,distance:F32,enabled:Bool,anchorWorldTick:U32,initialLead:U32) -> State:
  fresh_prepared(normalize(x),normalize(y),normalize(distance),enabled,anchorWorldTick,initialLead)
def view(state:State) -> M.Point:
  match state:
    case State{x,y,_,_,_,_,_,_,_}: M.Point{x,y}
def can_tick(state:State) -> Bool:
  match state:
    case State{_,_,_,enabled,_,anchor,+display,_,_}: Bool.and(enabled,Bool.and(U32.is_lt(world_count(anchor,display),horizon()),U32.is_lt(display,4294967295)))
def next_world_tick(state:State) -> U32:
  match state:
    case State{_,_,_,_,_,_,display,_,_}: after(display,1)
def target_present(rows:List<&2,Input>,+worldTick:U32) -> Bool:
  match rows:
    case []: False{}
    case Input{_,target,_,_} <> tail: Bool.or(U32.is_eq(target,worldTick),target_present(tail,worldTick))
def command_allowed(+state:State,+seq:U32,+x:U32,+y:U32) -> Bool:
  match state:
    case State{_,_,_,_,rows,_,display,_,last}: Bool.and(can_tick(state),Bool.and(Bool.not(target_present(rows,after(display,1))),Bool.and(U32.is_gt(seq,last),Bool.and(U32.is_le(x,2),U32.is_le(y,2)))))
def command_selected(accept:Bool,+state:State,+seq:U32,x:U32,y:U32) -> State:
  match accept state:
    case False{} _: state
    case True{} State{px,py,distance,enabled,rows,anchor,+display,observation,_}: State{px,py,distance,enabled,Input{seq,after(display,1),x,y} <> List.take(&2,Input,rows,127n),anchor,display,observation,seq}
def command(+state:State,+seq:U32,+x:U32,+y:U32) -> State: command_selected(command_allowed(state,seq,x,y),state,seq,x,y)
def tick_selected(accept:Bool,+state:State) -> State:
  match accept state:
    case False{} _: state
    case True{} State{px,py,+distance,enabled,+rows,anchor,+display,observation,last}:
      placed(distance,enabled,rows,anchor,after(display,1),observation,last,advance_point(M.Point{px,py},distance,input_at(rows,after(display,1))))
def tick(+state:State) -> State: tick_selected(can_tick(state),state)
def keep_input(keep:Bool,row:Input,tail:List<&2,Input>) -> List<&2,Input>:
  match keep:
    case True{}: row <> tail
    case False{}: tail
def unresolved(rows:List<&2,Input>,+anchorWorldTick:U32) -> List<&2,Input>:
  match rows:
    case []: []
    case Input{+seq,+target,+x,+y} <> tail: keep_input(U32.is_gt(target,anchorWorldTick),Input{seq,target,x,y},unresolved(tail,anchorWorldTick))
def observation_newer(state:State,observation:U32) -> Bool:
  match state:
    case State{_,_,_,_,_,_,_,prior,_}: U32.is_gt(observation,prior)
def resync_needed(state:State,anchorWorldTick:U32) -> Bool:
  match state:
    case State{_,_,_,enabled,_,_,display,_,_}: Bool.or(Bool.not(enabled),U32.is_ge(anchorWorldTick,display))
def choose_lead(state:State,+anchorWorldTick:U32,+roundTripMs:U32,+currentLead:U32) -> U32:
  match state:
    case State{_,_,_,_,_,priorAnchor,_,_,_}:
      Bool.pick(U32,U32.is_ge(anchorWorldTick,priorAnchor),U32.min(54,U32.max(currentLead,lead(roundTripMs))),currentLead)
def cursor(state:State,+anchor:U32,initialLead:U32) -> U32:
  match state:
    case State{_,_,_,_,_,_,display,_,_}: U32.max(display,after(anchor,U32.min(initialLead,54)))
def reconcile_running(+state:State,observation:U32,+anchor:U32,x:F32,y:F32,+distance:F32,initialLead:U32) -> State:
  match state:
    case State{_,_,_,_,inputs,_,_,_,last}:
      +display = cursor(state,anchor,initialLead)
      +rows = unresolved(inputs,anchor)
      placed(distance,True{},rows,anchor,display,observation,last,replay_position(U32.to_nat(world_count(anchor,display)),anchor,rows,distance,M.Point{x,y}))
def reconcile_selected(newer:Bool,+state:State,observation:U32,+anchor:U32,x:F32,y:F32,distance:F32,enabled:Bool,initialLead:U32) -> State:
  match newer state enabled:
    case False{} _ _: state
    case True{} State{_,_,_,_,_,_,_,_,last} False{}: State{x,y,distance,False{},[],anchor,anchor,observation,last}
    case True{} _ True{}: reconcile_running(state,observation,anchor,x,y,distance,initialLead)

def anchor_world_tick(state:State) -> U32:
  match state:
    case State{_,_,_,_,_,anchor,_,_,_}: anchor
def matches_anchor(state:State,tick:U32) -> Bool: U32.is_eq(anchor_world_tick(state),tick)

def reconcile(+state:State,+observation:U32,+anchorWorldTick:U32,x:F32,y:F32,distance:F32,enabled:Bool,initialLead:U32) -> State:
  reconcile_selected(Bool.and(observation_newer(state,observation),U32.is_ge(anchorWorldTick,anchor_world_tick(state))),state,observation,anchorWorldTick,normalize(x),normalize(y),normalize(distance),enabled,initialLead)
