import Base
import ../projectile-pool.bend as P
import ../body-index.bend as BI

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
  for +slot:U32
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

# Guarantees: owner 24 is outside the 24-weapon catalog and is always refused.
# Why it matters: the invalid-owner sentinel cannot emit a projectile.
law invalid_owner_is_refused:
  for +counts:List<&2,U32>
  for +caps:List<&2,U32>
  {P.allowed(24,counts,caps) == False{} : Bool}
