import Base
import ./list-map.bend as M

# Independent, direct specification: one output per input in the same order.
def reference(~A:Data,~B:Data,~Context:Data,~f:Context -> A -> B,rows:List<&2,A>,+context:Context) -> List<&2,B>:
  match rows:
    case []: []
    case head <> tail: f(context,head) <> reference(~A,~B,~Context,~f,tail,context)

# Guarantees: the accumulator traversal is exactly the reversed mapped input
# prepended to its original accumulator, for all rows and mapping contexts.
# Why it matters: making the ECS traversal iterative cannot omit, duplicate,
# reorder or change a row before the final order-restoring reverse.
law accumulator_exact:
  for ~A:Data
  for ~B:Data
  for ~Context:Data
  for ~f:Context -> A -> B
  for +rows:List<&2,A>
  for +context:Context
  for +acc:List<&2,B>
  {M.go(~A,~B,~Context,~f,rows,context,acc) == List.reverse.go(&2,B,reference(~A,~B,~Context,~f,rows,context),acc) : List<&2,B>}

# Guarantees: the public traversal returns exactly the direct recursive map,
# including every mapped value and the complete original row order.
# Why it matters: avoiding a browser stack overflow must not change gameplay
# ownership or any output row. Runtime emission checks qualify bounded stack;
# this equation proves values and order, not a JavaScript compiler property.
law map_exact:
  for ~A:Data
  for ~B:Data
  for ~Context:Data
  for ~f:Context -> A -> B
  for +rows:List<&2,A>
  for +context:Context
  {M.map(~A,~B,~Context,~f,context,rows) == reference(~A,~B,~Context,~f,rows,context) : List<&2,B>}
