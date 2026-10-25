import Base
import ./coop-input-flow.bend as I
import ./coop-snapshot-receipts.bend as R
import ./coop-snapshot-flow.bend as F
import ./coop-session.bend as S

# One native write carries input plus latest application receipt together.
# Completion identity is local; command fields and host receipt tokens stay intact.
type Packet is Data: Packet{epoch:U32,id:U32,batch:Maybe<&2,I.Batch>,receipt:Maybe<&2,F.Receipt>}
type State is Data: State{epoch:U32,nextId:U32,input:I.State,receipts:R.State,flight:Maybe<&2,Packet>,failed:Bool}
type Admission is Data: Admission{state:State,accepted:Bool}
type Prepared is Data: Prepared{state:State,packet:Maybe<&2,Packet>}
type Payload is Data: Payload{receipt:Maybe<&2,F.Receipt>,commands:List<&2,S.Command>}
def max_frame_bytes() -> U32: 5190
def fresh(+epoch:U32) -> State: State{epoch,0,I.fresh(epoch),R.fresh(epoch),None{},False{}}
def admitted(epoch:U32,next:U32,receipts:R.State,flight:Maybe<&2,Packet>,failed:Bool,result:I.Admission) -> Admission:
  match result:
    case I.Admission{input,accepted}: Admission{State{epoch,next,input,receipts,flight,failed},accepted}
def enqueue_selected(allowed:Bool,+state:State,command:S.Command) -> Admission:
  match allowed state:
    case True{} State{epoch,next,input,receipts,flight,failed}: admitted(epoch,next,receipts,flight,failed,I.enqueue(input,command))
    case False{} _: Admission{state,False{}}
def enqueue(+state:State,command:S.Command) -> Admission:
  match state:
    case State{_,_,_,_,_,failed}: enqueue_selected(Bool.not(failed),state,command)
def offer_selected(allowed:Bool,+state:State,token:U32,observation:U32) -> State:
  match allowed state:
    case True{} State{epoch,next,input,receipts,flight,failed}: State{epoch,next,input,R.offer(receipts,token,observation),flight,failed}
    case False{} _: state
def offer_receipt(+state:State,token:U32,observation:U32) -> State:
  match state:
    case State{_,_,_,_,_,failed}: offer_selected(Bool.not(failed),state,token,observation)
def ready(state:State) -> Bool:
  match state:
    case State{_,next,input,receipts,None{},False{}}: Bool.and(U32.is_lt(next,4294967295),Bool.or(I.ready(input),R.ready(receipts)))
    case _: False{}
def batch_present(value:Maybe<&2,I.Batch>) -> Bool:
  match value:
    case None{}: False{}
    case Some{_}: True{}
def combined(available:Bool,+epoch:U32,+next:U32,input:I.State,receipts:R.State,+batch:Maybe<&2,I.Batch>,+receipt:Maybe<&2,F.Receipt>) -> Prepared:
  match available:
    case False{}: Prepared{State{epoch,next,input,receipts,None{},False{}},None{}}
    case True{}:
      +packet:Packet = Packet{epoch,(next + 1 : U32),batch,receipt}
      Prepared{State{epoch,(next + 1 : U32),input,receipts,Some{packet},False{}},Some{packet}}
def prepared_children(epoch:U32,next:U32,input:I.Prepared,receipts:R.Prepared) -> Prepared:
  match input receipts:
    case I.Prepared{input,+batch} R.Prepared{receipts,+receipt}: combined(Bool.or(batch_present(batch),R.present(receipt)),epoch,next,input,receipts,batch,receipt)
def prepare_selected(allowed:Bool,+state:State) -> Prepared:
  match allowed state:
    case True{} State{epoch,next,input,receipts,None{},False{}}: prepared_children(epoch,next,I.prepare(input),R.prepare(receipts))
    case _ _: Prepared{state,None{}}
def prepare(+state:State) -> Prepared: prepare_selected(ready(state),state)
def matches(state:State,+epoch:U32,+id:U32) -> Bool:
  match state:
    case State{current,_,_,_,Some{Packet{packetEpoch,packetId,_,_}},False{}}: Bool.and(U32.is_eq(current,epoch),Bool.and(U32.is_eq(packetEpoch,epoch),U32.is_eq(packetId,id)))
    case _: False{}
def completed_input(batch:Maybe<&2,I.Batch>,input:I.State) -> I.State:
  match batch:
    case None{}: input
    case Some{I.Batch{epoch,id,_}}: I.complete(input,epoch,id)
def completed_receipt(receipt:Maybe<&2,F.Receipt>,receipts:R.State,epoch:U32) -> R.State:
  match receipt:
    case None{}: receipts
    case Some{F.Receipt{token,observation}}: R.complete(receipts,epoch,token,observation)
