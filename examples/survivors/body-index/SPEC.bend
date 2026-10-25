import Base
import ../body-index.bend as I

# This predicate checks every stored leaf, independently of lookup routing.
def all_keys(~T:Data,~allowed:U32 -> Bool,index:I.Index<T>) -> Bool:
  match index:
    case I.Empty{}: True{}
    case I.Item{key,_}: allowed(key)
    case I.Fork{_,_,zero,one}: Bool.and(all_keys(~T,~allowed,zero),all_keys(~T,~allowed,one))
def all_free(~allowed:U32 -> Bool,free:List<&2,U32>) -> Bool:
  match free:
    case []: True{}
    case key <> rest: Bool.and(allowed(key),all_free(~allowed,rest))
