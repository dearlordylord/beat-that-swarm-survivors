import Base
import ./coop-reward-policy.bend as R

def required_member(ids: List<&2,U32>,+id: U32) -> Bool:
  match ids:
    case []: False{}
    case head <> rest: Bool.or(U32.is_eq(head,id),required_member(rest,id))

# Guarantees: choices are accepted exactly for a required player, the current round, and an existing offer index.
# Why it matters: real players must be able to choose once while stale, duplicate, ineligible or out of range choices are refused.
law admission_exact:
  for +round: U32
  for +requested: U32
  for +id: U32
  for +choice: U32
  for +count: U32
  for +required: List<&2,U32>
  {R.allowed(round,requested,id,choice,count,required) == Bool.and(Bool.and(U32.is_eq(round,requested),required_member(required,id)),U32.is_lt(choice,count)) : Bool}

def retain_other(same: Bool,head: U32,rest: List<&2,U32>) -> List<&2,U32>:
  match same:
    case True{}: rest
    case False{}: head <> rest
def without_player(ids: List<&2,U32>,+id: U32) -> List<&2,U32>:
  match ids:
    case []: []
    case +head <> rest: retain_other(U32.is_eq(head,id),head,without_player(rest,id))

# Guarantees: completing a choice or departing removes precisely that player's outstanding obligations, preserving every other obligation in order.
# Why it matters: a player cannot choose twice and their departure cannot cancel another player's reward.
law removal_exact:
  for +required: List<&2,U32>
  for +id: U32
  {R.remove(required,id) == without_player(required,id) : List<&2,U32>}

# Guarantees: rejecting a reward choice retains every outstanding player's obligation.
# Why it matters: a duplicate or stale packet cannot release the reward barrier.
law denied_preserves:
  for round: U32
  for requested: U32
  for +id: U32
  for choice: U32
  for count: U32
  for +required: List<&2,U32>
  for denied: {False{} == R.allowed(round,requested,id,choice,count,required) : Bool}
  {R.decide(round,requested,id,choice,count,required) == R.Decision{False{},required} : R.Decision}

# Guarantees: accepting a choice marks it accepted and removes exactly the choosing player's obligations.
# Why it matters: the authoritative dispatcher consumes the same decision that advances the required-player barrier.
law accepted_removes:
  for round: U32
  for requested: U32
  for +id: U32
  for choice: U32
  for count: U32
  for +required: List<&2,U32>
  for accepted: {True{} == R.allowed(round,requested,id,choice,count,required) : Bool}
  {R.decide(round,requested,id,choice,count,required) == R.Decision{True{},without_player(required,id)} : R.Decision}

# Guarantees: no obligation for a player remains after that player completes a choice or leaves.
# Why it matters: a second choice from the same player is refused until a later reward round requires them again.
law removal_consumes_player:
  for +required: List<&2,U32>
  for +id: U32
  {R.contains(R.remove(required,id),id) == False{} : Bool}
