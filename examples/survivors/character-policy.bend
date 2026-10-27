import Base

def count() -> U32: 7
def mask() -> U32: 127
def valid(id: U32) -> Bool: U32.is_lt(id,count())
def normalized(ok: Bool,id: U32) -> U32:
  match ok:
    case True{}: id
    case False{}: 0
def normalize(+id: U32) -> U32: normalized(valid(id),id)

def starter(id: U32) -> U32:
  match id:
    case 0: 20
    case 1: 21
    case 2: 14
    case 3: 22
    case 4: 8
    case 5: 23
    case 6: 1
    case _: 20

def health(id: U32) -> U32:
  match id:
    case 6: 125
    case _: 100

def might_percent(+id: U32) -> U32:
  (20 * Bool.to_u32(U32.is_eq(id,2)) + 10 * Bool.to_u32(U32.is_eq(id,6)) : U32)
def speed_percent(id: U32) -> U32: (15 * Bool.to_u32(U32.is_eq(id,3)) : U32)
def cooldown_reduction(id: U32) -> U32: (10 * Bool.to_u32(U32.is_eq(id,5)) : U32)
def pickup_percent(id: U32) -> U32: (50 * Bool.to_u32(U32.is_eq(id,0)) : U32)
def regeneration(id: U32) -> U32: Bool.to_u32(U32.is_eq(id,1))
def armor(id: U32) -> U32: Bool.to_u32(U32.is_eq(id,4))
