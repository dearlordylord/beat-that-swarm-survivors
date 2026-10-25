import Base
import ./coop-input-flow.bend as F
import ./coop-session.bend as S
import ./coop-protocol.bend as P

# Guarantees: the journal admits at most 64 commands, reserves two entries for
# controls, and emits at most 32 commands in a 5156-byte frame.
# Why it matters: a shared lane can spend200ms on an ACK and200ms on an
# input write. The former16-row batch and32-record journal could not retain
# the resulting flight plus newly generated60Hz inputs. Capacity64 and batch32
# cover the measured operating point without changing any command's target tick;
# a slower lane still applies bounded backpressure rather than promising latency.
law limits_exact:
  {F.max_commands() == 64n : Nat} & {F.max_inputs() == 62n : Nat} & {F.max_controls() == 2n : Nat} & {F.max_batch() == 32n : Nat} & {F.max_frame_bytes() == 5156 : U32}

# Guarantees: a new connection epoch starts with no pending or in-flight data.
# Why it matters: commands from a departed connection cannot enter its replacement.
law fresh_exact:
  for +epoch:U32
  {F.fresh(epoch) == F.State{epoch,0,[],None{},False{}} : F.State}

# Guarantees: precisely fixed movement ticks consume the thirty input slots.
# Why it matters: a level-up choice retains access to the reserved control slots.
def input_action(action:S.Action) -> Bool:
  match action:
    case S.MovementTick{_,_,_}: True{}
    case _: False{}
law input_classification_exact:
  for session:U32
  for player:U32
  for seq:U32
  for target:U32
  for +action:S.Action
  {F.is_input(S.Command{session,player,seq,target,action}) == input_action(action) : Bool}

# Guarantees: an empty command journal contains zero movement ticks.
# Why it matters: control reservation must not start partly occupied.
law empty_input_count:
  {F.input_count([]) == 0n : Nat}

# Guarantees: counting a row adds exactly one for a movement tick and zero for
# any control, then continues over every remaining command.
# Why it matters: miscounting command kinds cannot bypass the journal bound.
law input_count_successor:
  for +head:S.Command
  for +tail:List<&2,S.Command>
  {F.input_count(head <> tail) == Nat.add(Bool.pick(Nat,F.is_input(head),1n,0n),F.input_count(tail)) : Nat}

# Guarantees: admission checks the entire journal, including the active flight,
# the total 32-entry limit and the independent input/control reservations.
# Why it matters: the producer must stop before accepting another predicted tick
# when its durable local send journal has no room.
law counts_exact:
  for +input:Bool
  for +rows:List<&2,S.Command>
  {F.counts_allowed(input,rows) == Bool.and(Nat.is_lt(List.length(&2,S.Command,rows),64n),Bool.pick(Bool,input,Nat.is_lt(F.input_count(rows),62n),Nat.is_lt(Nat.sub(List.length(&2,S.Command,rows),F.input_count(rows)),2n))) : Bool}

# Guarantees: a failed flow refuses admission; otherwise the journal's exact
# reservation policy decides, with no packet or world-tick rewriting.
# Why it matters: a failed transport cannot continue accumulating fake input.
law admission_exact:
  for +epoch:U32
  for +next:U32
  for +pending:List<&2,S.Command>
  for +flight:Maybe<&2,F.Batch>
  for +failed:Bool
  for +command:S.Command
  {F.can_enqueue(F.State{epoch,next,pending,flight,failed},command) == Bool.and(Bool.not(failed),F.counts_allowed(F.is_input(command),List.append(&2,S.Command,F.flight_commands(flight),pending))) : Bool}

# Guarantees: rejected admission preserves the entire journal and reports false.
# Why it matters: the caller can refuse a local simulation step without losing
# an earlier accepted command or claiming this new one was queued.
law rejected_enqueue_preserves:
  for +state:F.State
  for command:S.Command
  {F.enqueue_selected(False{},state,command) == F.Admission{state,False{}} : F.Admission}

