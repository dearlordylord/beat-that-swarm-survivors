import Base
import ./coop-session.bend as S

# Guarantees: an admission rejected by the policy leaves the entire session unchanged.
# Why it matters: malformed, forged and duplicate commands cannot mutate player input.
law denied_preserves:
  for +state: S.State
  for command: S.Command
  {S.admission_state(S.receive_decided(False{},state,command)) == state : S.State}

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
