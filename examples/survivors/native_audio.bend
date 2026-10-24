import Base
import music.bend as M

# Audio.write consumes interleaved stereo and reports queued *frames*.
# The runtime ring has 4096 frames; refill requests at most 1024 at once.
type Voice is Data: Voice{id: U32,start: U32,duration: U32,increment: F32,gain: F32}
type Control is Data: Control{smooth: U32,target: U32,band: U32,clock: Nat,raw: U32}
type Track is Data: Track{clock: Nat,time: U32,carry: U32,cursor: U32,step: U32,voices: List<&2,Voice>,active: Bool,stage: U32,band: Control}
type Feed is Type: Feed{audio: Audio,track: Track,queued: U32}
def initial() -> Track: Track{0n,0,0,0,4294967295,[],False{},0,Control{0,0,0,0n,0}}
def step_at(+frame: U32) -> U32: (frame / 55125 * 22 + (frame % 55125) * 22 / 55125 : U32)
def step_start(+step: U32) -> U32: (step / 22 * 55125 + ((step % 22) * 55125 + 21) / 22 : U32)
def clock_delta(previous: Nat,now: Nat) -> U32: U32.from_nat(Nat.min(60000n,Nat.sub(now,previous)))
def advance_clock(active: Bool,previous: Nat,now: Nat) -> U32:
  match active:
    case True{}: clock_delta(previous,now)
    case False{}: 0
def transport_voices(active: Bool,wasActive: Bool,voices: List<&2,Voice>) -> List<&2,Voice>:
  match active wasActive:
    case True{} True{}: voices
    case _ _: []
def control_value(now: Nat,+smooth: U32,target: U32,band: U32,raw: U32) -> Control:
  Control{smooth,M.target_band(target,smooth),band,now,raw}
def control_raw(raw: U32,previous: Control) -> Control:
  match previous:
    case Control{smooth,target,band,clock,_}: Control{smooth,target,band,clock,raw}
def midi_increment(pitch: U32) -> F32: (M.frequency(pitch) / 22050.0 : F32)
def retain_voice(same: Bool,v: Voice,rest: List<&2,Voice>) -> List<&2,Voice>:
  match same:
    case True{}: rest
    case False{}: v <> rest
def replace_voice(rows: List<&2,Voice>,+id: U32) -> List<&2,Voice>:
  match rows:
    case []: []
    case Voice{+kind,start,duration,increment,gain} <> rest: retain_voice(U32.is_eq(kind,id),Voice{kind,start,duration,increment,gain},replace_voice(rest,id))
def note_duration(voice: U32,length: U32) -> U32:
  match voice:
    case 5: 772
    case 4: U32.min(3308,U32.max(1,(length * 55125 / 22 : U32)))
    case 3: U32.min(2205,U32.max(1,(length * 55125 / 22 : U32)))
    case 6: U32.min(8820,U32.max(1,(length * 55125 / 22 : U32)))
    case _: U32.max(1,(length * 55125 / 22 : U32))
def note_voice(note: M.Note,start: U32) -> Voice:
  match note:
    case M.Note{+id,pitch,length,accent}: Voice{id,start,note_duration(id,length),midi_increment(pitch),(0.6 + U32.to_f32(accent) / 2500.0 : F32)}
def install(notes: List<&2,M.Note>,+start: U32,voices: List<&2,Voice>) -> List<&2,Voice>:
  match notes:
    case []: voices
    case note <> rest: note_voice(note,start) <> install(rest,start,voices)
def alive_voices(voices: List<&2,Voice>,+frame: U32) -> List<&2,Voice>:
  match voices:
    case []: []
    case Voice{+id,+start,+duration,increment,gain} <> rest: retain_voice(U32.is_le((start + duration : U32),frame),Voice{id,start,duration,increment,gain},alive_voices(rest,frame))
def take_voices(fuel: Nat,voices: List<&2,Voice>) -> List<&2,Voice>:
  match fuel:
    case 0n: []
    case 1n+k:
      match voices:
        case []: []
        case voice <> rest: voice <> take_voices(k,rest)
def install_score(notes: List<&2,M.Note>,+start: U32,voices: List<&2,Voice>) -> List<&2,Voice>:
  take_voices(10n,install(notes,start,alive_voices(voices,start)))
def score_step(changed: Bool,+frame: U32,step: U32,voices: List<&2,Voice>,stage: U32,band: U32) -> List<&2,Voice>:
  match changed:
    case True{}: install_score(M.notes(step,stage,band),frame,voices)
    case False{}: voices
