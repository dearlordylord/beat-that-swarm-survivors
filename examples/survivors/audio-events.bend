import Base
import ./body-index.bend as BI

# Cosmetic observation only: no world, damage resolver or progression authority.
# A network impact sound represents a coalesced confirmed contact tick, not one
# oscillator per target in a large area attack.
type Identity is Data: Identity{slot:U32,lifetime:String}
type SoundSubject is Data:
  Enemy{identity:Identity,archetype:U32,health:U32,x:F32}
  FriendlyProjectile{identity:Identity,weapon:U32,radius:F32,x:F32}
  HostileProjectile{identity:Identity,weapon:U32,x:F32}
type Meta is Data: Meta{run:String,tick:U32,phase:U32,round:U32,hp:U32,kills:U32,gold:U32,xp:U32,level:U32,px:F32,confirmed:Bool}
type Sound is Data: Sound{kind:U32,pan:F32}
type Impact is Data: Impact{tick:U32,x:F32}
type State is Data: State{ready:Bool,meta:Meta,subjects:BI.Index<SoundSubject>,impactTick:U32}
type Out is Data: Out{state:State,events:List<&2,Sound>}
type Scanned is Data: Scanned{subjects:BI.Index<SoundSubject>,events:List<&2,Sound>}
def fresh() -> State: State{False{},Meta{"",0,0,0,0,0,0,0,0,0.0,False{}},BI.Empty{},0}
def pan(+x:F32,+viewer:F32) -> F32: F32.clamp(((x - viewer) / 400.0 : F32),(0.0 - 0.8 : F32),0.8)
def same_identity(a:Identity,b:Identity) -> Bool:
  match a b:
    case Identity{aSlot,aLife} Identity{bSlot,bLife}: Bool.and(U32.is_eq(aSlot,bSlot),String.eq(aLife,bLife))
def identity(subject:SoundSubject) -> Identity:
  match subject:
    case Enemy{value,_,_,_}: value
    case FriendlyProjectile{value,_,_,_}: value
    case HostileProjectile{value,_,_}: value
def identity_slot(value:Identity) -> U32:
  match value:
    case Identity{value,_}: value
def slot(subject:SoundSubject) -> U32: identity_slot(identity(subject))
def subject_x(subject:SoundSubject) -> F32:
  match subject:
    case Enemy{_,_,_,x}: x
    case FriendlyProjectile{_,_,_,x}: x
    case HostileProjectile{_,_,x}: x
def same(a:SoundSubject,b:SoundSubject) -> Bool:
  match a b:
    case Enemy{ai,av,_,_} Enemy{bi,bv,_,_}: Bool.and(same_identity(ai,bi),U32.is_eq(av,bv))
    case FriendlyProjectile{ai,av,_,_} FriendlyProjectile{bi,bv,_,_}: Bool.and(same_identity(ai,bi),U32.is_eq(av,bv))
    case HostileProjectile{ai,av,_} HostileProjectile{bi,bv,_}: Bool.and(same_identity(ai,bi),U32.is_eq(av,bv))
    case _ _: False{}
def attack(subject:SoundSubject) -> Bool:
  match subject:
    case Enemy{_,_,_,_}: False{}
    case _: True{}
def attack_kind(subject:SoundSubject) -> U32:
  match subject:
    case HostileProjectile{_,_,_}: 6
    case _: 0
def add(+allowed:Bool,+kind:U32,+x:F32,+viewer:F32,+events:List<&2,Sound>) -> List<&2,Sound>:
  match allowed:
    case True{}: Sound{kind,pan(x,viewer)} <> events
    case False{}: events
def changed_events(+matching:Bool,+old:SoundSubject,+current:SoundSubject,+viewer:F32,+confirmed:Bool,+events:List<&2,Sound>) -> List<&2,Sound>:
  match old current:
    case Enemy{_,_,oldHealth,_} Enemy{_,_,health,x}:
      add(Bool.and(matching,Bool.and(Bool.not(confirmed),U32.is_lt(health,oldHealth))),1,x,viewer,events)
    case FriendlyProjectile{_,_,oldRadius,_} FriendlyProjectile{_,_,radius,x}:
      add(Bool.and(matching,Bool.and(F32.is_gt(oldRadius,0.0),Bool.and(F32.is_gt(radius,oldRadius),F32.is_ge(radius,(oldRadius * 2.0 : F32))))),8,x,viewer,
      add(Bool.not(matching),0,x,viewer,events))
    case _ _: add(Bool.and(Bool.not(matching),attack(current)),attack_kind(current),subject_x(current),viewer,events)
