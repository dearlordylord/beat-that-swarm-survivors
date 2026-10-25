import Base
import ./body-index.bend as BI

# Cosmetic observation only: no world, damage resolver or progression authority.
# A network impact sound represents a coalesced confirmed contact tick, not one
# oscillator per target in a large area attack.
type Body is Data: Body{seed:U32,kind:U32,variant:U32,age:U32,hp:U32,x:F32,radius:F32,generation:String}
type Stamp is Data: Stamp{body:Body,born:U32}
type Meta is Data: Meta{run:String,tick:U32,phase:U32,round:U32,hp:U32,kills:U32,gold:U32,xp:U32,level:U32,px:F32,confirmed:Bool}
type Sound is Data: Sound{kind:U32,pan:F32}
type Impact is Data: Impact{tick:U32,x:F32}
type State is Data: State{ready:Bool,meta:Meta,bodies:BI.Index<Stamp>,impactTick:U32}
type Out is Data: Out{state:State,events:List<&2,Sound>}
type Scanned is Data: Scanned{bodies:BI.Index<Stamp>,events:List<&2,Sound>}
def fresh() -> State: State{False{},Meta{"",0,0,0,0,0,0,0,0,0.0,False{}},BI.Empty{},0}
def pan(+x:F32,+viewer:F32) -> F32: F32.clamp(((x - viewer) / 400.0 : F32),(0.0 - 0.8 : F32),0.8)
def born(+tick:U32,+age:U32) -> U32: (tick - U32.min(tick,age) : U32)
def stamp(+body:Body,+tick:U32) -> Stamp:
  match body:
    case Body{_,_,_,+age,_,_,_,_}: Stamp{body,born(tick,age)}
def same_generation(+a:String,+b:String,+aBorn:U32,+bBorn:U32) -> Bool:
  Bool.pick(Bool,Bool.and(Bool.not(String.eq(a,"")),Bool.not(String.eq(b,""))),String.eq(a,b),U32.is_eq(aBorn,bBorn))
def same(+a:Stamp,+b:Stamp) -> Bool:
  match a b:
    case Stamp{Body{+aSeed,+ak,+av,_,_,_,_,+ag},+ab} Stamp{Body{+bSeed,+bk,+bv,_,_,_,_,+bg},+bb}: Bool.and(U32.is_eq(aSeed,bSeed),Bool.and(U32.is_eq(ak,bk),Bool.and(U32.is_eq(av,bv),same_generation(ag,bg,ab,bb))))
def attack(+kind:U32) -> Bool: Bool.or(U32.is_eq(kind,1),Bool.or(U32.is_eq(kind,6),U32.is_eq(kind,7)))
def attack_kind(+kind:U32) -> U32: Bool.pick(U32,U32.is_eq(kind,7),6,Bool.pick(U32,U32.is_eq(kind,6),7,0))
def add(+allowed:Bool,+kind:U32,+x:F32,+viewer:F32,+events:List<&2,Sound>) -> List<&2,Sound>:
  match allowed:
    case True{}: Sound{kind,pan(x,viewer)} <> events
    case False{}: events
def changed_events(+matching:Bool,+old:Stamp,+current:Stamp,+viewer:F32,+confirmed:Bool,+events:List<&2,Sound>) -> List<&2,Sound>:
  match old current:
    case Stamp{Body{_,_,_,_,+oldHp,_,+oldRadius,_},_} Stamp{Body{_,+kind,_,_,+hp,+x,+radius,_},_}:
      add(Bool.and(matching,Bool.and(U32.is_eq(kind,1),Bool.and(F32.is_gt(oldRadius,0.0),Bool.and(F32.is_gt(radius,oldRadius),F32.is_ge(radius,(oldRadius * 2.0 : F32)))))),8,x,viewer,
      add(Bool.and(matching,Bool.and(Bool.not(confirmed),Bool.and(U32.is_eq(kind,0),U32.is_lt(hp,oldHp)))),1,x,viewer,
      add(Bool.and(Bool.not(matching),attack(kind)),attack_kind(kind),x,viewer,events)))
