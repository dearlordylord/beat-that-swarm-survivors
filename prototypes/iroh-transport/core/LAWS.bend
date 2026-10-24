import Base
import protocol.bend as P

# Refusing a send cannot consume a sequence number or change any protocol state.
law refused_send_unchanged:
  for +state: P.State
  for text: String
  {P.send_state(P.send_decided(False{},state,text)) == state : P.State}

# Rejecting a receive cannot move the accepted remote frontier.
law rejected_receive_frontier:
  for +state: P.State
  for seq: U32
  for text: String
  {P.last_remote_seq(P.receive_state(P.receive_decided(False{},state,seq,text))) == P.last_remote_seq(state) : U32}

# Accepting a receive installs exactly its sequence number as the remote frontier.
law accepted_receive_frontier:
  for state: P.State
  for +seq: U32
  for text: String
  {P.last_remote_seq(P.receive_state(P.receive_decided(True{},state,seq,text))) == seq : U32}

# Rejection cannot increase the number of delivered application messages.
law rejected_receive_delivery_count:
  for +state: P.State
  for seq: U32
  for text: String
  {P.received_count(P.receive_state(P.receive_decided(False{},state,seq,text))) == P.received_count(state) : U32}
