import Base
import ./coop-session.bend as S
import ./coop-protocol.bend as Protocol

# A bounded journal owns accepted commands until their ordered batch completes.
# Transport identity, assigned world tick and every command field stay intact.
type Batch is Data: Batch{epoch:U32,id:U32,commands:List<&2,S.Command>}
type State is Data: State{epoch:U32,nextId:U32,pending:List<&2,S.Command>,flight:Maybe<&2,Batch>,failed:Bool}
type Admission is Data: Admission{state:State,accepted:Bool}
type Prepared is Data: Prepared{state:State,batch:Maybe<&2,Batch>}
def max_commands() -> Nat: 64n
def max_inputs() -> Nat: 62n
def max_controls() -> Nat: 2n
def max_batch() -> Nat: 32n
def max_frame_bytes() -> U32: 5156
def fresh(epoch:U32) -> State: State{epoch,0,[],None{},False{}}
def is_input(command:S.Command) -> Bool:
  match command:
    case S.Command{_,_,_,_,S.MovementTick{_,_,_}}: True{}
    case _: False{}
def input_count(rows:List<&2,S.Command>) -> Nat:
  match rows:
    case []: 0n
    case head <> tail: Nat.add(Bool.pick(Nat,is_input(head),1n,0n),input_count(tail))
def flight_commands(flight:Maybe<&2,Batch>) -> List<&2,S.Command>:
  match flight:
    case None{}: []
    case Some{Batch{_,_,rows}}: rows
def journal(state:State) -> List<&2,S.Command>:
  match state:
    case State{_,_,pending,flight,_}: List.append(&2,S.Command,flight_commands(flight),pending)
def counts_allowed(input:Bool,+rows:List<&2,S.Command>) -> Bool:
  +total = List.length(&2,S.Command,rows)
  +inputs = input_count(rows)
  Bool.and(Nat.is_lt(total,max_commands()),Bool.pick(Bool,input,Nat.is_lt(inputs,max_inputs()),Nat.is_lt(Nat.sub(total,inputs),max_controls())))
def can_enqueue(+state:State,command:S.Command) -> Bool:
  match state:
    case State{_,_,_,_,failed}: Bool.and(Bool.not(failed),counts_allowed(is_input(command),journal(state)))
def enqueue_selected(allowed:Bool,+state:State,command:S.Command) -> Admission:
  match allowed state:
    case False{} _: Admission{state,False{}}
    case True{} State{epoch,next,pending,flight,failed}: Admission{State{epoch,next,List.append(&2,S.Command,pending,[command]),flight,failed},True{}}
def enqueue(+state:State,+command:S.Command) -> Admission: enqueue_selected(can_enqueue(state,command),state,command)
def ready(state:State) -> Bool:
  match state:
    case State{_,next,_ <> _,None{},False{}}: U32.is_lt(next,4294967295)
    case _: False{}
def reserved(epoch:U32,id:U32,pending:List<&2,S.Command>,+batch:Batch) -> Prepared:
  Prepared{State{epoch,id,pending,Some{batch},False{}},Some{batch}}
def prepare_selected(allowed:Bool,+state:State) -> Prepared:
  match allowed state:
    case True{} State{+epoch,+next,+pending,None{},False{}}:
      reserved(epoch,(next + 1 : U32),List.drop(&2,S.Command,pending,max_batch()),Batch{epoch,(next + 1 : U32),List.take(&2,S.Command,pending,max_batch())})
    case _ _: Prepared{state,None{}}
def prepare(+state:State) -> Prepared: prepare_selected(ready(state),state)
def matches(state:State,+epoch:U32,+id:U32) -> Bool:
  match state:
    case State{+current,_,_,Some{Batch{batchEpoch,batchId,_}},False{}}: Bool.and(U32.is_eq(current,epoch),Bool.and(U32.is_eq(batchEpoch,epoch),U32.is_eq(batchId,id)))
    case _: False{}
def complete_selected(matching:Bool,+state:State) -> State:
  match matching state:
    case True{} State{epoch,next,pending,_,failed}: State{epoch,next,pending,None{},failed}
    case False{} _: state
def complete(+state:State,epoch:U32,id:U32) -> State: complete_selected(matches(state,epoch,id),state)
def fail_selected(matching:Bool,+state:State) -> State:
  match matching state:
    case True{} State{epoch,next,pending,flight,_}: State{epoch,next,pending,flight,True{}}
    case False{} _: state
def fail(+state:State,epoch:U32,id:U32) -> State: fail_selected(matches(state,epoch,id),state)

def encode_rows(rows:List<&2,S.Command>) -> String:
  match rows:
    case []: ""
    case head <> []: Protocol.encode(head)
    case head <> tail: Protocol.encode(head) ++ "\n" ++ encode_rows(tail)
def encode_commands(commands:List<&2,S.Command>) -> String: "BSB1\n" ++ encode_rows(commands)
def encode(batch:Batch) -> String:
  match batch:
    case Batch{_,_,commands}: encode_commands(commands)
def line_choice(newline:Bool,yes:Unit -> List<&2,String>,no:Unit -> List<&2,String>) -> List<&2,String>:
  match newline:
    case True{}: yes(Unit{})
    case False{}: no(Unit{})
def lines(text:String,+acc:String) -> List<&2,String>:
  match text:
    case SNil{}: [String.reverse(acc)]
    case SCon{+char,+tail}: line_choice(Char.is_eq(char,'\n'),u => String.reverse(acc) <> lines(tail,""),u => lines(tail,SCon{char,acc}))
def parsed_row(head:Maybe<&2,S.Command>,tail:Maybe<&2,List<&2,S.Command>>) -> Maybe<&2,List<&2,S.Command>>:
  match head tail:
    case Some{command} Some{rows}: Some{command <> rows}
    case _ _: None{}
def parse_rows(rows:List<&2,String>) -> Maybe<&2,List<&2,S.Command>>:
  match rows:
    case []: Some{[]}
    case head <> tail: parsed_row(Protocol.decode(head),parse_rows(tail))
def rows_allowed(+rows:List<&2,String>) -> Bool: Bool.and(Nat.is_gt(List.length(&2,String,rows),0n),Nat.is_le(List.length(&2,String,rows),max_batch()))
def parse_selected(allowed:Bool,rows:List<&2,String>) -> Maybe<&2,List<&2,S.Command>>:
  match allowed:
    case False{}: None{}
    case True{}: parse_rows(rows)
def decode_kind(batch:Bool,+rows:List<&2,String>) -> Maybe<&2,List<&2,S.Command>>:
  match batch:
    case True{}: parse_selected(rows_allowed(rows),rows)
    case False{}: None{}
def decode_lines(rows:List<&2,String>) -> Maybe<&2,List<&2,S.Command>>:
  match rows:
    case []: None{}
    case head <> tail: decode_kind(String.eq(head,"BSB1"),tail)
def decode_selected(allowed:Bool,+text:String) -> Maybe<&2,List<&2,S.Command>>:
  match allowed:
    case False{}: None{}
    case True{}: decode_lines(lines(text,""))
def decode(+text:String) -> Maybe<&2,List<&2,S.Command>>: decode_selected(Nat.is_le(String.length(text),U32.to_nat(max_frame_bytes())),text)
