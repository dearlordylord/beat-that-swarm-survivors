# Small canonical ASCII commands. World observations use a distinct bounded envelope.
import Base
import ./coop-session.bend as S

# Bounded recursion over characters, preserving empty fields for strict refusal.
def fields(text: String,acc: String) -> List<String>:
  match text:
    case SNil{}: [String.reverse(acc)]
    case SCon{'|',rest}: String.reverse(acc) <> fields(rest,"")
    case SCon{ch,rest}: fields(rest,SCon{ch,acc})
def canonical_number(value: Maybe<&2,Nat>,digits: String) -> Maybe<&2,U32>:
  match value:
    case None{}: None{}
    case Some{+n}: Bool.pick(Maybe<&2,U32>,Bool.and(Nat.is_le(n,4294967295n),String.eq(Nat.show(n),digits)),Some{U32.from_nat(n)},None{})
def number(+digits: String) -> Maybe<&2,U32>: canonical_number(Nat.read(digits),digits)
def parse_fields(rows: List<String>) -> Maybe<&2,S.Command>:
  match rows:
    case ["BSC1",session,player,seq,tick,"I",x,y]:
      do Maybe<&2,S.Command>:
        a : U32 <- number(session)
        b : U32 <- number(player)
        c : U32 <- number(seq)
        d : U32 <- number(tick)
        e : U32 <- number(x)
        f : U32 <- number(y)
        return S.Command{a,b,c,d,S.Movement{e,f}}
    case ["BSC1",session,player,seq,tick,"T",round,x,y]:
      do Maybe<&2,S.Command>:
        a : U32 <- number(session)
        b : U32 <- number(player)
        c : U32 <- number(seq)
        d : U32 <- number(tick)
        e : U32 <- number(round)
        f : U32 <- number(x)
        g : U32 <- number(y)
        return S.Command{a,b,c,d,S.MovementTick{e,f,g}}
    case ["BSC1",session,player,seq,tick,"C",round,index]:
      do Maybe<&2,S.Command>:
        a : U32 <- number(session)
        b : U32 <- number(player)
        c : U32 <- number(seq)
        d : U32 <- number(tick)
        e : U32 <- number(round)
        f : U32 <- number(index)
        return S.Command{a,b,c,d,S.Choice{e,f}}
    case ["BSC1",session,player,seq,tick,"S",character,arcana,meta,weapons]:
      do Maybe<&2,S.Command>:
        a : U32 <- number(session)
        b : U32 <- number(player)
        c : U32 <- number(seq)
        d : U32 <- number(tick)
        e : U32 <- number(character)
        f : U32 <- number(arcana)
        g : U32 <- number(meta)
        h : U32 <- number(weapons)
        return S.Command{a,b,c,d,S.Setup{e,f,g,h}}
    case _: None{}
def decode_bounded(allowed: Bool,text: String) -> Maybe<&2,S.Command>:
  match allowed:
    case False{}: None{}
    case True{}: parse_fields(fields(text,""))
def decode(+text: String) -> Maybe<&2,S.Command>: decode_bounded(Nat.is_le(String.length(text),160n),text)
def encode_action(action: S.Action) -> String:
  match action:
    case S.Movement{x,y}: "I|" ++ U32.show(x) ++ "|" ++ U32.show(y)
    case S.MovementTick{round,x,y}: "T|" ++ U32.show(round) ++ "|" ++ U32.show(x) ++ "|" ++ U32.show(y)
    case S.Choice{round,index}: "C|" ++ U32.show(round) ++ "|" ++ U32.show(index)
    case S.Setup{character,arcana,meta,weapons}: "S|" ++ U32.show(character) ++ "|" ++ U32.show(arcana) ++ "|" ++ U32.show(meta) ++ "|" ++ U32.show(weapons)
def encode(command: S.Command) -> String:
  match command:
    case S.Command{session,player,seq,tick,action}: "BSC1|" ++ U32.show(session) ++ "|" ++ U32.show(player) ++ "|" ++ U32.show(seq) ++ "|" ++ U32.show(tick) ++ "|" ++ encode_action(action)
