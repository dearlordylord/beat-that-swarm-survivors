import Base

type Amount is Data: Amount{numerator: List<&2,Nat>,denominator: List<&2,Nat>}
type DivisionStep is Data: DivisionStep{remainder: List<&2,Nat>,digit: Nat}
def step_remainder(+step: DivisionStep) -> List<&2,Nat>:
  match step:
    case DivisionStep{remainder,_}: remainder
def step_digit(+step: DivisionStep) -> Nat:
  match step:
    case DivisionStep{_,digit}: digit

# Small decimal limbs keep exact arithmetic within Bend's immediate Nat bound.
def big_trim_zero(+rows: List<&2,Nat>) -> List<&2,Nat>:
  match rows:
    case Con{0n,rest}: big_trim_zero(rest)
    case rows: rows
def big_trim(+rows: List<&2,Nat>) -> List<&2,Nat>: List.reverse(&2,Nat,big_trim_zero(List.reverse(&2,Nat,rows)))
def big_from_go(+fuel: Nat,+n: Nat) -> List<&2,Nat>:
  match fuel n:
    case _ 0n: []
    case 0n _: []
    case 1n+p n: Nat.mod(n,10n) <> big_from_go(p,Nat.div(n,10n))
def big_from(+n: Nat) -> List<&2,Nat>: big_from_go(16n,n)
def big_lex(+a: List<&2,Nat>,+b: List<&2,Nat>) -> U32:
  match a b:
    case Nil{} Nil{}: 1
    case Con{+x,xs} Con{+y,ys}: Bool.pick(U32,Nat.is_eq(x,y),big_lex(xs,ys),Bool.pick(U32,Nat.is_lt(x,y),0,2))
    case _ _: 1
def big_cmp(+a: List<&2,Nat>,+b: List<&2,Nat>) -> U32:
  +al = List.length(&2,Nat,a)
  +bl = List.length(&2,Nat,b)
  Bool.pick(U32,Nat.is_eq(al,bl),big_lex(List.reverse(&2,Nat,a),List.reverse(&2,Nat,b)),Bool.pick(U32,Nat.is_lt(al,bl),0,2))
def big_ge(+a: List<&2,Nat>,+b: List<&2,Nat>) -> Bool: U32.is_ne(big_cmp(a,b),0)
def big_add(+a: List<&2,Nat>,+b: List<&2,Nat>,+carry: Nat) -> List<&2,Nat>:
  match a b:
    case Nil{} Nil{}: big_from(carry)
    case Con{x,xs} Nil{}:
      +sum = Nat.add(x,carry)
      Nat.mod(sum,10n) <> big_add(xs,[],Nat.div(sum,10n))
    case Nil{} Con{y,ys}:
      +sum = Nat.add(y,carry)
      Nat.mod(sum,10n) <> big_add([],ys,Nat.div(sum,10n))
    case Con{x,xs} Con{y,ys}:
      +sum = Nat.add(Nat.add(x,y),carry)
      Nat.mod(sum,10n) <> big_add(xs,ys,Nat.div(sum,10n))
def big_sub(+a: List<&2,Nat>,+b: List<&2,Nat>,+borrow: Nat) -> List<&2,Nat>:
  match a b:
    case Nil{} _: []
    case Con{+x,xs} Nil{}:
      +owes = borrow
      Bool.pick(Nat,Nat.is_ge(x,owes),Nat.sub(x,owes),Nat.sub(Nat.add(x,10n),owes)) <> big_sub(xs,[],Bool.pick(Nat,Nat.is_ge(x,owes),0n,1n))
    case Con{+x,xs} Con{y,ys}:
      +owes = Nat.add(y,borrow)
      Bool.pick(Nat,Nat.is_ge(x,owes),Nat.sub(x,owes),Nat.sub(Nat.add(x,10n),owes)) <> big_sub(xs,ys,Bool.pick(Nat,Nat.is_ge(x,owes),0n,1n))
def big_mul_digit(+a: List<&2,Nat>,+digit: Nat,+carry: Nat) -> List<&2,Nat>:
  match a:
    case Nil{}: big_from(carry)
    case Con{x,xs}:
      +sum = Nat.add(Nat.mul(x,digit),carry)
      Nat.mod(sum,10n) <> big_mul_digit(xs,digit,Nat.div(sum,10n))
def big_mul(+a: List<&2,Nat>,+b: List<&2,Nat>) -> List<&2,Nat>:
  match a:
    case Nil{}: []
    case Con{x,xs}: big_trim(big_add(big_mul_digit(b,x,0n),0n <> big_mul(xs,b),0n))
