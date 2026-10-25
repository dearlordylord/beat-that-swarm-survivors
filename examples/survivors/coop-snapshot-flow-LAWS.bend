import Base
import ./coop-snapshot-flow.bend as F
import ./coop-protocol.bend as Protocol

# Guarantees: at most sixteen sent snapshots may await application admission.
# Why it matters: a long RTT does not force stop-and-wait, but cannot create unlimited stale work.
law window_exact:
  {F.window() == 16n : Nat}
# Guarantees: a new token starts with no pending, writing or sent observations.
# Why it matters: rejoin cannot inherit a previous guest backlog.
law fresh_exact:
  for +token:U32
  {F.fresh(token) == F.State{token,None{},None{},[],0,False{}} : F.State}
# Guarantees: only first or strictly newer offers replace pending.
# Why it matters: delayed duplicates cannot roll back waiting authority.
law offer_allowed_exact:
  for +token:U32
  for +pending:Maybe<&2,U32>
  for +writing:Maybe<&2,U32>
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  for +observation:U32
  {F.offer_allowed(F.State{token,pending,writing,flights,last,offered},observation) == Bool.or(Bool.not(offered),U32.is_gt(observation,last)) : Bool}
# Guarantees: an accepted offer replaces pending only and preserves both flight lanes.
# Why it matters: coalescing cannot pretend native or application completion.
law offered_replaces_pending:
  for +token:U32
  for +pending:Maybe<&2,U32>
  for +writing:Maybe<&2,U32>
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  for +observation:U32
  {F.offer_selected(True{},F.State{token,pending,writing,flights,last,offered},observation) == F.State{token,Some{observation},writing,flights,observation,True{}} : F.State}
# Guarantees: a rejected offer changes nothing.
# Why it matters: duplicates must preserve the current bounded window.
law rejected_offer_preserves:
  for +state:F.State
  for observation:U32
  {F.offer_selected(False{},state,observation) == state : F.State}
# Guarantees: public offers use exact admission and replacement.
# Why it matters: the browser delegates snapshot admission to this model.
law offer_wiring:
  for +state:F.State
  for +observation:U32
  {F.offer(state,observation) == F.offer_selected(F.offer_allowed(state,observation),state,observation) : F.State}
# Guarantees: idle native writes admit pending only below the sixteen-snapshot window.
# Why it matters: a full application window must stop dispatch while retaining latest pending.
law ready_available:
  for +token:U32
  for +observation:U32
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  {F.ready(F.State{token,Some{observation},None{},flights,last,offered}) == Nat.is_lt(List.length(&2,U32,flights),16n) : Bool}
# Guarantees: an outstanding native write always blocks another write.
# Why it matters: application ACK arriving early cannot overlap native writers.
law ready_writing:
  for +token:U32
  for +pending:Maybe<&2,U32>
  for +writing:U32
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  {F.ready(F.State{token,pending,Some{writing},flights,last,offered}) == False{} : Bool}
# Guarantees: no pending observation means no dispatch.
# Why it matters: idle polling cannot manufacture snapshots.
law ready_empty:
  for +token:U32
  for +writing:Maybe<&2,U32>
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  {F.ready(F.State{token,None{},writing,flights,last,offered}) == False{} : Bool}
# Guarantees: dispatch consumes pending and records the same ID in both flight lanes.
# Why it matters: a sent snapshot must remain accounted until application receipt.
law prepare_waiting:
  for +token:U32
  for +observation:U32
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  {F.prepare_selected(True{},F.State{token,Some{observation},None{},flights,last,offered}) == F.Prepared{F.State{token,None{},Some{observation},F.flight_rows(flights,observation),last,offered},Some{observation}} : F.Prepared}
# Guarantees: refused dispatch preserves every state field.
# Why it matters: backpressure cannot drop the latest observation.
law prepare_refused:
  for +state:F.State
  {F.prepare_selected(False{},state) == F.Prepared{state,None{}} : F.Prepared}
# Guarantees: public dispatch follows both capacity and native-write admission.
# Why it matters: a helper alone cannot guarantee the production entry point is bounded.
law prepare_wiring:
  for +state:F.State
  {F.prepare(state) == F.prepare_selected(F.ready(state),state) : F.Prepared}
# Guarantees: native completion matches both token and native observation.
# Why it matters: stale promises cannot clear a new writer.
law writing_matches_exact:
  for +token:U32
  for +pending:Maybe<&2,U32>
  for +writing:U32
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  for +other:U32
  for +observation:U32
  {F.writing_matches(F.State{token,pending,Some{writing},flights,last,offered},other,observation) == Bool.and(U32.is_eq(token,other),U32.is_eq(writing,observation)) : Bool}
# Guarantees: an idle native lane has no matching completion.
# Why it matters: an unsolicited completion cannot modify waiting work.
law writing_matches_idle:
  for +token:U32
  for +pending:Maybe<&2,U32>
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  for other:U32
  for observation:U32
  {F.writing_matches(F.State{token,pending,None{},flights,last,offered},other,observation) == False{} : Bool}
