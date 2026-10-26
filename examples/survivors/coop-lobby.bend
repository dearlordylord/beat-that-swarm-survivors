import Base

type Seat is Data: Seat{player: U32,character: U32,ready: Bool,connected: Bool}
type State is Data: State{started: Bool,seats: List<&2,Seat>,inputEpoch: U32}
def fresh(character: U32) -> State: State{False{},[Seat{0,character,True{},True{}}],0}
def seats(state: State) -> List<&2,Seat>:
  match state:
    case State{_,seats,_}: seats
def started(state: State) -> Bool:
  match state:
    case State{started,_,_}: started
def contains(rows: List<&2,Seat>,+player: U32) -> Bool:
  match rows:
    case []: False{}
    case Seat{+id,_,_,_} <> rest: Bool.or(U32.is_eq(id,player),contains(rest,player))
def admit(+state: State,+player: U32) -> Bool:
  match state:
    case State{started,+rows,_}: Bool.and(Bool.and(U32.is_gt(player,0),U32.is_lt(player,4)),Bool.or(Bool.not(started),contains(rows,player)))
def put(rows: List<&2,Seat>,+seat: Seat) -> List<&2,Seat>:
  match rows seat:
    case [] seat: [seat]
    case Seat{+id,character,ready,connected} <> +rest Seat{+player,+ch,+ok,+online}: Bool.pick(List<&2,Seat>,U32.is_eq(id,player),Seat{player,ch,ok,online} <> rest,Seat{id,character,ready,connected} <> put(rest,Seat{player,ch,ok,online}))
def update(state: State,seat: Seat) -> State:
  match state:
    case State{started,rows,epoch}: State{started,put(rows,seat),epoch}
def all_ready(rows: List<&2,Seat>) -> Bool:
  match rows:
    case []: True{}
    case Seat{_,_,ready,connected} <> rest: Bool.and(Bool.and(ready,connected),all_ready(rest))
def can_start(state: State) -> Bool:
  match state:
    case State{started,+rows,_}: Bool.and(Bool.not(started),Bool.and(Nat.is_le(2n,List.length(&2,Seat,rows)),all_ready(rows)))
def start_selected(allowed: Bool,state: State) -> State:
  match allowed state:
    case True{} State{_,rows,epoch}: State{True{},rows,epoch}
    case False{} state: state
def start(+state: State) -> State: start_selected(can_start(state),state)
def running(state: State) -> Bool:
  match state:
    case State{started,rows,_}: Bool.and(started,all_ready(rows))
def remove_seat(rows: List<&2,Seat>,+player: U32) -> List<&2,Seat>:
  match rows:
    case []: []
    case Seat{+id,character,ready,connected} <> rest: List.filter.put(Seat,Seat{id,character,ready,connected},remove_seat(rest,player),U32.is_ne(id,player))
def leave(state: State,+player: U32) -> State:
  match state:
    case State{+started,+rows,epoch}: State{started,Bool.pick(List<&2,Seat>,Bool.or(started,U32.is_eq(player,0)),rows,remove_seat(rows,player)),epoch}

def input_epoch(state: State) -> U32:
  match state:
    case State{_,_,epoch}: epoch
def pause(state: State) -> State:
  match state:
    case State{started,rows,epoch}: State{started,rows,(epoch + 1 : U32)}
