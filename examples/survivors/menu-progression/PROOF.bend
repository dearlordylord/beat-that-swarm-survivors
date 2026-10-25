import Base
import ../menu-progression.bend as P
import LAWS.bend as Laws
import ../proof-facts.bend as F
import ../../../vendor/bendlib/packages/bend-mathlib/list.bend as ML
import ../../../vendor/bendlib/packages/bend-mathlib/nat.bend as MN
import ../../../vendor/bendlib/packages/bend-mathlib/bool.bend as MB
import ../../../vendor/bendlib/packages/bend-mathlib/string.bend as MS

def Laws.receipt_decision_exact(seen,profile,paid): {==}

def lookup_new(+key: String,+value: P.Value) -> {P.get(P.JObject{[key],[value]},key) == value : P.Value}:
  %Equal.sym(Bool,String.eq(key,key),True{},F.string_eq_refl(key)) : {P.pick(_,value,P.JNull{}) == value : P.Value}
  {==}

def lookup_prepend(+name: String,+old: P.Value,rows: P.ObjectRows,+key: String) -> {P.get(P.object_value(P.prepend_object(name,old,rows)),key) == P.pick(String.eq(name,key),old,P.get(P.object_value(rows),key)) : P.Value}:
  match rows:
    case P.ObjectRows{+keys,+values}: {==}

def lookup_branch(same: Bool,+name: String,+keys: List<&2,String>,+old: P.Value,+values: List<&2,P.Value>,+key: String,+value: P.Value,+next: P.ObjectRows,h: {same == String.eq(name,key) : Bool},found: {P.get(P.object_value(next),key) == value : P.Value}) -> {P.get(P.object_value(P.set_head(same,name,keys,old,values,value,next)),key) == value : P.Value}:
  match same:
    case True{}:
      %h : {P.pick(_,value,P.get_rows(keys,values,key)) == value : P.Value}
      {==}
    case False{}:
      %Equal.sym(P.Value,P.get(P.object_value(P.prepend_object(name,old,next)),key),P.pick(String.eq(name,key),old,P.get(P.object_value(next),key)),lookup_prepend(name,old,next,key)) : {_ == value : P.Value}
      %h : {P.pick(_,old,P.get(P.object_value(next),key)) == value : P.Value}
      found

def lookup_rows(+keys: List<&2,String>,+values: List<&2,P.Value>,+key: String,+value: P.Value) -> {P.get(P.object_value(P.set_rows(keys,values,key,value)),key) == value : P.Value}:
  match keys values:
    case Con{+name,+restKeys} Con{+old,+restValues}:
      lookup_branch(String.eq(name,key),name,restKeys,old,restValues,key,value,P.set_rows(restKeys,restValues,key,value),{==},lookup_rows(restKeys,restValues,key,value))
    case Nil{} _: lookup_new(key,value)
    case Con{_,_} Nil{}: lookup_new(key,value)

def Laws.object_field_roundtrip(object,key,value):
  match object:
    case P.JObject{keys,values}: lookup_rows(keys,values,key,value)
    case P.JNull{}: lookup_new(key,value)
    case P.JBoolean{_}: lookup_new(key,value)
    case P.JNumber{_,_,_}: lookup_new(key,value)
    case P.JText{_}: lookup_new(key,value)
    case P.JDecimal{_,_,_,_}: lookup_new(key,value)
    case P.JRatio{_,_}: lookup_new(key,value)
    case P.JSequence{_}: lookup_new(key,value)


def Laws.wallet_credit_exact(awards,old,gained):
  Laws.object_field_roundtrip(awards,"gold",P.add(old,gained))

