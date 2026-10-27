import ../starter-mechanics.bend as SM
import Base
import ../projectile-state.bend as S
import ../projectile.bend as P
import ../enemy-spatial.bend as Space
import ../game-components.bend as Components

# Guarantees: projectile birth preserves every supplied shot, identity, side,
#   damage and ownership fact, activates the payload, and resets age/history.
# Why it matters: a reused physical slot starts exactly the requested volley,
#   without changing its damage or inheriting a previous lifetime's hits.
law created_exact:
  for +identity: U32 for +side: S.Side for +weapon: U32 for +damage: U32
  for +owner: U32 for +sourcePlayer: Maybe<&2,U32> for +slot: U32 for +x: F32 for +y: F32
  for +vx: F32 for +vy: F32 for +radius: F32 for +life: U32 for +pierce: U32
  {S.created(identity,side,weapon,damage,owner,sourcePlayer,slot,P.Shot{x,y,vx,vy,radius,life,pierce}) == S.State{Space.Spatial{x,y,0,radius},identity,side,Components.ShotPayload{weapon,damage,True{},SM.ordinary()},Components.Trajectory{vx,vy,life,pierce,[],owner,slot,sourcePlayer}} : S.State}
