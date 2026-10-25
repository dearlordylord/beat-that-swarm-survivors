import Base

# Status belongs to one enemy lifetime. Birth never accepts an old status.
type Status is Data: Status{slow: U32,burn: U32}
type Vitals is Data: Vitals{health: U32,maximum: U32}
type Candidate is Data: Candidate{x: F32,y: F32,archetype: U32,identity: U32,vitals: Vitals,radius: F32}
type Newborn is Data: Newborn{candidate: Candidate,age: U32,status: Status,contactDamage: U32,killer: Maybe<&2,U32>}
def birth(candidate: Candidate) -> Newborn:
  Newborn{candidate,0,Status{0,0},0,None{}}
