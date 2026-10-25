import Base
import coop-prediction.bend as P
import player-movement.bend as M
import coop-session.bend as S
import arena.bend as A

# Independent transition specification. Machine arithmetic is stated explicitly;
# it does not assume real-number identities for arbitrary IEEE F32 values.
def newest(rows: List<&2,P.Segment>) -> U32:
  match rows:
    case []: 0
    case P.Segment{seq,_,_,_,_} <> _: seq
def observed(state: P.State) -> U32:
  match state:
    case P.State{_,_,_,_,_,_,observation}: observation
def command_selected(allowed: Bool,+state: P.State,seq: U32,x: U32,y: U32) -> P.State:
  match allowed state:
    case False{} _: state
    case True{} P.State{px,py,distance,enabled,rows,age,observation}: P.State{px,py,distance,enabled,P.Segment{seq,x,y,0,0} <> List.take(&2,P.Segment,rows,63n),age,observation}
def command_spec(+state: P.State,+seq: U32,+x: U32,+y: U32) -> P.State:
  match state:
    case P.State{px,py,distance,enabled,+rows,age,observation}: command_selected(Bool.and(U32.is_gt(seq,newest(rows)),Bool.and(U32.is_le(x,2),U32.is_le(y,2))),P.State{px,py,distance,enabled,rows,age,observation},seq,x,y)
def tick_position(distance: F32,enabled: Bool,rows: List<&2,P.Segment>,age: U32,observation: U32,point: M.Point) -> P.State:
  match point:
    case M.Point{x,y}: P.State{x,y,distance,enabled,rows,age,observation}
def tick_selected(allowed: Bool,+state: P.State) -> P.State:
  match allowed state:
    case False{} _: state
    case True{} P.State{px,py,+distance,+enabled,P.Segment{seq,+x,+y,steps,consumed} <> rest,age,observation}:
      tick_position(distance,enabled,P.Segment{seq,x,y,U32.min((steps + 1 : U32),65535),consumed} <> rest,(age + 1 : U32),observation,M.move_point(px,py,distance,S.axis(x),S.axis(y)))
    case True{} P.State{px,py,distance,enabled,[],age,observation}: P.State{px,py,distance,enabled,[],(age + 1 : U32),observation}
def tick_spec(+state: P.State) -> P.State:
  match state:
    case P.State{_,_,_,enabled,_,age,_}: tick_selected(Bool.and(enabled,U32.is_lt(age,60)),state)
def acknowledged_row(+seq: U32,+reported: U32,+expired: Bool,row: P.Segment,+tail: List<&2,P.Segment>) -> List<&2,P.Segment>:
  match row:
    case P.Segment{+id,+x,+y,+steps,+prior}:
      +consumed = U32.max(prior,reported)
      +aligned = U32.max(steps,consumed)
      Bool.pick(List<&2,P.Segment>,Bool.pick(Bool,expired,U32.is_gt(id,seq),U32.is_ge(id,seq)),Bool.pick(P.Segment,U32.is_eq(id,seq),P.Segment{id,x,y,aligned,Bool.pick(U32,expired,aligned,consumed)},P.Segment{id,x,y,steps,prior}) <> tail,tail)
def acknowledge_spec(rows: List<&2,P.Segment>,+seq: U32,+reported: U32,+expired: Bool) -> List<&2,P.Segment>:
  match rows:
    case []: []
    case row <> rest: acknowledged_row(seq,reported,expired,row,acknowledge_spec(rest,seq,reported,expired))
def move_steps_spec(fuel: Nat,+distance: F32,+dx: F32,+dy: F32,point: M.Point) -> M.Point:
  match fuel point:
    case 0n point: point
    case 1n+rest M.Point{x,y}: move_steps_spec(rest,distance,dx,dy,M.move_point(x,y,distance,dx,dy))
def replay_one(distance: F32,row: P.Segment,state: P.Replay) -> P.Replay:
  match row state:
    case P.Segment{_,x,y,+steps,consumed} P.Replay{point,+budget}:
      +count = U32.min(budget,(steps - U32.min(steps,consumed) : U32))
      P.Replay{move_steps_spec(U32.to_nat(count),distance,S.axis(x),S.axis(y),point),(budget - count : U32)}
def replay_spec(rows: List<&2,P.Segment>,+distance: F32,state: P.Replay) -> P.Replay:
  match rows:
    case []: state
    case row <> rest: replay_spec(rest,distance,replay_one(distance,row,state))
def replay_result(+distance: F32,+rows: List<&2,P.Segment>,observation: U32,result: P.Replay) -> P.State:
  match result:
    case P.Replay{M.Point{x,y},left}: P.State{x,y,distance,True{},rows,(60 - left : U32),observation}
def reconcile_active(state: P.State,observation: U32,x: F32,y: F32,+distance: F32,receipt: S.Receipt) -> P.State:
  match state receipt:
    case P.State{_,_,_,False{},_,_,_} _: P.State{x,y,distance,True{},[],0,observation}
    case P.State{_,_,_,True{},segments,_,_} S.Receipt{seq,steps,_,_,expired}:
      +rows = acknowledge_spec(segments,seq,steps,expired)
      replay_result(distance,rows,observation,replay_spec(List.reverse(&2,P.Segment,rows),distance,P.Replay{M.Point{x,y},60}))
