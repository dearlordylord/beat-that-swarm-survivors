import Base
import affine.bend as S

# Guarantees: a pure map preserves every Data result and the full tree shape across CPU scheduling.
# Why it matters: distributing independent native worlds must not reorder or lose jobs. This law covers the generic scheduler, not game transitions or affine world equality.
law parallel_matches_serial:
  for ~Context:Data
  for ~A:Data
  for ~T:Data
  for ~job:Context -> A -> T
  for +context:Context
  for +plan:S.Tree<&2,A>
  {S.map_context(~Context,~&2,~&2,~A,~T,~job,context,plan) == S.map_context_serial(~Context,~&2,~&2,~A,~T,~job,context,plan) : S.Tree<&2,T>}
