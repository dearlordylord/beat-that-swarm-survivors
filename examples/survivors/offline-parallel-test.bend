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
    case P.Failed{actual}: String.eq("Native batch game failure: " ++ actual,message)
    case P.SafetyFuel{}: String.eq("Native batch exhausted safety fuel before requested tick horizon",message)
    case _: False{}
def completed(result: P.Finished) -> Bool:
  match result:
    case P.Complete{_}: True{}
    case _: False{}
# Keep fixture inputs opaque to native lowering; accepted values remain fixed.
def checks(+seed: U32,+zeroFuel: U32,+tenFuel: U32) -> IO(Unit):
  do IO<Unit>:
    expect(failed(P.simulate(U32.to_nat(zeroFuel),1,0,seed,0,S.gate(1,S.Progress{Policy.initial(),S.start(0,seed),0})),"Native batch exhausted safety fuel before requested tick horizon"),"exhausted fuel is a failure")
    expect(failed(P.simulate(U32.to_nat(tenFuel),1,0,seed,0,S.gate(1,S.Progress{Policy.initial(),G.Failed{"test"},0})),"Native batch game failure: test"),"engine failure retained")
    expect(completed(P.simulate(U32.to_nat(zeroFuel),0,0,seed,0,S.gate(0,S.Progress{Policy.initial(),S.start(0,seed),0}))),"completed horizon takes precedence over exhausted fuel")

def input_guard(ok: Bool,+seed: U32,+zeroFuel: U32,+tenFuel: U32) -> IO(Unit):
  match ok:
    case True{}: checks(seed,zeroFuel,tenFuel)
    case False{}: IO.die(Unit,1,"Offline parallel fixtures require seed=100 and fuels=0,10")
def checked_inputs(+seed: U32,+zeroFuel: U32,+tenFuel: U32) -> IO(Unit):
  input_guard(Bool.and(U32.is_eq(seed,100),Bool.and(U32.is_eq(zeroFuel,0),U32.is_eq(tenFuel,10))),seed,zeroFuel,tenFuel)
def main() -> IO(Unit):
  do IO<Unit>:
    seed : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_TEST_SEED")
    zero : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_TEST_ZERO_FUEL")
    ten : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_TEST_TEN_FUEL")
    checked_inputs(S.number(S.environment(seed),100),S.number(S.environment(zero),0),S.number(S.environment(ten),10))
