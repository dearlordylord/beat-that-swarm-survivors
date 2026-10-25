import Base
import ./coop-playback.bend as SnapshotPlayback
import ./coop-hit-journal.bend as J
import ./contact-id-set.bend as IDs

# Cosmetic host-confirmed contacts only. HP/rewards remain canonical World data.
# These laws pin retention/playback policy, not the Game resolver or transport.
law limits_exact:
  {J.window() == 64 : U32} & {J.capacity() == 512n : Nat}
law fresh_exact:
  for +epoch:U32
  {J.fresh(epoch) == J.State{epoch,0,[],0,0} : J.State}
law recent_exact:
  for +now:U32
  for +tick:U32
  {J.recent(now,tick) == Bool.and(U32.is_le(tick,now),U32.is_lt((now - tick : U32),64)) : Bool}
law retention_exact:
  for +epoch:U32
  for +now:U32
  for +old:List<&2,J.HitEvent>
  for +overflow:U32
  for +expired:U32
  for +incoming:List<&2,J.HitEvent>
  {J.ingest_at(epoch,now,old,overflow,expired,incoming) == J.State{epoch,now,J.trim(J.append_unique(J.recent_events(incoming,now),J.recent_events(old,now))),(overflow + U32.from_nat(Nat.sub(List.length(&2,J.HitEvent,J.append_unique(J.recent_events(incoming,now),J.recent_events(old,now))),512n)) : U32),(expired + U32.from_nat(Nat.sub(List.length(&2,J.HitEvent,old),List.length(&2,J.HitEvent,J.recent_events(old,now)))) : U32)} : J.State}
law ingest_clock_exact:
  for +epoch:U32
  for +previous:U32
  for +now:U32
  for +old:List<&2,J.HitEvent>
  for +overflow:U32
  for +expired:U32
  for +incoming:List<&2,J.HitEvent>
  {J.ingest(J.State{epoch,previous,old,overflow,expired},now,incoming) == J.ingest_at(epoch,U32.max(previous,now),old,overflow,expired,incoming) : J.State}
law trim_exact:
  for +rows:List<&2,J.HitEvent>
  {J.trim(rows) == List.drop(&2,J.HitEvent,rows,Nat.sub(List.length(&2,J.HitEvent,rows),512n)) : List<&2,J.HitEvent>}
law append_nil:
  for +rows:List<&2,J.HitEvent>
  {J.append_unique([],rows) == rows : List<&2,J.HitEvent>}
law append_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +rows:List<&2,J.HitEvent>
  {J.append_unique(head <> tail,rows) == J.append_unique(tail,Bool.pick(List<&2,J.HitEvent>,J.contains(rows,J.event_key(head)),rows,List.append(&2,J.HitEvent,rows,[head]))) : List<&2,J.HitEvent>}
# Guarantees: the public player starts one tail-safe scan with no emitted rows.
# Why it matters: dense receipt batches do not recurse once per accepted effect.
law playback_entry:
  for +rows:List<&2,J.HitEvent>
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for +tick:U32
  {J.play_rows(rows,epoch,seen,tick) == J.play_rows_go(rows,epoch,seen,tick,[]) : J.Played}
# Guarantees: completed scans retain newest512 IDs and emit input order.
# Why it matters: cap pressure discards oldest dedup history, never new receipts.
law playback_nil:
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for tick:U32
  for +acc:List<&2,J.HitEvent>
  {J.play_rows_go([],epoch,seen,tick,acc) == J.Played{J.Playback{epoch,List.take(&2,J.Seen,seen,512n)},List.reverse(&2,J.HitEvent,acc)} : J.Played}
# Guarantees: each due unseen input is marked and accumulated once before next.
# Why it matters: duplicates within one dense batch cannot emit twice.
law playback_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for +tick:U32
  for +acc:List<&2,J.HitEvent>
  {J.play_rows_go(head <> tail,epoch,seen,tick,acc) == J.play_rows_go(tail,epoch,J.mark(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),seen,head),tick,J.keep_event(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))),head,acc)) : J.Played}
