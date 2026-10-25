import Base
import enemy-combat.bend as Enemy
import enemy-spatial.bend as Space
import pickup-state.bend as Pickup

# XP goes to its persistent pool; other rewards occupy the defeated enemy slot.
# The death policy already clamped these named coordinates for legal collection.
def item(kind: Enemy.DropKind,amount: U32) -> Maybe<&2,Pickup.Item>:
  match kind:
    case Enemy.XpDrop{}: None{}
    case Enemy.GoldDrop{}: Some{Pickup.Gold{amount}}
    case Enemy.HealDrop{}: Some{Pickup.Healing{amount}}
    case Enemy.ChestDrop{}: Some{Pickup.Chest{}}
def placed(payload: Maybe<&2,Pickup.Item>,x: F32,y: F32,identity: U32,generation: U32) -> Maybe<&2,Pickup.State>:
  match payload:
    case None{}: None{}
    case Some{item}: Some{Pickup.State{Space.Spatial{x,y,0,6.0},Pickup.Payload{item,generation,True{}},identity}}
def create(reward: Enemy.DeathReward,generation: U32) -> Maybe<&2,Pickup.State>:
  match reward:
    case Enemy.DeathReward{kind,amount,x,y,_,identity,_}: placed(item(kind,amount),x,y,identity,generation)
