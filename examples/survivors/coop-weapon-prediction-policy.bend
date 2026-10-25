import Base
import ./coop-prediction.bend as P
import ./pools.bend as PL

# The proved orchestration kernel accepts only duplicable detached Data. The
# game's affine ECS World is Type and cannot be supplied as its forecast state.
type Replaying<-A:Data> is Data: Replaying{frame:A,budget:U32}
def advance_steps(~A:Data,~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A,fuel:Nat,frame:A,+x:U32,+y:U32) -> A:
  match fuel:
    case 0n: frame
    case 1n+rest: advance_steps(~A,~advance,rest,advance(frame,x,y),x,y)
def replay_one(~A:Data,~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A,segment:P.Segment,state:Replaying<A>) -> Replaying<A>:
  match segment state:
    case P.Segment{_,x,y,steps,consumed} Replaying{frame,+budget}:
      +count = U32.min(budget,P.remaining(steps,consumed))
      Replaying{advance_steps(~A,~advance,U32.to_nat(count),frame,x,y),(budget - count : U32)}
def finish(~A:Data,state:Replaying<A>) -> A:
  match state:
    case Replaying{frame,_}: frame
def replay_rows(~A:Data,~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A,rows:List<&2,P.Segment>,state:Replaying<A>) -> A:
  match rows:
    case []: finish(~A,state)
    case head <> tail: replay_rows(~A,~advance,tail,replay_one(~A,~advance,head,state))
def forecast(~A:Data,~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A,frame:A,prediction:P.State) -> A:
  match prediction:
    case P.State{_,_,_,False{},_,_,_}: frame
    case P.State{_,_,_,True{},segments,_,_}: replay_rows(~A,~advance,List.reverse(&2,P.Segment,segments),Replaying{frame,P.horizon()})
def guard(~A:Data,~advance:A -> U32 -> U32 -> A,allowed:Bool,frame:A,x:U32,y:U32) -> A:
  match allowed:
    case False{}: frame
    case True{}: advance(frame,x,y)
def eligible(phase:U32,hp:U32,+x:U32,+y:U32) -> Bool:
  Bool.and(Bool.and(U32.is_eq(phase,0),U32.is_gt(hp,0)),Bool.and(U32.is_le(x,2),U32.is_le(y,2)))
def prefer_existing(~A:Data,~retain:A -> A -> A,previous:Maybe<&2,A>,fresh:A) -> A:
  match previous:
    case None{}: fresh
    case Some{prior}: retain(prior,fresh)
def generation(player:U32,tick:U32,age:U32,owner:U32,slot:U32) -> String:
  U32.show(player) ++ ":" ++ U32.show((tick - age : U32)) ++ ":" ++ U32.show(owner) ++ ":" ++ U32.show((slot % 65536 : U32))
def owned_seeds_go(fuel:Nat,+seed:U32) -> List<&2,U32>:
  match fuel:
    case 0n: []
    case 1n+rest: seed <> owned_seeds_go(rest,(seed + 2 : U32))
def owned_seeds(player:U32) -> List<&2,U32>:
  owned_seeds_go(U32.to_nat((PL.player_count() / 2 : U32)),(PL.player_start() + player : U32))
