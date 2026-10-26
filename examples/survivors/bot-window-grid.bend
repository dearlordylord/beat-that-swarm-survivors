import Base
import game.bend as G
import bot-driver.bend as Driver
import offline-policy.bend as Policy
import native.bend as N
import native_draw.bend as D
import bot-pacing.bend as Pacing
import bot-metrics.bend as Metrics
import bot-window-loop.bend as WindowLoop
import bot-window-single.bend as Single
import bot-grid-layout.bend as Layout

type Cell is Type: Cell{id: U32,seed: U32,bot: Single.Bot,metrics: Metrics.State,done: Bool}
type Grid is Type: Grid{cells: List<Cell>,count: U32,pacing: Pacing.Mode}

def initialize(fuel: Nat,+id: U32,+base: U32,+profile: String,+now: Nat,+ticks: U32,+seconds: U32,+pacing: Pacing.Mode) -> List<Cell>:
  match fuel:
    case 0n: []
    case 1n+rest:
      +seed = Layout.seed(base,id)
      Cell{id,seed,Single.Bot{Driver.Progress{Policy.initial(),Single.initial_game(profile,seed),0},now,now,ticks,seconds,pacing},Metrics.initial(),False{}} <> initialize(rest,(id + 1 : U32),base,profile,now,ticks,seconds,pacing)

def progressed(done: Bool,+ready: Bool,progress: Driver.Progress,last: Nat,started: Nat,ticks: U32,seconds: U32,pacing: Pacing.Mode,now: Nat) -> Single.Bot:
  match done:
    case True{}: Single.Bot{progress,last,started,ticks,seconds,pacing}
    case False{}: Single.Bot{Single.advanced(ready,progress),Bool.pick(Nat,ready,now,last),started,ticks,seconds,pacing}
def bounded(id: U32,seed: U32,metrics: Metrics.State,+now: Nat,+last: Nat,+started: Nat,+ticks: U32,+seconds: U32,+pacing: Pacing.Mode,result: Driver.Progress & Bool) -> Cell:
  (progress,finished) = result
  +done = Bool.or(finished,Single.timed(now,started,seconds))
  Cell{id,seed,progressed(done,Pacing.ready(pacing,now,last),progress,last,started,ticks,seconds,pacing,now),metrics,done}
def advance_cell(+now: Nat,cell: Cell) -> Cell:
  match cell:
    case Cell{id,seed,Single.Bot{progress,last,started,+ticks,seconds,pacing},metrics,False{}}:
      bounded(id,seed,metrics,now,last,started,ticks,seconds,pacing,Single.bounded(progress,ticks))
    case cell: cell

def checked(cell: Cell) -> IO(Cell):
  match cell:
    case Cell{id,_,Single.Bot{Driver.Progress{_,G.Failed{error},_},_,_,_,_,_},_,_}:
      IO.die(Cell,1,"Native bot " ++ U32.show((id + 1 : U32)) ++ " game failure: " ++ error)
    case cell: IO.pure(Cell,cell)
def completed(+id: U32,+seed: U32,metrics: Metrics.State,result: Single.Bot & U32) -> IO(Cell):
  (bot,tick) = result
  match bot:
    case Single.Bot{Driver.Progress{memory,packet,+choices},last,started,ticks,seconds,pacing}:
      do IO<Cell>:
        IO.print("Native Bend bot " ++ U32.show((id + 1 : U32)) ++ " seed " ++ U32.show(seed) ++ " completed at tick " ++ U32.show(tick) ++ ", choices " ++ U32.show(choices))
        return Cell{id,seed,Single.Bot{Driver.Progress{memory,packet,choices},last,started,ticks,seconds,pacing},metrics,True{}}
def reported(was_done: Bool,cell: Cell) -> IO(Cell):
  match was_done cell:
    case False{} Cell{id,seed,bot,metrics,True{}}: completed(id,seed,metrics,Single.bot_tick(bot))
    case _ cell: IO.pure(Cell,cell)
def advance_checked(+now: Nat,cell: Cell) -> IO(Cell):
  match cell:
    case Cell{id,seed,bot,metrics,+done}:
      do IO<Cell>:
        next : Cell <- checked(advance_cell(now,Cell{id,seed,bot,metrics,done}))
        reported(done,next)
def collected(rest: List<Cell> & Bool,cell: Cell) -> List<Cell> & Bool:
  (tail,all_done) = rest
  match cell:
    case Cell{id,seed,bot,metrics,+done}: (Cell{id,seed,bot,metrics,done} <> tail,Bool.and(done,all_done))
def advance_cells(cells: List<Cell>,+now: Nat) -> IO(List<Cell> & Bool):
  match cells:
    case []: IO.pure(List<Cell> & Bool,([],True{}))
    case cell <> rest:
      do IO<List<Cell> & Bool>:
        next : Cell <- advance_checked(now,cell)
        tail : List<Cell> & Bool <- advance_cells(rest,now)
        return collected(tail,next)
def continued(count: U32,pacing: Pacing.Mode,result: List<Cell> & Bool) -> Maybe<Grid>:
  (cells,done) = result
  match done:
    case True{}: None{}
    case False{}: Some{Grid{cells,count,pacing}}
def advance(state: Grid) -> IO(Maybe<Grid>):
  match state:
    case Grid{cells,count,pacing}:
      do IO<Maybe<Grid>>:
        now : Nat <- IO.now()
        next : List<Cell> & Bool <- advance_cells(cells,now)
        return continued(count,pacing,next)

