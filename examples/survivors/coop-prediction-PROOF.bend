import Base
import coop-prediction.bend as P
import player-movement.bend as M
import coop-session.bend as S
import coop-prediction-LAWS.bend as L
import coop-prediction-counter-PROOF.bend as C

def L.shared_movement_exact(x,y,distance,dx,dy): {==}
def L.axis_exact(code): {==}
def L.horizon_exact(): {==}
def L.prediction_gate_exact(phase,hp,connected): {==}
def newest_same(+rows: List<&2,P.Segment>) -> {P.newest(rows) == L.newest(rows) : U32}:
  match rows:
    case []: {==}
    case P.Segment{_,_,_,_,_} <> _: {==}
def command_selected_same(allowed: Bool,+state: P.State,seq: U32,x: U32,y: U32) -> {P.command_new(allowed,state,seq,x,y) == L.command_selected(allowed,state,seq,x,y) : P.State}:
  match allowed state:
    case False{} _: {==}
    case True{} P.State{_,_,_,_,_,_,_}: {==}
def L.command_exact(state,seq,x,y):
  match state:
    case P.State{+px,+py,+distance,+enabled,+rows,+age,+observation}:
      %newest_same(rows) : {P.command(P.State{px,py,distance,enabled,rows,age,observation},seq,x,y) == L.command_selected(Bool.and(U32.is_gt(seq,_),Bool.and(U32.is_le(x,2),U32.is_le(y,2))),P.State{px,py,distance,enabled,rows,age,observation},seq,x,y) : P.State}
      command_selected_same(Bool.and(U32.is_gt(seq,P.newest(rows)),Bool.and(U32.is_le(x,2),U32.is_le(y,2))),P.State{px,py,distance,enabled,rows,age,observation},seq,x,y)
def tick_selected_same(allowed: Bool,+state: P.State) -> {P.tick_allowed(allowed,state) == L.tick_selected(allowed,state) : P.State}:
  match allowed state:
    case False{} _: {==}
    case True{} P.State{_,_,_,_,[],_,_}: {==}
    case True{} P.State{_,_,_,_,P.Segment{_,_,_,_,_} <> _,_,_}: {==}
def L.tick_exact(state):
  match state:
    case P.State{+x,+y,+distance,+enabled,+segments,+age,+observation}: tick_selected_same(Bool.and(enabled,U32.is_lt(age,60)),P.State{x,y,distance,enabled,segments,age,observation})
def receipt_lane_same(+previous: S.Receipt,+lane: S.Lane,clock: U32,enabled: Bool) -> {S.receipt_lane(previous,lane,clock,enabled) == L.receipt_lane_spec(previous,lane,clock,enabled) : S.Receipt}:
  match previous lane:
    case S.Receipt{_,_,_,_,_} S.Lane{_,_,_,_,_,_,_}: {==}
def L.receipt_exact(previous,state,player):
  match state:
    case S.State{_,clock,host,guest,connected,+ended}: receipt_lane_same(previous,S.lane_at(player,host,guest),clock,Bool.and(Bool.not(ended),Bool.or(U32.is_eq(player,0),connected)))
def ack_row_same(seq: U32,steps: U32,expired: Bool,+row: P.Segment,+tail: List<&2,P.Segment>) -> {P.acknowledged_row(seq,steps,expired,row,tail) == L.acknowledged_row(seq,steps,expired,row,tail) : List<&2,P.Segment>}:
  match row:
    case P.Segment{_,_,_,_,_}: {==}
def L.acknowledgment_exact(rows,seq,steps,expired):
  match rows:
    case []: {==}
    case +row <> +rest:
      %L.acknowledgment_exact(rest,seq,steps,expired) : {P.acknowledge(row <> rest,seq,steps,expired) == L.acknowledged_row(seq,steps,expired,row,_) : List<&2,P.Segment>}
      ack_row_same(seq,steps,expired,row,P.acknowledge(rest,seq,steps,expired))
def move_steps_same(fuel: Nat,+distance: F32,+dx: F32,+dy: F32,+point: M.Point) -> {P.move_steps(fuel,distance,dx,dy,point) == L.move_steps_spec(fuel,distance,dx,dy,point) : M.Point}:
  match fuel point:
    case 0n _: {==}
    case 1n+rest M.Point{x,y}: move_steps_same(rest,distance,dx,dy,M.move_point(x,y,distance,dx,dy))
