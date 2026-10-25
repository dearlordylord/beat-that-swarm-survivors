import Base

# Campaign termination is separate from the game's authoritative phase.
type Outcome is Data: Active{} Defeat{} Victory{} Aborted{} Horizon{}

def horizon(reached: Bool) -> Outcome:
  match reached:
    case True{}: Horizon{}
    case False{}: Active{}
def outcome(phase: U32,tick: U32,requested: U32) -> Outcome:
  match phase:
    case 3: Defeat{}
    case 4: Victory{}
    case 5: Aborted{}
    case _: horizon(U32.is_ge(tick,requested))
def stopped(value: Outcome) -> Bool:
  match value:
    case Active{}: False{}
    case _: True{}
def name(value: Outcome) -> String:
  match value:
    case Active{}: "active"
    case Defeat{}: "defeat"
    case Victory{}: "victory"
    case Aborted{}: "aborted"
    case Horizon{}: "horizon"
