import Base
import ./coop-prediction-replay.bend as R
import ./coop-prediction.bend as P

# Guarantees: an empty world interval preserves its entire detached anchor.
# Why it matters: replay cannot invent another combat tick after catching up.
law worlds_zero:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for tick:U32
  for inputs:List<&2,P.Input>
  for +frame:A
  {R.advance_worlds(~A,~advance,0n,tick,inputs,frame) == frame : A}

# Guarantees: each world tick advances the cohort once using only that tick's
# assigned input, then continues at the next clock value with the full history.
# Why it matters: commands42..44 cannot be compressed into world ticks39..41.
law worlds_successor:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +fuel:Nat
  for +tick:U32
  for +inputs:List<&2,P.Input>
  for +frame:A
  {R.advance_worlds(~A,~advance,1n+fuel,tick,inputs,frame) == R.advance_worlds(~A,~advance,fuel,P.after(tick,1),inputs,R.step_direction(~A,~advance,frame,P.input_at(inputs,P.after(tick,1)))) : A}

# Guarantees: a world interval with no commands still invokes every world step
# with codes1/1, which the separately pinned axis adapter maps to neutral.
# Why it matters: cooldowns, births and contact age must not stop in input holes.
law neutral_world_successor:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +fuel:Nat
  for +tick:U32
  for +frame:A
  {R.advance_worlds(~A,~advance,1n+fuel,tick,[],frame) == R.advance_worlds(~A,~advance,fuel,P.after(tick,1),[],advance(frame,1,1)) : A}

# Guarantees: active replay spans the entire bounded anchor-to-display interval.
# Why it matters: replay length is world time, never pending command count.
law forecast_world_interval_exact:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +frame:A
  for x:F32
  for y:F32
  for distance:F32
  for +inputs:List<&2,P.Input>
  for +anchor:U32
  for +display:U32
  for observation:U32
  for last:U32
  {R.forecast(~A,~advance,frame,P.State{x,y,distance,True{},inputs,anchor,display,observation,last}) == R.advance_worlds(~A,~advance,U32.to_nat(P.world_count(anchor,display)),anchor,inputs,frame) : A}

# Guarantees: inactive prediction preserves the complete received anchor.
# Why it matters: pause/death cannot replay speculative attacks or movement.
law forecast_disabled_preserves:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +frame:A
  for x:F32
  for y:F32
  for distance:F32
  for inputs:List<&2,P.Input>
  for anchor:U32
  for display:U32
  for observation:U32
  for last:U32
  {R.forecast(~A,~advance,frame,P.State{x,y,distance,False{},inputs,anchor,display,observation,last}) == frame : A}

# Guarantees: a denied game step does not call the detached simulation adapter.
# Why it matters: the guard must not advance a paused world through a side path.
law guard_refuses:
  for ~A:Data
  for ~advance:A -> U32 -> U32 -> A
  for +frame:A
  for x:U32
  for y:U32
  {R.guard(~A,~advance,False{},frame,x,y) == frame : A}

# Guarantees: an accepted game step invokes its adapter exactly once.
# Why it matters: the guard cannot duplicate or silently drop a world step.
law guard_accepts:
  for ~A:Data
  for ~advance:A -> U32 -> U32 -> A
  for +frame:A
  for +x:U32
  for +y:U32
  {R.guard(~A,~advance,True{},frame,x,y) == advance(frame,x,y) : A}

# Guarantees: forecast requires a living player in running phase and valid axes.
# Why it matters: an observed pause/death cannot create an extra volley.
law eligibility_exact:
  for +phase:U32
  for +hp:U32
  for +x:U32
  for +y:U32
  {R.eligible(phase,hp,x,y) == Bool.and(Bool.and(U32.is_eq(phase,0),U32.is_gt(hp,0)),Bool.and(U32.is_le(x,2),U32.is_le(y,2))) : Bool}

# Guarantees: the identity string contains player, tick-age, owner base and
# logical slot modulo65536 in that exact order; no collision theorem is claimed.
# Why it matters: renderer grouping must use the supplied semantic fields instead
# of silently substituting a physical pool address.
law generation_exact:
  for +player:U32
  for +tick:U32
  for +age:U32
  for +owner:U32
  for +slot:U32
  {R.generation(player,tick,age,owner,slot) == U32.show(player) ++ ":" ++ U32.show((tick - age : U32)) ++ ":" ++ U32.show(owner) ++ ":" ++ U32.show(slot) : String}
