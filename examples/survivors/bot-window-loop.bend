import Base
import bot-pacing.bend as Pacing

def presented(~S: Type,rest: Nat -> Window -> S -> IO(Unit),window: Window,state: S) -> IO(Unit):
  do IO<Unit>:
    now : Nat <- IO.now()
    rest(now)(window)(state)
def turn(~S: Type,~app: App<S>,~advance: S -> IO(Maybe<S>),draw: Bool,window: Window,state: S,shown: Window -> S -> IO(Unit),rest: Window -> S -> IO(Unit)) -> IO(Unit):
  match draw:
    case True{}: App.step(S,app,window,state,shown)
    case False{}:
      do IO<Unit>:
        next : Maybe<S> <- advance(state)
        App.next(S,window,rest,next)
def loop(~S: Type,~app: App<S>,~advance: S -> IO(Maybe<S>),fuel: Nat,+last: Nat,window: Window,state: S) -> IO(Unit):
  match fuel:
    case 0n: Window.close(window)
    case 1n+ +rest:
      do IO<Unit>:
        now : Nat <- IO.now()
        turn(~S,~app,~advance,Pacing.render_due(now,last),window,state,
          w => s => presented(~S,n => w => s => loop(~S,~app,~advance,rest,n,w,s),w,s),
          w => s => loop(~S,~app,~advance,rest,last,w,s))
def run(~S: Type,~app: App<S>,~advance: S -> IO(Maybe<S>),title: String,width: U32,height: U32,state: S) -> IO(Unit):
  do IO<Unit>:
    window : Window <- IO.try(Window,Window.open(title,width,height))
    loop(~S,~app,~advance,4294967295n,0n,window,state)
