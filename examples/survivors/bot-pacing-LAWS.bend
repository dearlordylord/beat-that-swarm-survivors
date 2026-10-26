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
# Guarantees: the first frame is presented without waiting for simulation work.
# Why it matters: an unlimited run must open a usable window immediately.
law first_frame:
  for now: Nat
  {P.render_due(now,0n) == True{} : Bool}
# Guarantees: a recent presentation does not require another one at 99 ms.
# Why it matters: simulation steps must not each cause a display wait.
law render_waits: {P.render_due(100n,1n) == False{} : Bool}
# Guarantees: presentation is requested at its 100 ms deadline.
# Why it matters: the picture and close events must keep receiving service.
law render_ready: {P.render_due(101n,1n) == True{} : Bool}
