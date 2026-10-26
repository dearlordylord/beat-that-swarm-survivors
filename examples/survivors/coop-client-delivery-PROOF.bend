import Base
import ./coop-client-delivery.bend as D
import ./coop-client-delivery-LAWS.bend as L
import ./coop-input-flow.bend as I
import ./coop-snapshot-receipts.bend as R
import ./coop-snapshot-flow.bend as F
import ./coop-session.bend as S

def L.limits_exact(): {==}
def L.fresh_exact(epoch): {==}
def L.admitted_exact(epoch,next,receipts,flight,failed,input,accepted): {==}
def L.enqueue_refused(state,command): {==}
def L.enqueue_allowed(epoch,next,input,receipts,flight,failed,command): {==}
def L.enqueue_wiring(epoch,next,input,receipts,flight,failed,command): {==}
def L.offer_refused(state,token,observation): {==}
def L.offer_allowed(epoch,next,input,receipts,flight,failed,token,observation): {==}
def L.offer_wiring(epoch,next,input,receipts,flight,failed,token,observation): {==}
def L.ready_idle(epoch,next,input,receipts): {==}
def L.ready_busy(epoch,next,input,receipts,packet,failed): {==}
def L.ready_failed(epoch,next,input,receipts,flight):
  match flight:
    case None{}: {==}
    case Some{packet}: {==}
def L.batch_absent(): {==}
def L.batch_present(batch): {==}
def L.combined_empty(epoch,next,input,receipts,batch,receipt): {==}
def L.combined_present(epoch,next,input,receipts,batch,receipt): {==}
def L.prepared_children_exact(epoch,next,input,receipts,batch,receipt): {==}
def L.prepare_refused(state): {==}
def L.prepare_allowed(epoch,next,input,receipts): {==}
def L.prepare_wiring(state): {==}
def L.matches_exact(epoch,next,input,receipts,packetEpoch,id,batch,receipt,callbackEpoch,callbackId): {==}
def L.matches_idle(epoch,next,input,receipts,failed,callbackEpoch,callbackId): {==}
def L.matches_failed(epoch,next,input,receipts,flight,callbackEpoch,callbackId):
  match flight:
    case None{}: {==}
    case Some{D.Packet{packetEpoch,packetId,batch,receipt}}: {==}
def L.completed_input_absent(input): {==}
def L.completed_input_stored(epoch,id,commands,input): {==}
def L.completed_receipt_absent(receipts,epoch): {==}
def L.completed_receipt_stored(token,observation,receipts,epoch): {==}
def L.complete_stored_packet(epoch,next,input,receipts,packetEpoch,id,batch,receipt,failed): {==}
def L.complete_refused(state): {==}
def L.complete_wiring(state,epoch,id): {==}
def L.failed_input_absent(input): {==}
def L.failed_input_stored(epoch,id,commands,input): {==}
def L.failed_packet_absent(input): {==}
def L.failed_packet_stored(epoch,id,batch,receipt,input): {==}
def L.fail_fences_retains(epoch,next,input,receipts,flight,failed): {==}
def L.fail_refused(state): {==}
def L.fail_wiring(state,epoch,id): {==}
def L.encode_exact(epoch,id,batch,receipt): {==}
def L.encoded_batch_absent(): {==}
def L.encoded_batch_present(batch): {==}
def L.encoded_receipt_absent(): {==}
def L.encoded_receipt_present(token,observation): {==}
def L.receipt_field_absent(): {==}
def L.assembled_success(receipt,commands): {==}
def L.assembled_bad_receipt(commands): {==}
def L.assembled_bad_commands(receipt):
  match receipt:
    case None{}: {==}
    case Some{value}: {==}
def L.join_lines_empty(): {==}
def L.join_lines_single(head): {==}
def L.join_lines_cons(head,next,tail): {==}
def L.command_field_absent(): {==}
def L.encode_command_exact(command): {==}
def L.decode_packet_lines(receipt,commands): {==}
def L.decode_refused(text): {==}
def L.decode_allowed(text): {==}
def L.decode_entry(text): {==}
def L.parsed_receipt_none(): {==}
def L.parsed_receipt_some(receipt): {==}
def L.receipt_selected_absent(text): {==}
def L.receipt_selected_present(text): {==}
def L.receipt_field_entry(text): {==}
def L.empty_marker_nil(): {==}
def L.empty_marker_single(text): {==}
def L.empty_marker_multi(head,next,tail): {==}
def L.command_selected_absent(rows): {==}
def L.command_selected_present(rows): {==}
def L.command_field_entry(rows): {==}
def L.composite_nil(): {==}
def L.composite_single(text): {==}
def L.composite_multi(head,next,tail): {==}
def L.packet_lines_nil(): {==}
def L.packet_lines_single(head): {==}
def L.packet_lines_multi(head,receipt,commands): {==}
def L.decode_kind_packet(rows): {==}
def L.decode_kind_noncomposite_refuses(rows): {==}
def L.decode_lines_entry(rows): {==}
