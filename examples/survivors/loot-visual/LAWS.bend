import Base
import ../loot-visual.bend as V

# Guarantees: for every contained XP amount at least100, public radius is8.
# Why it matters: merged red overflow piles must stop growing visually even
# when their contained XP is much greater than the visible size budget.
law capped_public_radius:
  for +amount: U32
  for large: {U32.is_le(100,amount) == True{} : Bool}
  {V.radius(amount) == 8.0 : F32}

# Guarantees: ordinary1XP drops use the blue tier.
# Why it matters: the smallest pickup must not look like a merged red pile.
law first_tier_blue:
  {V.color(1) == 6934271 : U32}

# Guarantees: the last amount below the first tier transition remains blue.
# Why it matters: a pile must not turn green before reaching5XP.
law last_blue:
  {V.color(4) == 6934271 : U32}

# Guarantees: the first5XP pile is green.
# Why it matters: collecting multiple small drops has a visible tier signal.
law first_green:
  {V.color(5) == 7986088 : U32}

# Guarantees: the last amount before10XP remains green.
# Why it matters: red is reserved for piles containing at least10XP.
law last_green:
  {V.color(9) == 7986088 : U32}

# Guarantees: the first10XP pile is red.
# Why it matters: the valuable merged pickup is distinguishable from green.
law first_red:
  {V.color(10) == 16740475 : U32}

# Guarantees: a400XP overflow pile is still red.
# Why it matters: the future field-budget overflow marker stays recognizable.
law overflow_red:
  {V.color(400) == 16740475 : U32}

# Guarantees: for every amount, an explicit accumulator marker selects red.
# Why it matters: a newly merged4XP pile must already identify itself as the
# red overflow accumulator, rather than looking like an ordinary blue gem.
law accumulator_always_red:
  for amount: U32
  {V.pile_color(amount,True{}) == 16740475 : U32}

# Guarantees: without an accumulator marker, public color selection is unchanged.
# Why it matters: ordinary small drops must retain their amount-based tiers.
law ordinary_pile_color_preserved:
  for +amount: U32
  {V.pile_color(amount,False{}) == V.color(amount) : U32}