def force_control(force: Bool,now: Nat,previous: Control) -> Control:
  match force:
    case True{}:
      match previous:
        case Control{smooth,target,band,clock,+raw}: control_value(now,M.smooth(smooth,raw),target,band,raw)
    case False{}: previous
def prepare_control(+step: U32,control: Control) -> Control:
  match control:
    case Control{smooth,+target,band,clock,raw}: Control{smooth,target,M.commit(step,band,target),clock,raw}
def prepare_changed(changed: Bool,+step: U32,+now: Nat,control: Control) -> Control:
  match changed:
    case True{}:
      match control:
        case Control{smooth,target,band,+clock,raw}: prepare_control(step,force_control(Bool.and(U32.is_eq((step % 16 : U32),0),Nat.is_lt(clock,now)),now,Control{smooth,target,band,clock,raw}))
    case False{}: control
def control_band(control: Control) -> U32:
  match control:
    case Control{_,_,band,_,_}: band
def prepared(clock: Nat,time: U32,carry: U32,+cursor: U32,+step: U32,voices: List<&2,Voice>,active: Bool,+stage: U32,+control: Control) -> Track:
  Track{clock,time,carry,cursor,step_at(cursor),score_step(Bool.not(U32.is_eq(step,step_at(cursor))),cursor,step_at(cursor),voices,stage,control_band(control)),active,stage,control}
def prepare_live(track: Track) -> Track:
  match track:
    case Track{+clock,time,carry,+cursor,+step,voices,active,stage,control}: prepared(clock,time,carry,cursor,step,voices,active,stage,prepare_changed(Bool.not(U32.is_eq(step,step_at(cursor))),step_at(cursor),clock,control))
def cue_frequency(cue: U32) -> F32:
  match cue:
    case 1: 220.0
    case 2: 660.0
    case _: 880.0
def cue_voices(cue: U32,+frame: U32,voices: List<&2,Voice>) -> List<&2,Voice>:
  match cue:
    case 0: voices
    case +id: take_voices(10n,Voice{7,frame,882,(cue_frequency(id) / 22050.0 : F32),0.8} <> replace_voice(voices,7))
def with_cue(track: Track,cue: U32) -> Track:
  match track:
    case Track{clock,time,carry,+cursor,step,voices,active,stage,band}: Track{clock,time,carry,cursor,step,cue_voices(cue,cursor,voices),active,stage,band}
def pulse(positive: Bool) -> F32:
  match positive:
    case True{}: 1.0
    case False{}: (0.0 - 1.0 : F32)
def fract(+value: F32) -> F32: (value - F32.floor(value) : F32)
def noise(index: U32) -> F32: (U32.to_f32(((index * 1103515245 + 12345) % 65536 : U32)) / 32768.0 - 1.0 : F32)
def waveform(id: U32,+age: U32,+increment: F32) -> F32:
  match id:
    case 0: (pulse(F32.is_lt(fract((U32.to_f32(age) * increment : F32)),0.5)) * 0.065 : F32)
    case 1: (pulse(F32.is_lt(fract((U32.to_f32(age) * increment : F32)),0.35)) * 0.045 : F32)
    case 2: (pulse(F32.is_lt(fract((U32.to_f32(age) * increment : F32)),0.5)) * 0.035 : F32)
    case 3: (pulse(F32.is_lt(fract((U32.to_f32(age) * (0.0012 + 0.005 / (1.0 + U32.to_f32(age) / 250.0)) : F32)),0.5)) * 0.12 : F32)
    case 4: (noise(age) * 0.10 : F32)
    case 5: (noise((age * 7 : U32)) * 0.035 : F32)
    case 6: (noise((age * 3 : U32)) * 0.07 : F32)
    case _: (pulse(F32.is_lt(fract((U32.to_f32(age) * increment : F32)),0.5)) * 0.09 : F32)
def voice_sample(alive: Bool,id: U32,+age: U32,duration: U32,increment: F32,gain: F32) -> F32:
  match alive:
    case False{}: 0.0
    case True{}: (waveform(id,age,increment) * gain * (1.0 - U32.to_f32(age) / U32.to_f32(duration)) : F32)
def mix(voices: List<&2,Voice>,+index: U32) -> F32:
  match voices:
    case []: 0.0
    case Voice{id,+start,+duration,increment,gain} <> rest:
      (voice_sample(Bool.and(U32.is_le(start,index),U32.is_lt(index,(start + duration : U32))),id,(index - start : U32),duration,increment,gain) + mix(rest,index) : F32)
