import Base
import ./coop-combat-broadphase.bend as B
import ./coop-combat-broadphase-LAWS.bend as L

def L.coordinate_envelope_exact(value): {==}
def L.path_envelope_exact(x0,y0,x1,y1,radius): {==}
def L.outward_padding_exact(): {==}
def L.swept_bounds_exact(x0,y0,x1,y1,radius): {==}
def L.source_falls_back(x0,x1,y0,y1,target):
  match target:
    case B.Box{False{},_,_,_,_}: {==}
    case B.Box{True{},_,_,_,_}: {==}
def L.target_falls_back(source,x0,x1,y0,y1):
  match source:
    case B.Box{False{},_,_,_,_}: {==}
    case B.Box{True{},_,_,_,_}: {==}
def L.inclusive_overlap_exact(lx0,lx1,ly0,ly1,rx0,rx1,ry0,ry1): {==}
def L.visited_is_excluded(source,target): {==}
def L.unvisited_uses_overlap(source,target): {==}
def L.retain_exact(target,tail): {==}
def L.reject_preserves_tail(target,tail): {==}
def L.candidate_step_exact(target,box,tail,source,visited): {==}
def L.query_path_exact(rows,x0,y0,x1,y1,radius,visited): {==}
