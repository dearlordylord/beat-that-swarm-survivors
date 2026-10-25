import Base
import ./coop-input-queue.bend as Q
import ./coop-input-queue-LAWS.bend as L

def L.reset_exact(round): {==}
def L.admission_exact(epoch,last,pending,round,seq,x,y): {==}
def accepted_exact(allowed: Bool,state: Q.State,seq: U32,x: U32,y: U32) -> {Q.accepted(Q.push_decided(allowed,state,seq,x,y)) == allowed : Bool}:
  match allowed state:
    case False{} state: {==}
    case True{} Q.State{round,last,pending}: {==}
def L.push_accepts_exactly(state,round,seq,x,y): accepted_exact(Q.allowed(state,round,seq,x,y),state,seq,x,y)
def L.refused_preserves(state,round,seq,x,y,denied):
  %denied : {Q.admission_state(Q.push_decided(_,state,seq,x,y)) == state : Q.State}
  {==}
def L.accepted_appends(epoch,last,pending,round,seq,x,y,allowed):
  %allowed : {Q.push_decided(_,Q.State{epoch,last,pending},seq,x,y) == Q.Admission{Q.State{epoch,seq,List.append(&2,Q.Tick,pending,[Q.Tick{seq,x,y}])},True{}} : Q.Admission}
  {==}
def L.take_one_exact(round,last,head,tail): {==}
def L.empty_is_neutral(round,last): {==}
def L.old_epoch_refused(epoch,last,pending,round,seq,x,y,different):
  %different : {Bool.and(_,Bool.and(U32.is_gt(seq,last),Bool.and(Bool.and(U32.is_le(x,2),U32.is_le(y,2)),Nat.is_lt(List.length(&2,Q.Tick,pending),128n)))) == False{} : Bool}
  {==}

def L.receipt_one_exact(previous,seq,x,y): {==}
def L.receipt_empty_preserves(previous): {==}
def L.activity_exact(phase,enabled): {==}
def active_push_choice(active: Bool,+state: Q.State,+round: U32,+seq: U32,+x: U32,+y: U32) -> {Q.push_activity(active,state,round,seq,x,y) == Bool.pick(Q.Admission,active,Q.push(state,round,seq,x,y),Q.Admission{state,False{}}) : Q.Admission}:
  match active:
    case False{}: {==}
    case True{}: {==}
def L.active_push_exact(state,phase,enabled,round,seq,x,y): active_push_choice(Q.activity(phase,enabled),state,round,seq,x,y)
def L.inactive_refused(state,phase,enabled,round,seq,x,y,inactive):
  %inactive : {Q.push_activity(_,state,round,seq,x,y) == Q.Admission{state,False{}} : Q.Admission}
  {==}
def L.overflow_exact(epoch,last,pending,phase,enabled,round,seq,x,y): {==}
