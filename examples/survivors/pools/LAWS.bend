import Base
import ../pools.bend as P

def bit(value:Bool) -> U32:
  match value:
    case True{}: 1
    case False{}: 0
def role_count(+role:P.Role) -> U32:
  (bit(P.enemy_flag(role)) + bit(P.player_flag(role)) + bit(P.hostile_flag(role)) + bit(P.actor_flag(role)) + bit(P.xp_flag(role)) + bit(P.outside_flag(role)) : U32)

# Guarantees: every seed has exactly one role, including an explicit outside role.
# Why it matters: the entity update router cannot assign one slot to two pools.
law unique_role:
  for seed:U32
  {role_count(P.role(seed)) == 1 : U32}

# Guarantees: the allocation intervals are adjacent and exhaust exactly 1468 slots.
# Why it matters: game initialization must neither omit a pool nor overlap storage.
law contiguous_layout:
  {(P.enemy_end(),P.player_start(),P.player_end(),P.hostile_start(),P.hostile_end(),P.actor_start(),P.actor_end(),P.xp_start(),P.xp_end(),P.total_count()) == (512,512,1024,1024,1056,1056,1068,1068,1468,1468) : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}

# Guarantees: pool counts and spawn thresholds have the approved exact values.
# Why it matters: the runtime must reserve 400 XP slots while leaving boss room.
law exact_counts:
  {(P.enemy_count(),P.relic_seed(),P.player_count(),P.hostile_count(),P.actor_count(),P.xp_count(),P.owner_count(),P.logical_count(),P.normal_enemy_cap(),P.max_regular_enemies()) == (512,511,512,32,12,400,24,8,300,500) : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}

# Guarantees: the structural entity traversal visits the same count as allocation.
# Why it matters: a stale Nat traversal count would leave part of a run dormant.
law exact_traversal:
  {P.total_nat() == 1468n : Nat}

# Guarantees: no weapon cap exceeds 70, including unknown catalogue identifiers.
# Why it matters: per-weapon admission has a finite bound below the shared pool.
law bounded_weapon_cap:
  for base:U32
  {U32.is_le(P.weapon_cap(base),70) == True{} : Bool}

# Guarantees: each known weapon receives its approved cap and unknown IDs get zero.
# Why it matters: weapon tuning cannot silently fall back to an unrelated cap.
law exact_weapon_caps:
  {(P.weapon_cap(0),P.weapon_cap(1),P.weapon_cap(2),P.weapon_cap(3),P.weapon_cap(4),P.weapon_cap(5),P.weapon_cap(6),P.weapon_cap(7),P.weapon_cap(8),P.weapon_cap(9),P.weapon_cap(10),P.weapon_cap(11),P.weapon_cap(12),P.weapon_cap(13),P.weapon_cap(14),P.weapon_cap(15),P.weapon_cap(16),P.weapon_cap(17),P.weapon_cap(18),P.weapon_cap(19),P.weapon_cap(20),P.weapon_cap(21),P.weapon_cap(22),P.weapon_cap(23),P.weapon_cap(24)) == (60,60,70,40,50,60,60,50,60,40,60,60,60,60,60,60,60,60,60,40,40,40,50,60,0) : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}

# Guarantees: the exported catalogue lists exactly the approved 24 capacities.
# Why it matters: host inspection and in-core admission must share the same tuning.
law exact_catalogue:
  {P.caps() == [60,60,70,40,50,60,60,50,60,40,60,60,60,60,60,60,60,60,60,40,40,40,50,60] : List<&2,U32>}

# Guarantees: each interval includes its first/last seed and excludes the next pool.
# Why it matters: the reserved relic and all pool boundary slots route correctly.
law exact_role_boundaries:
  {(P.role(0),P.role(511),P.role(512),P.role(1023),P.role(1024),P.role(1055),P.role(1056),P.role(1067),P.role(1068),P.role(1467),P.role(1468)) == (P.Enemy{},P.Enemy{},P.PlayerShot{},P.PlayerShot{},P.Hostile{},P.Hostile{},P.Actor{},P.Actor{},P.Xp{},P.Xp{},P.Outside{}) : P.Role & P.Role & P.Role & P.Role & P.Role & P.Role & P.Role & P.Role & P.Role & P.Role & P.Role}