# Guarantees: native completion clears only writing and retains every unacknowledged snapshot.
# Why it matters: QUIC completion cannot masquerade as guest adoption.
law complete_only_native:
  for +token:U32
  for +pending:Maybe<&2,U32>
  for +writing:Maybe<&2,U32>
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  {F.complete_selected(True{},F.State{token,pending,writing,flights,last,offered}) == F.State{token,pending,None{},flights,last,offered} : F.State}
# Guarantees: a nonmatching native completion changes nothing.
# Why it matters: reconnect fences delayed transport callbacks.
law complete_refused:
  for +state:F.State
  {F.complete_selected(False{},state) == state : F.State}
# Guarantees: public native completion uses exact native identity matching.
# Why it matters: the host cannot release a write based only on an application ACK.
law complete_wiring:
  for +state:F.State
  for +token:U32
  for +observation:U32
  {F.complete(state,token,observation) == F.complete_selected(F.writing_matches(state,token,observation),state) : F.State}
# Guarantees: an empty sent window contains no receipt identity.
# Why it matters: future or unsolicited ACKs cannot release capacity.
law contains_nil:
  for observation:U32
  {F.contains([],observation) == False{} : Bool}
# Guarantees: membership checks the exact identities of every outstanding snapshot.
# Why it matters: an ACK for a skipped unsent observation must not release the window.
law contains_cons:
  for +head:U32
  for +tail:List<&2,U32>
  for +observation:U32
  {F.contains(head <> tail,observation) == Bool.or(U32.is_eq(head,observation),F.contains(tail,observation)) : Bool}
# Guarantees: application ACK requires this connection token and an exact sent member.
# Why it matters: same-token future ACKs cannot acknowledge unsent snapshots.
law matches_exact:
  for +token:U32
  for +pending:Maybe<&2,U32>
  for +writing:Maybe<&2,U32>
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  for +other:U32
  for +observation:U32
  {F.matches(F.State{token,pending,writing,flights,last,offered},other,observation) == Bool.and(U32.is_eq(token,other),F.contains(flights,observation)) : Bool}
# Guarantees: retaining a newer sent identity preserves the row.
# Why it matters: cumulative ACK cannot discard later flights.
law keep_flight_true:
  for +observation:U32
  for +rows:List<&2,U32>
  {F.keep_flight(True{},observation,rows) == observation <> rows : List<&2,U32>}
# Guarantees: acknowledged identities are removed.
# Why it matters: successful receipts must actually free bounded window capacity.
law keep_flight_false:
  for observation:U32
  for +rows:List<&2,U32>
  {F.keep_flight(False{},observation,rows) == rows : List<&2,U32>}
# Guarantees: filtering an empty sent window stays empty.
# Why it matters: receipt handling cannot invent flight identities.
law unacknowledged_nil:
  for observation:U32
  {F.unacknowledged([],observation) == [] : List<&2,U32>}
# Guarantees: cumulative receipt retains exactly IDs above the admitted observation.
# Why it matters: delayed earlier ACKs cannot resurrect or remove newer work.
law unacknowledged_cons:
  for +head:U32
  for +tail:List<&2,U32>
  for +observation:U32
  {F.unacknowledged(head <> tail,observation) == F.keep_flight(U32.is_gt(head,observation),head,F.unacknowledged(tail,observation)) : List<&2,U32>}
# Guarantees: matched ACK removes cumulative sent IDs while preserving native writing and pending.
# Why it matters: ACK-before-completion cannot permit overlapping native writes.
law ack_cumulative_only:
  for +token:U32
  for +pending:Maybe<&2,U32>
  for +writing:Maybe<&2,U32>
  for +flights:List<&2,U32>
  for +last:U32
  for +offered:Bool
  for +observation:U32
  {F.ack_selected(True{},F.State{token,pending,writing,flights,last,offered},observation) == F.State{token,pending,writing,F.unacknowledged(flights,observation),last,offered} : F.State}
# Guarantees: a nonmatching application receipt changes nothing.
# Why it matters: stale, skipped and future ACKs cannot free snapshot capacity.
law unmatched_ack_preserves:
  for +state:F.State
  for observation:U32
  {F.ack_selected(False{},state,observation) == state : F.State}
# Guarantees: public acknowledgement applies exact membership and cumulative policy.
# Why it matters: the browser uses the same bounded transition that the laws pin.
law ack_wiring:
  for +state:F.State
  for +token:U32
  for +observation:U32
  {F.ack(state,token,observation) == F.ack_selected(F.matches(state,token,observation),state,observation) : F.State}
# Guarantees: canonical receipt wire text carries its token and observation.
# Why it matters: the host must know exactly which admitted snapshot was seen.
law encode_exact:
  for +token:U32
  for +observation:U32
  {F.encode_receipt(token,observation) == "BSA1|" ++ U32.show(token) ++ "|" ++ U32.show(observation) : String}
