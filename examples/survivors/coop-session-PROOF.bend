import Base
import ./proof-facts.bend as F
import ./coop-session.bend as S
import ./coop-session-LAWS.bend as L

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

def L.action_domain_exact(action):
  match action:
    case S.Movement{x,y}: {==}
    case S.Choice{round,index}: {==}
    case S.Setup{character,arcana,meta,weapons}: {==}

def sequence_exact(lane: S.Lane) -> {S.last_seq(lane) == L.lane_sequence(lane) : U32}:
  match lane:
    case S.Lane{seq,input,applied,tick,received,x,y}: {==}

def L.policy_exact(state,peer,command):
  match state command:
    case S.State{session,clock,+host,+guest,+connected,+ended} S.Command{+claimed,+player,+seq,+tick,+action}:
      %sequence_exact(Bool.pick(S.Lane,U32.is_eq(player,0),host,guest)) : {S.valid_command(S.State{session,clock,host,guest,connected,ended},peer,S.Command{claimed,player,seq,tick,action}) == Bool.and(Bool.not(ended),Bool.and(Bool.or(U32.is_eq(peer,0),connected),Bool.and(Bool.and(U32.is_eq(session,claimed),U32.is_eq(peer,player)),Bool.and(Bool.and(U32.is_le(player,1),Bool.or(U32.is_eq(player,0),connected)),Bool.and(U32.is_gt(seq,_),L.action_domain(action)))))) : Bool}
      %L.action_domain_exact(action) : {S.valid_command(S.State{session,clock,host,guest,connected,ended},peer,S.Command{claimed,player,seq,tick,action}) == Bool.and(Bool.not(ended),Bool.and(Bool.or(U32.is_eq(peer,0),connected),Bool.and(Bool.and(U32.is_eq(session,claimed),U32.is_eq(peer,player)),Bool.and(Bool.and(U32.is_le(player,1),Bool.or(U32.is_eq(player,0),connected)),Bool.and(U32.is_gt(seq,S.last_seq(Bool.pick(S.Lane,U32.is_eq(player,0),host,guest))),_))))) : Bool}
      {==}

def L.public_denied_preserves(state,peer,command,denied):
  %denied : {S.admission_state(S.receive_decided(_,state,command)) == state : S.State}
  {==}

def L.public_accepted_updates(state,peer,command,allowed):
  %allowed : {S.receive_decided(_,state,command) == S.Admission{S.admitted(command,state),True{},command} : S.Admission}
  {==}

def L.expiry_exact(clock,last,input,applied,tick,received,x,y): {==}

def L.host_lane_isolated(state,session,seq,tick,action):
  match state:
    case S.State{s,c,host,guest,connected,ended}: {==}

def L.guest_lane_isolated(state,session,seq,tick,action):
  match state:
    case S.State{s,c,host,guest,connected,ended}: {==}

def L.applied_exact(tick,last,input,applied,prior,received,x,y): {==}

def update_exact(command: S.Command,state: S.State) -> {S.admitted(command,state) == L.updated_state(command,state) : S.State}:
  match command state:
    case S.Command{s,p,q,t,S.Movement{x,y}} S.State{session,clock,S.Lane{a,b,c,d,e,f,g},S.Lane{h,i,j,k,l,m,n},connected,ended}: {==}
    case S.Command{s,p,q,t,S.Choice{r,z}} S.State{session,clock,S.Lane{a,b,c,d,e,f,g},S.Lane{h,i,j,k,l,m,n},connected,ended}: {==}
    case S.Command{s,p,q,t,S.Setup{x,y,z,w}} S.State{session,clock,S.Lane{a,b,c,d,e,f,g},S.Lane{h,i,j,k,l,m,n},connected,ended}: {==}

def L.public_update_exact(state,peer,command,allowed):
  %allowed : {S.admission_state(S.receive_decided(_,state,command)) == L.updated_state(command,state) : S.State}
  update_exact(command,state)

def gates_false(+a: Bool,+b: Bool,+c: Bool,+d: Bool) -> {Bool.and(a,Bool.and(b,Bool.and(c,Bool.and(d,False{})))) == False{} : Bool}:
  %Equal.sym(Bool,Bool.and(d,False{}),False{},F.and_false_right(d)) : {Bool.and(a,Bool.and(b,Bool.and(c,_))) == False{} : Bool}
  %Equal.sym(Bool,Bool.and(c,False{}),False{},F.and_false_right(c)) : {Bool.and(a,Bool.and(b,_)) == False{} : Bool}
  %Equal.sym(Bool,Bool.and(b,False{}),False{},F.and_false_right(b)) : {Bool.and(a,_) == False{} : Bool}
  F.and_false_right(a)

