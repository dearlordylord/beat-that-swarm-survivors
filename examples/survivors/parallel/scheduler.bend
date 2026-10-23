import Base

# Detached plans identify independent jobs; no World owners are shared here.
type Plan is Data:
  Empty{}
  Job{index:U32}
  Split{left:Plan,right:Plan}
type Results<T:Data> is Data:
  NoResults{}
  Value{value:T}
  Both{left:Results<T>,right:Results<T>}

def serial_plan(left:Nat,+index:U32,+stride:U32) -> Plan:
  match left:
    case 0n: Empty{}
    case 1n+rest: Split{Job{index},serial_plan(rest,(index + stride : U32),stride)}
def build_fuel(fuel:Nat,+count:U32,+index:U32,+stride:U32) -> Plan:
  match fuel count:
    case _ 0: Empty{}
    case _ 1: Job{index}
    case 0n _: serial_plan(U32.to_nat(count),index,stride)
    case 1n+ +rest _:
      +half=(count / 2 : U32)
      Split{build_fuel(rest,half,index,stride),build_fuel(rest,(count - half : U32),(index + half * stride : U32),stride)}
# For admitted counts<=10000,14 splits reach singleton leaves. The fallback
# retains every job even when this helper is called outside the admitted bound.
def build(count:U32,index:U32,stride:U32) -> Plan: build_fuel(14n,count,index,stride)

def map_serial(~Context:Data,~T:Data,~job:Context -> U32 -> T,+context:Context,plan:Plan) -> Results<T>:
  match plan:
    case Empty{}: NoResults{}
    case Job{index}: Value{job(context,index)}
    case Split{left,right}: Both{map_serial(~Context,~T,~job,context,left),map_serial(~Context,~T,~job,context,right)}
def map_parallel(~Context:Data,~T:Data,~job:Context -> U32 -> T,+context:Context,plan:Plan) -> Results<T>:
  match plan:
    case Empty{}: NoResults{}
    case Job{index}: Value{job(context,index)}
    case Split{left,right}:
      l r = map_parallel(~Context,~T,~job,context,left) map_parallel(~Context,~T,~job,context,right)
      Both{l,r}
def to_list(~T:Data,tree:Results<T>) -> List<&2,T>:
  match tree:
    case NoResults{}: []
    case Value{value}: [value]
    case Both{left,right}: List.append(&2,T,to_list(~T,left),to_list(~T,right))
