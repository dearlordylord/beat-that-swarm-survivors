# Admission clock is independent of the paused gameplay clock.
import Base

type Action is Data:
  Movement{x: U32,y: U32}
  MovementTick{round: U32,x: U32,y: U32}
  Choice{round: U32,index: U32}
  Setup{character: U32,arcana: U32,meta: U32,allowedWeapons: U32}
type Command is Data: Command{session: U32,player: U32,seq: U32,intendedTick: U32,action: Action}
type Lane is Data: Lane{lastSeq: U32,inputSeq: U32,appliedSeq: U32,appliedTick: U32,receivedAt: U32,x: U32,y: U32}
type State is Data: State{session: U32,clock: U32,host: Lane,guest: Lane,guestConnected: Bool,ended: Bool}
type Admission is Data: Admission{state: State,accepted: Bool,command: Command}
type Directions is Data: Directions{x0: F32,y0: F32,x1: F32,y1: F32}

def neutral() -> Lane: Lane{0,0,0,0,0,1,1}
def fresh(session: U32) -> State: State{session,0,neutral(),neutral(),True{},False{}}
def last_seq(lane: Lane) -> U32:
  match lane:
    case Lane{seq,_,_,_,_,_,_}: seq

def action_allowed(action: Action) -> Bool:
  match action:
    case Movement{x,y}: Bool.and(U32.is_le(x,2),U32.is_le(y,2))
    case MovementTick{_,x,y}: Bool.and(U32.is_le(x,2),U32.is_le(y,2))
    case Choice{round,index}: Bool.and(U32.is_gt(round,0),U32.is_lt(index,16))
    case Setup{character,arcana,_,allowed}: Bool.and(U32.is_lt(character,8),Bool.and(U32.is_lt(arcana,12),U32.is_le(allowed,16777215)))
def command_player(command: Command) -> U32:
  match command:
    case Command{_,player,_,_,_}: player
def lane_at(+player: U32,host: Lane,guest: Lane) -> Lane: Bool.pick(Lane,U32.is_eq(player,0),host,guest)
def valid_command(+state: State,+peer: U32,+command: Command) -> Bool:
  match state command:
    case State{session,_,host,guest,connected,ended} Command{claimed,+player,+seq,_,action}:
      Bool.and(Bool.not(ended),Bool.and(Bool.or(U32.is_eq(peer,0),connected),Bool.and(Bool.and(U32.is_eq(session,claimed),U32.is_eq(peer,player)),Bool.and(Bool.and(U32.is_le(player,1),Bool.or(U32.is_eq(player,0),connected)),Bool.and(U32.is_gt(seq,last_seq(lane_at(player,host,guest))),action_allowed(action))))))
def update_lane(action: Action,+seq: U32,clock: U32,lane: Lane) -> Lane:
  match action lane:
    case Movement{x,y} Lane{_,_,applied,tick,_,_,_}: Lane{seq,seq,applied,tick,clock,x,y}
    case _ Lane{_,input,applied,tick,received,x,y}: Lane{seq,input,applied,tick,received,x,y}
def admitted(command: Command,state: State) -> State:
  match command state:
    case Command{_,+player,+seq,_,+action} State{session,+clock,+host,+guest,connected,+ended}:
      State{session,clock,Bool.pick(Lane,U32.is_eq(player,0),update_lane(action,seq,clock,host),host),Bool.pick(Lane,U32.is_eq(player,1),update_lane(action,seq,clock,guest),guest),connected,ended}
def receive_decided(allowed: Bool,+state: State,+command: Command) -> Admission:
  match allowed:
    case False{}: Admission{state,False{},command}
    case True{}: Admission{admitted(command,state),True{},command}
def receive(+state: State,peer: U32,+command: Command) -> Admission: receive_decided(valid_command(state,peer,command),state,command)
def admission_state(result: Admission) -> State:
  match result:
    case Admission{state,_,_}: state
def accepted(result: Admission) -> Bool:
  match result:
    case Admission{_,accepted,_}: accepted

def expire_lane(+clock: U32,lane: Lane) -> Lane:
  match lane:
    case Lane{last,input,applied,tick,+received,x,y}:
      Lane{last,input,applied,tick,received,Bool.pick(U32,U32.is_ge((clock - received : U32),18),1,x),Bool.pick(U32,U32.is_ge((clock - received : U32),18),1,y)}
def clock(state: State) -> State:
  match state:
    case State{session,+now,host,guest,connected,ended}: State{session,(now + 1 : U32),expire_lane((now + 1 : U32),host),expire_lane((now + 1 : U32),guest),connected,ended}
def apply_lane(tick: U32,lane: Lane) -> Lane:
  match lane:
    case Lane{last,+input,+applied,priorTick,received,x,y}: Lane{last,input,input,Bool.pick(U32,U32.is_ne(input,applied),tick,priorTick),received,x,y}
def applied(+tick: U32,state: State) -> State:
  match state:
    case State{session,now,host,guest,connected,ended}: State{session,now,apply_lane(tick,host),apply_lane(tick,guest),connected,ended}
def axis(+value: U32) -> F32: Bool.pick(F32,U32.is_eq(value,0),(0.0 - 1.0 : F32),Bool.pick(F32,U32.is_eq(value,2),1.0,0.0))
def directions(state: State) -> Directions:
  match state:
    case State{_,_,Lane{_,_,_,_,_,x0,y0},Lane{_,_,_,_,_,x1,y1},+connected,+ended}:
      Directions{Bool.pick(F32,ended,0.0,axis(x0)),Bool.pick(F32,ended,0.0,axis(y0)),Bool.pick(F32,Bool.and(connected,Bool.not(ended)),axis(x1),0.0),Bool.pick(F32,Bool.and(connected,Bool.not(ended)),axis(y1),0.0)}
def disconnect(player: U32,state: State) -> State:
  match player state:
    case 0 State{session,now,host,guest,connected,_}: State{session,now,host,guest,connected,True{}}
    case 1 State{session,now,host,_,_,ended}: State{session,now,host,neutral(),False{},ended}
    case _ state: state

# Receipt describes consumed movement, never merely the newest received input.
# The worker updates it only after an authoritative gameplay step advanced.
type Receipt is Data: Receipt{seq: U32,steps: U32,x: U32,y: U32,expired: Bool}
def receipt_fresh() -> Receipt: Receipt{0,0,1,1,False{}}
def receipt_lane(previous: Receipt,lane: Lane,+clock: U32,+enabled: Bool) -> Receipt:
  match previous lane:
    case Receipt{prior,+steps,_,_,_} Lane{_,+seq,_,_,+received,x,y}:
      Receipt{seq,Bool.pick(U32,U32.is_eq(prior,seq),U32.min((steps + 1 : U32),65535),1),Bool.pick(U32,enabled,x,1),Bool.pick(U32,enabled,y,1),Bool.or(Bool.not(enabled),U32.is_ge((clock - received : U32),18))}
def receipt_step(previous: Receipt,state: State,+player: U32) -> Receipt:
  match state:
    case State{_,clock,host,guest,connected,+ended}: receipt_lane(previous,lane_at(player,host,guest),clock,Bool.and(Bool.not(ended),Bool.or(U32.is_eq(player,0),connected)))
