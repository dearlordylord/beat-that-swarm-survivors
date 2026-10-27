import Base

type Echo is Data: Echo{castTick:U32,due:U32,x:F32,y:F32,damage:U32,amount:U32,speed:F32,area:F32,duration:F32,level:U32}
type Owner is Data: Owner{stillTicks:U32,notes:U32,trailCarry:F32,orbitPhase:F32,orbits:U32,pulseReady:U32,comboHits:U32,comboDeadline:U32,comboReady:U32,echoes:List<&2,Echo>}
type Emission is Data: Primary{} TrailEmission{} EchoEmission{echo:Echo} ComboEmission{} PulseEmission{}
type Mechanic is Data: Ordinary{} Fan{marks:List<&2,U32>,returnBudget:U32,returning:Bool} Ink{heldTicks:U32,resolved:Bool} Trail{armed:Bool} Streak{credited:Bool}
type Attack is Data: Attack{castTick:U32,primary:Bool,mechanic:Mechanic}

def empty() -> Owner: Owner{0,0,0.0,0.0,0,0,0,0,0,[]}
def ordinary() -> Attack: Attack{0,False{},Ordinary{}}
def number(select:Bool,yes:U32,no:U32) -> U32:
  match select:
    case True{}: yes
    case False{}: no
def scalar(select:Bool,yes:F32,no:F32) -> F32:
  match select:
    case True{}: yes
    case False{}: no

def advance(owner:Owner,+character:U32,+distance:F32,+threshold:F32,familiarActive:Bool) -> Owner:
  match owner:
    case Owner{+stillTicks,+notes,+trailCarry,+orbitPhase,+orbits,+pulseReady,+comboHits,+comboDeadline,+comboReady,+echoes}:
      +charging = Bool.and(U32.is_eq(character,2),F32.is_eq(distance,0.0))
      +ticks = number(charging,(stillTicks + 1 : U32),0)
      +phase = (orbitPhase + scalar(Bool.and(U32.is_eq(character,1),familiarActive),0.035,0.0) : F32)
      +crossed = F32.is_le(6.2831855,phase)
      +completed = (orbits + Bool.to_u32(crossed) : U32)
      +travel = scalar(Bool.and(U32.is_eq(character,3),Bool.and(F32.is_le(0.0,distance),F32.is_le(distance,48.0))),distance,0.0)
      Owner{(ticks % 30 : U32),U32.min(3,(notes + ticks / 30 : U32)),F32.min((threshold + 48.0 : F32),(trailCarry + travel : F32)),(phase - scalar(crossed,6.2831855,0.0) : F32),(completed % 3 : U32),(pulseReady + completed / 3 : U32),comboHits,comboDeadline,comboReady,echoes}

def credit(owner:Owner,+tick:U32) -> Owner:
  match owner:
    case Owner{+stillTicks,+notes,+trailCarry,+orbitPhase,+orbits,+pulseReady,+comboHits,+comboDeadline,+comboReady,+echoes}:
      +count = (number(Bool.and(U32.is_lt(0,comboHits),U32.is_le(tick,comboDeadline)),comboHits,0) + 1 : U32)
      Owner{stillTicks,notes,trailCarry,orbitPhase,orbits,pulseReady,(count % 3 : U32),number(U32.is_eq(count,1),(tick + 120 : U32),comboDeadline),(comboReady + count / 3 : U32),echoes}

def consume_cast(owner:Owner,character:U32,accepted:Bool) -> Owner:
  match owner:
    case Owner{+stillTicks,+notes,+trailCarry,+orbitPhase,+orbits,+pulseReady,+comboHits,+comboDeadline,+comboReady,+echoes}:
      Owner{stillTicks,number(Bool.and(accepted,Bool.and(U32.is_eq(character,2),U32.is_eq(notes,3))),0,notes),trailCarry,orbitPhase,orbits,pulseReady,comboHits,comboDeadline,comboReady,echoes}

