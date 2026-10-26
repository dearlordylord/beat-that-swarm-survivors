import Base
import bot-pacing.bend as P

# Guarantees: unlimited mode permits the next step at every clock reading.
# Why it matters: simulation must not wait for a realtime tick deadline.
law unlimited_ready:
  for now: Nat
  for last: Nat
  {P.ready(P.Unlimited{},now,last) == True{} : Bool}
# Guarantees: realtime mode waits at fifteen elapsed milliseconds.
# Why it matters: the default window launch must retain its existing pace.
law realtime_waits: {P.ready(P.Realtime{},15n,0n) == False{} : Bool}
# Guarantees: realtime mode permits a step at its deadline.
# Why it matters: the default launch must advance after the wait.
law realtime_ready: {P.ready(P.Realtime{},16n,0n) == True{} : Bool}
# Guarantees: the simulation slice continues at seven elapsed milliseconds.
# Why it matters: unlimited mode can take more than one step per frame.
law slice_continues: {P.yield_frame(7n,0n) == False{} : Bool}
# Guarantees: an expired slice returns control to rendering and input.
# Why it matters: an unlimited bot must not monopolize the application loop.
law slice_yields: {P.yield_frame(8n,0n) == True{} : Bool}
