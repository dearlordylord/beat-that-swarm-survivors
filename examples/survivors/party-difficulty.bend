import Base
import pools.bend as Pools

# Party-size population policy. The caller supplies living, connected players
# and the solo budget after stage/mode/Curse modifiers. Only ordinary spawn
# slots are scaled; health, damage, wave time, bosses and XP keep their rules.
# A compile-time policy knob lets native experiments compare identical builds
# with different party overhead, without introducing a second simulation.
def extra_per_player_percent() -> U32: 25

def bounded_base(base: U32) -> U32:
  U32.min(base,Pools.max_regular_enemies())
def bounded_players(players: U32) -> U32:
  U32.max(1,U32.min(players,Pools.max_regular_enemies()))
def bounded_extra(extraPercent: U32) -> U32:
  U32.min(extraPercent,100)
def population_percent(players: U32,extraPercent: U32) -> U32:
  (100 + (bounded_players(players) - 1) * bounded_extra(extraPercent) : U32)
def capped_limit(amount: U32) -> U32:
  U32.min(Pools.max_regular_enemies(),amount)
def scaled_limit(base: U32,players: U32,extraPercent: U32) -> U32:
  capped_limit((bounded_base(base) * population_percent(players,extraPercent) / 100 : U32))

# Clamp before arithmetic: base <= 500, players <= 500, extra <= 100. The largest
# percent is 50,000 and numerator 25,000,000, both below the U32 maximum. Explicit
# zero/single-player branches preserve their exact budgets for every config.
def select_single(single: Bool,base: U32,players: U32,extraPercent: U32) -> U32:
  match single:
    case True{}: bounded_base(base)
    case False{}: scaled_limit(base,players,extraPercent)
def select_empty(empty: Bool,base: U32,+players: U32,extraPercent: U32) -> U32:
  match empty:
    case True{}: 0
    case False{}: select_single(U32.is_eq(players,1),base,players,extraPercent)
def spawn_limit_for(base: U32,+players: U32,extraPercent: U32) -> U32:
  select_empty(U32.is_zero(players),base,players,extraPercent)
def spawn_limit(base: U32,players: U32) -> U32:
  spawn_limit_for(base,players,extra_per_player_percent())
