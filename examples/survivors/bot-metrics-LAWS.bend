import Base
import bot-metrics.bend as M

# Guarantees: three ticks in fifty milliseconds display normal game speed.
# Why it matters: the overlay must distinguish realtime from acceleration.
law realtime: {M.speed(3n,50n) == 10n : Nat}
# Guarantees: twice the normal tick rate displays twice normal speed.
# Why it matters: unlimited mode must report actual simulated progress.
law doubled: {M.speed(6n,50n) == 20n : Nat}
# Guarantees: three frames in fifty milliseconds normalize to sixty per second.
# Why it matters: a shorter refresh interval must not halve the reported rate.
law window_normalization: {M.rate(3n,50n) == 60n : Nat}
# Guarantees: no simulated progress reports zero acceleration.
# Why it matters: rendered upgrade or paused frames do not advance game time.
law stopped: {M.speed(0n,1000n) == 0n : Nat}
# Guarantees: a zero-duration observation has no measured rate.
# Why it matters: startup must not display a rate from division by zero.
law no_elapsed_time: {M.rate(60n,0n) == 0n : Nat}
# Guarantees: an incomplete half-second window retains the startup placeholder.
# Why it matters: partial samples must not appear as a completed measurement.
law waits_for_window:
  {M.label(M.sample(400n,0,M.sample(1n,0,M.initial()))) == "FPS --  TPS --  SPEED --" : String}
# Guarantees: one frame and three ticks over half a second produce separate rates.
# Why it matters: the frame counter must not be mistaken for the simulation counter.
law first_window:
  {M.sample(501n,3,M.sample(1n,0,M.initial())) == M.State{501n,0n,3,"FPS 2  TPS 6  SPEED 0.1X"} : M.State}