def replay_segment_same(+distance: F32,+row: P.Segment,+state: P.Replay) -> {P.replay_segment(distance,row,state) == L.replay_one(distance,row,state) : P.Replay}:
  match row state:
    case P.Segment{+seq,+x,+y,+steps,+consumed} P.Replay{+point,+budget}:
      +count = U32.min(budget,P.remaining(steps,consumed))
      %move_steps_same(U32.to_nat(count),distance,S.axis(x),S.axis(y),point) : {P.replay_segment(distance,P.Segment{seq,x,y,steps,consumed},P.Replay{point,budget}) == P.Replay{_,(budget - count : U32)} : P.Replay}
      {==}
def L.replay_exact(rows,distance,state):
  match rows:
    case []: {==}
    case +row <> +rest:
      %replay_segment_same(distance,row,state) : {P.replay(row <> rest,distance,state) == L.replay_spec(rest,distance,_) : P.Replay}
      L.replay_exact(rest,distance,P.replay_segment(distance,row,state))
def replayed_same(distance: F32,+rows: List<&2,P.Segment>,observation: U32,+state: P.Replay) -> {P.replayed(distance,rows,observation,state) == L.replay_result(distance,rows,observation,state) : P.State}:
  match state:
    case P.Replay{M.Point{_,_},_}: {==}
def history_same(+observation: U32,+x: F32,+y: F32,+distance: F32,+rows: List<&2,P.Segment>) -> {P.reconciled_history(observation,x,y,distance,rows) == L.replay_result(distance,rows,observation,L.replay_spec(List.reverse(&2,P.Segment,rows),distance,P.Replay{M.Point{x,y},60})) : P.State}:
  %L.replay_exact(List.reverse(&2,P.Segment,rows),distance,P.Replay{M.Point{x,y},60}) : {P.reconciled_history(observation,x,y,distance,rows) == L.replay_result(distance,rows,observation,_) : P.State}
  replayed_same(distance,rows,observation,P.replay(List.reverse(&2,P.Segment,rows),distance,P.Replay{M.Point{x,y},60}))
def enabled(state: P.State) -> Bool:
  match state:
    case P.State{_,_,_,active,_,_,_}: active
def active_same(+state: P.State,+observation: U32,+x: F32,+y: F32,+distance: F32,+receipt: S.Receipt) -> {P.reconcile_enabled(enabled(state),state,observation,x,y,distance,receipt) == L.reconcile_active(state,observation,x,y,distance,receipt) : P.State}:
  match state receipt:
    case P.State{_,_,_,False{},_,_,_} _: {==}
    case P.State{+px,+py,+priorDistance,True{},+rows,+age,+priorObservation} S.Receipt{+seq,+steps,+rx,+ry,+expired}:
      %L.acknowledgment_exact(rows,seq,steps,expired) : {P.reconcile_enabled(True{},P.State{px,py,priorDistance,True{},rows,age,priorObservation},observation,x,y,distance,S.Receipt{seq,steps,rx,ry,expired}) == L.replay_result(distance,_,observation,L.replay_spec(List.reverse(&2,P.Segment,L.acknowledge_spec(rows,seq,steps,expired)),distance,P.Replay{M.Point{x,y},60})) : P.State}
      %L.acknowledgment_exact(rows,seq,steps,expired) : {P.reconcile_enabled(True{},P.State{px,py,priorDistance,True{},rows,age,priorObservation},observation,x,y,distance,S.Receipt{seq,steps,rx,ry,expired}) == L.replay_result(distance,P.acknowledge(rows,seq,steps,expired),observation,L.replay_spec(List.reverse(&2,P.Segment,_),distance,P.Replay{M.Point{x,y},60})) : P.State}
      history_same(observation,x,y,distance,P.acknowledge(rows,seq,steps,expired))
def reconcile_selected_same(newer: Bool,+state: P.State,observation: U32,x: F32,y: F32,distance: F32,+active: Bool,+receipt: S.Receipt) -> {P.reconcile_new(newer,state,observation,x,y,distance,active,receipt) == L.reconcile_selected(newer,state,observation,x,y,distance,active,receipt) : P.State}:
  match newer state active:
    case False{} _ _: {==}
    case True{} P.State{_,_,_,_,_,_,_} False{}: {==}
    case True{} P.State{+px,+py,+priorDistance,+prior,+rows,+age,+priorObservation} True{}: active_same(P.State{px,py,priorDistance,prior,rows,age,priorObservation},observation,x,y,distance,receipt)
def L.reconciliation_exact(state,observation,x,y,distance,enabled,receipt):
  match state:
    case P.State{+px,+py,+priorDistance,+prior,+rows,+age,+priorObservation}: reconcile_selected_same(U32.is_gt(observation,priorObservation),P.State{px,py,priorDistance,prior,rows,age,priorObservation},observation,x,y,distance,enabled,receipt)
