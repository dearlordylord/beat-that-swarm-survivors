import Base
import run-state.bend as RS
import game-components.bend as Components

# Read-only personal observations shared by solo and co-op presentation.
type Player is Data: Player{id: U32,player: RS.PlayerState,connected: Bool}
def solo(player: RS.PlayerState) -> List<&2,Player>: [Player{0,player,True{}}]
def from_records(rows: List<&2,Components.PlayerRecord>) -> List<&2,Player>:
  match rows:
    case []: []
    case Components.PlayerRecord{id,player,connected} <> rest: Player{id,player,connected} <> from_records(rest)
