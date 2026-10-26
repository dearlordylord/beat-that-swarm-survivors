import Base
import affine.bend as S
import affine-LAWS.bend as L

def same(~Context:Data,~A:Data,~T:Data,~job:Context -> A -> T,+context:Context,+plan:S.Tree<&2,A>) -> {S.map_context(~Context,~&2,~&2,~A,~T,~job,context,plan) == S.map_context_serial(~Context,~&2,~&2,~A,~T,~job,context,plan) : S.Tree<&2,T>}:
  match plan:
    case S.Empty{}: {==}
    case S.Leaf{value}: {==}
    case S.Branch{+left,+right}:
      Equal.trans(S.Tree<&2,T>,S.Branch{S.map_context(~Context,~&2,~&2,~A,~T,~job,context,left),S.map_context(~Context,~&2,~&2,~A,~T,~job,context,right)},S.Branch{S.map_context_serial(~Context,~&2,~&2,~A,~T,~job,context,left),S.map_context(~Context,~&2,~&2,~A,~T,~job,context,right)},S.Branch{S.map_context_serial(~Context,~&2,~&2,~A,~T,~job,context,left),S.map_context_serial(~Context,~&2,~&2,~A,~T,~job,context,right)},Equal.cong(S.Tree<&2,T>,S.Tree<&2,T>,l => S.Branch{l,S.map_context(~Context,~&2,~&2,~A,~T,~job,context,right)},S.map_context(~Context,~&2,~&2,~A,~T,~job,context,left),S.map_context_serial(~Context,~&2,~&2,~A,~T,~job,context,left),same(~Context,~A,~T,~job,context,left)),Equal.cong(S.Tree<&2,T>,S.Tree<&2,T>,r => S.Branch{S.map_context_serial(~Context,~&2,~&2,~A,~T,~job,context,left),r},S.map_context(~Context,~&2,~&2,~A,~T,~job,context,right),S.map_context_serial(~Context,~&2,~&2,~A,~T,~job,context,right),same(~Context,~A,~T,~job,context,right)))
def L.parallel_matches_serial(Context,A,T,job,context,plan): same(~Context,~A,~T,~job,context,plan)
