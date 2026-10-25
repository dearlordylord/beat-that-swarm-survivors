import Base

# Saturating damage: health never wraps when a hit consumes the remaining HP.
def lose_decided(survives: Bool,hp: U32,damage: U32) -> U32:
  match survives:
    case True{}: (hp - damage : U32)
    case False{}: 0
def lose(+hp: U32,+damage: U32) -> U32:
  lose_decided(U32.is_lt(damage,hp),hp,damage)

def admitted(vulnerable: Bool,amount: U32) -> U32:
  match vulnerable:
    case True{}: amount
    case False{}: 0
def contact_damage(hit: U32,invuln: U32,amount: U32) -> U32:
  admitted(Bool.and(U32.is_lt(0,hit),U32.is_eq(invuln,0)),amount)
