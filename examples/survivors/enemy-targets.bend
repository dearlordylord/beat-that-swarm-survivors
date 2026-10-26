import Base

# Immutable phase inputs. Aiming needs only position and identity; hostile-shot
# admission additionally needs the source archetype and age, never health/loot.
type Target is Data: Target{x: F32,y: F32,identity: U32}
type Shooter is Data: Shooter{target: Target,archetype: U32,age: U32}
type Targets is Data: Targets{aims: List<&2,Target>,shooters: List<&2,Shooter>}
def empty() -> Targets: Targets{[],[]}
def add_aim(target: Target,tail: Targets) -> Targets:
  match tail:
    case Targets{aims,shooters}: Targets{target <> aims,shooters}
def add_enemy(x: F32,y: F32,identity: U32,archetype: U32,age: U32,tail: Targets) -> Targets:
  match tail:
    case Targets{aims,shooters}:
      +target: Target = Target{x,y,identity}
      Targets{target <> aims,Shooter{target,archetype,age} <> shooters}
