import Base
import entity-role.bend as Role

# Shared selection policy used by checked queries and membership publication.
def active_role(role: Role.Role,kind: U32) -> Bool: Bool.and(Role.enemy(role),U32.is_eq(kind,0))

# Transaction outputs are already ordered. Only absent entries are removed.
def outputs(~H: Data,rows: List<&2,Maybe<&2,H>>) -> List<&2,H>:
  match rows:
    case []: []
    case Some{handle} <> rest: handle <> outputs(~H,rest)
    case None{} <> rest: outputs(~H,rest)
