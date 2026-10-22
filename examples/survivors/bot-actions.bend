import Base
import game.bend as G
import native-profile.bend as P

# Optional controller facade. All states belong to this compiled module's runtime.
# Observation consumes the affine state once and returns it unchanged. Candidates
# are snapshot-scoped goals, not promises of safety, reachability or rewards.
type Observed is Type:
  Observed{state: G.State,frame: String,actions: String,mechanics: String}
  ObserveFailed{error: String}

def goal(+tick: U32,+px: F32,+py: F32,+kind: String,+x: F32,+y: F32,identity: String) -> String:
  "{\"id\":\"t" ++ U32.show(tick) ++ ":" ++ kind ++ ":" ++ identity ++ "\",\"kind\":\"" ++ kind ++ "\",\"target\":{\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ "},\"distance\":" ++ F32.show(F32.sqrt(G.distance2(px,py,x,y))) ++ ",\"observedTick\":" ++ U32.show(tick) ++ ",\"validOnlyAtObservedTick\":true,\"executable\":false,\"safety\":\"unassessed\"}"

def entity_goal(+tick: U32,+px: F32,+py: F32,body: G.Body,+kind: String) -> String:
  match body:
    case G.Body{+x,+y,+bodyKind,+variant,_,_,+age,+seed,_}:
      goal(tick,px,py,kind,x,y,U32.show(seed) ++ ":" ++ U32.show(bodyKind) ++ ":" ++ U32.show(variant) ++ ":" ++ U32.show(age))

def maybe_entity(enabled: Bool,+tick: U32,+px: F32,+py: F32,body: G.Body,kind: String,tail: String) -> String:
  match enabled:
    case True{}: "," ++ entity_goal(tick,px,py,body,kind) ++ tail
    case False{}: tail

def entity_goals(rows: List<&2,G.Body>,+tick: U32,+px: F32,+py: F32) -> String:
  match rows:
    case []: ""
    case G.Body{+x,+y,5,+variant,+hp,+maxHp,+age,+seed,+radius} <> rest:
      "," ++ entity_goal(tick,px,py,G.Body{x,y,5,variant,hp,maxHp,age,seed,radius},"approach_chest") ++ entity_goals(rest,tick,px,py)
    case G.Body{+x,+y,9,+variant,+hp,+maxHp,+age,+seed,+radius} <> rest:
      "," ++ entity_goal(tick,px,py,G.Body{x,y,9,variant,hp,maxHp,age,seed,radius},"approach_relic") ++ entity_goals(rest,tick,px,py)
    case G.Body{+x,+y,10,0,+hp,+maxHp,+age,+seed,+radius} <> rest:
      maybe_entity(U32.is_lt(0,hp),tick,px,py,G.Body{x,y,10,0,hp,maxHp,age,seed,radius},"approach_wisp",entity_goals(rest,tick,px,py))
    case G.Body{+x,+y,11,0,+hp,+maxHp,+age,+seed,+radius} <> rest:
      maybe_entity(U32.is_lt(0,hp),tick,px,py,G.Body{x,y,11,0,hp,maxHp,age,seed,radius},"approach_ward",entity_goals(rest,tick,px,py))
    case _ <> rest: entity_goals(rest,tick,px,py)

def catalog_live(active: Bool,+tick: U32,+px: F32,+py: F32,bodies: List<&2,G.Body>) -> String:
  match active:
    case False{}: "[]"
    case True{}:
      "[" ++ goal(tick,px,py,"move_north",px,F32.max(20.0,(py - 160.0 : F32)),"north") ++ "," ++ goal(tick,px,py,"move_east",F32.min(3580.0,(px + 160.0 : F32)),py,"east") ++ "," ++ goal(tick,px,py,"move_south",px,F32.min(3580.0,(py + 160.0 : F32)),"south") ++ "," ++ goal(tick,px,py,"move_west",F32.max(20.0,(px - 160.0 : F32)),py,"west") ++ entity_goals(bodies,tick,px,py) ++ "]"

def catalog(run: G.Run,bodies: List<&2,G.Body>) -> String:
  match run:
    case G.Run{phase,tick,px,py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}:
      catalog_live(U32.is_le(phase,2),tick,px,py,bodies)