law mark_false:
  for +seen:List<&2,J.Seen>
  for +event:J.HitEvent
  {J.mark(False{},seen,event) == seen : List<&2,J.Seen>}
law mark_true:
  for +seen:List<&2,J.Seen>
  for +event:J.HitEvent
  {J.mark(True{},seen,event) == J.Seen{J.event_key(event),J.event_tick(event)} <> seen : List<&2,J.Seen>}
law contains_nil:
  for +id:String
  {J.contains([],id) == False{} : Bool}
law contains_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +id:String
  {J.contains(head <> tail,id) == Bool.or(String.eq(J.event_key(head),id),J.contains(tail,id)) : Bool}
law recent_nil:
  for +now:U32
  {J.recent_events([],now) == [] : List<&2,J.HitEvent>}
law recent_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +now:U32
  {J.recent_events(head <> tail,now) == Bool.pick(List<&2,J.HitEvent>,J.recent(now,J.event_tick(head)),head <> J.recent_events(tail,now),J.recent_events(tail,now)) : List<&2,J.HitEvent>}
law seen_nil:
  for +id:String
  {J.seen_contains([],id) == False{} : Bool}
law seen_cons:
  for +id:String
  for +tick:U32
  for +tail:List<&2,J.Seen>
  for +key:String
  {J.seen_contains(J.Seen{id,tick} <> tail,key) == Bool.or(String.eq(id,key),J.seen_contains(tail,key)) : Bool}
# Guarantees: the recent-ID scan starts with an empty reverse accumulator.
# Why it matters: filtering retained history is bounded-stack work.
law seen_recent_entry:
  for +rows:List<&2,J.Seen>
  for +now:U32
  {J.seen_recent(rows,now) == J.seen_recent_go(rows,now,[]) : List<&2,J.Seen>}
# Guarantees: completed filtering restores the original newest-first order.
# Why it matters: later capacity trimming retains the newest IDs.
law seen_recent_nil:
  for now:U32
  for +acc:List<&2,J.Seen>
  {J.seen_recent_go([],now,acc) == List.reverse(&2,J.Seen,acc) : List<&2,J.Seen>}
# Guarantees: only recent IDs enter the retained-history accumulator.
# Why it matters: expired IDs do not occupy the bounded dedup ledger.
law seen_recent_cons:
  for +id:String
  for +tick:U32
  for +tail:List<&2,J.Seen>
  for +now:U32
  for +acc:List<&2,J.Seen>
  {J.seen_recent_go(J.Seen{id,tick} <> tail,now,acc) == J.seen_recent_go(tail,now,J.keep_seen(J.recent(now,tick),J.Seen{id,tick},acc)) : List<&2,J.Seen>}
# Guarantees: retained-ID age is its stored event tick.
# Why it matters: expiry cannot accidentally use an observation identity.
law seen_tick_exact:
  for id:String
  for +tick:U32
  {J.seen_tick(J.Seen{id,tick}) == tick : U32}
law play_exact:
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for +journalEpoch:U32
  for +now:U32
  for +rows:List<&2,J.HitEvent>
  for +overflow:U32
  for +expired:U32
  for +display:U32
  {J.play(J.Playback{epoch,seen},J.State{journalEpoch,now,rows,overflow,expired},display) == J.play_rows(rows,journalEpoch,Bool.pick(List<&2,J.Seen>,U32.is_eq(epoch,journalEpoch),J.seen_recent(seen,now),[]),display) : J.Played}
law attach_exact:
  for +epoch:U32
  for +now:U32
  for +rows:List<&2,J.HitEvent>
  for +overflow:U32
  for +expired:U32
  {J.attach(J.State{epoch,now,rows,overflow,expired}) == J.Playback{epoch,J.seen_rows(rows)} : J.Playback}
# Guarantees: joining consumes journal rows into newest-first dedup history.
# Why it matters: reconnect never replays old effects and trims newest IDs first.
law attach_entry:
  for +rows:List<&2,J.HitEvent>
  {J.seen_rows(rows) == J.seen_rows_go(rows,[]) : List<&2,J.Seen>}
