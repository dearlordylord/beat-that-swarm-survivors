import Base
import ../menu-progression.bend as P
import ../menu-amount.bend as A
import LAWS.bend as Laws
import ../proof-facts.bend as F
import ../../../vendor/bendlib/packages/bend-mathlib/list.bend as ML
import ../../../vendor/bendlib/packages/bend-mathlib/nat.bend as MN
import ../../../vendor/bendlib/packages/bend-mathlib/bool.bend as MB

def Laws.receipt_decision_exact(seen,profile,paid):
  match seen:
    case True{}: {==}
    case False{}: {==}

def Laws.arcana_catalog_membership(profile,id,catalog): {==}
def upgrade_admission_entry(+entry: Maybe<&2,P.Upgrade>,+profile: P.Progress,+id: U32) -> {Bool.and(P.has_upgrade(entry),Bool.and(Bool.not(Nat.is_ge(P.rank_at(P.progress_meta(profile),U32.to_nat(id)),P.upgrade_cap(entry))),A.ge(P.progress_gold(profile),P.cost_value(P.upgrade_quoted(entry,profile,id))))) == Bool.and(P.has_upgrade(entry),Bool.and(Bool.not(Nat.is_ge(P.rank_at(P.progress_meta(profile),U32.to_nat(id)),Laws.upgrade_limit(entry))),A.ge(P.progress_gold(profile),Laws.upgrade_quote(entry,P.rank_at(P.progress_meta(profile),U32.to_nat(id)))))) : Bool}:
  match entry:
    case None{}: {==}
    case Some{P.Upgrade{_,_,_}}: {==}

def Laws.upgrade_admission_exact(profile,id,catalog):
  upgrade_admission_entry(P.upgrade_item(catalog,id),profile,id)
def unlock_admission_entry(+entry: Maybe<&2,P.UnlockEntry>,+kind: P.SelectionKind,+profile: P.Progress,+id: U32,+catalog: P.Catalog) -> {Bool.and(P.purchasable(kind),Bool.and(P.has_unlock(entry),Bool.and(Bool.not(P.unlocked(profile,kind,id,catalog)),Bool.and(P.requirements_met(profile,P.unlock_condition(entry)),A.ge(P.progress_gold(profile),P.unlock_cost(entry)))))) == Bool.and(Laws.purchasable(kind),Bool.and(P.has_unlock(entry),Bool.and(Bool.not(P.unlocked(profile,kind,id,catalog)),Bool.and(P.requirements_met(profile,Laws.unlock_requirement(entry)),A.ge(P.progress_gold(profile),Laws.unlock_quote(entry)))))) : Bool}:
  match entry kind:
    case None{} P.Character{}: {==}
    case None{} P.Stage{}: {==}
    case None{} P.Arcana{}: {==}
    case None{} P.Mode{}: {==}
    case None{} P.Weapon{}: {==}
    case Some{P.UnlockEntry{_,_,_}} P.Character{}: {==}
    case Some{P.UnlockEntry{_,_,_}} P.Stage{}: {==}
    case Some{P.UnlockEntry{_,_,_}} P.Arcana{}: {==}
    case Some{P.UnlockEntry{_,_,_}} P.Mode{}: {==}
    case Some{P.UnlockEntry{_,_,_}} P.Weapon{}: {==}

def Laws.unlock_admission_exact(profile,kind,id,catalog):
  unlock_admission_entry(P.unlock_item(kind,catalog,id),kind,profile,id,catalog)

def upgrade_replacement_entry(+entry: Maybe<&2,P.Upgrade>,+profile: P.Progress,+id: U32) -> {P.set_meta(P.set_gold(profile,A.subtract(P.progress_gold(profile),P.cost_value(P.upgrade_quoted(entry,profile,id)))),P.replace_at(P.progress_meta(profile),U32.to_nat(id),Nat.add(P.rank_at(P.progress_meta(profile),U32.to_nat(id)),1n))) == P.set_meta(P.set_gold(profile,A.subtract(P.progress_gold(profile),Laws.upgrade_quote(entry,P.rank_at(P.progress_meta(profile),U32.to_nat(id))))),P.replace_at(P.progress_meta(profile),U32.to_nat(id),Nat.add(P.rank_at(P.progress_meta(profile),U32.to_nat(id)),1n))) : P.Progress}:
  match entry:
    case None{}: {==}
    case Some{P.Upgrade{_,_,_}}: {==}

