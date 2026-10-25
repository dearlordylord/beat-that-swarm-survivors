import Base
import ../persistent-xp.bend as X

# Persistent XP is credited only on physical pickup. Age is deliberately absent.
law untouched_credit:
  for amount: U32
  {X.credited(False{},amount) == 0 : U32}
law untouched_preserved:
  for amount: U32
  {X.remaining(False{},amount) == amount : U32}
law pickup_credits_whole_pile:
  for amount: U32
  {X.credited(True{},amount) == amount : U32}
law pickup_consumes_pile:
  for amount: U32
  {X.remaining(True{},amount) == 0 : U32}
law merge_preserves_value:
  for amount: U32
  for incoming: U32
  {X.merge(amount,incoming) == (amount + incoming : U32) : U32}

# Guarantees: collecting a pile splits its exact natural value between credit
# and its remaining stored amount; this claim does not treat wrapping as value.
# Why it matters: a physical pickup cannot lose or duplicate the pile's XP.
law pickup_conserves_natural_value:
  for +touching:Bool
  for +amount:U32
  {Nat.add(U32.to_nat(X.credited(touching,amount)),U32.to_nat(X.remaining(touching,amount))) == U32.to_nat(amount) : Nat}

# Guarantees: collecting the remaining pile again credits zero.
# Why it matters: two pickup passes cannot award the same pile twice.
law consumed_pile_cannot_credit_again:
  for amount:U32
  {X.credited(True{},X.remaining(True{},amount)) == 0 : U32}

# Guarantees: either order of two overflow additions has the same machine value.
# Why it matters: aggregation order must not alter the stored overflow amount;
# natural-number overflow conservation is deliberately not claimed here.
law merge_order_independent:
  for +amount:U32
  for +incoming:U32
  {X.merge(amount,incoming) == X.merge(incoming,amount) : U32}
