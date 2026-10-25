import audio-identity.bend as AudioIdentity
import run-state.bend as RS
import Base
import game-components.bend as Components
import game.bend as G
import projectile-state.bend as Shot
import projectile-encoder.bend as ShotEncoder
import pickup-encoder.bend as PickupEncoder
import enemy-combat.bend as Enemy
import enemy-spatial.bend as Space
import player-presentation.bend as Players

def player_json(value: Players.Player) -> String:
  match value:
    case Players.Player{id,+player,connected}:
      "{\"id\":" ++ U32.show(id) ++ ",\"px\":" ++ F32.show(RS.player_px(player)) ++ ",\"py\":" ++ F32.show(RS.player_py(player)) ++ ",\"hp\":" ++ U32.show(RS.player_hp(player)) ++ ",\"maxHp\":" ++ U32.show(RS.player_maxHp(player)) ++ ",\"character\":" ++ U32.show(RS.player_character(player)) ++ ",\"connected\":" ++ Bool.pick(String,connected,"true","false") ++ ",\"alive\":" ++ Bool.pick(String,U32.is_lt(0,RS.player_hp(player)),"true","false") ++ "}"
def players_json(rows: List<&2,Players.Player>) -> String:
  match rows:
    case []: ""
    case player <> []: player_json(player)
    case player <> rest: player_json(player) ++ "," ++ players_json(rest)
def body_json(body: Components.Body) -> String:
  match body:
    case Components.Body{x,y,kind,variant,hp,maxHp,age,seed,radius}: "[" ++ F32.show(x) ++ "," ++ F32.show(y) ++ "," ++ U32.show(kind) ++ "," ++ U32.show(variant) ++ "," ++ U32.show(hp) ++ "," ++ U32.show(maxHp) ++ "," ++ U32.show(age) ++ "," ++ U32.show(seed) ++ "," ++ F32.show(radius) ++ "]"
def rows_json(rows: List<&2,Components.Body>) -> String:
  match rows:
    case []: ""
    case body <> []: body_json(body)
    case body <> rest: body_json(body) ++ "," ++ rows_json(rest)
def enemy_json(enemy: Enemy.State,+tick: U32) -> String:
  match enemy:
    case Enemy.State{Space.Spatial{x,y,+age,radius},archetype,+identity,Components.Vitals{health,maximum},_}:
      "{\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"age\":" ++ U32.show(age) ++ ",\"radius\":" ++ F32.show(radius) ++ ",\"archetype\":" ++ U32.show(archetype) ++ ",\"identity\":" ++ U32.show(identity) ++ ",\"health\":" ++ U32.show(health) ++ ",\"maximum\":" ++ U32.show(maximum) ++ ",\"lifetime\":\"" ++ AudioIdentity.enemy(identity,tick,age) ++ "\"}"
def enemies_json(rows: List<&2,Enemy.State>,+tick: U32) -> String:
  match rows:
    case []: ""
    case enemy <> []: enemy_json(enemy,tick)
    case enemy <> rest: enemy_json(enemy,tick) ++ "," ++ enemies_json(rest,tick)
def actor_ref_json(reference: G.ActorRef) -> String:
  match reference:
    case G.EnemyRef{identity}: "{\"enemy\":" ++ U32.show(identity) ++ "}"
    case G.ProjectileRef{identity}: "{\"projectile\":" ++ U32.show(identity) ++ "}"
    case G.PickupRef{identity}: "{\"pickup\":" ++ U32.show(identity) ++ "}"
    case G.BodyRef{identity}: "{\"body\":" ++ U32.show(identity) ++ "}"
def actor_order_json(rows: List<&2,G.ActorRef>) -> String:
  match rows:
    case []: ""
    case reference <> []: actor_ref_json(reference)
    case reference <> rest: actor_ref_json(reference) ++ "," ++ actor_order_json(rest)
def projectiles_json(rows: List<&2,Shot.State>,+tick: U32) -> String:
  match rows:
    case []: ""
    case +projectile <> []: ShotEncoder.visual(tick,(tick - Shot.age(projectile) : U32),projectile)
    case +projectile <> rest: ShotEncoder.visual(tick,(tick - Shot.age(projectile) : U32),projectile) ++ "," ++ projectiles_json(rest,tick)