# Guarantees: attachment finishes with its reverse accumulator unchanged.
# Why it matters: no phantom ID is added during reconnect.
law attach_nil:
  for +acc:List<&2,J.Seen>
  {J.seen_rows_go([],acc) == acc : List<&2,J.Seen>}
# Guarantees: each journal row contributes its exact identity and tick once.
# Why it matters: attaching the full dense journal remains bounded-stack.
law attach_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +acc:List<&2,J.Seen>
  {J.seen_rows_go(head <> tail,acc) == J.seen_rows_go(tail,J.Seen{J.event_key(head),J.event_tick(head)} <> acc) : List<&2,J.Seen>}
law keep_event_true:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  {J.keep_event(True{},head,tail) == head <> tail : List<&2,J.HitEvent>}
law keep_event_false:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  {J.keep_event(False{},head,tail) == tail : List<&2,J.HitEvent>}
law keep_seen_true:
  for +head:J.Seen
  for +tail:List<&2,J.Seen>
  {J.keep_seen(True{},head,tail) == head <> tail : List<&2,J.Seen>}
law keep_seen_false:
  for +head:J.Seen
  for +tail:List<&2,J.Seen>
  {J.keep_seen(False{},head,tail) == tail : List<&2,J.Seen>}
law contains_go_nil:
  for +id:String
  for +found:Bool
  {J.contains_go([],id,found) == found : Bool}
law contains_go_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +id:String
  for +found:Bool
  {J.contains_go(head <> tail,id,found) == J.contains_go(tail,id,Bool.or(found,String.eq(J.event_key(head),id))) : Bool}
law contains_entry:
  for +rows:List<&2,J.HitEvent>
  for +id:String
  {J.contains(rows,id) == J.contains_go(rows,id,False{}) : Bool}
law seen_go_nil:
  for +id:String
  for +found:Bool
  {J.seen_contains_go([],id,found) == found : Bool}
law seen_go_cons:
  for +key:String
  for +tick:U32
  for +tail:List<&2,J.Seen>
  for +id:String
  for +found:Bool
  {J.seen_contains_go(J.Seen{key,tick} <> tail,id,found) == J.seen_contains_go(tail,id,Bool.or(found,String.eq(key,id))) : Bool}
law seen_entry:
  for +rows:List<&2,J.Seen>
  for +id:String
  {J.seen_contains(rows,id) == J.seen_contains_go(rows,id,False{}) : Bool}
law event_key_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shotId:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +x:F32
  for +y:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {J.event_key(J.HitEvent{id,tick,kind,shotId,shotSeed,targetSeed,generation,fraction,x,y,tx,ty,radius,outcome}) == id : String}
law event_tick_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shotId:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +x:F32
  for +y:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {J.event_tick(J.HitEvent{id,tick,kind,shotId,shotSeed,targetSeed,generation,fraction,x,y,tx,ty,radius,outcome}) == tick : U32}
law presentation_tick_exact:
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +alpha:F32
  for +players:List<&2,SnapshotPlayback.Actor>
  for +bodies:List<&2,SnapshotPlayback.Actor>
  {J.presentation_tick(SnapshotPlayback.Sample{base,next,tick,fraction,alpha,players,bodies}) == tick : U32}
law play_sample_exact:
  for +state:J.Playback
  for +journal:J.State
  for +sample:SnapshotPlayback.Sample
  {J.play_sample(state,journal,sample) == J.play(state,journal,J.presentation_tick(sample)) : J.Played}

# Guarantees: arrival-time priming consumes at the journal's authority tick.
# Why it matters: a guide may arrive before its remote presentation-time FX.
law collect_exact:
  for +state:J.Playback
  for +epoch:U32
  for +now:U32
  for +events:List<&2,J.HitEvent>
  for +overflow:U32
  for +expired:U32
  {J.collect(state,J.State{epoch,now,events,overflow,expired}) == J.play(state,J.State{epoch,now,events,overflow,expired},now) : J.Played}
