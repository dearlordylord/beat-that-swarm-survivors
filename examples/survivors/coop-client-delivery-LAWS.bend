import Base
import ./coop-client-delivery.bend as D
import ./coop-input-flow.bend as I
import ./coop-snapshot-receipts.bend as R
import ./coop-snapshot-flow.bend as F
import ./coop-session.bend as S

# Guarantees: the composite frame uses a fixed5190-byte ASCII budget.
# Why it matters: host admission includes the input batch and piggyback receipt.
law limits_exact:
  {D.max_frame_bytes() == 5190 : U32}
# Guarantees: reset creates both child journals with the same connection epoch.
# Why it matters: a rejoin cannot inherit a previous native packet.
law fresh_exact:
  for +epoch:U32
  {D.fresh(epoch) == D.State{epoch,0,I.fresh(epoch),R.fresh(epoch),None{},False{}} : D.State}
# Guarantees: input admission preserves receipt and native-flight state.
# Why it matters: accepting movement cannot erase a pending snapshot acknowledgement.
law admitted_exact:
  for +epoch:U32
  for +next:U32
  for +receipts:R.State
  for +flight:Maybe<&2,D.Packet>
  for +failed:Bool
  for +input:I.State
  for +accepted:Bool
  {D.admitted(epoch,next,receipts,flight,failed,I.Admission{input,accepted}) == D.Admission{D.State{epoch,next,input,receipts,flight,failed},accepted} : D.Admission}
# Guarantees: refused enqueue returns the complete unchanged state.
# Why it matters: failed delivery cannot accept unsent speculative input.
law enqueue_refused:
  for +state:D.State
  for +command:S.Command
  {D.enqueue_selected(False{},state,command) == D.Admission{state,False{}} : D.Admission}
# Guarantees: admitted enqueue uses the existing bounded input journal.
# Why it matters: piggybacking must not change command fields or capacity rules.
law enqueue_allowed:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +flight:Maybe<&2,D.Packet>
  for +failed:Bool
  for +command:S.Command
  {D.enqueue_selected(True{},D.State{epoch,next,input,receipts,flight,failed},command) == D.admitted(epoch,next,receipts,flight,failed,I.enqueue(input,command)) : D.Admission}
# Guarantees: the public enqueue fences failed connections before child admission.
# Why it matters: an ACK-only write failure must also stop new movement.
law enqueue_wiring:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +flight:Maybe<&2,D.Packet>
  for +failed:Bool
  for +command:S.Command
  {D.enqueue(D.State{epoch,next,input,receipts,flight,failed},command) == D.enqueue_selected(Bool.not(failed),D.State{epoch,next,input,receipts,flight,failed},command) : D.Admission}
# Guarantees: refused receipt offers preserve all state.
# Why it matters: failure cannot reopen the client lane.
law offer_refused:
  for +state:D.State
  for +token:U32
  for +observation:U32
  {D.offer_selected(False{},state,token,observation) == state : D.State}
# Guarantees: receipt offers coalesce only the receipt child.
# Why it matters: new snapshots cannot discard retained guest input.
law offer_allowed:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +flight:Maybe<&2,D.Packet>
  for +failed:Bool
  for +token:U32
  for +observation:U32
  {D.offer_selected(True{},D.State{epoch,next,input,receipts,flight,failed},token,observation) == D.State{epoch,next,input,R.offer(receipts,token,observation),flight,failed} : D.State}
# Guarantees: public receipt offers stop after a shared delivery failure.
# Why it matters: ACK-only traffic cannot bypass the failed connection fence.
law offer_wiring:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +flight:Maybe<&2,D.Packet>
  for +failed:Bool
  for +token:U32
  for +observation:U32
  {D.offer_receipt(D.State{epoch,next,input,receipts,flight,failed},token,observation) == D.offer_selected(Bool.not(failed),D.State{epoch,next,input,receipts,flight,failed},token,observation) : D.State}
