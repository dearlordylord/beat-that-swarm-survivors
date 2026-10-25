import Base
import arena.bend as A

# Shared by authoritative movement and the display-only client predictor.
type Point is Data: Point{x: F32,y: F32}
def horizon() -> U32: 60
def move_point(+x: F32,+y: F32,+distance: F32,+dx: F32,+dy: F32) -> Point:
  +length = F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32)))
  Point{F32.clamp((x + dx * distance / length : F32),A.player_min(),A.player_max()),F32.clamp((y + dy * distance / length : F32),A.player_min(),A.player_max())}
