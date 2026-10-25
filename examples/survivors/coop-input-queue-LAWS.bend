import Base
import ./coop-input-queue.bend as Q
import ./coop-session.bend as S

# Guarantees: a new reward epoch has no queued input and resets its admission high-water mark.
# Why it matters: resuming a run cannot execute movement saved before a pause.
law reset_exact:
  for +round: U32
  {Q.fresh(round) == Q.State{round,0,[]} : Q.State}

# Guarantees: queue admission requires this epoch, a newer input tick, valid axes, and fewer than 128 waiting ticks.
# Why it matters: real delayed inputs cannot cross a reward pause or grow the queue without a bound.
law admission_exact:
  for +epoch: U32
  for +last: U32
  for +pending: List<&2,Q.Tick>
  for +round: U32
  for +seq: U32
  for +x: U32
  for +y: U32
  {Q.allowed(Q.State{epoch,last,pending},round,seq,x,y) == Bool.and(U32.is_eq(epoch,round),Bool.and(U32.is_gt(seq,last),Bool.and(Bool.and(U32.is_le(x,2),U32.is_le(y,2)),Nat.is_lt(List.length(&2,Q.Tick,pending),128n)))) : Bool}

# Guarantees: the public queue operation accepts exactly its complete admission policy.
# Why it matters: the worker cannot acknowledge an input the queue refused or silently drop a valid tick.
law push_accepts_exactly:
  for +state: Q.State
  for +round: U32
  for +seq: U32
  for +x: U32
  for +y: U32
  {Q.accepted(Q.push(state,round,seq,x,y)) == Q.allowed(state,round,seq,x,y) : Bool}

# Guarantees: a refused public input leaves the whole queue unchanged.
# Why it matters: an old epoch or duplicate packet cannot delete pending movement.
law refused_preserves:
  for +state: Q.State
  for round: U32
  for seq: U32
  for x: U32
  for y: U32
  for denied: {False{} == Q.allowed(state,round,seq,x,y) : Bool}
  {Q.admission_state(Q.push(state,round,seq,x,y)) == state : Q.State}

# Guarantees: an accepted tick is appended after all earlier waiting ticks and advances the admitted sequence.
# Why it matters: packet batching cannot reverse the order of a guest's movements.
law accepted_appends:
  for +epoch: U32
  for +last: U32
  for +pending: List<&2,Q.Tick>
  for round: U32
  for +seq: U32
  for +x: U32
  for +y: U32
  for allowed: {True{} == Q.allowed(Q.State{epoch,last,pending},round,seq,x,y) : Bool}
  {Q.push(Q.State{epoch,last,pending},round,seq,x,y) == Q.Admission{Q.State{epoch,seq,List.append(&2,Q.Tick,pending,[Q.Tick{seq,x,y}])},True{}} : Q.Admission}

# Guarantees: taking a nonempty queue returns exactly its first tick and removes exactly that one tick.
# Why it matters: one world step cannot apply several queued movement ticks and accelerate the guest.
law take_one_exact:
  for +round: U32
  for +last: U32
  for +head: Q.Tick
  for +tail: List<&2,Q.Tick>
  {Q.take(Q.State{round,last,head <> tail}) == Q.Taken{Q.State{round,last,tail},Some{head}} : Q.Taken}

# Guarantees: an empty queue supplies no movement tick and remains empty.
# Why it matters: waiting for the next packet must not repeat the last applied movement.
law empty_is_neutral:
  for +round: U32
  for +last: U32
  {Q.take(Q.State{round,last,[]}) == Q.Taken{Q.State{round,last,[]},None{}} : Q.Taken}

# Guarantees: an input with a different reward epoch is refused regardless of direction or sequence.
# Why it matters: a packet already in the relay at level-up cannot move the player after resuming.
law old_epoch_refused:
  for +epoch: U32
  for last: U32
  for pending: List<&2,Q.Tick>
  for +round: U32
  for seq: U32
  for x: U32
  for y: U32
  for different: {False{} == U32.is_eq(epoch,round) : Bool}
  {Q.allowed(Q.State{epoch,last,pending},round,seq,x,y) == False{} : Bool}

# Guarantees: acknowledging a consumed tick identifies that exact tick and one movement step.
# Why it matters: receipt counters must refer to the same input tick that the guest predicted, independently of packet timing.
law receipt_one_exact:
  for previous: S.Receipt
  for +seq: U32
  for +x: U32
  for +y: U32
  {Q.receipt(previous,Some{Q.Tick{seq,x,y}}) == S.Receipt{seq,1,x,y,False{}} : S.Receipt}

# Guarantees: a world step without a queued tick cannot advance the input acknowledgement.
# Why it matters: packet gaps must not tell the guest that an unreceived input was consumed.
law receipt_empty_preserves:
  for +previous: S.Receipt
  {Q.receipt(previous,None{}) == previous : S.Receipt}

# Guarantees: fixed tick admission is active precisely during running gameplay for an eligible living connected guest.
# Why it matters: queued movement cannot enter the world while a reward dialog is open or its player is unavailable.
law activity_exact:
  for +phase: U32
  for +enabled: Bool
  {Q.activity(phase,enabled) == Bool.and(U32.is_eq(phase,0),enabled) : Bool}

# Guarantees: public active admission delegates to queue admission only during eligible running gameplay and otherwise preserves the queue with refusal.
# Why it matters: the browser adapter cannot independently decide whether paused or dead guest input becomes pending movement.
law active_push_exact:
  for +state: Q.State
  for +phase: U32
  for +enabled: Bool
  for +round: U32
  for +seq: U32
  for +x: U32
  for +y: U32
  {Q.push_active(state,phase,enabled,round,seq,x,y) == Bool.pick(Q.Admission,Bool.and(U32.is_eq(phase,0),enabled),Q.push(state,round,seq,x,y),Q.Admission{state,False{}}) : Q.Admission}

# Guarantees: inactive input preserves the complete queue and reports refusal.
# Why it matters: a key held across a level-up cannot add movement to the suspended run.
law inactive_refused:
  for +state: Q.State
  for phase: U32
  for enabled: Bool
  for round: U32
  for seq: U32
  for x: U32
  for y: U32
  for inactive: {False{} == Q.activity(phase,enabled) : Bool}
  {Q.push_active(state,phase,enabled,round,seq,x,y) == Q.Admission{state,False{}} : Q.Admission}

# Guarantees: overflow means an otherwise valid active current-epoch fresh input met a full queue.
# Why it matters: late old-epoch packets during a full queue must be refused without disconnecting the guest as an overflow.
law overflow_exact:
  for +epoch: U32
  for +last: U32
  for +pending: List<&2,Q.Tick>
  for +phase: U32
  for +enabled: Bool
  for +round: U32
  for +seq: U32
  for +x: U32
  for +y: U32
  {Q.overflowed(Q.State{epoch,last,pending},phase,enabled,round,seq,x,y) == Bool.and(Bool.and(U32.is_eq(phase,0),enabled),Bool.and(Bool.not(Nat.is_lt(List.length(&2,Q.Tick,pending),128n)),Bool.and(U32.is_eq(epoch,round),Bool.and(U32.is_gt(seq,last),Bool.and(U32.is_le(x,2),U32.is_le(y,2)))))) : Bool}
