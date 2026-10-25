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
# Four themes: Iron March, Crypt Gallop, Ash Waltz (4/4 triplet-like riff), Night Engine.
# Alternate disjoint pairs, with a seeded choice inside each pair. Adjacent
# phrases cannot repeat, and no host needs a playlist or a transition queue.
def pair_choice(pair: Bool,bit: Bool) -> U32:
  match pair bit:
    case False{} False{}: 0
    case False{} True{}: 1
    case True{} False{}: 2
    case True{} True{}: 3
def composition(+step: U32,+seed: U32) -> U32:
  +phrase = (step / 512 : U32)
  pair_choice(U32.is_eq(((phrase + seed % 2) % 2 : U32),1),U32.is_eq(((phrase * 1664525 + seed * 1013904223 + 12345) / 65536 % 2 : U32),1))
def theme_root(theme: U32,bar: U32) -> U32:
  match theme:
    case 0: at([28,24,26,23,28,31,26,23],bar)
    case 1: at([28,28,31,26,24,26,23,23],bar)
    case 2: at([28,35,31,26,28,24,26,23],bar)
    case _: at([28,26,24,26,28,31,24,23],bar)
def riff_offset(theme: U32,step: U32) -> U32:
  match theme:
    case 0: at([0,0,0,1,0,7,0,3,0,0,0,1,0,10,7,3],(step % 16 : U32))
    case 1: at([0,0,7,0,0,7,3,0,0,0,10,0,7,3,1,0],(step % 16 : U32))
    case 2: at([0,7,12,0,3,7,0,7,10,0,3,7,0,1,3,7],(step % 16 : U32))
    case _: at([0,12,0,10,0,7,0,3,0,12,0,15,14,10,7,1],(step % 16 : U32))
def lead_offset(theme: U32,step: U32) -> U32:
  match theme:
    case 0: at([12,15,19,20,19,15,14,7],(step / 4 % 8 : U32))
    case 1: at([19,19,22,19,15,14,12,14],(step / 4 % 8 : U32))
    case 2: at([12,19,15,22,20,19,15,14],(step / 4 % 8 : U32))
    case _: at([24,19,22,15,19,14,15,12],(step / 4 % 8 : U32))
def riff_hit(theme: U32,+step: U32) -> Bool:
  match theme:
    case 1: Bool.not(U32.is_eq((step % 4 : U32),3))
    case 2: Bool.or(U32.is_eq((step % 3 : U32),0),U32.is_eq((step % 16 : U32),14))
    case _: True{}
def kick_hit(theme: U32,+step: U32) -> Bool:
  match theme:
    case 0: U32.is_eq((step % 8 : U32),6)
    case 1: Bool.or(U32.is_eq((step % 8 : U32),2),U32.is_eq((step % 8 : U32),3))
    case 2: U32.is_eq((step % 8 : U32),3)
    case _: U32.is_eq((step % 8 : U32),7)
def drums(+step: U32,+band: U32,theme: U32,tail: List<&2,Note>) -> List<&2,Note>:
  add(Bool.and(U32.is_eq((step % 64 : U32),0),U32.is_le(2,band)),6,60,4,450,
  add(Bool.and(U32.is_lt(0,band),Bool.or(U32.is_le(2,band),U32.is_eq((step % 2 : U32),0))),5,84,1,250,
  add(Bool.or(U32.is_eq((step % 16 : U32),4),U32.is_eq((step % 16 : U32),12)),4,38,1,(450 + 100 * band : U32),
  add(Bool.or(U32.is_eq((step % 8 : U32),0),Bool.and(U32.is_lt(0,band),Bool.or(kick_hit(theme,step),Bool.and(U32.is_eq(band,3),U32.is_eq((step % 2 : U32),0))))),3,36,1,(550 + 100 * band : U32),tail))))
def score(+step: U32,+band: U32,+base: U32,+theme: U32) -> List<&2,Note>:
  add(Bool.or(U32.is_eq((step % 4 : U32),0),Bool.and(U32.is_le(2,band),U32.is_eq((step % 2 : U32),0))),0,base,1,650,
  add(Bool.and(riff_hit(theme,step),Bool.and(Bool.or(U32.is_eq((step % 4 : U32),0),U32.is_lt(0,band)),Bool.or(U32.is_le(2,band),U32.is_eq((step % 2 : U32),0)))),1,(base + 12 + riff_offset(theme,step) : U32),1,(420 + 100 * band : U32),
  add(Bool.and(U32.is_le(2,band),U32.is_eq((step % 8 : U32),0)),1,(base + 19 : U32),2,300,
  add(Bool.and(U32.is_eq((step % 4 : U32),2),Bool.or(U32.is_eq(band,3),Bool.and(U32.is_le(1,band),U32.is_le(128,(step % 256 : U32))))),2,(base + 24 + lead_offset(theme,step) : U32),2,300,
  drums(step,band,theme,[])))))
