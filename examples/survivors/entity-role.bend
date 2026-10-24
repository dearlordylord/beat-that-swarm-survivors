import Base
import pools.bend as PL

# Immutable composition identity. Allocation ranges are interpreted only here.
# Body.kind describes the current incarnation, never the storage responsibility.
type Role is Data:
  EnemySlot{}
  RelicSlot{}
  PlayerProjectileSlot{}
  HostileProjectileSlot{}
  XpSlot{}
  OutsideSlot{}

def enemy_slot(relic: Bool) -> Role:
  match relic:
    case True{}: RelicSlot{}
    case False{}: EnemySlot{}
def assigned_role(role: PL.Role,seed: U32) -> Role:
  match role:
    case PL.Enemy{}: enemy_slot(U32.is_eq(seed,PL.relic_seed()))
    case PL.PlayerShot{}: PlayerProjectileSlot{}
    case PL.Hostile{}: HostileProjectileSlot{}
    case PL.Xp{}: XpSlot{}
    case _: OutsideSlot{}
def assigned(+seed: U32) -> Role: assigned_role(PL.role(seed),seed)
def projectile(role: Role) -> Bool:
  match role:
    case PlayerProjectileSlot{}: True{}
    case HostileProjectileSlot{}: True{}
    case _: False{}
def enemy(role: Role) -> Bool:
  match role:
    case EnemySlot{}: True{}
    case RelicSlot{}: True{}
    case _: False{}
def pool(role: Role) -> Bool:
  match role:
    case EnemySlot{}: True{}
    case RelicSlot{}: True{}
    case XpSlot{}: True{}
    case _: False{}
def relic(role: Role) -> Bool:
  match role:
    case RelicSlot{}: True{}
    case _: False{}
def pickup(role: Role) -> Bool:
  match role:
    case XpSlot{}: True{}
    case _: False{}
