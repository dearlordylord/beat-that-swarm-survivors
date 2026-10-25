import Base
import ./coop-protocol.bend as P
import ./coop-session.bend as S

# Guarantees: the public decoder refuses every envelope longer than its declared bound before parsing it.
# Why it matters: received network text cannot force unbounded command parsing work.
law oversized_refused:
  for +text: String
  for oversized: {False{} == Nat.is_le(String.length(text),160n) : Bool}
  {P.decode(text) == None{} : Maybe<&2,S.Command>}

# Guarantees: a parsed numeric field is accepted precisely when it fits U32 and its decimal spelling is canonical.
# Why it matters: peers cannot submit alternate numeric spellings or wrap an out of range identifier.
law parsed_number_exact:
  for +n: Nat
  for +digits: String
  {P.canonical_number(Some{n},digits) == Bool.pick(Maybe<&2,U32>,Bool.and(Nat.is_le(n,4294967295n),String.eq(Nat.show(n),digits)),Some{U32.from_nat(n)},None{}) : Maybe<&2,U32>}

# Guarantees: failed numeric parsing always refuses the field, regardless of its text.
# Why it matters: malformed fields cannot become a default session or player identifier.
law malformed_number_refused:
  for digits: String
  {P.canonical_number(None{},digits) == None{} : Maybe<&2,U32>}
