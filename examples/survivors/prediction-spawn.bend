import Base
import player-movement.bend as M
import spawn-policy.bend as S

type Camera is Data: Camera{x: F32,y: F32,distance: F32}
# Exact machine policy. +1 radius gives three additional clearance units.
def padded_radius(radius: F32,distance: F32) -> F32: (radius + U32.to_f32(M.horizon()) * F32.abs(distance) / 3.0 + 1.0 : F32)
def admissible(x: F32,y: F32,camera: Camera,radius: F32) -> Bool:
  match camera:
    case Camera{px,py,distance}: S.admissible(x,y,px,py,padded_radius(radius,distance))
def choose(seed: U32,tick: U32,camera: Camera,radius: F32) -> S.Point:
  match camera:
    case Camera{px,py,distance}: S.choose(seed,tick,px,py,padded_radius(radius,distance))
