import Base
import ../entity-role.bend as R
import ../pools.bend as P

# Guarantees: reserving a relic identity does not remove it from enemy storage.
# Why it matters: lifecycle replacements must retain the original movement scope.
law relic_retains_enemy_storage:
  for +flag: Bool
  {R.enemy(R.enemy_slot(flag)) == True{} : Bool}

# Guarantees: each allocated role retains its original projectile responsibility.
# Why it matters: free projectile identities must remain eligible for births.
law projectile_assignment:
  for +role: P.Role
  for seed: U32
  {R.projectile(R.assigned_role(role,seed)) == Bool.or(P.player_flag(role),P.hostile_flag(role)) : Bool}

# Guarantees: each allocated role retains its original enemy responsibility.
# Why it matters: the immutable role cannot silently exclude a live enemy.
law enemy_assignment:
  for +role: P.Role
  for seed: U32
  {R.enemy(R.assigned_role(role,seed)) == P.enemy_flag(role) : Bool}

# Guarantees: lifecycle responsibility covers the original enemy and XP roles.
# Why it matters: dormant spawn slots and free XP identities cannot disappear.
law pool_assignment:
  for +role: P.Role
  for seed: U32
  {R.pool(R.assigned_role(role,seed)) == Bool.or(P.enemy_flag(role),P.xp_flag(role)) : Bool}

# Guarantees: enemy and projectile component responsibilities never overlap.
# Why it matters: projectile systems cannot acquire enemy health/status storage.
law disjoint_responsibilities:
  for +role: R.Role
  {Bool.and(R.projectile(role),R.pool(role)) == False{} : Bool}

# Guarantees: the actual setup entry preserves every enemy allocation identity.
# Why it matters: a correct role adapter cannot excuse a broken setup dispatcher.
law allocated_enemy:
  for +seed: U32
  {R.enemy(R.assigned(seed)) == P.is_enemy_pool(seed) : Bool}

# Guarantees: the actual setup entry preserves every projectile allocation role.
# Why it matters: both player and hostile projectile births require their slots.
law allocated_projectile:
  for +seed: U32
  {R.projectile(R.assigned(seed)) == Bool.or(P.is_player_shot(seed),P.is_hostile(seed)) : Bool}

# Guarantees: the actual setup entry preserves every lifecycle allocation role.
# Why it matters: a free XP slot must still participate in physical drop routing.
law allocated_pool:
  for +seed: U32
  {R.pool(R.assigned(seed)) == Bool.or(P.is_enemy_pool(seed),P.is_xp(seed)) : Bool}

# Guarantees: the reserved stage objective has a distinct immutable identity.
# Why it matters: its system must resolve relic pickup rather than enemy admission.
law reserved_relic:
  {R.assigned(P.relic_seed()) == R.RelicSlot{} : R.Role}

# Guarantees: only the reserved enemy identity is classified as the stage relic.
# Why it matters: ordinary enemies must not execute the objective pickup system.
law relic_assignment:
  for +role: P.Role
  for +seed: U32
  {R.relic(R.assigned_role(role,seed)) == Bool.and(P.enemy_flag(role),U32.is_eq(seed,P.relic_seed())) : Bool}

# Guarantees: pickup dispatch admits exactly the allocated XP identities.
# Why it matters: pickups must not receive enemy health or status writers.
law pickup_assignment:
  for +role: P.Role
  for seed: U32
  {R.pickup(R.assigned_role(role,seed)) == P.xp_flag(role) : Bool}

# Guarantees: player projectiles cannot become hostile projectile identities.
# Why it matters: the two projectile systems use different spawn and hit rules.
law player_identity:
  for seed: U32
  {R.assigned_role(P.PlayerShot{},seed) == R.PlayerProjectileSlot{} : R.Role}

# Guarantees: hostile projectile identities retain their own system dispatch.
# Why it matters: hostile shots must not enter player weapon allocation.
law hostile_identity:
  for seed: U32
  {R.assigned_role(P.Hostile{},seed) == R.HostileProjectileSlot{} : R.Role}

# Guarantees: setup uses the proved allocation adapter without another remapping.
# Why it matters: correct helper laws must constrain the actual production entry.
law allocation_adapter:
  for +seed: U32
  {R.assigned(seed) == R.assigned_role(P.role(seed),seed) : R.Role}
