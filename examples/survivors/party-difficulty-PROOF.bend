import Base
import party-difficulty-LAWS.bend as L
import party-difficulty.bend as D

def L.default_extra_exact(): {==}
def L.bounded_base_exact(base): {==}
def L.bounded_players_exact(players): {==}
def L.bounded_extra_exact(extra): {==}
def L.population_percent_exact(players,extra): {==}
def L.capped_limit_exact(amount): {==}
def L.scaled_limit_exact(base,players,extra): {==}
def L.select_single_exact(single,base,players,extra):
  match single:
    case True{}: {==}
    case False{}: {==}
def L.select_empty_exact(empty,base,players,extra):
  match empty:
    case True{}: {==}
    case False{}: {==}

def single_spec(+single: Bool,+base: U32,+players: U32,+extra: U32) -> {D.select_single(single,base,players,extra) == Bool.pick(U32,single,U32.min(base,500),U32.min(500,(U32.min(base,500) * (100 + (U32.max(1,U32.min(players,500)) - 1) * U32.min(extra,100)) / 100 : U32))) : U32}:
  match single:
    case True{}: {==}
    case False{}: {==}
def empty_spec(+empty: Bool,+base: U32,+players: U32,+extra: U32) -> {D.select_empty(empty,base,players,extra) == Bool.pick(U32,empty,0,Bool.pick(U32,U32.is_eq(players,1),U32.min(base,500),U32.min(500,(U32.min(base,500) * (100 + (U32.max(1,U32.min(players,500)) - 1) * U32.min(extra,100)) / 100 : U32)))) : U32}:
  match empty:
    case True{}: {==}
    case False{}: single_spec(U32.is_eq(players,1),base,players,extra)
def L.configurable_spawn_limit_exact(base,players,extra):
  empty_spec(U32.is_zero(players),base,players,extra)
def L.spawn_limit_exact(base,players):
  L.configurable_spawn_limit_exact(base,players,25)
def L.no_players(base,extra): {==}
def L.one_player_identity(base,extra): {==}
def L.initial_pair_budget(): {==}
def L.late_pair_budget(): {==}
def L.pair_rounding(): {==}
def L.initial_legacy_control(): {==}
def L.late_legacy_control(): {==}
