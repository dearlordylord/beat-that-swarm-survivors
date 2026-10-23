# Experimental native GPU batch. Force +RTS --gpu on -RTS to reject CPU fallback.
# Host IO stays outside the marked pure computation.
import Base
import offline-batch.bend as Serial
import offline-parallel.bend as P
import parallel/scheduler.bend as Scheduler

def solve(context: P.JobContext,plan: Scheduler.Plan) -> Scheduler.Results<P.Finished>:
  Scheduler.map_parallel(~P.JobContext,~P.Finished,~P.run_job,context,plan)
def batch_numeric(count: U32,index: U32,stride: U32,seed: U32,profile: U32,ticks: U32) -> IO(Unit):
  P.emit_all(Scheduler.to_list(~P.Finished,solve!(P.JobContext{ticks,seed,profile},Scheduler.build(count,index,stride))))
def batch(count: U32,index: U32,stride: U32,seed: U32,profile: String,ticks: U32) -> IO(Unit):
  batch_numeric(count,index,stride,seed,P.profile_mode(profile),ticks)
def main() -> IO(Unit):
  do IO<Unit>:
    count : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_COUNT")
    ticks : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_TICKS")
    seed : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_SEED")
    profile : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_PROFILE")
    index : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_INDEX")
    stride : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_STRIDE")
    batch(Serial.number(Serial.environment(count),1),Serial.number(Serial.environment(index),0),Serial.number(Serial.environment(stride),1),Serial.number(Serial.environment(seed),12345),Serial.environment(profile),Serial.number(Serial.environment(ticks),1800))
