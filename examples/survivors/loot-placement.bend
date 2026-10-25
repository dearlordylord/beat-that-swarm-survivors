import Base
import arena.bend as A

# Positive finite IEEE coordinates have the same order as their unsigned words.
# Inspect the constructor directly: Base.F32.bits is an opaque primitive in proofs.
def word(value: F32) -> U32:
  match value:
    case F32{bits}: U32{bits}
def coordinate(value: U32) -> F32:
  match value:
    case U32{bits}: F32{bits}
def lower() -> U32: word(A.player_min())
def upper() -> U32: word(A.player_max())
def select(value: U32,below: Cmp,above: Cmp) -> U32:
  match below above:
    case LT{} LT{}: lower()
    case LT{} EQ{}: lower()
    case LT{} GT{}: lower()
    case EQ{} GT{}: upper()
    case GT{} GT{}: upper()
    case EQ{} LT{}: value
    case EQ{} EQ{}: value
    case GT{} LT{}: value
    case GT{} EQ{}: value
def place_word(+value: U32) -> U32:
  select(value,U32.cmp(value,lower()),U32.cmp(value,upper()))
# Every bit pattern is sanitized to a positive finite legal player coordinate.
# Negative/nonfinite encodings select the upper edge, rather than propagating NaN.
def place(value: F32) -> F32: coordinate(place_word(word(value)))
