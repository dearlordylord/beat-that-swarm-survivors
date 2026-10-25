import Base
import ../music.bend as M

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

# Guarantees: at any bar boundary, the public commit uses the newest target.
# Why it matters: an earlier threat must not replay after the player escapes.
law commit_at_any_boundary:
  for +step: U32
  for active: U32
  for +latest: U32
  for boundary: {True{} == U32.is_eq((step % 16 : U32),0) : Bool}
  {M.commit(step,active,latest) == U32.min(3,latest) : U32}

# Guarantees: every non-boundary step keeps the current arrangement.
# Why it matters: observations during a bar must not restart its instruments.
law commit_between_any_boundaries:
  for +step: U32
  for +active: U32
  for latest: U32
  for between: {False{} == U32.is_eq((step % 16 : U32),0) : Bool}
  {M.commit(step,active,latest) == active : U32}

# Guarantees: the latest boundary observation supersedes an arbitrary prior commit.
# Why it matters: an obsolete danger observation cannot remain queued for playback.
law latest_supersedes_any_previous_commit:
  for earlierStep: U32
  for +step: U32
  for active: U32
  for earlier: U32
  for +latest: U32
  for boundary: {True{} == U32.is_eq((step % 16 : U32),0) : Bool}
  {M.commit(step,M.commit(earlierStep,active,earlier),latest) == U32.min(3,latest) : U32}

# Guarantees: a rising critical threat reaches its normalized danger immediately.
# Why it matters: an approaching lethal enemy cannot wait for the normal music ramp.
law public_emergency_bypasses_ramp:
  for +previous: U32
  for +raw: U32
  for rising: {True{} == U32.is_lt(U32.min(previous,1000),U32.min(raw,1000)) : Bool}
  for emergency: {True{} == U32.is_le(900,U32.min(raw,1000)) : Bool}
  {M.smooth(previous,raw) == U32.min(raw,1000) : U32}