def recent_append(+rows: List<&2,P.Value>,+token: String) -> {P.recent(List.append(&2,P.Value,rows,[P.JText{token}])) == List.append(&2,P.Value,List.drop(&2,P.Value,rows,Nat.sub(List.length(&2,P.Value,rows),99n)),[P.JText{token}]) : List<&2,P.Value>}:
  %ML.length_append_sym(&2,P.Value,rows,[P.JText{token}]) : {List.drop(&2,P.Value,List.append(&2,P.Value,rows,[P.JText{token}]),Nat.sub(_,100n)) == List.append(&2,P.Value,List.drop(&2,P.Value,rows,Nat.sub(List.length(&2,P.Value,rows),99n)),[P.JText{token}]) : List<&2,P.Value>}
  %MN.add_succ_sym(List.length(&2,P.Value,rows),0n) : {List.drop(&2,P.Value,List.append(&2,P.Value,rows,[P.JText{token}]),Nat.sub(_,100n)) == List.append(&2,P.Value,List.drop(&2,P.Value,rows,Nat.sub(List.length(&2,P.Value,rows),99n)),[P.JText{token}]) : List<&2,P.Value>}
  %MN.add_zero_sym(List.length(&2,P.Value,rows)) : {List.drop(&2,P.Value,List.append(&2,P.Value,rows,[P.JText{token}]),Nat.sub(1n+_,100n)) == List.append(&2,P.Value,List.drop(&2,P.Value,rows,Nat.sub(List.length(&2,P.Value,rows),99n)),[P.JText{token}]) : List<&2,P.Value>}
  ML.drop_append_of_le_length(&2,P.Value,rows,[P.JText{token}],Nat.sub(List.length(&2,P.Value,rows),99n),MN.sub_le(List.length(&2,P.Value,rows),99n))

def recent_contains(+rows: List<&2,P.Value>,+token: String) -> {P.contains(P.recent(List.append(&2,P.Value,rows,[P.JText{token}])),P.JText{token}) == True{} : Bool}:
  %Equal.sym(List<&2,P.Value>,P.recent(List.append(&2,P.Value,rows,[P.JText{token}])),List.append(&2,P.Value,List.drop(&2,P.Value,rows,Nat.sub(List.length(&2,P.Value,rows),99n)),[P.JText{token}]),recent_append(rows,token)) : {P.contains(_,P.JText{token}) == True{} : Bool}
  %ML.contains_append_sym(~P.Value,~P.value_equal,List.drop(&2,P.Value,rows,Nat.sub(List.length(&2,P.Value,rows),99n)),[P.JText{token}],P.JText{token}) : {_ == True{} : Bool}
  %Equal.sym(Bool,String.eq(token,token),True{},F.string_eq_refl(token)) : {Bool.or(P.contains(List.drop(&2,P.Value,rows,Nat.sub(List.length(&2,P.Value,rows),99n)),P.JText{token}),List.any.if(u => False{},_)) == True{} : Bool}
  MB.or_true(P.contains(List.drop(&2,P.Value,rows,Nat.sub(List.length(&2,P.Value,rows),99n)),P.JText{token}))


def Laws.receipt_stamp_retained(awards,history,token):
  %Equal.sym(P.Value,P.get(P.set(awards,"recorded",P.JSequence{P.recent(List.append(&2,P.Value,history,[P.JText{token}]))}),"recorded"),P.JSequence{P.recent(List.append(&2,P.Value,history,[P.JText{token}]))},Laws.object_field_roundtrip(awards,"recorded",P.JSequence{P.recent(List.append(&2,P.Value,history,[P.JText{token}]))})) : {P.contains(P.sequence(_),P.JText{token}) == True{} : Bool}
  recent_contains(history,token)

def Laws.recorded_run_unchanged(profile,frame,catalog,recorded):
  %recorded : {P.pick(_,P.JObject{["profile","added"],[profile,P.JSequence{[]}]},P.recording(profile,frame,catalog)) == P.JObject{["profile","added"],[profile,P.JSequence{[]}]} : P.Value}
  {==}

def Laws.arcana_catalog_membership(profile,id,catalog): {==}


def Laws.upgrade_admission_exact(profile,id,catalog): {==}

def Laws.unlock_admission_exact(profile,kind,id,catalog): {==}

