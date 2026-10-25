import Base
import ./coop-hit-journal.bend as J
import ./coop-hit-journal-LAWS.bend as L
import ./contact-id-set.bend as IDs
import ./contact-id-set-LAWS.bend as IDL
import ./contact-id-set-PROOF.bend as IDP
import ../../vendor/bendlib/packages/bend-mathlib/list.bend as MathList
import ../../vendor/bendlib/packages/bend-mathlib/nat.bend as MathNat

def contains_true(rows:List<&2,J.HitEvent>,+id:String) -> {J.contains_go(rows,id,True{}) == True{} : Bool}:
  match rows:
    case []: {==}
    case _ <> tail: contains_true(tail,id)
def contains_choice(+yes:Bool,+tail:List<&2,J.HitEvent>,+id:String) -> {J.contains_go(tail,id,yes) == Bool.or(yes,J.contains_go(tail,id,False{})) : Bool}:
  match yes:
    case True{}: contains_true(tail,id)
    case False{}: {==}
def seen_true(rows:List<&2,J.Seen>,+id:String) -> {J.seen_contains_go(rows,id,True{}) == True{} : Bool}:
  match rows:
    case []: {==}
    case J.Seen{_,_} <> tail: seen_true(tail,id)
def seen_choice(+yes:Bool,+tail:List<&2,J.Seen>,+id:String) -> {J.seen_contains_go(tail,id,yes) == Bool.or(yes,J.seen_contains_go(tail,id,False{})) : Bool}:
  match yes:
    case True{}: seen_true(tail,id)
    case False{}: {==}

def L.limits_exact(): ({==},{==})
def L.fresh_exact(epoch): {==}
def L.recent_exact(now,tick): {==}
def L.retention_exact(epoch,now,old,overflow,expired,incoming): {==}
def L.ingest_clock_exact(epoch,previous,now,old,overflow,expired,incoming): {==}
def L.trim_exact(rows): {==}
def L.playback_nil(epoch,seen,tick,acc): {==}
def L.playback_cons(head,tail,epoch,seen,tick,acc): {==}
def L.mark_false(seen,event): {==}
def L.mark_true(seen,event): {==}
def L.contains_nil(id): {==}
def L.contains_cons(head,tail,id): contains_choice(String.eq(J.event_key(head),id),tail,id)
def L.recent_nil(now): {==}
def L.recent_cons(head,tail,now): {==}
def L.seen_nil(id): {==}
def L.seen_cons(id,tick,tail,key): seen_choice(String.eq(id,key),tail,key)
def L.seen_recent_entry(rows,now): {==}
def L.seen_recent_nil(now,acc): {==}
def L.seen_recent_cons(id,tick,tail,now,acc): {==}
def L.seen_tick_exact(id,tick): {==}
def L.play_exact(epoch,seen,journalEpoch,now,rows,overflow,expired,display): {==}
def L.attach_exact(epoch,now,rows,overflow,expired): {==}
def L.attach_entry(rows): {==}
def L.attach_nil(acc): {==}
def L.attach_cons(head,tail,acc): {==}
def L.keep_event_true(head,tail): {==}
def L.keep_event_false(head,tail): {==}
def L.keep_seen_true(head,tail): {==}
def L.keep_seen_false(head,tail): {==}
def L.contains_go_nil(id,found): {==}
def L.contains_go_cons(head,tail,id,found): {==}
def L.contains_entry(rows,id): {==}
def L.seen_go_nil(id,found): {==}
def L.seen_go_cons(key,tick,tail,id,found): {==}
def L.seen_entry(rows,id): {==}
def L.event_key_exact(id,tick,kind,shotId,shotSeed,targetSeed,generation,fraction,x,y,tx,ty,radius,outcome): {==}
def L.event_tick_exact(id,tick,kind,shotId,shotSeed,targetSeed,generation,fraction,x,y,tx,ty,radius,outcome): {==}
def L.presentation_tick_exact(base,next,tick,fraction,alpha,players,bodies): {==}
def L.play_sample_exact(state,journal,sample): {==}

