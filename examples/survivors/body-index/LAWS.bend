import Base
import ../body-index.bend as I
import SPEC.bend as S

# Opaque payloads are preserved and index leaves keep their physical ID source.
law empty_falls_back:
  for ~T: Data
  for key: U32
  for fallback: T
  {I.get(~T,I.Empty{},key,fallback) == fallback : T}
law empty_insert_roundtrip:
  for ~T: Data
  for +key: U32
  for +value: T
  {I.find(~T,I.insert(~T,I.Empty{},key,value),key) == Some{value} : Maybe<&2,T>}
law first_insert_wins:
  for ~T: Data
  for +key: U32
  for +first: T
  for second: T
  {I.find(~T,I.insert(~T,I.insert(~T,I.Empty{},key,first),key,second),key) == Some{first} : Maybe<&2,T>}

# Guarantees: insertion never introduces a physical identity outside the allowed
# source set when both the old tree and the new key belong to that set.
# Why it matters: pool planning must not create an assignment for a live slot,
# even when routing branches or insertion fuel differ.
law insertion_preserves_key_source:
  for ~T:Data
  for ~allowed:U32 -> Bool
  for +index:I.Index<T>
  for +key:U32
  for value:T
  for oldKeys:{True{} == S.all_keys(~T,~allowed,index) : Bool}
  for newKey:{True{} == allowed(key) : Bool}
  {True{} == S.all_keys(~T,~allowed,I.insert(~T,index,key,value)) : Bool}
