import Base

# Actual native upgrade scoring, isolated for bounded universal kernel checks.
def branch(~T: Type,+test: Bool,a: Unit -> T,b: Unit -> T) -> T:
  match test:
    case True{}: a(Unit{})
    case False{}: b(Unit{})

def yes(+test: Bool,+a: F32,+b: F32) -> F32:
  branch(~(F32),test,(_ =>
      a
  ),(_ =>
      b

  ))
def preference(+id: U32,+rows: List<&2,U32>,+index: U32) -> U32:
  match rows:
    case []: 999
    case item <> rest:
      branch(~(U32),U32.is_eq(id,item),(_ =>
          index
      ),(_ =>
          preference(id,rest,(index + 1 : U32))
      ))
def at(values: List<&2,U32>,index: U32) -> U32:
  match values index:
    case Nil{} _: 0
    case Con{head,_} 0: head
    case Con{_,tail} index: at(tail,(index - 1 : U32))
def offer_score(+kind: U32,+id: U32,+weapons: List<&2,U32>,+passives: List<&2,U32>,+hp: U32,+maxHp: U32) -> F32:
  match kind:
    case 3: 1000.0
    case 5: 1000.0
    case 0:
      +order=preference(id,[4,19,10,0,2,17],0)
      yes(U32.is_lt(order,999),(yes(U32.is_eq(id,4),260.0,170.0) + yes(U32.is_lt(0,at(weapons,id)),30.0,0.0) - U32.to_f32(order) : F32),(0.0 - 100.0 : F32))
    case 1:
      +order=preference(id,[11,1,6,2,0,7],0)
      yes(U32.is_lt(order,999),(210.0 - U32.to_f32(order) * 5.0 + yes(U32.is_eq(at(passives,id),0),20.0,0.0) : F32),(0.0 - 100.0 : F32))
    case 2: yes(F32.is_lt(U32.to_f32(hp),(U32.to_f32(maxHp) * 0.7 : F32)),300.0,10.0)
    case 4: 5.0
    case _: (0.0 - 100.0 : F32)
