import Base
import ./audio-events.bend as S
import ./body-index.bend as BI

# Independent field projections used by public-boundary laws.
def run(meta:S.Meta) -> String:
  match meta:
    case S.Meta{value,_,_,_,_,_,_,_,_,_,_}: value
def tick(meta:S.Meta) -> U32:
  match meta:
    case S.Meta{_,value,_,_,_,_,_,_,_,_,_}: value
def x(meta:S.Meta) -> F32:
  match meta:
    case S.Meta{_,_,_,_,_,_,_,_,_,value,_}: value
def confirmed(meta:S.Meta) -> Bool:
  match meta:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,value}: value
def body_seed(body:S.Body) -> U32:
  match body:
    case S.Body{value,_,_,_,_,_,_,_}: value

def same_spec(+a:S.Stamp,+b:S.Stamp) -> Bool:
  match a b:
    case S.Stamp{S.Body{+aSeed,+ak,+av,_,_,_,_,+ag},+ab} S.Stamp{S.Body{+bSeed,+bk,+bv,_,_,_,_,+bg},+bb}: Bool.and(U32.is_eq(aSeed,bSeed),Bool.and(U32.is_eq(ak,bk),Bool.and(U32.is_eq(av,bv),S.same_generation(ag,bg,ab,bb))))

def meta_spec(+old:S.Meta,+current:S.Meta,+events:List<&2,S.Sound>) -> List<&2,S.Sound>:
  match old current:
    case S.Meta{_,_,+oldPhase,+oldRound,+oldHp,+oldKills,+oldGold,+oldXp,+oldLevel,_,_} S.Meta{_,_,+phase,+round,+hp,+kills,+gold,+xp,+level,_,+confirmed}:
      S.add(Bool.and(U32.is_eq(phase,4),U32.is_ne(oldPhase,4)),12,0.0,0.0,
      S.add(Bool.and(U32.is_eq(phase,3),U32.is_ne(oldPhase,3)),11,0.0,0.0,
      S.add(Bool.and(U32.is_eq(phase,2),Bool.or(U32.is_ne(oldPhase,2),U32.is_ne(oldRound,round))),10,0.0,0.0,
      S.add(Bool.and(U32.is_eq(phase,1),Bool.or(U32.is_ne(oldPhase,1),U32.is_ne(oldRound,round))),9,0.0,0.0,
      S.add(Bool.or(U32.is_gt(gold,oldGold),Bool.or(U32.is_gt(xp,oldXp),U32.is_gt(level,oldLevel))),5,0.0,0.0,
      S.add(U32.is_gt(hp,oldHp),4,0.0,0.0,
      S.add(U32.is_gt(kills,oldKills),3,0.0,0.0,
      S.add(Bool.and(Bool.not(confirmed),U32.is_gt(kills,oldKills)),1,0.0,0.0,
      S.add(U32.is_lt(hp,oldHp),2,0.0,0.0,events)))))))))

# Guarantees: Birth identity uses a saturating tick-minus-age, including malformed ages.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law birth_exact:
  for +tick:U32
  for +age:U32
  {S.born(tick,age) == (tick - U32.min(tick,age) : U32) : U32}

# Guarantees: Explicit lifetimes override the fallback birth tick; empty IDs use birth ticks.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law generation_exact:
  for +a:String
  for +b:String
  for +at:U32
  for +bt:U32
  {S.same_generation(a,b,at,bt) == Bool.pick(Bool,Bool.and(Bool.not(String.eq(a,"")),Bool.not(String.eq(b,""))),String.eq(a,b),U32.is_eq(at,bt)) : Bool}

# Guarantees: Only player shots, area effects and hostile shots create attack sounds.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law attack_exact:
  for +kind:U32
  {S.attack(kind) == Bool.or(U32.is_eq(kind,1),Bool.or(U32.is_eq(kind,6),U32.is_eq(kind,7))) : Bool}

# Guarantees: Hostile fire and magic keep their own sound families.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law attack_kind_exact:
  for +kind:U32
  {S.attack_kind(kind) == Bool.pick(U32,U32.is_eq(kind,7),6,Bool.pick(U32,U32.is_eq(kind,6),7,0)) : U32}