def L.collect_exact(state,epoch,now,events,overflow,expired): {==}
def L.contact_kind_exact(kind,pierce,selected): {==}

def L.event_count_nil(acc): {==}
def L.event_count_cons(head,tail,acc): {==}
def L.event_count_acc_exact(rows,acc):
  match rows:
    case []: {==}
    case head <> tail:
      %MathNat.add_succ(List.length(&2,J.HitEvent,tail),acc) : {J.event_count_go(tail,1n+acc) == _ : Nat}
      L.event_count_acc_exact(tail,1n+acc)
def L.event_count_exact(rows):
  %MathNat.add_zero(List.length(&2,J.HitEvent,rows)) : {J.event_count_go(rows,0n) == _ : Nat}
  L.event_count_acc_exact(rows,0n)
def L.emission_for_exact(rows,count): {==}
def L.emit_capped_entry(rows): {==}
def L.emission_exact(rows):
  %L.event_count_exact(rows) : {J.emit_capped(rows) == J.Emission{List.drop(&2,J.HitEvent,rows,Nat.sub(_,512n)),U32.from_nat(Nat.sub(List.length(&2,J.HitEvent,rows),512n))} : J.Emission}
  %L.event_count_exact(rows) : {J.emit_capped(rows) == J.Emission{List.drop(&2,J.HitEvent,rows,Nat.sub(J.event_count(rows),512n)),U32.from_nat(Nat.sub(_,512n))} : J.Emission}
  {==}
def L.emitted_rows_projection(rows,omitted): {==}
def L.emitted_omitted_projection(rows,omitted): {==}
law remainder_bound:
  for +n:Nat
  for +cap:Nat
  for comparison:Or(MathNat.le(n,cap),MathNat.le(cap,n))
  {Nat.is_le(Nat.sub(n,Nat.sub(n,cap)),cap) == True{} : Bool}
def remainder_bound(n,cap,comparison):
  match comparison:
    case Inl{+h}:
      %Equal.sym(Nat,Nat.sub(n,cap),0n,MathNat.sub_eq_zero_of_le(n,cap,h)) : {Nat.is_le(Nat.sub(n,_),cap) == True{} : Bool}
      %MathNat.sub_zero_sym(n) : {Nat.is_le(_,cap) == True{} : Bool}
      h
    case Inr{h}:
      %Equal.sym(Nat,Nat.sub(n,Nat.sub(n,cap)),cap,MathNat.sub_sub_self(n,cap,h)) : {Nat.is_le(_,cap) == True{} : Bool}
      MathNat.le_refl(cap)
def L.emitted_rows_bounded(rows):
  %Equal.sym(Nat,J.event_count(rows),List.length(&2,J.HitEvent,rows),L.event_count_exact(rows)) : {Nat.is_le(List.length(&2,J.HitEvent,List.drop(&2,J.HitEvent,rows,Nat.sub(_,512n))),512n) == True{} : Bool}
  %MathList.length_drop_sym(&2,J.HitEvent,rows,Nat.sub(List.length(&2,J.HitEvent,rows),512n)) : {Nat.is_le(_,512n) == True{} : Bool}
  remainder_bound(List.length(&2,J.HitEvent,rows),512n,MathNat.le_total(List.length(&2,J.HitEvent,rows),512n))
def L.add_omitted_exact(epoch,now,events,overflow,expired,omitted): {==}
def L.ingest_capped_exact(state,now,events,omitted): {==}

law or_reorder:
  for +a:Bool
  for +b:Bool
  for +c:Bool
  {Bool.or(b,Bool.or(a,c)) == Bool.or(Bool.or(a,b),c) : Bool}
