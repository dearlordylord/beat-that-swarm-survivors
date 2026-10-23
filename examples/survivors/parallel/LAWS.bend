import Base
import scheduler.bend as S

# Scheduling may change evaluation order, never the result shape/values.
# This is pure scheduler equivalence, not universal game equivalence.
law parallel_matches_serial:
  for ~Context:Data
  for ~T:Data
  for ~job:Context -> U32 -> T
  for +context:Context
  for +plan:S.Plan
  {S.map_parallel(~Context,~T,~job,context,plan) == S.map_serial(~Context,~T,~job,context,plan) : S.Results<T>}

def identity(context:Unit,index:U32) -> U32:index
# Finite build guards cover empty/singleton, odd balanced split, and U32 wrap.
law empty_indices:
  {S.to_list(~U32,S.map_serial(~Unit,~U32,~identity,Unit{},S.build(0,7,3))) == [] : List<&2,U32>}
law singleton_index:
  {S.to_list(~U32,S.map_serial(~Unit,~U32,~identity,Unit{},S.build(1,7,3))) == [7] : List<&2,U32>}
law odd_stride_indices:
  {S.to_list(~U32,S.map_serial(~Unit,~U32,~identity,Unit{},S.build(3,5,2))) == [5,7,9] : List<&2,U32>}
law wrapped_indices:
  {S.to_list(~U32,S.map_serial(~Unit,~U32,~identity,Unit{},S.build(3,4294967294,2))) == [4294967294,0,2] : List<&2,U32>}
