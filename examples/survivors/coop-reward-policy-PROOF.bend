import Base
import ./coop-reward-policy.bend as R
import ./coop-reward-policy-LAWS.bend as L

def membership_exact(ids: List<&2,U32>,+id: U32) -> {R.contains(ids,id) == L.required_member(ids,id) : Bool}:
  match ids:
    case []: {==}
    case head <> rest:
      %membership_exact(rest,id) : {Bool.or(U32.is_eq(head,id),R.contains(rest,id)) == Bool.or(U32.is_eq(head,id),_) : Bool}
      {==}

def L.admission_exact(round,requested,id,choice,count,required):
  %membership_exact(required,id) : {R.allowed(round,requested,id,choice,count,required) == Bool.and(Bool.and(U32.is_eq(round,requested),_),U32.is_lt(choice,count)) : Bool}
  {==}

def removal_step(same: Bool,head: U32,rest: List<&2,U32>) -> {List.filter.put(U32,head,rest,Bool.not(same)) == L.retain_other(same,head,rest) : List<&2,U32>}:
  match same:
    case False{}: {==}
    case True{}: {==}

def L.removal_exact(required,id):
  match required:
    case []: {==}
    case +head <> rest:
      %L.removal_exact(rest,id) : {List.filter.put(U32,head,R.remove(rest,id),U32.is_ne(head,id)) == L.retain_other(U32.is_eq(head,id),head,_) : List<&2,U32>}
      removal_step(U32.is_eq(head,id),head,R.remove(rest,id))

def L.denied_preserves(round,requested,id,choice,count,required,denied):
  %denied : {R.decide_allowed(_,required,id) == R.Decision{False{},required} : R.Decision}
  {==}

def L.accepted_removes(round,requested,id,choice,count,required,accepted):
  %accepted : {R.decide_allowed(_,required,id) == R.Decision{True{},L.without_player(required,id)} : R.Decision}
  %L.removal_exact(required,id) : {R.Decision{True{},R.remove(required,id)} == R.Decision{True{},_} : R.Decision}
  {==}

def consumes_step(same: Bool,+head: U32,+rest: List<&2,U32>,+id: U32,eq: {same == U32.is_eq(head,id) : Bool},empty: {R.contains(rest,id) == False{} : Bool}) -> {R.contains(List.filter.put(U32,head,rest,Bool.not(same)),id) == False{} : Bool}:
  match same:
    case True{}: empty
    case False{}:
      %eq : {Bool.or(_,R.contains(rest,id)) == False{} : Bool}
      empty

def L.removal_consumes_player(required,id):
  match required:
    case []: {==}
    case +head <> rest:
      consumes_step(U32.is_eq(head,id),head,R.remove(rest,id),id,{==},L.removal_consumes_player(rest,id))
