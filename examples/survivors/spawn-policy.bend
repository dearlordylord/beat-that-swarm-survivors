import Base
import arena.bend as A
import viewport.bend as V

# Both presentations fit inside the shared viewport exclusion rectangle.
# 3r + 24 includes the complete enemy sprite, shadow and health indicator.
# Candidate placement adds 16 world units for rounding and the same-tick camera step.
type Point is Data: Point{x: F32,y: F32}
type Admission is Data:
  Admit{}
  Reject{}

def clearance(+radius: F32) -> F32: (V.exclusion_half_extent() + 3.0 * radius + 24.0 : F32)
def outside(+x: F32,+y: F32,+px: F32,+py: F32,radius: F32) -> Bool:
  +gap = clearance(radius)
  Bool.or(F32.is_lt(gap,F32.abs((x - px : F32))),F32.is_lt(gap,F32.abs((y - py : F32))))
def admissible(+x: F32,+y: F32,px: F32,py: F32,radius: F32) -> Bool:
  Bool.and(Bool.and(Bool.and(F32.is_le(A.spawn_min(),x),F32.is_le(x,A.spawn_max())),Bool.and(F32.is_le(A.spawn_min(),y),F32.is_le(y,A.spawn_max()))),outside(x,y,px,py,radius))
def gate(allowed: Bool) -> Admission:
  match allowed:
    case True{}: Admit{}
    case False{}: Reject{}
def accepted(admission: Admission) -> Bool:
  match admission:
    case Admit{}: True{}
    case Reject{}: False{}
def admission(x: F32,y: F32,px: F32,py: F32,radius: F32) -> Admission:
  gate(admissible(x,y,px,py,radius))

# Never clamp the outward coordinate: fall back to the opposite fitting side.
# The native geometry integration check covers arena edges, catalog radii and
# the prediction padding used by placement and admission.
def positive_side(preferPositive: Bool,negativeFits: Bool,positiveFits: Bool) -> Bool:
  Bool.and(positiveFits,Bool.or(preferPositive,Bool.not(negativeFits)))
def coordinate(positive: Bool,negative: F32,positiveValue: F32) -> F32:
  match positive:
    case True{}: positiveValue
    case False{}: negative
def axis(+position: F32,+gap: F32,preferPositive: Bool) -> F32:
  coordinate(positive_side(preferPositive,F32.is_le(A.spawn_min(),(position - gap : F32)),F32.is_le((position + gap : F32),A.spawn_max())),(position - gap : F32),(position + gap : F32))
def tangent(+seed: U32,tick: U32,position: F32,gap: F32) -> F32:
  F32.clamp((position + (U32.to_f32(((seed * 73 + tick * 19) % 2001 : U32)) / 1000.0 - 1.0) * gap : F32),A.spawn_min(),A.spawn_max())
def on_side(side: U32,+seed: U32,+tick: U32,+px: F32,+py: F32,+gap: F32) -> Point:
  match side:
    case 0: Point{axis(px,gap,True{}),tangent(seed,tick,py,gap)}
    case 1: Point{tangent(seed,tick,px,gap),axis(py,gap,True{})}
    case 2: Point{axis(px,gap,False{}),tangent(seed,tick,py,gap)}
    case _: Point{tangent(seed,tick,px,gap),axis(py,gap,False{})}
# Divide the six-tick admission cadence before selecting a side: using seed+tick
# directly would force every ordinary spawn onto even-numbered sides.
def choose(+seed: U32,+tick: U32,px: F32,py: F32,radius: F32) -> Point:
  on_side(((seed / 6 + tick / 6 + seed % 6) % 4 : U32),seed,tick,px,py,(clearance(radius) + 16.0 : F32))
