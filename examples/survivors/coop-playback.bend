import Base
import ./body-index.bend as BI
import ./list-map.bend as LM

# One bounded authoritative timeline for every remote combat layer.
# The local avatar's prediction is intentionally outside this model.
type Actor is Data: Actor{key:U32,kind:U32,generation:String,x:F32,y:F32,age:U32,alive:Bool,owner:U32}
type Frame is Data: Frame{observation:U32,tick:U32,receivedAt:Nat,players:List<&2,Actor>,bodies:List<&2,Actor>}
type Indexed is Data: Indexed{frame:Frame,players:BI.Index<Actor>,bodies:BI.Index<Actor>}
# fraction is millionths of one world tick. Emitted 2.0.38 Nat timestamps
# use exact integer Numbers; the IO adapter supplies monotonic microseconds.
type Mode is Data: Priming{} Holding{} Playing{} Boosting{}
type Cursor is Data: Cursor{tick:U32,fraction:Nat,lastAt:Nat,mode:Mode}
type State is Data: State{frames:List<&2,Indexed>,cursor:Cursor,recovered:Bool,delay:U32}
type Sample is Data: Sample{baseObservation:U32,nextObservation:U32,tick:U32,fraction:Nat,alpha:F32,players:List<&2,Actor>,bodies:List<&2,Actor>}
type Mix is Data: Mix{index:BI.Index<Actor>,alpha:F32}
# Preserve the host's existing 50ms presentation delay; guests buffer 100ms.
def delay_for(own:U32) -> U32: Bool.pick(U32,U32.is_eq(own,0),3,6)
def fresh_for(own:U32) -> State: State{[],Cursor{0,0n,0n,Priming{}},False{},delay_for(own)}
def fresh() -> State: State{[],Cursor{0,0n,0n,Priming{}},False{},6}
def actor_key(actor:Actor) -> U32:
  match actor:
    case Actor{key,_,_,_,_,_,_,_}: key
def observation(frame:Frame) -> U32:
  match frame:
    case Frame{observation,_,_,_,_}: observation
def world_tick(frame:Frame) -> U32:
  match frame:
    case Frame{_,tick,_,_,_}: tick
def received_at(frame:Frame) -> Nat:
  match frame:
    case Frame{_,_,at,_,_}: at
def frame(indexed:Indexed) -> Frame:
  match indexed:
    case Indexed{frame,_,_}: frame
def index_rows(rows:List<&2,Actor>,index:BI.Index<Actor>) -> BI.Index<Actor>:
  match rows:
    case []: index
    case +head <> tail: index_rows(tail,BI.insert(~Actor,index,actor_key(head),head))
def indexed(+source:Frame) -> Indexed:
  match source:
    case Frame{_,_,_,players,bodies}: Indexed{source,index_rows(players,BI.Empty{}),index_rows(bodies,BI.Empty{})}
def admissible(+old:Frame,+new:Frame) -> Bool:
  Bool.and(U32.is_gt(observation(new),observation(old)),U32.is_ge(world_tick(new),world_tick(old)))
def retain(sameTick:Bool,new:Indexed,rows:List<&2,Indexed>) -> List<&2,Indexed>:
  match sameTick rows:
    case True{} _ <> tail: new <> List.take(&2,Indexed,tail,7n)
    case _ _: new <> List.take(&2,Indexed,rows,7n)
def oldest(rows:List<&2,Indexed>,fallback:Indexed) -> Indexed:
  match rows:
    case []: fallback
    case head <> tail: oldest(tail,head)
def recovered_cursor(behind:Bool,cursor:Cursor,oldestTick:U32) -> Cursor:
  match behind cursor:
    case True{} Cursor{_,_,at,_}: Cursor{oldestTick,0n,at,Priming{}}
    case False{} _: cursor
def bounded_state(+rows:List<&2,Indexed>,cursor:Cursor,+oldestTick:U32,delay:U32) -> State:
  match cursor:
    case Cursor{+tick,fraction,at,buffering}: State{rows,recovered_cursor(U32.is_lt(tick,oldestTick),Cursor{tick,fraction,at,buffering},oldestTick),U32.is_lt(tick,oldestTick),delay}
def pushed_rows(+rows:List<&2,Indexed>,cursor:Cursor,+new:Indexed,delay:U32) -> State:
  bounded_state(rows,cursor,world_tick(frame(oldest(rows,new))),delay)
def push_existing(+head:Indexed,tail:List<&2,Indexed>,cursor:Cursor,delay:U32,+new:Indexed) -> State:
  pushed_rows(retain(U32.is_eq(world_tick(frame(head)),world_tick(frame(new))),new,head <> tail),cursor,new,delay)