# Guarantees: terminal contacts are exactly finite nonzero exhausted budgets.
# Why it matters: a continuing piercing shot or aura must not disappear at a hit.
law contact_kind_exact:
  for +kind:U32
  for +pierce:U32
  for +selected:Nat
  {J.contact_kind(kind,pierce,selected) == Bool.pick(U32,Bool.and(U32.is_eq(kind,0),Bool.and(U32.is_gt(pierce,0),Bool.and(U32.is_lt(pierce,9999),Nat.is_ge(selected,U32.to_nat(pierce))))),2,kind) : U32}

# Guarantees: source emission retains the same last512 ordered source rows.
# Why it matters: dense AoE must be bounded before JSON, not after worker parse.
law emission_exact:
  for +rows:List<&2,J.HitEvent>
  {J.emit_capped(rows) == J.Emission{J.trim(rows),U32.from_nat(Nat.sub(List.length(&2,J.HitEvent,rows),512n))} : J.Emission}
def emitted_events(value:J.Emission) -> List<&2,J.HitEvent>:
  match value:
    case J.Emission{rows,_}: rows
def emitted_omitted(value:J.Emission) -> U32:
  match value:
    case J.Emission{_,omitted}: omitted
# Guarantees: the emission event projection preserves every retained row.
# Why it matters: a capped JSON frame must not substitute or erase kept contacts.
law emitted_rows_projection:
  for +rows:List<&2,J.HitEvent>
  for omitted:U32
  {emitted_events(J.Emission{rows,omitted}) == rows : List<&2,J.HitEvent>}
# Guarantees: the omission projection returns its raw source-row counter.
# Why it matters: worker overflow accounting must receive the actual omitted count.
law emitted_omitted_projection:
  for rows:List<&2,J.HitEvent>
  for +omitted:U32
  {emitted_omitted(J.Emission{rows,omitted}) == omitted : U32}
# Guarantees: every source emission contains at most512 contacts, regardless of input size.
# Why it matters: legitimate thousands-of-contact AoE cannot create a huge worker journal input.
law emitted_rows_bounded:
  for +rows:List<&2,J.HitEvent>
  {Nat.is_le(List.length(&2,J.HitEvent,emitted_events(J.emit_capped(rows))),512n) == True{} : Bool}
# Guarantees: raw source omissions are added only to overflow moduloU32.
# Why it matters: omitted cosmetic rows cannot alter canonical receipts or expiry accounting.
law add_omitted_exact:
  for +epoch:U32
  for +now:U32
  for +events:List<&2,J.HitEvent>
  for +overflow:U32
  for +expired:U32
  for +omitted:U32
  {J.add_omitted(J.State{epoch,now,events,overflow,expired},omitted) == J.State{epoch,now,events,(overflow + omitted : U32),expired} : J.State}
# Guarantees: capped ingest retains ordinary duplicate/expiry semantics then accounts raw source omissions.
# Why it matters: the dense-source cap must not change generic journal behavior.
law ingest_capped_exact:
  for +state:J.State
  for +now:U32
  for +events:List<&2,J.HitEvent>
  for +omitted:U32
  {J.ingest_capped(state,now,events,omitted) == J.add_omitted(J.ingest(state,now,events),omitted) : J.State}
# Guarantees: the source row counter returns its accumulated count on completion.
# Why it matters: raw dense contact input must be counted without host stack growth.
law event_count_nil:
  for +acc:Nat
  {J.event_count_go([],acc) == acc : Nat}
# Guarantees: each source row contributes exactly one to the tail counter.
# Why it matters: omissions count raw selected contacts without deduplication.
law event_count_cons:
  for head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +acc:Nat
  {J.event_count_go(head <> tail,acc) == J.event_count_go(tail,1n+acc) : Nat}
# Guarantees: the tail source counter equals ordinary list length plus its accumulator.
# Why it matters: stack safety cannot change the source omission arithmetic.
law event_count_acc_exact:
  for +rows:List<&2,J.HitEvent>
  for +acc:Nat
  {J.event_count_go(rows,acc) == Nat.add(List.length(&2,J.HitEvent,rows),acc) : Nat}
