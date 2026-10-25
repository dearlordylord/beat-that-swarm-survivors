import Base
import ../pools.bend as P
import SPEC.bend as S

# Guarantees: every identity routes to exactly the interval selected by the
# ordered allocation bounds, including identities outside all allocated pools.
# Why it matters: assigning every slot Outside or to one pool disables gameplay
# while still satisfying the old one-tag-per-value assertion.
law exact_role_classification:
  for +seed:U32
  {P.role(seed) == S.role(seed) : P.Role}

# Guarantees: every pool begins at its predecessor's end, its count determines
# its own end, and the complete allocation ends at the final pool's boundary.
# Why it matters: initialization must neither overlap storage nor omit a pool.
law contiguous_layout:
  {(P.player_start(),P.hostile_start(),P.xp_start(),P.enemy_end(),P.player_end(),P.hostile_end(),P.xp_end(),P.total_count()) == (P.enemy_end(),P.player_end(),P.hostile_end(),P.enemy_count(),(P.player_start() + P.player_count() : U32),(P.hostile_start() + P.hostile_count() : U32),(P.xp_start() + P.xp_count() : U32),P.xp_end()) : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}

# Guarantees: the structural traversal count equals the allocation count.
# Why it matters: a stale traversal count would leave allocated slots dormant.
law exact_traversal:
  {P.total_nat() == U32.to_nat(P.total_count()) : Nat}

# Guarantees: no weapon cap exceeds the allowed live-projectile limit,
# including identifiers outside the local catalogue.
# Why it matters: per-weapon admission must stay below the shared pool capacity.
law bounded_weapon_cap:
  for base:U32
  {U32.is_le(P.weapon_cap(base),70) == True{} : Bool}

# Guarantees: every generated table is exactly the authoritative capacity
# query applied to successive owner identifiers, for arbitrary lengths/starts.
# Why it matters: bulk allocation and individual weapon queries cannot drift
# into independently maintained tuning tables.
law generated_caps_match_queries:
  for +left:Nat
  for +base:U32
  {P.caps_go(left,base) == S.capacities(S.owners(left,base)) : List<&2,U32>}

# Guarantees: generating a capacity table produces exactly the requested cells.
# Why it matters: an empty or truncated table would silently refuse valid shots.
law generated_caps_have_requested_length:
  for +left:Nat
  for base:U32
  {List.length(&2,U32,P.caps_go(left,base)) == left : Nat}

# Guarantees: the exported capacity table covers the configured owner catalogue
# in identifier order, starting with the first owner.
# Why it matters: the runtime allocator must receive the complete generated
# table rather than a stale export or an omitted owner.
law exported_caps_cover_catalogue:
  {P.caps() == S.capacities(S.owners(U32.to_nat(P.owner_count()),0)) : List<&2,U32>}

def positive_capacity(value:U32) -> Bool: U32.is_gt(value,0)
# Guarantees: every configured catalogue entry admits a positive shot capacity.
# Why it matters: changing the entire capacity source to zero would disable all
# player weapons while still satisfying an upper-bound-only contract.
law configured_caps_are_positive:
  {List.all(~&2,~U32,~positive_capacity,P.caps()) == True{} : Bool}
