import Base

# Patricia lookup keeps only branching bits. Sample keys identify a fork's
# shared prefix; opaque values remain only in leaves. First insertion wins.
type Index<-T: Data> is Data:
  Empty{}
  Item{key: U32,value: T}
  Fork{sample: U32,mask: U32,zero: Index<T>,one: Index<T>}

def high(+key: U32,mask: U32) -> Bool: U32.is_ne(U32.and(key,mask),0)
def outside(~T: Data,index: Index<T>,key: U32) -> Bool:
  match index:
    case Fork{sample,+mask,_,_}: U32.is_lt((mask + (mask - 1) : U32),U32.xor(sample,key))
    case _: False{}
def branch(~T: Data,index: Index<T>,key: U32) -> Bool:
  match index:
    case Fork{_,mask,_,_}: high(key,mask)
    case _: False{}
def join_side(~T: Data,one: Bool,sample: U32,mask: U32,old: Index<T>,fresh: Index<T>) -> Index<T>:
  match one:
    case False{}: Fork{sample,mask,fresh,old}
    case True{}: Fork{sample,mask,old,fresh}
def join_mask(~T: Data,+mask: U32,old: Index<T>,+key: U32,value: T) -> Index<T>:
  join_side(~T,high(key,mask),key,mask,old,Item{key,value})
def join(~T: Data,old: Index<T>,sample: U32,+key: U32,value: T) -> Index<T>:
  join_mask(~T,U32.shln(1,U32.log2(U32.xor(sample,key))),old,key,value)
def insert_item(~T: Data,same: Bool,+oldKey: U32,old: T,+key: U32,value: T) -> Index<T>:
  match same:
    case True{}: Item{oldKey,old}
    case False{}: join(~T,Item{oldKey,old},oldKey,key,value)
def insert_go(~T: Data,fuel: Nat,index: Index<T>,+key: U32,+value: T,above: Bool,one: Bool) -> Index<T>:
  match fuel index above one:
    case _ Empty{} _ _: Item{key,value}
    case _ Item{+oldKey,old} _ _: insert_item(~T,U32.is_eq(oldKey,key),oldKey,old,key,value)
    case _ Fork{+sample,mask,zero,one} True{} _: join(~T,Fork{sample,mask,zero,one},sample,key,value)
    case 0n index False{} _: index
    case 1n+rest Fork{sample,mask,+zero,one} False{} False{}: Fork{sample,mask,insert_go(~T,rest,zero,key,value,outside(~T,zero,key),branch(~T,zero,key)),one}
    case 1n+rest Fork{sample,mask,zero,+one} False{} True{}: Fork{sample,mask,zero,insert_go(~T,rest,one,key,value,outside(~T,one,key),branch(~T,one,key))}
def insert(~T: Data,+index: Index<T>,+key: U32,value: T) -> Index<T>:
  insert_go(~T,32n,index,key,value,outside(~T,index,key),branch(~T,index,key))
def find_item(~T: Data,same: Bool,value: T) -> Maybe<&2,T>:
  match same:
    case True{}: Some{value}
    case False{}: None{}
def find_go(~T: Data,fuel: Nat,index: Index<T>,+key: U32,one: Bool) -> Maybe<&2,T>:
  match fuel index one:
    case _ Empty{} _: None{}
    case _ Item{stored,value} _: find_item(~T,U32.is_eq(stored,key),value)
    case 0n Fork{_,_,_,_} _: None{}
    case 1n+rest Fork{_,_,+zero,_} False{}: find_go(~T,rest,zero,key,branch(~T,zero,key))
    case 1n+rest Fork{_,_,_,+one} True{}: find_go(~T,rest,one,key,branch(~T,one,key))
def find(~T: Data,+index: Index<T>,+key: U32) -> Maybe<&2,T>:
  find_go(~T,32n,index,key,branch(~T,index,key))
def value_or(~T: Data,result: Maybe<&2,T>,fallback: T) -> T:
  match result:
    case None{}: fallback
    case Some{value}: value
def get(~T: Data,index: Index<T>,key: U32,fallback: T) -> T:
  value_or(~T,find(~T,index,key),fallback)