def upgrade_replacement_equal(+profile: P.Progress,+id: U32,+catalog: P.Catalog) -> {P.buy_upgrade_ok(profile,id,catalog) == Laws.upgrade_replacement(profile,id,catalog) : P.Progress}:
  upgrade_replacement_entry(P.upgrade_item(catalog,id),profile,id)

def unlock_replacement_entry(+entry: Maybe<&2,P.UnlockEntry>,+kind: P.SelectionKind,+profile: P.Progress,+id: U32,+catalog: P.Catalog) -> {P.award(P.refresh_counts(P.add_owned(P.set_gold(profile,A.subtract(P.progress_gold(profile),P.unlock_cost(entry))),kind,id)),catalog) == P.award(P.refresh_counts(P.set_owned(P.set_gold(profile,A.subtract(P.progress_gold(profile),Laws.unlock_quote(entry))),kind,P.append_id(P.owned(profile,kind),id))),catalog) : P.Progress}:
  match entry kind profile:
    case None{} P.Character{} P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}
    case None{} P.Stage{} P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}
    case None{} P.Arcana{} P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}
    case None{} P.Mode{} P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}
    case None{} P.Weapon{} P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}
    case Some{P.UnlockEntry{_,_,_}} P.Character{} P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}
    case Some{P.UnlockEntry{_,_,_}} P.Stage{} P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}
    case Some{P.UnlockEntry{_,_,_}} P.Arcana{} P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}
    case Some{P.UnlockEntry{_,_,_}} P.Mode{} P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}
    case Some{P.UnlockEntry{_,_,_}} P.Weapon{} P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}

def unlock_replacement_equal(+profile: P.Progress,+kind: P.SelectionKind,+id: U32,+catalog: P.Catalog) -> {P.purchase_ok(profile,kind,id,catalog) == Laws.unlock_replacement(profile,kind,id,catalog) : P.Progress}:
  unlock_replacement_entry(P.unlock_item(kind,catalog,id),kind,profile,id,catalog)

def purchase_decision(+test: Bool,+profile: P.Progress) -> {P.purchase_decided(test,profile) == Bool.pick(Maybe<&2,P.Progress>,test,Some{profile},None{}) : Maybe<&2,P.Progress>}:
  match test:
    case True{}: {==}
    case False{}: {==}

def Laws.upgrade_decision_exact(profile,id,catalog):
  %Laws.upgrade_admission_exact(profile,id,catalog) : {P.buy_upgrade(profile,id,catalog) == Bool.pick(Maybe<&2,P.Progress>,_,Some{Laws.upgrade_replacement(profile,id,catalog)},None{}) : Maybe<&2,P.Progress>}
  %upgrade_replacement_equal(profile,id,catalog) : {P.buy_upgrade(profile,id,catalog) == Bool.pick(Maybe<&2,P.Progress>,P.upgrade_status_canBuy(P.upgrade_status(profile,id,catalog)),Some{_},None{}) : Maybe<&2,P.Progress>}
  purchase_decision(P.upgrade_admitted(profile,id,catalog),P.buy_upgrade_ok(profile,id,catalog))

def Laws.unlock_decision_exact(profile,kind,id,catalog):
  %Laws.unlock_admission_exact(profile,kind,id,catalog) : {P.purchase(profile,kind,id,catalog) == Bool.pick(Maybe<&2,P.Progress>,_,Some{Laws.unlock_replacement(profile,kind,id,catalog)},None{}) : Maybe<&2,P.Progress>}
  %unlock_replacement_equal(profile,kind,id,catalog) : {P.purchase(profile,kind,id,catalog) == Bool.pick(Maybe<&2,P.Progress>,P.purchase_status_canBuy(P.purchase_status(profile,kind,id,catalog)),Some{_},None{}) : Maybe<&2,P.Progress>}
  purchase_decision(P.purchase_admitted(profile,kind,id,catalog),P.purchase_ok(profile,kind,id,catalog))

def Laws.upgrade_success_exact(profile,id,catalog,accepted):
  %Equal.sym(Maybe<&2,P.Progress>,P.buy_upgrade(profile,id,catalog),Bool.pick(Maybe<&2,P.Progress>,Laws.upgrade_eligible(profile,id,catalog),Some{Laws.upgrade_replacement(profile,id,catalog)},None{}),Laws.upgrade_decision_exact(profile,id,catalog)) : {_ == Some{Laws.upgrade_replacement(profile,id,catalog)} : Maybe<&2,P.Progress>}
  %accepted : {Bool.pick(Maybe<&2,P.Progress>,_,Some{Laws.upgrade_replacement(profile,id,catalog)},None{}) == Some{Laws.upgrade_replacement(profile,id,catalog)} : Maybe<&2,P.Progress>}
  {==}

