import Base
import ../projectile-pool.bend as P
import ../body-index.bend as BI
import ../body-index/SPEC.bend as IS

# Guarantees: a refused emission consumes no free identity, counts or plan data.
# Why it matters: capped owners cannot starve later owners in request order.
law rejected_request_preserves_state:
  for +request:P.Request
  for +state:P.Pending
  {P.assign(False{},request,state) == state : P.Pending}

# Guarantees: an accepted request takes exactly the first supplied free identity,
# records its full logical metadata and increments only its owner's count.
# Why it matters: allocation order is deterministic and never chooses a live ID.
law accepted_request_consumes_free_head:
  for +owner:U32
  for +slot:P.Emission
  for +level:U32
  for +seed:U32
  for +rest:List<&2,U32>
  for +counts:List<&2,U32>
  for +caps:List<&2,U32>
  for +index:BI.Index<P.Request>
  for +count:U32
  {P.assign(True{},P.Request{owner,slot,level},P.Pending{seed <> rest,counts,caps,index,count}) == P.Pending{rest,P.bump(counts,owner),caps,BI.insert(~P.Request,index,seed,P.Request{owner,slot,level}),(count + 1 : U32)} : P.Pending}

# Guarantees: no free identity means no request can modify the assignment plan.
# Why it matters: saturation drops emissions instead of replacing a live shot.
law saturated_plan_is_preserved:
  for +requests:List<&2,P.Request>
  for +counts:List<&2,U32>
  for +caps:List<&2,U32>
  for +index:BI.Index<P.Request>
  for +count:U32
  {P.allocate_go(requests,P.Pending{[],counts,caps,index,count}) == P.Plan{index,count} : P.Plan}

# The specification branches independently on the catalogue bound and capacity.
def admission(inCatalogue:Bool,underCap:Bool) -> Bool:
  match inCatalogue underCap:
    case True{} True{}: True{}
    case _ _: False{}
def specified_allowed(+owner:U32,counts:List<&2,U32>,caps:List<&2,U32>) -> Bool:
  admission(U32.is_lt(owner,24),U32.is_lt(P.at(counts,owner),P.at(caps,owner)))
def specified_assign(admitted:Bool,request:P.Request,state:P.Pending) -> P.Pending:
  match admitted request state:
    case True{} P.Request{+owner,+slot,+level} P.Pending{seed <> rest,counts,caps,index,count}:
      P.Pending{rest,P.bump(counts,owner),caps,BI.insert(~P.Request,index,seed,P.Request{owner,slot,level}),(count + 1 : U32)}
    case _ _ state: state
def specified_step(request:P.Request,state:P.Pending) -> P.Pending:
  match request state:
    case P.Request{+owner,+slot,+level} P.Pending{free,+counts,+caps,index,count}:
      specified_assign(specified_allowed(owner,counts,caps),P.Request{owner,slot,level},P.Pending{free,counts,caps,index,count})
def specified_plan(requests:List<&2,P.Request>,state:P.Pending) -> P.Plan:
  match requests state:
    case [] P.Pending{_,_,_,index,count}: P.Plan{index,count}
    case request <> rest state: specified_plan(rest,specified_step(request,state))

def has_count_go(rows:List<&2,U32>,+index:U32,atHead:Bool) -> Bool:
  match rows atHead:
    case [] _: False{}
    case _ <> _ True{}: True{}
    case _ <> rest False{}: has_count_go(rest,(index - 1 : U32),U32.is_eq((index - 1 : U32),0))
def has_count(rows:List<&2,U32>,+index:U32) -> Bool:
  has_count_go(rows,index,U32.is_eq(index,0))

# Guarantees: incrementing any present owner's table cell increases the value
# read at that same address by exactly one machine count.
# Why it matters: later requests in the same frame must observe each accepted
# projectile against their owner's capacity instead of overfilling its pool.
law bump_updates_owner_count:
  for +rows:List<&2,U32>
  for +owner:U32
  for present:{True{} == has_count(rows,owner) : Bool}
  {P.at(P.bump(rows,owner),owner) == (P.at(rows,owner) + 1 : U32) : U32}

def other_counts_go(rows:List<&2,U32>,+index:U32,atHead:Bool) -> List<&2,U32>:
  match rows atHead:
    case [] _: []
    case _ <> rest True{}: rest
    case head <> rest False{}: head <> other_counts_go(rest,(index - 1 : U32),U32.is_eq((index - 1 : U32),0))
