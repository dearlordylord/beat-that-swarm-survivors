# Pure presentation projection policy. Game Data extraction lives in the wire adapter.
import Base
import pickup-state.bend as Pickup
import enemy-spatial.bend as Space
import ./coop-playback.bend as P
import ./coop-combat-prediction-policy.bend as Numbers
import ./coop-prediction-replay.bend as Replay
import ./body-index.bend as BI

def enemy_generation(seed:U32,born:U32) -> String: "enemy:" ++ U32.show(seed) ++ ":" ++ U32.show(born)
def projectile_generation(hostile:Bool,+seed:U32,born:U32,weapon:U32,slot:U32,sourcePlayer:Maybe<&2,U32>) -> String:
  match hostile sourcePlayer:
    case False{} Some{player}: Replay.generation(player,born,0,weapon,slot)
    case False{} None{}: "unowned-projectile:" ++ U32.show(seed) ++ ":" ++ U32.show(born)
    case True{} _: "hostile:" ++ U32.show(seed) ++ ":" ++ U32.show(born)
def visual_owner(sourcePlayer:Maybe<&2,U32>) -> U32:
  match sourcePlayer:
    case Some{player}: player
    case None{}: 4294967295
def player_actor(+id:U32,+character:U32,x:F32,y:F32,hp:U32,connected:Bool) -> P.Actor:
  P.Actor{id,character,"player:" ++ U32.show(id) ++ ":" ++ U32.show(character),Numbers.normalize(x),Numbers.normalize(y),0,Bool.and(connected,U32.is_gt(hp,0)),id}
# Playback consumes a boolean live-identity fact for every actor.
# Actual health, damage and pickup amount remain outside this timeline record.
def projectile_actor(+hostile: Bool,+seed:U32,born:U32,weapon:U32,+slot:U32,+sourcePlayer:Maybe<&2,U32>,x:F32,y:F32,age:U32,life:U32,pierce:U32) -> P.Actor:
  +kind = Bool.pick(U32,hostile,7,1)
  P.Actor{seed,kind,projectile_generation(hostile,seed,born,weapon,slot,sourcePlayer),Numbers.normalize(x),Numbers.normalize(y),age,Bool.and(U32.is_gt(life,0),U32.is_gt(pierce,0)),visual_owner(sourcePlayer)}
def enemy_actor(+identity:U32,born:U32,x:F32,y:F32,age:U32,health:U32) -> P.Actor:
  P.Actor{identity,0,enemy_generation(identity,born),Numbers.normalize(x),Numbers.normalize(y),age,U32.is_gt(health,0),4294967295}
def pickup_kind(item:Pickup.Item) -> U32:
  match item:
    case Pickup.Xp{_,_}: 2
    case Pickup.Gold{_}: 3
    case Pickup.Healing{_}: 4
    case Pickup.Chest{}: 5
    case Pickup.Relic{_}: 9
def pickup_actor(pickup:Pickup.State) -> P.Actor:
  match pickup:
    case Pickup.State{Space.Spatial{x,y,age,_},Pickup.Payload{+item,generation,active},+key}: P.Actor{key,pickup_kind(item),"pickup:" ++ U32.show(key) ++ ":" ++ U32.show(generation),x,y,age,active,4294967295}
def birth(births:BI.Index<U32>,tick:U32,age:U32,seed:U32) -> U32: BI.get(~U32,births,seed,(tick - age : U32))
def join(first:List<&2,P.Actor>,second:List<&2,P.Actor>) -> List<&2,P.Actor>:
  List.reverse.go(&2,P.Actor,List.reverse(&2,P.Actor,first),second)
def frame(observation:U32,tick:U32,receivedAt:Nat,players:List<&2,P.Actor>,bodies:List<&2,P.Actor>,extras:List<&2,P.Actor>) -> P.Frame:
  P.Frame{observation,tick,receivedAt,players,join(bodies,extras)}