def push_decided(accepted:Bool,+state:State,+new:Frame) -> State:
  match accepted state:
    case False{} _: state
    case True{} State{[],_,_,delay}: State{[indexed(new)],Cursor{world_tick(new),0n,received_at(new),Priming{}},False{},delay}
    case True{} State{head <> tail,cursor,_,delay}: push_existing(head,tail,cursor,delay,indexed(new))
def accepts(state:State,new:Frame) -> Bool:
  match state:
    case State{[],_,_,_}: True{}
    case State{head <> _,_,_,_}: admissible(frame(head),new)
def push(+state:State,+new:Frame) -> State:
  push_decided(accepts(state,new),state,new)

def elapsed(+now:Nat,+previous:Nat) -> Nat: Nat.min(Nat.sub(Nat.max(now,previous),previous),1000000n)
# Reduce an accumulated presentation backlog gradually, without seeking or replay.
# Integer-tick deadband tolerates ordinary twenty-Hz snapshot spacing.
def rate_selected(behind:Bool) -> Nat: Bool.pick(Nat,behind,66n,60n)
def rate_for(tick:U32,latest:U32,delay:U32) -> Nat:
  rate_selected(Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),1n)))
def fraction_after(+fraction:Nat,now:Nat,previous:Nat,rate:Nat) -> Nat: Nat.add(Nat.min(fraction,999999n),Nat.mul(elapsed(now,previous),rate))
def tick_after(+tick:U32,units:Nat) -> U32: (tick + U32.from_nat(Nat.min(Nat.div(units,1000000n),U32.to_nat((4294967295 - tick : U32)))) : U32)
# Startup builds the configured buffer. A starved established stream resumes
# after one authority tick; it does not repeatedly repay startup latency.
def waiting(mode:Mode) -> Bool:
  match mode:
    case Priming{}: True{}
    case Holding{}: True{}
    case _: False{}
def is_buffering(state:State) -> Bool:
  match state:
    case State{_,Cursor{_,_,_,mode},_,_}: waiting(mode)
def refill(mode:Mode,delay:U32) -> U32:
  match mode:
    case Priming{}: delay
    case _: 1
# Integer-tick hysteresis spans one nominal 20Hz authority interval.
def boost(mode:Mode,tick:U32,latest:U32,delay:U32) -> Bool:
  match mode:
    case Boosting{}: Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),1n))
    case _: Nat.is_gt(Nat.sub(U32.to_nat(latest),U32.to_nat(tick)),Nat.add(U32.to_nat(delay),4n))
def selected_mode(active:Bool) -> Mode: Bool.pick(Mode,active,Boosting{},Playing{})
def mode_rate(mode:Mode,tick:U32,latest:U32,delay:U32) -> Nat:
  match mode:
    case Boosting{}: 84n
    case _: rate_for(tick,latest,delay)
def clock_running(reached:Bool,tick:U32,fraction:Nat,now:Nat,latest:U32,mode:Mode) -> Cursor:
  match reached:
    case True{}: Cursor{latest,0n,now,Holding{}}
    case False{}: Cursor{tick,fraction,now,mode}
def running_units(+tick:U32,+units:Nat,now:Nat,+latest:U32,mode:Mode) -> Cursor:
  clock_running(U32.is_ge(tick_after(tick,units),latest),tick_after(tick,units),Nat.mod(units,1000000n),now,latest,mode)
def resume_units(fraction:Nat,now:Nat,previous:Nat,rate:Nat) -> Nat:
  Nat.add(Nat.min(fraction,999999n),Nat.mul(Nat.min(elapsed(now,previous),33334n),rate))
def move_clock(+mode:Mode,+tick:U32,fraction:Nat,+previous:Nat,+now:Nat,+latest:U32,+delay:U32) -> Cursor:
  +selected = selected_mode(boost(mode,tick,latest,delay))
  running_units(tick,fraction_after(fraction,now,previous,mode_rate(selected,tick,latest,delay)),Nat.max(now,previous),latest,selected)
def wait_decided(ready:Bool,mode:Mode,+tick:U32,+fraction:Nat,+previous:Nat,+now:Nat,+latest:U32,+delay:U32) -> Cursor:
  match ready:
    case False{}: Cursor{tick,fraction,Nat.max(now,previous),mode}
    case True{}:
      +selected = selected_mode(boost(Playing{},tick,latest,delay))
      running_units(tick,resume_units(fraction,now,previous,mode_rate(selected,tick,latest,delay)),Nat.max(now,previous),latest,selected)
def wait_clock(+mode:Mode,+tick:U32,fraction:Nat,previous:Nat,now:Nat,+latest:U32,+delay:U32) -> Cursor:
  wait_decided(Bool.and(U32.is_ge(latest,tick),U32.is_ge((latest - tick : U32),refill(mode,delay))),mode,tick,fraction,previous,now,latest,delay)
