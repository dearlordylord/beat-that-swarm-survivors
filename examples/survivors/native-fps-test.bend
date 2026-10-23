import Base
import native.bend as N
import game.bend as G
import native_draw.bend as D
import viewport.bend as V

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def counted(fuel: Nat,fps: N.Fps) -> N.Fps:
  match fuel:
    case 0n: fps
    case 1n+k: counted(k,N.fps_count(fps))
def measured(+fps: N.Fps,+value: U32) -> Bool:
  Bool.and(N.fps_ready(fps),U32.is_eq(N.fps_value(fps),value))
def rect_count(rows: List<&2,D.Rect>) -> U32:
  match rows:
    case []: 0
    case _ <> rest: (1 + rect_count(rest) : U32)
def offscreen() -> List<&2,G.Body>: [G.Body{20000.0,20000.0,0,0,10,10,0,1,12.0}]
def onscreen() -> List<&2,G.Body>: [G.Body{0.0,0.0,0,0,10,10,0,1,12.0}]
def main() -> IO(Unit):
  do IO<Unit>:
    expect(Bool.not(N.fps_ready(N.fps_initial())),"FPS starts unknown rather than claiming target rate")
    expect(Bool.not(N.fps_ready(N.fps_sample(1499n,N.Fps{1000n,30,0,False{}}))),"FPS waits for half-second wall window")
    expect(measured(N.fps_sample(1500n,counted(30n,N.Fps{1000n,0,0,False{}})),60),"30 rendered callbacks in 500ms measure 60FPS")
    expect(measured(N.fps_sample(2500n,counted(30n,N.Fps{1000n,0,0,False{}})),20),"FPS includes full wall stall instead of simulation lag clamp")
    expect(measured(N.fps_sample(1500n,N.Fps{1000n,15,60,True{}}),53),"FPS smooths measured 30FPS with previous 60FPS")
    expect(Bool.not(N.fps_ready(N.fps_sample(1000n,N.Fps{1000n,30,0,False{}}))),"zero wall interval never divides or invents FPS")
    expect(measured(N.fps_sample(1500n,N.Fps{1000n,0,0,False{}}),0),"no rendered callbacks measure zero FPS")
    expect(N.body_on_screen(V.native_x(0.0,0.0),V.native_y(0.0,0.0),12.0),"native camera center remains visible")
    expect(N.body_on_screen((0.0 - 60.0 : F32),210.0,12.0),"conservative sprite envelope keeps touching left edge")
    expect(Bool.not(N.body_on_screen((0.0 - 61.0 : F32),210.0,12.0)),"sprite beyond complete envelope is culled")
    expect(U32.is_eq(rect_count(N.body_sprites(offscreen(),0.0,0.0,[])),0),"offscreen body creates no sprite rectangles")
    expect(U32.is_eq(rect_count(N.body_healthbars(offscreen(),0.0,0.0,[])),0),"offscreen body creates no health-bar rectangles")
    expect(U32.is_lt(0,rect_count(N.body_sprites(onscreen(),0.0,0.0,[]))),"onscreen body still creates its sprite")
    expect(U32.is_lt(0,rect_count(N.body_healthbars(onscreen(),0.0,0.0,[]))),"onscreen enemy retains health bar")