# Guarantees: dispatch requires a free shared writer, identifier space and at least one ready child.
# Why it matters: input and ACK are one packet rather than competing native writes.
law ready_idle:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  {D.ready(D.State{epoch,next,input,receipts,None{},False{}}) == Bool.and(U32.is_lt(next,4294967295),Bool.or(I.ready(input),R.ready(receipts))) : Bool}
# Guarantees: an outstanding shared packet blocks all other dispatch.
# Why it matters: later input or ACK cannot start a second native writer.
law ready_busy:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +packet:D.Packet
  for +failed:Bool
  {D.ready(D.State{epoch,next,input,receipts,Some{packet},failed}) == False{} : Bool}
# Guarantees: failed delivery cannot dispatch either child.
# Why it matters: a failing ACK-only packet cannot leave an active send path.
law ready_failed:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +flight:Maybe<&2,D.Packet>
  {D.ready(D.State{epoch,next,input,receipts,flight,True{}}) == False{} : Bool}
# Guarantees: an absent input batch is not sendable work.
# Why it matters: an idle poll cannot manufacture an empty packet.
law batch_absent:
  {D.batch_present(None{}) == False{} : Bool}
# Guarantees: a prepared input batch counts as sendable work.
# Why it matters: movement alone can be sent without waiting for a snapshot.
law batch_present:
  for +batch:I.Batch
  {D.batch_present(Some{batch}) == True{} : Bool}
# Guarantees: empty work creates neither packet nor shared flight.
# Why it matters: both children being idle must not spend a packet ID.
law combined_empty:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +batch:Maybe<&2,I.Batch>
  for +receipt:Maybe<&2,F.Receipt>
  {D.combined(False{},epoch,next,input,receipts,batch,receipt) == D.Prepared{D.State{epoch,next,input,receipts,None{},False{}},None{}} : D.Prepared}
# Guarantees: one packet stores both child reservations under one shared identity.
# Why it matters: the native callback must complete the exact children actually sent.
law combined_present:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +batch:Maybe<&2,I.Batch>
  for +receipt:Maybe<&2,F.Receipt>
  {D.combined(True{},epoch,next,input,receipts,batch,receipt) == D.Prepared{D.State{epoch,(next + 1 : U32),input,receipts,Some{D.Packet{epoch,(next + 1 : U32),batch,receipt}},False{}},Some{D.Packet{epoch,(next + 1 : U32),batch,receipt}}} : D.Prepared}
# Guarantees: both prepared children enter the same combined packet decision.
# Why it matters: an available ACK or input batch cannot disappear during composition.
law prepared_children_exact:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +batch:Maybe<&2,I.Batch>
  for +receipt:Maybe<&2,F.Receipt>
  {D.prepared_children(epoch,next,I.Prepared{input,batch},R.Prepared{receipts,receipt}) == D.combined(Bool.or(D.batch_present(batch),R.present(receipt)),epoch,next,input,receipts,batch,receipt) : D.Prepared}
# Guarantees: a busy or failed prepare preserves both journals and writer.
# Why it matters: checking availability cannot consume child work.
law prepare_refused:
  for +state:D.State
  {D.prepare_selected(False{},state) == D.Prepared{state,None{}} : D.Prepared}
# Guarantees: dispatch reserves both ready child lanes before encoding.
# Why it matters: an ACK cannot be sent separately ahead of the input batch.
law prepare_allowed:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  {D.prepare_selected(True{},D.State{epoch,next,input,receipts,None{},False{}}) == D.prepared_children(epoch,next,I.prepare(input),R.prepare(receipts)) : D.Prepared}
# Guarantees: public preparation uses the shared writer admission rule.
# Why it matters: the caller cannot bypass one-native-write ownership.
law prepare_wiring:
  for +state:D.State
  {D.prepare(state) == D.prepare_selected(D.ready(state),state) : D.Prepared}
# Guarantees: native callbacks require the shared epoch, stored packet epoch and packet ID.
# Why it matters: stale completion cannot clear a replacement connection.
law matches_exact:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +packetEpoch:U32
  for +id:U32
  for +batch:Maybe<&2,I.Batch>
  for +receipt:Maybe<&2,F.Receipt>
  for +callbackEpoch:U32
  for +callbackId:U32
  {D.matches(D.State{epoch,next,input,receipts,Some{D.Packet{packetEpoch,id,batch,receipt}},False{}},callbackEpoch,callbackId) == Bool.and(U32.is_eq(epoch,callbackEpoch),Bool.and(U32.is_eq(packetEpoch,callbackEpoch),U32.is_eq(id,callbackId))) : Bool}
