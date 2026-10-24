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