def Laws.upgrade_success_exact(profile,id,catalog,accepted):
  %accepted : {P.pick(_,P.buy_upgrade_ok(profile,id,catalog),P.JNull{}) == P.set(P.set(profile,"gold",P.subtract(P.get(profile,"gold"),P.upgrade_cost(profile,id,catalog))),"meta",P.JSequence{P.replace_at(P.sequence(P.get(profile,"meta")),P.integer(id),P.add(P.at(P.sequence(P.get(profile,"meta")),P.integer(id)),P.one()))}) : P.Value}
  {==}

def Laws.unlock_success_exact(profile,kind,id,catalog,accepted):
  %accepted : {P.pick(_,P.purchase_ok(profile,kind,id,catalog),P.JNull{}) == P.award(P.refresh_counts(P.set(P.set(profile,"gold",P.subtract(P.get(profile,"gold"),P.get(P.item(catalog,kind,id),"cost"))),P.owned_list(kind),P.JSequence{P.append_unique(P.sequence(P.get(P.set(profile,"gold",P.subtract(P.get(profile,"gold"),P.get(P.item(catalog,kind,id),"cost"))),P.owned_list(kind))),id)})),catalog) : P.Value}
  {==}


def Laws.upgrade_decision_exact(profile,id,catalog): {==}

def Laws.unlock_decision_exact(profile,kind,id,catalog): {==}

def Laws.rank_replacement_preserves_other_slots(prefix,old,suffix,replacement):
  match prefix:
    case Nil{}: {==}
    case Con{+head,+tail}:
      Equal.cong(List<&2,P.Value>,List<&2,P.Value>,rows => head <> rows,P.replace_at(List.append(&2,P.Value,tail,old <> suffix),List.length(&2,P.Value,tail),replacement),List.append(&2,P.Value,tail,replacement <> suffix),Laws.rank_replacement_preserves_other_slots(tail,old,suffix,replacement))


def recording_contains(+profile: P.Value,+frame: P.Value,+catalog: P.Value,+token: String,signature: {P.JText{token} == P.record_signature(frame) : P.Value}) -> {P.contains(P.sequence(P.get(P.get(P.recording(profile,frame,catalog),"profile"),"recorded")),P.JText{token}) == True{} : Bool}:
  %signature : {P.contains(P.sequence(P.get(P.set(P.run_payment(profile,frame,catalog),"recorded",P.JSequence{P.recent(List.append(&2,P.Value,P.sequence(P.get(profile,"recorded")),[_]))}),"recorded")),P.JText{token}) == True{} : Bool}
  %Equal.sym(P.Value,P.get(P.set(P.run_payment(profile,frame,catalog),"recorded",P.JSequence{P.recent(List.append(&2,P.Value,P.sequence(P.get(profile,"recorded")),[P.JText{token}]))}),"recorded"),P.JSequence{P.recent(List.append(&2,P.Value,P.sequence(P.get(profile,"recorded")),[P.JText{token}]))},Laws.object_field_roundtrip(P.run_payment(profile,frame,catalog),"recorded",P.JSequence{P.recent(List.append(&2,P.Value,P.sequence(P.get(profile,"recorded")),[P.JText{token}]))})) : {P.contains(P.sequence(_),P.JText{token}) == True{} : Bool}
  recent_contains(P.sequence(P.get(profile,"recorded")),token)

def receipt_branch(seen: Bool,+profile: P.Value,+frame: P.Value,+catalog: P.Value,+token: String,signature: {P.JText{token} == P.record_signature(frame) : P.Value},condition: {seen == P.contains(P.sequence(P.get(profile,"recorded")),P.record_signature(frame)) : Bool}) -> {P.contains(P.sequence(P.get(P.get(P.pick(seen,P.JObject{["profile","added"],[profile,P.JSequence{[]}]},P.recording(profile,frame,catalog)),"profile"),"recorded")),P.JText{token}) == True{} : Bool}:
  match seen:
    case True{}:
      Equal.sym(Bool,True{},P.contains(P.sequence(P.get(profile,"recorded")),P.JText{token}),Equal.trans(Bool,True{},P.contains(P.sequence(P.get(profile,"recorded")),P.record_signature(frame)),P.contains(P.sequence(P.get(profile,"recorded")),P.JText{token}),condition,Equal.cong(P.Value,Bool,value => P.contains(P.sequence(P.get(profile,"recorded")),value),P.record_signature(frame),P.JText{token},Equal.sym(P.Value,P.JText{token},P.record_signature(frame),signature))))
    case False{}: recording_contains(profile,frame,catalog,token,signature)

