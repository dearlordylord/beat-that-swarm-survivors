import Base
import ../menu-progression.bend as P
import ../menu-amount.bend as A

def upgrade_limit(entry: Maybe<&2,P.Upgrade>) -> Nat:
  match entry:
    case None{}: 0n
    case Some{P.Upgrade{_,_,limit}}: limit

def upgrade_quote(entry: Maybe<&2,P.Upgrade>,rank: Nat) -> A.Amount:
  match entry:
    case None{}: A.zero()
    case Some{P.Upgrade{_,base,_}}: A.natural(Nat.div(Nat.mul(base,Nat.add(4n,Nat.mul(rank,3n))),4n))

def upgrade_eligible(+profile: P.Progress,+id: U32,+catalog: P.Catalog) -> Bool:
  Bool.and(P.has_upgrade(P.upgrade_item(catalog,id)),Bool.and(Bool.not(Nat.is_ge(P.rank_at(P.progress_meta(profile),U32.to_nat(id)),upgrade_limit(P.upgrade_item(catalog,id)))),A.ge(P.progress_gold(profile),upgrade_quote(P.upgrade_item(catalog,id),P.rank_at(P.progress_meta(profile),U32.to_nat(id))))))

def upgrade_replacement(+profile: P.Progress,+id: U32,catalog: P.Catalog) -> P.Progress:
  P.set_meta(P.set_gold(profile,A.subtract(P.progress_gold(profile),upgrade_quote(P.upgrade_item(catalog,id),P.rank_at(P.progress_meta(profile),U32.to_nat(id))))),P.replace_at(P.progress_meta(profile),U32.to_nat(id),Nat.add(P.rank_at(P.progress_meta(profile),U32.to_nat(id)),1n)))

def purchasable(kind: P.SelectionKind) -> Bool:
  match kind:
    case P.Character{}: True{}
    case P.Stage{}: True{}
    case _: False{}

def unlock_quote(entry: Maybe<&2,P.UnlockEntry>) -> A.Amount:
  match entry:
    case None{}: A.zero()
    case Some{P.UnlockEntry{_,cost,_}}: cost

def unlock_requirement(entry: Maybe<&2,P.UnlockEntry>) -> Maybe<&2,P.Condition>:
  match entry:
    case None{}: None{}
    case Some{P.UnlockEntry{_,_,condition}}: condition

def unlock_eligible(+profile: P.Progress,+kind: P.SelectionKind,+id: U32,+catalog: P.Catalog) -> Bool:
  Bool.and(purchasable(kind),Bool.and(P.has_unlock(P.unlock_item(kind,catalog,id)),Bool.and(Bool.not(P.unlocked(profile,kind,id,catalog)),Bool.and(P.requirements_met(profile,unlock_requirement(P.unlock_item(kind,catalog,id))),A.ge(P.progress_gold(profile),unlock_quote(P.unlock_item(kind,catalog,id)))))))

def unlock_replacement(+profile: P.Progress,+kind: P.SelectionKind,+id: U32,+catalog: P.Catalog) -> P.Progress:
  P.award(P.refresh_counts(P.set_owned(P.set_gold(profile,A.subtract(P.progress_gold(profile),unlock_quote(P.unlock_item(kind,catalog,id)))),kind,P.append_id(P.owned(profile,kind),id))),catalog)

# Guarantees: re-observing a recorded run preserves the whole progress and adds no achievements.
# Why it matters: a terminal receipt already present in storage cannot pay twice.
law recorded_run_unchanged:
  for +profile: P.Progress
  for +frame: P.RunReceipt
  for +catalog: P.Catalog
  for recorded: {True{} == P.contains_text(P.progress_recorded(profile),P.run_runId(frame)) : Bool}
  {P.record_run(profile,frame,catalog) == P.RecordResult{profile,[]} : P.RecordResult}

# Guarantees: arcana availability is precisely membership in the supplied catalog.
# Why it matters: the menu cannot offer an arcana identity absent from the actual catalog.
law arcana_catalog_membership:
  for profile: P.Progress
  for +id: U32
  for +catalog: P.Catalog
  {P.unlocked(profile,P.Arcana{},id,catalog) == P.contains_id(P.catalog_arcana(catalog),id) : Bool}

# Guarantees: an upgrade is offered exactly when its entry exists, rank is below its cap and its price is affordable.
# Why it matters: the camp menu must neither refuse affordable upgrades nor admit a capped or unaffordable one.
law upgrade_admission_exact:
  for +profile: P.Progress
  for +id: U32
  for +catalog: P.Catalog
  {P.upgrade_status_canBuy(P.upgrade_status(profile,id,catalog)) == upgrade_eligible(profile,id,catalog) : Bool}

# Guarantees: an unlock is offered exactly for an existing, unowned character or stage whose requirements and price are met.
# Why it matters: catalog membership alone must not bypass ownership, achievement conditions or payment.
law unlock_admission_exact:
  for +profile: P.Progress
  for +kind: P.SelectionKind
  for +id: U32
  for +catalog: P.Catalog
  {P.purchase_status_canBuy(P.purchase_status(profile,kind,id,catalog)) == unlock_eligible(profile,kind,id,catalog) : Bool}

# Guarantees: buying an eligible upgrade debits its exact quoted price and increments its selected rank by one.
# Why it matters: a successful camp purchase must apply its debit and rank update; locality is pinned separately.
law upgrade_success_exact:
  for +profile: P.Progress
  for +id: U32
  for +catalog: P.Catalog
  for accepted: {True{} == upgrade_eligible(profile,id,catalog) : Bool}
  {P.buy_upgrade(profile,id,catalog) == Some{upgrade_replacement(profile,id,catalog)} : Maybe<&2,P.Progress>}

