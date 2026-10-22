import Base

# All velocities are world units per 60 Hz tick. No host AI is required.
type Intent is Data: Intent{vx: F32,vy: F32,fire: Bool}

def magnitude(+x: F32,+y: F32) -> F32:
  F32.max(0.01,F32.sqrt((x * x + y * y : F32)))
def distance(+x: F32,+y: F32,+px: F32,+py: F32) -> F32:
  magnitude((px - x : F32),(py - y : F32))
def seek(+x: F32,+y: F32,+px: F32,+py: F32,+speed: F32,fire: Bool) -> Intent:
  Intent{((px - x) / distance(x,y,px,py) * speed : F32),((py - y) / distance(x,y,px,py) * speed : F32),fire}
def choose_float(test: Bool,yes: F32,no: F32) -> F32:
  match test:
    case True{}: yes
    case False{}: no
def cadence(+age: U32,period: U32) -> Bool:
  Bool.and(U32.is_lt(30,age),U32.is_eq((age % period : U32),0))
def ranged_speed(+range: F32,near: F32,far: F32) -> F32:
  choose_float(F32.is_lt(range,near),(0.0 - 0.65 : F32),choose_float(F32.is_lt(far,range),0.85,0.0))
def ranged(+x: F32,+y: F32,+px: F32,+py: F32,age: U32,period: U32,near: F32,far: F32) -> Intent:
  seek(x,y,px,py,ranged_speed(distance(x,y,px,py),near,far),cadence(age,period))
def strafe(+x: F32,+y: F32,+px: F32,+py: F32,+speed: F32,+side: F32,fire: Bool) -> Intent:
  Intent{(((px - x) * speed - (py - y) * side) / distance(x,y,px,py) : F32),(((py - y) * speed + (px - x) * side) / distance(x,y,px,py) : F32),fire}
def charge_speed(+phase: U32,walk: F32) -> F32:
  choose_float(U32.is_lt(phase,90),walk,choose_float(U32.is_lt(phase,120),0.0,3.8))
def charging(phase: U32,+x: F32,+y: F32,+px: F32,+py: F32,walk: F32,fire: Bool) -> Intent:
  seek(x,y,px,py,charge_speed(phase,walk),fire)

def grave(roll: U32) -> U32:
  match roll:
    case 0: 0
    case 1: 1
    case 2: 2
    case 3: 5
    case 4: 9
    case _: 19
def library(roll: U32) -> U32:
  match roll:
    case 0: 0
    case 1: 6
    case 2: 7
    case 3: 9
    case 4: 10
    case _: 11
def marsh(roll: U32) -> U32:
  match roll:
    case 0: 3
    case 1: 6
    case 2: 8
    case 3: 14
    case 4: 17
    case _: 18
def frost(roll: U32) -> U32:
  match roll:
    case 0: 1
    case 1: 4
    case 2: 7
    case 3: 12
    case 4: 15
    case _: 16
def inferno(roll: U32) -> U32:
  match roll:
    case 0: 8
    case 1: 10
    case 2: 13
    case 3: 5
    case 4: 16
    case _: 19
def roster(stage: U32,roll: U32) -> U32:
  match stage:
    case 0: grave(roll)
    case 1: library(roll)
    case 2: marsh(roll)
    case 3: frost(roll)
    case _: inferno(roll)
def variant(stage: U32,+tick: U32,seed: U32) -> U32:
  roster(stage,((seed * 17 + tick / 600) % U32.min(6,(3 + tick / 5400 : U32)) : U32))

def base_health(v: U32) -> U32:
  match v:
    case 0: 22
    case 1: 9
    case 2: 42
    case 3: 35
    case 4: 28
    case 5: 110
    case 6: 12
    case 7: 30
    case 8: 18
    case 9: 27
    case 10: 38
    case 11: 100
    case 12: 140
    case 13: 24
    case 14: 48
    case 15: 39
    case 16: 240
    case 17: 8
    case 18: 190
    case 19: 95
    case 25: 3200
    case 29: 4200
    case +v: (900 + (v % 20) * 180 : U32)
def health(v: U32,+tick: U32,stage: U32) -> U32:
  (base_health(v) * (100 + tick / 60 + (tick / 3600) * (tick / 3600) * 4 + stage * 18) / 100 : U32)
def radius(v: U32) -> F32:
  match v:
    case 1: 8.0
    case 6: 7.0
    case 8: 8.0
    case 17: 6.0
    case 16: 23.0
    case 18: 21.0
    case 25: 42.0
    case 29: 34.0
    case 30: 36.0
    case +v: choose_float(U32.is_le(20,v),27.0,12.0)

def final_boss(phase: U32,+age: U32,+x: F32,+y: F32,+px: F32,+py: F32) -> Intent:
  match phase:
    case 0: seek(x,y,px,py,1.15,cadence(age,90))
    case 1: strafe(x,y,px,py,0.25,1.8,cadence(age,35))
    case _: charging((age % 180 : U32),x,y,px,py,0.65,cadence(age,60))

