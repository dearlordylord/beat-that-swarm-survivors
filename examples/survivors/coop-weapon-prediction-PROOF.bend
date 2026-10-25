import Base
import ./coop-weapon-prediction-policy.bend as F
import ./coop-weapon-prediction-LAWS.bend as L
import ./coop-prediction.bend as P

def L.steps_zero(A,advance,frame,x,y): {==}
def L.steps_successor(A,advance,fuel,frame,x,y): {==}
def L.segment_budget_exact(A,advance,seq,x,y,steps,consumed,frame,budget): {==}
def L.chronological_replay_exact(A,advance,rows,state):
  match rows:
    case []: {==}
    case head <> tail: L.chronological_replay_exact(A,advance,tail,F.replay_one(~A,~advance,head,state))
def L.active_history_order_exact(A,advance,frame,px,py,distance,rows,age,observation): {==}
def L.disabled_history_preserves(A,advance,frame,px,py,distance,rows,age,observation): {==}
def L.empty_history_preserves(A,advance,frame,px,py,distance,age,observation): {==}
def L.one_pending_tick_exact(A,advance,frame,px,py,distance,seq,x,y,age,observation): {==}
def L.guard_refuses(A,advance,frame,x,y): {==}
def L.guard_accepts(A,advance,frame,x,y): {==}
def L.eligibility_exact(phase,hp,x,y): {==}
def L.known_shot_retains_existing(A,retain,previous,fresh): {==}
def L.new_shot_uses_forecast(A,retain,fresh): {==}
def L.generation_exact(player,tick,age,owner,slot): {==}
def L.owned_slots_successor(fuel,seed): {==}
def L.owned_slots_layout(player): {==}