def row_events(+previous:Maybe<&2,SoundSubject>,+current:SoundSubject,+viewer:F32,+confirmed:Bool,+events:List<&2,Sound>) -> List<&2,Sound>:
  match previous:
    case None{}: add(attack(current),attack_kind(current),subject_x(current),viewer,events)
    case Some{old}: changed_events(same(old,current),old,current,viewer,confirmed,events)
def scan(+rows:List<&2,SoundSubject>,+previous:BI.Index<SoundSubject>,+viewer:F32,+confirmed:Bool,+index:BI.Index<SoundSubject>,+events:List<&2,Sound>) -> Scanned:
  match rows:
    case []: Scanned{index,List.reverse(&2,Sound,events)}
    case head <> tail:
      scan(tail,previous,viewer,confirmed,
        BI.insert(~SoundSubject,index,slot(head),head),
        row_events(BI.find(~SoundSubject,previous,slot(head)),head,viewer,confirmed,events))

def baseline_ready(+meta:Meta,+result:Scanned) -> Out:
  match meta result:
    case Meta{_,+tick,_,_,_,_,_,_,_,_,_} Scanned{+subjects,_}: Out{State{True{},meta,subjects,tick},[]}
def baseline(+meta:Meta,+rows:List<&2,SoundSubject>) -> Out:
  match meta:
    case Meta{_,+tick,_,_,_,_,_,_,_,+px,+confirmed}: baseline_ready(meta,scan(rows,BI.Empty{},px,confirmed,BI.Empty{},[]))
def meta_events(+old:Meta,+current:Meta,+events:List<&2,Sound>) -> List<&2,Sound>:
  match old current:
    case Meta{_,_,+oldPhase,+oldRound,+oldHp,+oldKills,+oldGold,+oldXp,+oldLevel,_,_} Meta{_,_,+phase,+round,+hp,+kills,+gold,+xp,+level,_,+confirmed}:
      add(Bool.and(U32.is_eq(phase,4),U32.is_ne(oldPhase,4)),12,0.0,0.0,
      add(Bool.and(U32.is_eq(phase,3),U32.is_ne(oldPhase,3)),11,0.0,0.0,
      add(Bool.and(U32.is_eq(phase,2),Bool.or(U32.is_ne(oldPhase,2),U32.is_ne(oldRound,round))),10,0.0,0.0,
      add(Bool.and(U32.is_eq(phase,1),Bool.or(U32.is_ne(oldPhase,1),U32.is_ne(oldRound,round))),9,0.0,0.0,
      add(Bool.or(U32.is_gt(gold,oldGold),Bool.or(U32.is_gt(xp,oldXp),U32.is_gt(level,oldLevel))),5,0.0,0.0,
      add(U32.is_gt(hp,oldHp),4,0.0,0.0,
      add(U32.is_gt(kills,oldKills),3,0.0,0.0,
      add(Bool.and(Bool.not(confirmed),U32.is_gt(kills,oldKills)),1,0.0,0.0,
      add(U32.is_lt(hp,oldHp),2,0.0,0.0,events)))))))))
def observed(+old:Meta,+current:Meta,+impactTick:U32,+result:Scanned) -> Out:
  match result:
    case Scanned{+subjects,+events}: Out{State{True{},current,subjects,impactTick},meta_events(old,current,events)}
def observe_same(+newer:Bool,+old:Meta,+current:Meta,+subjects:BI.Index<SoundSubject>,+impactTick:U32,+rows:List<&2,SoundSubject>) -> Out:
  match newer current:
    case True{} Meta{_,+tick,_,_,_,_,_,_,_,+px,+confirmed}: observed(old,current,impactTick,scan(rows,subjects,px,confirmed,BI.Empty{},[]))
    case False{} _: observed(old,current,impactTick,Scanned{subjects,[]})