def sequence_false(+session: U32,+clock: U32,+host: S.Lane,+guest: S.Lane,+connected: Bool,+ended: Bool,+peer: U32,+claimed: U32,+player: U32,+seq: U32,+tick: U32,+action: S.Action,denied: {False{} == U32.is_gt(seq,S.last_seq(S.lane_at(player,host,guest))) : Bool}) -> {S.valid_command(S.State{session,clock,host,guest,connected,ended},peer,S.Command{claimed,player,seq,tick,action}) == False{} : Bool}:
  %denied : {Bool.and(Bool.not(ended),Bool.and(Bool.or(U32.is_eq(peer,0),connected),Bool.and(Bool.and(U32.is_eq(session,claimed),U32.is_eq(peer,player)),Bool.and(Bool.and(U32.is_le(player,1),Bool.or(U32.is_eq(player,0),connected)),Bool.and(_,S.action_allowed(action)))))) == False{} : Bool}
  gates_false(Bool.not(ended),Bool.or(U32.is_eq(peer,0),connected),Bool.and(U32.is_eq(session,claimed),U32.is_eq(peer,player)),Bool.and(U32.is_le(player,1),Bool.or(U32.is_eq(player,0),connected)))

def self_sequence_false(+seq: U32) -> {False{} == U32.is_gt(seq,seq) : Bool}:
  %Equal.sym(Cmp,U32.cmp(seq,seq),EQ{},F.u32_cmp_refl(seq)) : {False{} == Cmp.is_gt(_) : Bool}
  {==}

def L.host_replay_refused(state,session,seq,tick,action):
  match state action:
    case S.State{s,c,S.Lane{a,b,d,e,f,g,h},S.Lane{i,j,k,l,m,n,o},connected,ended} S.Movement{x,y}: sequence_false(s,c,S.update_lane(S.Movement{x,y},seq,c,S.Lane{a,b,d,e,f,g,h}),S.Lane{i,j,k,l,m,n,o},connected,ended,0,session,0,seq,tick,S.Movement{x,y},self_sequence_false(seq))
    case S.State{s,c,S.Lane{a,b,d,e,f,g,h},S.Lane{i,j,k,l,m,n,o},connected,ended} S.Choice{r,z}: sequence_false(s,c,S.update_lane(S.Choice{r,z},seq,c,S.Lane{a,b,d,e,f,g,h}),S.Lane{i,j,k,l,m,n,o},connected,ended,0,session,0,seq,tick,S.Choice{r,z},self_sequence_false(seq))
    case S.State{s,c,S.Lane{a,b,d,e,f,g,h},S.Lane{i,j,k,l,m,n,o},connected,ended} S.Setup{x,y,z,w}: sequence_false(s,c,S.update_lane(S.Setup{x,y,z,w},seq,c,S.Lane{a,b,d,e,f,g,h}),S.Lane{i,j,k,l,m,n,o},connected,ended,0,session,0,seq,tick,S.Setup{x,y,z,w},self_sequence_false(seq))

def L.guest_replay_refused(state,session,seq,tick,action):
  match state action:
    case S.State{s,c,S.Lane{a,b,d,e,f,g,h},S.Lane{i,j,k,l,m,n,o},connected,ended} S.Movement{x,y}: sequence_false(s,c,S.Lane{a,b,d,e,f,g,h},S.update_lane(S.Movement{x,y},seq,c,S.Lane{i,j,k,l,m,n,o}),connected,ended,1,session,1,seq,tick,S.Movement{x,y},self_sequence_false(seq))
    case S.State{s,c,S.Lane{a,b,d,e,f,g,h},S.Lane{i,j,k,l,m,n,o},connected,ended} S.Choice{r,z}: sequence_false(s,c,S.Lane{a,b,d,e,f,g,h},S.update_lane(S.Choice{r,z},seq,c,S.Lane{i,j,k,l,m,n,o}),connected,ended,1,session,1,seq,tick,S.Choice{r,z},self_sequence_false(seq))
    case S.State{s,c,S.Lane{a,b,d,e,f,g,h},S.Lane{i,j,k,l,m,n,o},connected,ended} S.Setup{x,y,z,w}: sequence_false(s,c,S.Lane{a,b,d,e,f,g,h},S.update_lane(S.Setup{x,y,z,w},seq,c,S.Lane{i,j,k,l,m,n,o}),connected,ended,1,session,1,seq,tick,S.Setup{x,y,z,w},self_sequence_false(seq))
