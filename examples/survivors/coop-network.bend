import Base
import coop-core.bend as Core
import coop-session.bend as Session
import coop-hit-journal.bend as Journal

type RejectedInput is Data: RejectedInput{reason: U32,seq: U32,targetWorldTick: U32,worldTick: U32}
type InputTiming is Data: InputTiming{worldTick: U32,lastRejected: Maybe<&2,RejectedInput>}
type Snapshot is Data: Snapshot{connectionVersion: U32,token: U32,initial: Bool,runId: String,observationSeq: U32,view: Core.NetworkView,commandAck: U32,contactJournal: Journal.State,inputTiming: InputTiming}
def command_ack(state: Session.State) -> U32:
  match state:
    case Session.State{_,_,_,guest,_,_}: Session.last_seq(guest)
def snapshot(token: U32,initial: Bool,runId: String,observation: U32,view: Core.NetworkView,session: Session.State,journal: Journal.State,timing: InputTiming) -> Snapshot:
  Snapshot{1,token,initial,runId,observation,view,command_ack(session),journal,timing}