# Guarantees: an idle shared writer has no matching callback.
# Why it matters: unsolicited completion cannot drain child journals.
law matches_idle:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +failed:Bool
  for +callbackEpoch:U32
  for +callbackId:U32
  {D.matches(D.State{epoch,next,input,receipts,None{},failed},callbackEpoch,callbackId) == False{} : Bool}
# Guarantees: failed state refuses every late success or failure callback.
# Why it matters: late success cannot revive a failed lane.
law matches_failed:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +flight:Maybe<&2,D.Packet>
  for +callbackEpoch:U32
  for +callbackId:U32
  {D.matches(D.State{epoch,next,input,receipts,flight,True{}},callbackEpoch,callbackId) == False{} : Bool}
# Guarantees: ACK-only completion leaves the input journal intact.
# Why it matters: unrelated pending movement must not be consumed.
law completed_input_absent:
  for +input:I.State
  {D.completed_input(None{},input) == input : I.State}
# Guarantees: input completion uses the stored child batch identity.
# Why it matters: a newer pending batch must not be mistaken for the sent one.
law completed_input_stored:
  for +epoch:U32
  for +id:U32
  for +commands:List<&2,S.Command>
  for +input:I.State
  {D.completed_input(Some{I.Batch{epoch,id,commands}},input) == I.complete(input,epoch,id) : I.State}
# Guarantees: input-only completion leaves receipts intact.
# Why it matters: movement transmission must not acknowledge an unsent host snapshot.
law completed_receipt_absent:
  for +receipts:R.State
  for +epoch:U32
  {D.completed_receipt(None{},receipts,epoch) == receipts : R.State}
# Guarantees: receipt completion uses the stored token and observation.
# Why it matters: a later offered receipt remains pending after the old write completes.
law completed_receipt_stored:
  for +token:U32
  for +observation:U32
  for +receipts:R.State
  for +epoch:U32
  {D.completed_receipt(Some{F.Receipt{token,observation}},receipts,epoch) == R.complete(receipts,epoch,token,observation) : R.State}
# Guarantees: matching completion finishes both stored children and only then clears the shared writer.
# Why it matters: piggyback completion must preserve newer pending work in both lanes.
law complete_stored_packet:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +packetEpoch:U32
  for +id:U32
  for +batch:Maybe<&2,I.Batch>
  for +receipt:Maybe<&2,F.Receipt>
  for +failed:Bool
  {D.complete_selected(True{},D.State{epoch,next,input,receipts,Some{D.Packet{packetEpoch,id,batch,receipt}},failed}) == D.State{epoch,next,D.completed_input(batch,input),D.completed_receipt(receipt,receipts,epoch),None{},failed} : D.State}
# Guarantees: a nonmatching shared completion changes nothing.
# Why it matters: old writes cannot drain a current journal.
law complete_refused:
  for +state:D.State
  {D.complete_selected(False{},state) == state : D.State}
# Guarantees: public completion uses shared identity matching.
# Why it matters: callbacks are not authorized merely because a child has work.
law complete_wiring:
  for +state:D.State
  for +epoch:U32
  for +id:U32
  {D.complete(state,epoch,id) == D.complete_selected(D.matches(state,epoch,id),state) : D.State}
# Guarantees: ACK-only failure does not discard input records.
# Why it matters: the shared failure fence must retain pending movement for diagnostics.
law failed_input_absent:
  for +input:I.State
  {D.failed_input(None{},input) == input : I.State}
# Guarantees: input failure fences its stored batch identity.
# Why it matters: a newer pending input cannot be reported as the failed transmission.
law failed_input_stored:
  for +epoch:U32
  for +id:U32
  for +commands:List<&2,S.Command>
  for +input:I.State
  {D.failed_input(Some{I.Batch{epoch,id,commands}},input) == I.fail(input,epoch,id) : I.State}
# Guarantees: an absent packet has no child input failure.
# Why it matters: failure handling cannot invent a failed command batch.
law failed_packet_absent:
  for +input:I.State
  {D.failed_input_packet(None{},input) == input : I.State}
