import Base
import ./coop-prediction.bend as P

# Detached Data only: the affine ECS World cannot be passed to this replay.
# Every world tick advances the cohort once, including neutral input holes.
def step_direction(~A:Data,~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A,frame:A,direction:P.Direction) -> A:
  match direction:
    case P.Direction{x,y}: advance(frame,x,y)
def advance_worlds(~A:Data,~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A,fuel:Nat,+worldTick:U32,+inputs:List<&2,P.Input>,frame:A) -> A:
  match fuel:
    case 0n: frame
    case 1n+rest: advance_worlds(~A,~advance,rest,P.after(worldTick,1),inputs,step_direction(~A,~advance,frame,P.input_at(inputs,P.after(worldTick,1))))
def forecast(~A:Data,~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A,frame:A,prediction:P.State) -> A:
  match prediction:
    case P.State{_,_,_,False{},_,_,_,_,_}: frame
    case P.State{_,_,_,True{},inputs,+anchor,display,_,_}: advance_worlds(~A,~advance,U32.to_nat(P.world_count(anchor,display)),anchor,inputs,frame)
def guard(~A:Data,~advance:A -> U32 -> U32 -> A,allowed:Bool,frame:A,x:U32,y:U32) -> A:
  match allowed:
    case False{}: frame
    case True{}: advance(frame,x,y)
def eligible(phase:U32,hp:U32,+x:U32,+y:U32) -> Bool:
  Bool.and(Bool.and(U32.is_eq(phase,0),U32.is_gt(hp,0)),Bool.and(U32.is_le(x,2),U32.is_le(y,2)))
def generation(player:U32,tick:U32,age:U32,owner:U32,slot:U32) -> String:
  U32.show(player) ++ ":" ++ U32.show((tick - age : U32)) ++ ":" ++ U32.show(owner) ++ ":" ++ U32.show((slot % 65536 : U32))
