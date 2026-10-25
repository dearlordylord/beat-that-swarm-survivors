import Base
import ./coop-weapon-prediction-policy.bend as F
import ./coop-prediction.bend as P
import ./pools.bend as PL

# These laws cover the production-used detached replay kernel and policies.
# Game factories/trajectories are shared runtime adapters, checked by the actual
# authority/forecast regression suite; this file does not claim to prove Game.
def fold_step(~A:Data,~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A,state:F.Replaying<A>,row:P.Segment) -> F.Replaying<A>: F.replay_one(~A,~advance,row,state)

# Guarantees: zero pending ticks preserve the entire detached state.
# Why it matters: a caught-up guest cannot manufacture another weapon frame.
law steps_zero:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +frame:A
  for x:U32
  for y:U32
  {F.advance_steps(~A,~advance,0n,frame,x,y) == frame : A}

# Guarantees: each requested tick calls the supplied shared game step once.
# Why it matters: replay must not double its clock or skip an animation tick.
law steps_successor:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +fuel:Nat
  for +frame:A
  for +x:U32
  for +y:U32
  {F.advance_steps(~A,~advance,1n+fuel,frame,x,y) == F.advance_steps(~A,~advance,fuel,advance(frame,x,y),x,y) : A}

# Guarantees: replay uses the unconsumed count clipped to the remaining budget,
# and subtracts exactly that same count from the budget.
# Why it matters: delayed ACKs must not multiply weapon ticks past the horizon.
law segment_budget_exact:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for seq:U32
  for +x:U32
  for +y:U32
  for +steps:U32
  for +consumed:U32
  for +frame:A
  for +budget:U32
  {F.replay_one(~A,~advance,P.Segment{seq,x,y,steps,consumed},F.Replaying{frame,budget}) == F.Replaying{F.advance_steps(~A,~advance,U32.to_nat(U32.min(budget,P.remaining(steps,consumed))),frame,x,y),(budget - U32.min(budget,P.remaining(steps,consumed)) : U32)} : F.Replaying<A>}

# Guarantees: chronological segments execute by a left fold over shared state.
# Why it matters: turns and projectile births cannot run in reverse packet order.
law chronological_replay_exact:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +rows:List<&2,P.Segment>
  for +state:F.Replaying<A>
  {F.replay_rows(~A,~advance,rows,state) == F.finish(~A,List.foldl(~&2,~P.Segment,~F.Replaying<A>,~fold_step(~A,~advance),rows,state)) : A}

# Guarantees: newest-first movement history is reversed exactly once, and the
# same sixty-tick budget bounds weapon replay and player movement replay.
# Why it matters: a single-pending-tick check cannot detect a reversed turn.
law active_history_order_exact:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +frame:A
  for px:F32
  for py:F32
  for distance:F32
  for +rows:List<&2,P.Segment>
  for age:U32
  for observation:U32
  {F.forecast(~A,~advance,frame,P.State{px,py,distance,True{},rows,age,observation}) == F.replay_rows(~A,~advance,List.reverse(&2,P.Segment,rows),F.Replaying{frame,60}) : A}

# Guarantees: disabling prediction preserves the full anchor despite pending ticks.
# Why it matters: observed reward pauses and death cannot replay stale attacks.
law disabled_history_preserves:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +frame:A
  for px:F32
  for py:F32
  for distance:F32
  for rows:List<&2,P.Segment>
  for age:U32
  for observation:U32
  {F.forecast(~A,~advance,frame,P.State{px,py,distance,False{},rows,age,observation}) == frame : A}

# Guarantees: an empty pending suffix is exactly a zero-step observation.
# Why it matters: the forecast must converge when authority consumes all inputs.
law empty_history_preserves:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +frame:A
  for px:F32
  for py:F32
  for distance:F32
  for age:U32
  for observation:U32
  {F.forecast(~A,~advance,frame,P.State{px,py,distance,True{},[],age,observation}) == frame : A}

