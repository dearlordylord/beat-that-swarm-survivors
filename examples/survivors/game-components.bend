import Base
import run-state.bend as RS

# Pure component payloads. Storage and query machinery depend on these types.
# Body is transitional only for actor paths owned by the remaining migration slices.
type Identity is Data: Identity{slot: U32}
type Body is Data: Body{x: F32,y: F32,kind: U32,variant: U32,hp: U32,maxHp: U32,age: U32,seed: U32,radius: F32}
type Vitals is Data: Vitals{health: U32,maximum: U32}
type Trajectory is Data: Trajectory{vx: F32,vy: F32,life: U32,pierce: U32,visited: List<&2,U32>,weaponOwner: U32,logicalSlot: U32,sourcePlayer: Maybe<&2,U32>}
type ShotPayload is Data: ShotPayload{weapon: U32,damage: U32,active: Bool}
type Status is Data: Status{slow: U32,burn: U32}
type PlayerRecord is Data: PlayerRecord{id: U32,player: RS.PlayerState,connected: Bool}