def decorated(text: String,native: N.Native) -> N.Native & Image:
  match native:
    case N.Native{G.Packet{G.State{world,+run,+offers,+snapshots,pending}},+ui,profile}:
      (N.Native{G.Packet{G.State{world,run,offers,snapshots,pending}},ui,profile},D.image(D.text(text,8.0,6.0,1.0,15196103,D.rect(0.0,0.0,512.0,16.0,724763,D.rect(0.0,0.0,1.0,512.0,15196103,D.rect(511.0,0.0,1.0,512.0,15196103,D.rect(0.0,511.0,512.0,1.0,15196103,D.rect(0.0,384.0,512.0,128.0,725017,N.gameplay_rows(run,offers,ui,snapshots)))))))))
    case native: N.view(native)
def done_label(done: Bool) -> String:
  match done:
    case True{}: " DONE"
    case False{}: ""
def cell_drawn(id: U32,seed: U32,metrics: Metrics.State,done: Bool,result: Single.Bot & Image) -> Cell & Image:
  (bot,picture) = result
  (Cell{id,seed,bot,metrics,done},picture)
def cell_view(cell: Cell) -> Cell & Image:
  match cell:
    case Cell{+id,+seed,Single.Bot{Driver.Progress{memory,game,choices},last,started,ticks,seconds,pacing},+metrics,+done}:
      text = "BOT " ++ U32.show((id + 1 : U32)) ++ " SEED " ++ U32.show(seed) ++ done_label(done) ++ "  " ++ Metrics.label(metrics)
      cell_drawn(id,seed,metrics,done,Single.image(memory,choices,last,started,ticks,seconds,pacing,decorated(text,Single.rendering_native(game))))
def views_join(head: Cell & Image,tail: List<Cell> & List<&2,Image>) -> List<Cell> & List<&2,Image>:
  (cell,picture) = head
  (cells,pictures) = tail
  (cell <> cells,picture <> pictures)
def views(cells: List<Cell>) -> List<Cell> & List<&2,Image>:
  match cells:
    case []: ([],[])
    case cell <> rest: views_join(cell_view(cell),views(rest))
def drawn(+count: U32,pacing: Pacing.Mode,result: List<Cell> & List<&2,Image>) -> Grid & Image:
  (cells,pictures) = result
  (Grid{cells,count,pacing},Layout.image(count,pictures))
def view(state: Grid) -> Grid & Image:
  match state:
    case Grid{cells,count,pacing}: drawn(count,pacing,views(cells))

def measured(id: U32,seed: U32,metrics: Metrics.State,done: Bool,now: Nat,result: Single.Bot & U32) -> Cell:
  (bot,tick) = result
  Cell{id,seed,bot,Metrics.sample(now,tick,metrics),done}
def sample_cell(now: Nat,cell: Cell) -> Cell:
  match cell:
    case Cell{id,seed,bot,metrics,done}: measured(id,seed,metrics,done,now,Single.bot_tick(bot))
def samples(cells: List<Cell>,+now: Nat) -> List<Cell>:
  match cells:
    case []: []
    case cell <> rest: sample_cell(now,cell) <> samples(rest,now)
def presented_closed(closed: Bool,state: Grid) -> IO(Maybe<Grid>):
  match closed state:
    case True{} _: IO.pure(Maybe<Grid>,None{})
    case False{} Grid{cells,count,pacing}:
      do IO<Maybe<Grid>>:
        now : Nat <- IO.now()
        return Some{Grid{samples(cells,now),count,pacing}}
def presented(events: List<Event>,state: Grid) -> IO(Maybe<Grid>): presented_closed(Single.closes(events),state)
def realtime_next(next: Maybe<Grid>) -> IO(Maybe<Grid>):
  match next:
    case None{}: IO.pure(Maybe<Grid>,None{})
    case Some{state}: advance(state)
def tick(events: List<Event>,state: Grid) -> IO(Maybe<Grid>):
  do IO<Maybe<Grid>>:
    next : Maybe<Grid> <- presented(events,state)
    realtime_next(next)
def run(+mode: Pacing.Mode,+count: U32,state: Grid) -> IO(Unit):
  match mode:
    case Pacing.Realtime{}: App.run(~Grid,~App{view,tick},"Nightfall - Bend Bot Grid",1024,Layout.height(count),state)
    case Pacing.Unlimited{}: WindowLoop.run(~Grid,~App{view,presented},~advance,"Nightfall - Bend Bot Grid",1024,Layout.height(count),state)
def configured(+count: U32) -> IO(Unit):
  do IO<Unit>:
    profile : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_PROFILE")
    seed : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_SEED")
    ticks : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_TICKS")
    seconds : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_SECONDS")
    pacing : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_PACING")
    +mode : Pacing.Mode = Pacing.parse(Single.environment(pacing))
    now : Nat <- IO.now()
    run(mode,count,Grid{initialize(U32.to_nat(count),0,Single.number(Single.environment(seed),12345),Single.environment(profile),now,Single.number(Single.environment(ticks),0),Single.number(Single.environment(seconds),0),mode),count,mode})
def bounded_count(valid: Bool,count: U32) -> IO(Unit):
  match valid:
    case True{}: configured(count)
    case False{}: IO.die(Unit,1,"Native bot count must be between 1 and 64")

def main(+count: U32) -> IO(Unit):
  match count:
    case 0: IO.die(Unit,1,"Native bot count must be between 1 and 64")
    case count: bounded_count(U32.is_le(count,64),count)
