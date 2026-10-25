import Base
import ./coop-snapshot-flow.bend as F
import ./coop-snapshot-flow-LAWS.bend as L
import ../../vendor/bendlib/packages/bend-mathlib/list.bend as MathList
import ../../vendor/bendlib/packages/bend-mathlib/nat.bend as MathNat

def L.window_exact(): {==}
def L.fresh_exact(token): {==}
def L.offer_allowed_exact(token,pending,writing,flights,last,offered,observation): {==}
def L.offered_replaces_pending(token,pending,writing,flights,last,offered,observation): {==}
def L.rejected_offer_preserves(state,observation): {==}
def L.offer_wiring(state,observation): {==}
def L.ready_available(token,observation,flights,last,offered): {==}
def L.ready_writing(token,pending,writing,flights,last,offered):
  match pending:
    case None{}: {==}
    case Some{observation}: {==}
def L.ready_empty(token,writing,flights,last,offered): {==}
def L.prepare_waiting(token,observation,flights,last,offered): {==}
def L.prepare_refused(state): {==}
def L.prepare_wiring(state): {==}
def L.writing_matches_exact(token,pending,writing,flights,last,offered,other,observation): {==}
def L.writing_matches_idle(token,pending,flights,last,offered,other,observation): {==}
def L.complete_only_native(token,pending,writing,flights,last,offered): {==}
def L.complete_refused(state): {==}
def L.complete_wiring(state,token,observation): {==}
def L.contains_nil(observation): {==}
def L.contains_cons(head,tail,observation): {==}
def L.matches_exact(token,pending,writing,flights,last,offered,other,observation): {==}
def L.keep_flight_true(observation,rows): {==}
def L.keep_flight_false(observation,rows): {==}
def L.unacknowledged_nil(observation): {==}
def L.unacknowledged_cons(head,tail,observation): {==}
def L.ack_cumulative_only(token,pending,writing,flights,last,offered,observation): {==}
def L.unmatched_ack_preserves(state,observation): {==}
def L.ack_wiring(state,token,observation): {==}
def L.encode_exact(token,observation): {==}
def L.decode_entry_exact(text): {==}
def L.decode_refused(text): {==}
def L.decode_allowed(text): {==}
def L.decode_fields_exact(token,observation): {==}
def L.flight_rows_exact(rows,observation): {==}

def L.flight_rows_bounded(rows,observation):
  %MathList.length_take_sym(&2,U32,List.append(&2,U32,rows,[observation]),16n) : {Nat.is_le(_,16n) == True{} : Bool}
  MathNat.min_le_left(16n,List.length(&2,U32,List.append(&2,U32,rows,[observation])))
def L.selected_prepare_preserves_bound(allowed,state,bound):
  match allowed state:
    case False{} state: bound
    case True{} F.State{token,Some{observation},None{},flights,last,offered}: L.flight_rows_bounded(flights,observation)
    case True{} F.State{token,None{},writing,flights,last,offered}: bound
    case True{} F.State{token,Some{observation},Some{writing},flights,last,offered}: bound
def L.public_prepare_preserves_bound(state,bound): L.selected_prepare_preserves_bound(F.ready(state),state,bound)

law keep_length_bound:
  for +keep:Bool
  for +head:U32
  for +filtered:List<&2,U32>
  for +tail:List<&2,U32>
  for h:{Nat.is_le(List.length(&2,U32,filtered),List.length(&2,U32,tail)) == True{} : Bool}
  {Nat.is_le(List.length(&2,U32,F.keep_flight(keep,head,filtered)),1n+List.length(&2,U32,tail)) == True{} : Bool}
def keep_length_bound(keep,head,filtered,tail,h):
  match keep:
    case True{}: h
    case False{}: MathNat.le_trans(List.length(&2,U32,filtered),List.length(&2,U32,tail),1n+List.length(&2,U32,tail),h,MathNat.le_succ(List.length(&2,U32,tail)))
def L.cumulative_filter_never_grows(rows,observation):
  match rows:
    case []: {==}
    case head <> tail: keep_length_bound(U32.is_gt(head,observation),head,F.unacknowledged(tail,observation),tail,L.cumulative_filter_never_grows(tail,observation))
law offer_bound_selected:
  for +allowed:Bool
  for +state:F.State
  for +observation:U32
  for bound:{Nat.is_le(L.flight_count(state),16n) == True{} : Bool}
  {Nat.is_le(L.flight_count(F.offer_selected(allowed,state,observation)),16n) == True{} : Bool}
def offer_bound_selected(allowed,state,observation,bound):
  match allowed state:
    case False{} state: bound
    case True{} F.State{token,pending,writing,flights,last,offered}: bound
def L.public_offer_preserves_bound(state,observation,bound): offer_bound_selected(F.offer_allowed(state,observation),state,observation,bound)
law complete_bound_selected:
  for +matching:Bool
  for +state:F.State
  for bound:{Nat.is_le(L.flight_count(state),16n) == True{} : Bool}
  {Nat.is_le(L.flight_count(F.complete_selected(matching,state)),16n) == True{} : Bool}
def complete_bound_selected(matching,state,bound):
  match matching state:
    case False{} state: bound
    case True{} F.State{token,pending,writing,flights,last,offered}: bound
def L.public_complete_preserves_bound(state,token,observation,bound): complete_bound_selected(F.writing_matches(state,token,observation),state,bound)
law ack_bound_selected:
  for +matching:Bool
  for +state:F.State
  for +observation:U32
  for bound:{Nat.is_le(L.flight_count(state),16n) == True{} : Bool}
  {Nat.is_le(L.flight_count(F.ack_selected(matching,state,observation)),16n) == True{} : Bool}
def ack_bound_selected(matching,state,observation,bound):
  match matching state:
    case False{} state: bound
    case True{} F.State{token,pending,writing,flights,last,offered}: MathNat.le_trans(List.length(&2,U32,F.unacknowledged(flights,observation)),List.length(&2,U32,flights),16n,L.cumulative_filter_never_grows(flights,observation),bound)
def L.public_ack_preserves_bound(state,token,observation,bound): ack_bound_selected(F.matches(state,token,observation),state,observation,bound)
def L.fresh_establishes_bound(token): {==}