# Guarantees: one unconsumed numbered tick calls the supplied game step once.
# Why it matters: receipt batching must not generate duplicate visual volleys.
law one_pending_tick_exact:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +frame:A
  for px:F32
  for py:F32
  for distance:F32
  for seq:U32
  for +x:U32
  for +y:U32
  for age:U32
  for observation:U32
  {F.forecast(~A,~advance,frame,P.State{px,py,distance,True{},[P.Segment{seq,x,y,1,0}],age,observation}) == advance(frame,x,y) : A}

# Guarantees: a denied step preserves every field, without invoking its adapter.
# Why it matters: a shared reward pause must not animate an additional attack.
law guard_refuses:
  for ~A:Data
  for ~advance:A -> U32 -> U32 -> A
  for +frame:A
  for x:U32
  for y:U32
  {F.guard(~A,~advance,False{},frame,x,y) == frame : A}

# Guarantees: an accepted step invokes its adapter exactly once.
# Why it matters: a guard cannot hide a dropped or duplicated local weapon tick.
law guard_accepts:
  for ~A:Data
  for ~advance:A -> U32 -> U32 -> A
  for +frame:A
  for +x:U32
  for +y:U32
  {F.guard(~A,~advance,True{},frame,x,y) == advance(frame,x,y) : A}

# Guarantees: advancement requires running phase, positive HP and valid axes.
# Why it matters: observed death/pauses and malformed input cannot forecast fire.
law eligibility_exact:
  for +phase:U32
  for +hp:U32
  for +x:U32
  for +y:U32
  {F.eligible(phase,hp,x,y) == Bool.and(Bool.and(U32.is_eq(phase,0),U32.is_gt(hp,0)),Bool.and(U32.is_le(x,2),U32.is_le(y,2))) : Bool}

# Guarantees: a previously displayed semantic shot is retained through the
# supplied continuity adapter, rather than reconstructed from a new aim history.
# Why it matters: receiving an ACK must not teleport an already flying shot.
law known_shot_retains_existing:
  for ~A:Data
  for ~retain:A -> A -> A
  for +previous:A
  for +fresh:A
  {F.prefer_existing(~A,~retain,Some{previous},fresh) == retain(previous,fresh) : A}

# Guarantees: a genuinely new semantic shot is taken from the current forecast.
# Why it matters: continuity cannot suppress a new volley at the predicted owner.
law new_shot_uses_forecast:
  for ~A:Data
  for ~retain:A -> A -> A
  for +fresh:A
  {F.prefer_existing(~A,~retain,None{},fresh) == fresh : A}

# Guarantees: visual shot identity uses owner, birth clock, weapon and volley slot.
# Why it matters: recycling a physical entity must not join unrelated shot lives.
law generation_exact:
  for +player:U32
  for +tick:U32
  for +age:U32
  for +owner:U32
  for +slot:U32
  {F.generation(player,tick,age,owner,slot) == U32.show(player) ++ ":" ++ U32.show((tick - age : U32)) ++ ":" ++ U32.show(owner) ++ ":" ++ U32.show((slot % 65536 : U32)) : String}

# Guarantees: owned physical identities advance by two slots from their start.
# Why it matters: host and guest cannot render or remove each other's slots.
law owned_slots_successor:
  for +fuel:Nat
  for +seed:U32
  {F.owned_seeds_go(1n+fuel,seed) == seed <> F.owned_seeds_go(fuel,(seed + 2 : U32)) : List<&2,U32>}

# Guarantees: each player owns its entire half of the current projectile pool.
# Why it matters: an expired own shot retained in interpolation must still be
# removed when its current forecast no longer contains that shot.
law owned_slots_layout:
  for +player:U32
  {F.owned_seeds(player) == F.owned_seeds_go(U32.to_nat((PL.player_count() / 2 : U32)),(PL.player_start() + player : U32)) : List<&2,U32>}
