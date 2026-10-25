import Base
import ../native-economy.bend as P
import ../native-content-policy.bend as C

# Guarantees: purchase admission requires a valid catalog identity, sufficient gold and the relevant rank or unlock requirements.
# Why it matters: native camp purchases cannot bypass payment, the rank cap or already-owned content.
law purchase_admission_exact:
  for +profile: P.Profile
  for +category: U32
  for +id: U32
  {P.can_purchase(profile,category,id) == Bool.and(Bool.and(U32.is_lt(id,C.count(category)),U32.is_ge(P.gold(profile),P.cost(profile,category,id))),P.choice(U32.is_eq(category,5),U32.is_lt(P.rank(profile,id),C.meta_max(id)),Bool.and(P.met(profile,category,id),Bool.not(P.allowed(profile,category,id))))) : Bool}

# Guarantees: a refused native purchase preserves every profile slot.
# Why it matters: repeatedly selecting unavailable camp content cannot change the save.
law purchase_rejected:
  for +profile: P.Profile
  for +category: U32
  for +id: U32
  for rejected: {False{} == P.can_purchase(profile,category,id) : Bool}
  {P.purchase(profile,category,id) == profile : P.Profile}

# Guarantees: buying any admitted upgrade performs its scaled catalog debit and the selected rank-slot write.
# Why it matters: every native upgrade button must perform the payment and selected-rank transition it presents.
law upgrade_success_exact:
  for +profile: P.Profile
  for +id: U32
  for accepted: {True{} == P.can_purchase(profile,5,id) : Bool}
  {P.purchase(profile,5,id) == P.put(P.put(profile,0,(P.gold(profile) - (C.cost(5,id) * (4 + P.rank(profile,id) * 3) / 4) : U32)),(id + 1 : U32),(P.rank(profile,id) + 1 : U32)) : P.Profile}

# Guarantees: starting a new expedition resets only its terminal receipt guard.
# Why it matters: a new run may reuse its deterministic seed and still earn its own reward.
law begin_clears_only_guard:
  for +values: List<&2,U32>
  for +seed: U32
  for +settled: Bool
  {P.begin(P.Profile{values,seed,settled}) == P.Profile{values,seed,False{}} : P.Profile}

# Guarantees: applying a native wallet credit writes the old balance plus its earned amount using native machine arithmetic.
# Why it matters: settlement must not double, omit or substitute the expedition's gold.
law wallet_credit_exact:
  for +profile: P.Profile
  for +old: U32
  for +gained: U32
  {P.gold(P.credit_wallet(profile,old,gained)) == (old + gained : U32) : U32}

# Guarantees: native settlement preserves the original profile unless the observation is terminal and its seed has not already settled; then it publishes the computed payment with its receipt.
# Why it matters: the real receipt decision cannot deny every reward or admit a repeated terminal callback.
law settlement_decision_exact:
  for +active: Bool
  for +seed: U32
  for +profile: P.Profile
  for +paid: P.Profile
  {P.settle(active,seed,profile,paid) == P.choose(active,P.choose(Bool.and(P.settled(profile),U32.is_eq(P.last_seed(profile),seed)),profile,P.stamp(paid,seed)),profile) : P.Profile}
