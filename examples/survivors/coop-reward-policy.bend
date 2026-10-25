# Shared by authoritative reward choice and departure handling.
import Base

def contains(ids: List<&2,U32>,+id: U32) -> Bool:
  match ids:
    case []: False{}
    case head <> rest: Bool.or(U32.is_eq(head,id),contains(rest,id))
def allowed(+round: U32,requested: U32,id: U32,choice: U32,count: U32,required: List<&2,U32>) -> Bool:
  Bool.and(Bool.and(U32.is_eq(round,requested),contains(required,id)),U32.is_lt(choice,count))
def remove(ids: List<&2,U32>,+id: U32) -> List<&2,U32>:
  match ids:
    case []: []
    case +head <> rest: List.filter.put(U32,head,remove(rest,id),U32.is_ne(head,id))

type Decision is Data: Decision{accepted: Bool,remaining: List<&2,U32>}
def decide_allowed(accepted: Bool,+required: List<&2,U32>,id: U32) -> Decision:
  match accepted:
    case False{}: Decision{False{},required}
    case True{}: Decision{True{},remove(required,id)}
def decide(round: U32,requested: U32,+id: U32,choice: U32,count: U32,+required: List<&2,U32>) -> Decision:
  decide_allowed(allowed(round,requested,id,choice,count,required),required,id)