# Guarantees: raw source count is exactly list length for every input.
# Why it matters: bounded emission must retain the same suffix as ordinary trim.
law event_count_exact:
  for +rows:List<&2,J.HitEvent>
  {J.event_count(rows) == List.length(&2,J.HitEvent,rows) : Nat}
# Guarantees: emission drops the raw excess prefix and preserves the ordered suffix.
# Why it matters: bounding before JSON must not change which512 source contacts remain.
law emission_for_exact:
  for +rows:List<&2,J.HitEvent>
  for +count:Nat
  {J.emission_for(rows,count) == J.Emission{List.drop(&2,J.HitEvent,rows,Nat.sub(count,512n)),U32.from_nat(Nat.sub(count,512n))} : J.Emission}
# Guarantees: public emission uses the tail-safe exact source count.
# Why it matters: a correct unused counter cannot protect the actual serializer path.
law emit_capped_entry:
  for +rows:List<&2,J.HitEvent>
  {J.emit_capped(rows) == J.emission_for(rows,J.event_count(rows)) : J.Emission}
# Guarantees: duplicate source IDs keep the reverse accumulator unchanged.
# Why it matters: duplicate receipts do not allocate an unused growing list copy.
law append_fresh_duplicate:
  for head:J.HitEvent
  for +rows:List<&2,J.HitEvent>
  {J.append_fresh(True{},head,rows) == rows : List<&2,J.HitEvent>}
# Guarantees: a new source ID contributes one row to the reverse accumulator.
# Why it matters: accepted dense receipts require one cons each, not a copied prefix.
law append_fresh_new:
  for +head:J.HitEvent
  for +rows:List<&2,J.HitEvent>
  {J.append_fresh(False{},head,rows) == head <> rows : List<&2,J.HitEvent>}
# Guarantees: a completed reverse scan retains its entire accumulator.
# Why it matters: final reversal must not lose existing journal history.
law append_reverse_nil:
  for +rows:List<&2,J.HitEvent>
  {J.append_reverse([],rows) == rows : List<&2,J.HitEvent>}
# Guarantees: each input ID is tested against all previously retained IDs.
# Why it matters: duplicates in one burst retain their first occurrence exactly.
law append_reverse_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +rows:List<&2,J.HitEvent>
  {J.append_reverse(head <> tail,rows) == J.append_reverse(tail,J.append_fresh(J.contains(rows,J.event_key(head)),head,rows)) : List<&2,J.HitEvent>}
# Guarantees: the optimized public operation restores FIFO after reverse accumulation.
# Why it matters: removing prefix copies cannot change externally observed receipt order.
law append_unique_entry:
  for +incoming:List<&2,J.HitEvent>
  for +rows:List<&2,J.HitEvent>
  {J.append_unique(incoming,rows) == List.reverse(&2,J.HitEvent,J.append_reverse(incoming,List.reverse(&2,J.HitEvent,rows))) : List<&2,J.HitEvent>}

# Guarantees: the empty row list produces the empty exact-string index.
# Why it matters: a fresh deduplication pass cannot assume any existing ID.
law event_index_nil:
  {J.event_index([]) == IDs.empty() : IDs.IdSet}
# Guarantees: canonical index construction inserts the head after the tail index.
# Why it matters: prepending a new receipt and inserting its ID preserve one structural invariant.
law event_index_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  {J.event_index(head <> tail) == IDs.insert(J.event_index(tail),J.event_key(head)) : IDs.IdSet}
# Guarantees: every queried ID agrees between the canonical index and list membership.
# Why it matters: indexed deduplication must preserve exact string identity without collisions.
law event_index_membership:
  for +rows:List<&2,J.HitEvent>
  for +id:String
  {IDs.contains(J.event_index(rows),id) == J.contains(rows,id) : Bool}
# Guarantees: a duplicate leaves the persistent index unchanged.
# Why it matters: repeated receipts must not rebuild or grow the index.
law indexed_insert_duplicate:
  for +index:IDs.IdSet
  for id:String
  {J.indexed_insert(True{},index,id) == index : IDs.IdSet}
