import Base
import party-difficulty.bend as D

# Independent arithmetic specification. The zero/single branches are explicit;
# positive parties add the configured percentage for each additional player.
def specification(+base: U32,+players: U32,+extraPercent: U32) -> U32:
  Bool.pick(U32,U32.is_zero(players),0,Bool.pick(U32,U32.is_eq(players,1),U32.min(base,500),U32.min(500,(U32.min(base,500) * (100 + (U32.max(1,U32.min(players,500)) - 1) * U32.min(extraPercent,100)) / 100 : U32))))

# Guarantees: each extra living player adds 25 percent of the solo population.
# Why it matters: two friends face 125 percent rather than the old 200 percent.
law default_extra_exact:
  {D.extra_per_player_percent() == 25 : U32}

# Guarantees: the incoming solo budget is capped at the pool ceiling of 500 slots.
# Why it matters: an oversized mode/Curse budget cannot wrap scaled arithmetic.
law bounded_base_exact:
  for +base: U32
  {D.bounded_base(base) == U32.min(base,500) : U32}

# Guarantees: arithmetic sees a player factor in 1..500, even for malformed input.
# Why it matters: subtracting the first player cannot underflow into huge pressure.
law bounded_players_exact:
  for +players: U32
  {D.bounded_players(players) == U32.max(1,U32.min(players,500)) : U32}

# Guarantees: configurable overhead is capped at 100 percent per extra player.
# Why it matters: experimental or malformed values cannot overflow the numerator.
law bounded_extra_exact:
  for +extra: U32
  {D.bounded_extra(extra) == U32.min(extra,100) : U32}

# Guarantees: the first player costs 100 percent and each additional player adds overhead.
# Why it matters: overhead is charged for extra players, not for the solo player.
law population_percent_exact:
  for +players: U32
  for +extra: U32
  {D.population_percent(players,extra) == (100 + (U32.max(1,U32.min(players,500)) - 1) * U32.min(extra,100) : U32) : U32}

# Guarantees: the final scaled budget never passes the physical limit of 500 slots.
# Why it matters: extra players cannot allocate more ordinary spawn slots than exist.
law capped_limit_exact:
  for +amount: U32
  {D.capped_limit(amount) == U32.min(500,amount) : U32}

# Guarantees: scaling multiplies a bounded solo budget, floors its percentage, then caps it.
# Why it matters: rounding and the physical ceiling are part of every experiment.
law scaled_limit_exact:
  for +base: U32
  for +players: U32
  for +extra: U32
  {D.scaled_limit(base,players,extra) == U32.min(500,(U32.min(base,500) * (100 + (U32.max(1,U32.min(players,500)) - 1) * U32.min(extra,100)) / 100 : U32)) : U32}

# Guarantees: the single-player selector chooses the unchanged base or scaled party budget.
# Why it matters: the real positive-party branch must preserve solo independently of tuning.
law select_single_exact:
  for +single: Bool
  for +base: U32
  for +players: U32
  for +extra: U32
  {D.select_single(single,base,players,extra) == Bool.pick(U32,single,D.bounded_base(base),D.scaled_limit(base,players,extra)) : U32}

# Guarantees: the empty-party selector returns zero or continues to the one-player selector.
# Why it matters: no new enemy population is created without a living connected player.
law select_empty_exact:
  for +empty: Bool
  for +base: U32
  for +players: U32
  for +extra: U32
  {D.select_empty(empty,base,players,extra) == Bool.pick(U32,empty,0,D.select_single(U32.is_eq(players,1),base,players,extra)) : U32}

# Guarantees: every configuration follows the independent complete population specification.
# Why it matters: the actual entry cannot bypass zero, solo, caps, overhead or rounding.
law configurable_spawn_limit_exact:
  for +base: U32
  for +players: U32
  for +extra: U32
  {D.spawn_limit_for(base,players,extra) == specification(base,players,extra) : U32}

# Guarantees: the public game entry uses exactly the configured 25-percent overhead.
# Why it matters: proving a configurable helper alone would not protect the real game.
law spawn_limit_exact:
  for +base: U32
  for +players: U32
  {D.spawn_limit(base,players) == specification(base,players,25) : U32}

# Guarantees: no living connected player admits any new ordinary spawn slot.
# Why it matters: an empty party must not keep building a population.
law no_players:
  for +base: U32
  for +extra: U32
  {D.spawn_limit_for(base,0,extra) == 0 : U32}

# Guarantees: one living player retains the exact capped solo budget for every config.
# Why it matters: co-op tuning must not silently change solo or one-survivor pressure.
law one_player_identity:
  for +base: U32
  for +extra: U32
  {D.spawn_limit_for(base,1,extra) == U32.min(base,500) : U32}

# Guarantees: the initial two-player budget is 120 slots at the standard solo 96.
# Why it matters: the new initial overhead is 24 slots instead of 96.
law initial_pair_budget:
  {D.spawn_limit(96,2) == 120 : U32}

# Guarantees: the ordinary late two-player budget is 375 when the solo budget is 300.
# Why it matters: co-op retains crowd growth without immediately filling 500 slots.
law late_pair_budget:
  {D.spawn_limit(300,2) == 375 : U32}

# Guarantees: fractional extra slots are rounded down, not up.
# Why it matters: integer slot admission remains deterministic between backends.
law pair_rounding:
  {D.spawn_limit(99,2) == 123 : U32}

# Guarantees: the 100-percent overhead control retains the old initial 192 slots.
# Why it matters: the experiment can reproduce current pressure before changing it.
law initial_legacy_control:
  {D.spawn_limit_for(96,2,100) == 192 : U32}

# Guarantees: the 100-percent overhead control retains the old capped 500 slots.
# Why it matters: a baseline arm must retain the old late-game cap.
law late_legacy_control:
  {D.spawn_limit_for(300,2,100) == 500 : U32}
