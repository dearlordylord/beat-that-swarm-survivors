import Base
import ../body-index.bend as I
import LAWS.bend as Laws

def empty_roundtrip(~T: Data,fuel: Nat,+key: U32,+value: T,bit: Bool) -> {I.find_go(~T,fuel,I.insert_go(~T,fuel,I.Empty{},key,value,bit),key,bit) == Some{value} : Maybe<&2,T>}:
  match fuel bit:
    case 0n _: {==}
    case 1n+rest False{}: empty_roundtrip(~T,rest,I.shift(key),value,I.high(I.shift(key)))
    case 1n+rest True{}: empty_roundtrip(~T,rest,I.shift(key),value,I.high(I.shift(key)))
def duplicate_roundtrip(~T: Data,fuel: Nat,+key: U32,+first: T,+second: T,bit: Bool) -> {I.find_go(~T,fuel,I.insert_go(~T,fuel,I.insert_go(~T,fuel,I.Empty{},key,first,bit),key,second,bit),key,bit) == Some{first} : Maybe<&2,T>}:
  match fuel bit:
    case 0n _: {==}
    case 1n+rest False{}: duplicate_roundtrip(~T,rest,I.shift(key),first,second,I.high(I.shift(key)))
    case 1n+rest True{}: duplicate_roundtrip(~T,rest,I.shift(key),first,second,I.high(I.shift(key)))
def Laws.empty_falls_back(T,key,fallback): {==}
def Laws.empty_insert_roundtrip(T,key,value): empty_roundtrip(~T,32n,key,value,I.high(key))
def Laws.first_insert_wins(T,key,first,second): duplicate_roundtrip(~T,32n,key,first,second,I.high(key))
