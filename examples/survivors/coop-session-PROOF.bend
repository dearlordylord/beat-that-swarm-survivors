import Base
import ./coop-session.bend as S
import ./coop-session-LAWS.bend as L

def L.denied_preserves(state,command): {==}
def L.departed_guest_denied(state,command):
  match state command:
    case S.State{session,clock,host,guest,connected,False{}} S.Command{claimed,player,seq,tick,action}: {==}
    case S.State{session,clock,host,guest,connected,True{}} S.Command{claimed,player,seq,tick,action}: {==}

def L.ended_denied(state,peer,command):
  match state command:
    case S.State{session,clock,host,guest,connected,ended} S.Command{claimed,player,seq,tick,action}: {==}

def decided_accepts(allowed: Bool,state: S.State,command: S.Command) -> {S.accepted(S.receive_decided(allowed,state,command)) == allowed : Bool}:
  match allowed:
    case False{}: {==}
    case True{}: {==}
def L.receive_accepts_exactly(state,peer,command): decided_accepts(S.valid_command(state,peer,command),state,command)