# Pursuit, wind-up, range control, flanking and firing are separate roles.
# Age is per entity, so different spawn times naturally stagger volleys.
def intent(v: U32,+age: U32,+x: F32,+y: F32,+px: F32,+py: F32) -> Intent:
  match v:
    case 0: seek(x,y,px,py,0.65,False{})
    case 1: strafe(x,y,px,py,1.35,(F32.sin((U32.to_f32(age) * 0.12 : F32)) * 0.7 : F32),False{})
    case 2: seek(x,y,px,py,0.36,False{})
    case 3: seek(x,y,px,py,choose_float(U32.is_lt((age % 100 : U32),65),0.12,1.55),False{})
    case 4: charging((age % 150 : U32),x,y,px,py,0.95,False{})
    case 5: seek(x,y,px,py,0.42,False{})
    case 6: strafe(x,y,px,py,1.3,0.7,False{})
    case 7: strafe(x,y,px,py,0.65,(0.0 - 0.95 : F32),False{})
    case 8: strafe(x,y,px,py,0.95,choose_float(U32.is_lt((age % 120 : U32),60),1.1,(0.0 - 1.1 : F32)),False{})
    case 9: ranged(x,y,px,py,age,120,170.0,260.0)
    case 10: ranged(x,y,px,py,age,85,210.0,310.0)
    case 11: seek(x,y,px,py,choose_float(U32.is_lt(age,100),0.0,1.65),False{})
    case 12: charging((age % 210 : U32),x,y,px,py,0.3,cadence(age,180))
    case 13: strafe(x,y,px,py,0.55,1.0,cadence(age,100))
    case 14: ranged(x,y,px,py,age,150,150.0,230.0)
    case 15: strafe(x,y,px,py,0.85,(0.0 - 1.6 : F32),cadence(age,160))
    case 16: seek(x,y,px,py,0.23,cadence(age,240))
    case 17: seek(x,y,px,py,1.8,False{})
    case 18: seek(x,y,px,py,0.18,cadence(age,180))
    case 19: charging((age % 170 : U32),x,y,px,py,1.1,cadence(age,125))
    case 20: charging((age % 180 : U32),x,y,px,py,0.55,cadence(age,150))
    case 21: strafe(x,y,px,py,ranged_speed(distance(x,y,px,py),210.0,290.0),1.1,cadence(age,55))
    case 22: seek(x,y,px,py,choose_float(U32.is_lt((age % 240 : U32),180),0.28,2.2),cadence(age,75))
    case 23: charging((age % 165 : U32),x,y,px,py,0.6,cadence(age,90))
    case 24: strafe(x,y,px,py,ranged_speed(distance(x,y,px,py),170.0,260.0),(0.0 - 1.2 : F32),cadence(age,40))
    case 25: charging((age % 360 : U32),x,y,px,py,0.13,cadence(age,240))
    case 26: strafe(x,y,px,py,0.8,1.7,cadence(age,45))
    case 27: ranged(x,y,px,py,age,30,270.0,370.0)
    case 28: charging((age % 240 : U32),x,y,px,py,ranged_speed(distance(x,y,px,py),130.0,190.0),cadence(age,70))
    case 30: seek(x,y,px,py,1.0,False{})
    case _: final_boss(((age / 240) % 3 : U32),age,x,y,px,py)

# Hazards have stationary readable zones and global, sparse pulse times.
# The central 180-unit cross is always safe; player spawn is (1800,1800).
# Call every tick. Damage is a single integer pulse, never damage per frame.
def hazard_zone(stage: U32,+tick: U32,+x: F32,+y: F32) -> Bool:
  match stage:
    case 0: Bool.and(U32.is_eq((tick % 360 : U32),300),Bool.and(U32.is_lt((F32.to_u32(x) % 480 : U32),65),U32.is_lt((F32.to_u32(y) % 480 : U32),65)))
    case 1: Bool.and(U32.is_eq((tick % 420 : U32),360),Bool.and(U32.is_lt((F32.to_u32(x) % 640 : U32),70),U32.is_lt(150,(F32.to_u32(y) % 640 : U32))))
    case 2: Bool.and(U32.is_eq((tick % 240 : U32),180),Bool.and(U32.is_lt(240,(F32.to_u32(x) % 400 : U32)),U32.is_lt(240,(F32.to_u32(y) % 400 : U32))))
    case 3: Bool.and(U32.is_eq((tick % 300 : U32),240),U32.is_lt(((F32.to_u32(x) + F32.to_u32(y)) % 700 : U32),95))
    case _: Bool.and(U32.is_eq((tick % 180 : U32),120),Bool.and(U32.is_lt((F32.to_u32(x) % 520 : U32),100),U32.is_lt((F32.to_u32(y) % 520 : U32),160)))
def hazard(+stage: U32,+tick: U32,+x: F32,+y: F32) -> U32:
  (Bool.to_u32(Bool.and(U32.is_lt(600,tick),Bool.and(F32.is_lt(90.0,F32.abs((x - 1800.0 : F32))),Bool.and(F32.is_lt(90.0,F32.abs((y - 1800.0 : F32))),hazard_zone(stage,tick,x,y))))) * (2 + stage) : U32)
