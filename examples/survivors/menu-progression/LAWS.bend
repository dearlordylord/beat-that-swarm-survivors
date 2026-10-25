import Base
import ../menu-progression.bend as P

# Guarantees: re-observing a recorded run preserves the whole profile and adds no achievements.
# Why it matters: a terminal receipt already present in storage cannot pay twice.
law recorded_run_unchanged:
  for +profile: P.Value
  for +frame: P.Value
  for +catalog: P.Value
  for recorded: {True{} == P.contains(P.sequence(P.get(profile,"recorded")),P.record_signature(frame)) : Bool}
  {P.record_run(profile,frame,catalog) == P.JObject{["profile","added"],[profile,P.JSequence{[]}]} : P.Value}

# Guarantees: arcana availability is precisely membership in the supplied catalog.
# Why it matters: the menu cannot offer an arcana identity absent from the actual catalog.
law arcana_catalog_membership:
  for profile: P.Value
  for +id: P.Value
  for +catalog: P.Value
  {P.unlocked(profile,"arcana",id,catalog) == Bool.not(P.is_null(P.item(catalog,"arcana",id))) : Bool}

# Guarantees: an upgrade is offered exactly when the catalog entry exists, its rank is below its cap and its price is affordable.
# Why it matters: the camp menu must neither refuse affordable upgrades nor admit a capped or unaffordable one.
law upgrade_admission_exact:
  for +profile: P.Value
  for +id: P.Value
  for +catalog: P.Value
  {P.boolean(P.get(P.upgrade_status(profile,id,catalog),"canBuy")) == Bool.and(Bool.not(P.is_null(P.upgrade_item(catalog,id))),Bool.and(Bool.not(P.ge(P.at(P.sequence(P.get(profile,"meta")),P.integer(id)),P.get(P.upgrade_item(catalog,id),"maxLevel"))),P.ge(P.get(profile,"gold"),P.upgrade_cost(profile,id,catalog)))) : Bool}

# Guarantees: an unlock is offered exactly for an existing, unowned character or stage whose requirements and price are met.
# Why it matters: catalog membership alone must not bypass ownership, achievement conditions or payment.
law unlock_admission_exact:
  for +profile: P.Value
  for +kind: String
  for +id: P.Value
  for +catalog: P.Value
  {P.boolean(P.get(P.purchase_status(profile,kind,id,catalog),"canBuy")) == Bool.and(Bool.or(String.eq(kind,"character"),String.eq(kind,"stage")),Bool.and(Bool.not(P.is_null(P.item(catalog,kind,id))),Bool.and(Bool.not(P.unlocked(profile,kind,id,catalog)),Bool.and(P.requirements_met(profile,P.item(catalog,kind,id)),P.ge(P.get(profile,"gold"),P.get(P.item(catalog,kind,id),"cost")))))) : Bool}

# Guarantees: buying an eligible upgrade debits its exact quoted price and replaces the selected rank slot with its previous value plus one.
# Why it matters: a successful camp purchase must apply its quoted debit and selected-slot update; a separate law pins replacement locality.
law upgrade_success_exact:
  for +profile: P.Value
  for +id: P.Value
  for +catalog: P.Value
  for accepted: {True{} == Bool.and(Bool.not(P.is_null(P.upgrade_item(catalog,id))),Bool.and(Bool.not(P.ge(P.at(P.sequence(P.get(profile,"meta")),P.integer(id)),P.get(P.upgrade_item(catalog,id),"maxLevel"))),P.ge(P.get(profile,"gold"),P.upgrade_cost(profile,id,catalog)))) : Bool}
  {P.buy_upgrade(profile,id,catalog) == P.set(P.set(profile,"gold",P.subtract(P.get(profile,"gold"),P.upgrade_cost(profile,id,catalog))),"meta",P.JSequence{P.replace_at(P.sequence(P.get(profile,"meta")),P.integer(id),P.add(P.at(P.sequence(P.get(profile,"meta")),P.integer(id)),P.one()))}) : P.Value}