def Laws.recorded_receipt_retained(profile,frame,catalog,token,signature):
  receipt_branch(P.contains(P.sequence(P.get(profile,"recorded")),P.record_signature(frame)),profile,frame,catalog,token,signature,{==})

def Laws.public_record_idempotent(profile,frame,catalog,token,signature):
  %signature : {P.get(P.pick(P.contains(P.sequence(P.get(P.get(P.record_run(profile,frame,catalog),"profile"),"recorded")),_),P.JObject{["profile","added"],[P.get(P.record_run(profile,frame,catalog),"profile"),P.JSequence{[]}]},P.recording(P.get(P.record_run(profile,frame,catalog),"profile"),frame,catalog)),"profile") == P.get(P.record_run(profile,frame,catalog),"profile") : P.Value}
  %Equal.sym(Bool,P.contains(P.sequence(P.get(P.get(P.record_run(profile,frame,catalog),"profile"),"recorded")),P.JText{token}),True{},Laws.recorded_receipt_retained(profile,frame,catalog,token,signature)) : {P.get(P.pick(_,P.JObject{["profile","added"],[P.get(P.record_run(profile,frame,catalog),"profile"),P.JSequence{[]}]},P.recording(P.get(P.record_run(profile,frame,catalog),"profile"),frame,catalog)),"profile") == P.get(P.record_run(profile,frame,catalog),"profile") : P.Value}
  {==}


def other_name_false(+name: String,+writeKey: String,+readKey: String,same: {True{} == String.eq(name,writeKey) : Bool},different: {False{} == String.eq(writeKey,readKey) : Bool}) -> {False{} == String.eq(name,readKey) : Bool}:
  Equal.trans(Bool,False{},String.eq(writeKey,readKey),String.eq(name,readKey),different,Equal.cong(String,Bool,k => String.eq(k,readKey),writeKey,name,Equal.sym(String,name,writeKey,MS.eq_of_eq_true(name,writeKey,Equal.sym(Bool,True{},String.eq(name,writeKey),same)))))

def other_branch(same: Bool,+name: String,+keys: List<&2,String>,+old: P.Value,+values: List<&2,P.Value>,+writeKey: String,+readKey: String,+value: P.Value,+next: P.ObjectRows,h: {same == String.eq(name,writeKey) : Bool},different: {False{} == String.eq(writeKey,readKey) : Bool},found: {P.get(P.object_value(next),readKey) == P.get_rows(keys,values,readKey) : P.Value}) -> {P.get(P.object_value(P.set_head(same,name,keys,old,values,value,next)),readKey) == P.get_rows(name <> keys,old <> values,readKey) : P.Value}:
  match same:
    case True{}:
      %other_name_false(name,writeKey,readKey,h,different) : {P.pick(_,value,P.get_rows(keys,values,readKey)) == P.pick(_,old,P.get_rows(keys,values,readKey)) : P.Value}
      {==}
    case False{}:
      %Equal.sym(P.Value,P.get(P.object_value(P.prepend_object(name,old,next)),readKey),P.pick(String.eq(name,readKey),old,P.get(P.object_value(next),readKey)),lookup_prepend(name,old,next,readKey)) : {_ == P.get_rows(name <> keys,old <> values,readKey) : P.Value}
      Equal.cong(P.Value,P.Value,item => P.pick(String.eq(name,readKey),old,item),P.get(P.object_value(next),readKey),P.get_rows(keys,values,readKey),found)

