# Independent native Bend worlds. No Node, classifier, rendering or per-job IO.
import Base
import game.bend as G
import offline-policy.bend as Policy
import offline-batch.bend as Serial
import parallel/scheduler.bend as Scheduler

def summary(+index: U32,+seed: U32,+profile: U32,+choices: U32,+ticks: U32,+run: G.Run,+rows: List<&2,G.Body>) -> String:
  match run:
    case G.Run{+phase,+tick,_,_,hp,_,xp,xpNeed,level,kills,gold,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}:
      "{\"type\":\"summary\",\"backend\":\"native\",\"policy\":\"bend-resource-memory-v1\",\"index\":" ++ U32.show(index) ++ ",\"seed\":" ++ U32.show(seed) ++ ",\"profile\":\"" ++ Serial.profile_name(profile) ++ "\",\"status\":\"completed\",\"tick\":" ++ U32.show(tick) ++ ",\"requestedTicks\":" ++ U32.show(ticks) ++ ",\"outcome\":\"" ++ Serial.outcome(U32.is_le(3,phase)) ++ "\",\"phase\":" ++ U32.show(phase) ++ ",\"hp\":" ++ U32.show(hp) ++ ",\"level\":" ++ U32.show(level) ++ ",\"xp\":" ++ U32.show(xp) ++ ",\"xpNeed\":" ++ U32.show(xpNeed) ++ ",\"kills\":" ++ U32.show(kills) ++ ",\"gold\":" ++ U32.show(gold) ++ ",\"choices\":" ++ U32.show(choices) ++ ",\"xpPiles\":" ++ U32.show(Serial.piles(rows)) ++ ",\"uncollectedBaseXp\":" ++ U32.show(Serial.xp_sum(rows)) ++ ",\"wallMs\":" ++ "null" ++ "}"

type Finished is Data:
  Complete{summary: String}
  Failed{error: String}

def simulate(+fuel: Nat,+ticks: U32,+index: U32,+seed: U32,+profile: U32,observed: Serial.BatchReady) -> Finished:
  match fuel observed:
    case _ Serial.BatchReady{_,Serial.Progress{_,G.Failed{error},_}}: Failed{"Native batch game failure: " ++ error}
    case _ Serial.BatchReady{True{},Serial.Progress{_,G.Packet{G.State{_,run,rows,_,_,_},_},choices}}: Complete{summary(index,seed,profile,choices,ticks,run,rows)}
    case 0n _: Failed{"Native batch exhausted safety fuel before requested tick horizon"}
    case 1n+rest Serial.BatchReady{False{},Serial.Progress{memory,G.Packet{G.State{world,+run,+rows,+offers,snapshots,pending},_},choices}}:
      simulate(rest,ticks,index,seed,profile,Serial.gate(ticks,Serial.next(G.run_phase(run),G.State{world,run,rows,offers,snapshots,pending},run,rows,offers,memory,choices)))
def job(+ticks: U32,+seed: U32,+profile: String,+index: U32) -> Finished:
  simulate(U32.to_nat((ticks * 4 + 100 : U32)),ticks,index,(seed + index : U32),Serial.select_profile(profile,index),Serial.gate(ticks,Serial.Progress{Policy.initial(),Serial.start(Serial.select_profile(profile,index),(seed + index : U32)),0}))
def emit(result: Finished) -> IO(Unit):
  match result:
    case Failed{error}: IO.die(Unit,1,error)
    case Complete{text}:
      do IO<Unit>:
        IO.print(text)
        IO.print_err("Completed native Bend parallel result")

type JobContext is Data: JobContext{ticks: U32,seed: U32,profile: String}
def run_job(context: JobContext,index: U32) -> Finished:
  match context:
    case JobContext{ticks,seed,profile}: job(ticks,seed,profile,index)
def emit_all(results: List<&2,Finished>) -> IO(Unit):
  match results:
    case []:
      do IO<Unit>:
        return Unit{}
    case first <> rest:
      do IO<Unit>:
        emit(first)
        emit_all(rest)
def batch(count: U32,index: U32,stride: U32,seed: U32,profile: String,ticks: U32) -> IO(Unit):
  emit_all(Scheduler.to_list(~Finished,Scheduler.map_parallel(~JobContext,~Finished,~run_job,JobContext{ticks,seed,profile},Scheduler.build(count,index,stride))))
def main() -> IO(Unit):
  do IO<Unit>:
    count : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_COUNT")
    ticks : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_TICKS")
    seed : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_SEED")
    profile : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_PROFILE")
    index : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_INDEX")
    stride : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BATCH_STRIDE")
    batch(Serial.number(Serial.environment(count),1),Serial.number(Serial.environment(index),0),Serial.number(Serial.environment(stride),1),Serial.number(Serial.environment(seed),12345),Serial.environment(profile),Serial.number(Serial.environment(ticks),1800))