def nums_json(rows: List<&2,U32>) -> String:
  match rows:
    case []: ""
    case n <> []: U32.show(n)
    case n <> rest: U32.show(n) ++ "," ++ nums_json(rest)
def offer_json(offer: G.Offer) -> String:
  match offer:
    case G.Offer{kind,id,level}: "{\"kind\":" ++ U32.show(kind) ++ ",\"id\":" ++ U32.show(id) ++ ",\"level\":" ++ U32.show(level) ++ "}"
def offers_json(rows: List<&2,G.Offer>) -> String:
  match rows:
    case []: ""
    case o <> []: offer_json(o)
    case o <> rest: offer_json(o) ++ "," ++ offers_json(rest)
def visible_bodies(rows: List<&2,Components.Body>) -> List<&2,Components.Body>:
  match rows:
    case []: []
    case Components.Body{_,_,8,_,_,_,_,_,_} <> rest: visible_bodies(rest)
    case body <> rest: body <> visible_bodies(rest)
def encode_extra(observation: G.Observation,players: List<&2,Players.Player>,extra: String) -> String:
  match observation:
    case G.Observation{G.Run{RS.Session{phase,+tick,xp,need,level,kills,gold,seed,+stage,bosses,+mode,enemyKinds,relicCollected},RS.PlayerState{px,py,hp,maxHp,character,weapons,passives,invuln,arcana,meta,revivals,rerolls,banishes,skips,bannedWeapons,bannedPassives}},bodies,offers,enemies,order,projectiles,pickups}:
      "{\"worldSize\":" ++ F32.show(G.world_size()) ++ ",\"worldMargin\":" ++ F32.show(G.world_margin()) ++ ",\"relicCollected\":" ++ U32.show(relicCollected) ++ ",\"relicX\":" ++ F32.show(G.relic_x(stage)) ++ ",\"relicY\":" ++ F32.show(G.relic_y(stage)) ++ ",\"runLength\":" ++ U32.show(G.run_length(mode)) ++ ",\"enemiesKilled\":[" ++ nums_json(enemyKinds) ++ "],\"mode\":" ++ U32.show(mode) ++ ",\"rerolls\":" ++ U32.show(rerolls) ++ ",\"banishes\":" ++ U32.show(banishes) ++ ",\"skips\":" ++ U32.show(skips) ++ ",\"stage\":" ++ U32.show(stage) ++ ",\"arcana\":" ++ U32.show(arcana) ++ ",\"revivalsUsed\":" ++ U32.show(revivals) ++ ",\"bossesKilled\":" ++ U32.show(bosses) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"px\":" ++ F32.show(px) ++ ",\"py\":" ++ F32.show(py) ++ ",\"hp\":" ++ U32.show(hp) ++ ",\"maxHp\":" ++ U32.show(maxHp) ++ ",\"xp\":" ++ U32.show(xp) ++ ",\"xpNeed\":" ++ U32.show(need) ++ ",\"level\":" ++ U32.show(level) ++ ",\"kills\":" ++ U32.show(kills) ++ ",\"gold\":" ++ U32.show(gold) ++ ",\"character\":" ++ U32.show(character) ++ ",\"weapons\":[" ++ nums_json(weapons) ++ "],\"passives\":[" ++ nums_json(passives) ++ "],\"offers\":[" ++ offers_json(offers) ++ "],\"bodies\":[" ++ rows_json(visible_bodies(bodies)) ++ "],\"enemies\":[" ++ enemies_json(enemies,tick) ++ "],\"actorOrder\":[" ++ actor_order_json(order) ++ "],\"projectiles\":[" ++ projectiles_json(projectiles,tick) ++ "],\"players\":[" ++ players_json(players) ++ "]" ++ extra ++ "}"
def encode(+observation: G.Observation) -> String:
  match observation:
    case G.Observation{run,_,_,_,_,_,_}: encode_extra(observation,Players.solo(G.run_player(run)),"")
type Encoded is Type: Encoded{state: G.State,frame: String}
def observe(state: G.State) -> Encoded:
  match state:
    case G.State{world,+run,+bodies,+offers,+snapshots,pending}: Encoded{G.State{world,run,bodies,offers,snapshots,pending},encode(G.Observation{run,bodies,offers,G.enemy_observations(snapshots),G.render_order(snapshots),G.projectile_observations(snapshots),G.pickup_observations(snapshots)})}
