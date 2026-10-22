import Base
import ../spawn-policy.bend as S

# Guarantees: admission accepts exactly the coordinates satisfying arena bounds
#   and complete-appearance clearance from the common viewport rectangle.
# Why it matters: an invalid spawn candidate must remain dormant, never appear
#   underneath the player or become visible before entering from outside.
law admission_matches_geometry:
  for +x: F32
  for +y: F32
  for +px: F32
  for +py: F32
  for +radius: F32
  {S.accepted(S.admission(x,y,px,py,radius)) == S.admissible(x,y,px,py,radius) : Bool}

# Guarantees: when either side of an axis fits, the selected side fits.
# Why it matters: a player at an arena edge still receives incoming enemies;
#   an outward coordinate is never clamped back inside the visible area.
law fitting_side_selected:
  for +preferPositive: Bool
  for +negativeFits: Bool
  for +positiveFits: Bool
  {Bool.or(Bool.not(Bool.or(negativeFits,positiveFits)),Bool.pick(Bool,S.positive_side(preferPositive,negativeFits,positiveFits),positiveFits,negativeFits)) == True{} : Bool}
