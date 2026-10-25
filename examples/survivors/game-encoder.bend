import run-state.bend as RS
import Base
import game.bend as G

def body_json(body: G.Body) -> String:
  match body:
    case G.Body{x,y,kind,variant,hp,maxHp,age,seed,radius}: "[" ++ F32.show(x) ++ "," ++ F32.show(y) ++ "," ++ U32.show(kind) ++ "," ++ U32.show(variant) ++ "," ++ U32.show(hp) ++ "," ++ U32.show(maxHp) ++ "," ++ U32.show(age) ++ "," ++ U32.show(seed) ++ "," ++ F32.show(radius) ++ "]"
def rows_json(rows: List<&2,G.Body>) -> String:
  match rows:
    case []: ""
    case body <> []: body_json(body)
    case body <> rest: body_json(body) ++ "," ++ rows_json(rest)
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
def visible_bodies(rows: List<&2,G.Body>) -> List<&2,G.Body>:
  match rows:
    case []: []
    case G.Body{_,_,8,_,_,_,_,_,_} <> rest: visible_bodies(rest)
    case body <> rest: body <> visible_bodies(rest)
def encode_extra(observation: G.Observation,extra: String) -> String:
  match observation:
    case G.Observation{G.Run{RS.Session{phase,tick,xp,need,level,kills,gold,seed,+stage,bosses,+mode,enemyKinds,relicCollected},RS.PlayerState{px,py,hp,maxHp,character,weapons,passives,invuln,arcana,meta,revivals,rerolls,banishes,skips,bannedWeapons,bannedPassives}},bodies,offers}:
      "{\"worldSize\":" ++ F32.show(G.world_size()) ++ ",\"worldMargin\":" ++ F32.show(G.world_margin()) ++ ",\"relicCollected\":" ++ U32.show(relicCollected) ++ ",\"relicX\":" ++ F32.show(G.relic_x(stage)) ++ ",\"relicY\":" ++ F32.show(G.relic_y(stage)) ++ ",\"runLength\":" ++ U32.show(G.run_length(mode)) ++ ",\"enemiesKilled\":[" ++ nums_json(enemyKinds) ++ "],\"mode\":" ++ U32.show(mode) ++ ",\"rerolls\":" ++ U32.show(rerolls) ++ ",\"banishes\":" ++ U32.show(banishes) ++ ",\"skips\":" ++ U32.show(skips) ++ ",\"stage\":" ++ U32.show(stage) ++ ",\"arcana\":" ++ U32.show(arcana) ++ ",\"revivalsUsed\":" ++ U32.show(revivals) ++ ",\"bossesKilled\":" ++ U32.show(bosses) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"px\":" ++ F32.show(px) ++ ",\"py\":" ++ F32.show(py) ++ ",\"hp\":" ++ U32.show(hp) ++ ",\"maxHp\":" ++ U32.show(maxHp) ++ ",\"xp\":" ++ U32.show(xp) ++ ",\"xpNeed\":" ++ U32.show(need) ++ ",\"level\":" ++ U32.show(level) ++ ",\"kills\":" ++ U32.show(kills) ++ ",\"gold\":" ++ U32.show(gold) ++ ",\"character\":" ++ U32.show(character) ++ ",\"weapons\":[" ++ nums_json(weapons) ++ "],\"passives\":[" ++ nums_json(passives) ++ "],\"offers\":[" ++ offers_json(offers) ++ "],\"bodies\":[" ++ rows_json(visible_bodies(bodies)) ++ "]" ++ extra ++ "}"
def encode(observation: G.Observation) -> String: encode_extra(observation,"")
type Encoded is Type: Encoded{state: G.State,frame: String}
def observe(state: G.State) -> Encoded:
  match state:
    case G.State{world,+run,+bodies,+offers,snapshots,pending}: Encoded{G.State{world,run,bodies,offers,snapshots,pending},encode(G.Observation{run,bodies,offers})}
