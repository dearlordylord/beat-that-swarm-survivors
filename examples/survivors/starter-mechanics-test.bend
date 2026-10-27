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
    case M.Owner{_,_,_,_,_,ready,_,_,_,_}: U32.is_lt(0,ready)
def wait(fuel:Nat,owner:M.Owner,+character:U32) -> M.Owner:
  match fuel:
    case 0n: owner
    case 1n+rest: wait(rest,M.consume_cast(M.advance(owner,character,0.0,40.0,True{}),character,False{}),character)
def auto_casts(fuel:Nat,owner:M.Owner) -> M.Owner:
  match fuel:
    case 0n: owner
    case 1n+rest: auto_casts(rest,M.consume_cast(M.advance(owner,2,0.0,40.0,False{}),2,True{}))
def echo(+tick:U32) -> M.Echo: M.fresh_echo(tick,tick,10.0,20.0,15,3,1.0,1.0,1.0,1)
def fill(fuel:Nat,owner:M.Owner) -> M.Owner:
  match fuel:
    case 0n: owner
    case 1n+rest: fill(rest,M.enqueue(owner,echo(27)))
def count(rows:List<&2,M.Echo>) -> U32: U32.from_nat(List.length(&2,M.Echo,rows))
def pulse_count(value: M.Owner) -> U32:
  match value:
    case M.Owner{_,_,_,_,_,ready,_,_,_,_}: ready
def no_slots(rows:List<&2,U32>) -> Bool:
  match rows:
    case []: True{}
    case _: False{}
def same_slots(left:List<&2,U32>,right:List<&2,U32>) -> Bool:
  match left:
    case []: no_slots(right)
    case head <> tail:
      match right:
        case other <> rest: Bool.and(U32.is_eq(head,other),same_slots(tail,rest))
        case []: False{}
def remaining_is(rows:List<&2,M.Echo>,wanted:List<&2,U32>) -> Bool:
  match rows:
    case M.Echo{_,_,_,_,_,_,_,_,_,_,remaining} <> []: same_slots(remaining,wanted)
    case _: False{}
def partial_captured(rows:List<&2,M.Echo>) -> Bool:
  match rows:
    case M.Echo{27,27,x,y,15,3,speed,area,duration,1,remaining} <> []:
      Bool.and(F32.is_eq(x,10.0),Bool.and(F32.is_eq(y,20.0),Bool.and(F32.is_eq(speed,1.0),Bool.and(F32.is_eq(area,1.0),Bool.and(F32.is_eq(duration,1.0),same_slots(remaining,[0,2]))))))
    case _: False{}
def main() -> IO(Unit):
  do IO<Unit>:
    expect(U32.is_eq(pulse_count(wait(1078n,M.empty(),1)),2),"two earned orbit pulses survive allocation starvation")
    expect(U32.is_eq(pulse_count(M.consume_bonus(wait(1078n,M.empty(),1),False{},True{})),1),"one admitted orbit pulse consumes one receipt")
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
    expect(Bool.and(M.echo_full(fill(8n,M.empty())),Bool.not(M.echo_full(fill(7n,M.empty())))),"full echo queue advertises primary backpressure")
    expect(remaining_is(M.due(M.complete_echo(M.enqueue(M.empty(),echo(27)),27,[]),100),[0,1,2]),"rejected echo allocation preserves every slot")
    expect(partial_captured(M.due(M.complete_echo(M.enqueue(M.empty(),echo(27)),27,[1]),100)),"partial echo preserves origin amount and unaccepted slots")
    expect(remaining_is(M.due(M.complete_echo(M.complete_echo(M.enqueue(M.empty(),echo(27)),27,[1]),27,[1,7]),100),[0,2]),"repeated and unknown receipts do not consume another slot")
    expect(remaining_is(M.due(M.complete_echo(M.enqueue(M.enqueue(M.empty(),echo(27)),echo(28)),27,[0,1,2]),100),[0,1,2]),"completion removes only its own cast")
    expect(U32.is_eq(count(M.due(M.complete_echo(M.enqueue(M.empty(),echo(27)),27,[0,1,2]),100)),0),"completed echo leaves no retry entry")
    expect(U32.is_eq(count(M.due(M.complete_echo(fill(8n,M.empty()),99,[0,1,2]),100)),8),"unmatched cast preserves a full queue")
    expect(same_slots(M.owner_words(M.enqueue(fill(8n,M.empty()),echo(99))),M.owner_words(fill(8n,M.empty()))),"overflow cannot replace an already captured echo")
    expect(Bool.not(same_slots(M.owner_words(M.enqueue(M.empty(),echo(27))),M.owner_words(M.complete_echo(M.enqueue(M.empty(),echo(27)),27,[1])))),"owner digest distinguishes partially emitted echo slots")
    return Unit{}
