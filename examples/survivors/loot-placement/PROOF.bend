import Base
import ../loot-placement.bend as P
import LAWS.bend as L
import ../../../vendor/bendlib/packages/bend-mathlib/bool.bend as B

def bound_selected(+value: U32,+below: Cmp,+above: Cmp,lo: {below == U32.cmp(value,P.lower()) : Cmp},hi: {above == U32.cmp(value,P.upper()) : Cmp}) -> {True{} == L.inside(P.select(value,below,above)) : Bool}:
  match below above:
    case LT{} LT{}: {==}
    case LT{} EQ{}: {==}
    case LT{} GT{}: {==}
    case EQ{} GT{}: {==}
    case GT{} GT{}: {==}
    case EQ{} LT{}:
      %lo : {True{} == Bool.and(Cmp.is_ge(_),Cmp.is_le(U32.cmp(value,P.upper()))) : Bool}
      %hi : {True{} == Bool.and(Cmp.is_ge(EQ{}),Cmp.is_le(_)) : Bool}
      {==}
    case EQ{} EQ{}:
      %lo : {True{} == Bool.and(Cmp.is_ge(_),Cmp.is_le(U32.cmp(value,P.upper()))) : Bool}
      %hi : {True{} == Bool.and(Cmp.is_ge(EQ{}),Cmp.is_le(_)) : Bool}
      {==}
    case GT{} LT{}:
      %lo : {True{} == Bool.and(Cmp.is_ge(_),Cmp.is_le(U32.cmp(value,P.upper()))) : Bool}
      %hi : {True{} == Bool.and(Cmp.is_ge(GT{}),Cmp.is_le(_)) : Bool}
      {==}
    case GT{} EQ{}:
      %lo : {True{} == Bool.and(Cmp.is_ge(_),Cmp.is_le(U32.cmp(value,P.upper()))) : Bool}
      %hi : {True{} == Bool.and(Cmp.is_ge(GT{}),Cmp.is_le(_)) : Bool}
      {==}
def bounded_word(+value: U32) -> {True{} == L.inside(P.place_word(value)) : Bool}:
  bound_selected(value,U32.cmp(value,P.lower()),U32.cmp(value,P.upper()),{==},{==})
def word_coordinate(value: U32) -> {value == P.word(P.coordinate(value)) : U32}:
  match value:
    case U32{bits}: {==}
def L.bounded(value):
  %word_coordinate(P.place_word(P.word(value))) : {True{} == L.inside(_) : Bool}
  bounded_word(P.word(value))

def preserve_selected(+value: U32,+below: Cmp,+above: Cmp,valid: {True{} == Bool.and(Cmp.is_ge(below),Cmp.is_le(above)) : Bool}) -> {P.select(value,below,above) == value : U32}:
  match below above:
    case LT{} LT{}:
      Empty.absurd({P.lower() == value : U32},B.true_ne_false()(valid))
    case LT{} EQ{}:
      Empty.absurd({P.lower() == value : U32},B.true_ne_false()(valid))
    case LT{} GT{}:
      Empty.absurd({P.lower() == value : U32},B.true_ne_false()(valid))
    case EQ{} GT{}:
      Empty.absurd({P.upper() == value : U32},B.true_ne_false()(valid))
    case GT{} GT{}:
      Empty.absurd({P.upper() == value : U32},B.true_ne_false()(valid))
    case EQ{} LT{}: {==}
    case EQ{} EQ{}: {==}
    case GT{} LT{}: {==}
    case GT{} EQ{}: {==}
def preserve_word(+value: U32,valid: {True{} == L.inside(value) : Bool}) -> {P.place_word(value) == value : U32}:
  preserve_selected(value,U32.cmp(value,P.lower()),U32.cmp(value,P.upper()),valid)
def coordinate_word(value: F32) -> {P.coordinate(P.word(value)) == value : F32}:
  match value:
    case F32{bits}: {==}
def L.preserve_inside(value,valid):
  %Equal.sym(U32,P.place_word(P.word(value)),P.word(value),preserve_word(P.word(value),valid)) : {P.coordinate(_) == value : F32}
  coordinate_word(value)
def L.idempotent(value): L.preserve_inside(P.place(value),L.bounded(value))
def L.lower_fixed(): {==}
def L.upper_fixed(): {==}
