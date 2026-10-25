import Base
import offline-coop-control.bend as C

# Guarantees: reaching the requested tick is an observation horizon, not victory.
# Why it matters: a living bot at a short time cap must not count as a game win.
law reached_horizon:
  {C.horizon(True{}) == C.Horizon{} : C.Outcome}
# Guarantees: an unreached horizon leaves execution active.
# Why it matters: the runner cannot stop after an arbitrary nonterminal step.
law before_horizon:
  {C.horizon(False{}) == C.Active{} : C.Outcome}
# Guarantees: phase 3 is defeat regardless of the observation limit.
# Why it matters: a death on the final requested tick remains a death.
law defeat_priority:
  for tick:U32
  for requested:U32
  {C.outcome(3,tick,requested) == C.Defeat{} : C.Outcome}
# Guarantees: phase 4 is the game's victory state regardless of HP or horizon.
# Why it matters: the timed finale can have HP zero without being ordinary defeat.
law victory_priority:
  for tick:U32
  for requested:U32
  {C.outcome(4,tick,requested) == C.Victory{} : C.Outcome}
# Guarantees: phase 5 is an abort, never an ordinary loss or win.
# Why it matters: interrupted sessions cannot inflate balance success or death rates.
law abort_priority:
  for tick:U32
  for requested:U32
  {C.outcome(5,tick,requested) == C.Aborted{} : C.Outcome}
# Guarantees: ordinary active gameplay stops only at its requested horizon.
# Why it matters: native campaign duration uses simulation ticks, not wall time.
law active_horizon:
  for +tick:U32
  for +requested:U32
  {C.outcome(0,tick,requested) == C.horizon(U32.is_ge(tick,requested)) : C.Outcome}
# Guarantees: reward pauses do not become terminal outcomes before the horizon.
# Why it matters: choosing an offered upgrade cannot end a campaign as a win.
law level_horizon:
  for +tick:U32
  for +requested:U32
  {C.outcome(1,tick,requested) == C.horizon(U32.is_ge(tick,requested)) : C.Outcome}
# Guarantees: chest pauses follow the same horizon rule as other active phases.
# Why it matters: the collector's reward is serviced rather than mistaken for defeat.
law chest_horizon:
  for +tick:U32
  for +requested:U32
  {C.outcome(2,tick,requested) == C.horizon(U32.is_ge(tick,requested)) : C.Outcome}
# Guarantees: Active is the sole continuing outcome.
# Why it matters: a terminal game cannot spend more campaign fuel moving afterward.
law active_continues:
  {C.stopped(C.Active{}) == False{} : Bool}
# Guarantees: all real termination labels stop the runner.
# Why it matters: classification and the loop's actual stop decision agree.
law defeat_stops:
  {C.stopped(C.Defeat{}) == True{} : Bool}
# Guarantees: victory stops the campaign loop.
# Why it matters: the timed finale is emitted exactly once as a final summary.
law victory_stops:
  {C.stopped(C.Victory{}) == True{} : Bool}
# Guarantees: abort stops the campaign loop.
# Why it matters: a failed session cannot keep generating apparently valid samples.
law abort_stops:
  {C.stopped(C.Aborted{}) == True{} : Bool}
# Guarantees: a bounded observation ends execution without claiming victory.
# Why it matters: short pilot campaigns remain right-censored balance evidence.
law horizon_stops:
  {C.stopped(C.Horizon{}) == True{} : Bool}
# Guarantees: the active label is serialized without inventing completion.
# Why it matters: the receipt schema must preserve the actual classifier output.
law active_label:
  {C.name(C.Active{}) == "active" : String}
# Guarantees: defeat serializes as defeat.
# Why it matters: completed execution is not confused with winning the game.
law defeat_label:
  {C.name(C.Defeat{}) == "defeat" : String}
# Guarantees: victory serializes as victory.
# Why it matters: the consumer can identify the real timed endpoint.
law victory_label:
  {C.name(C.Victory{}) == "victory" : String}
# Guarantees: an aborted episode remains explicitly aborted in receipts.
# Why it matters: infrastructure loss cannot silently count as a game loss.
law abort_label:
  {C.name(C.Aborted{}) == "aborted" : String}
# Guarantees: a horizon serializes as horizon rather than victory.
# Why it matters: downstream reports preserve right-censored observations.
law horizon_label:
  {C.name(C.Horizon{}) == "horizon" : String}
