import Base
import ./coop-combat-prediction-LAWS.bend as L
import ./coop-combat-prediction-policy.bend as C

def L.cohort_kind_exact(kind): {==}
def L.cohort_clock_exact(tick): {==}
def L.native_float_bits_exact(bits): {==}
def L.receive_normalization_uses_bits(value): {==}
def L.canonical_fresh(A,previous,fresh): {==}
def L.canonical_suffix_exact(A,advance,previous,fresh,prediction): {==}
def L.sweep_miss_has_no_witness(tick,shot,target,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius): {==}
def L.sweep_hit_exact(tick,shot,target,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,time): {==}
def L.sweep_solver_is_source(tick,shot,target,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius): {==}
def L.point_miss_has_no_witness(tick,shot,target,x,y,ex,ey,radius): {==}
def L.point_hit_exact(tick,shot,target,x,y,ex,ey,radius): {==}
def L.witness_lifetimes_exact(births,kind,tick,shot,target,shotBirth,targetBirth,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,time): {==}
def L.diagnostic_ttl_exact(): {==}
def L.diagnostic_recent_exact(now,value):
  match value:
    case C.Witness{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: {==}
