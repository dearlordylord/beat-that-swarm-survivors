import Base
import ./coop-input-queue.bend as Q
import ./coop-prediction.bend as P
import ./coop-session.bend as S
import ./player-movement.bend as M

# A chronological machine-F32 path. No vector sums or reassociation: clamping,
# normalization and rounding happen in exactly the order the world executes.
def step(+distance: F32,tick: Q.Tick,point: M.Point) -> M.Point:
  match tick point:
    case Q.Tick{_,x,y} M.Point{px,py}: M.move_point(px,py,distance,S.axis(x),S.axis(y))
def path(rows: List<&2,Q.Tick>,+distance: F32,point: M.Point) -> M.Point:
  match rows:
    case []: point
    case head <> tail: path(tail,distance,step(distance,head,point))
def state(distance: F32,rows: List<&2,P.Segment>,age: U32,observation: U32,point: M.Point) -> P.State:
  match point:
    case M.Point{x,y}: P.State{x,y,distance,True{},rows,age,observation}
def reconcile(state: P.State,observation: U32,distance: F32,receipt: S.Receipt,point: M.Point) -> M.Point:
  match point:
    case M.Point{x,y}: P.view(P.reconcile(state,observation,x,y,distance,True{},receipt))

# Count-only evidence: every pending tick has a remaining replay slot. This
# predicate contains no position, movement implementation or desired result.
def Room(rows: List<&2,Q.Tick>,+budget: U32) -> Type:
  match rows:
    case []: {0n == 0n : Nat}
    case _ <> tail: Pair({U32.is_lt(budget,1) == False{} : Bool},Room(tail,(budget - 1 : U32)))
def pending_row(tick: Q.Tick) -> P.Segment:
  match tick:
    case Q.Tick{seq,x,y}: P.Segment{seq,x,y,1,0}
def pending_rows(rows: List<&2,Q.Tick>) -> List<&2,P.Segment>:
  match rows:
    case []: []
    case head <> tail: pending_row(head) <> pending_rows(tail)
def budget_after(rows: List<&2,Q.Tick>,budget: U32) -> U32:
  match rows:
    case []: budget
    case _ <> tail: budget_after(tail,(budget - 1 : U32))
