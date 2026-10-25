import Base
import ./coop-input-history-LAWS.bend as L
import ./coop-input-history-SPEC.bend as H
import ./coop-input-queue.bend as Q
import ./coop-prediction.bend as P
import ./coop-session.bend as S
import ./player-movement.bend as M
import ./coop-prediction-counter-PROOF.bend as C

def L.fifo_partition(consumed,pending,distance,anchor):
  match consumed:
    case []: {==}
    case head <> tail: L.fifo_partition(tail,pending,distance,H.step(distance,head,anchor))

def min_one(+budget: U32,room: {U32.is_lt(budget,1) == False{} : Bool}) -> {U32.min(budget,1) == 1 : U32}:
  match budget:
    case U32{+word}:
      %Equal.sym(Bool,U32.is_lt(U32{word},1),False{},room) : {Bool.pick(U32,_,U32{word},1) == 1 : U32}
      {==}

def replay_one(+tick: Q.Tick,+budget: U32,+distance: F32,+point: M.Point,room: {U32.is_lt(budget,1) == False{} : Bool}) -> {P.replay_segment(distance,H.pending_row(tick),P.Replay{point,budget}) == P.Replay{H.step(distance,tick,point),(budget - 1 : U32)} : P.Replay}:
  match tick point:
    case Q.Tick{seq,+x,+y} M.Point{+px,+py}:
      Equal.cong(U32,P.Replay,count => P.Replay{P.move_steps(U32.to_nat(count),distance,S.axis(x),S.axis(y),M.Point{px,py}),(budget - count : U32)},U32.min(budget,1),1,min_one(budget,room))

def L.pending_replay_preserves_path(rows,budget,distance,point,room):
  match rows room:
    case [] _: {==}
    case +head <> +tail Tuple{stepRoom,tailRoom}:
      %Equal.sym(P.Replay,P.replay_segment(distance,H.pending_row(head),P.Replay{point,budget}),P.Replay{H.step(distance,head,point),(budget - 1 : U32)},replay_one(head,budget,distance,point,stepRoom)) : {P.replay(H.pending_rows(tail),distance,_) == P.Replay{H.path(tail,distance,H.step(distance,head,point)),H.budget_after(tail,(budget - 1 : U32))} : P.Replay}
      L.pending_replay_preserves_path(tail,(budget - 1 : U32),distance,H.step(distance,head,point),tailRoom)

def L.acknowledged_partition_preserves_path(consumed,pending,budget,distance,anchor,room):
  %Equal.sym(M.Point,H.path(List.append(&2,Q.Tick,consumed,pending),distance,anchor),H.path(pending,distance,H.path(consumed,distance,anchor)),L.fifo_partition(consumed,pending,distance,anchor)) : {P.replay(H.pending_rows(pending),distance,P.Replay{H.path(consumed,distance,anchor),budget}) == P.Replay{_,H.budget_after(pending,budget)} : P.Replay}
  L.pending_replay_preserves_path(pending,budget,distance,H.path(consumed,distance,anchor),room)

def acknowledge_one(+seq: U32,+x: U32,+y: U32) -> {P.acknowledge([P.Segment{seq,x,y,1,0}],seq,1,False{}) == [P.Segment{seq,x,y,1,1}] : List<&2,P.Segment>}:
  %Equal.sym(Bool,U32.is_ge(seq,seq),True{},C.ge_self(seq)) : {Bool.pick(List<&2,P.Segment>,_,[Bool.pick(P.Segment,U32.is_eq(seq,seq),P.Segment{seq,x,y,1,1},P.Segment{seq,x,y,1,0})],[]) == [P.Segment{seq,x,y,1,1}] : List<&2,P.Segment>}
  %Equal.sym(Bool,U32.is_eq(seq,seq),True{},C.eq_self(seq)) : {[Bool.pick(P.Segment,_,P.Segment{seq,x,y,1,1},P.Segment{seq,x,y,1,0})] == [P.Segment{seq,x,y,1,1}] : List<&2,P.Segment>}
  {==}

def consumed_point(+px: F32,+py: F32,+distance: F32,+seq: U32,+x: U32,+y: U32,+observation: U32) -> {P.view(P.reconciled_history(observation,px,py,distance,P.acknowledge([P.Segment{seq,x,y,1,0}],seq,1,False{}))) == M.Point{px,py} : M.Point}:
  Equal.cong(List<&2,P.Segment>,M.Point,rows => P.view(P.reconciled_history(observation,px,py,distance,rows)),P.acknowledge([P.Segment{seq,x,y,1,0}],seq,1,False{}),[P.Segment{seq,x,y,1,1}],acknowledge_one(seq,x,y))

