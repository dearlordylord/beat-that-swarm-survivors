import Base
import ../native-economy.bend as P
import ../native-content-policy.bend as C
import LAWS.bend as Laws

def Laws.settlement_decision_exact(active,seed,profile,paid): {==}
def Laws.wallet_credit_exact(profile,old,gained):
  match profile:
    case P.Profile{_,_,_}: {==}
def Laws.purchase_admission_exact(profile,category,id): {==}
def Laws.purchase_rejected(profile,category,id,rejected):
  %rejected : {P.choose(_,P.purchased(profile,category,id),profile) == profile : P.Profile}
  {==}
def Laws.upgrade_success_exact(profile,id,accepted):
  %accepted : {P.choose(_,P.purchased(profile,5,id),profile) == P.put(P.put(profile,0,(P.gold(profile) - (C.cost(5,id) * (4 + P.rank(profile,id) * 3) / 4) : U32)),(id + 1 : U32),(P.rank(profile,id) + 1 : U32)) : P.Profile}
  {==}

def Laws.begin_clears_only_guard(values,seed,settled): {==}