def meta_tick(+meta:Meta) -> U32:
  match meta:
    case Meta{_,+tick,_,_,_,_,_,_,_,_,_}: tick
def observe_configuring(+configuring:Bool,+old:Meta,+current:Meta,+subjects:BI.Index<SoundSubject>,+impactTick:U32,+rows:List<&2,SoundSubject>) -> Out:
  match configuring:
    case True{}: baseline(current,rows)
    case False{}: observe_same(U32.is_gt(meta_tick(current),meta_tick(old)),old,current,subjects,impactTick,rows)
def observe_time(+stale:Bool,+state:State,+old:Meta,+current:Meta,+subjects:BI.Index<SoundSubject>,+impactTick:U32,+rows:List<&2,SoundSubject>) -> Out:
  match stale:
    case True{}: Out{state,[]}
    case False{}: observe_configuring(Bool.and(U32.is_eq(meta_tick(old),0),U32.is_eq(meta_tick(current),0)),old,current,subjects,impactTick,rows)
def observe_existing(+sameRun:Bool,+state:State,+current:Meta,+rows:List<&2,SoundSubject>) -> Out:
  match sameRun state current:
    case False{} _ _: baseline(current,rows)
    case True{} State{_,+old,+subjects,+impactTick} Meta{_,+tick,_,_,_,_,_,_,_,_,_}: observe_time(U32.is_lt(tick,meta_tick(old)),state,old,current,subjects,impactTick,rows)
def observe(+state:State,+current:Meta,+rows:List<&2,SoundSubject>) -> Out:
  match state current:
    case State{False{},_,_,_} _: baseline(current,rows)
    case State{_,Meta{+run,_,_,_,_,_,_,_,_,_,_},_,_} Meta{+other,_,_,_,_,_,_,_,_,_,_}: observe_existing(String.eq(run,other),state,current,rows)

def impact_allowed(+tick:U32,+after:U32,+now:U32) -> Bool: Bool.and(U32.is_gt(tick,after),U32.is_le(tick,now))
def later_impact(+allowed:Bool,+head:Impact,+tail:Maybe<&2,Impact>) -> Maybe<&2,Impact>:
  match allowed head tail:
    case False{} _ _: tail
    case True{} Impact{+at,_} Some{Impact{+later,+x}}: Bool.pick(Maybe<&2,Impact>,U32.is_gt(at,later),Some{head},Some{Impact{later,x}})
    case True{} _ None{}: Some{head}
def impact_step(+head:Impact,+after:U32,+now:U32,+best:Maybe<&2,Impact>) -> Maybe<&2,Impact>:
  match head:
    case Impact{+tick,_}: later_impact(impact_allowed(tick,after,now),head,best)
def latest_impact_go(+rows:List<&2,Impact>,+after:U32,+now:U32,+best:Maybe<&2,Impact>) -> Maybe<&2,Impact>:
  match rows:
    case []: best
    case head <> tail: latest_impact_go(tail,after,now,impact_step(head,after,now,best))
def latest_impact(+rows:List<&2,Impact>,+after:U32,+now:U32) -> Maybe<&2,Impact>: latest_impact_go(rows,after,now,None{})
def meta_x(+meta:Meta) -> F32:
  match meta:
    case Meta{_,_,_,_,_,_,_,_,_,+x,_}: x
def impact_result(+state:State,+result:Maybe<&2,Impact>) -> Out:
  match state result:
    case _ None{}: Out{state,[]}
    case State{+ready,+meta,+subjects,_} Some{Impact{+tick,+x}}: Out{State{ready,meta,subjects,tick},[Sound{1,pan(x,meta_x(meta))}]}
def impacts(+state:State,+rows:List<&2,Impact>) -> Out:
  match state:
    case State{False{},_,_,_}: Out{state,[]}
    case State{_,+meta,_,+after}: impact_result(state,latest_impact(rows,after,meta_tick(meta)))
def name(+kind:U32) -> String:
  match kind:
    case 0: "shot"
    case 1: "impact"
    case 2: "hit"
    case 3: "kill"
    case 4: "heal"
    case 5: "pickup"
    case 6: "hostile"
    case 7: "cast"
    case 8: "explosion"
    case 9: "level"
    case 10: "chest"
    case 11: "gameover"
    case 12: "victory"
    case _: ""
