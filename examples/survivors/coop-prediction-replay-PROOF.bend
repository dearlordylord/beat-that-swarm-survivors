import Base
import ./coop-prediction-replay-LAWS.bend as L

def L.worlds_zero(A,advance,tick,inputs,frame): {==}
def L.worlds_successor(A,advance,fuel,tick,inputs,frame): {==}
def L.neutral_world_successor(A,advance,fuel,tick,frame): {==}
def L.forecast_world_interval_exact(A,advance,frame,x,y,distance,inputs,anchor,display,observation,last): {==}
def L.forecast_disabled_preserves(A,advance,frame,x,y,distance,inputs,anchor,display,observation,last): {==}
def L.guard_refuses(A,advance,frame,x,y): {==}
def L.guard_accepts(A,advance,frame,x,y): {==}
def L.eligibility_exact(phase,hp,x,y): {==}
def L.generation_exact(player,tick,age,owner,slot): {==}
