import Base
import ../native-economy.bend as P
import ../native-record.bend as R

# Guarantees: every paid terminal observation stores its exact run seed and marks its receipt, for every profile.
# Why it matters: the native host must not lose the duplicate-reward guard when saving a terminal run.
law receipt_stamp_exact:
  for +values: List<&2,U32>
  for +oldSeed: U32
  for +oldSettled: Bool
  for +seed: U32
  {P.stamp(P.Profile{values,oldSeed,oldSettled},seed) == P.Profile{values,seed,True{}} : P.Profile}

# Guarantees: observing the same run twice leaves the complete first result unchanged.
# Why it matters: native terminal screens and repeated host callbacks cannot award expedition gold or statistics twice.
law public_record_idempotent:
  for +profile: P.Profile
  for +receipt: R.Receipt
  {R.record(R.record(profile,receipt),receipt) == R.record(profile,receipt) : P.Profile}

# Guarantees: nonterminal run observations preserve the complete profile.
# Why it matters: native rendering frames cannot pay an expedition before its terminal transition.
law nonterminal_preserves:
  for +profile: P.Profile
  for +receipt: R.Receipt
  for active: {False{} == R.terminal(receipt) : Bool}
  {R.record(profile,receipt) == profile : P.Profile}

# Guarantees: the terminal payment computes the previous wallet plus the expedition's earned gold using the native wallet's machine arithmetic.
# Why it matters: settlement cannot omit the earned gold or accidentally pay a different observation's amount.
law payment_gold_exact:
  for +profile: P.Profile
  for +receipt: R.Receipt
  {P.gold(R.payment(profile,receipt)) == (P.gold(profile) + R.gained(receipt) : U32) : U32}

# Guarantees: an unsettled terminal observation performs the full payment and stores that exact receipt identity.
# Why it matters: an implementation that refuses every expedition reward must fail the native economy contract.
law fresh_terminal_records:
  for +profile: P.Profile
  for +receipt: R.Receipt
  for terminal: {True{} == R.terminal(receipt) : Bool}
  for unseen: {False{} == Bool.and(P.settled(profile),U32.is_eq(P.last_seed(profile),R.run_seed(receipt))) : Bool}
  {R.record(profile,receipt) == P.stamp(R.payment(profile,receipt),R.run_seed(receipt)) : P.Profile}