# Guarantees: a new receipt adds its exact ID to the persistent index.
# Why it matters: later rows in the same batch must see the newly retained receipt.
law indexed_insert_new:
  for +index:IDs.IdSet
  for +id:String
  {J.indexed_insert(False{},index,id) == IDs.insert(index,id) : IDs.IdSet}
# Guarantees: the completed indexed fold returns every retained reverse row.
# Why it matters: performance indexing cannot erase existing journal state.
law append_indexed_nil:
  for +rows:List<&2,J.HitEvent>
  for index:IDs.IdSet
  {J.append_indexed([],rows,index) == rows : List<&2,J.HitEvent>}
# Guarantees: the same membership decision controls both row retention and index insertion.
# Why it matters: a mismatched branch could suppress a valid later contact or emit duplicates.
law append_indexed_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +rows:List<&2,J.HitEvent>
  for +index:IDs.IdSet
  {J.append_indexed(head <> tail,rows,index) == J.append_indexed(tail,J.append_fresh(IDs.contains(index,J.event_key(head)),head,rows),J.indexed_insert(IDs.contains(index,J.event_key(head)),index,J.event_key(head))) : List<&2,J.HitEvent>}
# Guarantees: a batch builds its existing-row index once before the indexed fold.
# Why it matters: no whole-list membership scan occurs for every incoming receipt.
law append_indexed_start_exact:
  for +incoming:List<&2,J.HitEvent>
  for +rows:List<&2,J.HitEvent>
  {J.append_indexed_start(incoming,rows) == J.append_indexed(incoming,rows,J.event_index(rows)) : List<&2,J.HitEvent>}
# Guarantees: the indexed fold equals the original reverse-list reference for arbitrary receipts.
# Why it matters: optimization cannot alter FIFO, first-occurrence or duplicate semantics.
law append_indexed_refines_reference:
  for +incoming:List<&2,J.HitEvent>
  for +rows:List<&2,J.HitEvent>
  {J.append_indexed(incoming,rows,J.event_index(rows)) == J.append_reverse(incoming,rows) : List<&2,J.HitEvent>}
# Guarantees: the structural index invariant implies matching membership for every ID.
# Why it matters: the carried index is coherent with the retained reverse rows.
law indexed_state_membership:
  for +rows:List<&2,J.HitEvent>
  for +index:IDs.IdSet
  for +id:String
  for coherent:{index == J.event_index(rows) : IDs.IdSet}
  {IDs.contains(index,id) == J.contains(rows,id) : Bool}
# Guarantees: any coherent carried index yields the same complete reference result.
# Why it matters: callers cannot satisfy refinement with an unrelated proof-only index.
law coherent_index_refinement:
  for +incoming:List<&2,J.HitEvent>
  for +rows:List<&2,J.HitEvent>
  for +index:IDs.IdSet
  for coherent:{index == J.event_index(rows) : IDs.IdSet}
  {J.append_indexed(incoming,rows,index) == J.append_reverse(incoming,rows) : List<&2,J.HitEvent>}

# Guarantees: the seen-row ID projection is exactly its stored receipt ID.
# Why it matters: playback indexing cannot confuse event ticks with identity.
law seen_key_exact:
  for +id:String
  for tick:U32
  {J.seen_key(J.Seen{id,tick}) == id : String}
# Guarantees: no seen rows produce an empty exact-string index.
# Why it matters: first playback must not assume old receipts have played.
law seen_index_nil:
  {J.seen_index([]) == IDs.empty() : IDs.IdSet}
# Guarantees: canonical seen-index construction inserts the head after the tail index.
# Why it matters: marking a new receipt and updating the ephemeral index stay coherent.
law seen_index_cons:
  for +head:J.Seen
  for +tail:List<&2,J.Seen>
  {J.seen_index(head <> tail) == IDs.insert(J.seen_index(tail),J.seen_key(head)) : IDs.IdSet}
# Guarantees: every queried ID agrees between the seen index and ordinary seen membership.
# Why it matters: indexing cannot replay duplicates or suppress distinct contacts.
law seen_index_membership:
  for +seen:List<&2,J.Seen>
  for +id:String
  {IDs.contains(J.seen_index(seen),id) == J.seen_contains(seen,id) : Bool}
