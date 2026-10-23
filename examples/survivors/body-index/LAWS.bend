import Base
import ../body-index.bend as I

# These laws cover generic opaque values, empty fallback and first insertion.
# Full row-list/old-scan equivalence is exercised by executable differential tests.
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
