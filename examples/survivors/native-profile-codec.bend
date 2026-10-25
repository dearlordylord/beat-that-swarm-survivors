import Base
import native-economy.bend as P

def encode_values(values: List<&2,U32>) -> String:
  match values:
    case Nil{}: ""
    case Con{value,rest}: U32.show(value) ++ "\n" ++ encode_values(rest)
def encode(profile: P.Profile) -> String:
  match profile:
    case P.Profile{values,seed,settled}: "NIGHTFALL1\n" ++ encode_values(List.append(&2,U32,values,seed <> Bool.to_u32(settled) <> List.replicate(U32,29n,0)))
def read_number(text: String) -> U32: P.number_result(U32.read(text))
def decode_values(n: Nat,rows: List<&2,String>) -> List<&2,U32>:
  match n rows:
    case 0n _: []
    case 1n+p Nil{}: 0 <> decode_values(p,[])
    case 1n+p Con{head,tail}: read_number(head) <> decode_values(p,tail)
def decoded_values(+values: List<&2,U32>) -> P.Profile:
  P.Profile{List.take(&2,U32,values,33n),P.number_result(List.get(&2,U32,values,33n)),U32.is_eq(P.number_result(List.get(&2,U32,values,34n)),1)}
def decode_lines(rows: List<&2,String>) -> P.Profile:
  match rows:
    case Nil{}: P.fresh()
    case Con{head,tail}:
      P.choose(String.eq(head,"NIGHTFALL1"),decoded_values(decode_values(64n,tail)),P.fresh())
def valid_number(result: Maybe<&2,U32>) -> Bool:
  match result:
    case None{}: False{}
    case Some{_}: True{}
def valid_rows(n: Nat,rows: List<&2,String>) -> Bool:
  match n rows:
    case 0n Nil{}: True{}
    case 0n Con{head,Nil{}}: String.eq(head,"")
    case 0n _: False{}
    case 1n+p Nil{}: False{}
    case 1n+p Con{head,tail}: Bool.and(valid_number(U32.read(head)),valid_rows(p,tail))
def valid_save(rows: List<&2,String>) -> Bool:
  match rows:
    case Nil{}: False{}
    case Con{head,tail}: Bool.and(String.eq(head,"NIGHTFALL1"),valid_rows(64n,tail))
def normalize_ranks(n: Nat,+id: U32,+profile: P.Profile) -> P.Profile:
  match n:
    case 0n: profile
    case 1n+p: normalize_ranks(p,(id + 1 : U32),P.put(profile,(id + 1 : U32),P.rank(profile,id)))
def normalize(+profile: P.Profile) -> P.Profile:
  +p0 = P.put(profile,11,U32.or(1,U32.and(P.get(profile,11),255)))
  +p1 = P.put(p0,12,U32.or(1,U32.and(P.get(p0,12),31)))
  normalize_ranks(10n,0,p1)
def decode_rows(+rows: List<&2,String>) -> P.Profile:
  P.choose(valid_save(rows),normalize(decode_lines(rows)),P.fresh())
def decode(text: String) -> P.Profile: decode_rows(String.lines(text))

