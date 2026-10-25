import Base

# Small Base-only arithmetic facts used by prediction history proofs.
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

law ge_self:
  for +value: U32
  {U32.is_ge(value,value) == True{} : Bool}
def ge_self(value):
  %Equal.sym(Cmp,U32.cmp(value,value),EQ{},cmp_self(value)) : {Cmp.is_ge(_) == True{} : Bool}
  {==}

law max_self:
  for +value: U32
  {U32.max(value,value) == value : U32}
def max_self(value):
  match value:
    case U32{+word}:
      %Equal.sym(Cmp,U32.cmp(U32{word},U32{word}),EQ{},word_cmp_self(32n,word)) : {Bool.pick(U32,Cmp.is_lt(_),U32{word},U32{word}) == U32{word} : U32}
      {==}

def max_true(+a: U32,+b: U32,less: {U32.is_lt(a,b) == True{} : Bool}) -> {U32.max(a,b) == b : U32}:
  match a b:
    case U32{+aw} U32{+bw}:
      %Equal.sym(Bool,U32.is_lt(U32{aw},U32{bw}),True{},less) : {Bool.pick(U32,_,U32{bw},U32{aw}) == U32{bw} : U32}
      {==}
def max_false(+a: U32,+b: U32,less: {U32.is_lt(a,b) == False{} : Bool}) -> {U32.max(a,b) == a : U32}:
  match a b:
    case U32{+aw} U32{+bw}:
      %Equal.sym(Bool,U32.is_lt(U32{aw},U32{bw}),False{},less) : {Bool.pick(U32,_,U32{bw},U32{aw}) == U32{aw} : U32}
      {==}
def max_absorb_true(+a: U32,+b: U32,+chosen: {U32.max(a,b) == b : U32}) -> {U32.max(U32.max(a,b),b) == U32.max(a,b) : U32}:
  Equal.trans(U32,U32.max(U32.max(a,b),b),U32.max(b,b),U32.max(a,b),Equal.cong(U32,U32,v => U32.max(v,b),U32.max(a,b),b,chosen),Equal.trans(U32,U32.max(b,b),b,U32.max(a,b),max_self(b),Equal.sym(U32,U32.max(a,b),b,chosen)))
def max_absorb_false(+a: U32,+b: U32,chosen: {U32.max(a,b) == a : U32}) -> {U32.max(U32.max(a,b),b) == U32.max(a,b) : U32}:
  Equal.cong(U32,U32,v => U32.max(v,b),U32.max(a,b),a,chosen)
def max_absorb_case(+a: U32,+b: U32,less: Bool,equal: {U32.is_lt(a,b) == less : Bool}) -> {U32.max(U32.max(a,b),b) == U32.max(a,b) : U32}:
  match less:
    case True{}: max_absorb_true(a,b,max_true(a,b,equal))
    case False{}: max_absorb_false(a,b,max_false(a,b,equal))

law max_absorb:
  for +a: U32
  for +b: U32
  {U32.max(U32.max(a,b),b) == U32.max(a,b) : U32}
def max_absorb(a,b): max_absorb_case(a,b,U32.is_lt(a,b),{==})
