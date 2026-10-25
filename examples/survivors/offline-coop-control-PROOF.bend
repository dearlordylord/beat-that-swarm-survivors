import Base
import offline-coop-control-LAWS.bend as L
import offline-coop-control.bend as C

def L.reached_horizon(): {==}
def L.before_horizon(): {==}
def L.defeat_priority(tick,requested): {==}
def L.victory_priority(tick,requested): {==}
def L.abort_priority(tick,requested): {==}
def L.active_horizon(tick,requested): {==}
def L.level_horizon(tick,requested): {==}
def L.chest_horizon(tick,requested): {==}
def L.active_continues(): {==}
def L.defeat_stops(): {==}
def L.victory_stops(): {==}
def L.abort_stops(): {==}
def L.horizon_stops(): {==}
def L.active_label(): {==}
def L.defeat_label(): {==}
def L.victory_label(): {==}
def L.abort_label(): {==}
def L.horizon_label(): {==}

def L.living_enemy_exact(kind,hp): {==}
def L.boss_variant_exact(variant): {==}
def L.boss_exact(kind,variant,hp): {==}
def L.ordinary_exact(kind,variant,hp): {==}
def partition_bool(+live:Bool,+boss:Bool) -> {Bool.or(Bool.and(live,boss),Bool.and(live,Bool.not(boss))) == live : Bool}:
  match live boss:
    case True{} True{}: {==}
    case True{} False{}: {==}
    case False{} True{}: {==}
    case False{} False{}: {==}
def disjoint_bool(+live:Bool,+boss:Bool) -> {Bool.and(Bool.and(live,boss),Bool.and(live,Bool.not(boss))) == False{} : Bool}:
  match live boss:
    case True{} True{}: {==}
    case True{} False{}: {==}
    case False{} True{}: {==}
    case False{} False{}: {==}
def L.population_partition(kind,variant,hp): partition_bool(C.living_enemy(kind,hp),C.boss_variant(variant))
def L.population_disjoint(kind,variant,hp): disjoint_bool(C.living_enemy(kind,hp),C.boss_variant(variant))