# Guarantees: accepted admission appends the unchanged complete command after
# all previously pending commands and leaves the active flight unchanged.
# Why it matters: targets, sequences, choices and input order must survive batching.
law accepted_enqueue_exact:
  for +epoch:U32
  for +next:U32
  for +pending:List<&2,S.Command>
  for +flight:Maybe<&2,F.Batch>
  for +failed:Bool
  for +command:S.Command
  {F.enqueue_selected(True{},F.State{epoch,next,pending,flight,failed},command) == F.Admission{F.State{epoch,next,List.append(&2,S.Command,pending,[command]),flight,failed},True{}} : F.Admission}

# Guarantees: public admission delegates to that exact policy and transition.
# Why it matters: helper proofs cannot leave the production admission unchecked.
law enqueue_public_exact:
  for +state:F.State
  for +command:S.Command
  {F.enqueue(state,command) == F.enqueue_selected(F.can_enqueue(state,command),state,command) : F.Admission}

# Guarantees: an existing flight prevents preparing another simultaneous flight.
# Why it matters: native stream backpressure cannot create parallel send buildup.
law one_flight_only:
  for epoch:U32
  for next:U32
  for pending:List<&2,S.Command>
  for batch:F.Batch
  for failed:Bool
  {F.ready(F.State{epoch,next,pending,Some{batch},failed}) == False{} : Bool}

# Guarantees: preparation takes the first sixteen pending commands as one flight
# and leaves the remaining suffix pending, with a fresh batch identity.
# Why it matters: neither controls nor assigned movement ticks may be dropped,
# coalesced into a different input, or delivered out of order.
law prepared_batch_exact:
  for +epoch:U32
  for +next:U32
  for +pending:List<&2,S.Command>
  {F.prepare_selected(True{},F.State{epoch,next,pending,None{},False{}}) == F.Prepared{F.State{epoch,(next + 1 : U32),List.drop(&2,S.Command,pending,32n),Some{F.Batch{epoch,(next + 1 : U32),List.take(&2,S.Command,pending,32n)}},False{}},Some{F.Batch{epoch,(next + 1 : U32),List.take(&2,S.Command,pending,32n)}}} : F.Prepared}

def prepared_state(prepared:F.Prepared) -> F.State:
  match prepared:
    case F.Prepared{state,_}: state
# Guarantees: preparing a batch preserves the full ordered command journal.
# Why it matters: moving accepted input into a flight cannot silently erase it.
law preparation_preserves_journal:
  for +state:F.State
  {F.journal(prepared_state(F.prepare(state))) == F.journal(state) : List<&2,S.Command>}

# Guarantees: public preparation is controlled by the single-flight readiness rule.
# Why it matters: an unchecked adapter cannot reserve an additional native send.
law prepare_public_exact:
  for +state:F.State
  {F.prepare(state) == F.prepare_selected(F.ready(state),state) : F.Prepared}

# Guarantees: a flight completion must match its connection epoch and batch ID.
# Why it matters: a late callback from an older connection cannot drain new input.
law matching_exact:
  for +epoch:U32
  for next:U32
  for pending:List<&2,S.Command>
  for +batchEpoch:U32
  for +batchId:U32
  for rows:List<&2,S.Command>
  for +callbackEpoch:U32
  for +callbackId:U32
  {F.matches(F.State{epoch,next,pending,Some{F.Batch{batchEpoch,batchId,rows}},False{}},callbackEpoch,callbackId) == Bool.and(U32.is_eq(epoch,callbackEpoch),Bool.and(U32.is_eq(batchEpoch,callbackEpoch),U32.is_eq(batchId,callbackId))) : Bool}

# Guarantees: a matching completion removes only the flight, retaining every
# later pending command and the connection's batch counter.
# Why it matters: successful IO cannot discard commands queued while it waited.
law matching_completion_exact:
  for +epoch:U32
  for +next:U32
  for +pending:List<&2,S.Command>
  for flight:Maybe<&2,F.Batch>
  for +failed:Bool
  {F.complete_selected(True{},F.State{epoch,next,pending,flight,failed}) == F.State{epoch,next,pending,None{},failed} : F.State}

# Guarantees: nonmatching completion changes no state.
# Why it matters: stale or duplicate callbacks cannot consume another batch.
law stale_completion_preserves:
  for +state:F.State
  {F.complete_selected(False{},state) == state : F.State}