# Guarantees: Stereo positioning uses a bounded machine-F32 projection, not game movement.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law pan_exact:
  for +x:F32
  for +viewer:F32
  {S.pan(x,viewer) == F32.clamp(((x - viewer) / 400.0 : F32),(0.0 - 0.8 : F32),0.8) : F32}

# Guarantees: An admitted sound is prepended without altering prior output.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law sound_added_exact:
  for +kind:U32
  for +x:F32
  for +viewer:F32
  for +tail:List<&2,S.Sound>
  {S.add(True{},kind,x,viewer,tail) == S.Sound{kind,S.pan(x,viewer)} <> tail : List<&2,S.Sound>}

# Guarantees: A refused sound cannot fabricate output.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law sound_refused_exact:
  for +kind:U32
  for +x:F32
  for +viewer:F32
  for +tail:List<&2,S.Sound>
  {S.add(False{},kind,x,viewer,tail) == tail : List<&2,S.Sound>}

# Guarantees: A newly observed attack lifetime produces its sound in solo and co-op.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law new_shot:
  for +seed:U32
  for +variant:U32
  for +age:U32
  for +hp:U32
  for +x:F32
  for +radius:F32
  for +generation:String
  for +born:U32
  for +viewer:F32
  for +confirmed:Bool
  {S.row_events(None{},S.Stamp{S.Body{seed,1,variant,age,hp,x,radius,generation},born},viewer,confirmed,[]) == [S.Sound{0,S.pan(x,viewer)}] : List<&2,S.Sound>}

# Guarantees: A newly observed attack lifetime produces its sound in solo and co-op.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law new_area:
  for +seed:U32
  for +variant:U32
  for +age:U32
  for +hp:U32
  for +x:F32
  for +radius:F32
  for +generation:String
  for +born:U32
  for +viewer:F32
  for +confirmed:Bool
  {S.row_events(None{},S.Stamp{S.Body{seed,6,variant,age,hp,x,radius,generation},born},viewer,confirmed,[]) == [S.Sound{7,S.pan(x,viewer)}] : List<&2,S.Sound>}

# Guarantees: A newly observed attack lifetime produces its sound in solo and co-op.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law new_hostile:
  for +seed:U32
  for +variant:U32
  for +age:U32
  for +hp:U32
  for +x:F32
  for +radius:F32
  for +generation:String
  for +born:U32
  for +viewer:F32
  for +confirmed:Bool
  {S.row_events(None{},S.Stamp{S.Body{seed,7,variant,age,hp,x,radius,generation},born},viewer,confirmed,[]) == [S.Sound{6,S.pan(x,viewer)}] : List<&2,S.Sound>}

# Guarantees: An enemy entering view does not make a firing sound.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law new_enemy_is_not_a_shot:
  for +seed:U32
  for +x:F32
  for +viewer:F32
  for +confirmed:Bool
  {S.row_events(None{},S.Stamp{S.Body{seed,0,0,0,10,x,8.0,""},0},viewer,confirmed,[]) == [] : List<&2,S.Sound>}

# Guarantees: Damage, radius bursts and reused attack slots follow separate exact predicates.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law body_changes_exact:
  for +matching:Bool
  for +oldHp:U32
  for +oldRadius:F32
  for +kind:U32
  for +hp:U32
  for +x:F32
  for +radius:F32
  for +viewer:F32
  for +confirmed:Bool
  for +events:List<&2,S.Sound>
  {S.changed_events(matching,S.Stamp{S.Body{0,0,0,0,oldHp,0.0,oldRadius,""},0},S.Stamp{S.Body{0,kind,0,0,hp,x,radius,""},0},viewer,confirmed,events) ==
    S.add(Bool.and(matching,Bool.and(U32.is_eq(kind,1),Bool.and(F32.is_gt(oldRadius,0.0),Bool.and(F32.is_gt(radius,oldRadius),F32.is_ge(radius,(oldRadius * 2.0 : F32)))))),8,x,viewer,
    S.add(Bool.and(matching,Bool.and(Bool.not(confirmed),Bool.and(U32.is_eq(kind,0),U32.is_lt(hp,oldHp)))),1,x,viewer,
    S.add(Bool.and(Bool.not(matching),S.attack(kind)),S.attack_kind(kind),x,viewer,events))) : List<&2,S.Sound>}

