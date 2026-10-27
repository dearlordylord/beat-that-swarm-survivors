import starter-mechanics.bend as SM
import Base
import arena.bend as A
import encounters.bend as E
import projectile.bend as P
import combat-policy.bend as Combat
import enemy-spatial.bend as Space
import game-components.bend as Components

# Explicit read-set for a projectile update. This is an immutable phase value;
# authoritative storage keeps geometry, payload and trajectory independently.
type Side is Data: PlayerShot{} HostileShot{}
type State is Data: State{spatial: Space.Spatial,identity: U32,side: Side,payload: Components.ShotPayload,trajectory: Components.Trajectory}
type Outcome is Data: Outcome{projectile: State,contactDamage: U32}
type SpawnInput is Data: SpawnInput{tick: U32,px: F32,py: F32,dx: F32,dy: F32,tx: F32,ty: F32,damage: U32,speed: F32,area: F32,duration: F32}
type StepInput is Data: StepInput{px: F32,py: F32,tx: F32,ty: F32,reflect: Bool}
type Schedule is Data: Schedule{tick: U32,character: U32,weapons: List<&2,U32>,passives: List<&2,U32>,invulnerability: U32,arcana: U32,meta: U32,sourcePlayer: U32}

def schedule_tick(value: Schedule) -> U32:
  match value:
    case Schedule{tick,_,_,_,_,_,_,_}: tick

def empty_trajectory() -> Components.Trajectory: Components.Trajectory{0.0,0.0,0,0,[],0,0,None{}}
def dormant(x: F32,y: F32,identity: U32,side: Side) -> State: State{Space.Spatial{x,y,0,0.0},identity,side,Components.ShotPayload{0,0,False{},SM.ordinary()},empty_trajectory()}
def identity(state: State) -> U32:
  match state:
    case State{_,identity,_,_,_}: identity
def age(state: State) -> U32:
  match state:
    case State{Space.Spatial{_,_,age,_},_,_,_,_}: age
def damage(state: State) -> U32:
  match state:
    case State{_,_,_,Components.ShotPayload{_,damage,_,attack},_}: damage
def visited(state: State) -> List<&2,U32>:
  match state:
    case State{_,_,_,_,Components.Trajectory{_,_,_,_,visited,_,_,_}}: visited
def present(state: State) -> Bool:
  match state:
    case State{_,_,_,Components.ShotPayload{_,_,present,attack},_}: present

def source_player(state: State) -> Maybe<&2,U32>:
  match state:
    case State{_,_,_,_,Components.Trajectory{_,_,_,_,_,_,_,sourcePlayer}}: sourcePlayer
def attack(state: State) -> SM.Attack:
  match state:
    case State{_,_,_,Components.ShotPayload{_,_,_,attack},_}: attack
def with_attack(state: State,attack: SM.Attack) -> State:
  match state:
    case State{space,identity,side,Components.ShotPayload{weapon,damage,active,_},trajectory}: State{space,identity,side,Components.ShotPayload{weapon,damage,active,attack},trajectory}
def outward_fan(value: SM.Attack) -> Bool:
  match value:
    case SM.Attack{_,_,SM.Fan{_,_,False{}}}: True{}
    case _: False{}
def active(state: State) -> Bool:
  match state:
    case State{_,_,_,Components.ShotPayload{_,_,active,attack},Components.Trajectory{_,_,life,pierce,_,_,_,_}}: Bool.and(active,Bool.and(U32.is_lt(0,life),Bool.or(U32.is_lt(0,pierce),outward_fan(attack))))
def prepare(state: State,held: U32) -> State:
  match state:
    case State{Space.Spatial{+x,+y,+age,+radius},identity,side,Components.ShotPayload{weapon,damage,enabled,SM.Attack{cast,primary,SM.Fan{marks,+budget,False{}}}},Components.Trajectory{vx,vy,life,pierce,visited,owner,slot,source}}:
      State{Space.Spatial{x,y,age,radius},identity,side,Components.ShotPayload{weapon,damage,enabled,SM.Attack{cast,primary,SM.Fan{marks,budget,U32.is_le(45,age)}}},Components.Trajectory{vx,vy,life,Bool.pick(U32,U32.is_le(45,age),budget,pierce),Bool.pick(List<&2,U32>,U32.is_le(45,age),[],visited),owner,slot,source}}
    case State{space,identity,side,Components.ShotPayload{weapon,damage,enabled,SM.Attack{cast,primary,SM.Ink{+ticks,False{}}}},trajectory}:
      +next = Bool.pick(U32,U32.is_le(3,held),(ticks + 1 : U32),0)
      State{space,identity,side,Components.ShotPayload{weapon,damage,enabled,SM.Attack{cast,primary,SM.Ink{next,U32.is_le(60,next)}}},trajectory}
    case State{space,identity,side,Components.ShotPayload{weapon,damage,enabled,SM.Attack{cast,primary,SM.Ink{_,True{}}}},trajectory}: State{space,identity,side,Components.ShotPayload{weapon,damage,enabled,SM.Attack{cast,primary,SM.Ink{61,True{}}}},trajectory}
    case state: state