def L.next_tick_uses_replacement(px,py,distance,rows,age,observation,seq,x,y,fresh,validX,validY,budget):
  %Equal.sym(U32,P.newest(rows),L.newest(rows),newest_same(rows)) : {P.view(P.tick(P.command_new(Bool.and(U32.is_gt(seq,_),Bool.and(U32.is_le(x,2),U32.is_le(y,2))),P.State{px,py,distance,True{},rows,age,observation},seq,x,y))) == M.move_point(px,py,distance,S.axis(x),S.axis(y)) : M.Point}
  %Equal.sym(Bool,U32.is_gt(seq,L.newest(rows)),True{},fresh) : {P.view(P.tick(P.command_new(Bool.and(_,Bool.and(U32.is_le(x,2),U32.is_le(y,2))),P.State{px,py,distance,True{},rows,age,observation},seq,x,y))) == M.move_point(px,py,distance,S.axis(x),S.axis(y)) : M.Point}
  %Equal.sym(Bool,U32.is_le(x,2),True{},validX) : {P.view(P.tick(P.command_new(Bool.and(True{},Bool.and(_,U32.is_le(y,2))),P.State{px,py,distance,True{},rows,age,observation},seq,x,y))) == M.move_point(px,py,distance,S.axis(x),S.axis(y)) : M.Point}
  %Equal.sym(Bool,U32.is_le(y,2),True{},validY) : {P.view(P.tick(P.command_new(Bool.and(True{},Bool.and(True{},_)),P.State{px,py,distance,True{},rows,age,observation},seq,x,y))) == M.move_point(px,py,distance,S.axis(x),S.axis(y)) : M.Point}
  %Equal.sym(Bool,U32.is_lt(age,60),True{},budget) : {P.view(P.tick_allowed(Bool.and(True{},_),P.State{px,py,distance,True{},P.Segment{seq,x,y,0,0} <> List.take(&2,P.Segment,rows,63n),age,observation})) == M.move_point(px,py,distance,S.axis(x),S.axis(y)) : M.Point}
  {==}
def L.neutral_replaces_history(px,py,distance,rows,age,observation,seq,fresh,budget):
  L.next_tick_uses_replacement(px,py,distance,rows,age,observation,seq,1,1,fresh,{==},{==},budget)
def L.expired_ack_removes_segment(seq,x,y,steps,consumed,reported):
  %Equal.sym(Bool,U32.is_gt(seq,seq),False{},C.gt_self(seq)) : {Bool.pick(List<&2,P.Segment>,_,Bool.pick(P.Segment,U32.is_eq(seq,seq),P.Segment{seq,x,y,U32.max(steps,U32.max(consumed,reported)),U32.max(steps,U32.max(consumed,reported))},P.Segment{seq,x,y,steps,consumed}) <> [],[]) == [] : List<&2,P.Segment>}
  {==}
def L.expired_input_does_not_move(oldX,oldY,x,y,distance,age,priorObservation,observation,seq,inputX,inputY,predicted,consumed,reported,newer):
  %Equal.sym(Bool,U32.is_gt(observation,priorObservation),True{},newer) : {P.view(P.tick(P.reconcile_new(_,P.State{oldX,oldY,distance,True{},[P.Segment{seq,inputX,inputY,predicted,consumed}],age,priorObservation},observation,x,y,distance,True{},S.Receipt{seq,reported,1,1,True{}}))) == M.Point{x,y} : M.Point}
  %Equal.sym(List<&2,P.Segment>,P.acknowledge([P.Segment{seq,inputX,inputY,predicted,consumed}],seq,reported,True{}),[],L.expired_ack_removes_segment(seq,inputX,inputY,predicted,consumed,reported)) : {P.view(P.tick(P.reconciled_history(observation,x,y,distance,_))) == M.Point{x,y} : M.Point}
  {==}
def ack_row_cmp(+relation: Cmp,+id: U32,+x: U32,+y: U32,+steps: U32,+prior: U32,+reported: U32,+expired: Bool,+tail: List<&2,P.Segment>) -> List<&2,P.Segment>:
  +consumed = U32.max(prior,reported)
  +aligned = U32.max(steps,consumed)
  Bool.pick(List<&2,P.Segment>,Bool.pick(Bool,expired,Cmp.is_gt(relation),Cmp.is_ge(relation)),Bool.pick(P.Segment,Cmp.is_eq(relation),P.Segment{id,x,y,aligned,Bool.pick(U32,expired,aligned,consumed)},P.Segment{id,x,y,steps,prior}) <> tail,tail)
