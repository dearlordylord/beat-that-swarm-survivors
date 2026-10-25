import Base
import enemy-effects.bend as Effect
import arena.bend as A
import encounters.bend as E

# Enemy/relic spatial state. Movement advances age exactly once per active tick;
# lifecycle initialization/reset writes the complete new spatial incarnation.
type Spatial is Data: Spatial{x: F32,y: F32,age: U32,radius: F32}
def slow_factor(value: Effect.Slow) -> F32:
  match value:
    case Effect.Slow{ticks,frozen}: E.choose_float(frozen,0.0,E.choose_float(U32.is_lt(0,ticks),0.35,1.0))
def moved(space: Spatial,intent: E.Intent,+factor: F32) -> Spatial:
  match space intent:
    case Spatial{+x,+y,age,+radius} E.Intent{vx,vy,_}: Spatial{A.constrain((x + vx * factor : F32),radius),A.constrain((y + vy * factor : F32),radius),(age + 1 : U32),radius}
def step(space: Spatial,+variant: U32,slow: Effect.Slow,tick: U32,+px: F32,+py: F32) -> Spatial:
  match space:
    case Spatial{+x,+y,+age,+radius}: moved(Spatial{x,y,age,radius},E.intent(variant,age,x,y,px,py),(E.choose_float(U32.is_eq(variant,30),1.0,slow_factor(slow)) * (1.10 + F32.min(0.60,(U32.to_f32(tick) / 60000.0 : F32)) + F32.min(4.0,(U32.to_f32(age) / 120.0 : F32)) * U32.to_f32(Bool.to_u32(U32.is_eq(variant,30)))) : F32))
def age(value: Spatial) -> U32:
  match value:
    case Spatial{_,_,age,_}: age
def radius(value: Spatial) -> F32:
  match value:
    case Spatial{_,_,_,radius}: radius