def stereo_sample(+sample: F32,tail: List<&2,F32>) -> List<&2,F32>: sample <> sample <> tail
def samples(fuel: Nat,+index: U32,+voices: List<&2,Voice>) -> List<&2,F32>:
  match fuel:
    case 0n: []
    case 1n+k: stereo_sample(F32.clamp(mix(voices,index),(0.0 - 0.8 : F32),0.8),samples(k,(index + 1 : U32),voices))
def silence(fuel: Nat) -> List<&2,F32>:
  match fuel:
    case 0n: []
    case 1n+k: 0.0 <> 0.0 <> silence(k)
def block(active: Bool,count: U32,cursor: U32,voices: List<&2,Voice>) -> List<&2,F32>:
  match active:
    case True{}: samples(U32.to_nat(count),cursor,voices)
    case False{}: silence(U32.to_nat(count))
def chunk_size(+cursor: U32,queued: U32) -> U32:
  U32.min((3072 - U32.min(3072,queued) : U32),U32.min(1024,(step_start((step_at(cursor) + 1 : U32)) - cursor : U32)))
def after_block(count: U32,track: Track) -> Track:
  match track:
    case Track{clock,time,carry,+cursor,step,voices,+active,stage,band}: Track{clock,time,carry,(cursor + count * Bool.to_u32(active) : U32),step,voices,active,stage,band}
def feed_written(track: Track,result: Audio & U32) -> IO(Feed):
  (audio,queued) = result
  IO.pure(Feed,Feed{audio,track,queued})
def feed_chunk(audio: Audio,track: Track,queued: U32) -> IO(Feed):
  match track:
    case Track{clock,time,carry,+cursor,step,+voices,+active,stage,+band}:
      +count = chunk_size(cursor,queued)
      IO.bind(Audio & U32,Feed,Audio.write(audio,block(active,count,cursor,voices)),feed_written(after_block(count,Track{clock,time,carry,cursor,step,voices,active,stage,band})))
def prepare_active(active: Bool,track: Track) -> Track:
  match active:
    case True{}: prepare_live(track)
    case False{}: track
def prepare(track: Track) -> Track:
  match track:
    case Track{clock,time,carry,cursor,step,voices,+active,stage,control}: prepare_active(active,Track{clock,time,carry,cursor,step,voices,active,stage,control})
def refill_allowed(+queued: U32,+cursor: U32,step: U32,+active: Bool) -> Bool:
  +boundary = Bool.and(active,Bool.and(Bool.not(U32.is_eq(step,step_at(cursor))),U32.is_eq((step_at(cursor) % 16 : U32),0)))
  Bool.and(U32.is_lt(queued,3072),Bool.or(Bool.not(boundary),U32.is_le(queued,1024)))
def feed_if(below: Bool,audio: Audio,track: Track,queued: U32) -> IO(Feed):
  match below:
    case True{}: feed_chunk(audio,prepare(track),queued)
    case False{}: IO.pure(Feed,Feed{audio,track,queued})
def feed_next(state: Feed) -> IO(Feed):
  match state:
    case Feed{audio,Track{clock,time,carry,+cursor,+step,voices,+active,stage,band},+queued}:
      feed_if(refill_allowed(queued,cursor,step,active),audio,Track{clock,time,carry,cursor,step,voices,active,stage,band},queued)
def feed_finish(state: Feed) -> IO(Audio & Track):
  match state:
    case Feed{audio,track,_}: IO.pure(Audio & Track,(audio,track))
def refill(audio: Audio,track: Track,queued: U32) -> IO(Audio & Track):
  do IO<Audio & Track>:
    state : Feed <- feed_next(Feed{audio,track,queued})
    state : Feed <- feed_next(state)
    state : Feed <- feed_next(state)
    state : Feed <- feed_next(state)
    state : Feed <- feed_next(state)
    feed_finish(state)
def pumped(result: Audio & Track) -> IO(Maybe<Audio> & Track):
  (device,music) = result
  IO.pure(Maybe<Audio> & Track,(Some{device},music))
def probe_done(track: Track,result: Audio & U32) -> IO(Maybe<Audio> & Track):
  (audio,queued) = result
  IO.bind(Audio & Track,Maybe<Audio> & Track,refill(audio,track,queued),pumped)
def pump(audio: Maybe<Audio>,track: Track) -> IO(Maybe<Audio> & Track):
  match audio:
    case None{}: IO.pure(Maybe<Audio> & Track,(None{},track))
    case Some{device}: IO.bind(Audio & U32,Maybe<Audio> & Track,Audio.write(device,[]),probe_done(track))