# Guarantees: buying an eligible unlock debits its catalog price, adds its identity once and refreshes only the declared counts and achievements.
# Why it matters: a successful character or stage purchase cannot be acknowledged without its payment and ownership update.
law unlock_success_exact:
  for +profile: P.Value
  for +kind: String
  for +id: P.Value
  for +catalog: P.Value
  for accepted: {True{} == Bool.and(Bool.or(String.eq(kind,"character"),String.eq(kind,"stage")),Bool.and(Bool.not(P.is_null(P.item(catalog,kind,id))),Bool.and(Bool.not(P.unlocked(profile,kind,id,catalog)),Bool.and(P.requirements_met(profile,P.item(catalog,kind,id)),P.ge(P.get(profile,"gold"),P.get(P.item(catalog,kind,id),"cost")))))) : Bool}
  {P.purchase(profile,kind,id,catalog) == P.award(P.refresh_counts(P.set(P.set(profile,"gold",P.subtract(P.get(profile,"gold"),P.get(P.item(catalog,kind,id),"cost"))),P.owned_list(kind),P.JSequence{P.append_unique(P.sequence(P.get(P.set(profile,"gold",P.subtract(P.get(profile,"gold"),P.get(P.item(catalog,kind,id),"cost"))),P.owned_list(kind))),id)})),catalog) : P.Value}

# Guarantees: the public upgrade operation returns exactly the debit-and-rank transition when eligible and no replacement otherwise.
# Why it matters: neither an always-refusing button nor an unaffordable purchase may satisfy the camp's purchase contract.
law upgrade_decision_exact:
  for +profile: P.Value
  for +id: P.Value
  for +catalog: P.Value
  {P.buy_upgrade(profile,id,catalog) == P.pick(Bool.and(Bool.not(P.is_null(P.upgrade_item(catalog,id))),Bool.and(Bool.not(P.ge(P.at(P.sequence(P.get(profile,"meta")),P.integer(id)),P.get(P.upgrade_item(catalog,id),"maxLevel"))),P.ge(P.get(profile,"gold"),P.upgrade_cost(profile,id,catalog)))),P.set(P.set(profile,"gold",P.subtract(P.get(profile,"gold"),P.upgrade_cost(profile,id,catalog))),"meta",P.JSequence{P.replace_at(P.sequence(P.get(profile,"meta")),P.integer(id),P.add(P.at(P.sequence(P.get(profile,"meta")),P.integer(id)),P.one()))}),P.JNull{}) : P.Value}

# Guarantees: the public unlock operation performs exactly its payment-and-ownership update when eligible and returns no replacement otherwise.
# Why it matters: refused camp purchases cannot change the saved profile, while valid purchases must take effect.
law unlock_decision_exact:
  for +profile: P.Value
  for +kind: String
  for +id: P.Value
  for +catalog: P.Value
  {P.purchase(profile,kind,id,catalog) == P.pick(Bool.and(Bool.or(String.eq(kind,"character"),String.eq(kind,"stage")),Bool.and(Bool.not(P.is_null(P.item(catalog,kind,id))),Bool.and(Bool.not(P.unlocked(profile,kind,id,catalog)),Bool.and(P.requirements_met(profile,P.item(catalog,kind,id)),P.ge(P.get(profile,"gold"),P.get(P.item(catalog,kind,id),"cost")))))),P.award(P.refresh_counts(P.set(P.set(profile,"gold",P.subtract(P.get(profile,"gold"),P.get(P.item(catalog,kind,id),"cost"))),P.owned_list(kind),P.JSequence{P.append_unique(P.sequence(P.get(P.set(profile,"gold",P.subtract(P.get(profile,"gold"),P.get(P.item(catalog,kind,id),"cost"))),P.owned_list(kind))),id)})),catalog),P.JNull{}) : P.Value}

# Guarantees: replacing a rank at an existing position preserves the entire preceding and following loadout.
# Why it matters: purchasing one meta upgrade cannot overwrite another upgrade or lose the tail of the rank array.
law rank_replacement_preserves_other_slots:
  for +prefix: List<&2,P.Value>
  for +old: P.Value
  for +suffix: List<&2,P.Value>
  for +replacement: P.Value
  {P.replace_at(List.append(&2,P.Value,prefix,old <> suffix),List.length(&2,P.Value,prefix),replacement) == List.append(&2,P.Value,prefix,replacement <> suffix) : List<&2,P.Value>}

