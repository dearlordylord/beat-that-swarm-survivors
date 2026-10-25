import Base
import ../pools.bend as P

# Independent role predicates used only by proof contracts.
def enemy_flag(role:P.Role) -> Bool:
  match role:
    case P.Enemy{}: True{}
    case _: False{}
def hostile_flag(role:P.Role) -> Bool:
  match role:
    case P.Hostile{}: True{}
    case _: False{}
def is_enemy_pool(seed:U32) -> Bool: enemy_flag(P.role(seed))
def is_hostile(seed:U32) -> Bool: hostile_flag(P.role(seed))

# Priority follows the adjacent upper bounds; this specification never calls
# the runtime role router or its decision helpers.
def classify(enemy:Bool,player:Bool,hostile:Bool,xp:Bool) -> P.Role:
  match enemy player hostile xp:
    case True{} _ _ _: P.Enemy{}
    case False{} True{} _ _: P.PlayerShot{}
    case False{} False{} True{} _: P.Hostile{}
    case False{} False{} False{} True{}: P.Xp{}
    case False{} False{} False{} False{}: P.Outside{}
def role(+seed:U32) -> P.Role:
  classify(U32.is_lt(seed,P.enemy_end()),U32.is_lt(seed,P.player_end()),U32.is_lt(seed,P.hostile_end()),U32.is_lt(seed,P.xp_end()))

# Enumerate keys and query the authoritative capacity independently of caps_go.
def owners(left:Nat,+base:U32) -> List<&2,U32>:
  match left:
    case 0n: []
    case 1n+rest: base <> owners(rest,(base + 1 : U32))
def capacities(rows:List<&2,U32>) -> List<&2,U32>:
  match rows:
    case []: []
    case base <> rest: P.weapon_cap(base) <> capacities(rest)
