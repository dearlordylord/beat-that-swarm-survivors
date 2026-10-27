import Base
import starter-mechanics.bend as M

def expect(ok:Bool,label:String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def notes(owner:M.Owner) -> U32:
  match owner:
    case M.Owner{_,notes,_,_,_,_,_,_,_,_}: notes
def still(owner:M.Owner) -> U32:
  match owner:
    case M.Owner{ticks,_,_,_,_,_,_,_,_,_}: ticks
def carry(owner:M.Owner) -> F32:
  match owner:
    case M.Owner{_,_,carry,_,_,_,_,_,_,_}: carry
def combo(owner:M.Owner) -> Bool:
  match owner:
    case M.Owner{_,_,_,_,_,_,_,_,ready,_}: U32.is_lt(0,ready)
def pulse(owner:M.Owner) -> Bool:
  match owner:
    case M.Owner{_,_,_,_,_,ready,_,_,_,_}: ready
def wait(fuel:Nat,owner:M.Owner,+character:U32) -> M.Owner:
  match fuel:
    case 0n: owner
    case 1n+rest: wait(rest,M.consume_cast(M.advance(owner,character,0.0,40.0,True{}),character,False{}),character)
def auto_casts(fuel:Nat,owner:M.Owner) -> M.Owner:
  match fuel:
    case 0n: owner
    case 1n+rest: auto_casts(rest,M.consume_cast(M.advance(owner,2,0.0,40.0,False{}),2,True{}))
def echo(tick:U32) -> M.Echo: M.Echo{0,tick,10.0,20.0,15,3,1.0,1.0,1.0,1}
def fill(fuel:Nat,owner:M.Owner) -> M.Owner:
  match fuel:
    case 0n: owner
    case 1n+rest: fill(rest,M.enqueue(owner,echo(27)))
def count(rows:List<&2,M.Echo>) -> U32: U32.from_nat(List.length(&2,M.Echo,rows))
def main() -> IO(Unit):
  do IO<Unit>:
    expect(U32.is_eq(notes(auto_casts(89n,M.empty())),2),"automatic casts preserve one and two notes")
    expect(U32.is_eq(notes(auto_casts(90n,M.empty())),0),"third note consumed by one admitted cast")
    expect(U32.is_eq(notes(wait(90n,M.empty(),2)),3),"allocation rejection preserves full bank")
    expect(Bool.and(U32.is_eq(notes(M.advance(wait(45n,M.empty(),2),2,1.0,40.0,False{})),1),U32.is_eq(still(M.advance(wait(45n,M.empty(),2),2,1.0,40.0,False{})),0)),"movement clears partial timer but preserves earned notes")
    expect(U32.is_eq(notes(wait(120n,M.empty(),0)),0),"other owners do not charge notes")
    expect(F32.is_eq(carry(M.advance(M.empty(),3,1000.0,40.0,False{})),0.0),"teleport creates no trail distance")
    expect(F32.is_eq(carry(M.consume_trail(M.advance(M.advance(M.empty(),3,48.0,40.0,False{}),3,48.0,40.0,False{}),40.0,False{})),40.0),"suppressed placement caps carry at one threshold")
    expect(F32.is_eq(carry(M.consume_trail(M.advance(M.empty(),3,48.0,40.0,False{}),40.0,True{})),8.0),"admitted mark consumes one threshold")
    expect(Bool.not(pulse(wait(538n,M.empty(),1))),"three complete orbits required")
    expect(pulse(wait(539n,M.empty(),1)),"third orbit readies one pulse")
    expect(Bool.not(pulse(M.consume_bonus(wait(539n,M.empty(),1),False{},True{}))),"pulse receipt consumes readiness")
    expect(combo(M.credit(M.credit(M.credit(M.empty(),10),70),130)),"combo deadline is inclusive at 120 ticks")
    expect(Bool.not(combo(M.credit(M.credit(M.credit(M.empty(),10),70),131))),"expired combo begins a new window")
    expect(Bool.not(combo(M.consume_bonus(M.credit(M.credit(M.credit(M.empty(),10),11),12),True{},False{}))),"bonus receipt consumes combo readiness")
    expect(U32.is_eq(count(M.due(fill(20n,M.empty()),27)),8),"echo queue has eight-entry bound")
    expect(U32.is_eq(count(M.due(M.enqueue(M.empty(),echo(27)),26)),0),"echo does not fire early")
    expect(U32.is_eq(count(M.due(M.drain(M.enqueue(M.enqueue(M.empty(),echo(27)),echo(28)),27),28)),1),"drain removes due echoes and preserves future echoes")
    return Unit{}
