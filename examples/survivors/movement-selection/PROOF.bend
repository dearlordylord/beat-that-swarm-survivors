import Base
import ../movement-membership.bend as M
import ../pools.bend as P
import LAWS.bend as L
import ../entity-role.bend as R
import ../entity-role/LAWS.bend as RL
import ../entity-role/PROOF.bend as RP

def L.exact_movement_scope(kind,seed): {==}
def L.exact_role_scope(role,kind): {==}
def L.assigned_role_equivalence(kind,seed):
  Equal.trans(Bool,M.active_role(R.assigned(seed),kind),Bool.and(P.is_enemy_pool(seed),U32.is_eq(kind,0)),M.active(kind,seed),Equal.cong(Bool,Bool,flag => Bool.and(flag,U32.is_eq(kind,0)),R.enemy(R.assigned(seed)),P.is_enemy_pool(seed),RL.allocated_enemy(seed)),Equal.sym(Bool,M.active(kind,seed),Bool.and(P.is_enemy_pool(seed),U32.is_eq(kind,0)),L.exact_movement_scope(kind,seed)))
def L.roster_retains_active(H,handle): {==}
def L.roster_batch_order(H,left,right):
  match left:
    case []: {==}
    case None{} <> rest: L.roster_batch_order(~H,rest,right)
    case Some{handle} <> rest:
      Equal.cong(List<&2,H>,List<&2,H>,tail => handle <> tail,M.outputs(~H,List.append(&2,Maybe<&2,H>,rest,right)),List.append(&2,H,M.outputs(~H,rest),M.outputs(~H,right)),L.roster_batch_order(~H,rest,right))