# Guarantees: failure retains all accepted commands and fences further use.
# Why it matters: failed delivery is an explicit failed connection, never a
# successful send that quietly drops already predicted input.
law failure_preserves_journal:
  for +epoch:U32
  for +next:U32
  for +pending:List<&2,S.Command>
  for +flight:Maybe<&2,F.Batch>
  for failed:Bool
  {F.fail_selected(True{},F.State{epoch,next,pending,flight,failed}) == F.State{epoch,next,pending,flight,True{}} : F.State}

# Guarantees: a frame contains each complete encoded command in its FIFO order.
# Why it matters: batching never reconstructs, retargets or merges input ticks.
law encoding_exact:
  for epoch:U32
  for id:U32
  for +rows:List<&2,S.Command>
  {F.encode(F.Batch{epoch,id,rows}) == "BSB1\n" ++ F.encode_rows(rows) : String}

# Guarantees: the decoder accepts only nonempty batches of at most thirty-two rows.
# Why it matters: one network frame cannot expand into an unbounded mailbox job.
law row_limit_exact:
  for +rows:List<&2,String>
  {F.rows_allowed(rows) == Bool.and(Nat.is_gt(List.length(&2,String,rows),0n),Nat.is_le(List.length(&2,String,rows),32n)) : Bool}

# Guarantees: a malformed head or suffix refuses the entire batch.
# Why it matters: a malformed batch cannot apply a valid prefix before failing.
law malformed_head_refuses:
  for tail:Maybe<&2,List<&2,S.Command>>
  {F.parsed_row(None{},tail) == None{} : Maybe<&2,List<&2,S.Command>>}

# Guarantees: a malformed suffix refuses an otherwise valid first command.
# Why it matters: atomic decoding covers every row, not just the packet header.
law malformed_tail_refuses:
  for head:S.Command
  {F.parsed_row(Some{head},None{}) == None{} : Maybe<&2,List<&2,S.Command>>}

# Guarantees: two successfully parsed pieces retain the exact complete command.
# Why it matters: parsing cannot rewrite its transport identity or target tick.
law parsed_row_exact:
  for +head:S.Command
  for +tail:List<&2,S.Command>
  {F.parsed_row(Some{head},Some{tail}) == Some{head <> tail} : Maybe<&2,List<&2,S.Command>>}

# Guarantees: an oversized frame is refused before line or command parsing.
# Why it matters: batching cannot introduce unbounded parser recursion or memory.
law oversized_frame_refuses:
  for text:String
  {F.decode_selected(False{},text) == None{} : Maybe<&2,List<&2,S.Command>>}

# Guarantees: a healthy waiting journal can prepare a batch when its ID has room.
# Why it matters: the single-flight safety gate cannot disable all sending.
law waiting_flow_ready:
  for epoch:U32
  for +next:U32
  for head:S.Command
  for tail:List<&2,S.Command>
  {F.ready(F.State{epoch,next,head <> tail,None{},False{}}) == U32.is_lt(next,4294967295) : Bool}

# Guarantees: production completion uses the exact epoch/ID matching gate.
# Why it matters: a proved helper cannot mask an adapter dropping the wrong batch.
law complete_public_exact:
  for +state:F.State
  for +epoch:U32
  for +id:U32
  {F.complete(state,epoch,id) == F.complete_selected(F.matches(state,epoch,id),state) : F.State}

# Guarantees: production failure uses that same matching gate and retained journal.
# Why it matters: stale errors cannot fence a replacement connection.
law fail_public_exact:
  for +state:F.State
  for +epoch:U32
  for +id:U32
  {F.fail(state,epoch,id) == F.fail_selected(F.matches(state,epoch,id),state) : F.State}

# Guarantees: the encoded row list has no phantom command when empty.
# Why it matters: a prepared batch cannot acquire an invented input.
law empty_encoding:
  {F.encode_rows([]) == "" : String}

# Guarantees: a sole command is its exact canonical existing protocol encoding.
# Why it matters: all command fields survive the new batch envelope unchanged.
law single_encoding:
  for +command:S.Command
  {F.encode_rows([command]) == P.encode(command) : String}

