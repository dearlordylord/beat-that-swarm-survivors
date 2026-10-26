import Base

type Seat is Data: Seat{player: U32,character: U32,ready: Bool,connected: Bool}
type State is Data: State{started: Bool,seats: List<&2,Seat>}
def fresh(character: U32) -> State: State{False{},[Seat{0,character,True{},True{}}]}
def seats(state: State) -> List<&2,Seat>:
  match state:
    case State{_,seats}: seats
def started(state: State) -> Bool:
  match state:
    case State{started,_}: started
def contains(rows: List<&2,Seat>,+player: U32) -> Bool:
  match rows:
    case []: False{}
    case Seat{+id,_,_,_} <> rest: Bool.or(U32.is_eq(id,player),contains(rest,player))
def admit(+state: State,+player: U32) -> Bool:
  match state:
    case State{started,+rows}: Bool.and(Bool.and(U32.is_gt(player,0),U32.is_lt(player,4)),Bool.or(Bool.not(started),contains(rows,player)))
def put(rows: List<&2,Seat>,+seat: Seat) -> List<&2,Seat>:
  match rows seat:
    case [] seat: [seat]
    case Seat{+id,character,ready,connected} <> +rest Seat{+player,+ch,+ok,+online}: Bool.pick(List<&2,Seat>,U32.is_eq(id,player),Seat{player,ch,ok,online} <> rest,Seat{id,character,ready,connected} <> put(rest,Seat{player,ch,ok,online}))
def update(state: State,seat: Seat) -> State:
  match state:
    case State{started,rows}: State{started,put(rows,seat)}
def all_ready(rows: List<&2,Seat>) -> Bool:
  match rows:
    case []: True{}
    case Seat{_,_,ready,connected} <> rest: Bool.and(Bool.and(ready,connected),all_ready(rest))
def can_start(state: State) -> Bool:
  match state:
    case State{started,+rows}: Bool.and(Bool.not(started),Bool.and(Nat.is_le(2n,List.length(&2,Seat,rows)),all_ready(rows)))
def start_selected(allowed: Bool,state: State) -> State:
  match allowed state:
    case True{} State{_,rows}: State{True{},rows}
    case False{} state: state
def start(+state: State) -> State: start_selected(can_start(state),state)
def running(state: State) -> Bool:
  match state:
    case State{started,rows}: Bool.and(started,all_ready(rows))
