import Base
import protocol.bend as P
import LAWS.bend as Laws

def Laws.refused_send_unchanged(state,text): {==}
def Laws.rejected_receive_frontier(state,seq,text):
  match state:
    case P.State{_,_,_,_,_}: {==}
def Laws.accepted_receive_frontier(state,seq,text):
  match state:
    case P.State{_,_,_,_,_}: {==}
def Laws.rejected_receive_delivery_count(state,seq,text):
  match state:
    case P.State{_,_,_,_,_}: {==}
