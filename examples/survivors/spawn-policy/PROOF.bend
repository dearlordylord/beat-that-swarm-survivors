import Base
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
