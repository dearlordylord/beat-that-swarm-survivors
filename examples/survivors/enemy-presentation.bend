import Base
import music.bend as Music
import enemy-combat.bend as Enemy
import enemy-spatial.bend as Space
import enemy-targets.bend as Targets
import game-components.bend as Components

# Music reads proximity and archetype only, not a reconstructed enemy state.
def pressures(rows: List<&2,Enemy.State>) -> List<&2,Music.Threat>:
  match rows:
    case []: []
    case Enemy.State{Space.Spatial{x,y,_,_},archetype,_,_,_} <> rest: Music.Threat{x,y,archetype} <> pressures(rest)
def targets(rows: List<&2,Enemy.State>) -> Targets.Targets:
  match rows:
    case []: Targets.empty()
    case Enemy.State{Space.Spatial{x,y,age,_},archetype,identity,_,_} <> rest: Targets.add_enemy(x,y,identity,archetype,age,targets(rest))
def living(rows: List<&2,Enemy.State>) -> U32:
  match rows:
    case []: 0
    case Enemy.State{_,_,_,Components.Vitals{health,_},_} <> rest: (Bool.to_u32(U32.is_lt(0,health)) + living(rest) : U32)
def boss_seen(rows: List<&2,Enemy.State>) -> Bool:
  match rows:
    case []: False{}
    case Enemy.State{_,archetype,_,_,_} <> rest: Bool.or(U32.is_le(20,archetype),boss_seen(rest))
