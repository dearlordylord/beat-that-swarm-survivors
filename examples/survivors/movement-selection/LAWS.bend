import Base
import ../movement-membership.bend as M
import ../pools.bend as P
import ../entity-role.bend as R

# Guarantees: movement admits exactly enemy-pool identities with enemy kind.
# Why it matters: membership must include newly born enemies and exclude drops
#   and dormant incarnations before the next movement pass begins.
law exact_movement_scope:
  for kind: U32
  for seed: U32
  {M.active(kind,seed) == Bool.and(P.is_enemy_pool(seed),U32.is_eq(kind,0)) : Bool}

# Guarantees: collecting lifecycle outputs preserves their order across batches.
# Why it matters: filtering inactive rows cannot reorder movement writes and
#   therefore cannot change their lifecycle stamps or transactional order.
law roster_batch_order:
  for ~H: Data
  for +left: List<&2,Maybe<&2,H>>
  for +right: List<&2,Maybe<&2,H>>
  {M.outputs(~H,List.append(&2,Maybe<&2,H>,left,right)) == List.append(&2,H,M.outputs(~H,left),M.outputs(~H,right)) : List<&2,H>}

# Guarantees: a sole active lifecycle result survives collection unchanged.
# Why it matters: the first enemy born into an empty run must move next tick;
#   a collector dropping every result would otherwise preserve batch order.
law roster_retains_active:
  for ~H: Data
  for +handle: H
  {M.outputs(~H,[Some{handle}]) == [handle] : List<&2,H>}

# Guarantees: the role-based movement predicate requires an enemy incarnation.
# Why it matters: dormant identities and physical pickups cannot move as enemies.
law exact_role_scope:
  for +role: R.Role
  for +kind: U32
  {M.active_role(role,kind) == Bool.and(R.enemy(role),U32.is_eq(kind,0)) : Bool}

# Guarantees: assigned roles preserve the old movement selection for every seed.
# Why it matters: removing numeric dispatch cannot omit or add a moving identity.
law assigned_role_equivalence:
  for +kind: U32
  for +seed: U32
  {M.active_role(R.assigned(seed),kind) == M.active(kind,seed) : Bool}
