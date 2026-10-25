import Base

# Convert the word index once; recursive traversal only inspects Nat.
def at_nat(values: List<&2,U32>,index: Nat) -> U32:
  match values index:
    case Nil{} _: 0
    case Con{head,_} 0n: head
    case Con{_,tail} 1n+rest: at_nat(tail,rest)

def at(values: List<&2,U32>,index: U32) -> U32:
  at_nat(values,U32.to_nat(index))
