import Base

type Slow is Data: Slow{ticks: U32,frozen: Bool}
type Burn is Data: Burn{ticks: U32,sourcePlayer: Maybe<&2,U32>}

def empty_slow() -> Slow: Slow{0,False{}}
def empty_burn() -> Burn: Burn{0,None{}}
def dec(+ticks: U32) -> U32: U32.sub(ticks,U32.min(ticks,1))
def slow_ticks(value: Slow) -> U32:
  match value:
    case Slow{ticks,_}: ticks
def burn_ticks(value: Burn) -> U32:
  match value:
    case Burn{ticks,_}: ticks
def slow_active(value: Slow) -> Bool:
  match value:
    case Slow{ticks,frozen}: Bool.or(frozen,U32.is_lt(0,ticks))
def burn_active(value: Burn) -> Bool: U32.is_lt(0,burn_ticks(value))
def cool_slow(value: Slow) -> Slow:
  match value:
    case Slow{+ticks,frozen}: Slow{dec(ticks),Bool.and(frozen,U32.is_lt(1,ticks))}
def stronger_slow(+old: Slow,+fresh: Slow) -> Slow:
  match old fresh:
    case Slow{oldTicks,oldFrozen} Slow{freshTicks,freshFrozen}: Bool.pick(Slow,Bool.or(Bool.and(freshFrozen,Bool.not(oldFrozen)),Bool.and(U32.is_eq(Bool.to_u32(oldFrozen),Bool.to_u32(freshFrozen)),U32.is_lt(oldTicks,freshTicks))),fresh,old)
def burn(ticks: U32,player: U32) -> Burn:
  match ticks:
    case 0: empty_burn()
    case ticks: Burn{ticks,Some{player}}
def cool_burn(value: Burn) -> Burn:
  match value:
    case Burn{+ticks,source}: Bool.pick(Burn,U32.is_lt(1,ticks),Burn{dec(ticks),source},empty_burn())
def source_before(fresh: Maybe<&2,U32>,old: Maybe<&2,U32>) -> Bool:
  match fresh old:
    case Some{fresh} Some{old}: U32.is_lt(fresh,old)
    case _ _: False{}
def stronger_burn(+old: Burn,+fresh: Burn) -> Burn:
  match old fresh:
    case Burn{oldTicks,oldSource} Burn{freshTicks,freshSource}: Bool.pick(Burn,Bool.or(U32.is_lt(oldTicks,freshTicks),Bool.and(U32.is_eq(oldTicks,freshTicks),source_before(freshSource,oldSource))),fresh,old)
def source(value: Burn) -> Maybe<&2,U32>:
  match value:
    case Burn{_,sourcePlayer}: sourcePlayer
def slow_from_status(+code: U32) -> Slow:
  Slow{(90 * Bool.to_u32(Bool.or(U32.is_eq(code,1),U32.is_eq(code,2))) : U32),U32.is_eq(code,2)}