# Mechanical context comes from the exact functions used by live gameplay.
# Damage is a per-hit base, not DPS; previews do not simulate future combat.
def weapon_stat(+id: U32,+rank: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> String:
  "{\"id\":" ++ U32.show(id) ++ ",\"rank\":" ++ U32.show(rank) ++ ",\"baseHitDamage\":" ++ U32.show(G.weapon_damage(id,rank,passives,meta,arcana,character)) ++ ",\"cooldownTicks\":" ++ U32.show(G.cooldown_for(id,passives,meta,arcana,character)) ++ ",\"areaMultiplier\":" ++ F32.show(G.area_bonus(passives,arcana,rank)) ++ "}"
# Tail has a leading comma only when another owned weapon follows.
def weapon_stat_tail(nonempty: Bool,stats: String) -> String:
  match nonempty:
    case False{}: ""
    case True{}: "," ++ stats

def weapon_stats(rows: List<&2,U32>,+id: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> String:
  match rows:
    case []: ""
    case 0 <> rest: weapon_stats(rest,(id + 1 : U32),passives,meta,arcana,character)
    case +rank <> +rest:
      weapon_stat(id,rank,passives,meta,arcana,character) ++ weapon_stat_tail(U32.is_lt(0,G.owned(rest)),weapon_stats(rest,(id + 1 : U32),passives,meta,arcana,character))

def engine_stats(run: G.Run) -> String:
  match run:
    case G.Run{_,_,_,_,hp,maxHp,_,_,_,_,gold,+character,+weapons,+passives,_,_,_,+arcana,+meta,_,_,_,_,_,_,_,_,_,_}:
      "{\"hp\":" ++ U32.show(hp) ++ ",\"maxHp\":" ++ U32.show(maxHp) ++ ",\"gold\":" ++ U32.show(gold) ++ ",\"weapons\":[" ++ G.nums_json(weapons) ++ "],\"passives\":[" ++ G.nums_json(passives) ++ "],\"speedMultiplier\":" ++ F32.show(G.speed_bonus(passives,meta,arcana,character)) ++ ",\"xpAwardFor100BaseXp\":" ++ U32.show(G.earned_xp(100,passives,meta,arcana)) ++ ",\"durationMultiplier\":" ++ F32.show(G.duration_bonus(passives,arcana)) ++ ",\"projectileSpeedMultiplier\":" ++ F32.show(G.projectile_speed(passives,arcana)) ++ ",\"weaponStats\":[" ++ weapon_stats(weapons,0,passives,meta,arcana,character) ++ "]}"

def preview_stats(offer: G.Offer,run: G.Run) -> String: engine_stats(G.upgrade(offer,run))
def preview_json(+index: U32,+offer: G.Offer,run: G.Run) -> String:
  "{\"offerIndex\":" ++ U32.show(index) ++ ",\"offer\":" ++ G.offer_json(offer) ++ ",\"after\":" ++ preview_stats(offer,run) ++ "}"
def preview_rows(offers: List<&2,G.Offer>,+index: U32,+run: G.Run) -> String:
  match offers:
    case []: ""
    case offer <> []: preview_json(index,offer,run)
    case offer <> rest: preview_json(index,offer,run) ++ "," ++ preview_rows(rest,(index + 1 : U32),run)
def mechanics(+run: G.Run,offers: List<&2,G.Offer>) -> String:
  "{\"source\":\"Bend game functions\",\"notes\":\"Immediate pure upgrade preview; baseHitDamage is not DPS; cooldown is ticks, not a combat rollout.\",\"current\":" ++ engine_stats(run) ++ ",\"offers\":[" ++ preview_rows(offers,0,run) ++ "]}"

def observed_state(state: G.State,frame: String) -> Observed:
  match state:
    case G.State{world,+run,+bodies,+offers,snapshots,pending}:
      Observed{G.State{world,run,bodies,offers,snapshots,pending},frame,catalog(run,bodies),mechanics(run,offers)}

def observed_packet(packet: G.Packet) -> Observed:
  match packet:
    case G.Packet{state,frame}: observed_state(state,frame)
    case G.Failed{error}: ObserveFailed{error}

def observe(state: G.State) -> Observed: observed_packet(G.packet(state))
def start(character: U32,meta: U32) -> G.Packet: G.start(character,meta)
def configure(state: G.State,stage: U32,arcana: U32) -> G.Packet: G.configure(state,stage,arcana)
def set_mode(state: G.State,mode: U32) -> G.Packet: G.set_mode(state,mode)
def configure_unlocks(state: G.State,mask: U32) -> G.Packet: G.configure_unlocks(state,mask)
def choose(state: G.State,index: U32) -> G.Packet: G.choose(state,index)
def advance(state: G.State,dx: F32,dy: F32) -> G.Packet: G.advance(state,dx,dy)
def advance_live(state: G.State,dx: F32,dy: F32) -> G.Packet: G.advance_live(state,dx,dy)
def reroll(state: G.State) -> G.Packet: G.reroll(state)
def skip(state: G.State) -> G.Packet: G.skip(state)
def banish(state: G.State,index: U32) -> G.Packet: G.banish(state,index)

def start_unlocks(packet: G.Packet,mask: U32) -> G.Packet:
  match packet:
    case G.Packet{state,_}: G.configure_unlocks(state,mask)
    case G.Failed{error}: G.Failed{error}
def start_mode(packet: G.Packet,mode: U32) -> G.Packet:
  match packet:
    case G.Packet{state,_}: G.set_mode(state,mode)
    case G.Failed{error}: G.Failed{error}
def start_configured(packet: G.Packet,stage: U32,arcana: U32) -> G.Packet:
  match packet:
    case G.Packet{state,_}: G.configure(state,stage,arcana)
    case G.Failed{error}: G.Failed{error}
# Same fresh profile, stage and mode as the native UI. No profile injection.
def fresh_start() -> G.Packet:
  start_unlocks(start_mode(start_configured(G.start(0,P.meta(P.fresh())),0,0),0),P.weapon_mask(P.fresh()))
# Explicit qualification preset: advanced profile, Agatha, Living Tree Arcana.
def advanced_start() -> G.Packet:
  start_mode(start_configured(G.start(2,364304237),0,9),0)
