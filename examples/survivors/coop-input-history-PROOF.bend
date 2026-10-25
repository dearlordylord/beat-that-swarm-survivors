import Base
import ./coop-input-history-LAWS.bend as L
import ./coop-input-history-SPEC.bend as H
import ./coop-prediction.bend as P
import ./coop-prediction-replay.bend as R
import ./player-movement.bend as M

def L.clock_partition(consumed,pending,worldTick):
  match consumed:
    case 0n: {==}
    case 1n+rest: L.clock_partition(rest,pending,P.after(worldTick,1))

def L.world_partition_preserves_position(consumed,pending,worldTick,inputs,distance,point):
  match consumed:
    case 0n: {==}
    case 1n+rest: L.world_partition_preserves_position(rest,pending,P.after(worldTick,1),inputs,distance,P.advance_point(point,distance,P.input_at(inputs,P.after(worldTick,1))))

def L.world_partition_preserves_cohort(A,advance,consumed,pending,worldTick,inputs,frame):
  match consumed:
    case 0n: {==}
    case 1n+rest: L.world_partition_preserves_cohort(A,advance,rest,pending,P.after(worldTick,1),inputs,R.step_direction(~A,~advance,frame,P.input_at(inputs,P.after(worldTick,1))))

def movement_step(+distance:F32,+point:M.Point,+direction:P.Direction) -> {R.step_direction(~H.Moving,~H.movement,H.Moving{distance,point},direction) == H.Moving{distance,P.advance_point(point,distance,direction)} : H.Moving}:
  match point direction:
    case M.Point{px,py} P.Direction{x,y}: {==}

def L.cohort_movement_matches_position(fuel,worldTick,inputs,distance,point):
  match fuel:
    case 0n: {==}
    case 1n+rest:
      %Equal.sym(H.Moving,R.step_direction(~H.Moving,~H.movement,H.Moving{distance,point},P.input_at(inputs,P.after(worldTick,1))),H.Moving{distance,P.advance_point(point,distance,P.input_at(inputs,P.after(worldTick,1)))},movement_step(distance,point,P.input_at(inputs,P.after(worldTick,1)))) : {R.advance_worlds(~H.Moving,~H.movement,rest,P.after(worldTick,1),inputs,_) == H.Moving{distance,P.replay_position(rest,P.after(worldTick,1),inputs,distance,P.advance_point(point,distance,P.input_at(inputs,P.after(worldTick,1))))} : H.Moving}
      L.cohort_movement_matches_position(rest,P.after(worldTick,1),inputs,distance,P.advance_point(point,distance,P.input_at(inputs,P.after(worldTick,1))))

def L.neutral_worlds_are_not_compressed(A,advance,fuel,worldTick,frame):
  match fuel:
    case 0n: {==}
    case 1n+rest: L.neutral_worlds_are_not_compressed(A,advance,rest,P.after(worldTick,1),advance(frame,1,1))
