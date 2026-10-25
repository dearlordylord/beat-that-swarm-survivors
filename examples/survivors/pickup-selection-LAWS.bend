import Base
import ./pickup-policy.bend as P

# Guarantees: distance selects the nearer candidate and exact distance ties select the lower player id.
# Why it matters: collection ownership does not depend on player list order when both players reach the same pickup.
law distance_order_exact:
  for +candidate: F32
  for +best: F32
  for +candidateId: U32
  for +bestId: U32
  {P.closer(candidate,best,candidateId,bestId) == Bool.or(F32.is_lt(candidate,best),Bool.and(F32.is_eq(candidate,best),U32.is_lt(candidateId,bestId))) : Bool}

# Guarantees: candidates with zero health cannot replace any selected player, regardless of distance or identity.
# Why it matters: a dead player cannot steal collection or target selection from a living teammate.
law dead_candidate_refused:
  for bestHp: U32
  for candidate: F32
  for best: F32
  for candidateId: U32
  for bestId: U32
  {P.prefer(0,bestHp,candidate,best,candidateId,bestId) == False{} : Bool}

# Guarantees: every living candidate replaces a dead incumbent, regardless of their relative distances.
# Why it matters: a dead initial fallback cannot prevent a living player from receiving a reachable pickup.
law living_replaces_dead:
  for +hp: U32
  for candidate: F32
  for best: F32
  for candidateId: U32
  for bestId: U32
  for living: {True{} == U32.is_lt(0,hp) : Bool}
  {P.prefer(hp,0,candidate,best,candidateId,bestId) == True{} : Bool}

# Guarantees: when F32 comparisons report equal distances and no strictly nearer candidate, only the lower player id wins.
# Why it matters: two living players at equal finite distance receive deterministic ownership.
law equal_distance_lower_id:
  for +candidate: F32
  for +best: F32
  for +candidateId: U32
  for +bestId: U32
  for notNearer: {False{} == F32.is_lt(candidate,best) : Bool}
  for equal: {True{} == F32.is_eq(candidate,best) : Bool}
  {P.closer(candidate,best,candidateId,bestId) == U32.is_lt(candidateId,bestId) : Bool}

# Guarantees: a physical contact is eligible exactly when the player is alive and touching the pickup.
# Why it matters: dead players and out of reach players cannot enter the collector candidate list.
law contact_exact:
  for +hp: U32
  for +touching: Bool
  {P.living_contact(hp,touching) == Bool.and(U32.is_lt(0,hp),touching) : Bool}

# Guarantees: a candidate replaces the incumbent exactly when alive and either the incumbent is dead or distance and id ordering prefer the candidate.
# Why it matters: the production selector must accept eligible nearer players as well as reject dead players.
law preference_exact:
  for +hp: U32
  for +bestHp: U32
  for +candidate: F32
  for +best: F32
  for +candidateId: U32
  for +bestId: U32
  {P.prefer(hp,bestHp,candidate,best,candidateId,bestId) == Bool.and(U32.is_lt(0,hp),Bool.or(U32.is_eq(bestHp,0),Bool.or(F32.is_lt(candidate,best),Bool.and(F32.is_eq(candidate,best),U32.is_lt(candidateId,bestId))))) : Bool}
