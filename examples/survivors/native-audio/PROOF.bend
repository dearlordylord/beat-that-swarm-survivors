import Base
import LAWS.bend as Laws
import ../native_audio.bend as A

def Laws.paused_clock(previous,now): {==}
def Laws.uninterrupted_voices(voices): {==}
def Laws.paused_voices(previous,voices):
  match previous:
    case False{}: {==}
    case True{}: {==}
def Laws.resumed_voices(voices): {==}
def Laws.reset_clears_track(track): {==}
def Laws.no_reset_preserves_track(track): {==}
def Laws.paused_preparation_preserves_track(clock,time,carry,cursor,step,voices,stage,control,seed): {==}
def taken_bound(voices: List<&2,A.Voice>,+fuel: Nat) -> {Nat.is_le(List.length(&2,A.Voice,A.take_voices(fuel,voices)),fuel) == True{} : Bool}:
  match voices fuel:
    case [] 0n: {==}
    case [] 1n+k: {==}
    case _ <> rest 0n: {==}
    case _ <> rest 1n+k: taken_bound(rest,k)
def Laws.taken_voices_bounded(fuel,voices): taken_bound(voices,fuel)
def Laws.installed_voices_bounded(notes,start,voices):
  Laws.taken_voices_bounded(10n,A.install(notes,start,A.alive_voices(voices,start)))
def Laws.paused_block_preserves_track(count,clock,time,carry,cursor,step,voices,stage,control,seed): {==}
def Laws.active_block_advances_exactly(count,clock,time,carry,cursor,step,voices,stage,control,seed): {==}