def consume_trail(owner:Owner,+threshold:F32,accepted:Bool) -> Owner:
  match owner:
    case Owner{+stillTicks,+notes,+trailCarry,+orbitPhase,+orbits,+pulseReady,+comboHits,+comboDeadline,+comboReady,+echoes}:
      Owner{stillTicks,notes,scalar(accepted,F32.max(0.0,(trailCarry - threshold : F32)),F32.min(trailCarry,threshold)),orbitPhase,orbits,pulseReady,comboHits,comboDeadline,comboReady,echoes}

def consume_bonus(owner:Owner,combo:Bool,pulse:Bool) -> Owner:
  match owner:
    case Owner{+stillTicks,+notes,+trailCarry,+orbitPhase,+orbits,+pulseReady,+comboHits,+comboDeadline,+comboReady,+echoes}:
      Owner{stillTicks,notes,trailCarry,orbitPhase,orbits,(pulseReady - number(Bool.and(pulse,U32.is_lt(0,pulseReady)),1,0) : U32),comboHits,comboDeadline,(comboReady - number(Bool.and(combo,U32.is_lt(0,comboReady)),1,0) : U32),echoes}

def keep_echo(keep:Bool,echo:Echo,tail:List<&2,Echo>) -> List<&2,Echo>:
  match keep:
    case True{}: echo <> tail
    case False{}: tail
def select_echoes(rows:List<&2,Echo>,+tick:U32,+ready:Bool) -> List<&2,Echo>:
  match rows:
    case []: []
    case Echo{castTick,+deadline,x,y,damage,amount,speed,area,duration,level} <> tail:
      keep_echo(U32.is_eq(Bool.to_u32(U32.is_le(deadline,tick)),Bool.to_u32(ready)),Echo{castTick,deadline,x,y,damage,amount,speed,area,duration,level},select_echoes(tail,tick,ready))

def enqueue(owner:Owner,echo:Echo) -> Owner:
  match owner:
    case Owner{+stillTicks,+notes,+trailCarry,+orbitPhase,+orbits,+pulseReady,+comboHits,+comboDeadline,+comboReady,+echoes}:
      Owner{stillTicks,notes,trailCarry,orbitPhase,orbits,pulseReady,comboHits,comboDeadline,comboReady,List.append(&2,Echo,echoes,keep_echo(U32.is_lt(U32.from_nat(List.length(&2,Echo,echoes)),8),echo,[]))}

def drain(owner:Owner,tick:U32) -> Owner:
  match owner:
    case Owner{+stillTicks,+notes,+trailCarry,+orbitPhase,+orbits,+pulseReady,+comboHits,+comboDeadline,+comboReady,+echoes}:
      Owner{stillTicks,notes,trailCarry,orbitPhase,orbits,pulseReady,comboHits,comboDeadline,comboReady,select_echoes(echoes,tick,False{})}

def due(owner:Owner,tick:U32) -> List<&2,Echo>:
  match owner:
    case Owner{_,_,_,_,_,_,_,_,_,echoes}: select_echoes(echoes,tick,True{})

def native_bool(value:Bool) -> String:
  match value:
    case True{}: "true"
    case False{}: "false"
def native_echo(value:Echo) -> String:
  match value:
    case Echo{castTick,due,x,y,damage,amount,speed,area,duration,level}: "{\"$\":\"Echo\"" ++ ",\"castTick\":" ++ U32.show(castTick) ++ ",\"due\":" ++ U32.show(due) ++ ",\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"damage\":" ++ U32.show(damage) ++ ",\"amount\":" ++ U32.show(amount) ++ ",\"speed\":" ++ F32.show(speed) ++ ",\"area\":" ++ F32.show(area) ++ ",\"duration\":" ++ F32.show(duration) ++ ",\"level\":" ++ U32.show(level) ++ "}"

def native_echoes(rows:List<&2,Echo>) -> String:
  match rows:
    case []: "{\"$\":\"Nil\"}"
    case head <> tail: "{\"$\":\"Con\",\"head\":" ++ native_echo(head) ++ ",\"tail\":" ++ native_echoes(tail) ++ "}"


