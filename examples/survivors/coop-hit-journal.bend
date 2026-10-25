import Base
import ./coop-playback.bend as SnapshotPlayback
import ./coop-prediction-replay.bend as Replay
import ./contact-id-set.bend as IDs

# A confirmed contact, not a damage/kill prediction. Geometry is copied from
# the authoritative resolver's selected contact and its immutable lifetimes.
# This is bounded cosmetic history, never HP/reward authority. Aged retained
# rows increment expired; capacity-evicted rows increment overflow (U32 counters).
# Resent duplicates are ignored before capacity accounting. Incoming rows outside
# the current64-tick window are ineligible, not durable game events.
# Valid event IDs originate in event_id (numeric lifetime fields and colons).
type HitEvent is Data: HitEvent{id:String,tick:U32,kind:U32,shotId:String,shotSeed:U32,targetSeed:U32,targetGeneration:U32,fraction:F32,impactX:F32,impactY:F32,targetAtImpactX:F32,targetAtImpactY:F32,radius:F32,outcome:U32}
type State is Data: State{epoch:U32,now:U32,events:List<&2,HitEvent>,overflow:U32,expired:U32}
type Seen is Data: Seen{id:String,tick:U32}
type Playback is Data: Playback{epoch:U32,seen:List<&2,Seen>}
type Played is Data: Played{state:Playback,events:List<&2,HitEvent>}
def window() -> U32: 64
def capacity() -> Nat: 512n
def shot_id(player:U32,born:U32,weapon:U32,slot:U32) -> String: Replay.generation(player,born,0,weapon,slot)
def event_id(tick:U32,kind:U32,shotId:String,targetSeed:U32,targetGeneration:U32) -> String:
  shotId ++ ":" ++ U32.show(targetSeed) ++ ":" ++ U32.show(targetGeneration) ++ ":" ++ U32.show(tick) ++ ":" ++ U32.show(kind)
def fresh(epoch:U32) -> State: State{epoch,0,[],0,0}
def playback(epoch:U32) -> Playback: Playback{epoch,[]}

def event_tick(event:HitEvent) -> U32:
  match event:
    case HitEvent{_,tick,_,_,_,_,_,_,_,_,_,_,_,_}: tick
def event_key(event:HitEvent) -> String:
  match event:
    case HitEvent{id,_,_,_,_,_,_,_,_,_,_,_,_,_}: id
def recent(+now:U32,+tick:U32) -> Bool: Bool.and(U32.is_le(tick,now),U32.is_lt((now - tick : U32),window()))
def keep_event(keep:Bool,head:HitEvent,+tail:List<&2,HitEvent>) -> List<&2,HitEvent>: Bool.pick(List<&2,HitEvent>,keep,head <> tail,tail)
def recent_events(rows:List<&2,HitEvent>,+now:U32) -> List<&2,HitEvent>:
  match rows:
    case []: []
    case +head <> tail: keep_event(recent(now,event_tick(head)),head,recent_events(tail,now))
def contains_go(rows:List<&2,HitEvent>,+id:String,found:Bool) -> Bool:
  match rows:
    case []: found
    case head <> tail: contains_go(tail,id,Bool.or(found,String.eq(event_key(head),id)))
def contains(rows:List<&2,HitEvent>,id:String) -> Bool: contains_go(rows,id,False{})
def append_fresh(duplicate:Bool,head:HitEvent,rows:List<&2,HitEvent>) -> List<&2,HitEvent>:
  match duplicate:
    case True{}: rows
    case False{}: head <> rows
def append_reverse(incoming:List<&2,HitEvent>,+rows:List<&2,HitEvent>) -> List<&2,HitEvent>:
  match incoming:
    case []: rows
    case +head <> tail: append_reverse(tail,append_fresh(contains(rows,event_key(head)),head,rows))
# Canonical index order makes prepend-plus-insert structurally exact. This
# index is built once per nonempty incoming batch, not once per membership test.
def event_index(rows:List<&2,HitEvent>) -> IDs.IdSet:
  match rows:
    case []: IDs.empty()
    case +head <> tail: IDs.insert(event_index(tail),event_key(head))
def indexed_insert(duplicate:Bool,index:IDs.IdSet,id:String) -> IDs.IdSet:
  match duplicate:
    case True{}: index
    case False{}: IDs.insert(index,id)
def append_indexed(incoming:List<&2,HitEvent>,+rows:List<&2,HitEvent>,+index:IDs.IdSet) -> List<&2,HitEvent>:
  match incoming:
    case []: rows
    case +head <> tail:
      +duplicate = IDs.contains(index,event_key(head))
      append_indexed(tail,append_fresh(duplicate,head,rows),indexed_insert(duplicate,index,event_key(head)))