def Laws.unlock_success_exact(profile,kind,id,catalog,accepted):
  %Equal.sym(Maybe<&2,P.Progress>,P.purchase(profile,kind,id,catalog),Bool.pick(Maybe<&2,P.Progress>,Laws.unlock_eligible(profile,kind,id,catalog),Some{Laws.unlock_replacement(profile,kind,id,catalog)},None{}),Laws.unlock_decision_exact(profile,kind,id,catalog)) : {_ == Some{Laws.unlock_replacement(profile,kind,id,catalog)} : Maybe<&2,P.Progress>}
  %accepted : {Bool.pick(Maybe<&2,P.Progress>,_,Some{Laws.unlock_replacement(profile,kind,id,catalog)},None{}) == Some{Laws.unlock_replacement(profile,kind,id,catalog)} : Maybe<&2,P.Progress>}
  {==}

def Laws.rank_replacement_preserves_other_slots(prefix,old,suffix,replacement):
  match prefix:
    case Nil{}: {==}
    case Con{+head,+tail}:
      Equal.cong(List<&2,Nat>,List<&2,Nat>,rows => head <> rows,P.replace_at(List.append(&2,Nat,tail,old <> suffix),List.length(&2,Nat,tail),replacement),List.append(&2,Nat,tail,replacement <> suffix),Laws.rank_replacement_preserves_other_slots(tail,old,suffix,replacement))

def Laws.wallet_credit_exact(awards,old,gained):
  match awards:
    case P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}

def recent_append(+rows: List<&2,String>,+token: String) -> {P.recent(List.append(&2,String,rows,[token])) == List.append(&2,String,List.drop(&2,String,rows,Nat.sub(List.length(&2,String,rows),99n)),[token]) : List<&2,String>}:
  %ML.length_append_sym(&2,String,rows,[token]) : {List.drop(&2,String,List.append(&2,String,rows,[token]),Nat.sub(_,100n)) == List.append(&2,String,List.drop(&2,String,rows,Nat.sub(List.length(&2,String,rows),99n)),[token]) : List<&2,String>}
  %MN.add_succ_sym(List.length(&2,String,rows),0n) : {List.drop(&2,String,List.append(&2,String,rows,[token]),Nat.sub(_,100n)) == List.append(&2,String,List.drop(&2,String,rows,Nat.sub(List.length(&2,String,rows),99n)),[token]) : List<&2,String>}
  %MN.add_zero_sym(List.length(&2,String,rows)) : {List.drop(&2,String,List.append(&2,String,rows,[token]),Nat.sub(1n+_,100n)) == List.append(&2,String,List.drop(&2,String,rows,Nat.sub(List.length(&2,String,rows),99n)),[token]) : List<&2,String>}
  ML.drop_append_of_le_length(&2,String,rows,[token],Nat.sub(List.length(&2,String,rows),99n),MN.sub_le(List.length(&2,String,rows),99n))

def recent_contains(+rows: List<&2,String>,+token: String) -> {P.contains_text(P.recent(List.append(&2,String,rows,[token])),token) == True{} : Bool}:
  %Equal.sym(List<&2,String>,P.recent(List.append(&2,String,rows,[token])),List.append(&2,String,List.drop(&2,String,rows,Nat.sub(List.length(&2,String,rows),99n)),[token]),recent_append(rows,token)) : {P.contains_text(_,token) == True{} : Bool}
  %ML.contains_append_sym(~String,~String.eq,List.drop(&2,String,rows,Nat.sub(List.length(&2,String,rows),99n)),[token],token) : {_ == True{} : Bool}
  %Equal.sym(Bool,String.eq(token,token),True{},F.string_eq_refl(token)) : {Bool.or(P.contains_text(List.drop(&2,String,rows,Nat.sub(List.length(&2,String,rows),99n)),token),List.any.if(u => False{},_)) == True{} : Bool}
  MB.or_true(P.contains_text(List.drop(&2,String,rows,Nat.sub(List.length(&2,String,rows),99n)),token))

def Laws.receipt_stamp_retained(awards,history,token):
  match awards:
    case P.Progress{_,_,_,_,_,_,_,_,_,_}: recent_contains(history,token)

def Laws.recorded_run_unchanged(profile,frame,catalog,recorded):
  %recorded : {P.record_decided(_,profile,P.recording(profile,frame,catalog)) == P.RecordResult{profile,[]} : P.RecordResult}
  {==}

