import Base
import arena.bend as A
import encounters.bend as E
import player-movement.bend as M
import prediction-spawn.bend as P
import spawn-policy.bend as S
import native_art.bend as Art
import native_draw.bend as D
import viewport.bend as V

# Executes the actual native display list at adversarial predicted cameras.
# This is numerical integration evidence, not a universal float proof.
def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def clear_rectangles(rows: List<&2,D.Rect>) -> Bool:
  match rows:
    case []: True{}
    case D.Rect{+x,+y,w,h,_} <> rest:
      Bool.and(Bool.or(Bool.or(F32.is_le((x + w : F32),0.0),F32.is_le(V.native_image_extent(),x)),Bool.or(F32.is_le((y + h : F32),0.0),F32.is_le(V.native_image_extent(),y))),clear_rectangles(rest))
def appearance(point: S.Point,camera: M.Point,variant: U32,+radius: F32) -> Bool:
  match point camera:
    case S.Point{x,y} M.Point{px,py}:
      +sx = V.native_x(x,px)
      +sy = V.native_y(y,py)
      +scaled = F32.max(2.0,(radius * V.native_scale() : F32))
      clear_rectangles(Art.health_bar(0,100,100,sx,sy,scaled,Art.sprite(0,variant,sx,sy,scaled,16777215,[])))
def predicted(remaining: Nat,point: M.Point,+distance: F32,+dx: F32,+dy: F32) -> M.Point:
  match remaining point:
    case 0n point: point
    case 1n++k M.Point{x,y}: predicted(k,M.move_point(x,y,distance,dx,dy),distance,dx,dy)
def camera_case(+point: S.Point,+px: F32,+py: F32,+distance: F32,variant: U32,radius: F32,dx: F32,dy: F32) -> Bool:
  appearance(point,predicted(U32.to_nat(M.horizon()),M.Point{px,py},distance,dx,dy),variant,radius)
def directions(+point: S.Point,+px: F32,+py: F32,+distance: F32,+variant: U32,+radius: F32) -> Bool:
  Bool.and(camera_case(point,px,py,distance,variant,radius,1.0,0.0),Bool.and(camera_case(point,px,py,distance,variant,radius,(0.0 - 1.0 : F32),0.0),Bool.and(camera_case(point,px,py,distance,variant,radius,0.0,1.0),Bool.and(camera_case(point,px,py,distance,variant,radius,0.0,(0.0 - 1.0 : F32)),Bool.and(camera_case(point,px,py,distance,variant,radius,1.0,1.0),Bool.and(camera_case(point,px,py,distance,variant,radius,(0.0 - 1.0 : F32),1.0),Bool.and(camera_case(point,px,py,distance,variant,radius,1.0,(0.0 - 1.0 : F32)),camera_case(point,px,py,distance,variant,radius,(0.0 - 1.0 : F32),(0.0 - 1.0 : F32)))))))))
def candidate_admitted(point: S.Point,+px: F32,+py: F32,+distance: F32,+radius: F32) -> Bool:
  match point:
    case S.Point{x,y}: P.admissible(x,y,P.Camera{px,py,distance},radius)
def seed_cases(remaining: Nat,+px: F32,+py: F32,+distance: F32,+variant: U32,+radius: F32) -> Bool:
  match remaining:
    case 0n: True{}
    case 1n++ +remaining:
      +k = U32.from_nat(remaining)
      +point = P.choose(k,k,P.Camera{px,py,distance},radius)
      Bool.and(candidate_admitted(point,px,py,distance,radius),Bool.and(directions(point,px,py,distance,variant,radius),seed_cases(remaining,px,py,distance,variant,radius)))
def positions(+variant: U32,+radius: F32,+distance: F32) -> Bool:
  Bool.and(seed_cases(24n,A.player_min(),A.player_min(),distance,variant,radius),Bool.and(seed_cases(24n,A.player_max(),A.player_max(),distance,variant,radius),Bool.and(seed_cases(24n,A.player_min(),A.player_max(),distance,variant,radius),Bool.and(seed_cases(24n,A.player_max(),A.player_min(),distance,variant,radius),seed_cases(24n,A.center(),A.center(),distance,variant,radius)))))
def corners(+radius: F32) -> Bool:
  +gap = F32.max(0.0,(A.envelope(radius) - A.player_min() : F32))
  +reach = (radius + 10.0 : F32)
  F32.is_le((2.0 * gap * gap : F32),(reach * reach : F32))
def variants(remaining: Nat) -> Bool:
  match remaining:
    case 0n: True{}
    case 1n++ +remaining:
      +k = U32.from_nat(remaining)
      +radius = E.radius(k)
      Bool.and(corners(radius),Bool.and(positions(k,radius,0.0),Bool.and(positions(k,radius,4.0),Bool.and(positions(k,radius,16.0),variants(remaining)))))
def main() -> IO(Unit):
  do IO<Unit>:
    expect(F32.is_eq(A.player_max(),(A.size() - A.player_min() : F32)),"encoded player endpoint matches arena extent")
    expect(variants(31n),"catalog corner melee reach, admitted spawns, native sprites/shadows/health bars outside predicted cameras")