# Guarantees: the packet chooses the failed input child.
# Why it matters: ACK fields cannot change which input journal is fenced.
law failed_packet_stored:
  for +epoch:U32
  for +id:U32
  for +batch:Maybe<&2,I.Batch>
  for +receipt:Maybe<&2,F.Receipt>
  for +input:I.State
  {D.failed_input_packet(Some{D.Packet{epoch,id,batch,receipt}},input) == D.failed_input(batch,input) : I.State}
# Guarantees: failure fences the shared lane and retains receipt and packet history.
# Why it matters: nothing silently retries or discards accepted input after a send failure.
law fail_fences_retains:
  for +epoch:U32
  for +next:U32
  for +input:I.State
  for +receipts:R.State
  for +flight:Maybe<&2,D.Packet>
  for +failed:Bool
  {D.fail_selected(True{},D.State{epoch,next,input,receipts,flight,failed}) == D.State{epoch,next,D.failed_input_packet(flight,input),receipts,flight,True{}} : D.State}
# Guarantees: unmatched failures preserve every state field.
# Why it matters: stale network errors cannot poison a new connection.
law fail_refused:
  for +state:D.State
  {D.fail_selected(False{},state) == state : D.State}
# Guarantees: public failure checks exact shared callback identity.
# Why it matters: a stale promise rejection cannot close an unrelated packet lane.
law fail_wiring:
  for +state:D.State
  for +epoch:U32
  for +id:U32
  {D.fail(state,epoch,id) == D.fail_selected(D.matches(state,epoch,id),state) : D.State}
# Guarantees: one ASCII frame carries both reserved child payloads.
# Why it matters: combining writes must not drop either child.
law encode_exact:
  for +epoch:U32
  for +id:U32
  for +batch:Maybe<&2,I.Batch>
  for +receipt:Maybe<&2,F.Receipt>
  {D.encode(D.Packet{epoch,id,batch,receipt}) == "BSC1\n" ++ D.encoded_receipt(receipt) ++ "\n" ++ D.encoded_batch(batch) : String}
# Guarantees: missing input has an explicit empty marker.
# Why it matters: the packet decoder can distinguish absence from malformed commands.
law encoded_batch_absent:
  {D.encoded_batch(None{}) == "-" : String}
# Guarantees: batch encoding delegates to the exact existing command codec.
# Why it matters: all command timestamps and fields survive composition.
law encoded_batch_present:
  for +batch:I.Batch
  {D.encoded_batch(Some{batch}) == I.encode(batch) : String}
# Guarantees: missing receipt has an explicit empty marker.
# Why it matters: input-only packets remain unambiguous.
law encoded_receipt_absent:
  {D.encoded_receipt(None{}) == "-" : String}
# Guarantees: receipt text retains its host token and observation.
# Why it matters: a cumulative ACK cannot move to another host epoch.
law encoded_receipt_present:
  for +token:U32
  for +observation:U32
  {D.encoded_receipt(Some{F.Receipt{token,observation}}) == F.encode_receipt(token,observation) : String}
# Guarantees: the empty marker parses as successful absence.
# Why it matters: input-only packets must remain valid.
law receipt_field_absent:
  {D.receipt_field("-") == Some{None{}} : Maybe<&2,Maybe<&2,F.Receipt>>}
# Guarantees: a packet is admitted only after both child parses succeed.
# Why it matters: host receipt processing cannot precede validation of a malformed batch.
law assembled_success:
  for +receipt:Maybe<&2,F.Receipt>
  for +commands:List<&2,S.Command>
  {D.assembled(Some{receipt},Some{commands}) == Some{D.Payload{receipt,commands}} : Maybe<&2,D.Payload>}
# Guarantees: bad receipt parsing refuses the entire packet.
# Why it matters: a valid command suffix must not bypass a malformed receipt.
law assembled_bad_receipt:
  for +commands:Maybe<&2,List<&2,S.Command>>
  {D.assembled(None{},commands) == None{} : Maybe<&2,D.Payload>}
# Guarantees: bad command parsing refuses the entire packet.
# Why it matters: a valid ACK prefix must not free the host window before batch validation.
law assembled_bad_commands:
  for +receipt:Maybe<&2,Maybe<&2,F.Receipt>>
  {D.assembled(receipt,None{}) == None{} : Maybe<&2,D.Payload>}
