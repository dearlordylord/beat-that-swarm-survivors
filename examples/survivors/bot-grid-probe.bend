import Base
import game.bend as G
import bot-driver.bend as Driver
import bot-window-grid.bend as Grid
import bot-window-single.bend as Single
import bot-pacing.bend as Pacing
import bot-metrics.bend as Metrics
import offline-policy.bend as Policy

def require(ok: Bool,message: String) -> IO(Unit):
  match ok:
    case True{}: IO.pure(Unit,Unit{})
    case False{}: IO.die(Unit,1,message)
def inspect_bot(+id: U32,seed: U32,done: Bool,bot: Single.Bot) -> IO(Unit):
  match bot:
    case Single.Bot{Driver.Progress{_,G.Packet{G.State{_,run,_,_,_}},_},_,_,_,_,_}:
      require(Bool.and(done,Bool.and(U32.is_eq(G.run_tick(run),Bool.pick(U32,U32.is_eq(id,0),1,2)),U32.is_eq(seed,(12345 + id : U32)))),"Grid world failed its tick bound or seed")
    case _: IO.die(Unit,1,"Grid world failed")
def inspect(cells: List<Grid.Cell>) -> IO(Unit):
  match cells:
    case []: IO.pure(Unit,Unit{})
    case Grid.Cell{id,seed,bot,_,done} <> rest:
      do IO<Unit>:
        inspect_bot(id,seed,done,bot)
        inspect(rest)
def finished(result: List<Grid.Cell> & Bool) -> IO(Unit):
  (cells,done) = result
  do IO<Unit>:
    require(done,"Grid did not finish all worlds")
    inspect(cells)
def probe_next(result: List<Grid.Cell> & Bool,again: List<Grid.Cell> -> IO(Unit)) -> IO(Unit):
  (cells,done) = result
  match done:
    case True{}: finished((cells,True{}))
    case False{}: again(cells)
def rounds(fuel: Nat,cells: List<Grid.Cell>) -> IO(Unit):
  match fuel:
    case 0n: IO.die(Unit,1,"Grid probe exhausted its bound")
    case 1n+rest:
      do IO<Unit>:
        next : List<Grid.Cell> & Bool <- Grid.advance_cells(cells,100n)
        probe_next(next,cells => rounds(rest,cells))
def first() -> Grid.Cell:
  Grid.Cell{0,12345,Single.Bot{Driver.Progress{Policy.initial(),Single.initial_game("fresh",12345),0},0n,0n,1,0,Pacing.Unlimited{}},Metrics.initial(),False{}}
def main() -> IO(Unit):
  rounds(8n,first() <> Grid.initialize(9n,1,12345,"fresh",0n,2,0,Pacing.Unlimited{}))
