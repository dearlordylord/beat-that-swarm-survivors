import Base
import ./coop-playback.bend as P
import ./coop-playback-LAWS.bend as L
import ../../vendor/bendlib/packages/bend-mathlib/list.bend as F

def L.fresh_exact():
  {==}

def L.admission_exact(o0,t0,a0,p0,b0,o1,t1,a1,p1,b1):
  {==}

def L.rejected_preserves_state(state,new):
  {==}

def L.initial_frame_visible(cursor,recovered,delay,new):
  {==}

def L.same_tick_replaces(new,old,tail):
  {==}

def L.later_tick_bounded(new,rows):
  {==}

def L.eviction_forward_recovery(tick,fraction,at,buffering,oldest):
  {==}

def L.no_eviction_preserves_cursor(cursor,oldest):
  {==}

def L.elapsed_exact(now,before):
  {==}

def L.fraction_exact(fraction,now,before,rate):
  {==}

def L.tick_saturates_exact(tick,units):
  {==}

def L.buffer_clock_exact(tick,fraction,previous,now,latest,delay):
  {==}

def L.underrun_holds_latest(tick,fraction,now,latest,mode):
  {==}

def L.running_cursor_exact(tick,fraction,now,latest,mode):
  {==}

def L.identity_exact(k0,t0,g0,x0,y0,a0,h0,o0,k1,t1,g1,x1,y1,a1,h1,o1):
  {==}

def L.unmatched_preserves_old(old,alpha):
  {==}

def L.different_lifetime_preserves_old(old,new,alpha):
  {==}

def L.blend_only_positions(key,kind,generation,x0,y0,age,hp,owner,k1,t1,g1,x1,y1,a1,h1,o1,alpha):
  {==}

def L.empty_sample(cursor,recovered,delay):
  {==}

def L.push_wiring(head,tail,cursor,recovered,delay,new):
  {==}

def L.advance_wiring(head,tail,cursor,recovered,delay,now):
  {==}

def L.bracket_selects_reached(old,new,tick,fraction,continue):
  {==}

def L.bracket_skips_future(continue,old,new,tick,fraction):
  {==}

def L.sample_wiring(head,tail,tick,fraction,at,buffering,recovered,delay):
  {==}

def L.sample_cohort_exact(observation,oldTick,oldAt,players,bodies,oldPlayers,oldBodies,next,nextTick,nextAt,nextPlayers,nextBodies,playerIndex,bodyIndex,tick,fraction,alpha):
  {==}

def L.ratio_exact(older,newer,tick,fraction):
  {==}

def L.delay_exact(own):
  {==}

def L.fresh_for_exact(own):
  {==}

def L.running_clock_wiring(tick,fraction,previous,now,latest,delay):
  {==}

def L.running_units_exact(tick,units,now,latest,mode):
  {==}

def L.push_existing_exact(head,tail,cursor,delay,new):
  {==}

def L.actor_lookup_exact(index,alpha,old):
  {==}

def L.retained_history_bounded(sameTick,new,rows):
  match sameTick rows:
    case False{} rows: F.length_take_le(&2,P.Indexed,rows,7n)
    case True{} Nil{}: {==}
    case True{} head <> tail: F.length_take_le(&2,P.Indexed,tail,7n)

def L.push_empty_wiring(cursor,recovered,delay,new):
  {==}

def L.accepted_push_wiring(head,tail,cursor,recovered,delay,new):
  {==}

def L.pushed_rows_wiring(rows,cursor,new,delay):
  {==}

def L.bounded_state_exact(rows,tick,fraction,at,buffering,oldest,delay):
  {==}

def L.oldest_empty(fallback):
  {==}

def L.oldest_cons(head,tail,fallback):
  {==}

def L.matched_found_wiring(new,old,alpha):
  {==}

def L.bracket_empty(new,tick,fraction):
  {==}

def L.bracket_cons(head,tail,new,tick,fraction):
  {==}

def L.advance_empty(cursor,recovered,delay,now):
  {==}

def L.actor_key_exact(key,kind,generation,x,y,age,hp,owner):
  {==}

def L.index_rows_empty(index):
  {==}

def L.index_rows_cons(head,tail,index):
  {==}

def L.indexed_exact(observation,tick,at,players,bodies):
  {==}

def L.received_at_exact(observation,tick,at,players,bodies):
  {==}

def L.frame_projection_exact(source,players,bodies):
  {==}

def L.world_tick_projection_exact(observation,tick,at,players,bodies):
  {==}

def L.observation_projection_exact(observation,tick,at,players,bodies):
  {==}

law bounded_count:
  for +rows:List<&2,P.Indexed>
  for cursor:P.Cursor
  for oldest:U32
  for delay:U32
  {L.frame_count(P.bounded_state(rows,cursor,oldest,delay)) == List.length(&2,P.Indexed,rows) : Nat}
