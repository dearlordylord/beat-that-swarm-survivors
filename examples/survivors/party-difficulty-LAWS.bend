import Base
import party-difficulty.bend as D

# Guarantees: the party's ordinary spawn budget is the product of its solo
# budget and active player count, with both factors and the result capped at 500.
# Why it matters: a second living player must add spawn pressure without
# exceeding the allocated pool or changing enemy health and damage.
law spawn_limit_exact:
  for +base: U32
  for +players: U32
  {D.spawn_limit(base,players) == U32.min(500,(U32.min(base,500) * U32.min(players,500) : U32)) : U32}
