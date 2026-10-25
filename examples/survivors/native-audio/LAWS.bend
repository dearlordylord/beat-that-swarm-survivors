import Base
import ../native_audio.bend as A
import ../music.bend as M

# Guarantees: a paused transport advances by no elapsed audio frames.
# Why it matters: a long pause must not skip the score when play resumes.
law paused_clock:
  for previous: Nat
  for now: Nat
  {A.advance_clock(False{},previous,now) == 0 : U32}

# Guarantees: continuously playing keeps every currently held voice.
# Why it matters: a new clock observation must not cut off the previous riff.
law uninterrupted_voices:
  for +voices: List<&2,A.Voice>
  {A.transport_voices(True{},True{},voices) == voices : List<&2,A.Voice>}

# Guarantees: pausing discards held voices for either prior playing state.
# Why it matters: stale notes must not resume after a menu or reward pause.
law paused_voices:
  for previous: Bool
  for +voices: List<&2,A.Voice>
  {A.transport_voices(False{},previous,voices) == [] : List<&2,A.Voice>}

# Guarantees: resuming starts without voices that were held before the pause.
# Why it matters: stale notes must not be synthesized over the resumed score.
law resumed_voices:
  for +voices: List<&2,A.Voice>
  {A.transport_voices(True{},False{},voices) == [] : List<&2,A.Voice>}

# Guarantees: resetting a run discards all old transport and playlist state.
# Why it matters: a new run must not inherit another run's notes or seed.
law reset_clears_track:
  for track: A.Track
  {A.reset_if(True{},track) == A.initial() : A.Track}

# Guarantees: without a reset the entire transport is retained.
# Why it matters: ordinary host observations must not restart the playlist.
law no_reset_preserves_track:
  for +track: A.Track
  {A.reset_if(False{},track) == track : A.Track}

# Guarantees: preparing a paused track consumes no score or control state.
# Why it matters: menu audio refills must not consume the first game note.
law paused_preparation_preserves_track:
  for +clock: Nat
  for +time: U32
  for +carry: U32
  for +cursor: U32
  for +step: U32
  for +voices: List<&2,A.Voice>
  for +stage: U32
  for +control: A.Control
  for +seed: U32
  {A.prepare(A.Track{clock,time,carry,cursor,step,voices,False{},stage,control,seed}) == A.Track{clock,time,carry,cursor,step,voices,False{},stage,control,seed} : A.Track}

# Guarantees: retaining a voice prefix never exceeds its supplied voice budget.
# Why it matters: overlapping sustained riffs must not grow the synthesis bank.
law taken_voices_bounded:
  for +fuel: Nat
  for voices: List<&2,A.Voice>
  {Nat.is_le(List.length(&2,A.Voice,A.take_voices(fuel,voices)),fuel) == True{} : Bool}

# Guarantees: installing any score keeps at most the native synthesis voice limit.
# Why it matters: overlapping sustained riffs cannot overload audio generation.
law installed_voices_bounded:
  for notes: List<&2,M.Note>
  for +start: U32
  for voices: List<&2,A.Voice>
  {Nat.is_le(List.length(&2,A.Voice,A.install_score(notes,start,voices)),10n) == True{} : Bool}

# Guarantees: a paused output block preserves the entire track.
# Why it matters: A host silence refill must not consume any game music.
law paused_block_preserves_track:
  for +count: U32
  for +clock: Nat
  for +time: U32
  for +carry: U32
  for +cursor: U32
  for +step: U32
  for +voices: List<&2,A.Voice>
  for +stage: U32
  for +control: A.Control
  for +seed: U32
  {A.after_block(count,A.Track{clock,time,carry,cursor,step,voices,False{},stage,control,seed}) == A.Track{clock,time,carry,cursor,step,voices,False{},stage,control,seed} : A.Track}

# Guarantees: a playing output block advances only its cursor by its frame count.
# Why it matters: Consecutive output blocks must not skip or replay audio frames.
law active_block_advances_exactly:
  for +count: U32
  for +clock: Nat
  for +time: U32
  for +carry: U32
  for +cursor: U32
  for +step: U32
  for +voices: List<&2,A.Voice>
  for +stage: U32
  for +control: A.Control
  for +seed: U32
  {A.after_block(count,A.Track{clock,time,carry,cursor,step,voices,True{},stage,control,seed}) == A.Track{clock,time,carry,(cursor + count : U32),step,voices,True{},stage,control,seed} : A.Track}