def opened(result: Result<&1,&1,U32 & String,Audio>) -> IO(Maybe<Audio>):
  match result:
    case Fail{error}: IO.pure(Maybe<Audio>,None{})
    case Done{audio}: IO.pure(Maybe<Audio>,Some{audio})
def open() -> IO(Maybe<Audio>): IO.bind(Result<&1,&1,U32 & String,Audio>,Maybe<Audio>,Audio.open(22050),opened)
def close(audio: Maybe<Audio>) -> IO(Unit):
  match audio:
    case None{}: IO.pure(Unit,Unit{})
    case Some{device}: Audio.close(device)
def control_smoothed(now: Nat,+raw: U32,previous: Control) -> Control:
  match previous:
    case Control{smooth,+target,band,clock,_}: control_value(now,M.smooth(smooth,raw),target,band,raw)
def control_due(due: Bool,now: Nat,raw: U32,previous: Control) -> Control:
  match due:
    case True{}: control_smoothed(now,raw,previous)
    case False{}: control_raw(raw,previous)
def control_at(+now: Nat,+raw: U32,previous: Control) -> Control:
  match previous:
    case Control{smooth,target,band,+clock,_}: control_due(Nat.is_le(100n,Nat.sub(now,clock)),now,raw,Control{smooth,target,band,clock,raw})
def transport_at(+now: Nat,+active: Bool,stage: U32,danger: U32,track: Track) -> Track:
  match track:
    case Track{+clock,+time,+carry,+cursor,+step,voices,+wasActive,_,control}:
      +total = (advance_clock(Bool.and(active,wasActive),clock,now) * 22050 + carry : U32)
      +next = (time + total / 1000 : U32)
      Track{now,next,(total % 1000 : U32),U32.max(cursor,next),step,transport_voices(active,wasActive,voices),active,stage,control_at(now,danger,control)}

# Observations run at10Hz, with a fresh read while the next bar awaits generation.
def observation_due(+now: Nat,track: Track) -> Bool:
  match track:
    case Track{_,_,_,+cursor,+step,_,_,_,Control{_,_,_,clock,_}}:
      Bool.or(Nat.is_le(100n,Nat.sub(now,clock)),Bool.and(Bool.not(U32.is_eq(step,step_at(cursor))),U32.is_eq((step_at(cursor) % 16 : U32),0)))
def cached_raw(track: Track) -> U32:
  match track:
    case Track{_,_,_,_,_,_,_,_,Control{_,_,_,_,raw}}: raw
def reset_if(reset: Bool,track: Track) -> Track:
  match reset:
    case True{}: initial()
    case False{}: track
def cue_pcm(cue: U32) -> List<&2,F32>: samples(882n,0,cue_voices(cue,0,[]))
def inactive_done(track: Track,result: Audio & U32) -> IO(Maybe<Audio> & Track):
  (device,_) = result
  IO.pure(Maybe<Audio> & Track,(Some{device},track))
def inactive_write(allowed: Bool,cue: U32,track: Track,device: Audio) -> IO(Maybe<Audio> & Track):
  match allowed:
    case True{}: IO.bind(Audio & U32,Maybe<Audio> & Track,Audio.write(device,cue_pcm(cue)),inactive_done(track))
    case False{}: IO.pure(Maybe<Audio> & Track,(Some{device},track))
def inactive_probed(+cue: U32,track: Track,result: Audio & U32) -> IO(Maybe<Audio> & Track):
  (device,queued) = result
  inactive_write(Bool.and(U32.is_lt(0,cue),U32.is_le(queued,3214)),cue,track,device)
def inactive_pump(audio: Maybe<Audio>,track: Track,cue: U32) -> IO(Maybe<Audio> & Track):
  match audio:
    case None{}: IO.pure(Maybe<Audio> & Track,(None{},track))
    case Some{device}: IO.bind(Audio & U32,Maybe<Audio> & Track,Audio.write(device,[]),inactive_probed(cue,track))
def dispatch_active(active: Bool,audio: Maybe<Audio>,track: Track,cue: U32) -> IO(Maybe<Audio> & Track):
  match active:
    case True{}: pump(audio,with_cue(track,cue))
    case False{}: inactive_pump(audio,track,cue)
def dispatch(audio: Maybe<Audio>,track: Track,cue: U32) -> IO(Maybe<Audio> & Track):
  match track:
    case Track{clock,time,carry,cursor,step,voices,+active,stage,control}: dispatch_active(active,audio,Track{clock,time,carry,cursor,step,voices,active,stage,control},cue)
