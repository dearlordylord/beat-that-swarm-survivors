import Base

type State is Data: State{clock: Nat,frames: Nat,tick: U32,label: String}
def initial() -> State: State{0n,0n,0,"FPS --  TPS --  SPEED --"}
def label(state: State) -> String:
  match state:
    case State{_,_,_,text}: text
def positive_ratio(numerator: Nat,+span: Nat) -> Nat:
  Nat.div(Nat.add(numerator,Nat.div(span,2n)),span)
def rounded(numerator: Nat,span: Nat) -> Nat:
  match span:
    case 0n: 0n
    case 1n+rest: positive_ratio(numerator,1n+rest)
def rate(count: Nat,span: Nat) -> Nat: rounded(Nat.mul(count,1000n),span)
def speed(ticks: Nat,span: Nat) -> Nat: rounded(Nat.mul(ticks,500n),Nat.mul(span,3n))
def speed_label(+tenths: Nat) -> String:
  Nat.show(Nat.div(tenths,10n)) ++ "." ++ Nat.show(Nat.mod(tenths,10n)) ++ "X"
def measured(frames: Nat,+ticks: Nat,+span: Nat) -> String:
  "FPS " ++ Nat.show(rate(frames,span)) ++ "  TPS " ++ Nat.show(rate(ticks,span)) ++ "  SPEED " ++ speed_label(speed(ticks,span))
def sampled(enough: Bool,now: Nat,+tick: U32,clock: Nat,frames: Nat,previous: U32,text: String,span: Nat) -> State:
  match enough:
    case False{}: State{clock,frames,previous,text}
    case True{}: State{now,0n,tick,measured(frames,Nat.sub(U32.to_nat(tick),U32.to_nat(previous)),span)}
def sample(+now: Nat,+tick: U32,state: State) -> State:
  match state:
    case State{0n,_,_,text}: State{now,0n,tick,text}
    case State{+clock,frames,previous,text}:
      +span=Nat.sub(now,clock)
      sampled(Nat.is_le(500n,span),now,tick,clock,1n+frames,previous,text,span)
