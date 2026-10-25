import Base
import encounters.bend as Encounters
import spawn-policy.bend as Admission
import enemy-lifecycle.bend as Life
import game-components.bend as Components
import pools.bend as Pools
import party-difficulty.bend as Party

# Explicit spawn inputs from the selected player's loadout and shared clock.
# Budget bonus and health curse differ intentionally for the character bonus.
type Context is Data: Context{tick: U32,mode: U32,stage: U32,entropy: U32,px: F32,py: F32,budgetBonus: U32,healthCurse: U32,partySize: U32}
def wave_tick(+mode: U32,tick: U32) -> U32:
  (tick * (1 + Bool.to_u32(U32.is_eq(mode,3))) : U32)
def health(+archetype: U32,tick: U32,stage: U32,curse: U32) -> U32:
  (U32.max(Encounters.health(archetype,tick,stage),(10000000 * Bool.to_u32(U32.is_eq(archetype,30)) : U32)) * (100 + curse) / 100 : U32)
def candidate_ready(point: Admission.Point,identity: U32,+archetype: U32,+hp: U32) -> Life.Candidate:
  match point:
    case Admission.Point{x,y}: Life.Candidate{x,y,archetype,identity,Components.Vitals{hp,hp},Encounters.radius(archetype)}
def candidate_at(point: Admission.Point,identity: U32,tick: U32,+archetype: U32,stage: U32,curse: U32) -> Life.Candidate:
  candidate_ready(point,identity,archetype,health(archetype,tick,stage,curse))
def choose(+identity: U32,entropy: U32,+tick: U32,px: F32,py: F32,+archetype: U32,stage: U32,curse: U32) -> Life.Candidate:
  candidate_at(Admission.choose((identity + (entropy - 12345) * 31 : U32),tick,px,py,Encounters.radius(archetype)),identity,tick,archetype,stage,curse)
def admit_selected(admission: Admission.Admission,candidate: Life.Candidate) -> Maybe<&2,Life.Candidate>:
  match admission:
    case Admission.Admit{}: Some{candidate}
    case Admission.Reject{}: None{}
def admit(+candidate: Life.Candidate,px: F32,py: F32) -> Maybe<&2,Life.Candidate>:
  match candidate:
    case Life.Candidate{x,y,_,_,_,radius}: admit_selected(Admission.admission(x,y,px,py,radius),candidate)
def boss_variant(finale: Bool,tick: U32,stage: U32) -> U32:
  match finale:
    case True{}: 30
    case False{}: (20 + stage * 2 + ((tick / 7200) % 2) : U32)
def ordinary_limit(tick: U32,bonus: U32,partySize: U32) -> U32:
  Party.spawn_limit((U32.min(Pools.normal_enemy_cap(),(96 + tick / 50 : U32)) * (100 + bonus) / 100 : U32),partySize)
def ordinary_selected(allowed: Bool,+identity: U32,context: Context) -> Maybe<&2,Life.Candidate>:
  match allowed context:
    case False{} _: None{}
    case True{} Context{+tick,+mode,+stage,entropy,+px,+py,_,healthCurse,_}: admit(choose(identity,entropy,wave_tick(mode,tick),px,py,Encounters.variant(stage,wave_tick(mode,tick),identity),stage,healthCurse),px,py)
def ordinary_scheduled(scheduled: Bool,+identity: U32,+context: Context) -> Maybe<&2,Life.Candidate>:
  match scheduled context:
    case False{} _: None{}
    case True{} Context{tick,mode,_,_,_,_,bonus,_,partySize}: ordinary_selected(U32.is_lt((identity % Pools.player_start() : U32),ordinary_limit(wave_tick(mode,tick),bonus,partySize)),identity,context)
def ordinary(dormant: Bool,+identity: U32,+context: Context) -> Maybe<&2,Life.Candidate>:
  match dormant context:
    case False{} _: None{}
    case True{} Context{tick,_,_,_,_,_,_,_,_}: ordinary_scheduled(U32.is_eq(((tick + identity) % 6 : U32),0),identity,context)
def selected(boss: Bool,dormant: Bool,+identity: U32,+context: Context) -> Maybe<&2,Life.Candidate>:
  match boss context:
    case False{} _: ordinary(dormant,identity,context)
    case True{} Context{+tick,+mode,+stage,entropy,+px,+py,_,_,_}: admit(choose(identity,entropy,wave_tick(mode,tick),px,py,boss_variant(Bool.and(Bool.not(U32.is_eq(mode,2)),U32.is_eq(wave_tick(mode,tick),36000)),wave_tick(mode,tick),stage),stage,0),px,py)
def identity_context(identity: U32,context: Context) -> Context:
  match context:
    case Context{tick,mode,stage,entropy,px,py,bonus,curse,partySize}: Context{tick,mode,stage,entropy,px,py,bonus,curse,Bool.pick(U32,U32.is_eq(identity,0),1,partySize)}
def propose(+identity: U32,dormant: Bool,+context: Context) -> Maybe<&2,Life.Candidate>:
  match context:
    case Context{+tick,+mode,_,_,_,_,_,_,_}:
      selected(Bool.and(U32.is_eq(identity,0),Bool.and(U32.is_lt(0,tick),Bool.or(Bool.and(Bool.or(U32.is_lt(wave_tick(mode,tick),36000),U32.is_eq(mode,2)),U32.is_eq((wave_tick(mode,tick) % 7200 : U32),0)),Bool.or(U32.is_eq(wave_tick(mode,tick),34200),U32.is_eq(wave_tick(mode,tick),36000))))),dormant,identity,identity_context(identity,context))