def ack_head_idempotent(relation: Cmp,+expired: Bool,+id: U32,+x: U32,+y: U32,+steps: U32,+prior: U32,+seq: U32,+reported: U32,+tail: List<&2,P.Segment>,same: {U32.cmp(id,seq) == relation : Cmp},done: {P.acknowledge(tail,seq,reported,expired) == tail : List<&2,P.Segment>}) -> {P.acknowledge(ack_row_cmp(relation,id,x,y,steps,prior,reported,expired,tail),seq,reported,expired) == ack_row_cmp(relation,id,x,y,steps,prior,reported,expired,tail) : List<&2,P.Segment>}:
  match relation expired:
    case LT{} True{}: done
    case LT{} False{}: done
    case EQ{} True{}: done
    case GT{} True{}:
      %Equal.sym(Cmp,U32.cmp(id,seq),GT{},same) : {ack_row_cmp(_,id,x,y,steps,prior,reported,True{},P.acknowledge(tail,seq,reported,True{})) == P.Segment{id,x,y,steps,prior} <> tail : List<&2,P.Segment>}
      %Equal.sym(List<&2,P.Segment>,P.acknowledge(tail,seq,reported,True{}),tail,done) : {P.Segment{id,x,y,steps,prior} <> _ == P.Segment{id,x,y,steps,prior} <> tail : List<&2,P.Segment>}
      {==}
    case GT{} False{}:
      %Equal.sym(Cmp,U32.cmp(id,seq),GT{},same) : {ack_row_cmp(_,id,x,y,steps,prior,reported,False{},P.acknowledge(tail,seq,reported,False{})) == P.Segment{id,x,y,steps,prior} <> tail : List<&2,P.Segment>}
      %Equal.sym(List<&2,P.Segment>,P.acknowledge(tail,seq,reported,False{}),tail,done) : {P.Segment{id,x,y,steps,prior} <> _ == P.Segment{id,x,y,steps,prior} <> tail : List<&2,P.Segment>}
      {==}
    case EQ{} False{}:
      +consumed = U32.max(prior,reported)
      +aligned = U32.max(steps,consumed)
      %Equal.sym(Cmp,U32.cmp(id,seq),EQ{},same) : {ack_row_cmp(_,id,x,y,aligned,consumed,reported,False{},P.acknowledge(tail,seq,reported,False{})) == P.Segment{id,x,y,aligned,consumed} <> tail : List<&2,P.Segment>}
      %Equal.sym(U32,U32.max(U32.max(prior,reported),reported),U32.max(prior,reported),C.max_absorb(prior,reported)) : {P.Segment{id,x,y,U32.max(aligned,_),U32.max(consumed,reported)} <> P.acknowledge(tail,seq,reported,False{}) == P.Segment{id,x,y,aligned,consumed} <> tail : List<&2,P.Segment>}
      %Equal.sym(U32,U32.max(U32.max(prior,reported),reported),U32.max(prior,reported),C.max_absorb(prior,reported)) : {P.Segment{id,x,y,U32.max(aligned,consumed),_} <> P.acknowledge(tail,seq,reported,False{}) == P.Segment{id,x,y,aligned,consumed} <> tail : List<&2,P.Segment>}
      %Equal.sym(U32,U32.max(U32.max(steps,consumed),consumed),U32.max(steps,consumed),C.max_absorb(steps,consumed)) : {P.Segment{id,x,y,_,consumed} <> P.acknowledge(tail,seq,reported,False{}) == P.Segment{id,x,y,aligned,consumed} <> tail : List<&2,P.Segment>}
      %Equal.sym(List<&2,P.Segment>,P.acknowledge(tail,seq,reported,False{}),tail,done) : {P.Segment{id,x,y,aligned,consumed} <> _ == P.Segment{id,x,y,aligned,consumed} <> tail : List<&2,P.Segment>}
      {==}
def L.acknowledgment_idempotent(rows,seq,steps,expired):
  match rows:
    case []: {==}
    case P.Segment{+id,+x,+y,+count,+prior} <> +rest: ack_head_idempotent(U32.cmp(id,seq),expired,id,x,y,count,prior,seq,steps,P.acknowledge(rest,seq,steps,expired),{==},L.acknowledgment_idempotent(rest,seq,steps,expired))
def L.observation_newer_exact(state,observation):
  match state:
    case P.State{_,_,_,_,_,_,_}: {==}
