import Base
import enemy-spatial.bend as Space

# Payload meaning is fixed by its constructor, never by a health field or role.
# Geometry lives in the spatial column; State is a read-only phase observation.
type Item is Data:
  Xp{amount: U32,accumulator: Bool}
  Gold{coins: U32}
  Healing{health: U32}
  Chest{}
  Relic{stage: U32}
type Payload is Data: Payload{item: Item,generation: U32,active: Bool}
type State is Data: State{spatial: Space.Spatial,payload: Payload,identity: U32}
type Reward is Data: Reward{xp: U32,coins: U32,healing: U32,chests: U32,relics: U32}
type Outcome is Data: Outcome{state: State,reward: Reward}

def no_reward() -> Reward: Reward{0,0,0,0,0}
def reward(item: Item) -> Reward:
  match item:
    case Xp{amount,_}: Reward{amount,0,0,0,0}
    case Gold{coins}: Reward{0,coins,0,0,0}
    case Healing{health}: Reward{0,0,health,0,0}
    case Chest{}: Reward{0,0,0,1,0}
    case Relic{_}: Reward{50,75,0,0,1}
def consumed(item: Item) -> Item:
  match item:
    case Xp{_,accumulator}: Xp{0,accumulator}
    case item: item
def retired(space: Space.Spatial) -> Space.Spatial:
  match space:
    case Space.Spatial{x,y,_,_}: Space.Spatial{x,y,0,0.0}
def waiting(item: Item,space: Space.Spatial) -> Space.Spatial:
  match item space:
    case Relic{_} Space.Spatial{x,y,_,radius}: Space.Spatial{x,y,0,radius}
    case _ Space.Spatial{x,y,age,radius}: Space.Spatial{x,y,(age + 1 : U32),radius}
def collected(found: Bool,space: Space.Spatial,+item: Item,+slot: U32,+generation: U32) -> Outcome:
  match found:
    case True{}: Outcome{State{retired(space),Payload{consumed(item),generation,False{}},slot},reward(item)}
    case False{}: Outcome{State{waiting(item,space),Payload{item,generation,True{}},slot},no_reward()}
def step(found: Bool,state: State) -> Outcome:
  match state:
    case State{space,Payload{item,generation,True{}},slot}: collected(found,space,item,slot,generation)
    case state: Outcome{state,no_reward()}
def active(state: State) -> Bool:
  match state:
    case State{_,Payload{_,_,active},_}: active
def slot(state: State) -> U32:
  match state:
    case State{_,_,slot}: slot
def generation(state: State) -> U32:
  match state:
    case State{_,Payload{_,generation,_},_}: generation
def amount(state: State) -> U32:
  match state:
    case State{_,Payload{Xp{amount,_},_,True{}},_}: amount
    case _: 0
def accumulator(state: State) -> Bool:
  match state:
    case State{_,Payload{Xp{_,marked},_,True{}},_}: marked
    case _: False{}
def with_space(state: State,space: Space.Spatial) -> State:
  match state:
    case State{_,payload,identity}: State{space,payload,identity}
