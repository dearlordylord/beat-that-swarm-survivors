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