def or_reorder(a,b,c):
  match a b c:
    case False{} False{} False{}: {==}
    case False{} False{} True{}: {==}
    case False{} True{} False{}: {==}
    case False{} True{} True{}: {==}
    case True{} False{} False{}: {==}
    case True{} False{} True{}: {==}
    case True{} True{} False{}: {==}
    case True{} True{} True{}: {==}
law or_false_right:
  for +a:Bool
  {Bool.or(a,False{}) == a : Bool}
def or_false_right(a):
  match a:
    case False{}: {==}
    case True{}: {==}
law contains_reverse_go:
  for +rows:List<&2,J.HitEvent>
  for +acc:List<&2,J.HitEvent>
  for +id:String
  {J.contains(List.reverse.go(&2,J.HitEvent,rows,acc),id) == Bool.or(J.contains(rows,id),J.contains(acc,id)) : Bool}
def contains_reverse_go(rows,acc,id):
  match rows:
    case []: {==}
    case head <> tail:
      %Equal.sym(Bool,J.contains(head <> tail,id),Bool.or(String.eq(J.event_key(head),id),J.contains(tail,id)),L.contains_cons(head,tail,id)) : {J.contains(List.reverse.go(&2,J.HitEvent,tail,head <> acc),id) == Bool.or(_,J.contains(acc,id)) : Bool}
      %or_reorder(String.eq(J.event_key(head),id),J.contains(tail,id),J.contains(acc,id)) : {J.contains(List.reverse.go(&2,J.HitEvent,tail,head <> acc),id) == _ : Bool}
      %L.contains_cons(head,acc,id) : {J.contains(List.reverse.go(&2,J.HitEvent,tail,head <> acc),id) == Bool.or(J.contains(tail,id),_) : Bool}
      contains_reverse_go(tail,head <> acc,id)
law contains_reverse:
  for +rows:List<&2,J.HitEvent>
  for +id:String
  {J.contains(List.reverse(&2,J.HitEvent,rows),id) == J.contains(rows,id) : Bool}
def contains_reverse(rows,id):
  %or_false_right(J.contains(rows,id)) : {J.contains(List.reverse(&2,J.HitEvent,rows),id) == _ : Bool}
  contains_reverse_go(rows,[],id)
law reversed_choice:
  for +duplicate:Bool
  for +head:J.HitEvent
  for +rows:List<&2,J.HitEvent>
  {J.append_fresh(duplicate,head,List.reverse(&2,J.HitEvent,rows)) == List.reverse(&2,J.HitEvent,Bool.pick(List<&2,J.HitEvent>,duplicate,rows,List.append(&2,J.HitEvent,rows,[head]))) : List<&2,J.HitEvent>}
def reversed_choice(duplicate,head,rows):
  match duplicate:
    case True{}: {==}
    case False{}: MathList.reverse_append_sym(&2,J.HitEvent,rows,[head])
law restored_reference_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +rows:List<&2,J.HitEvent>
  {List.reverse(&2,J.HitEvent,J.append_reverse(head <> tail,List.reverse(&2,J.HitEvent,rows))) == List.reverse(&2,J.HitEvent,J.append_reverse(tail,List.reverse(&2,J.HitEvent,Bool.pick(List<&2,J.HitEvent>,J.contains(rows,J.event_key(head)),rows,List.append(&2,J.HitEvent,rows,[head]))))) : List<&2,J.HitEvent>}
def restored_reference_cons(head,tail,rows):
  %Equal.sym(Bool,J.contains(List.reverse(&2,J.HitEvent,rows),J.event_key(head)),J.contains(rows,J.event_key(head)),contains_reverse(rows,J.event_key(head))) : {List.reverse(&2,J.HitEvent,J.append_reverse(tail,J.append_fresh(_,head,List.reverse(&2,J.HitEvent,rows)))) == List.reverse(&2,J.HitEvent,J.append_reverse(tail,List.reverse(&2,J.HitEvent,Bool.pick(List<&2,J.HitEvent>,J.contains(rows,J.event_key(head)),rows,List.append(&2,J.HitEvent,rows,[head]))))) : List<&2,J.HitEvent>}
  %reversed_choice(J.contains(rows,J.event_key(head)),head,rows) : {List.reverse(&2,J.HitEvent,J.append_reverse(tail,J.append_fresh(J.contains(rows,J.event_key(head)),head,List.reverse(&2,J.HitEvent,rows)))) == List.reverse(&2,J.HitEvent,J.append_reverse(tail,_)) : List<&2,J.HitEvent>}
  {==}