def clock(cursor:Cursor,now:Nat,latest:U32,delay:U32) -> Cursor:
  match cursor:
    case Cursor{tick,fraction,previous,Priming{}}: wait_clock(Priming{},tick,fraction,previous,now,latest,delay)
    case Cursor{tick,fraction,previous,Holding{}}: wait_clock(Holding{},tick,fraction,previous,now,latest,delay)
    case Cursor{tick,fraction,previous,Playing{}}: move_clock(Playing{},tick,fraction,previous,now,latest,delay)
    case Cursor{tick,fraction,previous,Boosting{}}: move_clock(Boosting{},tick,fraction,previous,now,latest,delay)
def advance(state:State,now:Nat) -> State:
  match state:
    case State{[],cursor,recovered,delay}: State{[],cursor,recovered,delay}
    case State{+head <> tail,cursor,recovered,+delay}: State{head <> tail,clock(cursor,now,world_tick(frame(head)),delay),recovered,delay}

def identity(a:Actor,b:Actor) -> Bool:
  match a b:
    case Actor{k0,t0,g0,_,_,_,h0,o0} Actor{k1,t1,g1,_,_,_,h1,o1}:
      Bool.and(U32.is_eq(k0,k1),Bool.and(U32.is_eq(t0,t1),Bool.and(String.eq(g0,g1),Bool.and(U32.is_eq(o0,o1),Bool.and(h0,h1)))))
def blended(allowed:Bool,a:Actor,b:Actor,+alpha:F32) -> Actor:
  match allowed a b:
    case True{} Actor{key,kind,generation,x0,y0,age,alive,owner} Actor{_,_,_,x1,y1,_,_,_}: Actor{key,kind,generation,F32.lerp(x0,x1,alpha),F32.lerp(y0,y1,alpha),age,alive,owner}
    case False{} a _: a
def matched(found:Maybe<&2,Actor>,+old:Actor,alpha:F32) -> Actor:
  match found:
    case None{}: old
    case Some{+new}: blended(identity(old,new),old,new,alpha)
def mix_actor_impl(context:Mix,+old:Actor) -> Actor:
  match context:
    case Mix{index,alpha}: matched(BI.find(~Actor,index,actor_key(old)),old,alpha)
def mix_actor(context:Mix,old:Actor) -> Actor: mix_actor_impl(context,old)
def ratio(+older:U32,+newer:U32,tick:U32,fraction:Nat) -> F32:
  Bool.pick(F32,U32.is_gt(newer,older),F32.div(F32.add(U32.to_f32((tick - older : U32)),F32.div(F32.from_nat(fraction),1000000.0)),U32.to_f32(U32.max(1,(newer - older : U32)))),0.0)
def sample_pair(old:Indexed,new:Indexed,tick:U32,fraction:Nat,+alpha:F32) -> Sample:
  match old new:
    case Indexed{Frame{observation,_,_,players,bodies},_,_} Indexed{Frame{next,_,_,_,_},playerIndex,bodyIndex}:
      Sample{observation,next,tick,fraction,alpha,LM.map(~Actor,~Actor,~Mix,~mix_actor,Mix{playerIndex,alpha},players),LM.map(~Actor,~Actor,~Mix,~mix_actor,Mix{bodyIndex,alpha},bodies)}
def bracket_selected(atOrAfter:Bool,+old:Indexed,+new:Indexed,+tick:U32,+fraction:Nat,continue:Unit -> Sample) -> Sample:
  match atOrAfter:
    case True{}: sample_pair(old,new,tick,fraction,ratio(world_tick(frame(old)),world_tick(frame(new)),tick,fraction))
    case False{}: continue(Unit{})
def bracket(rows:List<&2,Indexed>,+new:Indexed,+tick:U32,+fraction:Nat) -> Sample:
  match rows:
    case []: sample_pair(new,new,tick,fraction,0.0)
    case +head <> tail: bracket_selected(U32.is_ge(tick,world_tick(frame(head))),head,new,tick,fraction,u => bracket(tail,head,tick,fraction))
def sample(state:State) -> Maybe<&2,Sample>:
  match state:
    case State{[],_,_,_}: None{}
    case State{+head <> tail,Cursor{tick,fraction,_,_},_,_}: Some{bracket(head <> tail,head,tick,fraction)}
def observation_rows(rows:List<&2,Indexed>) -> List<&2,U32>:
  match rows:
    case []: []
    case head <> tail: observation(frame(head)) <> observation_rows(tail)
def observations(state:State) -> List<&2,U32>:
  match state:
    case State{rows,_,_,_}: observation_rows(rows)
