import Base
import ./coop-session.bend as S

# Guarantees: a confirmed guest departure prevents further guest commands, regardless of payload.
# Why it matters: a departing guest cannot continue moving or choosing rewards.
law departed_guest_denied:
  for state: S.State
  for command: S.Command
  {S.valid_command(S.disconnect(1,state),1,command) == False{} : Bool}

# Guarantees: ending the host session denies all commands, regardless of claimed identity.
# Why it matters: host exit cannot leave a live authoritative simulation behind.
law ended_denied:
  for state: S.State
  for peer: U32
  for command: S.Command
  {S.valid_command(S.disconnect(0,state),peer,command) == False{} : Bool}

# Guarantees: actual receive reports acceptance exactly when the complete admission policy allows it.
# Why it matters: the receive dispatcher cannot ignore the policy or change its acceptance flag.
law receive_accepts_exactly:
  for +state: S.State
  for peer: U32
  for +command: S.Command
  {S.accepted(S.receive(state,peer,command)) == S.valid_command(state,peer,command) : Bool}

def lane_sequence(lane: S.Lane) -> U32:
  match lane:
    case S.Lane{seq,_,_,_,_,_,_}: seq

def action_domain(action: S.Action) -> Bool:
  match action:
    case S.Movement{x,y}: Bool.and(U32.is_le(x,2),U32.is_le(y,2))
    case S.MovementTick{_,x,y}: Bool.and(U32.is_le(x,2),U32.is_le(y,2))
    case S.Choice{round,index}: Bool.and(U32.is_gt(round,0),U32.is_lt(index,16))
    case S.Setup{character,arcana,_,weapons}: Bool.and(U32.is_lt(character,7),Bool.and(U32.is_lt(arcana,12),U32.is_le(weapons,16777215)))

# Guarantees: movement accepts precisely the three encoded positions on each axis; choices and setup use their declared domains.
# Why it matters: real input and setup packets must be accepted without allowing malformed values into gameplay.
law action_domain_exact:
  for +action: S.Action
  {S.action_allowed(action) == action_domain(action) : Bool}


def admission_policy(state: S.State,+peer: U32,command: S.Command) -> Bool:
  match state command:
    case S.State{session,_,host,guest,+connected,ended} S.Command{claimed,+player,+seq,_,action}:
      Bool.and(Bool.not(ended),Bool.and(Bool.or(U32.is_eq(peer,0),connected),Bool.and(Bool.and(U32.is_eq(session,claimed),U32.is_eq(peer,player)),Bool.and(Bool.and(U32.is_le(player,1),Bool.or(U32.is_eq(player,0),connected)),Bool.and(U32.is_gt(seq,lane_sequence(Bool.pick(S.Lane,U32.is_eq(player,0),host,guest))),action_domain(action))))))

# Guarantees: acceptance includes every well formed fresh command from its live session's authenticated lane, and excludes every other command.
# Why it matters: an implementation that refuses valid player inputs is just as broken as one accepting forged or duplicate packets.
law policy_exact:
  for +state: S.State
  for +peer: U32
  for +command: S.Command
  {S.valid_command(state,peer,command) == admission_policy(state,peer,command) : Bool}

# Guarantees: the public receive operation leaves the complete state unchanged whenever admission is refused.
# Why it matters: rejected network commands must not move a player or consume its sequence number.
law public_denied_preserves:
  for +state: S.State
  for peer: U32
  for +command: S.Command
  for denied: {False{} == S.valid_command(state,peer,command) : Bool}
  {S.admission_state(S.receive(state,peer,command)) == state : S.State}

# Guarantees: accepted public commands perform exactly their lane update and report success.
# Why it matters: an accepted packet cannot be acknowledged while its state update is silently dropped.
law public_accepted_updates:
  for +state: S.State
  for peer: U32
  for +command: S.Command
  for allowed: {True{} == S.valid_command(state,peer,command) : Bool}
  {S.receive(state,peer,command) == S.Admission{S.admitted(command,state),True{},command} : S.Admission}

# Guarantees: input expiry preserves all sequence metadata and neutralizes exactly when the unsigned elapsed admission clock reaches its timeout.
# Why it matters: a stalled movement sender stops moving even while the gameplay clock is paused.
law expiry_exact:
  for +clock: U32
  for +last: U32
  for +input: U32
  for +applied: U32
  for +tick: U32
  for +received: U32
  for +x: U32
  for +y: U32
  {S.expire_lane(clock,S.Lane{last,input,applied,tick,received,x,y}) == S.Lane{last,input,applied,tick,received,Bool.pick(U32,U32.is_ge((clock - received : U32),18),1,x),Bool.pick(U32,U32.is_ge((clock - received : U32),18),1,y)} : S.Lane}

def host_lane(state: S.State) -> S.Lane:
  match state:
    case S.State{_,_,host,_,_,_}: host
def guest_lane(state: S.State) -> S.Lane:
  match state:
    case S.State{_,_,_,guest,_,_}: guest

# Guarantees: a host command cannot change the guest's input or acknowledgement metadata.
# Why it matters: moving the host must never steer the other player's character.
law host_lane_isolated:
  for +state: S.State
  for session: U32
  for seq: U32
  for tick: U32
  for action: S.Action
  {guest_lane(S.admitted(S.Command{session,0,seq,tick,action},state)) == guest_lane(state) : S.Lane}

# Guarantees: a guest command cannot change the host's input or acknowledgement metadata.
# Why it matters: moving the guest must never steer the host's character.
law guest_lane_isolated:
  for +state: S.State
  for session: U32
  for seq: U32
  for tick: U32
  for action: S.Action
  {host_lane(S.admitted(S.Command{session,1,seq,tick,action},state)) == host_lane(state) : S.Lane}