def big_div_digit(+fuel: Nat,+remainder: List<&2,Nat>,+denominator: List<&2,Nat>,+digit: Nat) -> DivisionStep:
  match fuel:
    case 0n: DivisionStep{remainder,digit}
    case 1n+p:
      +enough = big_ge(remainder,denominator)
      big_div_digit(p,Bool.pick(List<&2,Nat>,enough,big_trim(big_sub(remainder,denominator,0n)),remainder),denominator,Nat.add(digit,U32.to_nat(Bool.to_u32(enough))))
def big_div_go(+digits: List<&2,Nat>,+denominator: List<&2,Nat>,+remainder: List<&2,Nat>,+quotient: List<&2,Nat>) -> List<&2,Nat> & List<&2,Nat>:
  match digits:
    case Nil{}: (big_trim(quotient),remainder)
    case Con{head,rest}:
      +step = big_div_digit(10n,big_trim(head <> remainder),denominator,0n)
      big_div_go(rest,denominator,step_remainder(step),step_digit(step) <> quotient)
def big_div(+numerator: List<&2,Nat>,+denominator: List<&2,Nat>) -> List<&2,Nat> & List<&2,Nat>: big_div_go(List.reverse(&2,Nat,numerator),denominator,[],[])
def big_quotient(result: List<&2,Nat> & List<&2,Nat>) -> List<&2,Nat>:
  match result:
    case (quotient,_): quotient
def bounded_digit(+tooBig: Bool,+acc: Nat,+digit: Nat) -> Nat:
  match tooBig:
    case True{}: Nat.add(Nat.mul(65536n,4294967295n),65535n)
    case False{}: Nat.add(Nat.mul(acc,10n),digit)
def big_to_go(+rows: List<&2,Nat>,+acc: Nat) -> Nat:
  match rows:
    case Nil{}: acc
    case Con{head,rest}: big_to_go(rest,bounded_digit(Nat.is_gt(acc,Nat.sub(Nat.div(Nat.add(Nat.mul(65536n,4294967295n),65535n),10n),1n)),acc,head))
def big_to(+rows: List<&2,Nat>) -> Nat: big_to_go(List.reverse(&2,Nat,rows),0n)

def natural(+value: Nat) -> Amount: Amount{big_from(value),[1n]}
def ratio(+numerator: Nat,+denominator: Nat) -> Amount: Amount{big_from(numerator),big_from(denominator)}
def zero() -> Amount: natural(0n)
def one() -> Amount: natural(1n)
def numerator(+value: Amount) -> List<&2,Nat>:
  match value:
    case Amount{n,_}: n
def denominator(+value: Amount) -> List<&2,Nat>:
  match value:
    case Amount{_,d}: d
def integer(+value: Amount) -> Nat:
  match value:
    case Amount{n,d}: big_to(big_quotient(big_div(n,d)))
def whole(+value: Amount) -> Amount:
  match value:
    case Amount{n,d}: Amount{big_quotient(big_div(n,d)),[1n]}
def ge(+a: Amount,+b: Amount) -> Bool:
  match a b:
    case Amount{n,d} Amount{m,e}: big_ge(big_mul(n,e),big_mul(m,d))
def equal(+a: Amount,+b: Amount) -> Bool: Bool.and(ge(a,b),ge(b,a))
def add(+a: Amount,+b: Amount) -> Amount:
  match a b:
    case Amount{n,+d} Amount{m,+e}: Amount{big_trim(big_add(big_mul(n,e),big_mul(m,d),0n)),big_mul(d,e)}
def subtract_parts(+enough: Bool,+left: List<&2,Nat>,+right: List<&2,Nat>,+denominator: List<&2,Nat>) -> Amount:
  match enough:
    case True{}: Amount{big_trim(big_sub(left,right,0n)),denominator}
    case False{}: zero()
def subtract(+a: Amount,+b: Amount) -> Amount:
  match a b:
    case Amount{n,+d} Amount{m,+e}:
      +left = big_mul(n,e)
      +right = big_mul(m,d)
      subtract_parts(big_ge(left,right),left,right,big_mul(d,e))
def choose(+test: Bool,+yes: Amount,+no: Amount) -> Amount:
  match test:
    case True{}: yes
    case False{}: no
def maximum(+a: Amount,+b: Amount) -> Amount: choose(ge(a,b),a,b)
def minimum(+a: Amount,+b: Amount) -> Amount: choose(ge(a,b),b,a)
