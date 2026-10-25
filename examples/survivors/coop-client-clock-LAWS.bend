import Base
import ./coop-client-clock.bend as C

# Guarantees: A new clock starts at the supplied timestamp without scheduling credit.
# Why it matters: Joining a run cannot inherit elapsed time from another connection.
law fresh_exact:
  for +now:Nat
  {C.fresh(now) == C.State{now,0n} : C.State}

# Guarantees: The retained timestamp never chooses the older of two clock observations.
# Why it matters: A render callback sampled before a message callback cannot rewind local scheduling.
law latest_exact:
  for +now:Nat
  for +lastAt:Nat
  {C.latest(now,lastAt) == Nat.max(now,lastAt) : Nat}

# Guarantees: Only elapsed time after the retained timestamp contributes to the next budget.
# Why it matters: Repeated or regressing callback samples cannot spend elapsed time twice.
law elapsed_exact:
  for +now:Nat
  for +lastAt:Nat
  {C.elapsed(now,lastAt) == Nat.sub(Nat.max(now,lastAt),lastAt) : Nat}

# Guarantees: Elapsed microseconds are capped before multiplication, then sixty-unit credit is capped at four million.
# Why it matters: Returning from a background tab cannot schedule an unbounded catch-up loop.
law earned_exact:
  for +now:Nat
  for +lastAt:Nat
  {C.earned(now,lastAt) == Nat.min(Nat.mul(Nat.min(Nat.sub(Nat.max(now,lastAt),lastAt),66667n),60n),4000000n) : Nat}

# Guarantees: Only a sub-tick prior remainder joins the new capped elapsed credit.
# Why it matters: A retained or malformed oversized credit cannot create accumulated scheduling debt.
law total_exact:
  for +credit:Nat
  for +now:Nat
  for +lastAt:Nat
  {C.total(credit,now,lastAt) == Nat.add(Nat.min(credit,999999n),Nat.min(Nat.mul(Nat.min(Nat.sub(Nat.max(now,lastAt),lastAt),66667n),60n),4000000n)) : Nat}

# Guarantees: Each budget contains at most four whole million-unit ticks.
# Why it matters: The IO adapter executes a fixed bounded number of scheduling attempts.
law count_exact:
  for +credit:Nat
  {C.count(credit) == Nat.min(4n,Nat.div(credit,1000000n)) : Nat}

# Guarantees: The budget subtracts exactly the whole ticks returned to IO and stores the retained timestamp.
# Why it matters: Rendering and input callbacks cannot independently spend the same fractional credit.
law budget_exact:
  for +now:Nat
  for +credit:Nat
  {C.budget(now,credit) == C.Advance{C.State{now,Nat.sub(credit,Nat.mul(Nat.min(4n,Nat.div(credit,1000000n)),1000000n))},U32.from_nat(Nat.min(4n,Nat.div(credit,1000000n)))} : C.Advance}

# Guarantees: Public consumption uses the one clock timestamp and its capped credit policy.
# Why it matters: The production scheduling boundary cannot bypass the proved elapsed-time decisions.
law consume_exact:
  for +lastAt:Nat
  for +credit:Nat
  for +now:Nat
  {C.consume(C.State{lastAt,credit},now) == C.budget(Nat.max(now,lastAt),Nat.add(Nat.min(credit,999999n),Nat.min(Nat.mul(Nat.min(Nat.sub(Nat.max(now,lastAt),lastAt),66667n),60n),4000000n))) : C.Advance}

# Guarantees: A blocked-network discard removes all residual credit but keeps the timestamp.
# Why it matters: Retrying after backpressure must neither replay old elapsed time nor keep fractional debt.
law discard_exact:
  for +lastAt:Nat
  for credit:Nat
  {C.discard(C.State{lastAt,credit}) == C.State{lastAt,0n} : C.State}

# Guarantees: For every amount of scheduling credit the whole-step count is at most four.
# Why it matters: Even arbitrary oversized input cannot produce an unbounded IO scheduling loop.
law count_bounded:
  for credit:Nat
  {Nat.is_le(C.count(credit),4n) == True{} : Bool}
