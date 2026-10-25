import Base
import ./coop-protocol.bend as Protocol

# At most sixteen application-unacknowledged snapshots, one native write and one
# latest pending observation. Native completion never acknowledges application
# admission; cumulative application ACK never completes the native write.
type State is Data: State{token:U32,pending:Maybe<&2,U32>,writing:Maybe<&2,U32>,flights:List<&2,U32>,last:U32,offered:Bool}
type Prepared is Data: Prepared{state:State,observation:Maybe<&2,U32>}
type Receipt is Data: Receipt{token:U32,observation:U32}
def window() -> Nat: 16n
def fresh(token:U32) -> State: State{token,None{},None{},[],0,False{}}
def offer_allowed(state:State,observation:U32) -> Bool:
  match state:
    case State{_,_,_,_,last,offered}: Bool.or(Bool.not(offered),U32.is_gt(observation,last))
def offer_selected(allowed:Bool,+state:State,+observation:U32) -> State:
  match allowed state:
    case True{} State{token,_,writing,flights,_,_}: State{token,Some{observation},writing,flights,observation,True{}}
    case False{} _: state
def offer(+state:State,+observation:U32) -> State: offer_selected(offer_allowed(state,observation),state,observation)
def ready(state:State) -> Bool:
  match state:
    case State{_,Some{_},None{},flights,_,_}: Nat.is_lt(List.length(&2,U32,flights),window())
    case _: False{}
def flight_rows(rows:List<&2,U32>,observation:U32) -> List<&2,U32>:
  List.take(&2,U32,List.append(&2,U32,rows,[observation]),window())
def prepare_selected(allowed:Bool,+state:State) -> Prepared:
  match allowed state:
    case True{} State{token,Some{+observation},None{},flights,last,offered}: Prepared{State{token,None{},Some{observation},flight_rows(flights,observation),last,offered},Some{observation}}
    case _ _: Prepared{state,None{}}
def prepare(+state:State) -> Prepared: prepare_selected(ready(state),state)
def writing_matches(state:State,+token:U32,observation:U32) -> Bool:
  match state:
    case State{current,_,Some{writing},_,_,_}: Bool.and(U32.is_eq(current,token),U32.is_eq(writing,observation))
    case _: False{}
def complete_selected(matching:Bool,+state:State) -> State:
  match matching state:
    case True{} State{token,pending,_,flights,last,offered}: State{token,pending,None{},flights,last,offered}
    case False{} _: state
def complete(+state:State,token:U32,observation:U32) -> State: complete_selected(writing_matches(state,token,observation),state)
def contains(rows:List<&2,U32>,+observation:U32) -> Bool:
  match rows:
    case []: False{}
    case head <> tail: Bool.or(U32.is_eq(head,observation),contains(tail,observation))
def matches(state:State,+token:U32,observation:U32) -> Bool:
  match state:
    case State{current,_,_,flights,_,_}: Bool.and(U32.is_eq(current,token),contains(flights,observation))
def keep_flight(keep:Bool,observation:U32,rows:List<&2,U32>) -> List<&2,U32>:
  match keep:
    case True{}: observation <> rows
    case False{}: rows
def unacknowledged(rows:List<&2,U32>,+observation:U32) -> List<&2,U32>:
  match rows:
    case []: []
    case +head <> tail: keep_flight(U32.is_gt(head,observation),head,unacknowledged(tail,observation))
def ack_selected(matching:Bool,+state:State,observation:U32) -> State:
  match matching state:
    case True{} State{token,pending,writing,flights,last,offered}: State{token,pending,writing,unacknowledged(flights,observation),last,offered}
    case False{} _: state
def ack(+state:State,+token:U32,+observation:U32) -> State: ack_selected(matches(state,token,observation),state,observation)
def encode_receipt(token:U32,observation:U32) -> String: "BSA1|" ++ U32.show(token) ++ "|" ++ U32.show(observation)
def decode_fields(rows:List<String>) -> Maybe<&2,Receipt>:
  match rows:
    case ["BSA1",token,observation]:
      do Maybe<&2,Receipt>:
        t : U32 <- Protocol.number(token)
        o : U32 <- Protocol.number(observation)
        return Receipt{t,o}
    case _: None{}
def decode_bounded(allowed:Bool,text:String) -> Maybe<&2,Receipt>:
  match allowed:
    case True{}: decode_fields(Protocol.fields(text,""))
    case False{}: None{}
def decode_receipt(+text:String) -> Maybe<&2,Receipt>: decode_bounded(Nat.is_le(String.length(text),26n),text)