def native_owner(value:Owner) -> String:
  match value:
    case Owner{stillTicks,notes,trailCarry,orbitPhase,orbits,pulseReady,comboHits,comboDeadline,comboReady,echoes}: "{\"$\":\"Owner\"" ++ ",\"stillTicks\":" ++ U32.show(stillTicks) ++ ",\"notes\":" ++ U32.show(notes) ++ ",\"trailCarry\":" ++ F32.show(trailCarry) ++ ",\"orbitPhase\":" ++ F32.show(orbitPhase) ++ ",\"orbits\":" ++ U32.show(orbits) ++ ",\"pulseReady\":" ++ U32.show(pulseReady) ++ ",\"comboHits\":" ++ U32.show(comboHits) ++ ",\"comboDeadline\":" ++ U32.show(comboDeadline) ++ ",\"comboReady\":" ++ U32.show(comboReady) ++ ",\"echoes\":" ++ native_echoes(echoes) ++ "}"

def expire(owner: Owner,+tick: U32) -> Owner:
  match owner:
    case Owner{stillTicks,notes,trailCarry,orbitPhase,orbits,pulseReady,+comboHits,+comboDeadline,comboReady,echoes}: Owner{stillTicks,notes,trailCarry,orbitPhase,orbits,pulseReady,number(U32.is_lt(comboDeadline,tick),0,comboHits),number(U32.is_lt(comboDeadline,tick),0,comboDeadline),comboReady,echoes}

def native_nums(rows: List<&2,U32>) -> String:
  match rows:
    case []: "{\"$\":\"Nil\"}"
    case head <> tail: "{\"$\":\"Con\",\"head\":" ++ U32.show(head) ++ ",\"tail\":" ++ native_nums(tail) ++ "}"
def native_mechanic(value: Mechanic) -> String:
  match value:
    case Ordinary{}: "{\"$\":\"Ordinary\"}"
    case Fan{marks,budget,returning}: "{\"$\":\"Fan\",\"marks\":" ++ native_nums(marks) ++ ",\"returnBudget\":" ++ U32.show(budget) ++ ",\"returning\":" ++ native_bool(returning) ++ "}"
    case Ink{ticks,resolved}: "{\"$\":\"Ink\",\"heldTicks\":" ++ U32.show(ticks) ++ ",\"resolved\":" ++ native_bool(resolved) ++ "}"
    case Trail{armed}: "{\"$\":\"Trail\",\"armed\":" ++ native_bool(armed) ++ "}"
    case Streak{credited}: "{\"$\":\"Streak\",\"credited\":" ++ native_bool(credited) ++ "}"
def native_attack(value: Attack) -> String:
  match value:
    case Attack{cast,primary,mechanic}: "{\"$\":\"Attack\",\"castTick\":" ++ U32.show(cast) ++ ",\"primary\":" ++ native_bool(primary) ++ ",\"mechanic\":" ++ native_mechanic(mechanic) ++ "}"

def echo_words(value: Echo) -> List<&2,U32>:
  match value:
    case Echo{cast,due,x,y,damage,amount,speed,area,duration,level}: [cast,due,F32.bits(x),F32.bits(y),damage,amount,F32.bits(speed),F32.bits(area),F32.bits(duration),level]
def echoes_words(rows: List<&2,Echo>) -> List<&2,U32>:
  match rows:
    case []: []
    case head <> tail: List.append(&2,U32,echo_words(head),echoes_words(tail))
def owner_words(value: Owner) -> List<&2,U32>:
  match value:
    case Owner{ticks,notes,carry,phase,orbits,pulse,hits,deadline,ready,+echoes}: List.append(&2,U32,[ticks,notes,F32.bits(carry),F32.bits(phase),orbits,pulse,hits,deadline,ready,U32.from_nat(List.length(&2,Echo,echoes))],echoes_words(echoes))
def mechanic_words(value: Mechanic) -> List<&2,U32>:
  match value:
    case Ordinary{}: [0]
    case Fan{marks,budget,returning}: 1 <> budget <> Bool.to_u32(returning) <> marks
    case Ink{ticks,resolved}: [2,ticks,Bool.to_u32(resolved)]
    case Trail{armed}: [3,Bool.to_u32(armed)]
    case Streak{credited}: [4,Bool.to_u32(credited)]
def attack_words(value: Attack) -> List<&2,U32>:
  match value:
    case Attack{cast,primary,mechanic}: cast <> Bool.to_u32(primary) <> mechanic_words(mechanic)
