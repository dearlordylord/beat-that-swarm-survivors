import Base
import ../persistent-xp.bend as X
import LAWS.bend as Laws
import ../proof-facts.bend as F

def Laws.untouched_credit(amount): {==}
def Laws.untouched_preserved(amount): {==}
def Laws.pickup_credits_whole_pile(amount): {==}
def Laws.pickup_consumes_pile(amount): {==}
def Laws.merge_preserves_value(amount,incoming): {==}

def Laws.pickup_conserves_natural_value(touching,amount):
  match touching:
    case True{}: F.nat_add_zero(U32.to_nat(amount))
    case False{}: {==}
def Laws.consumed_pile_cannot_credit_again(amount): {==}
def Laws.merge_order_independent(amount,incoming): U32.add_comm(amount,incoming)
