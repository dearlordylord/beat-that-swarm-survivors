import Base
import ../loot-visual.bend as V
import LAWS.bend as Laws

def Laws.capped_public_radius(amount,large):
  %Equal.sym(Bool,U32.is_le(100,amount),True{},large) : {V.radius_decision(_,amount) == 8.0 : F32}
  {==}

def Laws.blue_tier(amount,below_green,below_red):
  %below_green : {V.tier_color((Bool.to_u32(_) + Bool.to_u32(U32.is_le(V.red_threshold(),amount)) : U32)) == V.tier_color(0) : U32}
  %below_red : {V.tier_color((0 + Bool.to_u32(_) : U32)) == V.tier_color(0) : U32}
  {==}
def Laws.green_tier(amount,reaches_green,below_red):
  %reaches_green : {V.tier_color((Bool.to_u32(_) + Bool.to_u32(U32.is_le(V.red_threshold(),amount)) : U32)) == V.tier_color(1) : U32}
  %below_red : {V.tier_color((1 + Bool.to_u32(_) : U32)) == V.tier_color(1) : U32}
  {==}
def Laws.red_tier(amount,reaches_green,reaches_red):
  %reaches_green : {V.tier_color((Bool.to_u32(_) + Bool.to_u32(U32.is_le(V.red_threshold(),amount)) : U32)) == V.tier_color(2) : U32}
  %reaches_red : {V.tier_color((1 + Bool.to_u32(_) : U32)) == V.tier_color(2) : U32}
  {==}

def Laws.accumulator_always_red(amount): {==}
def Laws.ordinary_pile_color_preserved(amount): {==}
