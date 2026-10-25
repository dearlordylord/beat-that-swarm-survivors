import Base

# Solo presentation lifetimes preserve the established saturating audio clock.
def birth(+tick:U32,+age:U32) -> U32: (tick - U32.min(tick,age) : U32)
def enemy(slot:U32,tick:U32,age:U32) -> String:
  "enemy:" ++ U32.show(slot) ++ ":" ++ U32.show(birth(tick,age))
