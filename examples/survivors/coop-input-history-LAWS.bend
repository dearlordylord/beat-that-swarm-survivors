import Base
import ./coop-prediction.bend as P
import ./coop-prediction-replay.bend as R
import ./player-movement.bend as M
import ./coop-input-history-SPEC.bend as H

# Guarantees: splitting any number of world steps preserves the exact final
# saturating world clock, including its behavior at the U32 limit.
# Why it matters: a replay boundary cannot change which clock labels later input.
law clock_partition:
  for +consumed:Nat
  for +pending:Nat
  for +worldTick:U32
  {H.tick_after(Nat.add(consumed,pending),worldTick) == H.tick_after(pending,H.tick_after(consumed,worldTick)) : U32}

# Guarantees: actual movement replay over a consumed world interval followed by
# a pending world interval equals replaying the entire interval from its anchor.
# Inputs retain their original target ticks on both sides of the boundary.
# Why it matters: ACK batching cannot change the F32 path, including neutral
# holes, reversals and clamping; no FIFO-to-world-time equivalence is assumed.
law world_partition_preserves_position:
  for +consumed:Nat
  for +pending:Nat
  for +worldTick:U32
  for +inputs:List<&2,P.Input>
  for +distance:F32
  for +point:M.Point
  {P.replay_position(Nat.add(consumed,pending),worldTick,inputs,distance,point) == P.replay_position(pending,H.tick_after(consumed,worldTick),inputs,distance,P.replay_position(consumed,worldTick,inputs,distance,point)) : M.Point}

# Guarantees: any detached cohort adapter has the same whole-world-interval
# partition rule. The second interval starts at the clock reached by the first.
# Why it matters: weapon cooldowns and contacts cannot be shifted merely by
# splitting replay at an acknowledgement; adapter physics are outside this law.
law world_partition_preserves_cohort:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +consumed:Nat
  for +pending:Nat
  for +worldTick:U32
  for +inputs:List<&2,P.Input>
  for +frame:A
  {R.advance_worlds(~A,~advance,Nat.add(consumed,pending),worldTick,inputs,frame) == R.advance_worlds(~A,~advance,pending,H.tick_after(consumed,worldTick),inputs,R.advance_worlds(~A,~advance,consumed,worldTick,inputs,frame)) : A}

# Guarantees: for every world interval and assigned input history, the generic
# cohort replay with the shared movement adapter equals actual camera replay.
# Why it matters: camera and cohort cannot use different input clocks or remove
# different neutral gaps while claiming the same predicted position.
law cohort_movement_matches_position:
  for +fuel:Nat
  for +worldTick:U32
  for +inputs:List<&2,P.Input>
  for +distance:F32
  for +point:M.Point
  {R.advance_worlds(~H.Moving,~H.movement,fuel,worldTick,inputs,H.Moving{distance,point}) == H.Moving{distance,P.replay_position(fuel,worldTick,inputs,distance,point)} : H.Moving}

# Guarantees: an input-free interval invokes the adapter with codes1/1 exactly
# once per world tick, rather than returning immediately for an empty row list.
# Why it matters: actual cohort time must still reach scheduled weapon births
# while waiting for a future assigned input. Neutral-code meaning is pinned by
# the separate axis/adapter laws; arbitrary adapters are not assumed neutral.
law neutral_worlds_are_not_compressed:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for +fuel:Nat
  for worldTick:U32
  for +frame:A
  {R.advance_worlds(~A,~advance,fuel,worldTick,[],frame) == H.neutral_worlds(~A,~advance,fuel,frame) : A}