def hostile_active(state: State) -> Bool:
  match state:
    case State{_,_,_,_,Components.Trajectory{_,_,life,_,_,_,_,_}}: U32.is_lt(0,life)
def direction_x(+dx: F32,+dy: F32) -> F32: ((dx + U32.to_f32(Bool.to_u32(F32.is_lt((dx * dx + dy * dy : F32),0.01)))) / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32)
def direction_y(+dx: F32,+dy: F32) -> F32: (dy / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32)
def aim_direction_x(+dx: F32,+dy: F32,+px: F32,+py: F32,+tx: F32,+ty: F32) -> F32:
  E.choose_float(F32.is_lt((dx * dx + dy * dy : F32),0.01),P.aim_x(px,py,tx,ty),direction_x(dx,dy))
def aim_direction_y(+dx: F32,+dy: F32,+px: F32,+py: F32,+tx: F32,+ty: F32) -> F32:
  E.choose_float(F32.is_lt((dx * dx + dy * dy : F32),0.01),P.aim_y(px,py,tx,ty),direction_y(dx,dy))
def familiar_x(+weapon: U32,+owner: U32,+slot: U32,+px: F32,+tick: U32) -> F32:
  (px + E.choose_float(Bool.and(U32.is_eq(owner,21),Bool.not(U32.is_eq(weapon,21))),(F32.cos((U32.to_f32(tick) * 0.035 + U32.to_f32(slot) * 0.3926991 : F32)) * 80.0 : F32),0.0) : F32)
def familiar_y(+weapon: U32,+owner: U32,+slot: U32,+py: F32,+tick: U32) -> F32:
  (py + E.choose_float(Bool.and(U32.is_eq(owner,21),Bool.not(U32.is_eq(weapon,21))),(F32.sin((U32.to_f32(tick) * 0.035 + U32.to_f32(slot) * 0.3926991 : F32)) * 80.0 : F32),0.0) : F32)
def created(identity: U32,side: Side,weapon: U32,damage: U32,owner: U32,sourcePlayer: Maybe<&2,U32>,logicalSlot: U32,shot: P.Shot) -> State:
  match shot:
    case P.Shot{x,y,vx,vy,radius,life,pierce}: State{Space.Spatial{x,y,0,radius},identity,side,Components.ShotPayload{weapon,damage,True{},SM.ordinary()},Components.Trajectory{vx,vy,life,pierce,[],owner,logicalSlot,sourcePlayer}}
def spawn(+identity: U32,+weapon: U32,+level: U32,+owner: U32,+spread: U32,sourcePlayer: U32,logicalSlot: U32,input: SpawnInput) -> State:
  match input:
    case SpawnInput{+tick,+px,+py,+dx,+dy,+tx,+ty,damage,speed,area,duration}:
      created(identity,PlayerShot{},weapon,damage,owner,Some{sourcePlayer},logicalSlot,P.spawn(weapon,level,(spread * 2 : U32),familiar_x(weapon,owner,spread,px,tick),familiar_y(weapon,owner,spread,py,tick),tx,ty,aim_direction_x(dx,dy,px,py,tx,ty),aim_direction_y(dx,dy,px,py,tx,ty),speed,area,duration))
def ballistic(weapon: U32) -> Bool:
  match weapon:
    case 3: False{}
    case 4: False{}
    case 5: False{}
    case 7: False{}
    case 9: False{}
    case 11: False{}
    case 19: False{}
    case 20: False{}
    case 21: False{}
    case 22: False{}
    case _: True{}
def reflected(enabled: Bool,shot: P.Shot) -> P.Shot:
  match enabled shot:
    case False{} shot: shot
    case True{} P.Shot{+x,+y,+vx,+vy,+radius,+life,+pierce}: P.Shot{F32.clamp(x,20.0,(A.size() - 20.0 : F32)),F32.clamp(y,20.0,(A.size() - 20.0 : F32)),(vx * E.choose_float(Bool.or(F32.is_lt(x,20.0),F32.is_lt((A.size() - 20.0 : F32),x)),(0.0 - 1.0 : F32),1.0) : F32),(vy * E.choose_float(Bool.or(F32.is_lt(y,20.0),F32.is_lt((A.size() - 20.0 : F32),y)),(0.0 - 1.0 : F32),1.0) : F32),radius,life,pierce}
