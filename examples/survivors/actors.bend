import Base

# Independent map inhabitants. Phase is Body.variant; cooldown is Motion.life;
# positions are Body and health is Vitals. This module has no world authority.
type Actor is Data: Actor{x: F32,y: F32,hp: U32,age: U32,cooldown: U32,phase: U32,reward: U32}
def pick(test: Bool,yes: F32,no: F32) -> F32:
  match test:
    case True{}: yes
    case False{}: no
def amount(test: Bool,yes: U32,no: U32) -> U32:
  match test:
    case True{}: yes
    case False{}: no
def distance(+x: F32,+y: F32,+tx: F32,+ty: F32) -> F32: F32.sqrt(((tx - x) * (tx - x) + (ty - y) * (ty - y) : F32))
def direction(+x: F32,+y: F32) -> F32: (x / F32.max(1.0,F32.sqrt((x * x + y * y : F32))) : F32)
def spawn(+kind: U32,+slot: U32) -> Actor:
  Actor{(1800.0 + F32.cos((U32.to_f32(slot) * pick(U32.is_eq(kind,11),1.5707964,0.7853982) + pick(U32.is_eq(kind,11),0.4,0.0) : F32)) * pick(U32.is_eq(kind,11),230.0,(160.0 + U32.to_f32((slot % 3 : U32)) * 95.0 : F32)) : F32),(1800.0 + F32.sin((U32.to_f32(slot) * pick(U32.is_eq(kind,11),1.5707964,0.7853982) + pick(U32.is_eq(kind,11),0.4,0.0) : F32)) * pick(U32.is_eq(kind,11),230.0,(160.0 + U32.to_f32((slot % 3 : U32)) * 95.0 : F32)) : F32),amount(U32.is_eq(kind,11),160,80),0,(slot * 17 : U32),0,0}
def pulse(+kind: U32,+hp: U32,+phase: U32,cooldown: U32) -> Bool:
  Bool.and(U32.is_eq(kind,11),Bool.and(U32.is_lt(0,hp),Bool.and(U32.is_eq(phase,1),U32.is_eq(cooldown,0))))
def ward_radius() -> F32: 120.0
def ward_damage() -> U32: 24
def lost(+hp: U32,damage: U32) -> U32: U32.sub(hp,U32.min(hp,damage))
def surviving(+kind: U32,+seed: U32,+x: F32,+y: F32,+hp: U32,+age: U32,+cooldown: U32,+phase: U32,+ex: F32,+ey: F32,+enemyNear: Bool) -> Actor:
  Actor{F32.clamp((x + pick(Bool.and(U32.is_eq(kind,10),U32.is_eq(phase,1)),(direction((1800.0 - x : F32),(1800.0 - y : F32)) * 0.85 + pick(enemyNear,(direction((x - ex : F32),(y - ey : F32)) * 1.5 : F32),0.0) : F32),0.0) : F32),20.0,3580.0),F32.clamp((y + pick(Bool.and(U32.is_eq(kind,10),U32.is_eq(phase,1)),(direction((1800.0 - y : F32),(1800.0 - x : F32)) * 0.85 + pick(enemyNear,(direction((y - ey : F32),(x - ex : F32)) * 1.5 : F32),0.0) : F32),0.0) : F32),20.0,3580.0),lost(hp,(4 * Bool.to_u32(Bool.and(enemyNear,Bool.and(F32.is_lt(distance(x,y,ex,ey),28.0),U32.is_eq(((age + seed) % 60 : U32),0)))) : U32)),(age + 1 : U32),amount(pulse(kind,hp,phase,cooldown),90,lost(cooldown,1)),phase,0}
def resolve(rescued: Bool,+kind: U32,+seed: U32,+x: F32,+y: F32,+hp: U32,+age: U32,+cooldown: U32,+phase: U32,ex: F32,ey: F32,enemyNear: Bool) -> Actor:
  match rescued:
    case True{}: Actor{x,y,0,(age + 1 : U32),0,2,1}
    case False{}: surviving(kind,seed,x,y,hp,age,cooldown,phase,ex,ey,enemyNear)
def alive(living: Bool,+kind: U32,+seed: U32,+x: F32,+y: F32,+hp: U32,+age: U32,+cooldown: U32,+phase: U32,ex: F32,ey: F32,enemyNear: Bool) -> Actor:
  match living:
    case False{}: Actor{x,y,0,age,0,phase,0}
    case True{}: resolve(Bool.and(U32.is_eq(kind,10),Bool.and(U32.is_eq(phase,1),F32.is_lt(distance(x,y,1800.0,1800.0),18.0))),kind,seed,x,y,hp,age,cooldown,phase,ex,ey,enemyNear)
def step(+kind: U32,+seed: U32,+x: F32,+y: F32,+hp: U32,+age: U32,+cooldown: U32,+phase: U32,+px: F32,+py: F32,ex: F32,ey: F32,enemyNear: Bool) -> Actor:
  alive(U32.is_lt(0,hp),kind,seed,x,y,hp,age,cooldown,amount(Bool.and(U32.is_eq(phase,0),F32.is_lt(distance(x,y,px,py),100.0)),1,phase),ex,ey,enemyNear)
