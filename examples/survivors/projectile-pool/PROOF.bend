import Base
import ../projectile-pool.bend as P
import ../body-index.bend as BI
import LAWS.bend as Laws
import ../body-index/SPEC.bend as IS
import ../body-index/PROOF.bend as IP
import ../proof-facts.bend as F

def Laws.rejected_request_preserves_state(request,state): {==}
def Laws.accepted_request_consumes_free_head(owner,slot,level,emission,seed,rest,counts,caps,index,count): {==}
def saturated_assign(accepted:Bool,+request:P.Request,+counts:List<&2,U32>,+caps:List<&2,U32>,+index:BI.Index<P.Request>,+count:U32) -> {P.assign(accepted,request,P.Pending{[],counts,caps,index,count}) == P.Pending{[],counts,caps,index,count} : P.Pending}:
  match accepted request:
    case True{} P.Request{_,_,_,_}: {==}
    case False{} _: {==}
def saturated_step(+request:P.Request,+counts:List<&2,U32>,+caps:List<&2,U32>,+index:BI.Index<P.Request>,+count:U32) -> {P.step(request,P.Pending{[],counts,caps,index,count}) == P.Pending{[],counts,caps,index,count} : P.Pending}:
  match request:
    case P.Request{+owner,+slot,+level,+emission}: saturated_assign(P.allowed(owner,counts,caps),P.Request{owner,slot,level,emission},counts,caps,index,count)
def Laws.saturated_plan_is_preserved(requests,counts,caps,index,count):
  match requests:
    case []: {==}
    case +request <> rest:
      Equal.trans(P.Plan,P.allocate_go(rest,P.step(request,P.Pending{[],counts,caps,index,count})),P.allocate_go(rest,P.Pending{[],counts,caps,index,count}),P.Plan{index,count},Equal.cong(P.Pending,P.Plan,state => P.allocate_go(rest,state),P.step(request,P.Pending{[],counts,caps,index,count}),P.Pending{[],counts,caps,index,count},saturated_step(request,counts,caps,index,count)),Laws.saturated_plan_is_preserved(rest,counts,caps,index,count))
def admission_exact(inCatalogue:Bool,underCap:Bool) -> {Bool.and(inCatalogue,underCap) == Laws.admission(inCatalogue,underCap) : Bool}:
  match inCatalogue underCap:
    case True{} True{}: {==}
    case True{} False{}: {==}
    case False{} _: {==}
def Laws.exact_admission(owner,counts,caps):
  admission_exact(U32.is_lt(owner,24),U32.is_lt(P.at(counts,owner),P.at(caps,owner)))
def Laws.public_admission(owner,slot,level,emission,seed,rest,counts,caps,index,count,inCatalogue,belowCap):
  %inCatalogue : {P.assign(Bool.and(_,U32.is_lt(P.at(counts,owner),P.at(caps,owner))),P.Request{owner,slot,level,emission},P.Pending{seed <> rest,counts,caps,index,count}) == P.Pending{rest,P.bump(counts,owner),caps,BI.insert(~P.Request,index,seed,P.Request{owner,slot,level,emission}),(count + 1 : U32)} : P.Pending}
  %belowCap : {P.assign(Bool.and(True{},_),P.Request{owner,slot,level,emission},P.Pending{seed <> rest,counts,caps,index,count}) == P.Pending{rest,P.bump(counts,owner),caps,BI.insert(~P.Request,index,seed,P.Request{owner,slot,level,emission}),(count + 1 : U32)} : P.Pending}
  {==}
def Laws.invalid_owner_is_refused(owner,slot,level,emission,free,counts,caps,index,count,invalid):
  %invalid : {P.assign(Bool.and(_,U32.is_lt(P.at(counts,owner),P.at(caps,owner))),P.Request{owner,slot,level,emission},P.Pending{free,counts,caps,index,count}) == P.Pending{free,counts,caps,index,count} : P.Pending}
  {==}
def assign_exact(admitted:Bool,+request:P.Request,+state:P.Pending) -> {P.assign(admitted,request,state) == Laws.specified_assign(admitted,request,state) : P.Pending}:
  match admitted request state:
    case True{} P.Request{_,_,_,_} P.Pending{[],_,_,_,_}: {==}
    case True{} P.Request{_,_,_,_} P.Pending{_ <> _,_,_,_,_}: {==}
    case False{} _ _: {==}
