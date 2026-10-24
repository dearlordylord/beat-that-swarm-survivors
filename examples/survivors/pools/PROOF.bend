import Base
import ../pools.bend as P
import LAWS.bend as Laws

def role_unique(role:P.Role) -> {Laws.role_count(role) == 1 : U32}:
  match role:
    case P.Enemy{}: {==}
    case P.PlayerShot{}: {==}
    case P.Hostile{}: {==}
    case P.Actor{}: {==}
    case P.Xp{}: {==}
    case P.Outside{}: {==}
def Laws.unique_role(seed): role_unique(P.role(seed))
def Laws.contiguous_layout(): {==}
def Laws.exact_counts(): {==}
def Laws.exact_traversal(): {==}
def capacity_bounded(capacity:P.Capacity) -> {U32.is_le(P.capacity_value(capacity),70) == True{} : Bool}:
  match capacity:
    case P.Cap0{}: {==}
    case P.Cap40{}: {==}
    case P.Cap50{}: {==}
    case P.Cap60{}: {==}
    case P.Cap70{}: {==}
def Laws.bounded_weapon_cap(base): capacity_bounded(P.weapon_capacity(base))
def Laws.exact_weapon_caps(): {==}
def Laws.exact_catalogue(): {==}
def Laws.exact_role_boundaries(): {==}


def xp_no_actor(inside: Bool) -> {P.actor_flag(P.xp_role(inside)) == False{} : Bool}:
  match inside:
    case True{}: {==}
    case False{}: {==}
def hostile_no_actor(inside: Bool,+seed: U32) -> {P.actor_flag(P.hostile_role(inside,seed)) == False{} : Bool}:
  match inside:
    case True{}: {==}
    case False{}: xp_no_actor(U32.is_lt(seed,P.xp_end()))
def player_no_actor(inside: Bool,+seed: U32) -> {P.actor_flag(P.player_role(inside,seed)) == False{} : Bool}:
  match inside:
    case True{}: {==}
    case False{}: hostile_no_actor(U32.is_lt(seed,P.hostile_end()),seed)
def enemy_no_actor(inside: Bool,+seed: U32) -> {P.actor_flag(P.enemy_role(inside,seed)) == False{} : Bool}:
  match inside:
    case True{}: {==}
    case False{}: player_no_actor(U32.is_lt(seed,P.player_end()),seed)
def Laws.no_actor_role(seed): enemy_no_actor(U32.is_lt(seed,P.enemy_end()),seed)
