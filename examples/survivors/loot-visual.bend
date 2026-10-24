import Base

# Presentation policy shared by native and browser XP gems. The amount is the
# contained base XP, never the enemy variant, player bonus or collision radius.
# Reference-aligned tiers: blue below5, green5..9, red10 and above. Ordinary
# drops2..6 span blue/green; merged piles25/100/400 stay red.
def green_threshold() -> U32: 5
def red_threshold() -> U32: 10
def size_cap_amount() -> U32: 100
def minimum_radius() -> F32: 3.0
def maximum_radius() -> F32: 8.0

def tier(+amount: U32) -> U32:
  (Bool.to_u32(U32.is_le(green_threshold(),amount)) + Bool.to_u32(U32.is_le(red_threshold(),amount)) : U32)
def tier_color(tier: U32) -> U32:
  match tier:
    case 0: 6934271
    case 1: 7986088
    case _: 16740475
def color(amount: U32) -> U32: tier_color(tier(amount))
# An explicit merged/overflow accumulator is always red, even when its first
# combined amount is below10. Its size still depends only on contained XP.
def pile_color(amount: U32,accumulator: Bool) -> U32:
  match accumulator:
    case True{}: tier_color(2)
    case False{}: color(amount)

# Radius3 +sqrt(XP)/2 grows gently, then stays exactly8 at100XP and above.
# Clamp before conversion/square root: maximal U32 values and overflow piles remain finite.
# Examples: 2XP~3.71; 6XP~4.22; 25XP=5.5; 100XP/400XP=8.
# These are logical drawing units only; pickup/magnet/collision rules are not
# inputs to this module and must keep using their independent mechanics.
def radius_decision(large: Bool,amount: U32) -> F32:
  match large:
    case True{}: maximum_radius()
    case False{}: (minimum_radius() + F32.sqrt(U32.to_f32(U32.min(size_cap_amount(),amount))) * 0.5 : F32)
def radius(+amount: U32) -> F32:
  radius_decision(U32.is_le(size_cap_amount(),amount),amount)
# Existing native gem artwork has a4-unit half-height.
def scale(amount: U32) -> F32: (radius(amount) / 4.0 : F32)
