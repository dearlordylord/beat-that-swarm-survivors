import Base
import offline-coop-step.bend as Step
import offline-coop-journal-observe.bend as O

type Counts is Data: Counts{actions:U32,nonempty:U32,events:U32,omitted:U32}
def emitted(nextSample:Nat,counts:Counts,value:O.Capture,next:Array<Step.Progress> -> Nat -> Counts -> IO(Unit)) -> IO(Unit):
  match counts value:
    case Counts{actions,nonempty,events,omitted} O.Captured{progress,line,moreFrames,moreEvents,moreOmitted}:
      do IO<Unit>:
        IO.print(line)
        next(progress,nextSample,Counts{actions,(nonempty + moreFrames : U32),(events + moreEvents : U32),(omitted + moreOmitted : U32)})
    case _ O.Failed{message}: IO.die(Unit,1,message)
def emit(value:Array<Step.Instruction>,counts:Counts,next:Array<Step.Progress> -> Nat -> Counts -> IO(Unit)) -> IO(Unit):
  match value counts:
    case ALeaf{Step.Again{_,nextSample,progress}} Counts{+actions,nonempty,events,omitted}: emitted(nextSample,Counts{(actions + 1 : U32),nonempty,events,omitted},O.capture("journal-step",(actions + 1 : U32),progress),next)
    case ALeaf{Step.Finished{fields,outcome,tick}} Counts{actions,nonempty,events,omitted}:
      IO.print("{\"type\":\"journal-end\",\"actions\":" ++ U32.show(actions) ++ ",\"nonemptyFrames\":" ++ U32.show(nonempty) ++ ",\"eventCount\":" ++ U32.show(events) ++ ",\"omittedCount\":" ++ U32.show(omitted) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"outcome\":\"" ++ outcome ++ "\",\"summary\":{" ++ fields ++ "}}")
    case ALeaf{Step.Broken{message}} _: IO.die(Unit,1,message)
    case _ _: IO.die(Unit,1,"Journal instruction carrier must be one leaf")
def loop(fuel:Nat,+seed:U32,+index:U32,+ticks:U32,nextSample:Nat,counts:Counts,progress:Array<Step.Progress>) -> IO(Unit):
  match fuel:
    case 0n: IO.die(Unit,1,"Journal audit exhausted safety fuel")
    case 1n+rest:
      do IO<Unit>:
        instruction : Array<Step.Instruction> <- IO.pure(Array<Step.Instruction>,Step.prepare(seed,index,ticks,nextSample,progress))
        emit(instruction,counts,(progress => nextSample => counts => loop(rest,seed,index,ticks,nextSample,counts,progress)))
def launch(seedText:String,indexText:String,ticksText:String,profileText:String,character0Text:String,character1Text:String,arcana0Text:String,arcana1Text:String) -> IO(Unit):
  +advanced=String.eq(profileText,"advanced")
  +seed=Step.number(seedText,12345)
  +index=Step.number(indexText,0)
  +ticks=U32.max(1,U32.min(37000,Step.number(ticksText,7200)))
  +c0=Step.number(character0Text,Step.profile_character(advanced))
  +c1=Step.number(character1Text,Step.profile_character(advanced))
  +a0=Step.number(arcana0Text,Step.profile_arcana(advanced))
  +a1=Step.number(arcana1Text,Step.profile_arcana(advanced))
  do IO<Unit>:
    IO.print("{\"type\":\"journal-start\",\"schema\":\"bendvy-coop-step-journal-v1\",\"seed\":" ++ U32.show(seed) ++ ",\"index\":" ++ U32.show(index) ++ ",\"requestedTicks\":" ++ U32.show(ticks) ++ ",\"advanced\":" ++ Bool.pick(String,advanced,"true","false") ++ ",\"characters\":[" ++ U32.show(c0) ++ "," ++ U32.show(c1) ++ "],\"arcanas\":[" ++ U32.show(a0) ++ "," ++ U32.show(a1) ++ "]}")
    emitted(0n,Counts{0,0,0,0},O.capture("journal-initial",0,Step.initial(seed,advanced,c0,c1,a0,a1)),(progress => nextSample => counts => loop(U32.to_nat((ticks * 8 + 100 : U32)),seed,index,ticks,nextSample,counts,progress)))
def main() -> IO(Unit):
  do IO<Unit>:
    seed : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_SEED")
    index : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_INDEX")
    ticks : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_TICKS")
    profile : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_PROFILE")
    c0 : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_CHARACTER0")
    c1 : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_CHARACTER1")
    a0 : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_ARCANA0")
    a1 : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_ARCANA1")
    launch(Step.environment(seed),Step.environment(index),Step.environment(ticks),Step.environment(profile),Step.environment(c0),Step.environment(c1),Step.environment(a0),Step.environment(a1))
