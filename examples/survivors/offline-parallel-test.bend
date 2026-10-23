import Base
import offline-parallel.bend as P
import offline-batch.bend as S
import offline-policy.bend as Policy
import game.bend as G

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def failed(result: P.Finished,+message: String) -> Bool:
  match result:
    case P.Failed{actual}: String.eq(actual,message)
    case _: False{}
def completed(result: P.Finished) -> Bool:
  match result:
    case P.Complete{_}: True{}
    case _: False{}
def main() -> IO(Unit):
  do IO<Unit>:
    expect(failed(P.simulate(0n,1,0,100,0,S.gate(1,S.Progress{Policy.initial(),S.start(0,100),0})),"Native batch exhausted safety fuel before requested tick horizon"),"exhausted fuel is a failure")
    expect(failed(P.simulate(10n,1,0,100,0,S.gate(1,S.Progress{Policy.initial(),G.Failed{"test"},0})),"Native batch game failure: test"),"engine failure retained")
    expect(completed(P.simulate(0n,0,0,100,0,S.gate(0,S.Progress{Policy.initial(),S.start(0,100),0}))),"completed horizon takes precedence over exhausted fuel")
