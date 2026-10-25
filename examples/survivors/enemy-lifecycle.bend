import Base
import enemy-effects.bend as Effect
import game-components.bend as Components

# Status belongs to one enemy lifetime. Birth never accepts an old status.
type Candidate is Data: Candidate{x: F32,y: F32,archetype: U32,identity: U32,vitals: Components.Vitals,radius: F32}
type Newborn is Data: Newborn{candidate: Candidate,age: U32,status: Components.Status,contactDamage: U32,killer: Maybe<&2,U32>}
def birth(candidate: Candidate) -> Newborn:
  Newborn{candidate,0,Components.Status{Effect.empty_slow(),Effect.empty_burn()},0,None{}}