def append_indexed_start(+incoming:List<&2,HitEvent>,+rows:List<&2,HitEvent>) -> List<&2,HitEvent>:
  append_indexed(incoming,rows,event_index(rows))
def append_unique(incoming:List<&2,HitEvent>,rows:List<&2,HitEvent>) -> List<&2,HitEvent>:
  match incoming:
    case []: rows
    case head <> tail: List.reverse(&2,HitEvent,append_indexed_start(head <> tail,List.reverse(&2,HitEvent,rows)))
def trim(rows:List<&2,HitEvent>) -> List<&2,HitEvent>:
  match rows:
    case +rows: List.drop(&2,HitEvent,rows,Nat.sub(List.length(&2,HitEvent,rows),capacity()))
def ingest_at(epoch:U32,+now:U32,+old:List<&2,HitEvent>,overflow:U32,expired:U32,incoming:List<&2,HitEvent>) -> State:
  +kept = recent_events(old,now)
  +all = append_unique(recent_events(incoming,now),kept)
  State{epoch,now,trim(all),(overflow + U32.from_nat(Nat.sub(List.length(&2,HitEvent,all),capacity())) : U32),(expired + U32.from_nat(Nat.sub(List.length(&2,HitEvent,old),List.length(&2,HitEvent,kept))) : U32)}
def ingest(state:State,now:U32,incoming:List<&2,HitEvent>) -> State:
  match state:
    case State{epoch,+previous,rows,overflow,expired}: ingest_at(epoch,U32.max(previous,now),rows,overflow,expired,incoming)
def seen_contains_go(rows:List<&2,Seen>,+id:String,found:Bool) -> Bool:
  match rows:
    case []: found
    case Seen{key,_} <> tail: seen_contains_go(tail,id,Bool.or(found,String.eq(key,id)))
def seen_contains(rows:List<&2,Seen>,id:String) -> Bool: seen_contains_go(rows,id,False{})
def keep_seen(keep:Bool,head:Seen,+tail:List<&2,Seen>) -> List<&2,Seen>: Bool.pick(List<&2,Seen>,keep,head <> tail,tail)
def seen_tick(value:Seen) -> U32:
  match value:
    case Seen{_,tick}: tick
def seen_recent_go(rows:List<&2,Seen>,+now:U32,acc:List<&2,Seen>) -> List<&2,Seen>:
  match rows:
    case []: List.reverse(&2,Seen,acc)
    case +head <> tail: seen_recent_go(tail,now,keep_seen(recent(now,seen_tick(head)),head,acc))
def seen_recent(rows:List<&2,Seen>,now:U32) -> List<&2,Seen>: seen_recent_go(rows,now,[])
def mark(accept:Bool,+rows:List<&2,Seen>,+event:HitEvent) -> List<&2,Seen>:
  Bool.pick(List<&2,Seen>,accept,Seen{event_key(event),event_tick(event)} <> rows,rows)
def play_rows_go(rows:List<&2,HitEvent>,epoch:U32,+seen:List<&2,Seen>,+displayTick:U32,acc:List<&2,HitEvent>) -> Played:
  match rows:
    case []: Played{Playback{epoch,List.take(&2,Seen,seen,capacity())},List.reverse(&2,HitEvent,acc)}
    case +head <> tail:
      +accept = Bool.and(U32.is_le(event_tick(head),displayTick),Bool.not(seen_contains(seen,event_key(head))))
      play_rows_go(tail,epoch,mark(accept,seen,head),displayTick,keep_event(accept,head,acc))
def seen_key(value:Seen) -> String:
  match value:
    case Seen{id,_}: id
def seen_index(rows:List<&2,Seen>) -> IDs.IdSet:
  match rows:
    case []: IDs.empty()
    case +head <> tail: IDs.insert(seen_index(tail),seen_key(head))
def play_indexed(rows:List<&2,HitEvent>,epoch:U32,+seen:List<&2,Seen>,+displayTick:U32,acc:List<&2,HitEvent>,+index:IDs.IdSet) -> Played:
  match rows:
    case []: Played{Playback{epoch,List.take(&2,Seen,seen,capacity())},List.reverse(&2,HitEvent,acc)}
    case +head <> tail:
      +accept = Bool.and(U32.is_le(event_tick(head),displayTick),Bool.not(IDs.contains(index,event_key(head))))
      play_indexed(tail,epoch,mark(accept,seen,head),displayTick,keep_event(accept,head,acc),indexed_insert(Bool.not(accept),index,event_key(head)))
def play_rows(rows:List<&2,HitEvent>,epoch:U32,+seen:List<&2,Seen>,displayTick:U32) -> Played:
  play_indexed(rows,epoch,seen,displayTick,[],seen_index(seen))