def L.append_fresh_duplicate(head,rows): {==}
def L.append_fresh_new(head,rows): {==}
def L.append_reverse_nil(rows): {==}
def L.append_reverse_cons(head,tail,rows): {==}

def L.event_index_nil(): {==}
def L.event_index_cons(head,tail): {==}
def L.event_index_membership(rows,id):
  match rows:
    case []: IDL.contains_empty(id)
    case head <> tail:
      %Equal.sym(Bool,J.contains(head <> tail,id),Bool.or(String.eq(J.event_key(head),id),J.contains(tail,id)),L.contains_cons(head,tail,id)) : {IDs.contains(IDs.insert(J.event_index(tail),J.event_key(head)),id) == _ : Bool}
      %L.event_index_membership(tail,id) : {IDs.contains(IDs.insert(J.event_index(tail),J.event_key(head)),id) == Bool.or(String.eq(J.event_key(head),id),_) : Bool}
      IDL.contains_insert(J.event_key(head),id,J.event_index(tail))
def L.indexed_insert_duplicate(index,id): {==}
def L.indexed_insert_new(index,id): {==}
def L.append_indexed_nil(rows,index): {==}
def L.append_indexed_cons(head,tail,rows,index): {==}
def L.append_indexed_start_exact(incoming,rows): {==}
law indexed_step_correct:
  for +duplicate:Bool
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +rows:List<&2,J.HitEvent>
  for next:@+nextRows:List<&2,J.HitEvent> -> {J.append_indexed(tail,nextRows,J.event_index(nextRows)) == J.append_reverse(tail,nextRows) : List<&2,J.HitEvent>}
  {J.append_indexed(tail,J.append_fresh(duplicate,head,rows),J.indexed_insert(duplicate,J.event_index(rows),J.event_key(head))) == J.append_reverse(tail,J.append_fresh(duplicate,head,rows)) : List<&2,J.HitEvent>}
def indexed_step_correct(duplicate,head,tail,rows,next):
  match duplicate:
    case True{}: next(rows)
    case False{}: next(head <> rows)
def L.append_indexed_refines_reference(incoming,rows):
  match incoming:
    case []: {==}
    case head <> tail:
      %Equal.sym(Bool,IDs.contains(J.event_index(rows),J.event_key(head)),J.contains(rows,J.event_key(head)),L.event_index_membership(rows,J.event_key(head))) : {J.append_indexed(tail,J.append_fresh(_,head,rows),J.indexed_insert(IDs.contains(J.event_index(rows),J.event_key(head)),J.event_index(rows),J.event_key(head))) == J.append_reverse(tail,J.append_fresh(J.contains(rows,J.event_key(head)),head,rows)) : List<&2,J.HitEvent>}
      %Equal.sym(Bool,IDs.contains(J.event_index(rows),J.event_key(head)),J.contains(rows,J.event_key(head)),L.event_index_membership(rows,J.event_key(head))) : {J.append_indexed(tail,J.append_fresh(J.contains(rows,J.event_key(head)),head,rows),J.indexed_insert(_,J.event_index(rows),J.event_key(head))) == J.append_reverse(tail,J.append_fresh(J.contains(rows,J.event_key(head)),head,rows)) : List<&2,J.HitEvent>}
      indexed_step_correct(J.contains(rows,J.event_key(head)),head,tail,rows,more => L.append_indexed_refines_reference(tail,more))
