import Base

type Tree<a,-T:Kind(a)> is Kind(a):
  Empty{}
  Leaf{value:T}
  Branch{left:Tree<a,T>,right:Tree<a,T>}

def map_serial(~a:Quant,~b:Quant,~A:Kind(a),~B:Kind(b),~job:A -> B,tree:Tree<a,A>) -> Tree<b,B>:
  match tree:
    case Empty{}: Empty{}
    case Leaf{value}: Leaf{job(value)}
    case Branch{left,right}: Branch{map_serial(~a,~b,~A,~B,~job,left),map_serial(~a,~b,~A,~B,~job,right)}
def prepend(~a:Quant,~A:Kind(a),tree:Tree<a,A>,tail:List<a,A>) -> List<a,A>:
  match tree:
    case Empty{}: tail
    case Leaf{value}: value <> tail
    case Branch{left,right}: prepend(~a,~A,left,prepend(~a,~A,right,tail))
def to_list(~a:Quant,~A:Kind(a),tree:Tree<a,A>) -> List<a,A>: prepend(~a,~A,tree,[])

def map_context_serial(~Context:Data,~a:Quant,~b:Quant,~A:Kind(a),~B:Kind(b),~job:Context -> A -> B,+context:Context,tree:Tree<a,A>) -> Tree<b,B>:
  match tree:
    case Empty{}: Empty{}
    case Leaf{value}: Leaf{job(context,value)}
    case Branch{left,right}:
      Branch{map_context_serial(~Context,~a,~b,~A,~B,~job,context,left),map_context_serial(~Context,~a,~b,~A,~B,~job,context,right)}

def map_context(~Context:Data,~a:Quant,~b:Quant,~A:Kind(a),~B:Kind(b),~job:Context -> A -> B,+context:Context,tree:Tree<a,A>) -> Tree<b,B>:
  match tree:
    case Empty{}: Empty{}
    case Leaf{value}: Leaf{job(context,value)}
    case Branch{left,right}:
      l r = map_context(~Context,~a,~b,~A,~B,~job,context,left) map_context(~Context,~a,~b,~A,~B,~job,context,right)
      Branch{l,r}