# Guarantees: an eligible unlock debits its catalog price, adds its identity once and refreshes counts and achievements.
# Why it matters: a successful character or stage purchase cannot omit its payment or ownership update.
law unlock_success_exact:
  for +profile: P.Progress
  for +kind: P.SelectionKind
  for +id: U32
  for +catalog: P.Catalog
  for accepted: {True{} == unlock_eligible(profile,kind,id,catalog) : Bool}
  {P.purchase(profile,kind,id,catalog) == Some{unlock_replacement(profile,kind,id,catalog)} : Maybe<&2,P.Progress>}

# Guarantees: the public upgrade operation performs its exact debit-and-rank transition when eligible and refuses otherwise.
# Why it matters: neither an always-refusing button nor an unaffordable purchase may satisfy the camp contract.
law upgrade_decision_exact:
  for +profile: P.Progress
  for +id: U32
  for +catalog: P.Catalog
  {P.buy_upgrade(profile,id,catalog) == Bool.pick(Maybe<&2,P.Progress>,upgrade_eligible(profile,id,catalog),Some{upgrade_replacement(profile,id,catalog)},None{}) : Maybe<&2,P.Progress>}

# Guarantees: the public unlock operation performs its exact payment-and-ownership update when eligible and refuses otherwise.
# Why it matters: refused purchases cannot replace progress, while eligible purchases must take effect.
law unlock_decision_exact:
  for +profile: P.Progress
  for +kind: P.SelectionKind
  for +id: U32
  for +catalog: P.Catalog
  {P.purchase(profile,kind,id,catalog) == Bool.pick(Maybe<&2,P.Progress>,unlock_eligible(profile,kind,id,catalog),Some{unlock_replacement(profile,kind,id,catalog)},None{}) : Maybe<&2,P.Progress>}

# Guarantees: replacing a rank at an existing position preserves the entire preceding and following loadout.
# Why it matters: purchasing one meta upgrade cannot overwrite another upgrade or lose the array tail.
law rank_replacement_preserves_other_slots:
  for +prefix: List<&2,Nat>
  for +old: Nat
  for +suffix: List<&2,Nat>
  for +replacement: Nat
  {P.replace_at(List.append(&2,Nat,prefix,old <> suffix),List.length(&2,Nat,prefix),replacement) == List.append(&2,Nat,prefix,replacement <> suffix) : List<&2,Nat>}

# Guarantees: recording a run retains its receipt in the returned progress, even when older receipts are evicted.
# Why it matters: the next terminal observation must recognize the run it just paid for.
law recorded_receipt_retained:
  for +profile: P.Progress
  for +frame: P.RunReceipt
  for +catalog: P.Catalog
  {P.contains_text(P.progress_recorded(P.record_profile(P.record_run(profile,frame,catalog))),P.run_runId(frame)) == True{} : Bool}

# Guarantees: immediately observing the same run twice leaves the entire first returned progress unchanged.
# Why it matters: repeated terminal browser frames cannot credit gold or cumulative statistics twice.
law public_record_idempotent:
  for +profile: P.Progress
  for +frame: P.RunReceipt
  for +catalog: P.Catalog
  {P.record_profile(P.record_run(P.record_profile(P.record_run(profile,frame,catalog)),frame,catalog)) == P.record_profile(P.record_run(profile,frame,catalog)) : P.Progress}

# Guarantees: a known receipt preserves the wallet; a new receipt credits exactly the observed whole gold once.
# Why it matters: terminal observations cannot omit or double the first reward, nor pay the same receipt again.
law public_record_gold_exact:
  for +profile: P.Progress
  for +frame: P.RunReceipt
  for +catalog: P.Catalog
  {P.progress_gold(P.record_profile(P.record_run(profile,frame,catalog))) == A.choose(P.contains_text(P.progress_recorded(profile),P.run_runId(frame)),P.progress_gold(profile),A.add(P.progress_gold(profile),A.whole(P.run_gold(frame)))) : A.Amount}

# Guarantees: applying a wallet credit writes exactly the old balance plus the supplied earned amount.
# Why it matters: the production terminal payment cannot silently double or discard a run's gold.
law wallet_credit_exact:
  for +awards: P.Progress
  for +old: A.Amount
  for +gained: A.Amount
  {P.progress_gold(P.pay_wallet(awards,old,gained)) == A.add(old,gained) : A.Amount}

# Guarantees: stamping a receipt retains its identity while applying bounded history eviction.
# Why it matters: the production history write must let the next terminal callback recognize its payment.
law receipt_stamp_retained:
  for +awards: P.Progress
  for +history: List<&2,String>
  for +token: String
  {P.contains_text(P.progress_recorded(P.stamp_receipt(awards,history,token)),token) == True{} : Bool}

# Guarantees: a seen receipt returns original progress and no awards; an unseen receipt returns the computed paid outcome.
# Why it matters: production receipt admission must neither pay twice nor reject every new run.
law receipt_decision_exact:
  for +seen: Bool
  for +profile: P.Progress
  for +paid: P.RecordResult
  {P.record_decided(seen,profile,paid) == Bool.pick(P.RecordResult,seen,P.RecordResult{profile,[]},paid) : P.RecordResult}