def L.indexed_state_membership(rows,index,id,coherent):
  %Equal.sym(IDs.IdSet,index,J.event_index(rows),coherent) : {IDs.contains(_,id) == J.contains(rows,id) : Bool}
  L.event_index_membership(rows,id)
def L.coherent_index_refinement(incoming,rows,index,coherent):
  %Equal.sym(IDs.IdSet,index,J.event_index(rows),coherent) : {J.append_indexed(incoming,rows,_) == J.append_reverse(incoming,rows) : List<&2,J.HitEvent>}
  L.append_indexed_refines_reference(incoming,rows)
def L.append_unique_indexed_empty(rows): {==}
def L.append_unique_indexed_nonempty(head,tail,rows): {==}
def L.append_unique_entry(incoming,rows):
  match incoming:
    case []: Equal.sym(List<&2,J.HitEvent>,List.reverse(&2,J.HitEvent,List.reverse(&2,J.HitEvent,rows)),rows,MathList.reverse_reverse(&2,J.HitEvent,rows))
    case head <> tail:
      %L.append_indexed_refines_reference(head <> tail,List.reverse(&2,J.HitEvent,rows)) : {List.reverse(&2,J.HitEvent,J.append_indexed_start(head <> tail,List.reverse(&2,J.HitEvent,rows))) == List.reverse(&2,J.HitEvent,_) : List<&2,J.HitEvent>}
      {==}
def L.append_nil(rows): {==}
def L.append_cons(head,tail,rows):
  %Equal.sym(List<&2,J.HitEvent>,J.append_unique(head <> tail,rows),List.reverse(&2,J.HitEvent,J.append_reverse(head <> tail,List.reverse(&2,J.HitEvent,rows))),L.append_unique_entry(head <> tail,rows)) : {_ == J.append_unique(tail,Bool.pick(List<&2,J.HitEvent>,J.contains(rows,J.event_key(head)),rows,List.append(&2,J.HitEvent,rows,[head]))) : List<&2,J.HitEvent>}
  %Equal.sym(List<&2,J.HitEvent>,J.append_unique(tail,Bool.pick(List<&2,J.HitEvent>,J.contains(rows,J.event_key(head)),rows,List.append(&2,J.HitEvent,rows,[head]))),List.reverse(&2,J.HitEvent,J.append_reverse(tail,List.reverse(&2,J.HitEvent,Bool.pick(List<&2,J.HitEvent>,J.contains(rows,J.event_key(head)),rows,List.append(&2,J.HitEvent,rows,[head]))))),L.append_unique_entry(tail,Bool.pick(List<&2,J.HitEvent>,J.contains(rows,J.event_key(head)),rows,List.append(&2,J.HitEvent,rows,[head])))) : {List.reverse(&2,J.HitEvent,J.append_reverse(head <> tail,List.reverse(&2,J.HitEvent,rows))) == _ : List<&2,J.HitEvent>}
  restored_reference_cons(head,tail,rows)

def L.seen_key_exact(id,tick): {==}
def L.seen_index_nil(): {==}
def L.seen_index_cons(head,tail): {==}
def L.seen_index_membership(seen,id):
  match seen:
    case []: IDL.contains_empty(id)
    case J.Seen{key,at} <> tail:
      %Equal.sym(Bool,J.seen_contains(J.Seen{key,at} <> tail,id),Bool.or(String.eq(key,id),J.seen_contains(tail,id)),L.seen_cons(key,at,tail,id)) : {IDs.contains(IDs.insert(J.seen_index(tail),key),id) == _ : Bool}
      %L.seen_index_membership(tail,id) : {IDs.contains(IDs.insert(J.seen_index(tail),key),id) == Bool.or(String.eq(key,id),_) : Bool}
      IDL.contains_insert(key,id,J.seen_index(tail))