def row_events(+previous:Maybe<&2,Stamp>,+current:Stamp,+viewer:F32,+confirmed:Bool,+events:List<&2,Sound>) -> List<&2,Sound>:
  match previous current:
    case None{} Stamp{Body{_,+kind,_,_,_,+x,_,_},_}: add(attack(kind),attack_kind(kind),x,viewer,events)
    case Some{+old} _: changed_events(same(old,current),old,current,viewer,confirmed,events)
def scan(+rows:List<&2,Body>,+previous:BI.Index<Stamp>,+tick:U32,+viewer:F32,+confirmed:Bool,+index:BI.Index<Stamp>,+events:List<&2,Sound>) -> Scanned:
  match rows:
    case []: Scanned{index,List.reverse(&2,Sound,events)}
    case Body{+seed,+kind,+variant,+age,+hp,+x,+radius,+generation} <> tail:
      scan(tail,previous,tick,viewer,confirmed,
        BI.insert(~Stamp,index,seed,stamp(Body{seed,kind,variant,age,hp,x,radius,generation},tick)),
        row_events(BI.find(~Stamp,previous,seed),stamp(Body{seed,kind,variant,age,hp,x,radius,generation},tick),viewer,confirmed,events))

def baseline_ready(+meta:Meta,+result:Scanned) -> Out:
  match meta result:
    case Meta{_,+tick,_,_,_,_,_,_,_,_,_} Scanned{+bodies,_}: Out{State{True{},meta,bodies,tick},[]}
def baseline(+meta:Meta,+rows:List<&2,Body>) -> Out:
  match meta:
    case Meta{_,+tick,_,_,_,_,_,_,_,+px,+confirmed}: baseline_ready(meta,scan(rows,BI.Empty{},tick,px,confirmed,BI.Empty{},[]))
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
    case Scanned{+bodies,+events}: Out{State{True{},current,bodies,impactTick},meta_events(old,current,events)}
def observe_same(+newer:Bool,+old:Meta,+current:Meta,+bodies:BI.Index<Stamp>,+impactTick:U32,+rows:List<&2,Body>) -> Out:
  match newer current:
    case True{} Meta{_,+tick,_,_,_,_,_,_,_,+px,+confirmed}: observed(old,current,impactTick,scan(rows,bodies,tick,px,confirmed,BI.Empty{},[]))
    case False{} _: observed(old,current,impactTick,Scanned{bodies,[]})
def meta_tick(+meta:Meta) -> U32:
  match meta:
    case Meta{_,+tick,_,_,_,_,_,_,_,_,_}: tick
def observe_configuring(+configuring:Bool,+old:Meta,+current:Meta,+bodies:BI.Index<Stamp>,+impactTick:U32,+rows:List<&2,Body>) -> Out:
  match configuring:
    case True{}: baseline(current,rows)
    case False{}: observe_same(U32.is_gt(meta_tick(current),meta_tick(old)),old,current,bodies,impactTick,rows)
def observe_time(+stale:Bool,+state:State,+old:Meta,+current:Meta,+bodies:BI.Index<Stamp>,+impactTick:U32,+rows:List<&2,Body>) -> Out:
  match stale:
    case True{}: Out{state,[]}
    case False{}: observe_configuring(Bool.and(U32.is_eq(meta_tick(old),0),U32.is_eq(meta_tick(current),0)),old,current,bodies,impactTick,rows)
def observe_existing(+sameRun:Bool,+state:State,+current:Meta,+rows:List<&2,Body>) -> Out:
  match sameRun state current:
    case False{} _ _: baseline(current,rows)
    case True{} State{_,+old,+bodies,+impactTick} Meta{_,+tick,_,_,_,_,_,_,_,_,_}: observe_time(U32.is_lt(tick,meta_tick(old)),state,old,current,bodies,impactTick,rows)
def observe(+state:State,+current:Meta,+rows:List<&2,Body>) -> Out:
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
    case State{+ready,+meta,+bodies,_} Some{Impact{+tick,+x}}: Out{State{ready,meta,bodies,tick},[Sound{1,pan(x,meta_x(meta))}]}
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
