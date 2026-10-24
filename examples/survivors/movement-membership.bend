import Base
import pools.bend as PL
import entity-role.bend as Role

# Shared selection policy used by checked queries and membership publication.
def selected_kind(+mode: U32,+kind: U32,+seed: U32) -> Bool:
  Bool.or(Bool.and(U32.is_eq(mode,0),Bool.or(PL.is_player_shot(seed),PL.is_hostile(seed))),Bool.or(Bool.and(U32.is_eq(mode,2),PL.is_xp(seed)),Bool.and(PL.is_enemy_pool(seed),Bool.or(U32.is_eq(mode,2),Bool.and(U32.is_eq(mode,1),U32.is_eq(kind,0))))))
def active(kind: U32,seed: U32) -> Bool: selected_kind(1,kind,seed)
def active_role(role: Role.Role,kind: U32) -> Bool: Bool.and(Role.enemy(role),U32.is_eq(kind,0))

# Transaction outputs are already ordered. Only absent entries are removed.
def outputs(~H: Data,rows: List<&2,Maybe<&2,H>>) -> List<&2,H>:
  match rows:
    case []: []
    case Some{handle} <> rest: handle <> outputs(~H,rest)
    case None{} <> rest: outputs(~H,rest)
