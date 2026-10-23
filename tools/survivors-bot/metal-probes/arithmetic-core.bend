import Base
import common.bend as C

def accumulate(left:Nat,+value:U32,sum:U32) -> U32:
  match left:
    case 0n:sum
    case 1n+rest:accumulate(rest,(value + 1 : U32),(sum + value + 1 : U32))
def job(iterations:U32,seed:U32,index:U32) -> C.Answer:C.Answer{accumulate(U32.to_nat(iterations),(seed + index : U32),0),True{}}
def tree(depth:Nat,+iterations:U32,+seed:U32,+index:U32,+stride:U32) -> C.Answer:
  match depth:
    case 0n:job(iterations,seed,index)
    case 1n+ +rest:
      l r = tree(rest,iterations,seed,index,(stride * 2 : U32)) tree(rest,iterations,seed,(index + stride : U32),(stride * 2 : U32))
      C.join(l,r)
def solve(iterations:U32,seed:U32) -> C.Answer:tree(3n,iterations,seed,0,1)
