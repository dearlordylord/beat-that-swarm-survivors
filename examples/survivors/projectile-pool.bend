import Base
import body-index.bend as BI

# Logical emission metadata is independent of the physical projectile identity.
type Request is Data: Request{owner:U32,slot:U32,level:U32}
type Plan is Data: Plan{assignments:BI.Index<Request>,count:U32}
type Pending is Data:
  Pending{free:List<&2,U32>,counts:List<&2,U32>,caps:List<&2,U32>,assignments:BI.Index<Request>,count:U32}
def at(rows:List<&2,U32>,index:U32) -> U32:
  match rows index:
    case [] _: 0
    case head <> _ 0: head
    case _ <> rest index: at(rest,(index - 1 : U32))
def bump(rows:List<&2,U32>,index:U32) -> List<&2,U32>:
  match rows index:
    case [] _: []
    case head <> rest 0: (head + 1 : U32) <> rest
    case head <> rest index: head <> bump(rest,(index - 1 : U32))
def allowed(+owner:U32,counts:List<&2,U32>,caps:List<&2,U32>) -> Bool:
  Bool.and(U32.is_lt(owner,24),U32.is_lt(at(counts,owner),at(caps,owner)))
def assign(accepted:Bool,+request:Request,state:Pending) -> Pending:
  match accepted request state:
    case True{} Request{+owner,+slot,+level} Pending{seed <> free,counts,caps,index,count}:
      Pending{free,bump(counts,owner),caps,BI.insert(~Request,index,seed,Request{owner,slot,level}),(count + 1 : U32)}
    case _ _ state: state
def step(+request:Request,state:Pending) -> Pending:
  match request state:
    case Request{+owner,+slot,+level} Pending{+free,+counts,+caps,index,count}:
      assign(allowed(owner,counts,caps),Request{owner,slot,level},Pending{free,counts,caps,index,count})
def finish(state:Pending) -> Plan:
  match state:
    case Pending{_,_,_,index,count}: Plan{index,count}
def allocate_go(requests:List<&2,Request>,state:Pending) -> Plan:
  match requests:
    case []: finish(state)
    case request <> rest: allocate_go(rest,step(request,state))
# Premises for production callers: free identities are unique and actually free;
# counts/caps contain one entry per owner (24), with counts from the same frame.
# A rejected request is dropped without consuming a free identity. No backlog.
def allocate(freeSeeds:List<&2,U32>,liveCounts:List<&2,U32>,caps:List<&2,U32>,requests:List<&2,Request>) -> Plan:
  allocate_go(requests,Pending{freeSeeds,liveCounts,caps,BI.Empty{},0})
def lookup(plan:Plan,seed:U32) -> Maybe<&2,Request>:
  match plan:
    case Plan{index,_}: BI.find(~Request,index,seed)
