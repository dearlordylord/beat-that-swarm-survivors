import Base
import ./coop-snapshot-receipts.bend as R
import ./coop-snapshot-flow.bend as F

# Guarantees: a receipt is at most 26 wire bytes; two queued slots budget 52.
# Why it matters: ACK traffic has an explicit small payload bound under delay.
law limits_exact:
  {R.max_frame_bytes() == 26 : U32} & {R.max_buffered_bytes() == 52 : U32}
# Guarantees: a fresh local connection has no received observation or native flight.
# Why it matters: reconnect must not reuse ACK backlog from the prior connection.
law fresh_exact:
  for +epoch:U32
  {R.fresh(epoch) == R.State{epoch,None{},False{},None{}} : R.State}
# Guarantees: the first accepted snapshot can establish any valid U32 identity.
# Why it matters: observation zero and unrelated host/local epoch numbers work.
law newer_first:
  for token:U32
  for observation:U32
  {R.newer(None{},token,observation) == True{} : Bool}
# Guarantees: later offers require the same host token and a strictly newer ID.
# Why it matters: stale/duplicate snapshots cannot replace the latest receipt.
law newer_existing:
  for +current:U32
  for +last:U32
  for +token:U32
  for +observation:U32
  {R.newer(Some{F.Receipt{current,last}},token,observation) == Bool.and(U32.is_eq(current,token),U32.is_gt(observation,last)) : Bool}
# Guarantees: admission compares against the newest received observation, not flight.
# Why it matters: coalescing must not regress while an older ACK is being written.
law offer_allowed_exact:
  for epoch:U32
  for +latest:Maybe<&2,F.Receipt>
  for pending:Bool
  for flight:Maybe<&2,F.Receipt>
  for +token:U32
  for +observation:U32
  {R.offer_allowed(R.State{epoch,latest,pending,flight},token,observation) == R.newer(latest,token,observation) : Bool}
# Guarantees: an accepted offer replaces only latest pending and preserves flight.
# Why it matters: a burst must coalesce without cancelling a native ACK write.
law offered_latest:
  for +epoch:U32
  for latest:Maybe<&2,F.Receipt>
  for pending:Bool
  for +flight:Maybe<&2,F.Receipt>
  for +token:U32
  for +observation:U32
  {R.offer_selected(True{},R.State{epoch,latest,pending,flight},token,observation) == R.State{epoch,Some{F.Receipt{token,observation}},True{},flight} : R.State}
# Guarantees: refused offers preserve all state.
# Why it matters: duplicates cannot enqueue another ACK or clear the current one.
law rejected_preserves:
  for +state:R.State
  for token:U32
  for observation:U32
  {R.offer_selected(False{},state,token,observation) == state : R.State}
# Guarantees: public offers use the high-watermark admission rule.
# Why it matters: callers cannot accidentally bypass receipt coalescing.
law offer_entry:
  for +state:R.State
  for +token:U32
  for +observation:U32
  {R.offer(state,token,observation) == R.offer_selected(R.offer_allowed(state,token,observation),state,token,observation) : R.State}
# Guarantees: a waiting latest receipt moves into the sole native flight.
# Why it matters: dispatch sends the newest actually offered ID without inventing one.
law prepare_waiting:
  for +epoch:U32
  for +receipt:F.Receipt
  {R.prepare(R.State{epoch,Some{receipt},True{},None{}}) == R.Prepared{R.State{epoch,Some{receipt},False{},Some{receipt}},Some{receipt}} : R.Prepared}
# Guarantees: an existing native write prevents a second dispatch.
# Why it matters: repeated timer callbacks cannot fill the transport send queue.
law prepare_busy:
  for +epoch:U32
  for +latest:Maybe<&2,F.Receipt>
  for +pending:Bool
  for +flight:F.Receipt
  {R.prepare(R.State{epoch,latest,pending,Some{flight}}) == R.Prepared{R.State{epoch,latest,pending,Some{flight}},None{}} : R.Prepared}
# Guarantees: a latest receipt already sent is not automatically sent again.
# Why it matters: ACK completion cannot cause an infinite immediate send loop.
law prepare_consumed:
  for +epoch:U32
  for +latest:Maybe<&2,F.Receipt>
  {R.prepare(R.State{epoch,latest,False{},None{}}) == R.Prepared{R.State{epoch,latest,False{},None{}},None{}} : R.Prepared}
