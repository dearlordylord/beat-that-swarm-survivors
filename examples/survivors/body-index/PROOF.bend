import Base
import ../body-index.bend as I
import LAWS.bend as Laws
import SPEC.bend as S
import ../proof-facts.bend as F

def singleton_find(~T: Data,+key: U32,+value: T) -> {I.find(~T,I.Item{key,value},key) == Some{value} : Maybe<&2,T>}:
  Equal.cong(Bool,Maybe<&2,T>,same => I.find_item(~T,same,value),U32.is_eq(key,key),True{},F.u32_eq_refl(key))
def duplicate_item(~T: Data,+key: U32,+first: T,second: T) -> {I.insert(~T,I.Item{key,first},key,second) == I.Item{key,first} : I.Index<T>}:
  Equal.cong(Bool,I.Index<T>,same => I.insert_item(~T,same,key,first,key,second),U32.is_eq(key,key),True{},F.u32_eq_refl(key))
def Laws.empty_falls_back(T,key,fallback): {==}
def Laws.empty_insert_roundtrip(T,key,value): singleton_find(~T,key,value)
def Laws.first_insert_wins(T,key,first,second):
  Equal.trans(Maybe<&2,T>,I.find(~T,I.insert(~T,I.Item{key,first},key,second),key),I.find(~T,I.Item{key,first},key),Some{first},Equal.cong(I.Index<T>,Maybe<&2,T>,index => I.find(~T,index,key),I.insert(~T,I.Item{key,first},key,second),I.Item{key,first},duplicate_item(~T,key,first,second)),singleton_find(~T,key,first))

def joined_source(~T:Data,~allowed:U32 -> Bool,one:Bool,+sample:U32,+mask:U32,+old:I.Index<T>,+fresh:I.Index<T>,oldKeys:{True{} == S.all_keys(~T,~allowed,old) : Bool},newKeys:{True{} == S.all_keys(~T,~allowed,fresh) : Bool}) -> {True{} == S.all_keys(~T,~allowed,I.join_side(~T,one,sample,mask,old,fresh)) : Bool}:
  match one:
    case False{}: F.and_true(S.all_keys(~T,~allowed,fresh),S.all_keys(~T,~allowed,old),newKeys,oldKeys)
    case True{}: F.and_true(S.all_keys(~T,~allowed,old),S.all_keys(~T,~allowed,fresh),oldKeys,newKeys)
def join_source(~T:Data,~allowed:U32 -> Bool,+old:I.Index<T>,+sample:U32,+key:U32,+value:T,oldKeys:{True{} == S.all_keys(~T,~allowed,old) : Bool},newKey:{True{} == allowed(key) : Bool}) -> {True{} == S.all_keys(~T,~allowed,I.join(~T,old,sample,key,value)) : Bool}:
  joined_source(~T,~allowed,I.high(key,U32.shln(1,U32.log2(U32.xor(sample,key)))),key,U32.shln(1,U32.log2(U32.xor(sample,key))),old,I.Item{key,value},oldKeys,newKey)
def item_source(~T:Data,~allowed:U32 -> Bool,same:Bool,+oldKey:U32,+old:T,+key:U32,+value:T,oldKeys:{True{} == allowed(oldKey) : Bool},newKey:{True{} == allowed(key) : Bool}) -> {True{} == S.all_keys(~T,~allowed,I.insert_item(~T,same,oldKey,old,key,value)) : Bool}:
  match same:
    case True{}: oldKeys
    case False{}: join_source(~T,~allowed,I.Item{oldKey,old},oldKey,key,value,oldKeys,newKey)
def insert_go_source(~T:Data,~allowed:U32 -> Bool,+fuel:Nat,+index:I.Index<T>,+key:U32,+value:T,+above:Bool,+one:Bool,+oldKeys:{True{} == S.all_keys(~T,~allowed,index) : Bool},newKey:{True{} == allowed(key) : Bool}) -> {True{} == S.all_keys(~T,~allowed,I.insert_go(~T,fuel,index,key,value,above,one)) : Bool}:
  match fuel index above one:
    case _ I.Empty{} True{} True{}: newKey
    case _ I.Empty{} True{} False{}: newKey
    case _ I.Empty{} False{} True{}: newKey
    case _ I.Empty{} False{} False{}: newKey
    case _ I.Item{+oldKey,old} True{} True{}: item_source(~T,~allowed,U32.is_eq(oldKey,key),oldKey,old,key,value,oldKeys,newKey)
    case _ I.Item{+oldKey,old} True{} False{}: item_source(~T,~allowed,U32.is_eq(oldKey,key),oldKey,old,key,value,oldKeys,newKey)
    case _ I.Item{+oldKey,old} False{} True{}: item_source(~T,~allowed,U32.is_eq(oldKey,key),oldKey,old,key,value,oldKeys,newKey)
    case _ I.Item{+oldKey,old} False{} False{}: item_source(~T,~allowed,U32.is_eq(oldKey,key),oldKey,old,key,value,oldKeys,newKey)
    case _ I.Fork{+sample,+mask,+zero,+one} True{} _: join_source(~T,~allowed,I.Fork{sample,mask,zero,one},sample,key,value,oldKeys,newKey)
    case 0n index False{} _: oldKeys
    case 1n+rest I.Fork{sample,mask,+zero,+one} False{} False{}:
      F.and_true(S.all_keys(~T,~allowed,I.insert_go(~T,rest,zero,key,value,I.outside(~T,zero,key),I.branch(~T,zero,key))),S.all_keys(~T,~allowed,one),insert_go_source(~T,~allowed,rest,zero,key,value,I.outside(~T,zero,key),I.branch(~T,zero,key),F.and_left(S.all_keys(~T,~allowed,zero),S.all_keys(~T,~allowed,one),oldKeys),newKey),F.and_right(S.all_keys(~T,~allowed,zero),S.all_keys(~T,~allowed,one),oldKeys))
    case 1n+rest I.Fork{sample,mask,+zero,+one} False{} True{}:
      F.and_true(S.all_keys(~T,~allowed,zero),S.all_keys(~T,~allowed,I.insert_go(~T,rest,one,key,value,I.outside(~T,one,key),I.branch(~T,one,key))),F.and_left(S.all_keys(~T,~allowed,zero),S.all_keys(~T,~allowed,one),oldKeys),insert_go_source(~T,~allowed,rest,one,key,value,I.outside(~T,one,key),I.branch(~T,one,key),F.and_right(S.all_keys(~T,~allowed,zero),S.all_keys(~T,~allowed,one),oldKeys),newKey))
def Laws.insertion_preserves_key_source(T,allowed,index,key,value,oldKeys,newKey):
  insert_go_source(~T,~allowed,32n,index,key,value,I.outside(~T,index,key),I.branch(~T,index,key),oldKeys,newKey)
