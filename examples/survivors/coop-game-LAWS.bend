import Base
import pickup-policy.bend as P

# Guarantees: every item age and kind uses exactly the same physical reach test.
# Why it matters: coins and healing cannot auto-credit after a timed delay.
law physical_pickup_exact:
  for +x: F32
  for +y: F32
  for +px: F32
  for +py: F32
  for +radius: F32
  for age: U32
  for kind: U32
  {P.admission(x,y,px,py,radius,age,kind) == P.close(x,y,px,py,radius) : Bool}

# Guarantees: close returns exactly the F32 squared-distance comparison below.
# Why it matters: a policy accepting every position cannot satisfy the reach rule.
# This pins machine F32 arithmetic, not a theorem about real-number geometry.
law physical_close_exact:
  for +x: F32
  for +y: F32
  for +px: F32
  for +py: F32
  for +radius: F32
  {P.close(x,y,px,py,radius) == F32.is_le(((x - px) * (x - px) + (y - py) * (y - py) : F32),(radius * radius : F32)) : Bool}
