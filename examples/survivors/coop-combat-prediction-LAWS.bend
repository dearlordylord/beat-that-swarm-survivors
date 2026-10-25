import Base
import ./coop-combat-prediction-policy.bend as C
import ./coop-prediction-replay.bend as Replay
import ./coop-prediction.bend as P
import ./projectile-contact.bend as Contact
import ./body-index.bend as BI

# Scope: these are the production-used detached cohort/adoption/contact-policy
# laws. The Game adapters are qualified by real authority/forecast parity runs;
# no statement here claims to kernel-prove the entire imported ECS game.
def contact_tick(value:C.Witness) -> U32:
  match value:
    case C.Witness{_,tick,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: tick

# Guarantees: the cohort admission predicate accepts exactly enemies and both
# projectile kinds. Runtime tests check that collection and rendering use it.
# Why it matters: forecasting only the local projectile mixes two time lines.
law cohort_kind_exact:
  for +kind:U32
  {C.cohort_kind(kind) == Bool.or(U32.is_eq(kind,0),Bool.or(U32.is_eq(kind,1),U32.is_eq(kind,7))) : Bool}

# Guarantees: the cohort clock helper increments its input exactly once.
# Runtime tests qualify its use in stepping and actor render tags.
# Why it matters: actor roles must not use different prediction clocks.
law cohort_clock_exact:
  for +tick:U32
  {C.next_tick(tick) == (tick + 1 : U32) : U32}

# Guarantees: decoding an explicit machine word constructs exactly those F32 bits.
# Why it matters: nested JSON fields must enter game arithmetic as native F32.
law native_float_bits_exact:
  for +bits:Word(32n)
  {C.from_bits(U32{bits}) == F32{bits} : F32}

# Guarantees: received numeric fields pass through the native F32 bit codec.
# Why it matters: raw JSON binary64 fields bypass scalar F32 export wrappers and
# can otherwise change a later shared movement operation by one ULP. This pins
# the adapter operation; external JS-number behavior is also tested at runtime.
law receive_normalization_uses_bits:
  for +value:F32
  {C.normalize(value) == C.from_bits(F32.bits(value)) : F32}

# Guarantees: canonical adoption returns the complete fresh anchor, regardless
# of every field of the previous presentation state.
# Why it matters: projectile velocity, visited hits and enemy status from an
# earlier observation cannot be retained over a new authoritative anchor.
law canonical_fresh:
  for ~A:Data
  for previous:A
  for +fresh:A
  {C.canonical(~A,previous,fresh) == fresh : A}

# Guarantees: reconciliation starts from the fresh anchor and replays exactly
# the current unconsumed input suffix using the common bounded replay kernel.
# Why it matters: selecting fresh state alone must not discard local input.
law canonical_suffix_exact:
  for ~A:Data
  for ~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A
  for previous:A
  for +fresh:A
  for +prediction:P.State
  {C.rebase(~A,~advance,previous,fresh,prediction) == Replay.forecast(~A,~advance,fresh,prediction) : A}

# Guarantees: a failed actual sweep creates no diagnostic contact witness.
# Why it matters: the trace cannot manufacture a hit to explain a missed enemy.
law sweep_miss_has_no_witness:
  for tick:U32
  for shot:U32
  for target:U32
  for x0:F32
  for y0:F32
  for x1:F32
  for y1:F32
  for ex0:F32
  for ey0:F32
  for ex1:F32
  for ey1:F32
  for radius:F32
  {C.record(Contact.Miss{},tick,shot,target,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius) == None{} : Maybe<&2,C.Witness>}

# Guarantees: an actual sweep hit records its exact time and path geometry,
# and is explicitly a swept contact rather than a point-area contact.
# Why it matters: visual evidence must come from the same contact calculation.
law sweep_hit_exact:
  for +tick:U32
  for +shot:U32
  for +target:U32
  for +x0:F32
  for +y0:F32
  for +x1:F32
  for +y1:F32
  for +ex0:F32
  for +ey0:F32
  for +ex1:F32
  for +ey1:F32
  for +radius:F32
  for +time:F32
  {C.record(Contact.Hit{time},tick,shot,target,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius) == Some{C.Witness{0,tick,shot,target,0,0,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,time}} : Maybe<&2,C.Witness>}

# Guarantees: reported swept contacts are classified by the existing actual
# continuous-contact solver over the exact two relative movement segments.
# Why it matters: endpoint overlap cannot substitute for a swept contact.
law sweep_solver_is_source:
  for +tick:U32
  for +shot:U32
  for +target:U32
  for +x0:F32
  for +y0:F32
  for +x1:F32
  for +y1:F32
  for +ex0:F32
  for +ey0:F32
  for +ex1:F32
  for +ey1:F32
  for +radius:F32
  {C.witness(tick,shot,target,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius) == C.record(Contact.sweep(x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius),tick,shot,target,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius) : Maybe<&2,C.Witness>}

# Guarantees: a rejected actual point-area predicate creates no witness.
# Why it matters: area contacts must not be mislabeled as successful sweeps.
law point_miss_has_no_witness:
  for tick:U32
  for shot:U32
  for target:U32
  for x:F32
  for y:F32
  for ex:F32
  for ey:F32
  for radius:F32
  {C.point_record(False{},tick,shot,target,x,y,ex,ey,radius) == None{} : Maybe<&2,C.Witness>}

# Guarantees: an accepted actual point predicate records a separate point
# contact at the resolved positions; its segments do not claim swept travel.
# Why it matters: area fields and ballistic contacts have distinct semantics.
law point_hit_exact:
  for +tick:U32
  for +shot:U32
  for +target:U32
  for +x:F32
  for +y:F32
  for +ex:F32
  for +ey:F32
  for +radius:F32
  {C.point_record(True{},tick,shot,target,x,y,ex,ey,radius) == Some{C.Witness{1,tick,shot,target,0,0,x,y,x,y,ex,ey,ex,ey,radius,0.0}} : Maybe<&2,C.Witness>}

# Guarantees: both physical IDs are stamped with the birth-index lookup for
# their respective IDs, without changing geometry. Completeness and uniqueness
# of that index are separate runtime obligations, not proved by this law.
# Why it matters: contact traces must distinguish reused pool slots.
law witness_lifetimes_exact:
  for +births:BI.Index<U32>
  for +kind:U32
  for +tick:U32
  for +shot:U32
  for +target:U32
  for +shotBirth:U32
  for +targetBirth:U32
  for +x0:F32
  for +y0:F32
  for +x1:F32
  for +y1:F32
  for +ex0:F32
  for +ey0:F32
  for +ex1:F32
  for +ey1:F32
  for +radius:F32
  for +time:F32
  {C.stamp_births(births,C.Witness{kind,tick,shot,target,shotBirth,targetBirth,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,time}) == C.Witness{kind,tick,shot,target,BI.get(~U32,births,shot,0),BI.get(~U32,births,target,0),x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,time} : C.Witness}

# Guarantees: diagnostic witnesses cover the latest four physics ticks only.
# Why it matters: a long local run cannot accumulate an unbounded trace history;
# this TTL does not limit, omit or alter any simulated combat interaction.
law diagnostic_ttl_exact:
  {C.ttl_ticks() == 4 : U32}

# Guarantees: the diagnostic retention predicate uses the declared four-tick
# window over the witness's original contact tick.
# Why it matters: old collisions cannot be presented as newly observed hits.
law diagnostic_recent_exact:
  for +now:U32
  for +value:C.Witness
  {C.recent(now,value) == U32.is_lt((now - contact_tick(value) : U32),4) : Bool}
