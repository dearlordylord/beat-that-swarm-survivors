import Base

# Planner-only spatial observation. No health, damage, XP or identity payloads
# can be written or interpreted through a threat.
type Threat is Data: Threat{x: F32,y: F32,radius: F32,hostile: Bool}
def keep(enabled: Bool,threat: Threat,tail: List<&2,Threat>) -> List<&2,Threat>:
  match enabled:
    case True{}: threat <> tail
    case False{}: tail