# Guarantees: reading a field immediately after setting it returns the exact stored value, for every JSON shape.
# Why it matters: profile writes must not silently lose gold, ownership or terminal receipt identities.
law object_field_roundtrip:
  for +object: P.Value
  for +key: String
  for +value: P.Value
  {P.get(P.set(object,key,value),key) == value : P.Value}

# Guarantees: recording a frame with a text receipt retains that receipt in the returned profile, even when older receipts are evicted.
# Why it matters: the next terminal observation must recognize the run it just paid for.
law recorded_receipt_retained:
  for +profile: P.Value
  for +frame: P.Value
  for +catalog: P.Value
  for +token: String
  for signature: {P.JText{token} == P.record_signature(frame) : P.Value}
  {P.contains(P.sequence(P.get(P.get(P.record_run(profile,frame,catalog),"profile"),"recorded")),P.JText{token}) == True{} : Bool}

# Guarantees: immediately observing the same text-identified run twice leaves the entire first returned profile unchanged.
# Why it matters: repeated terminal browser frames cannot credit gold or cumulative statistics twice.
law public_record_idempotent:
  for +profile: P.Value
  for +frame: P.Value
  for +catalog: P.Value
  for +token: String
  for +signature: {P.JText{token} == P.record_signature(frame) : P.Value}
  {P.get(P.record_run(P.get(P.record_run(profile,frame,catalog),"profile"),frame,catalog),"profile") == P.get(P.record_run(profile,frame,catalog),"profile") : P.Value}

# Guarantees: setting one object field preserves every differently named field.
# Why it matters: recording a run identity must not erase its wallet payment or other saved progression.
law object_other_field_preserved:
  for +object: P.Value
  for +writeKey: String
  for +readKey: String
  for +value: P.Value
  for different: {False{} == String.eq(writeKey,readKey) : Bool}
  {P.get(P.set(object,writeKey,value),readKey) == P.get(object,readKey) : P.Value}

# Guarantees: the public run operation preserves an already recorded run's wallet, otherwise it credits exactly the observed whole gold once.
# Why it matters: terminal observations cannot omit or double the first reward, nor pay the same receipt again.
law public_record_gold_exact:
  for +profile: P.Value
  for +frame: P.Value
  for +catalog: P.Value
  {P.get(P.get(P.record_run(profile,frame,catalog),"profile"),"gold") == P.pick(P.contains(P.sequence(P.get(profile,"recorded")),P.record_signature(frame)),P.get(profile,"gold"),P.add(P.get(profile,"gold"),P.whole(P.get(frame,"gold")))) : P.Value}

# Guarantees: applying a wallet credit writes exactly the old balance plus the supplied earned amount.
# Why it matters: the production terminal payment cannot silently double or discard a run's gold.
law wallet_credit_exact:
  for +awards: P.Value
  for +old: P.Value
  for +gained: P.Value
  {P.get(P.pay_wallet(awards,old,gained),"gold") == P.add(old,gained) : P.Value}

# Guarantees: stamping a text receipt retains that identity while applying bounded history eviction.
# Why it matters: the production history write must let the next terminal callback recognize its payment.
law receipt_stamp_retained:
  for +awards: P.Value
  for +history: List<&2,P.Value>
  for +token: String
  {P.contains(P.sequence(P.get(P.stamp_receipt(awards,history,P.JText{token}),"recorded")),P.JText{token}) == True{} : Bool}

# Guarantees: a previously observed receipt returns the original profile with no new awards; an unseen one returns the computed payment outcome.
# Why it matters: production receipt admission must neither pay twice nor reject every new run.
law receipt_decision_exact:
  for +seen: Bool
  for +profile: P.Value
  for +paid: P.Value
  {P.record_decided(seen,profile,paid) == P.pick(seen,P.JObject{["profile","added"],[profile,P.JSequence{[]}]},paid) : P.Value}
