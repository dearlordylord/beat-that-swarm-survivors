import Base
import native-bot.bend as V
import bot-actions.bend as B
import game.bend as G
import native.bend as N

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def check(state: V.Bot,+sequence: U32,+tick: U32,+left: U32) -> IO(V.Bot):
  match state:
    case V.Bot{G.Packet{G.State{world,+run,rows,offers,snapshots,pending},frame},directory,+actualSequence,published,+actualLeft,dx,dy,last}:
      do IO<V.Bot>:
        expect(Bool.and(U32.is_eq(sequence,actualSequence),Bool.and(U32.is_eq(tick,N.run_tick(run)),U32.is_eq(left,actualLeft))),"native command lifecycle")
        return V.Bot{G.Packet{G.State{world,run,rows,offers,snapshots,pending},frame},directory,actualSequence,published,actualLeft,dx,dy,last}
    case _: IO.die(V.Bot,1,"Native engine failure")
def main() -> IO(Unit):
  do IO<Unit>:
    expect(U32.is_eq(V.seed_value(""),12345),"missing seed defaults safely")
    expect(U32.is_eq(V.seed_value("invalid"),12345),"invalid seed defaults safely")
    expect(U32.is_eq(V.seed_value("4294967296"),12345),"overflow seed defaults safely")
    expect(U32.is_eq(V.seed_value("-1"),12345),"negative seed defaults safely")
    expect(U32.is_eq(V.seed_value("0"),0),"zero seed accepted")
    expect(U32.is_eq(V.seed_value("4294967295"),4294967295),"maximum U32 seed accepted")
    expect(Bool.not(V.valid_move(V.parse("0\n2001\n1000\n0\n6\n"))),"out-of-range direction rejected")
    expect(Bool.not(V.valid_move(V.parse("0\n1000\n1000\n0\n31\n"))),"unbounded horizon rejected")
    expect(Bool.not(V.valid_move(V.parse("0\n1000\n1000\n0\n0\n"))),"zero horizon rejected")
    expect(Bool.not(V.valid_move(V.parse("truncated"))),"partial command rejected")
    state : V.Bot <- check(V.command(V.Bot{B.fresh_start(),"unused",1,1,0,0.0,0.0,0n},V.parse("1\n1000\n1000\n99\n1\n")),1,0,0)
    state : V.Bot <- check(V.command(state,V.parse("0\n1500\n1000\n0\n2\n")),1,0,2)
    state : V.Bot <- check(V.step(15n,state),1,0,2)
    state : V.Bot <- check(V.step(16n,state),1,1,1)
    state : V.Bot <- check(V.step(32n,state),2,2,0)
    state : V.Bot <- check(V.step(48n,state),2,2,0)
    IO.print("PASS visible native protocol fixture (fresh real engine, no injected state)")
