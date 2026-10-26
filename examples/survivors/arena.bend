import Base

# World geometry shared by simulation and both presentations.
def size() -> F32: 14400.0
def center() -> F32: 7200.0
# Keep the player within melee reach at corners while full enemy sprites fit.
def player_min() -> F32: 128.0
# A literal makes encoded bounds reducible.
def player_max() -> F32: 14272.0
# Covers the full sprite, shadow and health bar, not only its collision circle.
def envelope(radius: F32) -> F32: (3.0 * radius + 24.0 : F32)
def constrain(value: F32,+radius: F32) -> F32:
  F32.clamp(value,envelope(radius),(size() - envelope(radius) : F32))
# Every current enemy has radius <=42, hence envelope <=150.
def spawn_min() -> F32: 160.0
def spawn_max() -> F32: (size() - spawn_min() : F32)
