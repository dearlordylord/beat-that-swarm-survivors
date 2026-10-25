import Base

# One local monotonic microsecond clock supplies bounded 60Hz scheduling credit.
# IO owns reading time; this model owns elapsed-time admission and step budget.
type State is Data: State{lastAt:Nat,credit:Nat}
type Advance is Data: Advance{state:State,steps:U32}
def fresh(now:Nat) -> State: State{now,0n}
def latest(+now:Nat,+lastAt:Nat) -> Nat: Nat.max(now,lastAt)
def elapsed(+now:Nat,+lastAt:Nat) -> Nat: Nat.sub(Nat.max(now,lastAt),lastAt)
def earned(now:Nat,lastAt:Nat) -> Nat: Nat.min(Nat.mul(Nat.min(elapsed(now,lastAt),66667n),60n),4000000n)
def total(credit:Nat,now:Nat,lastAt:Nat) -> Nat: Nat.add(Nat.min(credit,999999n),earned(now,lastAt))
def count(credit:Nat) -> Nat: Nat.min(4n,Nat.div(credit,1000000n))
def budget(now:Nat,+credit:Nat) -> Advance:
  Advance{State{now,Nat.sub(credit,Nat.mul(count(credit),1000000n))},U32.from_nat(count(credit))}
def consume(state:State,+now:Nat) -> Advance:
  match state:
    case State{+lastAt,credit}: budget(latest(now,lastAt),total(credit,now,lastAt))
def discard(state:State) -> State:
  match state:
    case State{lastAt,_}: State{lastAt,0n}
