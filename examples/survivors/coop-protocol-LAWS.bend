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

# Guarantees: numbered input ticks have a distinct tag carrying their reward epoch and both axes.
# Why it matters: the host must not interpret one fixed tick as an indefinitely held direction.
law tick_encoding_exact:
  for +round: U32
  for +x: U32
  for +y: U32
  {P.encode_action(S.MovementTick{round,x,y}) == "T|" ++ U32.show(round) ++ "|" ++ U32.show(x) ++ "|" ++ U32.show(y) : String}

def tick_fields(session: String,player: String,seq: String,tick: String,round: String,x: String,y: String) -> Maybe<&2,S.Command>:
  do Maybe<&2,S.Command>:
    a : U32 <- P.number(session)
    b : U32 <- P.number(player)
    c : U32 <- P.number(seq)
    d : U32 <- P.number(tick)
    e : U32 <- P.number(round)
    f : U32 <- P.number(x)
    g : U32 <- P.number(y)
    return S.Command{a,b,c,d,S.MovementTick{e,f,g}}

# Guarantees: the T packet decodes all seven canonical numbers into exactly one movement tick command, or refuses a malformed field.
# Why it matters: transmitted tick identity and reward epoch must survive parsing without becoming held movement.
law tick_fields_exact:
  for +session: String
  for +player: String
  for +seq: String
  for +tick: String
  for +round: String
  for +x: String
  for +y: String
  {P.parse_fields(["BSC1",session,player,seq,tick,"T",round,x,y]) == tick_fields(session,player,seq,tick,round,x,y) : Maybe<&2,S.Command>}
