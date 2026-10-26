import Base
import ../arena.bend as A
import ../spawn-policy.bend as S
import LAWS.bend as Laws

def gate_exact(+allowed: Bool) -> {S.accepted(S.gate(allowed)) == allowed : Bool}:
  match allowed:
    case True{}: {==}
    case False{}: {==}

def Laws.admission_matches_geometry(x,y,px,py,radius):
  gate_exact(S.admissible(x,y,px,py,radius))

def Laws.fitting_side_selected(preferPositive,negativeFits,positiveFits):
  match preferPositive negativeFits positiveFits:
    case True{} True{} True{}: {==}
    case True{} True{} False{}: {==}
    case True{} False{} True{}: {==}
    case True{} False{} False{}: {==}
    case False{} True{} True{}: {==}
    case False{} True{} False{}: {==}
    case False{} False{} True{}: {==}
    case False{} False{} False{}: {==}

def conjunction_implies_right(bounds:Bool,outside:Bool) -> {Bool.or(Bool.not(S.accepted(S.gate(Bool.and(bounds,outside)))),outside) == True{} : Bool}:
  match bounds outside:
    case True{} True{}: {==}
    case True{} False{}: {==}
    case False{} True{}: {==}
    case False{} False{}: {==}
def Laws.accepted_candidate_is_outside(x,y,px,py,radius):
  conjunction_implies_right(Bool.and(Bool.and(F32.is_le(A.spawn_min(),x),F32.is_le(x,A.spawn_max())),Bool.and(F32.is_le(A.spawn_min(),y),F32.is_le(y,A.spawn_max()))),S.outside(x,y,px,py,radius))