# Guarantees: Joining an existing run records its baseline without replaying old attacks.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law baseline_discards_history:
  for +meta:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +events:List<&2,S.Sound>
  {S.baseline_ready(meta,S.Scanned{bodies,events}) == S.Out{S.State{True{},meta,bodies,S.meta_tick(meta)},[]} : S.Out}

# Guarantees: The first snapshot cannot sound every projectile already in flight.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law initial_observation_baselines:
  for +old:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +impact:U32
  for +current:S.Meta
  for +rows:List<&2,S.Body>
  {S.observe(S.State{False{},old,bodies,impact},current,rows) == S.baseline(current,rows) : S.Out}

# Guarantees: Repeated network/render ticks cannot create body-birth sounds.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law same_tick_keeps_body_history:
  for +old:S.Meta
  for +current:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +impact:U32
  for +rows:List<&2,S.Body>
  {S.observe_same(False{},old,current,bodies,impact,rows) == S.Out{S.State{True{},current,bodies,impact},S.meta_events(old,current,[])} : S.Out}

# Guarantees: Out-of-order snapshots cannot rewind sound history or replay attacks.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law stale_frame_is_silent:
  for +state:S.State
  for +old:S.Meta
  for +current:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +impact:U32
  for +rows:List<&2,S.Body>
  {S.observe_time(True{},state,old,current,bodies,impact,rows) == S.Out{state,[]} : S.Out}

# Guarantees: A new run cannot inherit sound identities from the previous run.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law new_run_baselines:
  for +state:S.State
  for +current:S.Meta
  for +rows:List<&2,S.Body>
  {S.observe_existing(False{},state,current,rows) == S.baseline(current,rows) : S.Out}

# Guarantees: Tick-zero configuration cannot pretend that health setup was combat damage.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law setup_is_silent:
  for +old:S.Meta
  for +current:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +impact:U32
  for +rows:List<&2,S.Body>
  {S.observe_configuring(True{},old,current,bodies,impact,rows) == S.baseline(current,rows) : S.Out}

# Guarantees: Only an unplayed, authority-supported contact tick can sound.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law impact_admission_exact:
  for +tick:U32
  for +after:U32
  for +now:U32
  {S.impact_allowed(tick,after,now) == Bool.and(U32.is_gt(tick,after),U32.is_le(tick,now)) : Bool}

# Guarantees: Old or future contacts do not replace the sound cursor.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law rejected_impact_preserves:
  for +head:S.Impact
  for +tail:Maybe<&2,S.Impact>
  {S.later_impact(False{},head,tail) == tail : Maybe<&2,S.Impact>}

# Guarantees: Finishing a contact batch preserves its selected newest valid contact.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law latest_impact_empty:
  for +after:U32
  for +now:U32
  for +best:Maybe<&2,S.Impact>
  {S.latest_impact_go([],after,now,best) == best : Maybe<&2,S.Impact>}

# Guarantees: Every contact is considered, with no replay or tail omission.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law latest_impact_step:
  for +head:S.Impact
  for +tail:List<&2,S.Impact>
  for +after:U32
  for +now:U32
  for +best:Maybe<&2,S.Impact>
  {S.latest_impact_go(head <> tail,after,now,best) == S.latest_impact_go(tail,after,now,S.impact_step(head,after,now,best)) : Maybe<&2,S.Impact>}

# Guarantees: A frame without new due contacts cannot invent an impact.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law no_impact_is_silent:
  for +state:S.State
  {S.impact_result(state,None{}) == S.Out{state,[]} : S.Out}

# Guarantees: Sounding a contact advances the cursor to that exact contact tick.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law impact_commit_exact:
  for +ready:Bool
  for +meta:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +previous:U32
  for +tick:U32
  for +x:F32
  {S.impact_result(S.State{ready,meta,bodies,previous},Some{S.Impact{tick,x}}) == S.Out{S.State{ready,meta,bodies,tick},[S.Sound{1,S.pan(x,S.meta_x(meta))}]} : S.Out}

# Guarantees: The IO entry uses the deduplicating contact selection, not the raw contact list.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law public_impacts_exact:
  for +meta:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +after:U32
  for +rows:List<&2,S.Impact>
  {S.impacts(S.State{True{},meta,bodies,after},rows) == S.impact_result(S.State{True{},meta,bodies,after},S.latest_impact(rows,after,S.meta_tick(meta))) : S.Out}

