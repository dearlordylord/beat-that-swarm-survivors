import Base

# Both traversals are tail calls. The explicit context avoids allocating a
# closure per row while preserving the order of the ordinary recursive map.
def go(~A:Data,~B:Data,~Context:Data,~f:Context -> A -> B,rows:List<&2,A>,+context:Context,acc:List<&2,B>) -> List<&2,B>:
  match rows:
    case []: acc
    case head <> tail: go(~A,~B,~Context,~f,tail,context,f(context,head) <> acc)
def map(~A:Data,~B:Data,~Context:Data,~f:Context -> A -> B,context:Context,rows:List<&2,A>) -> List<&2,B>:
  List.reverse(&2,B,go(~A,~B,~Context,~f,rows,context,[]))