# Guarantees: indexed playback admits exactly the same due unseen receipts.
# Why it matters: the performance path must preserve early/future/duplicate decisions.
law indexed_play_admission:
  for +seen:List<&2,J.Seen>
  for +head:J.HitEvent
  for +tick:U32
  {Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(J.seen_index(seen),J.event_key(head)))) == Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(J.seen_contains(seen,J.event_key(head)))) : Bool}
# Guarantees: completed indexed playback retains newest512 seen IDs and FIFO output.
# Why it matters: the ephemeral index must not change output capacity or ordering.
law play_indexed_nil:
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for tick:U32
  for +acc:List<&2,J.HitEvent>
  for index:IDs.IdSet
  {J.play_indexed([],epoch,seen,tick,acc,index) == J.Played{J.Playback{epoch,List.take(&2,J.Seen,seen,512n)},List.reverse(&2,J.HitEvent,acc)} : J.Played}
# Guarantees: one due/unseen decision controls marking, output and index insertion together.
# Why it matters: future rows cannot poison deduplication and duplicates cannot emit twice.
law play_indexed_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for +tick:U32
  for +acc:List<&2,J.HitEvent>
  for +index:IDs.IdSet
  {J.play_indexed(head <> tail,epoch,seen,tick,acc,index) == J.play_indexed(tail,epoch,J.mark(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(index,J.event_key(head)))),seen,head),tick,J.keep_event(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(index,J.event_key(head)))),head,acc),J.indexed_insert(Bool.not(Bool.and(U32.is_le(J.event_tick(head),tick),Bool.not(IDs.contains(index,J.event_key(head))))),index,J.event_key(head))) : J.Played}
# Guarantees: indexed playback equals the original complete playback reference for arbitrary inputs.
# Why it matters: optimizing long-string membership must preserve the epoch, seen rows and emitted output.
law indexed_play_refines_reference:
  for +rows:List<&2,J.HitEvent>
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for +tick:U32
  for +acc:List<&2,J.HitEvent>
  {J.play_indexed(rows,epoch,seen,tick,acc,J.seen_index(seen)) == J.play_rows_go(rows,epoch,seen,tick,acc) : J.Played}
# Guarantees: any structurally coherent seen index yields the same complete playback reference.
# Why it matters: the law must constrain the actual carried index, not a disconnected proof copy.
law coherent_play_refinement:
  for +rows:List<&2,J.HitEvent>
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for +tick:U32
  for +acc:List<&2,J.HitEvent>
  for +index:IDs.IdSet
  for coherent:{index == J.seen_index(seen) : IDs.IdSet}
  {J.play_indexed(rows,epoch,seen,tick,acc,index) == J.play_rows_go(rows,epoch,seen,tick,acc) : J.Played}
# Guarantees: public playback builds a fresh ephemeral seen index once per fold.
# Why it matters: Playback keeps its existing ABI while eliminating repeated list scans.
law play_rows_indexed_entry:
  for +rows:List<&2,J.HitEvent>
  for +epoch:U32
  for +seen:List<&2,J.Seen>
  for +tick:U32
  {J.play_rows(rows,epoch,seen,tick) == J.play_indexed(rows,epoch,seen,tick,[],J.seen_index(seen)) : J.Played}
# Guarantees: empty input returns old rows without constructing an index.
# Why it matters: no-contact ticks must not pay for an unused membership structure.
law append_unique_indexed_empty:
  for +rows:List<&2,J.HitEvent>
  {J.append_unique([],rows) == rows : List<&2,J.HitEvent>}
# Guarantees: nonempty production ingestion uses the persistent indexed fold.
# Why it matters: a correct unused index cannot leave the quadratic reference path active.
law append_unique_indexed_nonempty:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +rows:List<&2,J.HitEvent>
  {J.append_unique(head <> tail,rows) == List.reverse(&2,J.HitEvent,J.append_indexed_start(head <> tail,List.reverse(&2,J.HitEvent,rows))) : List<&2,J.HitEvent>}