# Guarantees: multiple commands are encoded oldest first with one line separator.
# Why it matters: batch preparation cannot reverse the command stream.
law ordered_encoding:
  for +first:S.Command
  for +second:S.Command
  for +rest:List<&2,S.Command>
  {F.encode_rows(first <> second <> rest) == P.encode(first) ++ "\n" ++ F.encode_rows(second <> rest) : String}

# Guarantees: decoding a row list checks its head and its complete suffix.
# Why it matters: no valid prefix may conceal a malformed later command.
law row_parser_exact:
  for +head:String
  for +tail:List<&2,String>
  {F.parse_rows(head <> tail) == F.parsed_row(P.decode(head),F.parse_rows(tail)) : Maybe<&2,List<&2,S.Command>>}

# Guarantees: only the allowed branch invokes the row parser.
# Why it matters: a zero-row or thirty-third-row batch cannot bypass the declared bound.
law parser_gate_exact:
  for +allowed:Bool
  for +rows:List<&2,String>
  {F.parse_selected(allowed,rows) == Bool.pick(Maybe<&2,List<&2,S.Command>>,allowed,F.parse_rows(rows),None{}) : Maybe<&2,List<&2,S.Command>>}

# Guarantees: the BSB1 envelope delegates to bounded atomic row parsing.
# Why it matters: the production packet decoder cannot ignore its count checks.
law batch_decoding_exact:
  for +rows:List<&2,String>
  {F.decode_lines("BSB1" <> rows) == F.parse_selected(F.rows_allowed(rows),rows) : Maybe<&2,List<&2,S.Command>>}

# Guarantees: the public decoder applies the frame-size limit before parsing.
# Why it matters: bounded helper proofs must cover the actual network entrypoint.
law decode_public_exact:
  for +text:String
  {F.decode(text) == F.decode_selected(Nat.is_le(String.length(text),U32.to_nat(F.max_frame_bytes())),text) : Maybe<&2,List<&2,S.Command>>}

# Guarantees: absent flights contribute no commands to the journal.
# Why it matters: reservation counters cannot contain phantom in-flight inputs.
law no_flight_commands:
  {F.flight_commands(None{}) == [] : List<&2,S.Command>}

# Guarantees: a flight contributes its entire unchanged command list.
# Why it matters: counting or journaling cannot omit the active batch.
law flight_commands_exact:
  for epoch:U32
  for id:U32
  for +rows:List<&2,S.Command>
  {F.flight_commands(Some{F.Batch{epoch,id,rows}}) == rows : List<&2,S.Command>}

# Guarantees: every journal is exactly the active flight followed by pending rows.
# Why it matters: capacity and conservation laws must include both owners.
law journal_exact:
  for epoch:U32
  for next:U32
  for +pending:List<&2,S.Command>
  for +flight:Maybe<&2,F.Batch>
  for failed:Bool
  {F.journal(F.State{epoch,next,pending,flight,failed}) == List.append(&2,S.Command,F.flight_commands(flight),pending) : List<&2,S.Command>}

# Guarantees: an empty pending queue cannot create another flight.
# Why it matters: the sender must not emit endless empty native streams.
law empty_flow_not_ready:
  for epoch:U32
  for next:U32
  for flight:Maybe<&2,F.Batch>
  for failed:Bool
  {F.ready(F.State{epoch,next,[],flight,failed}) == False{} : Bool}

# Guarantees: failed flows cannot prepare more commands.
# Why it matters: transport failure is fenced rather than silently retried.
law failed_flow_not_ready:
  for epoch:U32
  for next:U32
  for pending:List<&2,S.Command>
  for flight:Maybe<&2,F.Batch>
  {F.ready(F.State{epoch,next,pending,flight,True{}}) == False{} : Bool}

# Guarantees: completion cannot match when no flight exists.
# Why it matters: duplicate callbacks cannot drain a later pending queue.
law absent_flight_never_matches:
  for epoch:U32
  for next:U32
  for pending:List<&2,S.Command>
  for failed:Bool
  for callbackEpoch:U32
  for callbackId:U32
  {F.matches(F.State{epoch,next,pending,None{},failed},callbackEpoch,callbackId) == False{} : Bool}

