import Base
import pools.bend as Pools

# Party-size difficulty policy. The caller supplies living, connected players
# and the solo spawn budget after stage/mode/Curse modifiers. Scale ordinary
# spawn slots only: health, damage, wave time and bosses keep their own rules.
# Preserve the physical pool ceiling. Clamp both factors before multiplication
# so even malformed U32 inputs cannot wrap the scaled budget.
def spawn_limit(base: U32,players: U32) -> U32:
  U32.min(Pools.max_regular_enemies(),(U32.min(base,Pools.max_regular_enemies()) * U32.min(players,Pools.max_regular_enemies()) : U32))
