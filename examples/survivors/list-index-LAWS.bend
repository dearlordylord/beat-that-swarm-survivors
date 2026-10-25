import Base
import ./list-index.bend as I

# Guarantees: an empty list returns zero at every natural index.
# Why it matters: absent player upgrade slots keep the existing zero fallback.
law empty:
  for +index: Nat
  {I.at_nat([],index) == 0 : U32}

# Guarantees: index zero returns the first stored value.
# Why it matters: the first upgrade slot retains its exact U32 payload.
law first:
  for +head: U32
  for tail: List<&2,U32>
  {I.at_nat(head <> tail,0n) == head : U32}

# Guarantees: a positive index drops exactly one list cell and decrements once.
# Why it matters: later upgrade slots retain their ordering and absent slots reach the empty fallback.
law next:
  for head: U32
  for +tail: List<&2,U32>
  for +index: Nat
  {I.at_nat(head <> tail,1n+index) == I.at_nat(tail,index) : U32}

# Guarantees: the public U32 entry converts its index once before traversal.
# Why it matters: callers retain the word-index API while traversal uses natural-number recursion.
law entry:
  for +values: List<&2,U32>
  for +index: U32
  {I.at(values,index) == I.at_nat(values,U32.to_nat(index)) : U32}
