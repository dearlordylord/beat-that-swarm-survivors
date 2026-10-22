import Base

# Pure trajectories. The ECS owns identity, collision, damage and hit budgets.
type Shot is Data:
  Shot{x: F32,y: F32,vx: F32,vy: F32,radius: F32,life: U32,pierce: U32}

def dec(n: U32) -> U32:
  match n:
    case 0: 0
    case +n: (n - 1 : U32)
def norm(+x: F32,+y: F32) -> F32:
  F32.max(0.001,F32.sqrt((x * x + y * y : F32)))
def aim_x(+px: F32,py: F32,+tx: F32,ty: F32) -> F32:
  ((tx - px) / norm((tx - px : F32),(ty - py : F32)) : F32)
def aim_y(px: F32,+py: F32,tx: F32,+ty: F32) -> F32:
  ((ty - py) / norm((tx - px : F32),(ty - py : F32)) : F32)
def angle(slot: U32) -> F32:
  (U32.to_f32((slot % 16 : U32)) * 0.3926991 : F32)
def duration_life(base: U32,duration: F32) -> U32:
  U32.max(1,F32.to_u32((U32.to_f32(base) * F32.clamp(duration,0.1,20.0) : F32)))
def moving(+px: F32,+py: F32,+tx: F32,+ty: F32,+speed: F32,radius: F32,life: U32,pierce: U32) -> Shot:
  Shot{px,py,(aim_x(px,py,tx,ty) * speed : F32),(aim_y(px,py,tx,ty) * speed : F32),radius,life,pierce}
def directed(px: F32,py: F32,+dx: F32,+dy: F32,+slot: U32,+speed: F32,radius: F32,life: U32,pierce: U32) -> Shot:
  Shot{px,py,((dx * F32.cos(angle(slot)) - dy * F32.sin(angle(slot))) * speed : F32),((dx * F32.sin(angle(slot)) + dy * F32.cos(angle(slot))) * speed : F32),radius,life,pierce}
def field(x: F32,y: F32,radius: F32,life: U32) -> Shot:
  Shot{x,y,0.0,0.0,radius,life,9999}
def orbit(+slot: U32,+px: F32,+py: F32,+distance: F32,radius: F32,life: U32) -> Shot:
  Shot{(px + F32.cos(angle(slot)) * distance : F32),(py + F32.sin(angle(slot)) * distance : F32),angle(slot),distance,radius,life,9999}

# IDs match content.mjs. Slot is a deterministic spread / orbit phase, not RNG.
def spawn(id: U32,+level: U32,+slot: U32,+px: F32,+py: F32,+tx: F32,+ty: F32,+dx: F32,+dy: F32,+speed: F32,+area: F32,+duration: F32) -> Shot:
  match id:
    case 0: moving(px,py,tx,ty,(7.5 * speed : F32),(5.0 * area : F32),duration_life(100,duration),(1 + level / 3 : U32))
    case 1: directed(px,py,dx,dy,(slot % 3 : U32),(11.0 * speed : F32),(4.0 * area : F32),duration_life(75,duration),(2 + level / 2 : U32))
    case 2: Shot{px,py,((U32.to_f32((slot % 5 : U32)) - 2.0) * 1.7 * speed : F32),((0.0 - 8.0) * speed : F32),(14.0 * area : F32),duration_life(110,duration),(5 + level : U32)}
    case 3: orbit(slot,px,py,(75.0 * area : F32),(13.0 * area : F32),duration_life(210,duration))
    case 4: field(px,py,((42.0 + U32.to_f32(level) * 3.0) * area : F32),duration_life(90,duration))
    case 5: field(tx,ty,(23.0 * area : F32),duration_life(18,duration))
    case 6: moving(px,py,tx,ty,(5.5 * speed : F32),(17.0 * area : F32),duration_life(140,duration),(5 + level : U32))
    case 7: field(tx,ty,(49.0 * area : F32),duration_life(170,duration))
    case 8: directed(px,py,dx,dy,(slot % 4 : U32),(6.0 * speed : F32),(13.0 * area : F32),duration_life(130,duration),(10 + level : U32))
    case 9: field((px + F32.cos(angle(slot)) * 110.0 : F32),(py + F32.sin(angle(slot)) * 110.0 : F32),(44.0 * area : F32),duration_life(65,duration))
    case 10: moving(px,py,tx,ty,(10.0 * speed : F32),(7.0 * area : F32),duration_life(90,duration),(2 + level / 2 : U32))
    case 11: field(px,py,(850.0 * area : F32),1)
    case 12: directed(px,py,dx,dy,0,(8.0 * speed : F32),(35.0 * area : F32),duration_life(13,duration),9999)
    case 13: directed(px,py,dx,dy,(slot % 2 : U32),(14.0 * speed : F32),(10.0 * area : F32),duration_life(24,duration),(15 + level : U32))
    case 14: moving(px,py,tx,ty,(3.0 * speed : F32),(8.0 * area : F32),duration_life(70,duration),9999)
    case 15: directed(px,py,F32.cos(angle(slot)),F32.sin(angle(slot)),0,(5.0 * speed : F32),(20.0 * area : F32),duration_life(170,duration),9999)
    case 16: moving(px,py,tx,ty,(4.0 * speed : F32),(6.0 * area : F32),duration_life(170,duration),(2 + level / 3 : U32))
    case 17: Shot{tx,(ty - 240.0 : F32),0.0,(12.0 * speed : F32),(13.0 * area : F32),duration_life(55,duration),9999}
    case 18: moving(px,py,tx,ty,(27.0 * speed : F32),(15.0 * area : F32),duration_life(25,duration),9999)
    case 19: orbit(slot,px,py,(55.0 * area : F32),(24.0 * area : F32),duration_life(160,duration))
    case 20: field(tx,ty,(68.0 * area : F32),duration_life(140,duration))
    case 21: orbit(slot,px,py,80.0,(14.0 * area : F32),duration_life(240,duration))
    case 22: field(px,py,(37.0 * area : F32),duration_life(260,duration))
    case _: directed(px,py,F32.cos(angle(slot)),F32.sin(angle(slot)),0,(8.0 * speed : F32),(7.0 * area : F32),duration_life(110,duration),(2 + level / 2 : U32))

