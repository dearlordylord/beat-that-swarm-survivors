import Base

# Small Base-only reflexive comparison facts used by world-tick lookup proofs.
law bool_cmp_self:
  for +value: Bool
  {Bool.cmp(value,value) == EQ{} : Cmp}
def bool_cmp_self(value):
  match value:
    case False{}: {==}
    case True{}: {==}

def cmp_fin_self(+head: Bool,+tail: Cmp,equal: {tail == EQ{} : Cmp}) -> {Word.cmp.fin(head,head,tail) == EQ{} : Cmp}:
  %Equal.sym(Cmp,tail,EQ{},equal) : {Word.cmp.fin(head,head,_) == EQ{} : Cmp}
  bool_cmp_self(head)

law word_cmp_self:
  for n: Nat
  for +value: Word(n)
  {Word.cmp(n,value,value) == EQ{} : Cmp}
def word_cmp_self(n,value):
  match n value:
    case 0n WNil{}: {==}
    case 1n++prior WCon{+head,+tail}: cmp_fin_self(head,Word.cmp(prior,tail,tail),word_cmp_self(prior,tail))

law cmp_self:
  for +value: U32
  {U32.cmp(value,value) == EQ{} : Cmp}
def cmp_self(value):
  match value:
    case U32{word}: word_cmp_self(32n,word)

law eq_self:
  for +value: U32
  {U32.is_eq(value,value) == True{} : Bool}
def eq_self(value):
  %Equal.sym(Cmp,U32.cmp(value,value),EQ{},cmp_self(value)) : {Cmp.is_eq(_) == True{} : Bool}
  {==}

law gt_self:
  for +value: U32
  {U32.is_gt(value,value) == False{} : Bool}
def gt_self(value):
  %Equal.sym(Cmp,U32.cmp(value,value),EQ{},cmp_self(value)) : {Cmp.is_gt(_) == False{} : Bool}
  {==}
