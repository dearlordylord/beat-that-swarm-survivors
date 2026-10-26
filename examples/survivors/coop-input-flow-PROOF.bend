import Base
import ./coop-input-flow-LAWS.bend as L
import ./coop-input-flow.bend as F
import ./coop-session.bend as S

def split_join(+fuel:Nat,+rows:List<&2,S.Command>) -> {List.append(&2,S.Command,List.take(&2,S.Command,rows,fuel),List.drop(&2,S.Command,rows,fuel)) == rows : List<&2,S.Command>}:
  match fuel rows:
    case 0n Nil{}: {==}
    case 0n Con{_,_}: {==}
    case 1n+rest Nil{}: {==}
    case 1n+rest Con{head,tail}: Equal.cong(List<&2,S.Command>,List<&2,S.Command>,rows => head <> rows,List.append(&2,S.Command,List.take(&2,S.Command,tail,rest),List.drop(&2,S.Command,tail,rest)),tail,split_join(rest,tail))

def selected_journal(+allowed:Bool,+state:F.State) -> {F.journal(L.prepared_state(F.prepare_selected(allowed,state))) == F.journal(state) : List<&2,S.Command>}:
  match allowed state:
    case True{} F.State{_,_,pending,None{},False{}}: split_join(32n,pending)
    case False{} _: {==}
    case True{} F.State{_,_,_,Some{_},_}: {==}
    case True{} F.State{_,_,_,None{},True{}}: {==}

def L.limits_exact(): ({==},({==},({==},({==},{==}))))

def L.fresh_exact(epoch): {==}

def L.input_classification_exact(session,player,seq,target,action):
  match action:
    case S.Movement{_,_}: {==}
    case S.MovementTick{_,_,_}: {==}
    case S.Choice{_,_}: {==}
    case S.Setup{_,_,_,_}: {==}

def L.empty_input_count(): {==}

def L.input_count_successor(head,tail): {==}

def L.counts_exact(input,rows): {==}

def L.admission_exact(epoch,next,pending,flight,failed,command): {==}

def L.rejected_enqueue_preserves(state,command): {==}

def L.accepted_enqueue_exact(epoch,next,pending,flight,failed,command): {==}

def L.enqueue_public_exact(state,command): {==}

def L.one_flight_only(epoch,next,pending,batch,failed):
  match pending:
    case []: {==}
    case _ <> _: {==}

def L.prepared_batch_exact(epoch,next,pending): {==}

def L.preparation_preserves_journal(state): selected_journal(F.ready(state),state)

def L.prepare_public_exact(state): {==}

def L.matching_exact(epoch,next,pending,batchEpoch,batchId,rows,callbackEpoch,callbackId): {==}

def L.matching_completion_exact(epoch,next,pending,flight,failed): {==}

def L.stale_completion_preserves(state): {==}

def L.failure_preserves_journal(epoch,next,pending,flight,failed): {==}

def L.encoding_exact(epoch,id,rows): {==}

def L.row_limit_exact(rows): {==}

def L.malformed_head_refuses(tail): {==}

def L.malformed_tail_refuses(head): {==}

def L.parsed_row_exact(head,tail): {==}

def L.oversized_frame_refuses(text): {==}

def L.waiting_flow_ready(epoch,next,head,tail): {==}

def L.complete_public_exact(state,epoch,id): {==}

def L.fail_public_exact(state,epoch,id): {==}

def L.empty_encoding(): {==}

def L.single_encoding(command): {==}

def L.ordered_encoding(first,second,rest): {==}

def L.row_parser_exact(head,tail): {==}

def L.parser_gate_exact(allowed,rows):
  match allowed:
    case False{}: {==}
    case True{}: {==}

def L.batch_decoding_exact(rows): {==}

def L.decode_public_exact(text): {==}

def L.no_flight_commands(): {==}

def L.flight_commands_exact(epoch,id,rows): {==}

def L.journal_exact(epoch,next,pending,flight,failed): {==}

def L.empty_flow_not_ready(epoch,next,flight,failed): {==}

def L.failed_flow_not_ready(epoch,next,pending,flight):
  match pending flight:
    case [] _: {==}
    case _ <> _ None{}: {==}
    case _ <> _ Some{_}: {==}

def L.absent_flight_never_matches(epoch,next,pending,failed,callbackEpoch,callbackId): {==}

def L.failed_flow_never_matches(epoch,next,pending,flight,callbackEpoch,callbackId):
  match flight:
    case None{}: {==}
    case Some{F.Batch{_,_,_}}: {==}

def L.stale_failure_preserves(state): {==}

def L.empty_row_parser(): {==}

def L.allowed_frame_dispatches(text): {==}

def L.packet_dispatch_exact(rows):
  match rows:
    case []: {==}
    case _ <> _: {==}

def L.empty_packet_refuses(): {==}

def line_join(+newline:Bool,+prefix:String,+a:List<&2,String>,+b:List<&2,String>,+c:List<&2,String>,+d:List<&2,String>,ab:{a == b : List<&2,String>},cd:{c == d : List<&2,String>}) -> {F.line_choice(newline,u => prefix <> a,u => c) == F.line_choice(newline,u => prefix <> b,u => d) : List<&2,String>}:
  match newline:
    case True{}: Equal.cong(List<&2,String>,List<&2,String>,rows => prefix <> rows,a,b,ab)
    case False{}: cd

def L.line_split_exact(text,acc):
  match text:
    case SNil{}: {==}
    case SCon{+char,+tail}: line_join(Char.is_eq(char,'\n'),String.reverse(acc),F.lines(tail,""),L.line_spec(tail,""),F.lines(tail,SCon{char,acc}),L.line_spec(tail,SCon{char,acc}),L.line_split_exact(tail,""),L.line_split_exact(tail,SCon{char,acc}))

def L.nonready_prepare_preserves(state): {==}

def L.batch_kind_exact(rows): {==}
def L.unknown_kind_refuses(rows): {==}
def L.newline_choice_exact(yes,no): {==}
def L.character_choice_exact(yes,no): {==}
