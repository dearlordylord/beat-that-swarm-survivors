import Base
import ./coop-hit-journal.bend as J
import ./coop-playback.bend as P
import ./coop-contact-playback.bend as C
import ./body-index.bend as BI

# One cosmetic effect ledger for both roles. The journal owns due/seen identity;
# this ledger owns display lifetime, including receipts crossed during recovery.
# No game state or local projectile simulation is reachable through this API.
type Effect is Data: Effect{event:J.HitEvent,started:U32}
type State is Data: State{attached:Bool,played:J.Playback,effects:List<&2,Effect>,dropped:U32}
def duration() -> U32: 4
def capacity() -> Nat: 512n
def fresh() -> State: State{False{},J.playback(0),[],0}
def attach(journal:J.State) -> State: State{True{},J.attach(journal),[],0}
def same_epoch(state:State,journal:J.State) -> Bool:
  match state journal:
    case State{attached,J.Playback{epoch,_},_,_} J.State{other,_,_,_,_}: Bool.and(attached,U32.is_eq(epoch,other))
# Attach at accepted snapshot intake, before a first render can be delayed.
# Later same-epoch arrivals are observations, never a new history baseline.
def receive_selected(same:Bool,state:State,journal:J.State) -> State:
  match same:
    case True{}: state
    case False{}: attach(journal)
def receive(+state:State,+journal:J.State) -> State:
  receive_selected(same_epoch(state,journal),state,journal)
def key(effect:Effect) -> String:
  match effect:
    case Effect{event,_}: J.event_key(event)
def recent(+started:U32,+tick:U32) -> Bool:
  Bool.and(U32.is_le(started,tick),U32.is_lt((tick - started : U32),duration()))
def visible(effect:Effect,tick:U32) -> Bool:
  match effect:
    case Effect{_,started}: recent(started,tick)
def retained(keep:Bool,effect:Effect,rows:List<&2,Effect>) -> List<&2,Effect>:
  match keep:
    case True{}: effect <> rows
    case False{}: rows
def retain_go(rows:List<&2,Effect>,+tick:U32,acc:List<&2,Effect>) -> List<&2,Effect>:
  match rows:
    case []: List.reverse(&2,Effect,acc)
    case +head <> tail: retain_go(tail,tick,retained(visible(head,tick),head,acc))
def contains_go(rows:List<&2,Effect>,+id:String,found:Bool) -> Bool:
  match rows:
    case []: found
    case head <> tail: contains_go(tail,id,Bool.or(found,String.eq(key(head),id)))
def contains(rows:List<&2,Effect>,id:String) -> Bool: contains_go(rows,id,False{})
def eligible(event:J.HitEvent,tick:U32) -> Bool:
  match event:
    case J.HitEvent{_,at,_,_,_,_,_,_,_,_,_,_,_,outcome}: Bool.and(U32.is_eq(outcome,0),U32.is_le(at,tick))
def add_selected(allowed:Bool,duplicate:Bool,event:J.HitEvent,tick:U32,rows:List<&2,Effect>) -> List<&2,Effect>:
  match allowed duplicate:
    case True{} False{}: Effect{event,tick} <> rows
    case _ _: rows
def add(+event:J.HitEvent,+tick:U32,+rows:List<&2,Effect>) -> List<&2,Effect>:
  add_selected(eligible(event,tick),contains(rows,J.event_key(event)),event,tick,rows)
def add_rows(rows:List<&2,J.HitEvent>,+tick:U32,effects:List<&2,Effect>) -> List<&2,Effect>:
  match rows:
    case []: effects
    case head <> tail: add_rows(tail,tick,add(head,tick,effects))
def bounded(played:J.Playback,+rows:List<&2,Effect>,dropped:U32) -> State:
  State{True{},played,List.take(&2,Effect,rows,capacity()),(dropped + U32.from_nat(Nat.sub(List.length(&2,Effect,rows),capacity())) : U32)}
def completed(result:J.Played,rows:List<&2,Effect>,+tick:U32,dropped:U32) -> State:
  match result:
    case J.Played{played,events}: bounded(played,add_rows(events,tick,retain_go(rows,tick,[])),dropped)
def advance_same(state:State,journal:J.State,+sample:P.Sample) -> State:
  match state:
    case State{_,played,rows,dropped}: completed(J.play_sample(played,journal,sample),rows,J.presentation_tick(sample),dropped)
def advance_selected(same:Bool,state:State,journal:J.State,sample:P.Sample) -> State:
  match same:
    case True{}: advance_same(state,journal,sample)
    case False{}: attach(journal)
def advance(+state:State,+journal:J.State,sample:P.Sample) -> State:
  advance_selected(same_epoch(state,journal),state,journal,sample)

def rendered(event:J.HitEvent,+started:U32,+tick:U32,point:C.Point) -> C.Fx:
  match event point:
    case J.HitEvent{id,at,kind,_,_,seed,generation,_,_,_,_,_,radius,_} C.Point{x,y}:
      C.Fx{id,at,kind,seed,generation,x,y,radius,(tick - started : U32),F32.div(U32.to_f32((duration() - U32.min(duration(),(tick - started : U32)) : U32)),4.0)}
def render_effect(effect:Effect,+tick:U32,index:BI.Index<P.Actor>) -> C.Fx:
  match effect:
    case Effect{+event,started}: rendered(event,started,tick,C.fx_point(BI.find(~P.Actor,index,C.target_seed(event)),event))
def render_selected(keep:Bool,effect:Effect,tick:U32,index:BI.Index<P.Actor>,acc:List<&2,C.Fx>) -> List<&2,C.Fx>:
  match keep:
    case False{}: acc
    case True{}: render_effect(effect,tick,index) <> acc
def render_rows(rows:List<&2,Effect>,+tick:U32,+index:BI.Index<P.Actor>,acc:List<&2,C.Fx>) -> List<&2,C.Fx>:
  match rows:
    case []: List.reverse(&2,C.Fx,acc)
    case +head <> tail: render_rows(tail,tick,index,render_selected(visible(head,tick),head,tick,index,acc))
def render(state:State,sample:P.Sample) -> List<&2,C.Fx>:
  match state sample:
    case State{_,_,rows,_} P.Sample{_,_,tick,_,_,_,bodies}: render_rows(rows,tick,P.index_rows(bodies,BI.Empty{}),[])
