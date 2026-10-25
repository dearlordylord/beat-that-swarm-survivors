import Base
import ../loot-placement.bend as P

def inside(+value: U32) -> Bool:
  Bool.and(Cmp.is_ge(U32.cmp(value,P.lower())),U32.is_le(value,P.upper()))

# Guarantees: every placed coordinate is between the player's encoded finite bounds.
# Why it matters: an edge kill must not leave a drop outside the walkable rectangle.
law bounded:
  for +value: F32
  {True{} == inside(P.word(P.place(value))) : Bool}

# Guarantees: a coordinate already in the player rectangle keeps every bit.
# Why it matters: ordinary kills retain their location rather than moving all drops.
law preserve_inside:
  for +value: F32
  for valid: {True{} == inside(P.word(value)) : Bool}
  {P.place(value) == value : F32}

# Guarantees: applying placement a second time cannot move a drop again.
# Why it matters: overflow merging and repeated routing must not make loot drift.
law idempotent:
  for +value: F32
  {P.place(P.place(value)) == P.place(value) : F32}

# Guarantees: the actual lower player corner remains available for loot.
# Why it matters: a constant-output implementation must not pass the bounds alone.
law lower_fixed:
  {P.place(P.coordinate(P.lower())) == P.coordinate(P.lower()) : F32}

# Guarantees: the actual upper player corner also remains available for loot.
# Why it matters: placement must preserve both ends of the accessible arena.
law upper_fixed:
  {P.place(P.coordinate(P.upper())) == P.coordinate(P.upper()) : F32}