# Guarantees: A not-yet-attached browser cannot replay historical contact sounds.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law unattached_impacts_are_silent:
  for +meta:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +after:U32
  for +rows:List<&2,S.Impact>
  {S.impacts(S.State{False{},meta,bodies,after},rows) == S.Out{S.State{False{},meta,bodies,after},[]} : S.Out}

# Guarantees: Existing bodies use their immutable lifetime before selecting damage or a new birth.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law known_row_dispatch:
  for +old:S.Stamp
  for +current:S.Stamp
  for +viewer:F32
  for +confirmed:Bool
  for +events:List<&2,S.Sound>
  {S.row_events(Some{old},current,viewer,confirmed,events) == S.changed_events(S.same(old,current),old,current,viewer,confirmed,events) : List<&2,S.Sound>}

# Guarantees: The iterative body scan retains all selected sound events in observation order.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law scan_empty:
  for +previous:BI.Index<S.Stamp>
  for +tick:U32
  for +viewer:F32
  for +confirmed:Bool
  for +index:BI.Index<S.Stamp>
  for +events:List<&2,S.Sound>
  {S.scan([],previous,tick,viewer,confirmed,index,events) == S.Scanned{index,List.reverse(&2,S.Sound,events)} : S.Scanned}

# Guarantees: Every observed row reaches the lifetime check and next-frame index.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law scan_step:
  for +head:S.Body
  for +tail:List<&2,S.Body>
  for +previous:BI.Index<S.Stamp>
  for +tick:U32
  for +viewer:F32
  for +confirmed:Bool
  for +index:BI.Index<S.Stamp>
  for +events:List<&2,S.Sound>
  {S.scan(head <> tail,previous,tick,viewer,confirmed,index,events) == S.scan(tail,previous,tick,viewer,confirmed,BI.insert(~S.Stamp,index,body_seed(head),S.stamp(head,tick)),S.row_events(BI.find(~S.Stamp,previous,body_seed(head)),S.stamp(head,tick),viewer,confirmed,events)) : S.Scanned}

# Guarantees: Baseline construction cannot silently discard body identities needed for deduplication.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law baseline_public_exact:
  for +meta:S.Meta
  for +rows:List<&2,S.Body>
  {S.baseline(meta,rows) == S.baseline_ready(meta,S.scan(rows,BI.Empty{},tick(meta),x(meta),confirmed(meta),BI.Empty{},[])) : S.Out}

# Guarantees: Body events and metadata events are both delivered to the audio adapter.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law observed_public_exact:
  for +old:S.Meta
  for +current:S.Meta
  for +impact:U32
  for +bodies:BI.Index<S.Stamp>
  for +events:List<&2,S.Sound>
  {S.observed(old,current,impact,S.Scanned{bodies,events}) == S.Out{S.State{True{},current,bodies,impact},S.meta_events(old,current,events)} : S.Out}

# Guarantees: A new authoritative tick actually invokes body event detection.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law newer_frame_scans:
  for +old:S.Meta
  for +current:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +impact:U32
  for +rows:List<&2,S.Body>
  {S.observe_same(True{},old,current,bodies,impact,rows) == S.observed(old,current,impact,S.scan(rows,bodies,tick(current),x(current),confirmed(current),BI.Empty{},[])) : S.Out}

# Guarantees: Only a genuinely newer tick can rescan bodies.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law configuration_dispatch:
  for +old:S.Meta
  for +current:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +impact:U32
  for +rows:List<&2,S.Body>
  {S.observe_configuring(False{},old,current,bodies,impact,rows) == S.observe_same(U32.is_gt(tick(current),tick(old)),old,current,bodies,impact,rows) : S.Out}

# Guarantees: The public path distinguishes setup from live observations.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law time_dispatch:
  for +state:S.State
  for +old:S.Meta
  for +current:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +impact:U32
  for +rows:List<&2,S.Body>
  {S.observe_time(False{},state,old,current,bodies,impact,rows) == S.observe_configuring(Bool.and(U32.is_eq(tick(old),0),U32.is_eq(tick(current),0)),old,current,bodies,impact,rows) : S.Out}

# Guarantees: The actual stale-frame predicate is tied to the retained and incoming world ticks.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law existing_run_dispatch:
  for +ready:Bool
  for +old:S.Meta
  for +current:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +impact:U32
  for +rows:List<&2,S.Body>
  {S.observe_existing(True{},S.State{ready,old,bodies,impact},current,rows) == S.observe_time(U32.is_lt(tick(current),tick(old)),S.State{ready,old,bodies,impact},old,current,bodies,impact,rows) : S.Out}

