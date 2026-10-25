import Base
import ../projectile-state.bend as S
import ../projectile.bend as P

# Guarantees: constructing a projectile keeps its actual slot identity.
# Why it matters: pooled shot reuse must retain the issued entity identity used
#   by contact ordering and ownership receipts.
law created_identity:
  for +identity: U32 for side: S.Side for weapon: U32 for damage: U32 for owner: U32 for slot: U32
  for x: F32 for y: F32 for vx: F32 for vy: F32 for radius: F32 for life: U32 for pierce: U32
  {S.identity(S.created(identity,side,weapon,damage,owner,slot,P.Shot{x,y,vx,vy,radius,life,pierce})) == identity : U32}

# Guarantees: a newly constructed projectile has age zero.
# Why it matters: a reused physical shot slot must not inherit a previous
#   lifetime's collision exclusions or trajectory phase.
law created_age:
  for identity: U32 for side: S.Side for weapon: U32 for damage: U32 for owner: U32 for slot: U32
  for x: F32 for y: F32 for vx: F32 for vy: F32 for radius: F32 for life: U32 for pierce: U32
  {S.age(S.created(identity,side,weapon,damage,owner,slot,P.Shot{x,y,vx,vy,radius,life,pierce})) == 0 : U32}

# Guarantees: construction always begins with an empty visited-target list.
# Why it matters: the next volley can hit targets visited by its previous slot
#   occupant while piercing order remains local to the new lifetime.
law created_history:
  for identity: U32 for side: S.Side for weapon: U32 for damage: U32 for owner: U32 for slot: U32
  for x: F32 for y: F32 for vx: F32 for vy: F32 for radius: F32 for life: U32 for pierce: U32
  {S.visited(S.created(identity,side,weapon,damage,owner,slot,P.Shot{x,y,vx,vy,radius,life,pierce})) == [] : List<&2,U32>}

# Guarantees: explicit projectile damage is preserved at birth.
# Why it matters: damage is a projectile fact and must not be inferred from a
#   health field or dropped while constructing the first authoritative state.
law created_damage:
  for identity: U32 for side: S.Side for weapon: U32 for +damage: U32 for owner: U32 for slot: U32
  for x: F32 for y: F32 for vx: F32 for vy: F32 for radius: F32 for life: U32 for pierce: U32
  {S.damage(S.created(identity,side,weapon,damage,owner,slot,P.Shot{x,y,vx,vy,radius,life,pierce})) == damage : U32}