# Guarantees: completion cannot match an already failed flow.
# Why it matters: an asynchronous success cannot revive a failed connection.
law failed_flow_never_matches:
  for epoch:U32
  for next:U32
  for pending:List<&2,S.Command>
  for flight:Maybe<&2,F.Batch>
  for callbackEpoch:U32
  for callbackId:U32
  {F.matches(F.State{epoch,next,pending,flight,True{}},callbackEpoch,callbackId) == False{} : Bool}

# Guarantees: a nonmatching failure does not fence or alter the flow.
# Why it matters: errors from an older epoch cannot close a replacement sender.
law stale_failure_preserves:
  for +state:F.State
  {F.fail_selected(False{},state) == state : F.State}

# Guarantees: an empty row parser succeeds with exactly an empty typed list.
# Why it matters: recursive atomic parsing cannot invent a trailing command.
law empty_row_parser:
  {F.parse_rows([]) == Some{[]} : Maybe<&2,List<&2,S.Command>>}

# Guarantees: the allowed size branch dispatches to the packet and line parser.
# Why it matters: the network decoder must actually process accepted-size frames.
law allowed_frame_dispatches:
  for +text:String
  {F.decode_selected(True{},text) == F.decode_lines(F.lines(text,"")) : Maybe<&2,List<&2,S.Command>>}

# Only an explicit bounded batch envelope is accepted at this boundary.
def packet_spec(rows:List<&2,String>) -> Maybe<&2,List<&2,S.Command>>:
  match rows:
    case []: None{}
    case head <> tail: F.decode_kind(String.eq(head,"BSB1"),tail)
# Guarantees: packet dispatch accepts only the batch envelope and its atomic parser.
# Why it matters: plain single commands cannot bypass canonical delivery framing.
law packet_dispatch_exact:
  for +rows:List<&2,String>
  {F.decode_lines(rows) == packet_spec(rows) : Maybe<&2,List<&2,S.Command>>}

# Guarantees: absent framing cannot produce a command list.
# Why it matters: empty input must not become a fabricated action.
law empty_packet_refuses:
  {F.decode_lines([]) == None{} : Maybe<&2,List<&2,S.Command>>}

def line_spec(text:String,+acc:String) -> List<&2,String>:
  match text:
    case SNil{}: [String.reverse(acc)]
    case SCon{+char,+tail}: F.line_choice(Char.is_eq(char,'\n'),u => String.reverse(acc) <> line_spec(tail,""),u => line_spec(tail,SCon{char,acc}))
# Guarantees: splitting preserves every character and every empty field exactly,
# using only a newline as a command boundary.
# Why it matters: a batch parser cannot skip a malformed middle row or reverse
# characters while the typed row parser still appears correct in isolation.
law line_split_exact:
  for +text:String
  for +acc:String
  {F.lines(text,acc) == line_spec(text,acc) : List<&2,String>}

# Guarantees: a nonready preparation preserves the full state and emits no batch.
# Why it matters: readiness cannot be bypassed to create an extra native flight.
law nonready_prepare_preserves:
  for +state:F.State
  {F.prepare_selected(False{},state) == F.Prepared{state,None{}} : F.Prepared}

# Guarantees: a recognized batch header enters bounded atomic row parsing.
# Why it matters: a batch cannot silently become a single-frame fallback.
law batch_kind_exact:
  for +rows:List<&2,String>
  {F.decode_kind(True{},rows) == F.parse_selected(F.rows_allowed(rows),rows) : Maybe<&2,List<&2,S.Command>>}

# Guarantees: an unrecognized batch header is always refused.
# Why it matters: Setup and host actions must use the same framed batch codec.
law unknown_kind_refuses:
  for rows:List<&2,String>
  {F.decode_kind(False{},rows) == None{} : Maybe<&2,List<&2,S.Command>>}

# Guarantees: newline dispatch selects only its newline branch.
# Why it matters: command separators cannot be appended to numeric fields.
law newline_choice_exact:
  for +yes:List<&2,String>
  for no:List<&2,String>
  {F.line_choice(True{},u => yes,u => no) == yes : List<&2,String>}

# Guarantees: a non-newline selects only its character-preserving branch.
# Why it matters: normal characters cannot be discarded as separators.
law character_choice_exact:
  for yes:List<&2,String>
  for +no:List<&2,String>
  {F.line_choice(False{},u => yes,u => no) == no : List<&2,String>}
