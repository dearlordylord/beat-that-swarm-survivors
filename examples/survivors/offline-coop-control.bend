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

# Game.boss_variant emits 20..29 for timed stage bosses and 30 for the finale.
# Keep this metadata classification distinct from the ordinary spawn budget.
def living_enemy(kind:U32,hp:U32) -> Bool:
  Bool.and(U32.is_eq(kind,0),U32.is_lt(0,hp))
def boss_variant(+variant:U32) -> Bool:
  Bool.and(U32.is_le(20,variant),U32.is_le(variant,30))
def boss(kind:U32,variant:U32,hp:U32) -> Bool:
  Bool.and(living_enemy(kind,hp),boss_variant(variant))
def ordinary(kind:U32,variant:U32,hp:U32) -> Bool:
  Bool.and(living_enemy(kind,hp),Bool.not(boss_variant(variant)))
