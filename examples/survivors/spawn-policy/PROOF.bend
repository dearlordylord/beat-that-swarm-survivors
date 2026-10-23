import Base
import ../spawn-policy.bend as S
import ../spawn-lifecycle.bend as L
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

def Laws.newborn_payload_and_status(T,M,payload,cleanMotion): {==}
def Laws.newborn_is_fresh(T,payload,previousAge): {==}
def routing_payload(~T:Data,fresh:Bool,+value:T) -> {L.payload(~T,L.route_flag(~T,fresh,value)) == value : T}:
  match fresh:
    case True{}: {==}
    case False{}: {==}
def Laws.routing_preserves_payload(T,previousKind,previousAge,kind,age,payload):
  routing_payload(~T,L.fresh_transition(L.is_newborn(previousKind,previousAge),L.is_newborn(kind,age)),payload)
def Laws.admission_survives_newborn(M,motion,x,y,px,py,radius):
  Equal.sym(Bool,S.accepted(S.admission(x,y,px,py,radius)),S.admissible(x,y,px,py,radius),gate_exact(S.admissible(x,y,px,py,radius)))
def Laws.rejected_dormant_is_not_newborn(T,age,previous): {==}

def conjunction_implies_right(bounds:Bool,outside:Bool) -> {Bool.or(Bool.not(S.accepted(S.gate(Bool.and(bounds,outside)))),outside) == True{} : Bool}:
  match bounds outside:
    case True{} True{}: {==}
    case True{} False{}: {==}
    case False{} True{}: {==}
    case False{} False{}: {==}
def Laws.accepted_newborn_is_outside(M,motion,x,y,px,py,radius):
  conjunction_implies_right(Bool.and(Bool.and(F32.is_le(20.0,x),F32.is_le(x,3580.0)),Bool.and(F32.is_le(20.0,y),F32.is_le(y,3580.0))),S.outside(x,y,px,py,radius))

def Laws.existing_zero_age_is_not_newborn(T,payload): {==}
