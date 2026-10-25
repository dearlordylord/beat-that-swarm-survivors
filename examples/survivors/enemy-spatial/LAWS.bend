import Base
import ../enemy-spatial.bend as S
import ../encounters.bend as E

# Guarantees: every active movement tick increments age once, including wrap.
# Why it matters: ranged firing and boss acceleration use this lifetime clock;
#   freezing position must not freeze or double-advance that clock.
law age_advances_once:
  for x: F32 for y: F32 for +age: U32 for radius: F32
  for vx: F32 for vy: F32 for fire: Bool for factor: F32
  {S.age(S.moved(S.Spatial{x,y,age,radius},E.Intent{vx,vy,fire},factor)) == (age + 1 : U32) : U32}

# Guarantees: movement preserves collision radius for every intent and factor.
# Why it matters: moving or slowing an enemy must not change its hit footprint.
law radius_preserved:
  for x: F32 for y: F32 for age: U32 for +radius: F32
  for vx: F32 for vy: F32 for fire: Bool for factor: F32
  {S.radius(S.moved(S.Spatial{x,y,age,radius},E.Intent{vx,vy,fire},factor)) == radius : F32}
