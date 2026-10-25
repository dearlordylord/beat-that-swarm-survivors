import Base
import game-components.bend as Components
import arena.bend as Arena
import combat-policy.bend as Combat
import enemy-lifecycle.bend as Life
import enemy-spatial.bend as Space
import loot-placement.bend as Placement
import persistent-xp.bend as XP

# Read-only enemy facts for one phase. Systems write the individual components.
type State is Data: State{spatial: Space.Spatial,archetype: U32,identity: U32,vitals: Components.Vitals,status: Components.Status}
type Phase is Data:
  Dormant{archetype: U32}
  ActiveEnemy{archetype: U32}
  OccupiedByLoot{}
type DropKind is Data: XpDrop{} GoldDrop{} HealDrop{} ChestDrop{}
# A death hands reward production named data; it never writes pickup storage.
type DeathReward is Data: DeathReward{kind: DropKind,amount: U32,x: F32,y: F32,archetype: U32,identity: U32,killer: Maybe<&2,U32>}
type Outcome is Data:
  Alive{enemy: State,contactDamage: U32}
  Killed{enemy: State,reward: DeathReward}
  Born{newborn: Life.Newborn}
  Sleeping{enemy: State}
type Effects is Data: Effects{damage: U32,freshSlow: U32,dx: F32,dy: F32}
def distance2(+x: F32,+y: F32,+px: F32,+py: F32) -> F32:
  ((x - px) * (x - px) + (y - py) * (y - py) : F32)
def contact(spatial: Space.Spatial,archetype: U32,px: F32,py: F32) -> U32:
  match spatial:
    case Space.Spatial{x,y,_,+radius}: (Bool.to_u32(F32.is_le(distance2(x,y,px,py),((radius + 10.0) * (radius + 10.0) : F32))) * (1 + 1000 * Bool.to_u32(U32.is_eq(archetype,30))) : U32)
def selected_drop(gold: Bool,heal: Bool) -> DropKind:
  match gold heal:
    case True{} _: GoldDrop{}
    case False{} True{}: HealDrop{}
    case False{} False{}: XpDrop{}
def normal_drop(+identity: U32) -> DropKind:
  selected_drop(U32.is_eq((identity % 17 : U32),0),U32.is_eq((identity % 41 : U32),0))
def lucky_drop(+identity: U32,+luck: U32) -> DropKind:
  selected_drop(U32.is_eq((identity % U32.max(3,(1700 / (100 + luck * 10 : U32) : U32)) : U32),0),U32.is_eq((identity % U32.max(7,(4100 / (100 + luck * 10 : U32) : U32)) : U32),0))
def selected_kind(boss: Bool,ordinary: Bool,identity: U32,luck: U32) -> DropKind:
  match boss ordinary:
    case True{} _: ChestDrop{}
    case False{} True{}: lucky_drop(identity,luck)
    case False{} False{}: normal_drop(identity)
def reward_kind(+archetype: U32,identity: U32,luck: U32) -> DropKind:
  selected_kind(Bool.and(U32.is_le(20,archetype),U32.is_le(archetype,29)),U32.is_lt(archetype,20),identity,luck)
def amount(kind: DropKind,archetype: U32) -> U32:
  match kind:
    case XpDrop{}: XP.drop_amount(archetype)
    case GoldDrop{}: (2 + U32.min(4,(archetype / 4 : U32)) : U32)
    case HealDrop{}: 25
    case ChestDrop{}: 1
def reward_with_kind(+kind: DropKind,+archetype: U32,identity: U32,x: F32,y: F32,killer: Maybe<&2,U32>) -> DeathReward:
  DeathReward{kind,amount(kind,archetype),Placement.place(x),Placement.place(y),archetype,identity,killer}
def reward(enemy: State,luck: U32,killer: Maybe<&2,U32>) -> DeathReward:
  match enemy:
    case State{Space.Spatial{x,y,_,_},+archetype,+identity,_,_}: reward_with_kind(reward_kind(archetype,identity,luck),archetype,identity,x,y,killer)
def resolved_health(health: U32,+spatial: Space.Spatial,+archetype: U32,+identity: U32,+maximum: U32,+status: Components.Status,luck: U32,px: F32,py: F32,killer: Maybe<&2,U32>) -> Outcome:
  match health:
    case 0: Killed{State{spatial,archetype,identity,Components.Vitals{0,maximum},status},reward(State{spatial,archetype,identity,Components.Vitals{0,maximum},status},luck,killer)}
    case health: Alive{State{spatial,archetype,identity,Components.Vitals{health,maximum},status},contact(spatial,archetype,px,py)}
def resolve(enemy: State,+oldX: F32,+oldY: F32,effects: Effects,nextStatus: Components.Status,oldBurnDamage: U32,luck: U32,px: F32,py: F32,killer: Maybe<&2,U32>) -> Outcome:
  match enemy effects:
    case State{Space.Spatial{x,y,age,+radius},archetype,identity,Components.Vitals{health,maximum},Components.Status{+slow,_}} Effects{damage,+freshSlow,dx,dy}:
      resolved_health(Combat.lose(health,(damage + oldBurnDamage : U32)),Space.Spatial{Arena.constrain((oldX + (x - oldX) * Space.slow_factor(U32.max(slow,freshSlow)) + dx : F32),radius),Arena.constrain((oldY + (y - oldY) * Space.slow_factor(U32.max(slow,freshSlow)) + dy : F32),radius),age,radius},archetype,identity,maximum,nextStatus,luck,px,py,killer)
def born(candidate: Life.Candidate) -> Outcome: Born{Life.birth(candidate)}

type Credit is Data: Credit{contactDamage: U32,kills: U32}
def newborn_state(newborn: Life.Newborn) -> State:
  match newborn:
    case Life.Newborn{Life.Candidate{x,y,archetype,identity,vitals,radius},age,status,_,_}: State{Space.Spatial{x,y,age,radius},archetype,identity,vitals,status}
def state(outcome: Outcome) -> State:
  match outcome:
    case Alive{enemy,_}: enemy
    case Killed{enemy,_}: enemy
    case Born{newborn}: newborn_state(newborn)
    case Sleeping{enemy}: enemy
def credit(outcome: Outcome) -> Credit:
  match outcome:
    case Alive{_,contactDamage}: Credit{contactDamage,0}
    case Killed{_,_}: Credit{0,1}
    case Born{Life.Newborn{_,_,_,contactDamage,_}}: Credit{contactDamage,0}
    case Sleeping{_}: Credit{0,0}
def active(phase: Phase) -> Bool:
  match phase:
    case ActiveEnemy{_}: True{}
    case _: False{}
def dormant(phase: Phase) -> Bool:
  match phase:
    case Dormant{_}: True{}
    case _: False{}
def archetype(phase: Phase) -> U32:
  match phase:
    case Dormant{archetype}: archetype
    case ActiveEnemy{archetype}: archetype
    case OccupiedByLoot{}: 0
