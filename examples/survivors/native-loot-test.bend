import Base
import game.bend as G
import native.bend as N
import native_draw.bend as D
import native-capture.bend as Capture
import loot-visual.bend as V

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def gem(amount: U32,variant: U32) -> List<&2,D.Rect>:
  N.body_sprites([G.Body{1800.0,1800.0,2,variant,amount,10,1000,G.pool_xp_start(),6.0}],1800.0,1800.0,[])
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
    Capture.save("experience-piles.ppm",D.image(N.body_sprites([G.Body{1650.0,1800.0,2,0,2,10,0,G.pool_xp_start(),6.0},G.Body{1725.0,1800.0,2,0,6,10,0,(G.pool_xp_start() + 1 : U32),6.0},G.Body{1800.0,1800.0,2,0,25,10,0,(G.pool_xp_start() + 2 : U32),6.0},G.Body{1875.0,1800.0,2,1,100,10,0,(G.pool_xp_start() + 3 : U32),6.0},G.Body{1950.0,1800.0,2,1,4000000,10,0,(G.pool_xp_start() + 4 : U32),6.0}],1800.0,1800.0,[])))
