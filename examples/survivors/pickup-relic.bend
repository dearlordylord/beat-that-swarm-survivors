import Base
import pickup-state.bend as Pickup
import enemy-spatial.bend as Space
import pickup-policy.bend as Contact

# Relics use their original fixed reach, independent of pickup/magnet bonuses.
# The collected frame is at the collector; subsequent frames are dormant at0,0.
def selected(found: Bool,stage: U32,identity: U32,generation: U32,x: F32,y: F32,px: F32,py: F32) -> Pickup.Outcome:
  match found:
    case True{}: Pickup.Outcome{Pickup.State{Space.Spatial{px,py,0,0.0},Pickup.Payload{Pickup.Relic{stage},generation,False{}},identity},Pickup.Reward{50,75,0,0,1}}
    case False{}: Pickup.Outcome{Pickup.State{Space.Spatial{x,y,0,18.0},Pickup.Payload{Pickup.Relic{stage},generation,True{}},identity},Pickup.no_reward()}
def step(alreadyCollected: Bool,stage: U32,identity: U32,generation: U32,+x: F32,+y: F32,+px: F32,+py: F32) -> Pickup.Outcome:
  match alreadyCollected:
    case True{}: Pickup.Outcome{Pickup.State{Space.Spatial{0.0,0.0,0,0.0},Pickup.Payload{Pickup.Relic{stage},0,False{}},identity},Pickup.no_reward()}
    case False{}: selected(Contact.close(x,y,px,py,30.0),stage,identity,generation,x,y,px,py)
