import Base
import ../projectile-contact.bend as C
import LAWS.bend as Laws
import ../proof-facts.bend as F
import ../../../vendor/bendlib/packages/bend-mathlib/list.bend as ML
import ../../../vendor/bendlib/packages/bend-mathlib/nat.bend as N

def Laws.initial_contact_is_not_lost(a,b,c): {==}
def Laws.separated_without_approach_misses(a,b,c): {==}
def Laws.no_real_entry_misses(b,c,disc): {==}
def Laws.entry_gate_exact(inside,time):
  match inside:
    case True{}: {==}
    case False{}: {==}
def Laws.excluded_target_preserves_contacts(seed,impact,rows): {==}
def Laws.missed_target_preserves_contacts(seed,rows): {==}
def Laws.admitted_hit_is_inserted(seed,time,rows): {==}

def inserted_count(before:Bool,+item:C.Contact,+head:C.Contact,+tail:List<&2,C.Contact>,+later:List<&2,C.Contact>,ih:{List.length(&2,C.Contact,later) == 1n+List.length(&2,C.Contact,tail) : Nat}) -> {List.length(&2,C.Contact,C.insert_at(before,item,head,tail,later)) == 1n+List.length(&2,C.Contact,head <> tail) : Nat}:
  match before:
    case True{}: {==}
    case False{}: Equal.cong(Nat,Nat,n => 1n+n,List.length(&2,C.Contact,later),1n+List.length(&2,C.Contact,tail),ih)
def Laws.ordering_preserves_contact_count(item,rows):
  match rows:
    case []: {==}
    case +head <> +tail: inserted_count(C.comes_first(item,head),item,head,tail,C.insert(item,tail),Laws.ordering_preserves_contact_count(item,tail))
def ids_count(+rows:List<&2,C.Contact>) -> {List.length(&2,U32,C.ids(rows)) == List.length(&2,C.Contact,rows) : Nat}:
  match rows:
    case []: {==}
    case C.Contact{_,_} <> +tail: Equal.cong(Nat,Nat,n => 1n+n,List.length(&2,U32,C.ids(tail)),List.length(&2,C.Contact,tail),ids_count(tail))
def Laws.exact_budget_consumption(budget,rows):
  Equal.trans(Nat,List.length(&2,U32,C.ids(List.take(&2,C.Contact,rows,U32.to_nat(budget)))),List.length(&2,C.Contact,List.take(&2,C.Contact,rows,U32.to_nat(budget))),Nat.min(U32.to_nat(budget),List.length(&2,C.Contact,rows)),ids_count(List.take(&2,C.Contact,rows,U32.to_nat(budget))),ML.length_take(&2,C.Contact,rows,U32.to_nat(budget)))
def Laws.earlier_contact_precedes_head(item,head,tail,earlier):
  %earlier : {C.insert_at(_,item,head,tail,C.insert(item,tail)) == item <> head <> tail : List<&2,C.Contact>}
  {==}
def Laws.equal_time_uses_identity(left,right,time):
  Equal.cong(Cmp,Cmp,order => C.tie_order(order,left,right),U32.cmp(C.time_word(time),C.time_word(time)),EQ{},F.u32_cmp_refl(C.time_word(time)))

def inserted_tally(~observed:C.Contact -> Bool,before:Bool,+item:C.Contact,+head:C.Contact,+tail:List<&2,C.Contact>,+later:List<&2,C.Contact>,ih:{Laws.tally(~observed,later) == Nat.add(Bool.pick(Nat,observed(item),1n,0n),Laws.tally(~observed,tail)) : Nat}) -> {Laws.tally(~observed,C.insert_at(before,item,head,tail,later)) == Nat.add(Bool.pick(Nat,observed(item),1n,0n),Laws.tally(~observed,head <> tail)) : Nat}:
  match before:
    case True{}: {==}
    case False{}:
      Equal.trans(Nat,Nat.add(Bool.pick(Nat,observed(head),1n,0n),Laws.tally(~observed,later)),Nat.add(Bool.pick(Nat,observed(head),1n,0n),Nat.add(Bool.pick(Nat,observed(item),1n,0n),Laws.tally(~observed,tail))),Nat.add(Bool.pick(Nat,observed(item),1n,0n),Nat.add(Bool.pick(Nat,observed(head),1n,0n),Laws.tally(~observed,tail))),Equal.cong(Nat,Nat,n => Nat.add(Bool.pick(Nat,observed(head),1n,0n),n),Laws.tally(~observed,later),Nat.add(Bool.pick(Nat,observed(item),1n,0n),Laws.tally(~observed,tail)),ih),N.add_left_comm(Bool.pick(Nat,observed(head),1n,0n),Bool.pick(Nat,observed(item),1n,0n),Laws.tally(~observed,tail)))
def Laws.ordering_preserves_payloads(observed,item,rows):
  match rows:
    case []: {==}
    case +head <> +tail: inserted_tally(~observed,C.comes_first(item,head),item,head,tail,C.insert(item,tail),Laws.ordering_preserves_payloads(~observed,item,tail))

def prefix_ids(+rows:List<&2,C.Contact>,+count:Nat) -> {C.ids(List.take(&2,C.Contact,rows,count)) == List.take(&2,U32,C.ids(rows),count) : List<&2,U32>}:
  match rows count:
    case [] _: {==}
    case _ <> _ 0n: {==}
    case C.Contact{+seed,_} <> +tail 1n+rest:
      Equal.cong(List<&2,U32>,List<&2,U32>,xs => seed <> xs,C.ids(List.take(&2,C.Contact,tail,rest)),List.take(&2,U32,C.ids(tail),rest),prefix_ids(tail,rest))
def Laws.budget_preserves_prefix_identities(budget,rows): prefix_ids(rows,U32.to_nat(budget))
def Laws.public_single_hit_is_collected(seed,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,r,time,visited,fresh,intersecting):
  %fresh : {C.collect(_,seed,C.sweep(x0,y0,x1,y1,ex0,ey0,ex1,ey1,(radius + r : F32)),[]) == C.Contact{seed,time} <> [] : List<&2,C.Contact>}
  %intersecting : {C.add(seed,_,[]) == C.Contact{seed,time} <> [] : List<&2,C.Contact>}
  {==}

def Laws.public_visited_targets_are_excluded(rows,x0,y0,x1,y1,radius,visited,excluded):
  match rows:
    case []: {==}
    case C.Target{+seed,+ex0,+ey0,+ex1,+ey1,+r} <> +tail:
      +headExcluded = F.and_left(C.contains(visited,seed),Laws.all_visited(tail,visited),excluded)
      +tailExcluded = F.and_right(C.contains(visited,seed),Laws.all_visited(tail,visited),excluded)
      %headExcluded : {C.collect(_,seed,C.sweep(x0,y0,x1,y1,ex0,ey0,ex1,ey1,(radius + r : F32)),C.contacts(tail,x0,y0,x1,y1,radius,visited)) == [] : List<&2,C.Contact>}
      Laws.public_visited_targets_are_excluded(tail,x0,y0,x1,y1,radius,visited,tailExcluded)
def Laws.relative_endpoints_are_used(x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius): {==}