def bounded_count(rows,cursor,oldest,delay):
  match cursor:
    case P.Cursor{tick,fraction,at,buffering}: {==}

law pushed_count:
  for +rows:List<&2,P.Indexed>
  for cursor:P.Cursor
  for new:P.Indexed
  for delay:U32
  {L.frame_count(P.pushed_rows(rows,cursor,new,delay)) == List.length(&2,P.Indexed,rows) : Nat}
def pushed_count(rows,cursor,new,delay):
  bounded_count(rows,cursor,P.world_tick(P.frame(P.oldest(rows,new))),delay)

law decided_bound:
  for accepted:Bool
  for +state:P.State
  for +new:P.Frame
  for bounded:{Nat.is_le(L.frame_count(state),8n) == True{} : Bool}
  {Nat.is_le(L.frame_count(P.push_decided(accepted,state,new)),8n) == True{} : Bool}
def decided_bound(accepted,state,new,bounded):
  match accepted state:
    case False{} state: bounded
    case True{} P.State{[],cursor,recovered,delay}: {==}
    case True{} P.State{+head <> +tail,+cursor,_,+delay}:
      +fresh = P.indexed(new)
      +same = U32.is_eq(P.world_tick(P.frame(head)),P.world_tick(P.frame(fresh)))
      +rows = P.retain(same,fresh,head <> tail)
      %Equal.sym(Nat,L.frame_count(P.pushed_rows(rows,cursor,fresh,delay)),List.length(&2,P.Indexed,rows),pushed_count(rows,cursor,fresh,delay)) : {Nat.is_le(_,8n) == True{} : Bool}
      L.retained_history_bounded(same,fresh,head <> tail)

def L.public_push_preserves_bound(state,new,bounded):
  match state:
    case P.State{[],cursor,recovered,delay}: {==}
    case P.State{+head <> tail,cursor,recovered,delay}:
      decided_bound(P.admissible(P.frame(head),new),P.State{head <> tail,cursor,recovered,delay},new,bounded)

def L.accepts_empty(cursor,recovered,delay,new):
  {==}
def L.accepts_latest(head,tail,cursor,recovered,delay,new):
  {==}
def L.push_admission_consistent(state,new):
  {==}

def L.rate_selected_exact(behind):
  {==}

def L.rate_for_exact(tick,latest,delay):
  {==}

def selected_rate_bounds(+behind:Bool) -> {Bool.and(Nat.is_ge(P.rate_selected(behind),60n),Nat.is_le(P.rate_selected(behind),66n)) == True{} : Bool}:
  match behind:
    case True{}: {==}
    case False{}: {==}

def L.rate_for_bounds(tick,latest,delay):
  selected_rate_bounds(Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),1n)))

def L.waiting_exact(mode):
  match mode:
    case P.Priming{}: {==}
    case P.Holding{}: {==}
    case P.Playing{}: {==}
    case P.Boosting{}: {==}

def L.refill_exact(mode,delay):
  match mode:
    case P.Priming{}: {==}
    case P.Holding{}: {==}
    case P.Playing{}: {==}
    case P.Boosting{}: {==}

def L.boost_exact(mode,tick,latest,delay):
  match mode:
    case P.Priming{}: {==}
    case P.Holding{}: {==}
    case P.Playing{}: {==}
    case P.Boosting{}: {==}

def L.mode_rate_exact(mode,tick,latest,delay):
  match mode:
    case P.Priming{}: {==}
    case P.Holding{}: {==}
    case P.Playing{}: {==}
    case P.Boosting{}: {==}

def L.buffering_projection_exact(rows,tick,fraction,at,mode,recovered,delay):
  L.waiting_exact(mode)
def L.selected_mode_exact(active):
  {==}

def wide_rate_bounds(+behind:Bool) -> {Bool.and(Nat.is_ge(P.rate_selected(behind),60n),Nat.is_le(P.rate_selected(behind),84n)) == True{} : Bool}:
  match behind:
    case True{}: {==}
    case False{}: {==}
def L.mode_rate_bounds(mode,tick,latest,delay):
  match mode:
    case P.Boosting{}: {==}
    case P.Priming{}: wide_rate_bounds(Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),1n)))
    case P.Holding{}: wide_rate_bounds(Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),1n)))
    case P.Playing{}: wide_rate_bounds(Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),1n)))
def L.resume_units_exact(fraction,now,previous,rate):
  {==}
def L.waiting_holds_exact(mode,tick,fraction,previous,now,latest,delay):
  {==}
def L.ready_resumes_exact(mode,tick,fraction,previous,now,latest,delay):
  {==}
def L.wait_clock_exact(mode,tick,fraction,previous,now,latest,delay):
  {==}
def L.move_clock_exact(mode,tick,fraction,previous,now,latest,delay):
  {==}
def L.holding_clock_wiring(tick,fraction,previous,now,latest,delay):
  {==}
def L.boosting_clock_wiring(tick,fraction,previous,now,latest,delay):
  {==}