def play(state:Playback,journal:State,displayTick:U32) -> Played:
  match state journal:
    case Playback{epoch,seen} State{+journalEpoch,now,rows,_,_}: play_rows(rows,journalEpoch,Bool.pick(List<&2,Seen>,U32.is_eq(epoch,journalEpoch),seen_recent(seen,now),[]),displayTick)

def native_event(event:HitEvent) -> String:
  match event:
    case HitEvent{id,tick,kind,shotId,shotSeed,targetSeed,targetGeneration,fraction,impactX,impactY,targetAtImpactX,targetAtImpactY,radius,outcome}:
      "{\"$\":\"HitEvent\",\"id\":\"" ++ id ++ "\",\"tick\":" ++ U32.show(tick) ++ ",\"kind\":" ++ U32.show(kind) ++ ",\"shotId\":\"" ++ shotId ++ "\",\"shotSeed\":" ++ U32.show(shotSeed) ++ ",\"targetSeed\":" ++ U32.show(targetSeed) ++ ",\"targetGeneration\":" ++ U32.show(targetGeneration) ++ ",\"fraction\":" ++ F32.show(fraction) ++ ",\"impactX\":" ++ F32.show(impactX) ++ ",\"impactY\":" ++ F32.show(impactY) ++ ",\"targetAtImpactX\":" ++ F32.show(targetAtImpactX) ++ ",\"targetAtImpactY\":" ++ F32.show(targetAtImpactY) ++ ",\"radius\":" ++ F32.show(radius) ++ ",\"outcome\":" ++ U32.show(outcome) ++ "}"
def native_events_go(rows:List<&2,HitEvent>,acc:String,closers:String) -> String:
  match rows:
    case []: acc ++ "{\"$\":\"Nil\"}" ++ closers
    case head <> tail: native_events_go(tail,acc ++ "{\"$\":\"Con\",\"head\":" ++ native_event(head) ++ ",\"tail\":","}" ++ closers)
def native_events(rows:List<&2,HitEvent>) -> String: native_events_go(rows,"","")

# Joining a running stream consumes its existing cosmetic history without
# replaying it. Future receipts remain eligible at their presentation tick.
def seen_rows_go(rows:List<&2,HitEvent>,acc:List<&2,Seen>) -> List<&2,Seen>:
  match rows:
    case []: acc
    case +head <> tail: seen_rows_go(tail,Seen{event_key(head),event_tick(head)} <> acc)
def seen_rows(rows:List<&2,HitEvent>) -> List<&2,Seen>: seen_rows_go(rows,[])
def attach(journal:State) -> Playback:
  match journal:
    case State{epoch,_,rows,_,_}: Playback{epoch,seen_rows(rows)}

def presentation_tick(sample:SnapshotPlayback.Sample) -> U32:
  match sample:
    case SnapshotPlayback.Sample{_,_,tick,_,_,_,_}: tick
def play_sample(state:Playback,journal:State,sample:SnapshotPlayback.Sample) -> Played:
  play(state,journal,presentation_tick(sample))

# Arrival-time priming is a separate consumer from presentation-time FX.
def collect(state:Playback,+journal:State) -> Played:
  match journal:
    case State{_,now,_,_,_}: play(state,journal,now)
# Only a finite shot exhausting its selected recipient budget ends at contact.
def contact_kind(+kind:U32,+pierce:U32,selected:Nat) -> U32:
  Bool.pick(U32,Bool.and(U32.is_eq(kind,0),Bool.and(U32.is_gt(pierce,0),Bool.and(U32.is_lt(pierce,9999),Nat.is_ge(selected,U32.to_nat(pierce))))),2,kind)

# Cap raw source receipts before JSON construction. Omission counts source rows,
# not unique IDs: Core source selection is unique; generic ingest still dedups.
type Emission is Data: Emission{events:List<&2,HitEvent>,omitted:U32}
def event_count_go(rows:List<&2,HitEvent>,acc:Nat) -> Nat:
  match rows:
    case []: acc
    case _ <> tail: event_count_go(tail,1n+acc)
def event_count(rows:List<&2,HitEvent>) -> Nat: event_count_go(rows,0n)
def emission_for(+rows:List<&2,HitEvent>,+count:Nat) -> Emission:
  Emission{List.drop(&2,HitEvent,rows,Nat.sub(count,capacity())),U32.from_nat(Nat.sub(count,capacity()))}
def emit_capped(+rows:List<&2,HitEvent>) -> Emission:
  emission_for(rows,event_count(rows))
def add_omitted(state:State,omitted:U32) -> State:
  match state:
    case State{epoch,now,events,overflow,expired}: State{epoch,now,events,(overflow + omitted : U32),expired}
def ingest_capped(state:State,now:U32,rows:List<&2,HitEvent>,omitted:U32) -> State:
  add_omitted(ingest(state,now,rows),omitted)