def L.consumed_tick_preserves_position(point,distance,seq,x,y,prior,observation,newer):
  match point:
    case M.Point{+px,+py}:
      %newer : {P.view(P.reconcile_new(_,P.State{px,py,distance,True{},[P.Segment{seq,x,y,1,0}],1,prior},observation,px,py,distance,True{},S.Receipt{seq,1,x,y,False{}})) == M.Point{px,py} : M.Point}
      consumed_point(px,py,distance,seq,x,y,observation)

def acknowledge_two(+ack: U32,+ackX: U32,+ackY: U32,+seq: U32,+x: U32,+y: U32,retained: {True{} == U32.is_ge(seq,ack) : Bool},distinct: {False{} == U32.is_eq(seq,ack) : Bool}) -> {P.acknowledge([P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,0}],ack,1,False{}) == [P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,1}] : List<&2,P.Segment>}:
  %Equal.sym(List<&2,P.Segment>,P.acknowledge([P.Segment{ack,ackX,ackY,1,0}],ack,1,False{}),[P.Segment{ack,ackX,ackY,1,1}],acknowledge_one(ack,ackX,ackY)) : {P.acknowledged_row(ack,1,False{},P.Segment{seq,x,y,1,0},_) == [P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,1}] : List<&2,P.Segment>}
  %retained : {Bool.pick(List<&2,P.Segment>,_,[Bool.pick(P.Segment,U32.is_eq(seq,ack),P.Segment{seq,x,y,1,1},P.Segment{seq,x,y,1,0}),P.Segment{ack,ackX,ackY,1,1}],[P.Segment{ack,ackX,ackY,1,1}]) == [P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,1}] : List<&2,P.Segment>}
  %distinct : {[Bool.pick(P.Segment,_,P.Segment{seq,x,y,1,1},P.Segment{seq,x,y,1,0}),P.Segment{ack,ackX,ackY,1,1}] == [P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,1}] : List<&2,P.Segment>}
  {==}

def pending_point(+px: F32,+py: F32,+distance: F32,+ack: U32,+ackX: U32,+ackY: U32,+seq: U32,+x: U32,+y: U32,+observation: U32,retained: {True{} == U32.is_ge(seq,ack) : Bool},distinct: {False{} == U32.is_eq(seq,ack) : Bool}) -> {P.view(P.reconciled_history(observation,px,py,distance,P.acknowledge([P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,0}],ack,1,False{}))) == M.move_point(px,py,distance,S.axis(x),S.axis(y)) : M.Point}:
  Equal.cong(List<&2,P.Segment>,M.Point,rows => P.view(P.reconciled_history(observation,px,py,distance,rows)),P.acknowledge([P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,0}],ack,1,False{}),[P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,1}],acknowledge_two(ack,ackX,ackY,seq,x,y,retained,distinct))

def reconcile_pending(+point: M.Point,+distance: F32,+ack: U32,+ackX: U32,+ackY: U32,+seq: U32,+x: U32,+y: U32,+prior: U32,+observation: U32,retained: {True{} == U32.is_ge(seq,ack) : Bool},distinct: {False{} == U32.is_eq(seq,ack) : Bool},newer: {True{} == U32.is_gt(observation,prior) : Bool}) -> {H.reconcile(H.state(distance,[P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,0}],2,prior,H.step(distance,Q.Tick{seq,x,y},point)),observation,distance,Q.receipt(S.receipt_fresh(),Some{Q.Tick{ack,ackX,ackY}}),point) == H.step(distance,Q.Tick{seq,x,y},point) : M.Point}:
  match point:
    case M.Point{+px,+py}:
      %newer : {P.view(P.reconcile_new(_,H.state(distance,[P.Segment{seq,x,y,1,0},P.Segment{ack,ackX,ackY,1,0}],2,prior,M.move_point(px,py,distance,S.axis(x),S.axis(y))),observation,px,py,distance,True{},S.Receipt{ack,1,ackX,ackY,False{}})) == M.move_point(px,py,distance,S.axis(x),S.axis(y)) : M.Point}
      pending_point(px,py,distance,ack,ackX,ackY,seq,x,y,observation,retained,distinct)

def L.one_pending_tick_preserves_path(prefix,anchor,distance,ack,ackX,ackY,seq,x,y,prior,observation,retained,distinct,newer): reconcile_pending(H.path(prefix,distance,anchor),distance,ack,ackX,ackY,seq,x,y,prior,observation,retained,distinct,newer)
