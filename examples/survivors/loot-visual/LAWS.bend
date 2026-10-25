import Base
import ../loot-visual.bend as V

# Guarantees: for every contained XP amount at least100, public radius is8.
# Why it matters: merged red overflow piles must stop growing visually even
# when their contained XP is much greater than the visible size budget.
law capped_public_radius:
  for +amount: U32
  for large: {U32.is_le(100,amount) == True{} : Bool}
  {V.radius(amount) == 8.0 : F32}

# Guarantees: every amount below both tier thresholds uses the blue palette.
# Why it matters: ordinary small drops remain distinguishable from accumulated loot.
law blue_tier:
  for +amount: U32
  for below_green: {False{} == U32.is_le(V.green_threshold(),amount) : Bool}
  for below_red: {False{} == U32.is_le(V.red_threshold(),amount) : Bool}
  {V.color(amount) == V.tier_color(0) : U32}

# Guarantees: every amount reaching green but not red uses the green palette.
# Why it matters: the intermediate loot tier must not skip to a different color.
law green_tier:
  for +amount: U32
  for reaches_green: {True{} == U32.is_le(V.green_threshold(),amount) : Bool}
  for below_red: {False{} == U32.is_le(V.red_threshold(),amount) : Bool}
  {V.color(amount) == V.tier_color(1) : U32}

# Guarantees: every amount reaching both thresholds uses the red palette.
# Why it matters: valuable and overflow piles retain the high-value color at arbitrary amounts.
law red_tier:
  for +amount: U32
  for reaches_green: {True{} == U32.is_le(V.green_threshold(),amount) : Bool}
  for reaches_red: {True{} == U32.is_le(V.red_threshold(),amount) : Bool}
  {V.color(amount) == V.tier_color(2) : U32}

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