def other_counts(rows:List<&2,U32>,+index:U32) -> List<&2,U32>:
  other_counts_go(rows,index,U32.is_eq(index,0))

# Guarantees: updating an owner's count keeps the table's number of cells.
# Why it matters: count updates cannot shift the catalogue's owner addresses.
law bump_preserves_table_length:
  for +rows:List<&2,U32>
  for +owner:U32
  {List.length(&2,U32,P.bump(rows,owner)) == List.length(&2,U32,rows) : Nat}

# Guarantees: deleting the addressed cell before and after a count update gives
# exactly the same ordered table of every other owner's values.
# Why it matters: firing one weapon cannot charge another weapon's capacity.
law bump_preserves_other_owners:
  for +rows:List<&2,U32>
  for +owner:U32
  {other_counts(P.bump(rows,owner),owner) == other_counts(rows,owner) : List<&2,U32>}

# Guarantees: an owner is admitted exactly when it belongs to the catalogue and
# its current count is below its own cap, including positive admissions.
# Why it matters: replacing the allocator with an all-deny policy stops firing.
law exact_admission:
  for +owner:U32
  for +counts:List<&2,U32>
  for +caps:List<&2,U32>
  {P.allowed(owner,counts,caps) == specified_allowed(owner,counts,caps) : Bool}

# Guarantees: the public step consumes the first free identity for any catalogue
# owner below cap and preserves the complete request metadata.
# Why it matters: a legal shot must reach the pool rather than silently vanish.
law public_admission:
  for +owner:U32
  for +slot:P.Emission
  for +level:U32
  for +seed:U32
  for +rest:List<&2,U32>
  for +counts:List<&2,U32>
  for +caps:List<&2,U32>
  for +index:BI.Index<P.Request>
  for +count:U32
  for inCatalogue:{True{} == U32.is_lt(owner,24) : Bool}
  for belowCap:{True{} == U32.is_lt(P.at(counts,owner),P.at(caps,owner)) : Bool}
  {P.step(P.Request{owner,slot,level},P.Pending{seed <> rest,counts,caps,index,count}) == P.Pending{rest,P.bump(counts,owner),caps,BI.insert(~P.Request,index,seed,P.Request{owner,slot,level}),(count + 1 : U32)} : P.Pending}

# Guarantees: every out-of-catalogue owner is rejected by the public step.
# Why it matters: corrupt metadata cannot consume a physical projectile identity.
law invalid_owner_is_refused:
  for +owner:U32
  for +slot:P.Emission
  for +level:U32
  for +free:List<&2,U32>
  for +counts:List<&2,U32>
  for +caps:List<&2,U32>
  for +index:BI.Index<P.Request>
  for +count:U32
  for invalid:{False{} == U32.is_lt(owner,24) : Bool}
  {P.step(P.Request{owner,slot,level},P.Pending{free,counts,caps,index,count}) == P.Pending{free,counts,caps,index,count} : P.Pending}

# Guarantees: the whole public allocation agrees with the ordered admission
# specification, beginning with an empty plan and the supplied free list/counts.
# Why it matters: batch recursion must neither reorder requests nor skip the
# capacity updates caused by earlier accepted shots.
law complete_ordered_plan:
  for +free:List<&2,U32>
  for +counts:List<&2,U32>
  for +caps:List<&2,U32>
  for +requests:List<&2,P.Request>
  {P.allocate(free,counts,caps,requests) == specified_plan(requests,P.Pending{free,counts,caps,BI.Empty{},0}) : P.Plan}

def plan_keys(~allowedKey:U32 -> Bool,plan:P.Plan) -> Bool:
  match plan:
    case P.Plan{index,_}: IS.all_keys(~P.Request,~allowedKey,index)

# Guarantees: every physical identity in the complete allocation comes from the
# permitted free-key source, provided every supplied free identity is permitted.
# Why it matters: an allocator cannot overwrite a live projectile outside its
# free list, regardless of request count or per-owner cap decisions.
law whole_plan_uses_only_free_source:
  for ~allowedKey:U32 -> Bool
  for +free:List<&2,U32>
  for counts:List<&2,U32>
  for caps:List<&2,U32>
  for requests:List<&2,P.Request>
  for source:{True{} == IS.all_free(~allowedKey,free) : Bool}
  {True{} == plan_keys(~allowedKey,P.allocate(free,counts,caps,requests)) : Bool}
