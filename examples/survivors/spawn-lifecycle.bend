import Base

# An updated age-zero enemy is fresh only if its pre-update body was not
# already an age-zero enemy. This distinguishes births/boss resets from a live
# movement age counter wrapping to zero before update.
# Payload is carried intact; consumers reset status rather than interpolate it
# from the previous incarnation's coordinates, collision or Motion.
type Routed<T:Data> is Data:
  Fresh{payload:T}
  Existing{payload:T}
def is_newborn(kind:U32,age:U32) -> Bool:
  match kind age:
    case 0 0: True{}
    case _ _: False{}
def route_flag(~T:Data,fresh:Bool,payload:T) -> Routed<T>:
  match fresh:
    case True{}: Fresh{payload}
    case False{}: Existing{payload}
def fresh_transition(previous:Bool,updated:Bool) -> Bool:
  Bool.and(Bool.not(previous),updated)
def route(~T:Data,previousKind:U32,previousAge:U32,kind:U32,age:U32,payload:T) -> Routed<T>:
  route_flag(~T,fresh_transition(is_newborn(previousKind,previousAge),is_newborn(kind,age)),payload)
# Newborn output deliberately has no old-status argument.
def newborn(~T:Data,~M:Data,payload:T,cleanMotion:M) -> T & M:
  (payload,cleanMotion)

def payload(~T:Data,routed:Routed<T>) -> T:
  match routed:
    case Fresh{value}: value
    case Existing{value}: value
