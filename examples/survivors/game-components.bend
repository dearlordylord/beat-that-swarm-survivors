import Base
import enemy-effects.bend as Effect
import run-state.bend as RS

# Pure component payloads. Storage and query machinery depend on these types.
# Authoritative payloads contain one named gameplay responsibility each.
type Identity is Data: Identity{slot: U32}
type Vitals is Data: Vitals{health: U32,maximum: U32}
type Trajectory is Data: Trajectory{vx: F32,vy: F32,life: U32,pierce: U32,visited: List<&2,U32>,weaponOwner: U32,logicalSlot: U32,sourcePlayer: Maybe<&2,U32>}
type ShotPayload is Data: ShotPayload{weapon: U32,damage: U32,active: Bool}
type Status is Data: Status{slow: Effect.Slow,burn: Effect.Burn}
type PlayerRecord is Data: PlayerRecord{id: U32,player: RS.PlayerState,connected: Bool,reviveTick: U32}
