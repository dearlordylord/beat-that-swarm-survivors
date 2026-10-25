import pickup-state.bend as Pickup
import enemy-spatial.bend as Space
import pools.bend as Pool
import Base
import game-components.bend as Components
import game.bend as G
import native.bend as N
import native_draw.bend as D
import native-capture.bend as Capture
import loot-visual.bend as V

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def pile(x: F32,amount: U32,marked: Bool,slot: U32) -> Pickup.State:
  Pickup.State{Space.Spatial{x,1800.0,1000,6.0},Pickup.Payload{Pickup.Xp{amount,marked},10,True{}},slot}
def gems(rows: List<&2,Pickup.State>) -> List<&2,D.Rect>:
  match rows:
    case []: []
    case head <> rest: N.pickup_sprite(head,1800.0,1800.0,gems(rest))
def gem(amount: U32,variant: U32) -> List<&2,D.Rect>:
  gems([pile(1800.0,amount,U32.is_eq(variant,1),Pool.xp_start())])
def max_width(rows: List<&2,D.Rect>,width: F32) -> F32:
  match rows:
    case []: width
    case D.Rect{_,_,w,_,_} <> rest: max_width(rest,F32.max(w,width))
def colored(rows: List<&2,D.Rect>,+color: U32) -> Bool:
  match rows:
    case []: False{}
    case D.Rect{_,_,_,_,found} <> rest: Bool.or(U32.is_eq(found,color),colored(rest,color))
def main() -> IO(Unit):
  do IO<Unit>:
    expect(F32.is_lt(max_width(gem(2,0),0.0),max_width(gem(25,0),0.0)),"native XP grows with amount")
    expect(F32.is_eq(max_width(gem(100,0),0.0),max_width(gem(4000000,0),0.0)),"native XP size stops at cap")
    expect(colored(gem(2,0),V.color(2)),"native ordinary low XP is blue")
    expect(colored(gem(6,0),V.color(6)),"native ordinary middle XP is green")
    expect(colored(gem(10,0),V.color(10)),"native ordinary high XP is red")
    expect(colored(gem(4,1),V.tier_color(2)),"native overflow is red even below ordinary red threshold")
    Capture.save("experience-piles.ppm",D.image(gems([pile(1650.0,2,False{},Pool.xp_start()),pile(1725.0,6,False{},(Pool.xp_start() + 1 : U32)),pile(1800.0,25,False{},(Pool.xp_start() + 2 : U32)),pile(1875.0,100,True{},(Pool.xp_start() + 3 : U32)),pile(1950.0,4000000,True{},(Pool.xp_start() + 4 : U32))])))
