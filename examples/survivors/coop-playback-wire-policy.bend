# Pure presentation projection policy. Game Data extraction lives in the wire adapter.
import Base
import ./coop-playback.bend as P
import ./coop-combat-prediction-policy.bend as Numbers
import ./coop-prediction-replay.bend as Replay
import ./body-index.bend as BI

def generation(kind:U32,+seed:U32,born:U32,weapon:U32,+slot:U32) -> String:
  match kind:
    case 1: Replay.generation((slot / 65536 : U32),born,0,weapon,slot)
    case 0: "enemy:" ++ U32.show(seed) ++ ":" ++ U32.show(born)
    case _: "hostile:" ++ U32.show(seed) ++ ":" ++ U32.show(born)
def visual_owner(kind:U32,slot:U32) -> U32: Bool.pick(U32,U32.is_eq(kind,1),(slot / 65536 : U32),4294967295)
def player_actor(+id:U32,+character:U32,x:F32,y:F32,hp:U32,connected:Bool) -> P.Actor:
  P.Actor{id,character,"player:" ++ U32.show(id) ++ ":" ++ U32.show(character),Numbers.normalize(x),Numbers.normalize(y),0,Bool.and(connected,U32.is_gt(hp,0)),id}
# Playback consumes a boolean live-identity fact for every actor.
# Actual health, damage and pickup amount remain outside this timeline record.
def body_liveness(+kind:U32,hp:U32,life:U32,pierce:U32) -> Bool:
  Bool.pick(Bool,Bool.or(U32.is_eq(kind,1),U32.is_eq(kind,7)),Bool.and(U32.is_gt(life,0),U32.is_gt(pierce,0)),U32.is_gt(hp,0))
def projectile_actor(hostile: Bool,+seed:U32,born:U32,weapon:U32,+slot:U32,x:F32,y:F32,age:U32,life:U32,pierce:U32) -> P.Actor:
  +kind = Bool.pick(U32,hostile,7,1)
  P.Actor{seed,kind,generation(kind,seed,born,weapon,slot),Numbers.normalize(x),Numbers.normalize(y),age,Bool.and(U32.is_gt(life,0),U32.is_gt(pierce,0)),visual_owner(kind,slot)}
def body_actor(+seed:U32,+kind:U32,born:U32,weapon:U32,+slot:U32,x:F32,y:F32,age:U32,hp:U32,life:U32,pierce:U32) -> P.Actor:
  P.Actor{seed,kind,generation(kind,seed,born,weapon,slot),Numbers.normalize(x),Numbers.normalize(y),age,body_liveness(kind,hp,life,pierce),visual_owner(kind,slot)}
def birth(births:BI.Index<U32>,tick:U32,age:U32,seed:U32) -> U32: BI.get(~U32,births,seed,(tick - age : U32))
def extra_selected(keep:Bool,key:U32,+kind:U32,variant:U32,x:F32,y:F32,+age:U32,hp:U32,tick:U32) -> Maybe<&2,P.Actor>:
  match keep:
    case False{}: None{}
    case True{}: Some{P.Actor{key,kind,"item:" ++ U32.show(kind) ++ ":" ++ U32.show(variant) ++ ":" ++ U32.show((tick - age : U32)),Numbers.normalize(x),Numbers.normalize(y),age,U32.is_gt(hp,0),4294967295}}
def extra_actor(key:U32,+kind:U32,variant:U32,x:F32,y:F32,age:U32,hp:U32,tick:U32) -> Maybe<&2,P.Actor>:
  extra_selected(Bool.not(Numbers.cohort_kind(kind)),key,kind,variant,x,y,age,hp,tick)
def join(first:List<&2,P.Actor>,second:List<&2,P.Actor>) -> List<&2,P.Actor>:
  List.reverse.go(&2,P.Actor,List.reverse(&2,P.Actor,first),second)
def frame(observation:U32,tick:U32,receivedAt:Nat,players:List<&2,P.Actor>,bodies:List<&2,P.Actor>,extras:List<&2,P.Actor>) -> P.Frame:
  P.Frame{observation,tick,receivedAt,players,join(bodies,extras)}