def step_exact(+request:P.Request,+state:P.Pending) -> {P.step(request,state) == Laws.specified_step(request,state) : P.Pending}:
  match request state:
    case P.Request{+owner,+slot,+level,+emission} P.Pending{+free,+counts,+caps,+index,+count}:
      Equal.trans(P.Pending,P.assign(P.allowed(owner,counts,caps),P.Request{owner,slot,level,emission},P.Pending{free,counts,caps,index,count}),P.assign(Laws.specified_allowed(owner,counts,caps),P.Request{owner,slot,level,emission},P.Pending{free,counts,caps,index,count}),Laws.specified_assign(Laws.specified_allowed(owner,counts,caps),P.Request{owner,slot,level,emission},P.Pending{free,counts,caps,index,count}),Equal.cong(Bool,P.Pending,admitted => P.assign(admitted,P.Request{owner,slot,level,emission},P.Pending{free,counts,caps,index,count}),P.allowed(owner,counts,caps),Laws.specified_allowed(owner,counts,caps),Laws.exact_admission(owner,counts,caps)),assign_exact(Laws.specified_allowed(owner,counts,caps),P.Request{owner,slot,level,emission},P.Pending{free,counts,caps,index,count}))

def plan_exact(+requests:List<&2,P.Request>,+state:P.Pending) -> {P.allocate_go(requests,state) == Laws.specified_plan(requests,state) : P.Plan}:
  match requests state:
    case [] P.Pending{_,_,_,_,_}: {==}
    case +request <> +rest state:
      Equal.trans(P.Plan,P.allocate_go(rest,P.step(request,state)),P.allocate_go(rest,Laws.specified_step(request,state)),Laws.specified_plan(rest,Laws.specified_step(request,state)),Equal.cong(P.Pending,P.Plan,next => P.allocate_go(rest,next),P.step(request,state),Laws.specified_step(request,state),step_exact(request,state)),plan_exact(rest,Laws.specified_step(request,state)))
def Laws.complete_ordered_plan(free,counts,caps,requests): plan_exact(requests,P.Pending{free,counts,caps,BI.Empty{},0})

def pending_source(~allowedKey:U32 -> Bool,state:P.Pending) -> Bool:
  match state:
    case P.Pending{free,_,_,index,_}: Bool.and(IS.all_free(~allowedKey,free),IS.all_keys(~P.Request,~allowedKey,index))
def assign_source(~allowedKey:U32 -> Bool,admitted:Bool,+request:P.Request,+state:P.Pending,+source:{True{} == pending_source(~allowedKey,state) : Bool}) -> {True{} == pending_source(~allowedKey,P.assign(admitted,request,state)) : Bool}:
  match admitted request state:
    case False{} _ _: source
    case True{} P.Request{_,_,_,_} P.Pending{[],_,_,_,_}: source
    case True{} P.Request{+owner,+slot,+level,+emission} P.Pending{+seed <> +free,counts,caps,+index,count}:
      F.and_true(IS.all_free(~allowedKey,free),IS.all_keys(~P.Request,~allowedKey,BI.insert(~P.Request,index,seed,P.Request{owner,slot,level,emission})),F.and_right(allowedKey(seed),IS.all_free(~allowedKey,free),F.and_left(IS.all_free(~allowedKey,seed <> free),IS.all_keys(~P.Request,~allowedKey,index),source)),IP.insert_go_source(~P.Request,~allowedKey,32n,index,seed,P.Request{owner,slot,level,emission},BI.outside(~P.Request,index,seed),BI.branch(~P.Request,index,seed),F.and_right(IS.all_free(~allowedKey,seed <> free),IS.all_keys(~P.Request,~allowedKey,index),source),F.and_left(allowedKey(seed),IS.all_free(~allowedKey,free),F.and_left(IS.all_free(~allowedKey,seed <> free),IS.all_keys(~P.Request,~allowedKey,index),source))))