def travel(shot: Shot) -> Shot:
  match shot:
    case Shot{+x,+y,+vx,+vy,radius,life,pierce}: Shot{(x + vx : F32),(y + vy : F32),vx,vy,radius,dec(life),pierce}
def gravity(shot: Shot) -> Shot:
  match shot:
    case Shot{+x,+y,+vx,+vy,radius,life,pierce}: Shot{(x + vx : F32),(y + vy : F32),vx,(vy + 0.18 : F32),radius,dec(life),pierce}
def stationary(shot: Shot) -> Shot:
  match shot:
    case Shot{x,y,vx,vy,radius,life,pierce}: Shot{x,y,vx,vy,radius,dec(life),pierce}
def anchored(shot: Shot,px: F32,py: F32) -> Shot:
  match shot:
    case Shot{_,_,vx,vy,radius,life,pierce}: Shot{px,py,vx,vy,radius,dec(life),pierce}
def orbit_step(shot: Shot,+age: U32,+px: F32,+py: F32,+rate: F32) -> Shot:
  match shot:
    case Shot{_,_,+phase,+distance,radius,life,pierce}: Shot{(px + F32.cos((U32.to_f32(age) * rate + phase : F32)) * distance : F32),(py + F32.sin((U32.to_f32(age) * rate + phase : F32)) * distance : F32),phase,distance,radius,dec(life),pierce}
def home(shot: Shot,+tx: F32,+ty: F32) -> Shot:
  match shot:
    case Shot{+x,+y,+vx,+vy,radius,life,pierce}: Shot{(x + vx : F32),(y + vy : F32),(vx * 0.88 + aim_x(x,y,tx,ty) * norm(vx,vy) * 0.12 : F32),(vy * 0.88 + aim_y(x,y,tx,ty) * norm(vx,vy) * 0.12 : F32),radius,dec(life),pierce}
def return_step(returning: Bool,shot: Shot,px: F32,py: F32) -> Shot:
  match returning:
    case False{}: travel(shot)
    case True{}: home(shot,px,py)
def bomb_step(exploded: Bool,shot: Shot) -> Shot:
  match exploded shot:
    case True{} Shot{x,y,_,_,+radius,life,pierce}: Shot{x,y,0.0,0.0,(radius * 8.0 : F32),dec(life),pierce}
    case False{} +shot: stationary(shot)
def bomb_phase(waiting: Bool,+age: U32,shot: Shot) -> Shot:
  match waiting:
    case True{}: travel(shot)
    case False{}: bomb_step(U32.is_eq(age,30),shot)
def meteor_step(landed: Bool,shot: Shot) -> Shot:
  match landed shot:
    case True{} Shot{x,y,_,_,+radius,life,pierce}: Shot{x,y,0.0,0.0,(radius * 6.0 : F32),dec(life),pierce}
    case False{} +shot: stationary(shot)
def meteor_phase(waiting: Bool,+age: U32,shot: Shot) -> Shot:
  match waiting:
    case True{}: travel(shot)
    case False{}: meteor_step(U32.is_eq(age,20),shot)

def step(id: U32,+age: U32,shot: Shot,+px: F32,+py: F32,+tx: F32,+ty: F32) -> Shot:
  match id:
    case 0: home(shot,tx,ty)
    case 2: gravity(shot)
    case 3: orbit_step(shot,age,px,py,0.055)
    case 4: anchored(shot,px,py)
    case 5: stationary(shot)
    case 7: stationary(shot)
    case 8: return_step(U32.is_le(45,age),shot,px,py)
    case 9: stationary(shot)
    case 11: anchored(shot,px,py)
    case 14: bomb_phase(U32.is_lt(age,30),age,shot)
    case 16: home(shot,tx,ty)
    case 17: meteor_phase(U32.is_lt(age,20),age,shot)
    case 19: orbit_step(shot,age,px,py,0.027)
    case 20: stationary(shot)
    case 21: orbit_step(shot,age,px,py,0.035)
    case 22: stationary(shot)
    case _: travel(shot)

# Cadence is per projectile age. Single contacts still consume ECS pierce budget.
def active_hit(id: U32,+age: U32) -> Bool:
  match id:
    case 3: U32.is_eq((age % 15 : U32),0)
    case 4: U32.is_eq((age % 24 : U32),0)
    case 5: U32.is_eq(age,0)
    case 7: U32.is_eq((age % 20 : U32),0)
    case 9: U32.is_eq((age % 30 : U32),0)
    case 11: U32.is_eq(age,0)
    case 14: U32.is_eq(age,30)
    case 17: U32.is_eq(age,20)
    case 19: U32.is_eq((age % 20 : U32),0)
    case 20: U32.is_eq((age % 12 : U32),0)
    case 21: U32.is_eq((age % 25 : U32),0)
    case 22: Bool.and(U32.is_le(25,age),U32.is_eq((age % 45 : U32),25))
    case _: True{}

def status(id: U32) -> U32:
  match id:
    case 2: 5
    case 5: 2
    case 6: 3
    case 10: 1
    case 12: 5
    case 17: 3
    case 19: 5
    case 20: 4
    case 22: 2
    case _: 0
