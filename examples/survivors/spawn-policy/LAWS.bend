import Base
import ../spawn-policy.bend as S
import ../viewport.bend as V
import ../spawn-lifecycle.bend as L

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

# Guarantees: every accepted newborn payload survives the lifecycle boundary
# unchanged, and its output Motion is exactly the clean Motion supplied there.
# Why it matters: old slow/freeze/burn cannot move a new enemy onto the camera.
law newborn_payload_and_status:
  for ~T:Data
  for ~M:Data
  for +payload:T
  for +cleanMotion:M
  {L.newborn(~T,~M,payload,cleanMotion) == (payload,cleanMotion) : T & M}

# Guarantees: a dormant body becoming an updated enemy of age zero is routed
# as a fresh incarnation, regardless of its dormant age.
# Why it matters: it must bypass all collision/status from its former lifetime.
law newborn_is_fresh:
  for ~T:Data
  for +payload:T
  for +previousAge:U32
  {L.route(~T,8,previousAge,0,0,payload) == L.Fresh{payload} : L.Routed<T>}

# Guarantees: routing never changes a payload, for any kind and age.
# Why it matters: the boundary cannot shift coordinates or alter enemy identity.
law routing_preserves_payload:
  for ~T:Data
  for +previousKind:U32
  for +previousAge:U32
  for +kind:U32
  for +age:U32
  for +payload:T
  {L.payload(~T,L.route(~T,previousKind,previousAge,kind,age,payload)) == payload : T}

def point_geometry(point:S.Point,px:F32,py:F32,radius:F32) -> Bool:
  match point:
    case S.Point{x,y}: S.admissible(x,y,px,py,radius)
def newborn_geometry(~M:Data,result:S.Point & M,px:F32,py:F32,radius:F32) -> Bool:
  match result:
    case (point,_): point_geometry(point,px,py,radius)
# Guarantees: geometry after the status-clearing newborn boundary is exactly
# the admission result, for all coordinates and all clean Motion values.
# Why it matters: accepted offscreen placement remains offscreen after spawning.
law admission_survives_newborn:
  for ~M:Data
  for +motion:M
  for +x:F32
  for +y:F32
  for +px:F32
  for +py:F32
  for +radius:F32
  {newborn_geometry(~M,L.newborn(~S.Point,~M,S.Point{x,y},motion),px,py,radius) == S.accepted(S.admission(x,y,px,py,radius)) : Bool}

# Guarantees: a rejected candidate whose retained previous body is dormant
# (kind8) remains on the existing/non-newborn route, at every age.
# Why it matters: rejection must not revive a dormant slot as a fresh enemy;
# this law explicitly assumes the admission gate retained its dormant body.
law rejected_dormant_is_not_newborn:
  for ~T:Data
  for +age:U32
  for +previous:T
  {L.route(~T,8,age,8,age,previous) == L.Existing{previous} : L.Routed<T>}

def point_outside(point:S.Point,px:F32,py:F32,radius:F32) -> Bool:
  match point:
    case S.Point{x,y}: S.outside(x,y,px,py,radius)
def newborn_outside(~M:Data,result:S.Point & M,px:F32,py:F32,radius:F32) -> Bool:
  match result:
    case (point,_): point_outside(point,px,py,radius)
# Guarantees: if admission accepts a candidate, its newborn output is outside
# the complete-appearance viewport exclusion, for every clean Motion value.
# Why it matters: a newly admitted enemy must never first appear on screen.
law accepted_newborn_is_outside:
  for ~M:Data
  for +motion:M
  for +x:F32
  for +y:F32
  for +px:F32
  for +py:F32
  for +radius:F32
  {Bool.or(Bool.not(S.accepted(S.admission(x,y,px,py,radius))),newborn_outside(~M,L.newborn(~S.Point,~M,S.Point{x,y},motion),px,py,radius)) == True{} : Bool}

# Guarantees: an already-enemy age-zero body staying enemy age-zero does not
# cross a birth boundary (including a live age wrap before update).
# Why it matters: ordinary movement must retain status/collision processing.
law existing_zero_age_is_not_newborn:
  for ~T:Data
  for +payload:T
  {L.route(~T,0,0,0,0,payload) == L.Existing{payload} : L.Routed<T>}
