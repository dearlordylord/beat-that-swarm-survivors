import Base
import ../body-index.bend as I
import LAWS.bend as Laws

def word_cmp_refl(+n: Nat,+word: Word(n)) -> {Word.cmp(n,word,word) == EQ{} : Cmp}:
  match n word:
    case 0n WNil{}: {==}
    case 1n+p WCon{False{},+tail}: Equal.cong(Cmp,Cmp,c => Word.cmp.fin(False{},False{},c),Word.cmp(p,tail,tail),EQ{},word_cmp_refl(p,tail))
    case 1n+p WCon{True{},+tail}: Equal.cong(Cmp,Cmp,c => Word.cmp.fin(True{},True{},c),Word.cmp(p,tail,tail),EQ{},word_cmp_refl(p,tail))
def u32_eq_refl(+key: U32) -> {U32.is_eq(key,key) == True{} : Bool}:
  match key:
    case U32{+word}: Equal.cong(Cmp,Bool,Cmp.is_eq,Word.cmp(32n,word,word),EQ{},word_cmp_refl(32n,word))
def singleton_find(~T: Data,+key: U32,+value: T) -> {I.find(~T,I.Item{key,value},key) == Some{value} : Maybe<&2,T>}:
  Equal.cong(Bool,Maybe<&2,T>,same => I.find_item(~T,same,value),U32.is_eq(key,key),True{},u32_eq_refl(key))
def duplicate_item(~T: Data,+key: U32,+first: T,second: T) -> {I.insert(~T,I.Item{key,first},key,second) == I.Item{key,first} : I.Index<T>}:
  Equal.cong(Bool,I.Index<T>,same => I.insert_item(~T,same,key,first,key,second),U32.is_eq(key,key),True{},u32_eq_refl(key))
def Laws.empty_falls_back(T,key,fallback): {==}
def Laws.empty_insert_roundtrip(T,key,value): singleton_find(~T,key,value)
def Laws.first_insert_wins(T,key,first,second):
  Equal.trans(Maybe<&2,T>,I.find(~T,I.insert(~T,I.Item{key,first},key,second),key),I.find(~T,I.Item{key,first},key),Some{first},Equal.cong(I.Index<T>,Maybe<&2,T>,index => I.find(~T,index,key),I.insert(~T,I.Item{key,first},key,second),I.Item{key,first},duplicate_item(~T,key,first,second)),singleton_find(~T,key,first))
