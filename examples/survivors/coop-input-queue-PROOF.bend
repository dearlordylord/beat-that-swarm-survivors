import Base
import ./coop-input-queue.bend as Q
import ./coop-input-queue-LAWS.bend as L
import ./coop-session.bend as S

def L.reset_exact(round,world): {==}
def membership_choice(hit: Bool,+row: Q.Tick,+tail: List<&2,Q.Tick>) -> {Bool.or(hit,Bool.not(List.is_empty(&2,Q.Tick,tail))) == Bool.not(List.is_empty(&2,Q.Tick,Bool.pick(List<&2,Q.Tick>,hit,row <> tail,tail))) : Bool}:
  match hit:
    case False{}: {==}
    case True{}: {==}
def L.membership_exact(rows,target):
  match rows:
    case []: {==}
    case Q.Tick{+seq,+world,+x,+y} <> +tail:
      Equal.trans(Bool,Bool.or(U32.is_eq(world,target),Q.contains(tail,target)),Bool.or(U32.is_eq(world,target),Bool.not(List.is_empty(&2,Q.Tick,L.matches(tail,target)))),Bool.not(List.is_empty(&2,Q.Tick,Bool.pick(List<&2,Q.Tick>,U32.is_eq(world,target),Q.Tick{seq,world,x,y} <> L.matches(tail,target),L.matches(tail,target)))),Equal.cong(Bool,Bool,value => Bool.or(U32.is_eq(world,target),value),Q.contains(tail,target),Bool.not(List.is_empty(&2,Q.Tick,L.matches(tail,target))),L.membership_exact(tail,target)),membership_choice(U32.is_eq(world,target),Q.Tick{seq,world,x,y},L.matches(tail,target)))
def L.reason_exact(epoch,last,world,pending,phase,enabled,round,seq,target,x,y): {==}
def L.late_refused(round,last,world,pending,phase,enabled,epoch,seq,target,x,y,late):
  %late : {Q.push_decided(Bool.pick(U32,Bool.not(_),5,Bool.pick(U32,Bool.not(Q.activity(phase,enabled)),1,Bool.pick(U32,Bool.not(U32.is_eq(round,epoch)),2,Bool.pick(U32,Bool.not(U32.is_gt(seq,last)),3,Bool.pick(U32,Bool.not(Bool.and(U32.is_le(x,2),U32.is_le(y,2))),4,Bool.pick(U32,U32.is_gt((target - world : U32),60),6,Bool.pick(U32,Q.contains(pending,target),7,Bool.pick(U32,Bool.not(Nat.is_lt(List.length(&2,Q.Tick,pending),128n)),8,0)))))))),Q.State{round,last,world,pending},seq,target,x,y) == Q.Admission{Q.State{round,last,world,pending},False{},5} : Q.Admission}
  {==}
def L.accepted_appends_exact(round,last,world,pending,seq,target,x,y): {==}
def L.rejected_preserves(reason,state,seq,target,x,y,denied):
  %denied : {Q.push_choice(_,reason,state,seq,target,x,y) == Q.Admission{state,False{},reason} : Q.Admission}
  {==}

def find_choice(same: Bool,+row: Q.Tick,+tail: List<&2,Q.Tick>) -> {Q.find_selected(same,row,List.head(&2,Q.Tick,tail)) == List.head(&2,Q.Tick,Bool.pick(List<&2,Q.Tick>,same,row <> tail,tail)) : Maybe<&2,Q.Tick>}:
  match same:
    case False{}: {==}
    case True{}: {==}
def L.assigned_input_exact(rows,target):
  match rows:
    case []: {==}
    case Q.Tick{+seq,+world,+x,+y} <> +tail:
      Equal.trans(Maybe<&2,Q.Tick>,Q.find_selected(U32.is_eq(world,target),Q.Tick{seq,world,x,y},Q.find_at(tail,target)),Q.find_selected(U32.is_eq(world,target),Q.Tick{seq,world,x,y},List.head(&2,Q.Tick,L.matches(tail,target))),List.head(&2,Q.Tick,Bool.pick(List<&2,Q.Tick>,U32.is_eq(world,target),Q.Tick{seq,world,x,y} <> L.matches(tail,target),L.matches(tail,target))),Equal.cong(Maybe<&2,Q.Tick>,Maybe<&2,Q.Tick>,value => Q.find_selected(U32.is_eq(world,target),Q.Tick{seq,world,x,y},value),Q.find_at(tail,target),List.head(&2,Q.Tick,L.matches(tail,target)),L.assigned_input_exact(tail,target)),find_choice(U32.is_eq(world,target),Q.Tick{seq,world,x,y},L.matches(tail,target)))

def keep_choice(keep: Bool,+row: Q.Tick,+tail: List<&2,Q.Tick>) -> {Q.keep_selected(keep,row,tail) == Bool.pick(List<&2,Q.Tick>,keep,row <> tail,tail) : List<&2,Q.Tick>}:
  match keep:
    case False{}: {==}
    case True{}: {==}
def L.remaining_world_ticks_exact(rows,world):
  match rows:
    case []: {==}
    case Q.Tick{+seq,+target,+x,+y} <> +tail:
      Equal.trans(List<&2,Q.Tick>,Q.keep_selected(U32.is_gt(target,world),Q.Tick{seq,target,x,y},Q.future(tail,world)),Q.keep_selected(U32.is_gt(target,world),Q.Tick{seq,target,x,y},L.later(tail,world)),Bool.pick(List<&2,Q.Tick>,U32.is_gt(target,world),Q.Tick{seq,target,x,y} <> L.later(tail,world),L.later(tail,world)),Equal.cong(List<&2,Q.Tick>,List<&2,Q.Tick>,value => Q.keep_selected(U32.is_gt(target,world),Q.Tick{seq,target,x,y},value),Q.future(tail,world),L.later(tail,world),L.remaining_world_ticks_exact(tail,world)),keep_choice(U32.is_gt(target,world),Q.Tick{seq,target,x,y},L.later(tail,world)))
def L.next_world_tick_exact(round,last,world,pending,next): {==}
def take_choice(allowed: Bool,+round: U32,+last: U32,+world: U32,+pending: List<&2,Q.Tick>,+next: U32) -> {Q.take_selected(allowed,Q.State{round,last,world,pending},next) == Bool.pick(Q.Taken,allowed,Q.Taken{Q.State{round,last,next,Q.future(pending,next)},Q.find_at(pending,next)},Q.Taken{Q.State{round,last,world,pending},None{}}) : Q.Taken}:
  match allowed:
    case False{}: {==}
    case True{}: {==}
def L.take_exact(round,last,world,pending,next): take_choice(Q.next_allowed(Q.State{round,last,world,pending},next),round,last,world,pending,next)
def L.neutral_receipt_exact(world): {==}
def receipt_choice(applied: Bool,+seq: U32,+world: U32,+x: U32,+y: U32) -> {Q.receipt_selected(applied,seq,world,x,y) == Bool.pick(S.Receipt,applied,S.Receipt{seq,world,x,y,True{}},S.Receipt{0,world,1,1,False{}}) : S.Receipt}:
  match applied:
    case False{}: {==}
    case True{}: {==}
def L.assigned_receipt_exact(seq,world,target,x,y): receipt_choice(U32.is_eq(target,world),seq,world,x,y)
