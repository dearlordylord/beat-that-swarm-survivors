import Base
import ./coop-input-queue.bend as Q
import ./coop-session.bend as S

def matches(rows: List<&2,Q.Tick>,+target: U32) -> List<&2,Q.Tick>:
  match rows:
    case []: []
    case Q.Tick{+seq,+world,+x,+y} <> tail:
      +rest = matches(tail,target)
      Bool.pick(List<&2,Q.Tick>,U32.is_eq(world,target),Q.Tick{seq,world,x,y} <> rest,rest)
def later(rows: List<&2,Q.Tick>,+resolved: U32) -> List<&2,Q.Tick>:
  match rows:
    case []: []
    case Q.Tick{+seq,+world,+x,+y} <> tail:
      +rest = later(tail,resolved)
      Bool.pick(List<&2,Q.Tick>,U32.is_gt(world,resolved),Q.Tick{seq,world,x,y} <> rest,rest)

# Guarantees: reset preserves the authoritative world clock and empties inputs.
# Why it matters: a reward epoch cannot inherit movement from before its pause.
law reset_exact:
  for +round: U32
  for +world: U32
  {Q.fresh(round,world) == Q.State{round,0,world,[]} : Q.State}

# Guarantees: slot membership means exactly that at least one input has the
# requested world target, independent of transport sequence or list order.
# Why it matters: a broken helper must not silently admit duplicate world slots.
law membership_exact:
  for +rows: List<&2,Q.Tick>
  for +target: U32
  {Q.contains(rows,target) == Bool.not(List.is_empty(&2,Q.Tick,matches(rows,target))) : Bool}

# Guarantees: the public reason pins every admission criterion and refusal code.
# Why it matters: a timestamp cannot be accepted late, outside the bounded future
# window, twice for the same world step, or for a different reward epoch.
law reason_exact:
  for +epoch: U32
  for +last: U32
  for +world: U32
  for +pending: List<&2,Q.Tick>
  for +phase: U32
  for +enabled: Bool
  for +round: U32
  for +seq: U32
  for +target: U32
  for +x: U32
  for +y: U32
  {Q.reason(Q.State{epoch,last,world,pending},phase,enabled,round,seq,target,x,y) == Bool.pick(U32,Bool.not(U32.is_gt(target,world)),5,Bool.pick(U32,Bool.not(Bool.and(U32.is_eq(phase,0),enabled)),1,Bool.pick(U32,Bool.not(U32.is_eq(epoch,round)),2,Bool.pick(U32,Bool.not(U32.is_gt(seq,last)),3,Bool.pick(U32,Bool.not(Bool.and(U32.is_le(x,2),U32.is_le(y,2))),4,Bool.pick(U32,U32.is_gt((target - world : U32),60),6,Bool.pick(U32,Q.contains(pending,target),7,Bool.pick(U32,Bool.not(Nat.is_lt(List.length(&2,Q.Tick,pending),128n)),8,0)))))))) : U32}

# Guarantees: any expired target is explicitly refused as Late without changing
# any pending input, regardless of transport sequence or arrival batching.
# Why it matters: an input for tick40 arriving after tick44 cannot become tick45.
law late_refused:
  for +round: U32
  for +last: U32
  for +world: U32
  for +pending: List<&2,Q.Tick>
  for phase: U32
  for enabled: Bool
  for epoch: U32
  for seq: U32
  for +target: U32
  for x: U32
  for y: U32
  for late: {False{} == U32.is_gt(target,world) : Bool}
  {Q.push_active(Q.State{round,last,world,pending},phase,enabled,epoch,seq,target,x,y) == Q.Admission{Q.State{round,last,world,pending},False{},5} : Q.Admission}

# Guarantees: only an accepted input updates sequence freshness and appends its
# exact target; the current world clock is never advanced by packet receipt.
# Why it matters: arrival order may not relabel an input or accelerate gameplay.
law accepted_appends_exact:
  for +round: U32
  for last: U32
  for +world: U32
  for +pending: List<&2,Q.Tick>
  for +seq: U32
  for +target: U32
  for +x: U32
  for +y: U32
  {Q.push_decided(0,Q.State{round,last,world,pending},seq,target,x,y) == Q.Admission{Q.State{round,seq,world,List.append(&2,Q.Tick,pending,[Q.Tick{seq,target,x,y}])},True{},0} : Q.Admission}

# Guarantees: every rejected decision preserves the complete queue.
# Why it matters: refusing a duplicate, old epoch or full-buffer input cannot
# discard a previously admitted future movement.
law rejected_preserves:
  for +reason: U32
  for +state: Q.State
  for seq: U32
  for target: U32
  for x: U32
  for y: U32
  for denied: {False{} == U32.is_eq(reason,0) : Bool}
  {Q.push_decided(reason,state,seq,target,x,y) == Q.Admission{state,False{},reason} : Q.Admission}

# Guarantees: lookup is exactly the first input for this world tick, independent
# of packet order and of inputs for earlier or later world ticks.
# Why it matters: neutral holes cannot be replaced by a future command.
law assigned_input_exact:
  for +rows: List<&2,Q.Tick>
  for +target: U32
  {Q.find_at(rows,target) == List.head(&2,Q.Tick,matches(rows,target)) : Maybe<&2,Q.Tick>}

# Guarantees: committing a world tick keeps exactly inputs assigned later.
# Why it matters: advancing past a missing input cannot compress future history.
law remaining_world_ticks_exact:
  for +rows: List<&2,Q.Tick>
  for +world: U32
  {Q.future(rows,world) == later(rows,world) : List<&2,Q.Tick>}

# Guarantees: a tentative step is valid only for the immediate next world tick.
# Why it matters: neither a packet burst nor a suspended worker may skip clocks.
law next_world_tick_exact:
  for round: U32
  for last: U32
  for +world: U32
  for pending: List<&2,Q.Tick>
  for +next: U32
  {Q.next_allowed(Q.State{round,last,world,pending},next) == Bool.and(U32.is_lt(world,4294967295),U32.is_eq(next,(world + 1 : U32))) : Bool}

# Guarantees: the public tentative step selects exactly the assigned input and
# advances one world tick, including a neutral hole; invalid clocks change nothing.
# Why it matters: the worker can commit one exact step, never FIFO-retarget input.
law take_exact:
  for +round: U32
  for +last: U32
  for +world: U32
  for +pending: List<&2,Q.Tick>
  for +next: U32
  {Q.take_at(Q.State{round,last,world,pending},next) == Bool.pick(Q.Taken,Bool.and(U32.is_lt(world,4294967295),U32.is_eq(next,(world + 1 : U32))),Q.Taken{Q.State{round,last,next,Q.future(pending,next)},Q.find_at(pending,next)},Q.Taken{Q.State{round,last,world,pending},None{}}) : Q.Taken}

# Guarantees: no queued input yields an explicit neutral receipt for that world tick.
# Why it matters: missing input still advances cooldown and contact clocks.
law neutral_receipt_exact:
  for +world: U32
  {Q.receipt(world,None{}) == S.Receipt{0,world,1,1,False{}} : S.Receipt}

# Guarantees: receipt creation checks the supplied input's own target tick.
# Why it matters: an ACK must not claim a future input was executed in a hole.
law assigned_receipt_exact:
  for +seq: U32
  for +world: U32
  for +target: U32
  for +x: U32
  for +y: U32
  {Q.receipt(world,Some{Q.Tick{seq,target,x,y}}) == Bool.pick(S.Receipt,U32.is_eq(target,world),S.Receipt{seq,world,x,y,True{}},S.Receipt{0,world,1,1,False{}}) : S.Receipt}
