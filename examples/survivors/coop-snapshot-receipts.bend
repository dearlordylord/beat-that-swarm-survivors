import Base
import ./coop-snapshot-flow.bend as F

# Guest-side cumulative application receipts. Local connection epoch fences IO
# callbacks; Receipt.token names the host protocol epoch and is not that epoch.
# At most one native write and one replaceable latest pending receipt exist.
type State is Data: State{epoch:U32,latest:Maybe<&2,F.Receipt>,pending:Bool,flight:Maybe<&2,F.Receipt>}
type Prepared is Data: Prepared{state:State,receipt:Maybe<&2,F.Receipt>}
def max_frame_bytes() -> U32: 26
def max_buffered_bytes() -> U32: 52
def fresh(epoch:U32) -> State: State{epoch,None{},False{},None{}}
def newer(latest:Maybe<&2,F.Receipt>,token:U32,observation:U32) -> Bool:
  match latest:
    case None{}: True{}
    case Some{F.Receipt{current,last}}: Bool.and(U32.is_eq(current,token),U32.is_gt(observation,last))
def offer_allowed(state:State,token:U32,observation:U32) -> Bool:
  match state:
    case State{_,latest,_,_}: newer(latest,token,observation)
def offer_selected(allowed:Bool,+state:State,token:U32,observation:U32) -> State:
  match allowed state:
    case True{} State{epoch,_,_,flight}: State{epoch,Some{F.Receipt{token,observation}},True{},flight}
    case False{} _: state
def offer(+state:State,+token:U32,+observation:U32) -> State:
  offer_selected(offer_allowed(state,token,observation),state,token,observation)
def ready(state:State) -> Bool:
  match state:
    case State{_,Some{_},True{},None{}}: True{}
    case _: False{}
def prepare_selected(allowed:Bool,+state:State) -> Prepared:
  match allowed state:
    case True{} State{epoch,Some{+latest},True{},None{}}: Prepared{State{epoch,Some{latest},False{},Some{latest}},Some{latest}}
    case _ _: Prepared{state,None{}}
def prepare(+state:State) -> Prepared: prepare_selected(ready(state),state)
def matches(state:State,epoch:U32,token:U32,observation:U32) -> Bool:
  match state:
    case State{current,_,_,Some{F.Receipt{host,flight}}}: Bool.and(U32.is_eq(current,epoch),Bool.and(U32.is_eq(host,token),U32.is_eq(flight,observation)))
    case _: False{}
def complete_selected(matching:Bool,+state:State) -> State:
  match matching state:
    case True{} State{epoch,latest,pending,_}: State{epoch,latest,pending,None{}}
    case False{} _: state
def complete(+state:State,epoch:U32,token:U32,observation:U32) -> State:
  complete_selected(matches(state,epoch,token,observation),state)
def present(receipt:Maybe<&2,F.Receipt>) -> Bool:
  match receipt:
    case None{}: False{}
    case Some{_}: True{}
def buffered_count(state:State) -> U32:
  match state:
    case State{_,latest,pending,flight}: (Bool.to_u32(Bool.and(pending,present(latest))) + Bool.to_u32(present(flight)) : U32)
def buffered_bytes(state:State) -> U32: (buffered_count(state) * max_frame_bytes() : U32)
def encode(receipt:F.Receipt) -> String:
  match receipt:
    case F.Receipt{token,observation}: F.encode_receipt(token,observation)