def next(state: State,input: StepInput) -> P.Shot:
  match state input:
    case State{Space.Spatial{x,y,+age,radius},_,_,Components.ShotPayload{+weapon,_,_,+attack},Components.Trajectory{vx,vy,life,pierce,_,_,_,_}} StepInput{px,py,tx,ty,reflect}:
      reflected(Bool.and(reflect,ballistic(weapon)),P.step(weapon,(age + 1 : U32),P.Shot{x,y,vx,vy,radius,life,pierce},px,py,tx,ty))
def survived(alive: Bool,identity: U32,side: Side,weapon: U32,damage: U32,age: U32,owner: U32,sourcePlayer: Maybe<&2,U32>,logicalSlot: U32,visited: List<&2,U32>,attack: SM.Attack,shot: P.Shot) -> Outcome:
  match alive shot:
    case False{} P.Shot{x,y,_,_,_,_,_}: Outcome{dormant(x,y,identity,side),0}
    case True{} P.Shot{x,y,vx,vy,radius,life,pierce}: Outcome{State{Space.Spatial{x,y,age,radius},identity,side,Components.ShotPayload{weapon,damage,True{},attack},Components.Trajectory{vx,vy,life,pierce,visited,owner,logicalSlot,sourcePlayer}},0}
def contacted_attack(value: SM.Attack,+hits: List<&2,U32>,+age: U32) -> SM.Attack:
  match value:
    case SM.Attack{cast,primary,SM.Fan{marks,budget,False{}}}: SM.Attack{cast,primary,SM.Fan{List.append(&2,U32,marks,hits),budget,False{}}}
    case SM.Attack{cast,primary,SM.Streak{credited}}: SM.Attack{cast,primary,SM.Streak{Bool.or(credited,U32.is_lt(0,U32.from_nat(List.length(&2,U32,hits))))}}
    case SM.Attack{cast,primary,SM.Trail{armed}}: SM.Attack{cast,primary,SM.Trail{Bool.or(armed,U32.is_le(25,age))}}
    case value: value
def contacted(state: State,+newHits: List<&2,U32>,shot: P.Shot) -> Outcome:
  match state shot:
    case State{Space.Spatial{_,_,+age,_},identity,side,Components.ShotPayload{+weapon,damage,_,+attack},Components.Trajectory{_,_,_,_,visited,owner,logicalSlot,+sourcePlayer}} P.Shot{+x,+y,+vx,+vy,+radius,+life,+pierce}:
      +cost = (U32.from_nat(List.length(&2,U32,newHits)) * Bool.to_u32(Bool.and(P.active_hit(weapon,age),U32.is_lt(pierce,9999))) : U32)
      +remaining = Combat.lose(pierce,cost)
      survived(Bool.and(U32.is_lt(0,life),Bool.or(U32.is_lt(0,remaining),outward_fan(attack))),identity,side,weapon,damage,(age + 1 : U32),owner,sourcePlayer,logicalSlot,List.append(&2,U32,visited,newHits),contacted_attack(attack,newHits,age),P.Shot{x,y,vx,vy,radius,life,remaining})
def step(+state: State,input: StepInput,newHits: List<&2,U32>) -> Outcome: contacted(state,newHits,next(state,input))
def hostile_spawn(identity: U32,+x: F32,+y: F32,+px: F32,+py: F32) -> State:
  created(identity,HostileShot{},0,8,0,None{},0,P.Shot{x,y,((px - x) / F32.max(1.0,F32.sqrt(((px - x) * (px - x) + (py - y) * (py - y) : F32))) * 3.5 : F32),((py - y) / F32.max(1.0,F32.sqrt(((px - x) * (px - x) + (py - y) * (py - y) : F32))) * 3.5 : F32),6.0,240,1})
def hostile_step(state: State,+px: F32,+py: F32) -> Outcome:
  match state:
    case State{Space.Spatial{+x,+y,age,+radius},identity,side,payload,Components.Trajectory{+vx,+vy,life,pierce,visited,owner,logicalSlot,+sourcePlayer}}:
      Outcome{State{Space.Spatial{(x + vx : F32),(y + vy : F32),(age + 1 : U32),radius},identity,side,payload,Components.Trajectory{vx,vy,P.dec(life),pierce,visited,owner,logicalSlot,sourcePlayer}},Bool.to_u32(F32.is_le(((px - x) * (px - x) + (py - y) * (py - y) : F32),((radius + 10.0) * (radius + 10.0) : F32)))}
