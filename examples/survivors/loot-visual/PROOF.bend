import Base
import ../loot-visual.bend as V
import LAWS.bend as Laws

def Laws.capped_public_radius(amount,large):
  %Equal.sym(Bool,U32.is_le(100,amount),True{},large) : {V.radius_decision(_,amount) == 8.0 : F32}
  {==}

def Laws.first_tier_blue(): {==}
def Laws.last_blue(): {==}
def Laws.first_green(): {==}
def Laws.last_green(): {==}
def Laws.first_red(): {==}
def Laws.overflow_red(): {==}

def Laws.accumulator_always_red(amount): {==}
def Laws.ordinary_pile_color_preserved(amount): {==}