# Guarantees: empty command rows reconstruct empty text.
# Why it matters: missing payload text cannot be invented.
law join_lines_empty:
  {D.join_lines([]) == "" : String}
# Guarantees: one row is reconstructed without an added separator.
# Why it matters: legacy command spelling remains unchanged.
law join_lines_single:
  for +head:String
  {D.join_lines([head]) == head : String}
# Guarantees: multiple rows retain their newline boundaries and order.
# Why it matters: batch reconstruction cannot merge or reorder commands.
law join_lines_cons:
  for +head:String
  for +next:String
  for +tail:List<&2,String>
  {D.join_lines(head <> next <> tail) == head ++ "\n" ++ D.join_lines(next <> tail) : String}
# Guarantees: the empty command marker yields no commands.
# Why it matters: ACK-only packets must not require a fabricated input.
law command_field_absent:
  {D.command_field(["-"]) == Some{[]} : Maybe<&2,List<&2,S.Command>>}
# Guarantees: immediate commands use the same composite and batch framing.
# Why it matters: Setup and host-local actions cannot require a legacy decoder.
law encode_command_exact:
  for +command:S.Command
  {D.encode_command(command) == "BSC1\n-\n" ++ I.encode_commands([command]) : String}
# Guarantees: recognized composite frames parse both children before returning a payload.
# Why it matters: a bad batch must not partially acknowledge a host snapshot.
law decode_packet_lines:
  for +receipt:String
  for +commands:List<&2,String>
  {D.decode_lines("BSC1" <> receipt <> commands) == D.assembled(D.receipt_field(receipt),D.command_field(commands)) : Maybe<&2,D.Payload>}
# Guarantees: over-budget text is refused before parsing.
# Why it matters: composite framing cannot permit unbounded host parse work.
law decode_refused:
  for +text:String
  {D.decode_selected(False{},text) == None{} : Maybe<&2,D.Payload>}
# Guarantees: bounded decoding preserves line structure.
# Why it matters: the composite header cannot bypass atomic child admission.
law decode_allowed:
  for +text:String
  {D.decode_selected(True{},text) == D.decode_lines(I.lines(text,"")) : Maybe<&2,D.Payload>}
# Guarantees: the public decoder applies the composite budget.
# Why it matters: host and worker can share the same complete parse boundary.
law decode_entry:
  for +text:String
  {D.decode(text) == D.decode_selected(Nat.is_le(String.length(text),5190n),text) : Maybe<&2,D.Payload>}
# Guarantees: a malformed receipt stays a parse failure.
# Why it matters: invalid ACK text must not become successful absence.
law parsed_receipt_none:
  {D.parsed_receipt(None{}) == None{} : Maybe<&2,Maybe<&2,F.Receipt>>}
# Guarantees: a decoded receipt is retained exactly.
# Why it matters: receipt parsing cannot silently drop a valid host acknowledgement.
law parsed_receipt_some:
  for +receipt:F.Receipt
  {D.parsed_receipt(Some{receipt}) == Some{Some{receipt}} : Maybe<&2,Maybe<&2,F.Receipt>>}
# Guarantees: the explicit absent branch succeeds without receipt data.
# Why it matters: input-only packets are supported without a fake ACK.
law receipt_selected_absent:
  for +text:String
  {D.receipt_selected(True{},text) == Some{None{}} : Maybe<&2,Maybe<&2,F.Receipt>>}
# Guarantees: nonempty receipt text uses the bounded receipt decoder.
# Why it matters: malformed tokens cannot bypass atomic packet validation.
law receipt_selected_present:
  for +text:String
  {D.receipt_selected(False{},text) == D.parsed_receipt(F.decode_receipt(text)) : Maybe<&2,Maybe<&2,F.Receipt>>}
# Guarantees: only the exact empty marker skips receipt parsing.
# Why it matters: other malformed receipt text is not silently ignored.
law receipt_field_entry:
  for +text:String
  {D.receipt_field(text) == D.receipt_selected(String.eq(text,"-"),text) : Maybe<&2,Maybe<&2,F.Receipt>>}
