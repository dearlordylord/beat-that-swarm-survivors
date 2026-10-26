import Base
import offline-coop-step.bend as Step

def sample(line:Maybe<&2,String>,progress:Array<Step.Progress>,nextSample:Nat,next:Array<Step.Progress> -> Nat -> IO(Unit)) -> IO(Unit):
  match line:
    case None{}: next(progress,nextSample)
    case Some{text}:
      do IO<Unit>:
        IO.print("{\"type\":\"sample\"," ++ text ++ "}")
        IO.print_err("Co-op balance sample")
        next(progress,nextSample)
def emit(seed:U32,started:Nat,value:Array<Step.Instruction>,next:Array<Step.Progress> -> Nat -> IO(Unit)) -> IO(Unit):
  match value:
    case ALeaf{Step.Again{line,nextSample,progress}}: sample(line,progress,nextSample,next)
    case ALeaf{Step.Finished{fields,outcome,tick}}:
      do IO<Unit>:
        now : Nat <- IO.now()
        IO.print("{\"type\":\"summary\"," ++ fields ++ ",\"outcome\":\"" ++ outcome ++ "\",\"wallMs\":" ++ Nat.show(Nat.sub(now,started)) ++ "}")
        IO.print_err("Completed native co-op seed " ++ U32.show(seed) ++ " at tick " ++ U32.show(tick))
    case ALeaf{Step.Broken{message}}: IO.die(Unit,1,message)
    case _: IO.die(Unit,1,"Native co-op instruction carrier must be one leaf")
def loop(fuel:Nat,+seed:U32,+index:U32,+ticks:U32,+started:Nat,nextSample:Nat,progress:Array<Step.Progress>) -> IO(Unit):
  match fuel:
    case 0n: IO.die(Unit,1,"Native co-op exhausted safety fuel")
    case 1n+rest:
      do IO<Unit>:
        instruction : Array<Step.Instruction> <- IO.pure(Array<Step.Instruction>,Step.prepare(seed,index,ticks,nextSample,progress))
        emit(seed,started,instruction,(progress => nextSample => loop(rest,seed,index,ticks,started,nextSample,progress)))
def launch(seedText:String,indexText:String,ticksText:String,profileText:String,character0Text:String,character1Text:String,arcana0Text:String,arcana1Text:String,started:Nat) -> IO(Unit):
  +advanced=String.eq(profileText,"advanced")
  +seed=Step.number(seedText,12345)
  index=Step.number(indexText,0)
  +ticks=U32.max(1,U32.min(37000,Step.number(ticksText,7200)))
  loop(U32.to_nat((ticks * 8 + 100 : U32)),seed,index,ticks,started,0n,Step.initial(seed,advanced,Step.number(character0Text,Step.profile_character(advanced)),Step.number(character1Text,Step.profile_character(advanced)),Step.number(arcana0Text,Step.profile_arcana(advanced)),Step.number(arcana1Text,Step.profile_arcana(advanced))))
def audit_mode(mode:String,next:Unit -> IO(Unit)) -> IO(Unit):
  match mode:
    case "": next(Unit{})
    case "off": next(Unit{})
    case _: IO.die(Unit,1,"Use offline-coop-audit.bend for audit captures")
def main() -> IO(Unit):
  do IO<Unit>:
    seedText : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_SEED")
    indexText : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_INDEX")
    ticksText : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_TICKS")
    profileText : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_PROFILE")
    character0Text : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_CHARACTER0")
    character1Text : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_CHARACTER1")
    arcana0Text : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_ARCANA0")
    arcana1Text : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_ARCANA1")
    auditText : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_AUDIT")
    started : Nat <- IO.now()
    audit_mode(Step.environment(auditText),_ => launch(Step.environment(seedText),Step.environment(indexText),Step.environment(ticksText),Step.environment(profileText),Step.environment(character0Text),Step.environment(character1Text),Step.environment(arcana0Text),Step.environment(arcana1Text),started))