# Guarantees: applying input copies its sequence to the acknowledgement and changes its tick only for newly applied input.
# Why it matters: repeating simulation frames must not claim the same input was first applied later.
law applied_exact:
  for +tick: U32
  for +last: U32
  for +input: U32
  for +applied: U32
  for +prior: U32
  for +received: U32
  for +x: U32
  for +y: U32
  {S.apply_lane(tick,S.Lane{last,input,applied,prior,received,x,y}) == S.Lane{last,input,input,Bool.pick(U32,U32.is_ne(input,applied),tick,prior),received,x,y} : S.Lane}

def lane_update(action: S.Action,+seq: U32,clock: U32,lane: S.Lane) -> S.Lane:
  match action lane:
    case S.Movement{x,y} S.Lane{_,_,applied,tick,_,_,_}: S.Lane{seq,seq,applied,tick,clock,x,y}
    case S.MovementTick{_,_,_} S.Lane{_,input,applied,tick,received,x,y}: S.Lane{seq,input,applied,tick,received,x,y}
    case S.Choice{_,_} S.Lane{_,input,applied,tick,received,x,y}: S.Lane{seq,input,applied,tick,received,x,y}
    case S.Setup{_,_,_,_} S.Lane{_,input,applied,tick,received,x,y}: S.Lane{seq,input,applied,tick,received,x,y}
def updated_state(command: S.Command,state: S.State) -> S.State:
  match command state:
    case S.Command{_,+player,+seq,_,+action} S.State{session,+clock,+host,+guest,connected,ended}:
      S.State{session,clock,Bool.pick(S.Lane,U32.is_eq(player,0),lane_update(action,seq,clock,host),host),Bool.pick(S.Lane,U32.is_eq(player,1),lane_update(action,seq,clock,guest),guest),connected,ended}

# Guarantees: accepted public packets update only their selected lane, advance its last sequence, preserve session metadata, and update movement metadata only for movement.
# Why it matters: acknowledging a setup or reward packet must not overwrite movement or steer the other player.
law public_update_exact:
  for +state: S.State
  for peer: U32
  for +command: S.Command
  for allowed: {True{} == S.valid_command(state,peer,command) : Bool}
  {S.admission_state(S.receive(state,peer,command)) == updated_state(command,state) : S.State}

# Guarantees: after accepting a host command, the identical command cannot pass admission again.
# Why it matters: retransmission must not apply a reward, setup change or movement sequence twice.
law host_replay_refused:
  for +state: S.State
  for +session: U32
  for +seq: U32
  for +tick: U32
  for +action: S.Action
  {S.valid_command(S.admitted(S.Command{session,0,seq,tick,action},state),0,S.Command{session,0,seq,tick,action}) == False{} : Bool}

# Guarantees: after accepting a guest command, the identical command cannot pass admission again.
# Why it matters: guest retransmission cannot consume another reward choice or replay a setup change.
law guest_replay_refused:
  for +state: S.State
  for +session: U32
  for +seq: U32
  for +tick: U32
  for +action: S.Action
  {S.valid_command(S.admitted(S.Command{session,1,seq,tick,action},state),1,S.Command{session,1,seq,tick,action}) == False{} : Bool}

# Guarantees: admitting a numbered movement tick advances packet freshness without changing held input or claiming it was applied.
# Why it matters: the worker must acknowledge the queued tick only after its own authoritative world step.
law tick_does_not_hold:
  for round: U32
  for x: U32
  for y: U32
  for +seq: U32
  for clock: U32
  for last: U32
  for +input: U32
  for +applied: U32
  for +tick: U32
  for +received: U32
  for +dx: U32
  for +dy: U32
  {S.update_lane(S.MovementTick{round,x,y},seq,clock,S.Lane{last,input,applied,tick,received,dx,dy}) == S.Lane{seq,input,applied,tick,received,dx,dy} : S.Lane}

# Guarantees: a new session starts with an explicit unresolved neutral world tick.
# Why it matters: a setup ACK cannot be mistaken for an applied gameplay input.
law fresh_receipt_exact:
  {S.receipt_fresh() == S.Receipt{0,0,1,1,False{}} : S.Receipt}

# Guarantees: a new guest connection clears only its command lane and restores admission in a live session.
# Why it matters: after reload the guest restarts command numbering while the host keeps its current lane and clock.
law reconnect_live_exact:
  for +session: U32
  for +clock: U32
  for +host: S.Lane
  for guest: S.Lane
  for connected: Bool
  {S.reconnect(S.State{session,clock,host,guest,connected,False{}}) == S.State{session,clock,host,S.Lane{0,0,0,0,0,1,1},True{},False{}} : S.State}

# Guarantees: reconnect cannot reopen or otherwise change a terminated session.
# Why it matters: a late connection after host exit cannot resurrect the game.
law reconnect_ended_unchanged:
  for +session: U32
  for +clock: U32
  for +host: S.Lane
  for +guest: S.Lane
  for +connected: Bool
  {S.reconnect(S.State{session,clock,host,guest,connected,True{}}) == S.State{session,clock,host,guest,connected,True{}} : S.State}

# Guarantees: a first setup command is admitted after a live guest disconnect and reconnect, regardless of previous guest sequence numbers.
# Why it matters: reload starts at sequence one instead of inheriting an unreachable freshness threshold.
law reloaded_guest_setup_accepted:
  for +session: U32
  for clock: U32
  for host: S.Lane
  for guest: S.Lane
  for connected: Bool
  for tick: U32
  {S.accepted(S.receive(S.reconnect(S.disconnect(1,S.State{session,clock,host,guest,connected,False{}})),1,S.Command{session,1,1,tick,S.Setup{0,0,0,0}})) == True{} : Bool}
