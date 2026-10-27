import Base
import bot-window-single.bend as Single
import bot-driver.bend as Driver
import bot-pacing.bend as Pacing
import bot-metrics.bend as Metrics
import offline-policy.bend as Policy

type Session is Data: Session{profile: String,seed: U32,run: U32,started: Nat,seconds: U32,ticks: U32}
type Stream is Type: Stream{monitor: Single.Monitor,session: Session}

def new_monitor(+profile: String,seed: U32,+now: Nat,ticks: U32) -> Single.Monitor:
  Single.Monitor{Single.Bot{Driver.Progress{Policy.initial(),Single.initial_game(profile,seed),0},now,now,ticks,0,Pacing.Realtime{}},Metrics.initial()}
def announced(+session: Session) -> IO(Unit):
  match session:
    case Session{_,seed,run,_,_,_}: IO.print("Stream run " ++ U32.show(run) ++ " seed " ++ U32.show(seed))
def wrapped(session: Session,result: Single.Monitor & Image) -> Stream & Image:
  (monitor,image) = result
  (Stream{monitor,session},image)
def view(state: Stream) -> Stream & Image:
  match state:
    case Stream{monitor,session}: wrapped(session,Single.monitor_view(monitor))
def restarted(+session: Session) -> IO(Maybe<Stream>):
  match session:
    case Session{+profile,+seed,+run,+started,+seconds,+ticks}:
      do IO<Maybe<Stream>>:
        now : Nat <- IO.now()
        +next : Session <- IO.pure(Session,Session{profile,(seed + 1 : U32),(run + 1 : U32),started,seconds,ticks})
        announced(next)
        return Some{Stream{new_monitor(profile,(seed + 1 : U32),now,ticks),next}}
def continued(session: Session,result: Maybe<Single.Monitor>) -> IO(Maybe<Stream>):
  match result:
    case Some{monitor}: IO.pure(Maybe<Stream>,Some{Stream{monitor,session}})
    case None{}: restarted(session)
def expired(+session: Session,now: Nat) -> Bool:
  match session:
    case Session{_,_,_,started,seconds,_}: Single.timed(now,started,seconds)
def advance(stopped: Bool,state: Stream) -> IO(Maybe<Stream>):
  match stopped state:
    case True{} _: IO.pure(Maybe<Stream>,None{})
    case False{} Stream{monitor,session}:
      do IO<Maybe<Stream>>:
        next : Maybe<Single.Monitor> <- Single.monitor_tick([],monitor)
        continued(session,next)
def timed_tick(closed: Bool,+now: Nat,state: Stream) -> IO(Maybe<Stream>):
  match state:
    case Stream{monitor,+session}: advance(Bool.or(closed,expired(session,now)),Stream{monitor,session})
def tick(events: List<Event>,state: Stream) -> IO(Maybe<Stream>):
  do IO<Maybe<Stream>>:
    now : Nat <- IO.now()
    timed_tick(Single.closes(events),now,state)
def main() -> IO(Unit):
  do IO<Unit>:
    profile : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_PROFILE")
    seed : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_SEED")
    ticks : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_TICKS")
    seconds : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_SECONDS")
    +now : Nat <- IO.now()
    +mode : String <- IO.pure(String,Single.environment(profile))
    +chosenSeed : U32 <- IO.pure(U32,Single.number(Single.environment(seed),12345))
    +runTicks : U32 <- IO.pure(U32,Single.number(Single.environment(ticks),0))
    +session : Session <- IO.pure(Session,Session{mode,chosenSeed,1,now,Single.number(Single.environment(seconds),0),runTicks})
    announced(session)
    App.run(~Stream,~App{view,tick},"B.T.S: Beat That Swarm - Survivors",1024,768,Stream{new_monitor(mode,chosenSeed,now,runTicks),session})
