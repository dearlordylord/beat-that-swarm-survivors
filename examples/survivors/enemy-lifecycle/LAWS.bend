import Base
import ../enemy-lifecycle.bend as E

# Guarantees: admitted enemy birth preserves its candidate and constructs age
#   zero, zero slow/burn, zero contact damage and no previous-life killer.
# Why it matters: a corpse's effects or contacts cannot damage its replacement.
law birth_constructs_fresh_lifetime:
  for +candidate: E.Candidate
  {E.birth(candidate) == E.Newborn{candidate,0,E.Status{0,0},0,None{}} : E.Newborn}
