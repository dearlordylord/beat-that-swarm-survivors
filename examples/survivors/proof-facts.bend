# Proof-only adapters reuse the pinned mathlib facts with the project's equation orientation.
import Base
import ../../vendor/bendlib/packages/bend-mathlib/string.bend as S
import ../../vendor/bendlib/packages/bend-mathlib/bool.bend as B
import ../../vendor/bendlib/packages/bend-mathlib/nat.bend as N

def u32_cmp_refl(+key: U32) -> {U32.cmp(key,key) == EQ{} : Cmp}: S.u32_cmp_refl(key)
def u32_eq_refl(+key: U32) -> {U32.is_eq(key,key) == True{} : Bool}:
  Equal.cong(Cmp,Bool,Cmp.is_eq,U32.cmp(key,key),EQ{},S.u32_cmp_refl(key))
def string_eq_refl(text: String) -> {String.eq(text,text) == True{} : Bool}: S.eq_refl(text)
def and_left(+a: Bool,+b: Bool,h: {True{} == Bool.and(a,b) : Bool}) -> {True{} == a : Bool}:
  Equal.sym(Bool,a,True{},B.eq_true_of_and_left(a,b,Equal.sym(Bool,True{},Bool.and(a,b),h)))
def and_right(+a: Bool,+b: Bool,h: {True{} == Bool.and(a,b) : Bool}) -> {True{} == b : Bool}:
  Equal.sym(Bool,b,True{},B.eq_true_of_and_right(a,b,Equal.sym(Bool,True{},Bool.and(a,b),h)))
def and_true(+a: Bool,+b: Bool,ha: {True{} == a : Bool},hb: {True{} == b : Bool}) -> {True{} == Bool.and(a,b) : Bool}:
  Equal.sym(Bool,Bool.and(a,b),True{},B.and_eq_true(a,b,Equal.sym(Bool,True{},a,ha),Equal.sym(Bool,True{},b,hb)))
def and_false_right(a: Bool) -> {Bool.and(a,False{}) == False{} : Bool}: B.and_false(a)
def nat_add_zero(amount: Nat) -> {Nat.add(amount,0n) == amount : Nat}: N.add_zero(amount)
