import Base
import ../pools.bend as P
import SPEC.bend as S
import LAWS.bend as Laws

def xp_decision(xp:Bool) -> {P.xp_role(xp) == S.classify(False{},False{},False{},xp) : P.Role}:
  match xp:
    case True{}: {==}
    case False{}: {==}
def hostile_decision(+hostile:Bool,+seed:U32) -> {P.hostile_role(hostile,seed) == S.classify(False{},False{},hostile,U32.is_lt(seed,P.xp_end())) : P.Role}:
  match hostile:
    case True{}: {==}
    case False{}: xp_decision(U32.is_lt(seed,P.xp_end()))
def player_decision(+player:Bool,+seed:U32) -> {P.player_role(player,seed) == S.classify(False{},player,U32.is_lt(seed,P.hostile_end()),U32.is_lt(seed,P.xp_end())) : P.Role}:
  match player:
    case True{}: {==}
    case False{}: hostile_decision(U32.is_lt(seed,P.hostile_end()),seed)
def enemy_decision(+enemy:Bool,+seed:U32) -> {P.enemy_role(enemy,seed) == S.classify(enemy,U32.is_lt(seed,P.player_end()),U32.is_lt(seed,P.hostile_end()),U32.is_lt(seed,P.xp_end())) : P.Role}:
  match enemy:
    case True{}: {==}
    case False{}: player_decision(U32.is_lt(seed,P.player_end()),seed)
def Laws.exact_role_classification(seed): enemy_decision(U32.is_lt(seed,P.enemy_end()),seed)
def Laws.contiguous_layout(): {==}
def Laws.exact_traversal(): {==}
def capacity_bounded(capacity:P.Capacity) -> {U32.is_le(P.capacity_value(capacity),70) == True{} : Bool}:
  match capacity:
    case P.Cap0{}: {==}
    case P.Cap40{}: {==}
    case P.Cap50{}: {==}
    case P.Cap60{}: {==}
    case P.Cap70{}: {==}
def Laws.bounded_weapon_cap(base): capacity_bounded(P.weapon_capacity(base))
def Laws.generated_caps_match_queries(left,base):
  match left:
    case 0n: {==}
    case 1n+rest:
      Equal.cong(List<&2,U32>,List<&2,U32>,tail => P.weapon_cap(base) <> tail,P.caps_go(rest,(base + 1 : U32)),S.capacities(S.owners(rest,(base + 1 : U32))),Laws.generated_caps_match_queries(rest,(base + 1 : U32)))
def Laws.generated_caps_have_requested_length(left,base):
  match left:
    case 0n: {==}
    case 1n+rest:
      Equal.cong(Nat,Nat,n => 1n+n,List.length(&2,U32,P.caps_go(rest,(base + 1 : U32))),rest,Laws.generated_caps_have_requested_length(rest,(base + 1 : U32)))
def Laws.exported_caps_cover_catalogue(): Laws.generated_caps_match_queries(U32.to_nat(P.owner_count()),0)
def Laws.configured_caps_are_positive(): {==}
