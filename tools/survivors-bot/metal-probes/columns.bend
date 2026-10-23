import Base
import bendvy-ecs-core@0.1.0.1/column.bend as Col
import common.bend as C

type Schema is Data:Schema{}
type Cell is Type:Cell{value:U32}
def project(cell:Cell) -> Cell & U32:
  match cell:
    case Cell{+value}:(Cell{value},value)
def failed() -> C.Answer:C.Answer{0,False{}}
def finish(+expected:U32,+sum:U32,result:Col.Column<Schema,Cell> & Maybe<&2,U32>) -> C.Answer:
  match result:
    case (_,Some{value}):C.Answer{sum,U32.is_eq(value,expected)}
    case (_,None{}):failed()
type Step is Type:
  Continue{column:Col.Column<Schema,Cell>,expected:U32,sum:U32}
  Invalid{}
def validated(valid:Bool,column:Col.Column<Schema,Cell>,expected:U32,sum:U32,observed:U32) -> Step:
  match valid:
    case False{}:Invalid{}
    case True{}:Continue{column,(expected + 1 : U32),(sum + observed + 1 : U32)}
def swapped(+expected:U32,+sum:U32,+observed:U32,result:Col.SwapOutcome<Schema,Cell>) -> Step:
  match result:
    case Col.Accepted{column,Some{Cell{old}}}:validated(U32.is_eq(old,expected) && U32.is_eq(observed,expected),column,expected,sum,observed)
    case _:Invalid{}
def read_step(+expected:U32,+sum:U32,result:Col.Column<Schema,Cell> & Maybe<&2,U32>) -> Step:
  match result:
    case (column,Some{+observed}):swapped(expected,sum,observed,Col.swap(~Schema,~Cell,column,1,Some{Cell{(expected + 1 : U32)}}))
    case _:Invalid{}
def loop(left:Nat,state:Step) -> C.Answer:
  match left state:
    case _ Invalid{}:failed()
    case 0n Continue{column,+expected,+sum}:finish(expected,sum,Col.view(~Schema,~Cell,~U32,~project,column,1))
    case 1n+rest Continue{column,+expected,+sum}:loop(rest,read_step(expected,sum,Col.view(~Schema,~Cell,~U32,~project,column,1)))
def initialized(+iterations:U32,+initial:U32,result:Col.SwapOutcome<Schema,Cell>) -> C.Answer:
  match result:
    case Col.Accepted{column,None{}}:loop(U32.to_nat(iterations),Continue{column,initial,0})
    case _:failed()
def job(iterations:U32,+seed:U32,+index:U32) -> C.Answer:
  initialized(iterations,(seed + index : U32),Col.swap(~Schema,~Cell,Col.ensure(~Schema,~Cell,Col.empty_indexed(~Schema,~Cell),1),1,Some{Cell{(seed + index : U32)}}))
def tree(depth:Nat,+iterations:U32,+seed:U32,+index:U32,+stride:U32) -> C.Answer:
  match depth:
    case 0n:job(iterations,seed,index)
    case 1n+ +rest:
      l r = tree(rest,iterations,seed,index,(stride * 2 : U32)) tree(rest,iterations,seed,(index + stride : U32),(stride * 2 : U32))
      C.join(l,r)
def solve(iterations:U32,seed:U32) -> C.Answer:tree(3n,iterations,seed,0,1)
def run(+iterations:U32,seed:U32) -> IO(Unit):C.report("columns",iterations,solve!(iterations,seed))
def main() -> IO(Unit):
  do IO<Unit>:
    n:Result<&1,&1,U32 & String,String> <- IO.get_env("METAL_PROBE_ITERATIONS")
    seed:Result<&1,&1,U32 & String,String> <- IO.get_env("METAL_PROBE_SEED")
    run(U32.min(4096,C.parsed(C.text(n),128)),C.parsed(C.text(seed),100))
