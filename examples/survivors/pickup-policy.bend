import Base

# Age and kind are intentionally irrelevant to physical collection.
def close(+x: F32,+y: F32,+px: F32,+py: F32,+radius: F32) -> Bool:
  F32.is_le(((x - px) * (x - px) + (y - py) * (y - py) : F32),(radius * radius : F32))
def admission(x: F32,y: F32,px: F32,py: F32,radius: F32,age: U32,kind: U32) -> Bool:
  close(x,y,px,py,radius)

# Squared IEEE F32 distances preserve the game's existing comparison semantics.
def closer(+candidateDistance: F32,+bestDistance: F32,candidateId: U32,bestId: U32) -> Bool:
  Bool.or(F32.is_lt(candidateDistance,bestDistance),Bool.and(F32.is_eq(candidateDistance,bestDistance),U32.is_lt(candidateId,bestId)))
def prefer(candidateHp: U32,bestHp: U32,candidateDistance: F32,bestDistance: F32,candidateId: U32,bestId: U32) -> Bool:
  Bool.and(U32.is_lt(0,candidateHp),Bool.or(U32.is_eq(bestHp,0),closer(candidateDistance,bestDistance,candidateId,bestId)))
def living_contact(hp: U32,touching: Bool) -> Bool: Bool.and(U32.is_lt(0,hp),touching)
