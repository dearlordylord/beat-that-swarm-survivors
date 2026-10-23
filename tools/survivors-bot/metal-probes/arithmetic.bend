import Base
import common.bend as C
import arithmetic-core.bend as A

def solve(iterations:U32,seed:U32) -> C.Answer:A.solve(iterations,seed)
def run(+iterations:U32,seed:U32) -> IO(Unit):C.report("arithmetic",iterations,solve!(iterations,seed))
def main() -> IO(Unit):
  do IO<Unit>:
    n:Result<&1,&1,U32 & String,String> <- IO.get_env("METAL_PROBE_ITERATIONS")
    seed:Result<&1,&1,U32 & String,String> <- IO.get_env("METAL_PROBE_SEED")
    run(U32.min(4096,C.parsed(C.text(n),128)),C.parsed(C.text(seed),100))
