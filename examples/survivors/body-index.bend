import Base

# Immutable, shared lookup by every bit of an arbitrary U32 key. Leaves keep
# values opaque. Insertion never replaces an existing value (first row wins).
type Index<-T: Data> is Data:
  Empty{}
  Item{value: T}
  Fork{zero: Index<T>,one: Index<T>}

def high(key: U32) -> Bool: U32.is_ne(U32.shrn(key,31n),0)
def shift(key: U32) -> U32: U32.shln(key,1n)
def insert_go(~T: Data,fuel: Nat,index: Index<T>,+key: U32,+value: T,bit: Bool) -> Index<T>:
  match fuel index bit:
    case 0n Item{old} _: Item{old}
    case 0n _ _: Item{value}
    case 1n+_ Item{old} _: Item{old}
    case 1n+rest Empty{} False{}: Fork{insert_go(~T,rest,Empty{},shift(key),value,high(shift(key))),Empty{}}
    case 1n+rest Empty{} True{}: Fork{Empty{},insert_go(~T,rest,Empty{},shift(key),value,high(shift(key)))}
    case 1n+rest Fork{zero,one} False{}: Fork{insert_go(~T,rest,zero,shift(key),value,high(shift(key))),one}
    case 1n+rest Fork{zero,one} True{}: Fork{zero,insert_go(~T,rest,one,shift(key),value,high(shift(key)))}
def insert(~T: Data,index: Index<T>,+key: U32,value: T) -> Index<T>:
  insert_go(~T,32n,index,key,value,high(key))
def find_go(~T: Data,fuel: Nat,index: Index<T>,+key: U32,bit: Bool) -> Maybe<&2,T>:
  match fuel index bit:
    case _ Empty{} _: None{}
    case _ Item{value} _: Some{value}
    case 0n Fork{_,_} _: None{}
    case 1n+rest Fork{zero,_} False{}: find_go(~T,rest,zero,shift(key),high(shift(key)))
    case 1n+rest Fork{_,one} True{}: find_go(~T,rest,one,shift(key),high(shift(key)))
def find(~T: Data,index: Index<T>,+key: U32) -> Maybe<&2,T>:
  find_go(~T,32n,index,key,high(key))
def value_or(~T: Data,result: Maybe<&2,T>,fallback: T) -> T:
  match result:
    case None{}: fallback
    case Some{value}: value
def get(~T: Data,index: Index<T>,key: U32,fallback: T) -> T:
  value_or(~T,find(~T,index,key),fallback)
