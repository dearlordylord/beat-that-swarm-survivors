import Base
import primitives.bend as P

# These are structural laws of the actual scorer used by the controller.
# Full route/decision parity is executable differential coverage, not a proof.
law evolution_priority:
  for id: U32
  for weapons: List<&2,U32>
  for passives: List<&2,U32>
  for hp: U32
  for maxHp: U32
  {P.offer_score(3,id,weapons,passives,hp,maxHp) == 1000.0 : F32}
law union_priority:
  for id: U32
  for weapons: List<&2,U32>
  for passives: List<&2,U32>
  for hp: U32
  for maxHp: U32
  {P.offer_score(5,id,weapons,passives,hp,maxHp) == 1000.0 : F32}