def reconcile_selected(newer: Bool,+state: P.State,observation: U32,x: F32,y: F32,distance: F32,enabled: Bool,receipt: S.Receipt) -> P.State:
  match newer state enabled:
    case False{} _ _: state
    case True{} _ False{}: P.State{x,y,distance,False{},[],0,observation}
    case True{} state True{}: reconcile_active(state,observation,x,y,distance,receipt)
def reconcile_spec(+state: P.State,+observation: U32,x: F32,y: F32,distance: F32,enabled: Bool,receipt: S.Receipt) -> P.State:
  reconcile_selected(U32.is_gt(observation,observed(state)),state,observation,x,y,distance,enabled,receipt)

# Guarantees: the shared step uses precisely the existing F32 operation order.
# Why it matters: predicting must not introduce a second movement implementation.
law shared_movement_exact:
  for +x: F32
  for +y: F32
  for +distance: F32
  for +dx: F32
  for +dy: F32
  {M.move_point(x,y,distance,dx,dy) == M.Point{F32.clamp((x + dx * distance / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),A.player_min(),A.player_max()),F32.clamp((y + dy * distance / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),A.player_min(),A.player_max())} : M.Point}

# Guarantees: axis codes describe exactly negative, neutral and positive input.
# Why it matters: input replacement cannot be hidden behind an incorrect decoder.
law axis_exact:
  for +code: U32
  {S.axis(code) == Bool.pick(F32,U32.is_eq(code,0),(0.0 - 1.0 : F32),Bool.pick(F32,U32.is_eq(code,2),1.0,0.0)) : F32}

# Guarantees: the speculative movement horizon is exactly sixty fixed steps.
# Why it matters: the safety bound must not move with its implementation.
law horizon_exact:
  {P.horizon() == 60 : U32}

# Guarantees: only a connected living player in running phase may predict.
# Why it matters: pause, death and disconnect cannot become local movement.
law prediction_gate_exact:
  for +phase: U32
  for +hp: U32
  for +connected: Bool
  {P.allowed(phase,hp,connected) == Bool.and(connected,Bool.and(U32.is_eq(phase,0),U32.is_gt(hp,0))) : Bool}

# Guarantees: every command insertion matches the independent bounded-history rule.
# Why it matters: changes, releases and reversals replace the next step after
# any existing history, while invalid or stale commands cannot replace input.
law command_exact:
  for +state: P.State
  for +seq: U32
  for +x: U32
  for +y: U32
  {P.command(state,seq,x,y) == command_spec(state,seq,x,y) : P.State}

# Guarantees: every local tick matches the stateful reference transition, including
# counter progress, disabled states, empty history and every age at or beyond60.
# Why it matters: no old input or accumulated pause time may control the next tick.
law tick_exact:
  for +state: P.State
  {P.tick(state) == tick_spec(state) : P.State}

# Guarantees: ACK filtering retains exactly seq>=ack, and its ACK segment uses
# monotonic cumulative consumption and aligns counters when authority is ahead.
# Why it matters: dropping all pending input or undoing an older ACK must fail.
law acknowledgment_exact:
  for +rows: List<&2,P.Segment>
  for +seq: U32
  for +steps: U32
  for +expired: Bool
  {P.acknowledge(rows,seq,steps,expired) == acknowledge_spec(rows,seq,steps,expired) : List<&2,P.Segment>}

# Guarantees: replay consumes pending steps in the given chronological order,
# with explicit remaining-budget subtraction and the shared movement arithmetic.
# Why it matters: a replay ignoring input or reversing its order must fail.
law replay_exact:
  for +rows: List<&2,P.Segment>
  for +distance: F32
  for +state: P.Replay
  {P.replay(rows,distance,state) == replay_spec(rows,distance,state) : P.Replay}

# Guarantees: reconciliation starts at authority, replays only remaining history
# oldest-first with budget60, ignores nonnew snapshots, clears disabled history,
# and resumes from a fresh anchor rather than replaying pre-pause segments.
# Why it matters: no correction may accumulate movement over an old local pose.
law reconciliation_exact:
  for +state: P.State
  for +observation: U32
  for +x: F32
  for +y: F32
  for +distance: F32
  for +enabled: Bool
  for +receipt: S.Receipt
  {P.reconcile(state,observation,x,y,distance,enabled,receipt) == reconcile_spec(state,observation,x,y,distance,enabled,receipt) : P.State}

# Guarantees: an accepted replacement controls the next eligible tick after any
# existing history. The premises are the actual sequence, axis and horizon checks.
# Why it matters: testing only an empty fresh state would miss delayed reversals.
law next_tick_uses_replacement:
  for +px: F32
  for +py: F32
  for +distance: F32
  for +rows: List<&2,P.Segment>
  for +age: U32
  for +observation: U32
  for +seq: U32
  for +x: U32
  for +y: U32
  for fresh: {U32.is_gt(seq,newest(rows)) == True{} : Bool}
  for validX: {U32.is_le(x,2) == True{} : Bool}
  for validY: {U32.is_le(y,2) == True{} : Bool}
  for budget: {U32.is_lt(age,60) == True{} : Bool}
  {P.view(P.tick(P.command(P.State{px,py,distance,True{},rows,age,observation},seq,x,y))) == M.move_point(px,py,distance,S.axis(x),S.axis(y)) : M.Point}

