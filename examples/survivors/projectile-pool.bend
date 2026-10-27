import starter-mechanics.bend as SM
import Base
import body-index.bend as BI

# Logical emission metadata is independent of the physical projectile identity.
type Emission is Data: Emission{sourcePlayer:U32,logicalSlot:U32}
def emission_player(value: Emission) -> U32:
  match value:
    case Emission{player,_}: player
def emission_slot(value: Emission) -> U32:
  match value:
    case Emission{_,slot}: slot
type Request is Data: Request{weaponOwner:U32,slot:Emission,level:U32,emission:SM.Emission}
type Plan is Data: Plan{assignments:BI.Index<Request>,count:U32}
type Pending is Data:
  Pending{free:List<&2,U32>,counts:List<&2,U32>,caps:List<&2,U32>,assignments:BI.Index<Request>,count:U32}
def at_go(rows:List<&2,U32>,+index:U32,atHead:Bool) -> U32:
  match rows atHead:
    case [] _: 0
    case head <> _ True{}: head
    case _ <> rest False{}: at_go(rest,(index - 1 : U32),U32.is_eq((index - 1 : U32),0))
def at(rows:List<&2,U32>,+index:U32) -> U32:
  at_go(rows,index,U32.is_eq(index,0))
def bump_go(rows:List<&2,U32>,+index:U32,atHead:Bool) -> List<&2,U32>:
  match rows atHead:
    case [] _: []
    case head <> rest True{}: (head + 1 : U32) <> rest
    case head <> rest False{}: head <> bump_go(rest,(index - 1 : U32),U32.is_eq((index - 1 : U32),0))
def bump(rows:List<&2,U32>,+index:U32) -> List<&2,U32>:
  bump_go(rows,index,U32.is_eq(index,0))
def allowed(+owner:U32,counts:List<&2,U32>,caps:List<&2,U32>) -> Bool:
  Bool.and(U32.is_lt(owner,24),U32.is_lt(at(counts,owner),at(caps,owner)))
def assign(accepted:Bool,+request:Request,state:Pending) -> Pending:
  match accepted request state:
    case True{} Request{+owner,+slot,+level,+emission} Pending{seed <> free,counts,caps,index,count}:
      Pending{free,bump(counts,owner),caps,BI.insert(~Request,index,seed,Request{owner,slot,level,emission}),(count + 1 : U32)}
    case _ _ state: state
def step(+request:Request,state:Pending) -> Pending:
  match request state:
    case Request{+owner,+slot,+level,+emission} Pending{+free,+counts,+caps,index,count}:
      assign(allowed(owner,counts,caps),Request{owner,slot,level,emission},Pending{free,counts,caps,index,count})
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
