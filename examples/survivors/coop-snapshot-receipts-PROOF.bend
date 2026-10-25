import Base
import ./coop-snapshot-receipts-LAWS.bend as L

def L.limits_exact(): ({==},{==})
def L.fresh_exact(epoch): {==}
def L.newer_first(token,observation): {==}
def L.newer_existing(current,last,token,observation): {==}
def L.offer_allowed_exact(epoch,latest,pending,flight,token,observation): {==}
def L.offered_latest(epoch,latest,pending,flight,token,observation): {==}
def L.rejected_preserves(state,token,observation): {==}
def L.offer_entry(state,token,observation): {==}
def L.prepare_waiting(epoch,receipt): {==}
def L.prepare_busy(epoch,latest,pending,flight):
  match latest pending:
    case None{} True{}: {==}
    case None{} False{}: {==}
    case Some{_} True{}: {==}
    case Some{_} False{}: {==}
def L.prepare_consumed(epoch,latest):
  match latest:
    case None{}: {==}
    case Some{_}: {==}
def L.prepare_empty(epoch,pending):
  match pending:
    case True{}: {==}
    case False{}: {==}
def L.prepare_entry(state): {==}
def L.matches_exact(current,latest,pending,host,flight,epoch,token,observation): {==}
def L.matches_idle(current,latest,pending,epoch,token,observation): {==}
def L.complete_clears_flight(epoch,latest,pending,flight): {==}
def L.complete_stale(state): {==}
def L.complete_entry(state,epoch,token,observation): {==}
def L.present_none(): {==}
def L.present_some(receipt): {==}
def L.buffered_count_exact(epoch,latest,pending,flight): {==}
def L.buffered_bytes_exact(state): {==}
def L.encode_exact(token,observation): {==}
