import Base
import ./coop-input-queue.bend as Q
import ./coop-prediction.bend as P
import ./coop-session.bend as S
import ./player-movement.bend as M
import ./coop-input-history-SPEC.bend as H

# Guarantees: for any chronological input history and any split into consumed
# prefix and pending suffix, executing both parts equals executing all ticks.
# Why it matters: transport batching may change the split, never the F32 path.
law fifo_partition:
  for +consumed: List<&2,Q.Tick>
  for +pending: List<&2,Q.Tick>
  for +distance: F32
  for +anchor: M.Point
  {H.path(List.append(&2,Q.Tick,consumed,pending),distance,anchor) == H.path(pending,distance,H.path(consumed,distance,anchor)) : M.Point}

# Guarantees: actual prediction replay of any chronological one-step tick list
# with sufficient slots follows precisely the independent sequential F32 path
# and consumes exactly one slot per tick. Room concerns only the tick count;
# setting budget60 covers every suffix that fits the production horizon.
# Why it matters: ACK batching cannot drop, repeat or reorder pending movements,
# including reversals and diagonal movement at the arena's clamped boundaries.
law pending_replay_preserves_path:
  for +rows: List<&2,Q.Tick>
  for +budget: U32
  for +distance: F32
  for +point: M.Point
  for room: H.Room(rows,budget)
  {P.replay(H.pending_rows(rows),distance,P.Replay{point,budget}) == P.Replay{H.path(rows,distance,point),H.budget_after(rows,budget)} : P.Replay}

# Guarantees: replaying any fitting pending suffix from the host's consumed
# prefix endpoint equals the guest's entire original input path, bit-for-bit.
# Why it matters: once ACK filtering selects the consumed prefix, changing that
# boundary cannot itself move the displayed player or camera.
law acknowledged_partition_preserves_path:
  for +consumed: List<&2,Q.Tick>
  for +pending: List<&2,Q.Tick>
  for +budget: U32
  for +distance: F32
  for +anchor: M.Point
  for room: H.Room(pending,budget)
  {P.replay(H.pending_rows(pending),distance,P.Replay{H.path(consumed,distance,anchor),budget}) == P.Replay{H.path(List.append(&2,Q.Tick,consumed,pending),distance,anchor),H.budget_after(pending,budget)} : P.Replay}

# Guarantees: acknowledging a sole one-step input preserves the already
# predicted point; the receipt identifies the consumed step, not its arrival.
# Why it matters: an ACK alone must not add another movement step or snap back.
law consumed_tick_preserves_position:
  for +point: M.Point
  for +distance: F32
  for +seq: U32
  for +x: U32
  for +y: U32
  for +prior: U32
  for +observation: U32
  for newer: {True{} == U32.is_gt(observation,prior) : Bool}
  {H.reconcile(H.state(distance,[P.Segment{seq,x,y,1,0}],1,prior,point),observation,distance,Q.receipt(S.receipt_fresh(),Some{Q.Tick{seq,x,y}}),point) == point : M.Point}

# Guarantees: after any consumed chronological prefix, acknowledging its last
# one-step input preserves one still-pending predicted step, bit-for-bit. The
# pending sequence is retained and differs from the acknowledged sequence, and
# the observation is newer. This theorem covers a suffix of exactly one tick.
# Why it matters: a new ACK must not drop or double the next predicted movement
# merely because a packet or world-step boundary happened between the two ticks.
law one_pending_tick_preserves_path:
  for +prefix: List<&2,Q.Tick>
  for +anchor: M.Point
  for +distance: F32
  for +ack: U32
  for +ackX: U32
  for +ackY: U32
  for +seq: U32
  for +x: U32
  for +y: U32
  for +prior: U32
  for +observation: U32
  for retained: {True{} == U32.is_ge(seq,ack) : Bool}
  for distinct: {False{} == U32.is_eq(seq,ack) : Bool}
  for newer: {True{} == U32.is_gt(observation,prior) : Bool}
  {H.reconcile(H.state(distance,[P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,0}],2,prior,H.step(distance,Q.Tick{seq,x,y},H.path(prefix,distance,anchor))),observation,distance,Q.receipt(S.receipt_fresh(),Some{Q.Tick{ack,ackX,ackY}}),H.path(prefix,distance,anchor)) == H.step(distance,Q.Tick{seq,x,y},H.path(prefix,distance,anchor)) : M.Point}