def other_new(+writeKey: String,+readKey: String,+value: P.Value,different: {False{} == String.eq(writeKey,readKey) : Bool}) -> {P.get(P.JObject{[writeKey],[value]},readKey) == P.JNull{} : P.Value}:
  %different : {P.pick(_,value,P.JNull{}) == P.JNull{} : P.Value}
  {==}

def other_rows(+keys: List<&2,String>,+values: List<&2,P.Value>,+writeKey: String,+readKey: String,+value: P.Value,+different: {False{} == String.eq(writeKey,readKey) : Bool}) -> {P.get(P.object_value(P.set_rows(keys,values,writeKey,value)),readKey) == P.get_rows(keys,values,readKey) : P.Value}:
  match keys values:
    case Con{+name,+restKeys} Con{+old,+restValues}:
      other_branch(String.eq(name,writeKey),name,restKeys,old,restValues,writeKey,readKey,value,P.set_rows(restKeys,restValues,writeKey,value),{==},different,other_rows(restKeys,restValues,writeKey,readKey,value,different))
    case Nil{} _: other_new(writeKey,readKey,value,different)
    case Con{_,_} Nil{}: other_new(writeKey,readKey,value,different)

def Laws.object_other_field_preserved(object,writeKey,readKey,value,different):
  match object:
    case P.JObject{keys,values}: other_rows(keys,values,writeKey,readKey,value,different)
    case P.JNull{}: other_new(writeKey,readKey,value,different)
    case P.JBoolean{_}: other_new(writeKey,readKey,value,different)
    case P.JNumber{_,_,_}: other_new(writeKey,readKey,value,different)
    case P.JText{_}: other_new(writeKey,readKey,value,different)
    case P.JDecimal{_,_,_,_}: other_new(writeKey,readKey,value,different)
    case P.JRatio{_,_}: other_new(writeKey,readKey,value,different)
    case P.JSequence{_}: other_new(writeKey,readKey,value,different)


def recording_gold(+profile: P.Value,+frame: P.Value,+catalog: P.Value) -> {P.get(P.get(P.recording(profile,frame,catalog),"profile"),"gold") == P.add(P.get(profile,"gold"),P.whole(P.get(frame,"gold"))) : P.Value}:
  %Equal.sym(P.Value,P.get(P.set(P.run_payment(profile,frame,catalog),"recorded",P.JSequence{P.recent(List.append(&2,P.Value,P.sequence(P.get(profile,"recorded")),[P.record_signature(frame)]))}),"gold"),P.get(P.run_payment(profile,frame,catalog),"gold"),Laws.object_other_field_preserved(P.run_payment(profile,frame,catalog),"recorded","gold",P.JSequence{P.recent(List.append(&2,P.Value,P.sequence(P.get(profile,"recorded")),[P.record_signature(frame)]))},{==})) : {_ == P.add(P.get(profile,"gold"),P.whole(P.get(frame,"gold"))) : P.Value}
  Laws.object_field_roundtrip(P.run_awards(profile,frame,catalog),"gold",P.add(P.get(profile,"gold"),P.whole(P.get(frame,"gold"))))

def record_gold_branch(seen: Bool,+profile: P.Value,+frame: P.Value,+catalog: P.Value) -> {P.get(P.get(P.pick(seen,P.JObject{["profile","added"],[profile,P.JSequence{[]}]},P.recording(profile,frame,catalog)),"profile"),"gold") == P.pick(seen,P.get(profile,"gold"),P.add(P.get(profile,"gold"),P.whole(P.get(frame,"gold")))) : P.Value}:
  match seen:
    case True{}: {==}
    case False{}: recording_gold(profile,frame,catalog)

def Laws.public_record_gold_exact(profile,frame,catalog):
  record_gold_branch(P.contains(P.sequence(P.get(profile,"recorded")),P.record_signature(frame)),profile,frame,catalog)
