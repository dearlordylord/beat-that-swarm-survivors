import Base
import bot-turn.bend as T

# Guarantees: gameplay requests a movement decision.
# Why it matters: both bot launchers must advance through the same policy.
law active_moves: {T.select(0) == T.MovementDecision{} : T.Turn}
# Guarantees: a level-up requests an upgrade instead of moving.
# Why it matters: the native bot must resolve upgrades without an external controller.
law level_up_chooses: {T.select(1) == T.UpgradeDecision{} : T.Turn}
# Guarantees: a chest requests the same upgrade policy.
# Why it matters: chest phases must not freeze an otherwise autonomous run.
law chest_chooses: {T.select(2) == T.UpgradeDecision{} : T.Turn}
# Guarantees: defeat stops further decisions.
# Why it matters: a terminal world must not take an extra movement step.
law defeat_stops: {T.select(3) == T.StopDecision{} : T.Turn}
# Guarantees: victory stops further decisions.
# Why it matters: completed runs must retain their final state.
law victory_stops: {T.select(4) == T.StopDecision{} : T.Turn}
