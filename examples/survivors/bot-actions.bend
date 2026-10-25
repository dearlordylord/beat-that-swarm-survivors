import run-state.bend as RS
import Base
import game.bend as G
import game-encoder.bend as Encoder
import native-economy.bend as P
import projectile.bend as Shots

# Optional controller facade. All states belong to this compiled module's runtime.
# Observation consumes the affine state once and returns it unchanged. Candidates
# are snapshot-scoped goals, not promises of safety, reachability or rewards.
type Observed is Type:
  Observed{state: G.State,frame: String,actions: String,mechanics: String}
  ObserveFailed{error: String}

def goal_data(+tick: U32,+px: F32,+py: F32,+kind: String,+x: F32,+y: F32,identity: String,resource: String) -> String:
  "{\"id\":\"t" ++ U32.show(tick) ++ ":" ++ kind ++ ":" ++ identity ++ "\",\"kind\":\"" ++ kind ++ "\",\"target\":{\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ "},\"distance\":" ++ F32.show(F32.sqrt(G.distance2(px,py,x,y))) ++ ",\"observedTick\":" ++ U32.show(tick) ++ ",\"validOnlyAtObservedTick\":true,\"executable\":false,\"safety\":\"unassessed\"" ++ resource ++ "}"

def goal(+tick: U32,+px: F32,+py: F32,+kind: String,+x: F32,+y: F32,identity: String) -> String:
  goal_data(tick,px,py,kind,x,y,identity,"")

def resource_metadata(kind: U32,amount: U32,generation: U32) -> String:
  match kind:
    case 2: ",\"resource\":{\"kind\":\"experience\",\"baseXp\":" ++ U32.show(amount) ++ ",\"generation\":" ++ U32.show(generation) ++ ",\"autoClaimTicks\":null}"
    case _: ""

def entity_goal(+tick: U32,+px: F32,+py: F32,body: G.Body,+kind: String) -> String:
  match body:
    case G.Body{+x,+y,+bodyKind,+variant,+hp,+generation,+age,+seed,+radius}:
      goal_data(tick,px,py,kind,x,y,U32.show(seed) ++ ":" ++ U32.show(bodyKind) ++ ":" ++ U32.show(variant) ++ ":" ++ U32.show(age),resource_metadata(bodyKind,G.xp_amount(G.Body{x,y,bodyKind,variant,hp,generation,age,seed,radius}),generation))

def maybe_entity(enabled: Bool,+tick: U32,+px: F32,+py: F32,body: G.Body,kind: String,tail: String) -> String:
  match enabled:
    case True{}: "," ++ entity_goal(tick,px,py,body,kind) ++ tail
    case False{}: tail

def entity_goals(rows: List<&2,G.Body>,+tick: U32,+px: F32,+py: F32) -> String:
  match rows:
    case []: ""
    case G.Body{+x,+y,2,+variant,+hp,+maxHp,+age,+seed,+radius} <> rest:
      maybe_entity(U32.is_lt(0,hp),tick,px,py,G.Body{x,y,2,variant,hp,maxHp,age,seed,radius},"approach_experience",entity_goals(rest,tick,px,py))
    case G.Body{+x,+y,5,+variant,+hp,+maxHp,+age,+seed,+radius} <> rest:
      "," ++ entity_goal(tick,px,py,G.Body{x,y,5,variant,hp,maxHp,age,seed,radius},"approach_chest") ++ entity_goals(rest,tick,px,py)
    case G.Body{+x,+y,9,+variant,+hp,+maxHp,+age,+seed,+radius} <> rest:
      "," ++ entity_goal(tick,px,py,G.Body{x,y,9,variant,hp,maxHp,age,seed,radius},"approach_relic") ++ entity_goals(rest,tick,px,py)
    case _ <> rest: entity_goals(rest,tick,px,py)

def catalog_live(active: Bool,+tick: U32,+px: F32,+py: F32,bodies: List<&2,G.Body>) -> String:
  match active:
    case False{}: "[]"
    case True{}:
      "[" ++ goal(tick,px,py,"move_north",px,F32.max(G.world_margin(),(py - 160.0 : F32)),"north") ++ "," ++ goal(tick,px,py,"move_east",F32.min((G.world_size() - G.world_margin() : F32),(px + 160.0 : F32)),py,"east") ++ "," ++ goal(tick,px,py,"move_south",px,F32.min((G.world_size() - G.world_margin() : F32),(py + 160.0 : F32)),"south") ++ "," ++ goal(tick,px,py,"move_west",F32.max(G.world_margin(),(px - 160.0 : F32)),py,"west") ++ entity_goals(bodies,tick,px,py) ++ "]"

def catalog(run: G.Run,bodies: List<&2,G.Body>) -> String:
  match run:
    case G.Run{RS.Session{phase,tick,_,_,_,_,_,_,_,_,_,_,_},RS.PlayerState{px,py,_,_,_,_,_,_,_,_,_,_,_,_,_,_}}:
      catalog_live(U32.is_le(phase,2),tick,px,py,bodies)

# Mechanical context comes from the exact functions used by live gameplay.
# Damage is a per-hit base, not DPS; previews do not simulate future combat.
def shot_radius(shot: Shots.Shot) -> F32:
  match shot:
    case Shots.Shot{_,_,_,_,radius,_,_}: radius

