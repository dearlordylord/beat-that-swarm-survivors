import Base
import parallel/affine.bend as A
import bot-window-grid.bend as Grid
import bot-window-single.bend as Single
import bot-driver.bend as Driver
import game.bend as G
import offline-policy.bend as P
import offline-coop-observe.bend as O
import bot-pacing.bend as Pacing

def point(value:P.Point) -> String:
  match value:
    case P.Point{x,y}: "[" ++ O.fbits(x) ++ "," ++ O.fbits(y) ++ "]"
def goal(value:P.Goal) -> String:
  match value:
    case P.Goal{seed,generation,kind,x,y,reward,cluster}: "[" ++ U32.show(seed) ++ "," ++ U32.show(generation) ++ "," ++ U32.show(kind) ++ "," ++ O.fbits(x) ++ "," ++ O.fbits(y) ++ "," ++ O.fbits(reward) ++ "," ++ point(cluster) ++ "]"
def choice(value:P.Choice) -> String:
  match value:
    case P.Choice{g,path,score}: "[" ++ goal(g) ++ "," ++ O.listed(~P.Point,~point,path) ++ "," ++ O.fbits(score) ++ "]"
def memory(value:P.Memory) -> String:
  match value:
    case P.Memory{current,lastPlan,lastHp,anchor,stuckSince,initialized,objectKeys,candidates}:
      "[" ++ O.optional(~P.Choice,~choice,current) ++ "," ++ U32.show(lastPlan) ++ "," ++ U32.show(lastHp) ++ "," ++ point(anchor) ++ "," ++ U32.show(stuckSince) ++ "," ++ Bool.pick(String,initialized,"true","false") ++ "," ++ O.listed(~P.Goal,~goal,objectKeys) ++ "," ++ O.listed(~P.Choice,~choice,candidates) ++ "]"
def record(cell:Grid.Cell) -> IO(Unit):
  match cell:
    case Grid.Cell{id,seed,Single.Bot{Driver.Progress{m,G.Packet{G.State{_,run,offers,snapshots,pending}},choices},_,_,_,_,_},_,done}:
      IO.print("[" ++ U32.show(id) ++ "," ++ U32.show(seed) ++ "," ++ U32.show(choices) ++ "," ++ Bool.pick(String,done,"true","false") ++ "," ++ O.run(run) ++ "," ++ O.offers(offers) ++ "," ++ O.snapshots(snapshots) ++ "," ++ O.u32s(pending) ++ "," ++ memory(m) ++ "]")
    case _: IO.die(Unit,1,"Grid equivalence probe game failure")
def records(cells:A.Tree<&1,Grid.Cell>) -> IO(Unit):
  match cells:
    case A.Empty{}: IO.pure(Unit,Unit{})
    case A.Leaf{cell}: record(cell)
    case A.Branch{left,right}:
      do IO<Unit>:
        records(left)
        records(right)
def serial_job(cell:Grid.Cell) -> Bool & Grid.Cell: Grid.advance_marked(100n,cell)
def step(serial:Bool,cells:A.Tree<&1,Grid.Cell>) -> IO(A.Tree<&1,Grid.Cell> & Bool):
  match serial:
    case True{}: Grid.report_cells(A.map_serial(~&1,~&1,~Grid.Cell,~(Bool & Grid.Cell),~serial_job,cells))
    case False{}: Grid.advance_cells(cells,100n)
def next(result:A.Tree<&1,Grid.Cell> & Bool,again:A.Tree<&1,Grid.Cell> -> IO(Unit)) -> IO(Unit):
  (cells,done) = result
  match done:
    case True{}: records(cells)
    case False{}: again(cells)
def rounds(fuel:Nat,+serial:Bool,cells:A.Tree<&1,Grid.Cell>) -> IO(Unit):
  match fuel:
    case 0n: IO.die(Unit,1,"Grid equivalence probe exhausted fuel")
    case 1n+rest:
      do IO<Unit>:
        result : A.Tree<&1,Grid.Cell> & Bool <- step(serial,cells)
        next(result,c => rounds(rest,serial,c))
def main() -> IO(Unit):
  do IO<Unit>:
    mode : Result<&1,&1,U32 & String,String> <- IO.get_env("GRID_PROBE_SERIAL")
    rounds(1300n,String.eq(Single.environment(mode),"1"),Grid.initialize(7n,10,0,12345,"advanced",0n,300,0,Pacing.Unlimited{}))
