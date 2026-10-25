import Base
import prediction-spawn.bend as P
import player-movement.bend as M
import spawn-policy.bend as S

# Guarantees: the exclusion radius includes the complete bounded prediction
# travel, plus three world units to absorb radius division/multiplication rounding.
# Why it matters: the predicted local camera must not reveal a newborn enemy.
law padding_exact:
  for +radius: F32
  for +distance: F32
  {P.padded_radius(radius,distance) == (radius + U32.to_f32(M.horizon()) * F32.abs(distance) / 3.0 + 1.0 : F32) : F32}

# Guarantees: admission applies the existing stage and viewport predicate to the
# padded radius, using the same camera coordinates supplied by the shared core.
# Why it matters: adding placement padding cannot leave the actual guard unpadded.
law admission_exact:
  for +x: F32
  for +y: F32
  for +px: F32
  for +py: F32
  for +distance: F32
  for +radius: F32
  {P.admissible(x,y,P.Camera{px,py,distance},radius) == S.admissible(x,y,px,py,P.padded_radius(radius,distance)) : Bool}

# Guarantees: candidate generation uses exactly the same padded radius as admission.
# Why it matters: padding only the guard would reject every ordinary new enemy.
law placement_exact:
  for +seed: U32
  for +tick: U32
  for +px: F32
  for +py: F32
  for +distance: F32
  for +radius: F32
  {P.choose(seed,tick,P.Camera{px,py,distance},radius) == S.choose(seed,tick,px,py,P.padded_radius(radius,distance)) : S.Point}