def L.indexed_play_admission(seen,head,tick):
  %L.seen_index_membership(seen,J.event_key(head)) : {Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(J.seen_index(seen),J.event_key(head)))) == Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(_)) : Bool}
  {==}
def L.play_indexed_nil(epoch,seen,tick,acc,index): {==}
def L.play_indexed_cons(head,tail,epoch,seen,tick,acc,index): {==}
law indexed_play_step_correct:
  for +accept:Bool
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for +tick:U32
  for +acc:List<&2,J.HitEvent>
  for next:@+newSeen:List<&2,J.Seen> -> @+newAcc:List<&2,J.HitEvent> -> {J.play_indexed(tail,epoch,newSeen,tick,newAcc,J.seen_index(newSeen)) == J.play_rows_go(tail,epoch,newSeen,tick,newAcc) : J.Played}
  {J.play_indexed(tail,epoch,J.mark(accept,seen,head),tick,J.keep_event(accept,head,acc),J.indexed_insert(Bool.not(accept),J.seen_index(seen),J.event_key(head))) == J.play_rows_go(tail,epoch,J.mark(accept,seen,head),tick,J.keep_event(accept,head,acc)) : J.Played}
def indexed_play_step_correct(accept,head,tail,epoch,seen,tick,acc,next):
  match accept:
    case True{}: next(J.Seen{J.event_key(head),J.event_tick(head)} <> seen,head <> acc)
    case False{}: next(seen,acc)
def L.indexed_play_refines_reference(rows,epoch,seen,tick,acc):
  match rows:
    case []: {==}
    case head <> tail:
      %Equal.sym(Bool,Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(J.seen_index(seen),J.event_key(head)))),Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),L.indexed_play_admission(seen,head,tick)) : {J.play_indexed(tail,epoch,J.mark(_,seen,head),tick,J.keep_event(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(J.seen_index(seen),J.event_key(head)))),head,acc),J.indexed_insert(Bool.not(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(J.seen_index(seen),J.event_key(head))))),J.seen_index(seen),J.event_key(head))) == J.play_rows_go(tail,epoch,J.mark(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),seen,head),tick,J.keep_event(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),head,acc)) : J.Played}
      %Equal.sym(Bool,Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(J.seen_index(seen),J.event_key(head)))),Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),L.indexed_play_admission(seen,head,tick)) : {J.play_indexed(tail,epoch,J.mark(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),seen,head),tick,J.keep_event(_,head,acc),J.indexed_insert(Bool.not(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(J.seen_index(seen),J.event_key(head))))),J.seen_index(seen),J.event_key(head))) == J.play_rows_go(tail,epoch,J.mark(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),seen,head),tick,J.keep_event(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),head,acc)) : J.Played}
      %Equal.sym(Bool,Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(J.seen_index(seen),J.event_key(head)))),Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),L.indexed_play_admission(seen,head,tick)) : {J.play_indexed(tail,epoch,J.mark(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),seen,head),tick,J.keep_event(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),head,acc),J.indexed_insert(Bool.not(_),J.seen_index(seen),J.event_key(head))) == J.play_rows_go(tail,epoch,J.mark(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),seen,head),tick,J.keep_event(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),head,acc)) : J.Played}
      indexed_play_step_correct(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),head,tail,epoch,seen,tick,acc,newSeen => newAcc => L.indexed_play_refines_reference(tail,epoch,newSeen,tick,newAcc))
def L.coherent_play_refinement(rows,epoch,seen,tick,acc,index,coherent):
  %Equal.sym(IDs.IdSet,index,J.seen_index(seen),coherent) : {J.play_indexed(rows,epoch,seen,tick,acc,_) == J.play_rows_go(rows,epoch,seen,tick,acc) : J.Played}
  L.indexed_play_refines_reference(rows,epoch,seen,tick,acc)
def L.play_rows_indexed_entry(rows,epoch,seen,tick): {==}
def L.playback_entry(rows,epoch,seen,tick): L.indexed_play_refines_reference(rows,epoch,seen,tick,[])