# Guarantees: decoder admission is limited to the maximal canonical frame length.
# Why it matters: no unbounded parse work is done for incoming receipt text.
law decode_entry_exact:
  for +text:String
  {F.decode_receipt(text) == F.decode_bounded(Nat.is_le(String.length(text),26n),text) : Maybe<&2,F.Receipt>}
# Guarantees: an overlong receipt is rejected before field parsing.
# Why it matters: a peer cannot spend unbounded work on the receipt path.
law decode_refused:
  for text:String
  {F.decode_bounded(False{},text) == None{} : Maybe<&2,F.Receipt>}
# Guarantees: bounded receipt text uses the shared canonical-number parser.
# Why it matters: malformed digits cannot be silently coerced to another epoch.
law decode_allowed:
  for +text:String
  {F.decode_bounded(True{},text) == F.decode_fields(Protocol.fields(text,"")) : Maybe<&2,F.Receipt>}
# Guarantees: the three receipt fields decode through canonical U32 parsers.
# Why it matters: a decoder that always refuses cannot satisfy valid receipts.
law decode_fields_exact:
  for +token:String
  for +observation:String
  {F.decode_fields(["BSA1",token,observation]) == (do Maybe<&2,F.Receipt>:
    t : U32 <- Protocol.number(token)
    o : U32 <- Protocol.number(observation)
    return F.Receipt{t,o}) : Maybe<&2,F.Receipt>}

# Guarantees: dispatch appends one ID and mechanically caps the result at sixteen.
# Why it matters: even a direct helper caller cannot create an unbounded window.
law flight_rows_exact:
  for +rows:List<&2,U32>
  for +observation:U32
  {F.flight_rows(rows,observation) == List.take(&2,U32,List.append(&2,U32,rows,[observation]),16n) : List<&2,U32>}
# Guarantees: sent-ID storage is at most sixteen for every append input.
# Why it matters: the dispatch bound is universal, not just a tested queue size.
law flight_rows_bounded:
  for +rows:List<&2,U32>
  for +observation:U32
  {Nat.is_le(List.length(&2,U32,F.flight_rows(rows,observation)),16n) == True{} : Bool}
def flight_count(state:F.State) -> Nat:
  match state:
    case F.State{_,_,_,flights,_,_}: List.length(&2,U32,flights)
def prepared_count(value:F.Prepared) -> Nat:
  match value:
    case F.Prepared{state,_}: flight_count(state)
# Guarantees: every dispatch branch preserves the sixteen-ID invariant.
# Why it matters: fresh plus repeated dispatches cannot accumulate obsolete work.
law selected_prepare_preserves_bound:
  for +allowed:Bool
  for +state:F.State
  for bound:{Nat.is_le(flight_count(state),16n) == True{} : Bool}
  {Nat.is_le(prepared_count(F.prepare_selected(allowed,state)),16n) == True{} : Bool}
# Guarantees: public dispatch preserves bounded sent-ID storage.
# Why it matters: the browser's real entry point inherits the window bound.
law public_prepare_preserves_bound:
  for +state:F.State
  for bound:{Nat.is_le(flight_count(state),16n) == True{} : Bool}
  {Nat.is_le(prepared_count(F.prepare(state)),16n) == True{} : Bool}
# Guarantees: cumulative filtering never grows any input sent-ID list.
# Why it matters: receiving a receipt cannot break the resource invariant.
law cumulative_filter_never_grows:
  for +rows:List<&2,U32>
  for +observation:U32
  {Nat.is_le(List.length(&2,U32,F.unacknowledged(rows,observation)),List.length(&2,U32,rows)) == True{} : Bool}
# Guarantees: offering a new latest snapshot preserves bounded sent storage.
# Why it matters: high publication rate cannot grow the unacknowledged window.
law public_offer_preserves_bound:
  for +state:F.State
  for +observation:U32
  for bound:{Nat.is_le(flight_count(state),16n) == True{} : Bool}
  {Nat.is_le(flight_count(F.offer(state,observation)),16n) == True{} : Bool}
# Guarantees: native completion preserves bounded application sent storage.
# Why it matters: send callbacks cannot corrupt the application resource invariant.
law public_complete_preserves_bound:
  for +state:F.State
  for +token:U32
  for +observation:U32
  for bound:{Nat.is_le(flight_count(state),16n) == True{} : Bool}
  {Nat.is_le(flight_count(F.complete(state,token,observation)),16n) == True{} : Bool}
# Guarantees: cumulative application acknowledgement preserves the sixteen-ID bound.
# Why it matters: fresh plus every exported state transition stays bounded.
law public_ack_preserves_bound:
  for +state:F.State
  for +token:U32
  for +observation:U32
  for bound:{Nat.is_le(flight_count(state),16n) == True{} : Bool}
  {Nat.is_le(flight_count(F.ack(state,token,observation)),16n) == True{} : Bool}
# Guarantees: a fresh connection establishes the sent-ID invariant.
# Why it matters: preservation laws apply to every reachable connection history.
law fresh_establishes_bound:
  for +token:U32
  {Nat.is_le(flight_count(F.fresh(token)),16n) == True{} : Bool}
