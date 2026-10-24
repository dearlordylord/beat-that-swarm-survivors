# A per-authenticated-connection protocol. IO and peer identity belong to Iroh.
import Base

type State is Data: State{nextSeq: U32,lastRemoteSeq: U32,sent: U32,received: U32,rejected: U32}
type Send is Data: Send{state: State,accepted: Bool,wire: String,seq: U32,text: String,reason: String}
type Receive is Data: Receive{state: State,accepted: Bool,seq: U32,text: String,reason: String}
type Part is Data: Part{head: String,tail: String,found: Bool}

def fresh() -> State: State{1,0,0,0,0}
def next_seq(state: State) -> U32:
  match state:
    case State{next,_,_,_,_}: next
def last_remote_seq(state: State) -> U32:
  match state:
    case State{_,last,_,_,_}: last
def received_count(state: State) -> U32:
  match state:
    case State{_,_,_,received,_}: received
def rejected(state: State) -> State:
  match state:
    case State{next,last,sent,received,denied}: State{next,last,sent,received,(denied + 1 : U32)}
def scalar_text(text: String) -> Bool:
  match text:
    case SNil{}: True{}
    case SCon{Chr{+code},rest}:
      Bool.and(Bool.and(U32.is_le(code,1114111),Bool.or(U32.is_lt(code,55296),U32.is_gt(code,57343))),scalar_text(rest))
def text_allowed(+text: String) -> Bool:
  Bool.and(Bool.not(String.is_empty(text)),Bool.and(Nat.is_le(String.length(text),256n),scalar_text(text)))
def encode(seq: U32,text: String) -> String: "BIP1|" ++ U32.show(seq) ++ "|" ++ text

def send_decided(allowed: Bool,+state: State,+text: String) -> Send:
  match allowed state:
    case False{} state: Send{state,False{},"",0,"","Text must contain 1–256 Unicode scalar values, and sequence space must remain."}
    case True{} State{+next,last,sent,received,denied}:
      Send{State{(next + 1 : U32),last,(sent + 1 : U32),received,denied},True{},encode(next,text),next,text,""}
def send(+state: State,+text: String) -> Send:
  send_decided(Bool.and(text_allowed(text),U32.is_gt(next_seq(state),0)),state,text)

def receive_decided(allowed: Bool,+state: State,+seq: U32,+text: String) -> Receive:
  match allowed state:
    case False{} state: Receive{rejected(state),False{},seq,"","Sequence is zero, duplicate or older than the accepted frontier."}
    case True{} State{next,_,sent,received,denied}:
      Receive{State{next,seq,sent,(received + 1 : U32),denied},True{},seq,text,""}
def receive_state(result: Receive) -> State:
  match result:
    case Receive{state,_,_,_,_}: state
def send_state(result: Send) -> State:
  match result:
    case Send{state,_,_,_,_,_}: state
def refuse(+state: State,reason: String) -> Receive: Receive{rejected(state),False{},0,"",reason}

def split(s: String,acc: String) -> Part:
  match s:
    case SNil{}: Part{String.reverse(acc),"",False{}}
    case SCon{'|',rest}: Part{String.reverse(acc),rest,True{}}
    case SCon{char,rest}: split(rest,SCon{char,acc})
def parsed_text(allowed: Bool,+state: State,+seq: U32,text: String) -> Receive:
  match allowed:
    case False{}: refuse(state,"Text must contain 1–256 Unicode scalar values.")
    case True{}: receive_decided(Bool.and(U32.is_gt(seq,0),U32.is_gt(seq,last_remote_seq(state))),state,seq,text)
def parsed_sequence_gate(valid: Bool,state: State,n: Nat,+text: String) -> Receive:
  match valid:
    case False{}: refuse(state,"Invalid or noncanonical sequence number.")
    case True{}: parsed_text(text_allowed(text),state,U32.from_nat(n),text)
def parsed_sequence(value: Maybe<&2,Nat>,+state: State,+digits: String,+text: String) -> Receive:
  match value:
    case None{}: refuse(state,"Invalid sequence number.")
    case Some{+n}:
      parsed_sequence_gate(Bool.and(Nat.is_le(n,4294967295n),String.eq(Nat.show(n),digits)),state,n,text)
def parsed_header(part: Part,state: State) -> Receive:
  match part:
    case Part{+digits,+text,True{}}: parsed_sequence(Nat.read(digits),state,digits,text)
    case _: refuse(state,"Missing sequence separator.")
def parsed_version(part: Part,state: State) -> Receive:
  match part:
    case Part{"BIP1",text,True{}}: parsed_header(split(text,""),state)
    case _: refuse(state,"Unsupported protocol version.")
def receive_bounded(allowed: Bool,state: State,wire: String) -> Receive:
  match allowed:
    case False{}: refuse(state,"Wire message exceeds the protocol character bound.")
    case True{}: parsed_version(split(wire,""),state)
def receive(+state: State,+wire: String) -> Receive:
  receive_bounded(Nat.is_le(String.length(wire),280n),state,wire)
