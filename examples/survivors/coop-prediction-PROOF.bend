import Base
import ./coop-prediction-LAWS.bend as L
import ./coop-prediction.bend as P
import ./coop-prediction-counter-PROOF.bend as Counter

def direction_pick(+found:Bool,+x:U32,+y:U32,+tail:P.Direction) -> {P.direction_selected(found,x,y,tail) == Bool.pick(P.Direction,found,P.Direction{x,y},tail) : P.Direction}:
  match found:
    case False{}: {==}
    case True{}: {==}
def keep_pick(+keep:Bool,+row:P.Input,+tail:List<&2,P.Input>) -> {P.keep_input(keep,row,tail) == Bool.pick(List<&2,P.Input>,keep,row <> tail,tail) : List<&2,P.Input>}:
  match keep:
    case False{}: {==}
    case True{}: {==}

def L.horizon_exact(): {==}
def L.lead_exact(roundTripMs): {==}
def L.after_exact(tick,amount): {==}
def L.world_count_exact(anchor,display): {==}
def L.prediction_gate_exact(phase,hp,connected): {==}
def L.input_empty_neutral(tick): {==}
def L.input_row_exact(seq,target,x,y,tail,tick): direction_pick(U32.is_eq(target,tick),x,y,P.input_at(tail,tick))
def L.assigned_input_selected(seq,target,x,y,tail):
  %Equal.sym(Bool,U32.is_eq(target,target),True{},Counter.eq_self(target)) : {P.direction_selected(_,x,y,P.input_at(tail,target)) == P.Direction{x,y} : P.Direction}
  {==}
def L.target_present_exact(seq,target,x,y,tail,tick): {==}
def L.can_tick_exact(x,y,distance,enabled,inputs,anchor,display,observation,last): {==}
def L.command_gate_exact(px,py,distance,enabled,inputs,anchor,display,observation,last,seq,x,y): {==}
def L.command_assigns_next_world_tick(px,py,distance,enabled,inputs,anchor,display,observation,last,seq,x,y): {==}
def L.command_refuses(state,seq,x,y): {==}
def L.command_exact(state,seq,x,y): {==}
def L.tick_selected_exact(x,y,distance,enabled,inputs,anchor,display,observation,last): {==}
def L.tick_refuses(state): {==}
def L.tick_exact(state): {==}
def L.unresolved_row_exact(seq,target,x,y,tail,anchor): keep_pick(U32.is_gt(target,anchor),P.Input{seq,target,x,y},P.unresolved(tail,anchor))
def L.committed_input_removed(seq,anchor,x,y,tail):
  %Equal.sym(Bool,U32.is_gt(anchor,anchor),False{},Counter.gt_self(anchor)) : {P.keep_input(_,P.Input{seq,anchor,x,y},P.unresolved(tail,anchor)) == P.unresolved(tail,anchor) : List<&2,P.Input>}
  {==}
def L.resync_exact(x,y,distance,enabled,inputs,anchor,display,observation,last,incoming): {==}
def L.cursor_exact(x,y,distance,enabled,inputs,anchor,display,observation,last,incoming,initialLead): {==}
def L.rejected_observation_preserves(state,observation,anchor,x,y,distance,enabled,initialLead): {==}
def L.disabled_reconcile_clears(px,py,priorDistance,priorEnabled,inputs,oldAnchor,oldDisplay,oldObservation,last,observation,anchor,x,y,distance,initialLead): {==}
def L.reconciliation_admission_exact(state,observation,anchor,x,y,distance,enabled,initialLead): {==}
def L.observation_newer_exact(x,y,distance,enabled,inputs,anchor,display,prior,last,observation): {==}
def L.shared_movement_exact(x,y,distance,dx,dy): {==}
def L.axis_exact(code): {==}
def L.point_step_exact(x,y,distance,dx,dy): {==}
def L.position_zero(tick,rows,distance,point): {==}
def L.position_successor(fuel,tick,rows,distance,point): {==}
def L.fresh_exact(x,y,distance,enabled,anchor,initialLead): {==}
def L.running_reconcile_exact(state,observation,anchor,x,y,distance,initialLead):
  match state:
    case P.State{_,_,_,_,_,_,_,_,_}: {==}
def L.active_reconcile_exact(state,observation,anchor,x,y,distance,initialLead):
  match state:
    case P.State{_,_,_,_,_,_,_,_,_}: {==}
def L.anchor_match_exact(x,y,distance,enabled,inputs,anchor,display,observation,last,tick): {==}

def L.normalize_exact(value): {==}

def L.from_bits_exact(word): {==}
