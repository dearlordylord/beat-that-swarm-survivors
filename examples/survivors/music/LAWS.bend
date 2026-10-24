import Base
import ../music.bend as M

# The latest target replaces all previous observations at a musical boundary.
law latest_at_boundary:
  for active: U32
  for latest: U32
  {M.boundary(True{},active,latest) == U32.min(3,latest) : U32}
# Observing danger between bars must not change the committed arrangement.
law held_between_boundaries:
  for active: U32
  for latest: U32
  {M.boundary(False{},active,latest) == active : U32}
# A superseded high target is not an event to replay at the next bar.
law replaced_before_next_bar:
  for active: U32
  for earlier: U32
  for +latest: U32
  {M.commit(16,M.commit(15,active,earlier),latest) == U32.min(3,latest) : U32}

# Guarantees: an emergency observation bypasses the ordinary rise delay.
# Why it matters: lethal enemies must not wait behind the gentle music ramp.
law emergency_rise:
  for previous: U32
  for +raw: U32
  {M.rise_policy(True{},previous,raw) == raw : U32}
# Guarantees: either choice within a pair selects one of the four themes.
# Why it matters: random playlist choices must always have a playable score.
law theme_in_range:
  for pair: Bool
  for bit: Bool
  {U32.is_lt(M.pair_choice(pair,bit),4) == True{} : Bool}
# Guarantees: changing pair cannot repeat the previous theme, for any random bits.
# Why it matters: a scheduled theme change must audibly change composition.
law opposite_pairs_differ:
  for +pair: Bool
  for earlier: Bool
  for later: Bool
  {U32.is_eq(M.pair_choice(pair,earlier),M.pair_choice(Bool.not(pair),later)) == False{} : Bool}
