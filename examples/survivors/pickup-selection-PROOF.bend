import Base
import ./pickup-policy.bend as P
import ./pickup-selection-LAWS.bend as L

def L.distance_order_exact(candidate,best,candidateId,bestId): {==}
def L.dead_candidate_refused(bestHp,candidate,best,candidateId,bestId): {==}
def L.living_replaces_dead(hp,candidate,best,candidateId,bestId,living):
  %living : {Bool.and(_,Bool.or(U32.is_eq(0,0),P.closer(candidate,best,candidateId,bestId))) == True{} : Bool}
  {==}
def L.equal_distance_lower_id(candidate,best,candidateId,bestId,notNearer,equal):
  %notNearer : {Bool.or(_,Bool.and(F32.is_eq(candidate,best),U32.is_lt(candidateId,bestId))) == U32.is_lt(candidateId,bestId) : Bool}
  %equal : {Bool.and(_,U32.is_lt(candidateId,bestId)) == U32.is_lt(candidateId,bestId) : Bool}
  {==}
def L.contact_exact(hp,touching): {==}
def L.preference_exact(hp,bestHp,candidate,best,candidateId,bestId): {==}