# Guarantees: missing command rows are not the explicit empty marker.
# Why it matters: truncated composite packets must fail validation.
law empty_marker_nil:
  {D.empty_marker([]) == False{} : Bool}
# Guarantees: a single command row is empty only when exactly a dash.
# Why it matters: invalid batch text cannot become an ACK-only packet.
law empty_marker_single:
  for +text:String
  {D.empty_marker([text]) == String.eq(text,"-") : Bool}
# Guarantees: multiple command rows always require batch decoding.
# Why it matters: a leading dash cannot hide a malformed suffix.
law empty_marker_multi:
  for +head:String
  for +next:String
  for +tail:List<&2,String>
  {D.empty_marker(head <> next <> tail) == False{} : Bool}
# Guarantees: the absence branch emits no commands.
# Why it matters: ACK-only packets must not fabricate movement.
law command_selected_absent:
  for +rows:List<&2,String>
  {D.command_selected(True{},rows) == Some{[]} : Maybe<&2,List<&2,S.Command>>}
# Guarantees: all batch text passes through the existing atomic input parser.
# Why it matters: a malformed middle command must reject the whole packet.
law command_selected_present:
  for +rows:List<&2,String>
  {D.command_selected(False{},rows) == I.decode(D.join_lines(rows)) : Maybe<&2,List<&2,S.Command>>}
# Guarantees: command parsing uses the exact empty-marker classification.
# Why it matters: receipt processing cannot skip a nonempty invalid batch.
law command_field_entry:
  for +rows:List<&2,String>
  {D.command_field(rows) == D.command_selected(D.empty_marker(rows),rows) : Maybe<&2,List<&2,S.Command>>}
# Guarantees: an empty frame has no composite header.
# Why it matters: empty input must not be admitted as a packet.
law composite_nil:
  {D.composite([]) == False{} : Bool}
# Guarantees: one line is not a complete composite header plus receipt.
# Why it matters: truncated framing is refused by ordinary legacy parsing.
law composite_single:
  for +text:String
  {D.composite([text]) == False{} : Bool}
# Guarantees: the first line alone selects composite framing when a receipt row exists.
# Why it matters: legacy commands retain their existing pipe-based protocol.
law composite_multi:
  for +head:String
  for +next:String
  for +tail:List<&2,String>
  {D.composite(head <> next <> tail) == String.eq(head,"BSC1") : Bool}
# Guarantees: missing packet fields refuse admission.
# Why it matters: partial packets cannot acknowledge snapshots.
law packet_lines_nil:
  {D.packet_lines([]) == None{} : Maybe<&2,D.Payload>}
# Guarantees: a lone packet line refuses admission.
# Why it matters: truncated packets cannot be mistaken for empty commands.
law packet_lines_single:
  for +head:String
  {D.packet_lines([head]) == None{} : Maybe<&2,D.Payload>}
# Guarantees: both packet children are parsed before any payload is returned.
# Why it matters: a good receipt plus bad commands cannot partly mutate host state.
law packet_lines_multi:
  for +head:String
  for +receipt:String
  for +commands:List<&2,String>
  {D.packet_lines(head <> receipt <> commands) == D.assembled(D.receipt_field(receipt),D.command_field(commands)) : Maybe<&2,D.Payload>}
# Guarantees: recognized composite framing never falls back to permissive parsing.
# Why it matters: invalid combined packets must remain invalid.
law decode_kind_packet:
  for +rows:List<&2,String>
  {D.decode_kind(True{},rows) == D.packet_lines(rows) : Maybe<&2,D.Payload>}
# Guarantees: any noncomposite top-level frame is refused.
# Why it matters: standalone ACKs and command batches cannot bypass atomic delivery.
law decode_kind_noncomposite_refuses:
  for rows:List<&2,String>
  {D.decode_kind(False{},rows) == None{} : Maybe<&2,D.Payload>}
# Guarantees: line dispatch uses exact composite header recognition.
# Why it matters: a good helper cannot hide a broken public packet parser.
law decode_lines_entry:
  for +rows:List<&2,String>
  {D.decode_lines(rows) == D.decode_kind(D.composite(rows),rows) : Maybe<&2,D.Payload>}
