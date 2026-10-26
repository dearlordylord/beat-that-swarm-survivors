import Base
import bot-metrics.bend as M

def frames(left: Nat,+now: Nat,+tick: U32,+step: U32,state: M.State) -> M.State:
  match left:
    case 0n: state
    case 1n+rest: frames(rest,Nat.add(now,10n),(tick + step : U32),step,M.sample(Nat.add(now,10n),(tick + step : U32),state))
def checked(ok: Bool,name: String,expected: String,got: String) -> IO(Unit):
  match ok:
    case True{}: IO.pure(Unit,Unit{})
    case False{}: IO.die(Unit,1,name ++ ": expected " ++ expected ++ "; got " ++ got)
def check(name: String,+expected: String,+got: String) -> IO(Unit): checked(String.eq(expected,got),name,expected,got)
def main() -> IO(Unit):
  do IO<Unit>:
    check("initial","FPS --  TPS --  SPEED --",M.label(M.initial()))
    check("warming up","FPS --  TPS --  SPEED --",M.label(frames(49n,1000n,0,6,M.sample(1000n,0,M.initial()))))
    check("independent frames and ticks","FPS 100  TPS 600  SPEED 10.0X",M.label(frames(50n,1000n,0,6,M.sample(1000n,0,M.initial()))))
    check("rendering without simulation","FPS 100  TPS 0  SPEED 0.0X",M.label(frames(50n,1000n,0,0,M.sample(1000n,0,M.initial()))))
    check("irregular callbacks","FPS 4  TPS 240  SPEED 4.0X",M.label(M.sample(1500n,130,M.sample(1250n,70,M.sample(1000n,10,M.initial())))))
    check("next window","FPS 100  TPS 600  SPEED 10.0X",M.label(frames(50n,1500n,300,6,frames(50n,1000n,0,6,M.sample(1000n,0,M.initial())))))
    IO.print("Native bot metrics checks passed")
