import Base

type Turn is Data: MovementDecision{} UpgradeDecision{} StopDecision{}
def select(phase: U32) -> Turn:
  match phase:
    case 0: MovementDecision{}
    case 1: UpgradeDecision{}
    case 2: UpgradeDecision{}
    case _: StopDecision{}
