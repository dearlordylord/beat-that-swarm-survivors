import Base

# Base XP values and explicit pickup accounting for persistent ECS loot.
def drop_amount(+variant: U32) -> U32: (2 + U32.min(4,(variant / 4 : U32)) : U32)
def merge(amount: U32,incoming: U32) -> U32: (amount + incoming : U32)
def credited(touching: Bool,amount: U32) -> U32:
  match touching:
    case True{}: amount
    case False{}: 0
def remaining(touching: Bool,amount: U32) -> U32:
  match touching:
    case True{}: 0
    case False{}: amount
