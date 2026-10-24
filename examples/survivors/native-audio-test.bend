import Base
import native_audio.bend as A
import music.bend as M

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def stereo(rows: List<&2,F32>) -> Bool:
  match rows:
    case []: True{}
    case +a <> b <> rest: Bool.and(F32.is_eq(a,b),Bool.and(F32.is_le(F32.abs(a),0.8),stereo(rest)))
    case _: False{}
def frames(rows: List<&2,F32>) -> U32:
  match rows:
    case []: 0
    case _ <> _ <> rest: (1 + frames(rest) : U32)
    case _: 4294967295
def cursor(track: A.Track) -> U32:
  match track:
    case A.Track{_,_,_,cursor,_,_,_,_,_,_}: cursor
def playlist_seed(track: A.Track) -> U32:
  match track:
    case A.Track{_,_,_,_,_,_,_,_,_,seed}: seed
def elapsed(now: Nat,then: Nat) -> Nat: Nat.sub(now,then)
def energy(rows: List<&2,F32>) -> F32:
  match rows:
    case []: 0.0
    case sample <> rest: (F32.abs(sample) + energy(rest) : F32)
def busy_voices(+index: U32) -> List<&2,A.Voice>:
  [A.Voice{0,index,4096,0.005,0.8},A.Voice{1,index,4096,0.010,0.8},A.Voice{1,index,4096,0.015,0.8},A.Voice{2,index,4096,0.020,0.8},A.Voice{2,index,4096,0.025,0.8},A.Voice{3,index,4096,0.003,0.8},A.Voice{4,index,4096,0.004,0.8},A.Voice{5,index,4096,0.010,0.8},A.Voice{6,index,4096,0.010,0.8},A.Voice{7,index,4096,0.010,0.8}]
def bench(fuel: Nat,+index: U32) -> F32:
  match fuel:
    case 0n: 0.0
    case 1n+k: (energy(A.samples(1024n,index,busy_voices(index))) + bench(k,(index + 1024 : U32)) : F32)
def score_step(track: A.Track) -> U32:
  match track:
    case A.Track{_,_,_,_,step,_,_,_,_,_}: step
def target(control: A.Control) -> U32:
  match control:
    case A.Control{_,target,_,_,_}: target
def band(control: A.Control) -> U32:
  match control:
    case A.Control{_,_,band,_,_}: band
def held(voices: List<&2,A.Voice>) -> Bool:
  match voices:
    case []: False{}
    case A.Voice{1,0,5000,_,_} <> _: True{}
    case _ <> rest: held(rest)
def voice_count(voices: List<&2,A.Voice>) -> U32:
  match voices:
    case []: 0
    case _ <> rest: (1 + voice_count(rest) : U32)
def measured(start: Nat,+sum: F32) -> IO(Unit):
  do IO<Unit>:
    expect(F32.is_gt(sum,0.0),"native synth emits audible energy")
    end : Nat <- IO.now()
    IO.print("PCM_BENCH voices=10 frames=22528 elapsed_ms=" ++ Nat.show(elapsed(end,start)) ++ " energy=" ++ F32.show(sum))
def main() -> IO(Unit):
  +voices = A.install_score(M.notes(0,0,3),0,[])
  +paused = A.transport_at(1000n,False{},0,0,A.initial())
  do IO<Unit>:
    expect(stereo(A.samples(441n,0,voices)),"native PCM is bounded interleaved stereo")
    expect(U32.is_eq(frames(A.samples(441n,0,voices)),441),"441 audio frames contain882 channel samples")
    expect(U32.is_eq(A.step_at(A.step_start(64)),64),"four-bar score boundary matches132 BPM22050Hz")
    expect(U32.is_le(A.chunk_size(0,0),1024),"native chunk is bounded to1024frames")
    expect(U32.is_eq(A.note_duration(5,1),772),"native hat is35ms rather than full sixteenth")
    expect(held(A.install_score([M.Note{1,40,1,500}],2506,[A.Voice{1,0,5000,0.01,1.0}])),"new riff preserves held fifth lifetime")
    expect(U32.is_le(voice_count(A.install_score(M.notes(0,0,3),0,busy_voices(0))),10),"overlapping note bank is capped at10voices")
    expect(U32.is_eq(cursor(A.transport_at(5000n,False{},0,0,paused)),0),"paused musical clock does not advance")
    expect(U32.is_eq(score_step(A.prepare(A.initial())),4294967295),"menu refill does not consume first score step")
    expect(Bool.not(A.observation_due(150n,A.Track{150n,100,0,100,0,[],True{},0,A.Control{0,0,0,100n,0},0})),"danger scan reuses cached observation before100ms")
    expect(A.observation_due(200n,A.Track{200n,100,0,100,0,[],True{},0,A.Control{0,0,0,100n,0},0}),"danger scan becomes due at100ms")
    expect(A.observation_due(150n,A.Track{150n,100,0,A.step_start(16),15,[],True{},0,A.Control{0,0,0,100n,0},0}),"bar preparation requests fresh danger before100ms")
    expect(U32.is_eq(cursor(A.reset_if(True{},A.after_block(100,A.Track{0n,0,0,0,0,[],True{},0,A.Control{0,0,0,0n,0},0}))),0),"new run resets musical cursor")
    expect(stereo(A.cue_pcm(3)),"paused reward cue uses standalone stereo PCM")
    expect(F32.is_gt(energy(A.cue_pcm(3)),0.0),"paused reward cue retains audible energy")
    expect(U32.is_eq(frames(A.cue_pcm(3)),882),"paused reward cue is bounded to882frames")
    expect(Bool.not(A.refill_allowed(2048,A.step_start(16),15,True{})),"bar generation waits until queue is at most1024frames")
    expect(A.refill_allowed(1024,A.step_start(16),15,True{}),"bar generation is allowed within46ms playback horizon")
    expect(U32.is_eq(target(A.control_at(200n,0,A.Control{0,3,0,100n,1000})),0),"latest calmer observation replaces pending high target")
    expect(U32.is_eq(band(A.prepare_changed(True{},16,200n,A.Control{0,3,0,100n,0})),0),"bar boundary uses latest intent rather than latched high target")
    expect(U32.is_eq(playlist_seed(A.transport_at(5000n,False{},0,0,A.transport_at(1000n,True{},0,0,A.initial()))),1001),"native pause retains the run playlist seed")
    expect(U32.is_eq(playlist_seed(A.reset_if(True{},A.transport_at(1000n,True{},0,0,A.initial()))),0),"new native run discards the old playlist seed")
    start : Nat <- IO.now()
    measured(start,bench(22n,0))
