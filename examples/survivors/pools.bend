import Base

# Application allocation layout. Enemy pool includes the reserved relic seed.
def enemy_count() -> U32: 512
def enemy_end() -> U32: 512
def relic_seed() -> U32: 511
def player_start() -> U32: 512
def player_count() -> U32: 512
def player_end() -> U32: 1024
def hostile_start() -> U32: 1024
def hostile_count() -> U32: 32
def hostile_end() -> U32: 1056
def xp_start() -> U32: 1056
def xp_count() -> U32: 400
def xp_end() -> U32: 1456
def total_count() -> U32: 1456
def total_nat() -> Nat: 1456n
def owner_count() -> U32: 24
def logical_count() -> U32: 8
def normal_enemy_cap() -> U32: 300
def max_regular_enemies() -> U32: 500

type Role is Data:
  Enemy{}
  PlayerShot{}
  Hostile{}
  Xp{}
  Outside{}

def xp_role(inside:Bool) -> Role:
  match inside:
    case True{}: Xp{}
    case False{}: Outside{}
def hostile_role(inside:Bool,+seed:U32) -> Role:
  match inside:
    case True{}: Hostile{}
    case False{}: xp_role(U32.is_lt(seed,xp_end()))
def player_role(inside:Bool,+seed:U32) -> Role:
  match inside:
    case True{}: PlayerShot{}
    case False{}: hostile_role(U32.is_lt(seed,hostile_end()),seed)
def enemy_role(inside:Bool,+seed:U32) -> Role:
  match inside:
    case True{}: Enemy{}
    case False{}: player_role(U32.is_lt(seed,player_end()),seed)
def role(+seed:U32) -> Role:
  enemy_role(U32.is_lt(seed,enemy_end()),seed)
def enemy_flag(role:Role) -> Bool:
  match role:
    case Enemy{}: True{}
    case _: False{}
def player_flag(role:Role) -> Bool:
  match role:
    case PlayerShot{}: True{}
    case _: False{}
def hostile_flag(role:Role) -> Bool:
  match role:
    case Hostile{}: True{}
    case _: False{}
def xp_flag(role:Role) -> Bool:
  match role:
    case Xp{}: True{}
    case _: False{}
def outside_flag(role:Role) -> Bool:
  match role:
    case Outside{}: True{}
    case _: False{}
def is_enemy_pool(seed:U32) -> Bool: enemy_flag(role(seed))
def is_player_shot(seed:U32) -> Bool: player_flag(role(seed))
def is_hostile(seed:U32) -> Bool: hostile_flag(role(seed))
def is_xp(seed:U32) -> Bool: xp_flag(role(seed))

# Per-weapon live caps for the local 24-weapon catalogue, not a claim of
# exact parity for each local weapon with a particular poncle game version.
type Capacity is Data:
  Cap0{}
  Cap40{}
  Cap50{}
  Cap60{}
  Cap70{}
def capacity_value(capacity:Capacity) -> U32:
  match capacity:
    case Cap0{}: 0
    case Cap40{}: 40
    case Cap50{}: 50
    case Cap60{}: 60
    case Cap70{}: 70
def weapon_capacity(base:U32) -> Capacity:
  match base:
    case 0: Cap60{}
    case 1: Cap60{}
    case 2: Cap70{}
    case 3: Cap40{}
    case 4: Cap50{}
    case 5: Cap60{}
    case 6: Cap60{}
    case 7: Cap50{}
    case 8: Cap60{}
    case 9: Cap40{}
    case 10: Cap60{}
    case 11: Cap60{}
    case 12: Cap60{}
    case 13: Cap60{}
    case 14: Cap60{}
    case 15: Cap60{}
    case 16: Cap60{}
    case 17: Cap60{}
    case 18: Cap60{}
    case 19: Cap40{}
    case 20: Cap40{}
    case 21: Cap40{}
    case 22: Cap50{}
    case 23: Cap60{}
    case _: Cap0{}

def weapon_cap(base:U32) -> U32: capacity_value(weapon_capacity(base))

def caps() -> List<&2,U32>:
  [60,60,70,40,50,60,60,50,60,40,60,60,60,60,60,60,60,60,60,40,40,40,50,60]
