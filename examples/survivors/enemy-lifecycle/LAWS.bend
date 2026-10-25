import Base
import ../enemy-effects.bend as Effect
import ../game-components.bend as Components
import ../enemy-lifecycle.bend as E

# Guarantees: admitted enemy birth preserves its candidate and constructs age
#   zero, zero slow/burn, zero contact damage and no previous-life killer.
# Why it matters: a corpse's effects or contacts cannot damage its replacement.
law birth_constructs_fresh_lifetime:
  for +candidate: E.Candidate
  {E.birth(candidate) == E.Newborn{candidate,0,Components.Status{Effect.Slow{0,False{}},Effect.Burn{0,None{}}},0,None{}} : E.Newborn}
