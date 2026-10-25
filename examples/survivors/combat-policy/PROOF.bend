import Base
import ../combat-policy.bend as C
import LAWS.bend as L

def L.lethal_hit_exhausts_health(hp,damage,lethal):
  %lethal : {C.lose_decided(_,hp,damage) == 0 : U32}
  {==}
def L.surviving_hit_debits_exactly(hp,damage,survives):
  %survives : {C.lose_decided(_,hp,damage) == (hp - damage : U32) : U32}
  {==}
def protected_damage(contact: Bool,amount: U32) -> {C.admitted(Bool.and(contact,False{}),amount) == 0 : U32}:
  match contact:
    case True{}: {==}
    case False{}: {==}
def L.invulnerable_contact_does_no_damage(hit,invuln,amount,protected):
  %protected : {C.admitted(Bool.and(U32.is_lt(0,hit),_),amount) == 0 : U32}
  protected_damage(U32.is_lt(0,hit),amount)
def L.absent_contact_does_no_damage(hit,invuln,amount,absent):
  %absent : {C.admitted(Bool.and(_,U32.is_eq(invuln,0)),amount) == 0 : U32}
  {==}
def L.vulnerable_contact_applies_damage(hit,invuln,amount,contact,vulnerable):
  %contact : {C.admitted(Bool.and(_,U32.is_eq(invuln,0)),amount) == amount : U32}
  %vulnerable : {C.admitted(_,amount) == amount : U32}
  {==}