# Guarantees: no received observation means no dispatch.
# Why it matters: polling before a snapshot cannot acknowledge an unreceived ID.
law prepare_empty:
  for +epoch:U32
  for +pending:Bool
  {R.prepare(R.State{epoch,None{},pending,None{}}) == R.Prepared{R.State{epoch,None{},pending,None{}},None{}} : R.Prepared}
# Guarantees: public dispatch applies readiness before moving pending to flight.
# Why it matters: a future adapter must keep the one-write boundary.
law prepare_entry:
  for +state:R.State
  {R.prepare(state) == R.prepare_selected(R.ready(state),state) : R.Prepared}
# Guarantees: callback matching requires local epoch, host token and observation.
# Why it matters: old callbacks cannot release a new connection's matching ID.
law matches_exact:
  for +current:U32
  for latest:Maybe<&2,F.Receipt>
  for pending:Bool
  for +host:U32
  for +flight:U32
  for +epoch:U32
  for +token:U32
  for +observation:U32
  {R.matches(R.State{current,latest,pending,Some{F.Receipt{host,flight}}},epoch,token,observation) == Bool.and(U32.is_eq(current,epoch),Bool.and(U32.is_eq(host,token),U32.is_eq(flight,observation))) : Bool}
# Guarantees: idle state cannot match any completion callback.
# Why it matters: a duplicate completion cannot consume newer pending work.
law matches_idle:
  for current:U32
  for latest:Maybe<&2,F.Receipt>
  for pending:Bool
  for epoch:U32
  for token:U32
  for observation:U32
  {R.matches(R.State{current,latest,pending,None{}},epoch,token,observation) == False{} : Bool}
# Guarantees: a matched callback clears only native flight.
# Why it matters: an ACK finishing must preserve a newer pending observation.
law complete_clears_flight:
  for +epoch:U32
  for +latest:Maybe<&2,F.Receipt>
  for +pending:Bool
  for flight:Maybe<&2,F.Receipt>
  {R.complete_selected(True{},R.State{epoch,latest,pending,flight}) == R.State{epoch,latest,pending,None{}} : R.State}
# Guarantees: unmatched callbacks cannot change any state.
# Why it matters: reconnect and delayed duplicate completion remain fenced.
law complete_stale:
  for +state:R.State
  {R.complete_selected(False{},state) == state : R.State}
# Guarantees: public completion applies the full three-part callback identity.
# Why it matters: local connection epoch is not interchangeable with host token.
law complete_entry:
  for +state:R.State
  for +epoch:U32
  for +token:U32
  for +observation:U32
  {R.complete(state,epoch,token,observation) == R.complete_selected(R.matches(state,epoch,token,observation),state) : R.State}
# Guarantees: an empty receipt slot consumes no queued payload capacity.
# Why it matters: diagnostics distinguish idle metadata from queued wire work.
law present_none:
  {R.present(None{}) == False{} : Bool}
# Guarantees: a populated receipt slot counts as one queued payload.
# Why it matters: a native flight cannot disappear from queue accounting.
law present_some:
  for receipt:F.Receipt
  {R.present(Some{receipt}) == True{} : Bool}
# Guarantees: capacity accounting counts one waiting receipt and one flight.
# Why it matters: many snapshots replace a slot rather than creating a queue.
law buffered_count_exact:
  for epoch:U32
  for +latest:Maybe<&2,F.Receipt>
  for +pending:Bool
  for +flight:Maybe<&2,F.Receipt>
  {R.buffered_count(R.State{epoch,latest,pending,flight}) == (Bool.to_u32(Bool.and(pending,R.present(latest))) + Bool.to_u32(R.present(flight)) : U32) : U32}
# Guarantees: the wire budget reserves 26 bytes per queued slot.
# Why it matters: the maximal pending-plus-flight payload is 52 bytes.
law buffered_bytes_exact:
  for +state:R.State
  {R.buffered_bytes(state) == (R.buffered_count(state) * 26 : U32) : U32}
# Guarantees: encoding preserves host token and the accepted observation ID.
# Why it matters: the cumulative ACK cannot name an invented future snapshot.
law encode_exact:
  for +token:U32
  for +observation:U32
  {R.encode(F.Receipt{token,observation}) == "BSA1|" ++ U32.show(token) ++ "|" ++ U32.show(observation) : String}