def complete_selected(matching:Bool,+state:State) -> State:
  match matching state:
    case True{} State{+epoch,next,input,receipts,Some{Packet{_,_,batch,receipt}},failed}: State{epoch,next,completed_input(batch,input),completed_receipt(receipt,receipts,epoch),None{},failed}
    case _ _: state
def complete(+state:State,epoch:U32,id:U32) -> State: complete_selected(matches(state,epoch,id),state)
def failed_input(batch:Maybe<&2,I.Batch>,input:I.State) -> I.State:
  match batch:
    case None{}: input
    case Some{I.Batch{epoch,id,_}}: I.fail(input,epoch,id)
def failed_input_packet(packet:Maybe<&2,Packet>,input:I.State) -> I.State:
  match packet:
    case None{}: input
    case Some{Packet{_,_,batch,_}}: failed_input(batch,input)
def fail_selected(matching:Bool,+state:State) -> State:
  match matching state:
    case True{} State{epoch,next,input,receipts,+flight,failed}: State{epoch,next,failed_input_packet(flight,input),receipts,flight,True{}}
    case _ _: state
def fail(+state:State,epoch:U32,id:U32) -> State: fail_selected(matches(state,epoch,id),state)
def encoded_batch(value:Maybe<&2,I.Batch>) -> String:
  match value:
    case None{}: "-"
    case Some{batch}: I.encode(batch)
def encoded_receipt(value:Maybe<&2,F.Receipt>) -> String:
  match value:
    case None{}: "-"
    case Some{F.Receipt{token,observation}}: F.encode_receipt(token,observation)
def encode(packet:Packet) -> String:
  match packet:
    case Packet{_,_,batch,receipt}: "BSC1\n" ++ encoded_receipt(receipt) ++ "\n" ++ encoded_batch(batch)
def parsed_receipt(value:Maybe<&2,F.Receipt>) -> Maybe<&2,Maybe<&2,F.Receipt>>:
  match value:
    case None{}: None{}
    case Some{receipt}: Some{Some{receipt}}
def receipt_selected(absent:Bool,text:String) -> Maybe<&2,Maybe<&2,F.Receipt>>:
  match absent:
    case True{}: Some{None{}}
    case False{}: parsed_receipt(F.decode_receipt(text))
def receipt_field(+text:String) -> Maybe<&2,Maybe<&2,F.Receipt>>:
  receipt_selected(String.eq(text,"-"),text)
def join_lines(rows:List<&2,String>) -> String:
  match rows:
    case []: ""
    case head <> []: head
    case head <> tail: head ++ "\n" ++ join_lines(tail)
def empty_marker(rows:List<&2,String>) -> Bool:
  match rows:
    case [text]: String.eq(text,"-")
    case _: False{}
def command_selected(absent:Bool,rows:List<&2,String>) -> Maybe<&2,List<&2,S.Command>>:
  match absent:
    case True{}: Some{[]}
    case False{}: I.decode(join_lines(rows))
def command_field(+rows:List<&2,String>) -> Maybe<&2,List<&2,S.Command>>:
  command_selected(empty_marker(rows),rows)
def assembled(receipt:Maybe<&2,Maybe<&2,F.Receipt>>,commands:Maybe<&2,List<&2,S.Command>>) -> Maybe<&2,Payload>:
  match receipt commands:
    case Some{receipt} Some{commands}: Some{Payload{receipt,commands}}
    case _ _: None{}
def fallback_receipt(receipt:Maybe<&2,F.Receipt>,text:String) -> Maybe<&2,Payload>:
  match receipt:
    case Some{receipt}: Some{Payload{Some{receipt},[]}}
    case None{}: assembled(Some{None{}},I.decode(text))
def composite(rows:List<&2,String>) -> Bool:
  match rows:
    case head <> _ <> _: String.eq(head,"BSC1")
    case _: False{}
def packet_lines(rows:List<&2,String>) -> Maybe<&2,Payload>:
  match rows:
    case _ <> receipt <> commands: assembled(receipt_field(receipt),command_field(commands))
    case _: None{}
def decode_kind(combined:Bool,rows:List<&2,String>,+text:String) -> Maybe<&2,Payload>:
  match combined:
    case True{}: packet_lines(rows)
    case False{}: fallback_receipt(F.decode_receipt(text),text)
def decode_lines(+rows:List<&2,String>,text:String) -> Maybe<&2,Payload>:
  decode_kind(composite(rows),rows,text)
def decode_selected(allowed:Bool,+text:String) -> Maybe<&2,Payload>:
  match allowed:
    case False{}: None{}
    case True{}: decode_lines(I.lines(text,""),text)
def decode(+text:String) -> Maybe<&2,Payload>:
  decode_selected(Nat.is_le(String.length(text),U32.to_nat(max_frame_bytes())),text)