# Guarantees: key-up selects zero direction on the next eligible tick even after
# actual earlier motion. Its result is the shared zero-direction step, not a
# false arithmetic claim about arbitrary NaN or out-of-arena F32 coordinates.
# Why it matters: no historical held direction can survive neutral replacement.
law neutral_replaces_history:
  for +px: F32
  for +py: F32
  for +distance: F32
  for +rows: List<&2,P.Segment>
  for +age: U32
  for +observation: U32
  for +seq: U32
  for fresh: {U32.is_gt(seq,newest(rows)) == True{} : Bool}
  for budget: {U32.is_lt(age,60) == True{} : Bool}
  {P.view(P.tick(P.command(P.State{px,py,distance,True{},rows,age,observation},seq,1,1))) == M.move_point(px,py,distance,0.0,0.0) : M.Point}

# Guarantees: processing an identical cumulative ACK again changes no history.
# Why it matters: even a new observation carrying the same receipt cannot double-consume.
law acknowledgment_idempotent:
  for +rows: List<&2,P.Segment>
  for +seq: U32
  for +steps: U32
  for +expired: Bool
  {P.acknowledge(P.acknowledge(rows,seq,steps,expired),seq,steps,expired) == P.acknowledge(rows,seq,steps,expired) : List<&2,P.Segment>}

# Receipt specification is separate from prediction history: it records each
# direction actually passed to an advanced authoritative step, not a receipt-only
# network event. Worker call ordering is additionally checked at the IO boundary.
def receipt_lane_spec(previous: S.Receipt,lane: S.Lane,+clock: U32,+enabled: Bool) -> S.Receipt:
  match previous lane:
    case S.Receipt{prior,+steps,_,_,_} S.Lane{_,+seq,_,_,+received,x,y}:
      S.Receipt{seq,Bool.pick(U32,U32.is_eq(prior,seq),U32.min((steps + 1 : U32),65535),1),Bool.pick(U32,enabled,x,1),Bool.pick(U32,enabled,y,1),Bool.or(Bool.not(enabled),U32.is_ge((clock - received : U32),18))}
def receipt_spec(previous: S.Receipt,state: S.State,+player: U32) -> S.Receipt:
  match state:
    case S.State{_,clock,host,guest,connected,+ended}: receipt_lane_spec(previous,Bool.pick(S.Lane,U32.is_eq(player,0),host,guest),clock,Bool.and(Bool.not(ended),Bool.or(U32.is_eq(player,0),connected)))

# Guarantees: each consumed-step receipt reports the chosen sequence/direction,
# increments exactly once, resets only for a changed sequence, and marks expiry.
# Why it matters: received input alone cannot masquerade as elapsed simulation.
law receipt_exact:
  for +previous: S.Receipt
  for +state: S.State
  for +player: U32
  {S.receipt_step(previous,state,player) == receipt_spec(previous,state,player) : S.Receipt}


# Guarantees: expiry removes the expired ACK segment, rather than merely marking
# its existing steps consumed. Only a later command can supply a new direction.
# Why it matters: an old held direction cannot restart on every new snapshot.
law expired_ack_removes_segment:
  for +seq: U32
  for x: U32
  for y: U32
  for steps: U32
  for consumed: U32
  for reported: U32
  {P.acknowledge([P.Segment{seq,x,y,steps,consumed}],seq,reported,True{}) == [] : List<&2,P.Segment>}

# Guarantees: after a newer expired-input observation with no later input,
# the next local tick preserves the authoritative point exactly. The age counter
# may still advance, so this is a position guarantee rather than state equality.
# Why it matters: ongoing snapshots must not revive expired movement.
law expired_input_does_not_move:
  for oldX: F32
  for oldY: F32
  for +x: F32
  for +y: F32
  for +distance: F32
  for age: U32
  for +priorObservation: U32
  for +observation: U32
  for +seq: U32
  for inputX: U32
  for inputY: U32
  for predicted: U32
  for consumed: U32
  for reported: U32
  for newer: {U32.is_gt(observation,priorObservation) == True{} : Bool}
  {P.view(P.tick(P.reconcile(P.State{oldX,oldY,distance,True{},[P.Segment{seq,inputX,inputY,predicted,consumed}],age,priorObservation},observation,x,y,distance,True{},S.Receipt{seq,reported,1,1,True{}}))) == M.Point{x,y} : M.Point}


# Guarantees: observation admission is exactly a strictly increasing sequence
# comparison against the stored observation, including duplicate rejection.
# Why it matters: IO may check freshness through Bend before touching render or
# timing state, using the same rule as reconciliation.
law observation_newer_exact:
  for +state: P.State
  for +observation: U32
  {P.observation_newer(state,observation) == U32.is_gt(observation,observed(state)) : Bool}
