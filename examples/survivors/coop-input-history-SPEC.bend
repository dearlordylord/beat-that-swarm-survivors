import Base
import ./coop-prediction.bend as P
import ./player-movement.bend as M
import ./coop-session.bend as S

# Count world steps structurally, using the same saturating one-tick clock as
# production. This does not identify packet sequences with simulation time.
def tick_after(fuel:Nat,worldTick:U32) -> U32:
  match fuel:
    case 0n: worldTick
    case 1n+rest: tick_after(rest,P.after(worldTick,1))

# The movement adapter used to compare generic cohort replay with camera replay.
# Both use the shared machine-F32 step, preserving rounding/clamping order.
type Moving is Data: Moving{distance:F32,point:M.Point}
def movement(+state:Moving,+x:U32,+y:U32) -> Moving:
  match state:
    case Moving{+distance,M.Point{px,py}}: Moving{distance,M.move_point(px,py,distance,S.axis(x),S.axis(y))}

# An independent count-only reference for an interval without any own input.
# Even an empty interval of command rows still contains real simulation steps.
def neutral_worlds(~A:Data,~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A,fuel:Nat,frame:A) -> A:
  match fuel:
    case 0n: frame
    case 1n+rest: neutral_worlds(~A,~advance,rest,advance(frame,1,1))
