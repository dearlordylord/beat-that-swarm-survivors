import Base
import run-state.bend as RS
import coop-core.bend as Core
import coop-hit-journal.bend as Journal
import offline-coop-step.bend as Step
import offline-policy.bend as Policy

type Info is Data: Info{text:String,nonempty:U32,events:U32,omitted:U32} Unexpected{message:String}
type Capture is Type: Captured{progress:Array<Step.Progress>,line:String,nonempty:U32,events:U32,omitted:U32} Failed{message:String}
def fbits(value:F32) -> String: U32.show(F32.bits(value))
def codes(value:String) -> String:
  match value:
    case SNil{}: ""
    case SCon{Chr{code},SNil{}}: U32.show(code)
    case SCon{Chr{code},rest}: U32.show(code) ++ "," ++ codes(rest)
def string(value:String) -> String: "[" ++ codes(value) ++ "]"
def event(value:Journal.HitEvent) -> String:
  match value:
    case Journal.HitEvent{id,tick,kind,shotId,shotSeed,targetSeed,targetGeneration,fraction,impactX,impactY,targetAtImpactX,targetAtImpactY,radius,outcome}:
      "{\"id\":" ++ string(id) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"kind\":" ++ U32.show(kind) ++ ",\"shotId\":" ++ string(shotId) ++ ",\"shotSeed\":" ++ U32.show(shotSeed) ++ ",\"targetSeed\":" ++ U32.show(targetSeed) ++ ",\"targetGeneration\":" ++ U32.show(targetGeneration) ++ ",\"fraction\":" ++ fbits(fraction) ++ ",\"impactX\":" ++ fbits(impactX) ++ ",\"impactY\":" ++ fbits(impactY) ++ ",\"targetAtImpactX\":" ++ fbits(targetAtImpactX) ++ ",\"targetAtImpactY\":" ++ fbits(targetAtImpactY) ++ ",\"radius\":" ++ fbits(radius) ++ ",\"outcome\":" ++ U32.show(outcome) ++ "}"
def events(values:List<&2,Journal.HitEvent>) -> String:
  match values:
    case []: ""
    case value <> []: event(value)
    case value <> rest: event(value) ++ "," ++ events(rest)
def info(value:Core.Observation) -> Info:
  match value:
    case Core.NoObservation{}: Info{"{\"kind\":\"none\"}",0,0,0}
    case Core.StepObservation{tick,phase,advanced,+contacts,+omitted}:
      +count=U32.from_nat(List.length(&2,Journal.HitEvent,contacts))
      Info{"{\"kind\":\"step\",\"tick\":" ++ U32.show(tick) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"advanced\":" ++ Bool.pick(String,advanced,"true","false") ++ ",\"contacts\":[" ++ events(contacts) ++ "],\"contactsOmitted\":" ++ U32.show(omitted) ++ "}",Bool.to_u32(U32.is_lt(0,count)),count,omitted}
    case _: Unexpected{"Journal capture received a non-step observation"}
def clock(state:Core.CoreState) -> Core.CoreState & (U32 & U32):
  match state:
    case Core.CoreState{world,+shared,refs,snapshots,round,required,offers,pending}: (Core.CoreState{world,shared,refs,snapshots,round,required,offers,pending},(RS.session_tick(shared),RS.session_phase(shared)))
def captured(kind:String,ordinal:U32,state:Core.CoreState,observation:Core.Observation,m0:Policy.Memory,m1:Policy.Memory,+choices0:U32,+choices1:U32,action:Maybe<&2,Step.Action>,+tick:U32,+phase:U32,value:Info) -> Capture:
  match value:
    case Info{text,nonempty,events,omitted}: Captured{ALeaf{Step.Progress{Core.CorePacket{state,observation},m0,m1,choices0,choices1,action}},"{\"type\":\"" ++ kind ++ "\",\"ordinal\":" ++ U32.show(ordinal) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"choices\":[" ++ U32.show(choices0) ++ "," ++ U32.show(choices1) ++ "],\"observation\":" ++ text ++ "}",nonempty,events,omitted}
    case Unexpected{message}: Failed{message}
def clocked_pair(kind:String,ordinal:U32,state:Core.CoreState,+observation:Core.Observation,m0:Policy.Memory,m1:Policy.Memory,choices0:U32,choices1:U32,action:Maybe<&2,Step.Action>,pair:U32 & U32) -> Capture:
  (tick,phase) = pair
  captured(kind,ordinal,state,observation,m0,m1,choices0,choices1,action,tick,phase,info(observation))
def clocked(kind:String,ordinal:U32,observation:Core.Observation,m0:Policy.Memory,m1:Policy.Memory,choices0:U32,choices1:U32,action:Maybe<&2,Step.Action>,pair:Core.CoreState & (U32 & U32)) -> Capture:
  (state,time) = pair
  clocked_pair(kind,ordinal,state,observation,m0,m1,choices0,choices1,action,time)
def packet(kind:String,ordinal:U32,m0:Policy.Memory,m1:Policy.Memory,choices0:U32,choices1:U32,action:Maybe<&2,Step.Action>,value:Core.CorePacket) -> Capture:
  match value:
    case Core.CorePacket{state,observation}: clocked(kind,ordinal,observation,m0,m1,choices0,choices1,action,clock(state))
    case Core.CoreRejected{_,message}: Failed{"Journal core rejection: " ++ message}
    case Core.CoreFailed{message}: Failed{"Journal core failure: " ++ message}
def capture(kind:String,ordinal:U32,value:Array<Step.Progress>) -> Capture:
  match value:
    case ALeaf{Step.Progress{packetValue,m0,m1,choices0,choices1,action}}: packet(kind,ordinal,m0,m1,choices0,choices1,action,packetValue)
    case _: Failed{"Journal progress carrier must be one leaf"}
