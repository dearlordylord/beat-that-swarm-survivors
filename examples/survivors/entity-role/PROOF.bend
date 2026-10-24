import Base
import ../entity-role.bend as R
import ../pools.bend as P
import LAWS.bend as L

def L.relic_retains_enemy_storage(flag):
  match flag:
    case True{}: {==}
    case False{}: {==}
def projectile_enemy_slot(flag: Bool) -> {R.projectile(R.enemy_slot(flag)) == False{} : Bool}:
  match flag:
    case True{}: {==}
    case False{}: {==}
def pool_enemy_slot(flag: Bool) -> {R.pool(R.enemy_slot(flag)) == True{} : Bool}:
  match flag:
    case True{}: {==}
    case False{}: {==}
def L.projectile_assignment(role,seed):
  match role:
    case P.Enemy{}: projectile_enemy_slot(U32.is_eq(seed,P.relic_seed()))
    case P.PlayerShot{}: {==}
    case P.Hostile{}: {==}
    case P.Actor{}: {==}
    case P.Xp{}: {==}
    case P.Outside{}: {==}
def L.enemy_assignment(role,seed):
  match role:
    case P.Enemy{}: L.relic_retains_enemy_storage(U32.is_eq(seed,P.relic_seed()))
    case P.PlayerShot{}: {==}
    case P.Hostile{}: {==}
    case P.Actor{}: {==}
    case P.Xp{}: {==}
    case P.Outside{}: {==}
def L.pool_assignment(role,seed):
  match role:
    case P.Enemy{}: pool_enemy_slot(U32.is_eq(seed,P.relic_seed()))
    case P.PlayerShot{}: {==}
    case P.Hostile{}: {==}
    case P.Actor{}: {==}
    case P.Xp{}: {==}
    case P.Outside{}: {==}
def L.disjoint_responsibilities(role):
  match role:
    case R.EnemySlot{}: {==}
    case R.RelicSlot{}: {==}
    case R.PlayerProjectileSlot{}: {==}
    case R.HostileProjectileSlot{}: {==}
    case R.XpSlot{}: {==}
    case R.OutsideSlot{}: {==}
def L.allocated_enemy(seed): L.enemy_assignment(P.role(seed),seed)
def L.allocated_projectile(seed): L.projectile_assignment(P.role(seed),seed)
def L.allocated_pool(seed): L.pool_assignment(P.role(seed),seed)
def L.reserved_relic(): {==}
def relic_enemy_slot(+flag: Bool) -> {R.relic(R.enemy_slot(flag)) == flag : Bool}:
  match flag:
    case True{}: {==}
    case False{}: {==}
def pickup_enemy_slot(flag: Bool) -> {R.pickup(R.enemy_slot(flag)) == False{} : Bool}:
  match flag:
    case True{}: {==}
    case False{}: {==}
def L.relic_assignment(role,seed):
  match role:
    case P.Enemy{}: relic_enemy_slot(U32.is_eq(seed,P.relic_seed()))
    case P.PlayerShot{}: {==}
    case P.Hostile{}: {==}
    case P.Actor{}: {==}
    case P.Xp{}: {==}
    case P.Outside{}: {==}
def L.pickup_assignment(role,seed):
  match role:
    case P.Enemy{}: pickup_enemy_slot(U32.is_eq(seed,P.relic_seed()))
    case P.PlayerShot{}: {==}
    case P.Hostile{}: {==}
    case P.Actor{}: {==}
    case P.Xp{}: {==}
    case P.Outside{}: {==}
def L.player_identity(seed): {==}
def L.hostile_identity(seed): {==}
def L.allocation_adapter(seed): {==}