def stamp_recorded(+profile: P.Progress,+history: List<&2,String>,+token: String) -> {P.progress_recorded(P.stamp_receipt(profile,history,token)) == P.recent(List.append(&2,String,history,[token])) : List<&2,String>}:
  match profile:
    case P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}

def recording_contains(+profile: P.Progress,+frame: P.RunReceipt,+catalog: P.Catalog) -> {P.contains_text(P.progress_recorded(P.record_profile(P.recording(profile,frame,catalog))),P.run_runId(frame)) == True{} : Bool}:
  %Equal.sym(List<&2,String>,P.progress_recorded(P.stamp_receipt(P.run_payment(profile,frame,catalog),P.progress_recorded(profile),P.run_runId(frame))),P.recent(List.append(&2,String,P.progress_recorded(profile),[P.run_runId(frame)])),stamp_recorded(P.run_payment(profile,frame,catalog),P.progress_recorded(profile),P.run_runId(frame))) : {P.contains_text(_,P.run_runId(frame)) == True{} : Bool}
  recent_contains(P.progress_recorded(profile),P.run_runId(frame))

def receipt_branch(seen: Bool,+profile: P.Progress,+frame: P.RunReceipt,+catalog: P.Catalog,condition: {seen == P.contains_text(P.progress_recorded(profile),P.run_runId(frame)) : Bool}) -> {P.contains_text(P.progress_recorded(P.record_profile(P.record_decided(seen,profile,P.recording(profile,frame,catalog)))),P.run_runId(frame)) == True{} : Bool}:
  match seen:
    case True{}: Equal.sym(Bool,True{},P.contains_text(P.progress_recorded(profile),P.run_runId(frame)),condition)
    case False{}: recording_contains(profile,frame,catalog)

def Laws.recorded_receipt_retained(profile,frame,catalog):
  receipt_branch(P.contains_text(P.progress_recorded(profile),P.run_runId(frame)),profile,frame,catalog,{==})

def Laws.public_record_idempotent(profile,frame,catalog):
  %Equal.sym(Bool,P.contains_text(P.progress_recorded(P.record_profile(P.record_run(profile,frame,catalog))),P.run_runId(frame)),True{},Laws.recorded_receipt_retained(profile,frame,catalog)) : {P.record_profile(P.record_decided(_,P.record_profile(P.record_run(profile,frame,catalog)),P.recording(P.record_profile(P.record_run(profile,frame,catalog)),frame,catalog))) == P.record_profile(P.record_run(profile,frame,catalog)) : P.Progress}
  {==}

def stamp_gold(+profile: P.Progress,+history: List<&2,String>,+token: String) -> {P.progress_gold(P.stamp_receipt(profile,history,token)) == P.progress_gold(profile) : A.Amount}:
  match profile:
    case P.Progress{_,_,_,_,_,_,_,_,_,_}: {==}

def recording_gold(+profile: P.Progress,+frame: P.RunReceipt,+catalog: P.Catalog) -> {P.progress_gold(P.record_profile(P.recording(profile,frame,catalog))) == A.add(P.progress_gold(profile),A.whole(P.run_gold(frame))) : A.Amount}:
  %Equal.sym(A.Amount,P.progress_gold(P.stamp_receipt(P.run_payment(profile,frame,catalog),P.progress_recorded(profile),P.run_runId(frame))),P.progress_gold(P.run_payment(profile,frame,catalog)),stamp_gold(P.run_payment(profile,frame,catalog),P.progress_recorded(profile),P.run_runId(frame))) : {_ == A.add(P.progress_gold(profile),A.whole(P.run_gold(frame))) : A.Amount}
  Laws.wallet_credit_exact(P.run_awards(profile,frame,catalog),P.progress_gold(profile),A.whole(P.run_gold(frame)))

def record_gold_branch(seen: Bool,+profile: P.Progress,+frame: P.RunReceipt,+catalog: P.Catalog) -> {P.progress_gold(P.record_profile(P.record_decided(seen,profile,P.recording(profile,frame,catalog)))) == A.choose(seen,P.progress_gold(profile),A.add(P.progress_gold(profile),A.whole(P.run_gold(frame)))) : A.Amount}:
  match seen:
    case True{}: {==}
    case False{}: recording_gold(profile,frame,catalog)

def Laws.public_record_gold_exact(profile,frame,catalog):
  record_gold_branch(P.contains_text(P.progress_recorded(profile),P.run_runId(frame)),profile,frame,catalog)
