import Base

type State is Data: Active{} Draining{remaining:U32} Closed{}
def fresh() -> State: Active{}
def terminal(+phase:U32) -> Bool: Bool.or(U32.is_eq(phase,3),U32.is_eq(phase,4))
def begin_selected(empty:Bool,remaining:U32) -> State:
  match empty:
    case True{}: Closed{}
    case False{}: Draining{remaining}
def begin_count(+remaining:U32) -> State: begin_selected(U32.is_eq(remaining,0),remaining)
def begin(state:State,remaining:U32) -> State:
  match state:
    case Active{}: begin_count(remaining)
    case _: state
def applied(state:State) -> State:
  match state:
    case Draining{remaining}: begin_count(U32.sub(remaining,1))
    case _: state
def expire(state:State) -> State:
  match state:
    case Draining{_}: Closed{}
    case _: state
def active(state:State) -> Bool:
  match state:
    case Active{}: True{}
    case _: False{}
def closed(state:State) -> Bool:
  match state:
    case Closed{}: True{}
    case _: False{}
def drain_milliseconds() -> U32: 20000
