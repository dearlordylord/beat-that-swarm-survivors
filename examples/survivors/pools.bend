import Base

# TODO: Investigate whether fixed pools are needed. Their origin may be copying
# the reference game's architecture rather than a Bend/Bendvy requirement;
# verify that hypothesis against project history. Try dynamic entity creation
# and removal while preserving gameplay limits, lifetime identity and behavior.
# Check native/browser/co-op correctness and measure allocation/step costs before
# deciding whether to retain pools; no comparative speed advantage is established.
# Application allocation layout. Enemy pool includes the reserved relic seed.
def enemy_count() -> U32: 512
def enemy_end() -> U32: enemy_count()
def relic_seed() -> U32: (enemy_end() - 1 : U32)
def player_start() -> U32: enemy_end()
def player_count() -> U32: 512
def player_end() -> U32: (player_start() + player_count() : U32)
def hostile_start() -> U32: player_end()
def hostile_count() -> U32: 32
def hostile_end() -> U32: (hostile_start() + hostile_count() : U32)
def xp_start() -> U32: hostile_end()
def xp_count() -> U32: 400
def xp_end() -> U32: (xp_start() + xp_count() : U32)
def total_count() -> U32: xp_end()
def total_nat() -> Nat: U32.to_nat(total_count())
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
def player_flag(role:Role) -> Bool:
  match role:
    case PlayerShot{}: True{}
    case _: False{}
def xp_flag(role:Role) -> Bool:
  match role:
    case Xp{}: True{}
    case _: False{}
def is_player_shot(seed:U32) -> Bool: player_flag(role(seed))
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

# The exported table is generated from the same source as individual queries.
def caps_go(left:Nat,+base:U32) -> List<&2,U32>:
  match left:
    case 0n: []
    case 1n+rest: weapon_cap(base) <> caps_go(rest,(base + 1 : U32))
def caps() -> List<&2,U32>: caps_go(U32.to_nat(owner_count()),0)
