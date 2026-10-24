import Base
import ../projectile-pool.bend as P
import ../body-index.bend as BI
import LAWS.bend as Laws

def Laws.rejected_request_preserves_state(request,state): {==}
def Laws.accepted_request_consumes_free_head(owner,slot,level,seed,rest,counts,caps,index,count): {==}
def saturated_assign(accepted:Bool,+request:P.Request,+counts:List<&2,U32>,+caps:List<&2,U32>,+index:BI.Index<P.Request>,+count:U32) -> {P.assign(accepted,request,P.Pending{[],counts,caps,index,count}) == P.Pending{[],counts,caps,index,count} : P.Pending}:
  match accepted request:
    case True{} P.Request{_,_,_}: {==}
    case False{} _: {==}
def saturated_step(+request:P.Request,+counts:List<&2,U32>,+caps:List<&2,U32>,+index:BI.Index<P.Request>,+count:U32) -> {P.step(request,P.Pending{[],counts,caps,index,count}) == P.Pending{[],counts,caps,index,count} : P.Pending}:
  match request:
    case P.Request{+owner,+slot,+level}: saturated_assign(P.allowed(owner,counts,caps),P.Request{owner,slot,level},counts,caps,index,count)
def Laws.saturated_plan_is_preserved(requests,counts,caps,index,count):
  match requests:
    case []: {==}
    case +request <> rest:
      Equal.trans(P.Plan,P.allocate_go(rest,P.step(request,P.Pending{[],counts,caps,index,count})),P.allocate_go(rest,P.Pending{[],counts,caps,index,count}),P.Plan{index,count},Equal.cong(P.Pending,P.Plan,state => P.allocate_go(rest,state),P.step(request,P.Pending{[],counts,caps,index,count}),P.Pending{[],counts,caps,index,count},saturated_step(request,counts,caps,index,count)),Laws.saturated_plan_is_preserved(rest,counts,caps,index,count))
def Laws.invalid_owner_is_refused(counts,caps): {==}
