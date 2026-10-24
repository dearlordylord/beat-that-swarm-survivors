import Base

# Shared chip-metal score. The hosts only schedule and synthesize these notes.
type Note is Data: Note{voice: U32,pitch: U32,length: U32,accent: U32}
def bpm() -> U32: 132
def sample_rate() -> U32: 22050
def step_seconds() -> F32: (60.0 / 132.0 / 4.0 : F32)
def at(values: List<&2,U32>,index: U32) -> U32:
  match values index:
    case [] _: 0
    case value <> _ 0: value
    case _ <> rest index: at(rest,(index - 1 : U32))
def semitone(index: U32) -> F32:
  match index:
    case 0: 8.175799
    case 1: 8.661957
    case 2: 9.177024
    case 3: 9.722718
    case 4: 10.300861
    case 5: 10.913382
    case 6: 11.562326
    case 7: 12.249857
    case 8: 12.978272
    case 9: 13.750000
    case 10: 14.567618
    case _: 15.433853
def frequency(+pitch: U32) -> F32:
  (semitone((pitch % 12 : U32)) * U32.to_f32(U32.shln(1,U32.to_nat((U32.min(pitch,127) / 12 : U32)))) : F32)
def add(enabled: Bool,voice: U32,pitch: U32,length: U32,accent: U32,tail: List<&2,Note>) -> List<&2,Note>:
  match enabled:
    case True{}: Note{voice,pitch,length,accent} <> tail
    case False{}: tail
def root(+step: U32,stage: U32) -> U32:
  (at([28,24,26,23],(step / 16 % 4 : U32)) + at([0,2,5,7,3],(stage % 5 : U32)) : U32)
def riff_offset(step: U32) -> U32: at([0,0,0,1,0,7,0,3,0,0,0,1,0,10,7,3],(step % 16 : U32))
def lead_offset(step: U32) -> U32: at([12,15,19,20,19,15,14,7],(step / 4 % 8 : U32))
def drums(+step: U32,+band: U32,tail: List<&2,Note>) -> List<&2,Note>:
  add(Bool.and(U32.is_eq((step % 64 : U32),0),U32.is_le(2,band)),6,60,4,450,
  add(Bool.and(U32.is_lt(0,band),Bool.or(U32.is_le(2,band),U32.is_eq((step % 2 : U32),0))),5,84,1,250,
  add(Bool.or(U32.is_eq((step % 16 : U32),4),U32.is_eq((step % 16 : U32),12)),4,38,1,(450 + 100 * band : U32),
  add(Bool.or(U32.is_eq((step % 8 : U32),0),Bool.and(U32.is_lt(0,band),Bool.or(U32.is_eq((step % 8 : U32),6),Bool.and(U32.is_eq(band,3),U32.is_eq((step % 2 : U32),0))))),3,36,1,(550 + 100 * band : U32),tail))))
def score(+step: U32,+band: U32,+base: U32) -> List<&2,Note>:
  add(Bool.or(U32.is_eq((step % 4 : U32),0),Bool.and(U32.is_le(2,band),U32.is_eq((step % 2 : U32),0))),0,base,1,650,
  add(Bool.and(Bool.or(U32.is_eq((step % 4 : U32),0),U32.is_lt(0,band)),Bool.or(U32.is_le(2,band),U32.is_eq((step % 2 : U32),0))),1,(base + 12 + riff_offset(step) : U32),1,(420 + 100 * band : U32),
  add(Bool.and(U32.is_le(2,band),U32.is_eq((step % 8 : U32),0)),1,(base + 19 : U32),2,300,
  add(Bool.and(U32.is_eq((step % 4 : U32),2),Bool.or(U32.is_eq(band,3),Bool.and(U32.is_le(1,band),U32.is_le(128,(step % 256 : U32))))),2,(base + 24 + lead_offset(step) : U32),2,300,
  drums(step,band,[])))))
def notes(+step: U32,stage: U32,band: U32) -> List<&2,Note>:
  score(step,U32.min(3,band),root(step,stage))

# Rise quickly, release more slowly. These are fixed 100ms observations, not ticks.
def release(+previous: U32,+raw: U32) -> U32:
  (previous - U32.min(previous,((previous - raw + 7) / 8 : U32)) : U32)
def smooth_direction(rising: Bool,+previous: U32,+raw: U32) -> U32:
  match rising:
    case True{}: (previous + (raw - previous + 1) / 2 : U32)
    case False{}: release(previous,raw)
def smooth(+previous: U32,+raw: U32) -> U32:
  smooth_direction(U32.is_lt(U32.min(previous,1000),U32.min(raw,1000)),U32.min(previous,1000),U32.min(raw,1000))
# Up/down thresholds differ: nearby enemies do not make instrumentation chatter.
def target_band(previous: U32,+danger: U32) -> U32:
  match previous:
    case 0: U32.min(3,(danger / 250 : U32))
    case 1: Bool.pick(U32,U32.is_lt(danger,170),0,U32.min(3,U32.max(1,(danger / 250 : U32))))
    case 2: Bool.pick(U32,U32.is_lt(danger,420),Bool.pick(U32,U32.is_lt(danger,170),0,1),Bool.pick(U32,U32.is_le(750,danger),3,2))
    case _: Bool.pick(U32,U32.is_lt(danger,670),Bool.pick(U32,U32.is_lt(danger,420),Bool.pick(U32,U32.is_lt(danger,170),0,1),2),3)
def boundary(atBar: Bool,active: U32,latest: U32) -> U32:
  match atBar:
    case True{}: U32.min(3,latest)
    case False{}: active
# There is exactly one latest target. Never enqueue obsolete transitions.
def commit(step: U32,active: U32,latest: U32) -> U32:
  boundary(U32.is_eq((step % 16 : U32),0),active,latest)
def danger(+hp: U32,maxHp: U32,pressure: U32) -> U32:
  U32.min(1000,((100 - U32.min(100,(hp * 100 / U32.max(1,maxHp) : U32))) * 3 + U32.min(1000,pressure) : U32))