def self_field_radius(enabled: Bool,id: U32,rank: U32,speed: F32,area: F32,duration: F32) -> F32:
  match enabled:
    case False{}: 0.0
    case True{}: shot_radius(Shots.spawn(id,rank,0,0.0,0.0,0.0,0.0,1.0,0.0,speed,area,duration))

def weapon_stat(+id: U32,+rank: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> String:
  "{\"id\":" ++ U32.show(id) ++ ",\"rank\":" ++ U32.show(rank) ++ ",\"baseHitDamage\":" ++ U32.show(G.weapon_damage(id,rank,passives,meta,arcana,character)) ++ ",\"cooldownTicks\":" ++ U32.show(G.cooldown_for(id,passives,meta,arcana,character)) ++ ",\"selfFieldRadius\":" ++ F32.show(self_field_radius(Bool.and(U32.is_lt(rank,9),Bool.or(U32.is_eq(id,4),U32.is_eq(id,22))),id,rank,G.projectile_speed(passives,arcana),G.area_bonus(passives,arcana,rank),G.duration_bonus(passives,arcana))) ++ ",\"areaMultiplier\":" ++ F32.show(G.area_bonus(passives,arcana,rank)) ++ "}"
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
    case G.Run{RS.Session{_,_,_,_,_,_,gold,_,_,_,_,_,_},RS.PlayerState{_,_,hp,maxHp,+character,+weapons,+passives,_,+arcana,+meta,_,_,_,_,_,_}}:
      "{\"hp\":" ++ U32.show(hp) ++ ",\"maxHp\":" ++ U32.show(maxHp) ++ ",\"gold\":" ++ U32.show(gold) ++ ",\"weapons\":[" ++ Encoder.nums_json(weapons) ++ "],\"passives\":[" ++ Encoder.nums_json(passives) ++ "],\"speedMultiplier\":" ++ F32.show(G.speed_bonus(passives,meta,arcana,character)) ++ ",\"pickupRadius\":" ++ F32.show(G.pickup_radius(passives,meta,arcana,character)) ++ ",\"xpAwardFor100BaseXp\":" ++ U32.show(G.earned_xp(100,passives,meta,arcana)) ++ ",\"durationMultiplier\":" ++ F32.show(G.duration_bonus(passives,arcana)) ++ ",\"projectileSpeedMultiplier\":" ++ F32.show(G.projectile_speed(passives,arcana)) ++ ",\"weaponStats\":[" ++ weapon_stats(weapons,0,passives,meta,arcana,character) ++ "]}"

def preview_stats(offer: G.Offer,run: G.Run) -> String: engine_stats(G.upgrade(offer,run))
def preview_json(+index: U32,+offer: G.Offer,run: G.Run) -> String:
  "{\"offerIndex\":" ++ U32.show(index) ++ ",\"offer\":" ++ Encoder.offer_json(offer) ++ ",\"after\":" ++ preview_stats(offer,run) ++ "}"
def preview_rows(offers: List<&2,G.Offer>,+index: U32,+run: G.Run) -> String:
  match offers:
    case []: ""
    case offer <> []: preview_json(index,offer,run)
    case offer <> rest: preview_json(index,offer,run) ++ "," ++ preview_rows(rest,(index + 1 : U32),run)
def mechanics(+run: G.Run,offers: List<&2,G.Offer>) -> String:
  "{\"source\":\"Bend game functions\",\"notes\":\"Immediate pure upgrade preview; baseHitDamage is not DPS; cooldown is ticks, not a combat rollout.\",\"current\":" ++ engine_stats(run) ++ ",\"offers\":[" ++ preview_rows(offers,0,run) ++ "]}"

def observed_state(state: G.State) -> Observed:
  match state:
    case G.State{world,+run,+bodies,+offers,snapshots,pending}:
      Observed{G.State{world,run,bodies,offers,snapshots,pending},Encoder.encode(G.Observation{run,bodies,offers}),catalog(run,bodies),mechanics(run,offers)}

def observed_packet(packet: G.Packet) -> Observed:
  match packet:
    case G.Packet{state}: observed_state(state)
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
    case G.Packet{state}: G.configure_unlocks(state,mask)
    case G.Failed{error}: G.Failed{error}
def start_mode(packet: G.Packet,mode: U32) -> G.Packet:
  match packet:
    case G.Packet{state}: G.set_mode(state,mode)
    case G.Failed{error}: G.Failed{error}
def start_configured(packet: G.Packet,stage: U32,arcana: U32) -> G.Packet:
  match packet:
    case G.Packet{state}: G.configure(state,stage,arcana)
    case G.Failed{error}: G.Failed{error}
# Same fresh profile, stage and mode as the native UI. No profile injection.
def fresh_start_seed(seed: U32) -> G.Packet:
  start_unlocks(start_mode(start_configured(G.start_seed(0,P.meta(P.fresh()),seed),0,0),0),P.weapon_mask(P.fresh()))

def fresh_start() -> G.Packet: fresh_start_seed(12345)
# Explicit qualification preset: advanced profile, Agatha, Living Tree Arcana.
def advanced_start_seed(seed: U32) -> G.Packet:
  start_mode(start_configured(G.start_seed(2,364304237,seed),0,9),0)

def advanced_start() -> G.Packet: advanced_start_seed(12345)