def theme_notes(+step: U32,stage: U32,band: U32,+theme: U32) -> List<&2,Note>:
  score(step,U32.min(3,band),(theme_root(theme,(step / 16 % 8 : U32)) + at([0,2,5,7,3],(stage % 5 : U32)) : U32),theme)
def notes_seed(+step: U32,stage: U32,band: U32,seed: U32) -> List<&2,Note>:
  theme_notes(step,stage,band,composition(step,seed))
def notes(step: U32,+stage: U32,band: U32) -> List<&2,Note>:
  notes_seed(step,stage,band,stage)

# Ordinary danger builds over seconds; emergencies bypass the rise envelope.
# These are fixed 100ms observations, not ticks.
def release(+previous: U32,+raw: U32) -> U32:
  (previous - U32.min(previous,((previous - raw + 7) / 8 : U32)) : U32)
def rise_policy(emergency: Bool,+previous: U32,+raw: U32) -> U32:
  match emergency:
    case True{}: raw
    case False{}: (previous + U32.min(12,((raw - previous + 23) / 24 : U32)) : U32)
def smooth_direction(rising: Bool,+previous: U32,+raw: U32) -> U32:
  match rising:
    case True{}: rise_policy(U32.is_le(900,raw),previous,raw)
    case False{}: release(previous,raw)
def smooth(+previous: U32,+raw: U32) -> U32:
  smooth_direction(U32.is_lt(U32.min(previous,1000),U32.min(raw,1000)),U32.min(previous,1000),U32.min(raw,1000))
# Up/down thresholds differ: nearby enemies do not make instrumentation chatter.
def target_band(previous: U32,+danger: U32) -> U32:
  match previous:
    case 0: Bool.pick(U32,U32.is_le(900,danger),3,U32.min(2,(danger / 325 : U32)))
    case 1: Bool.pick(U32,U32.is_lt(danger,240),0,Bool.pick(U32,U32.is_le(900,danger),3,U32.min(2,U32.max(1,(danger / 325 : U32)))))
    case 2: Bool.pick(U32,U32.is_lt(danger,560),Bool.pick(U32,U32.is_lt(danger,240),0,1),Bool.pick(U32,U32.is_le(900,danger),3,2))
    case _: Bool.pick(U32,U32.is_lt(danger,800),Bool.pick(U32,U32.is_lt(danger,560),Bool.pick(U32,U32.is_lt(danger,240),0,1),2),3)
def boundary(atBar: Bool,active: U32,latest: U32) -> U32:
  match atBar:
    case True{}: U32.min(3,latest)
    case False{}: active
# There is exactly one latest target. Never enqueue obsolete transitions.
def commit(step: U32,active: U32,latest: U32) -> U32:
  boundary(U32.is_eq((step % 16 : U32),0),active,latest)
def danger(+hp: U32,maxHp: U32,pressure: U32) -> U32:
  U32.min(1000,((100 - U32.min(100,(hp * 100 / U32.max(1,maxHp) : U32))) * 5 / 2 + U32.min(1000,pressure) : U32))

# Narrow read-only enemy observation for host-cadence music decisions.
type Threat is Data: Threat{x: F32,y: F32,archetype: U32}
def enemy_weight(+archetype: U32) -> U32:
  (1 + 3 * Bool.to_u32(U32.is_le(20,archetype)) + 32 * Bool.to_u32(U32.is_eq(archetype,30)) + Bool.to_u32(Bool.or(U32.is_eq(archetype,4),Bool.or(U32.is_eq(archetype,12),U32.is_eq(archetype,19)))) : U32)
def threat_distance(+x: F32,+y: F32,+px: F32,+py: F32) -> F32:
  ((x - px) * (x - px) + (y - py) * (y - py) : F32)
def enemy_pressure_at(archetype: U32,+range: F32) -> U32:
  (enemy_weight(archetype) * (3 * Bool.to_u32(F32.is_le(range,102400.0)) + 27 * Bool.to_u32(F32.is_le(range,10000.0))) : U32)
def enemy_pressure(rows: List<&2,Threat>,+px: F32,+py: F32) -> U32:
  match rows:
    case []: 0
    case Threat{x,y,archetype} <> rest:
      U32.min(1000,(enemy_pressure_at(archetype,threat_distance(x,y,px,py)) + enemy_pressure(rest,px,py) : U32))
