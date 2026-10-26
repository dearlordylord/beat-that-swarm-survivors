import Base

type Mode is Data: Realtime{} Unlimited{}
def parse(text: String) -> Mode:
  match text:
    case "unlimited": Unlimited{}
    case _: Realtime{}
def ready(mode: Mode,now: Nat,last: Nat) -> Bool:
  match mode:
    case Unlimited{}: True{}
    case Realtime{}: Nat.is_le(16n,Nat.sub(now,last))
def render_due(now: Nat,last: Nat) -> Bool:
  match last:
    case 0n: True{}
    case 1n+rest: Nat.is_le(100n,Nat.sub(now,1n+rest))