# Guarantees: Production playback cannot bypass deduplication or the run-identity boundary.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law public_ready_dispatch:
  for +old:S.Meta
  for +current:S.Meta
  for +bodies:BI.Index<S.Stamp>
  for +impact:U32
  for +rows:List<&2,S.Body>
  {S.observe(S.State{True{},old,bodies,impact},current,rows) == S.observe_existing(String.eq(run(old),run(current)),S.State{True{},old,bodies,impact},current,rows) : S.Out}

# Guarantees: A confirmed contact cannot bypass the already-played or future-tick guard.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law impact_row_dispatch:
  for +at:U32
  for +x:F32
  for +after:U32
  for +now:U32
  for +best:Maybe<&2,S.Impact>
  {S.impact_step(S.Impact{at,x},after,now,best) == S.later_impact(Bool.and(U32.is_gt(at,after),U32.is_le(at,now)),S.Impact{at,x},best) : Maybe<&2,S.Impact>}

# Guarantees: A new contact batch begins with no fabricated candidate.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law impact_latest_entry:
  for +rows:List<&2,S.Impact>
  for +after:U32
  for +now:U32
  {S.latest_impact(rows,after,now) == S.latest_impact_go(rows,after,now,None{}) : Maybe<&2,S.Impact>}

# Guarantees: The first valid contact must be audible.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law impact_first_candidate:
  for +head:S.Impact
  {S.later_impact(True{},head,None{}) == Some{head} : Maybe<&2,S.Impact>}

# Guarantees: Many simultaneous hits coalesce to one newest contact tick.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law impact_newest_candidate:
  for +at:U32
  for +x:F32
  for +other:U32
  for +otherX:F32
  {S.later_impact(True{},S.Impact{at,x},Some{S.Impact{other,otherX}}) == Bool.pick(Maybe<&2,S.Impact>,U32.is_gt(at,other),Some{S.Impact{at,x}},Some{S.Impact{other,otherX}}) : Maybe<&2,S.Impact>}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_shot:
  {S.name(0) == "shot" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_impact:
  {S.name(1) == "impact" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_hit:
  {S.name(2) == "hit" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_kill:
  {S.name(3) == "kill" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_heal:
  {S.name(4) == "heal" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_pickup:
  {S.name(5) == "pickup" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_hostile:
  {S.name(6) == "hostile" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_cast:
  {S.name(7) == "cast" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_explosion:
  {S.name(8) == "explosion" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_level:
  {S.name(9) == "level" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_chest:
  {S.name(10) == "chest" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_gameover:
  {S.name(11) == "gameover" : String}

# Guarantees: The typed sound code reaches the corresponding browser instrument.
# Why it matters: Playback must follow authoritative observations without duplicate sound.
law name_victory:
  {S.name(12) == "victory" : String}

# Guarantees: Body identity checks seed, kind, variant and semantic lifetime.
# Why it matters: Reusing a pool slot must produce a new attack sound.
law same_identity_exact:
  for +a:S.Stamp
  for +b:S.Stamp
  {S.same(a,b) == same_spec(a,b) : Bool}

# Guarantees: All score, reward, hurt and outcome sounds follow exact field changes.
# Why it matters: Wiring observation playback must not silently lose those effects.
law metadata_sounds_exact:
  for +old:S.Meta
  for +current:S.Meta
  for +events:List<&2,S.Sound>
  {S.meta_events(old,current,events) == meta_spec(old,current,events) : List<&2,S.Sound>}

# Guarantees: A body stamp records its exact body and saturating birth tick.
# Why it matters: A constant generation would silence recycled projectile slots.
law stamp_exact:
  for +seed:U32
  for +kind:U32
  for +variant:U32
  for +age:U32
  for +hp:U32
  for +x:F32
  for +radius:F32
  for +generation:String
  for +tick:U32
  {S.stamp(S.Body{seed,kind,variant,age,hp,x,radius,generation},tick) == S.Stamp{S.Body{seed,kind,variant,age,hp,x,radius,generation},(tick - U32.min(tick,age) : U32)} : S.Stamp}