def step_source(~allowedKey:U32 -> Bool,+request:P.Request,+state:P.Pending,source:{True{} == pending_source(~allowedKey,state) : Bool}) -> {True{} == pending_source(~allowedKey,P.step(request,state)) : Bool}:
  match request state:
    case P.Request{+owner,+slot,+level,+emission} P.Pending{+free,+counts,+caps,+index,+count}:
      assign_source(~allowedKey,P.allowed(owner,counts,caps),P.Request{owner,slot,level,emission},P.Pending{free,counts,caps,index,count},source)
def plan_source(~allowedKey:U32 -> Bool,requests:List<&2,P.Request>,+state:P.Pending,source:{True{} == pending_source(~allowedKey,state) : Bool}) -> {True{} == Laws.plan_keys(~allowedKey,P.allocate_go(requests,state)) : Bool}:
  match requests state:
    case [] P.Pending{free,_,_,index,_}: F.and_right(IS.all_free(~allowedKey,free),IS.all_keys(~P.Request,~allowedKey,index),source)
    case +request <> rest state: plan_source(~allowedKey,rest,P.step(request,state),step_source(~allowedKey,request,state,source))
def Laws.whole_plan_uses_only_free_source(allowedKey,free,counts,caps,requests,source):
  plan_source(~allowedKey,requests,P.Pending{free,counts,caps,BI.Empty{},0},F.and_true(IS.all_free(~allowedKey,free),True{},source,{==}))

def bumped_count_go(+rows:List<&2,U32>,+index:U32,+atHead:Bool,present:{True{} == Laws.has_count_go(rows,index,atHead) : Bool}) -> {P.at_go(P.bump_go(rows,index,atHead),index,atHead) == (P.at_go(rows,index,atHead) + 1 : U32) : U32}:
  match rows atHead:
    case [] True{}: Equal.cong(Bool,U32,b => Bool.pick(U32,b,0,1),True{},False{},present)
    case [] False{}: Equal.cong(Bool,U32,b => Bool.pick(U32,b,0,1),True{},False{},present)
    case _ <> _ True{}: {==}
    case _ <> rest False{}: bumped_count_go(rest,(index - 1 : U32),U32.is_eq((index - 1 : U32),0),present)
def Laws.bump_updates_owner_count(rows,owner,present): bumped_count_go(rows,owner,U32.is_eq(owner,0),present)

def bumped_length_go(+rows:List<&2,U32>,+index:U32,+atHead:Bool) -> {List.length(&2,U32,P.bump_go(rows,index,atHead)) == List.length(&2,U32,rows) : Nat}:
  match rows atHead:
    case [] True{}: {==}
    case [] False{}: {==}
    case _ <> _ True{}: {==}
    case _ <> +rest False{}: Equal.cong(Nat,Nat,n => 1n+n,List.length(&2,U32,P.bump_go(rest,(index - 1 : U32),U32.is_eq((index - 1 : U32),0))),List.length(&2,U32,rest),bumped_length_go(rest,(index - 1 : U32),U32.is_eq((index - 1 : U32),0)))
def Laws.bump_preserves_table_length(rows,owner): bumped_length_go(rows,owner,U32.is_eq(owner,0))
def bumped_others_go(+rows:List<&2,U32>,+index:U32,+atHead:Bool) -> {Laws.other_counts_go(P.bump_go(rows,index,atHead),index,atHead) == Laws.other_counts_go(rows,index,atHead) : List<&2,U32>}:
  match rows atHead:
    case [] True{}: {==}
    case [] False{}: {==}
    case _ <> _ True{}: {==}
    case +head <> +rest False{}:
      Equal.cong(List<&2,U32>,List<&2,U32>,xs => head <> xs,Laws.other_counts_go(P.bump_go(rest,(index - 1 : U32),U32.is_eq((index - 1 : U32),0)),(index - 1 : U32),U32.is_eq((index - 1 : U32),0)),Laws.other_counts_go(rest,(index - 1 : U32),U32.is_eq((index - 1 : U32),0)),bumped_others_go(rest,(index - 1 : U32),U32.is_eq((index - 1 : U32),0)))
def Laws.bump_preserves_other_owners(rows,owner): bumped_others_go(rows,owner,U32.is_eq(owner,0))
