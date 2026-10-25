import Base
import coop-reward-policy.bend as RP
import game.bend as G
import coop-prediction.bend as Prediction
import coop-combat-prediction.bend as CombatPrediction
import arena.bend as A
import entity-role.bend as Role
import spawn-policy.bend as S
import spawn-lifecycle.bend as SL
import pools.bend as PL
import projectile-pool.bend as SP
import body-index.bend as BI
import bendvy-ecs-core@0.1.0.1/world.bend as W
import bendvy-ecs-core@0.1.0.1/component.bend as C
import bendvy-ecs-core@0.1.0.1/transaction.bend as T
import bendvy-ecs-core@0.1.0.1/compose.bend as Q
import bendvy-ecs-core@0.1.0.1/capabilities.bend as Cap

type PlayerRef is Data: PlayerRef{id: U32,handle: W.Handle<G.Schema>}
type PlayerOffers is Data: PlayerOffers{id: U32,offers: List<&2,G.Offer>}
type Reward is Data: Reward{kind: U32,collector: U32}
type CoreState is Type:
  CoreState{world: G.World(),shared: G.Run,refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,required: List<&2,U32>,offers: List<&2,PlayerOffers>,pending: List<&2,Reward>}
type CorePacket is Type:
  CorePacket{state: CoreState,frame: String}
  CoreRejected{state: CoreState,message: String}
  CoreFailed{message: String}
def run_phase(run: G.Run) -> U32:
  match run:
    case G.Run{phase,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: phase
def run_tick(run: G.Run) -> U32:
  match run:
    case G.Run{_,tick,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: tick
def run_px(run: G.Run) -> F32:
  match run:
    case G.Run{_,_,px,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: px
def run_py(run: G.Run) -> F32:
  match run:
    case G.Run{_,_,_,py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: py
def run_hp(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,hp,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: hp
def run_maxHp(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,maxHp,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: maxHp
def run_xp(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,xp,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: xp
def run_xpNeed(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,xpNeed,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: xpNeed
def run_level(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,level,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: level
def run_kills(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,kills,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: kills
def run_gold(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,gold,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: gold
def run_character(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,character,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: character
def run_weapons(run: G.Run) -> List<&2,U32>:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,weapons,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: weapons
def run_passives(run: G.Run) -> List<&2,U32>:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,passives,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: passives
def run_invuln(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,invuln,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: invuln
def run_seed(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,seed,_,_,_,_,_,_,_,_,_,_,_,_,_}: seed
def run_stage(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,stage,_,_,_,_,_,_,_,_,_,_,_,_}: stage
def run_arcana(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,arcana,_,_,_,_,_,_,_,_,_,_,_}: arcana
def run_meta(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,meta,_,_,_,_,_,_,_,_,_,_}: meta
def run_revivals(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,revivals,_,_,_,_,_,_,_,_,_}: revivals
def run_bosses(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,bosses,_,_,_,_,_,_,_,_}: bosses
def run_mode(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,mode,_,_,_,_,_,_,_}: mode
def run_rerolls(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,rerolls,_,_,_,_,_,_}: rerolls
def run_banishes(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,banishes,_,_,_,_,_}: banishes
def run_skips(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,skips,_,_,_,_}: skips
def run_bannedWeapons(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,bannedWeapons,_,_,_}: bannedWeapons
def run_bannedPassives(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,bannedPassives,_,_}: bannedPassives
def run_enemyKinds(run: G.Run) -> List<&2,U32>:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,enemyKinds,_}: enemyKinds
def run_relicCollected(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,relicCollected}: relicCollected
def with_phase(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{value,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_tick(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{+phase,_,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,value,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_xp(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,_,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,tick,px,py,hp,maxHp,value,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_xpNeed(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,_,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,tick,px,py,hp,maxHp,xp,value,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_level(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,_,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,value,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_gold(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,_,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,value,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_seed(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,_,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,value,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_hp(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,_,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,tick,px,py,value,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_invuln(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,_,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,value,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_revivals(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,_,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,value,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_px(run: G.Run,value: F32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,_,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,tick,value,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_py(run: G.Run,value: F32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,_,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{phase,tick,px,value,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def with_relicCollected(run: G.Run,value: U32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,_}: G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,value}
def projection(+shared: G.Run,personal: G.Run) -> G.Run:
  match personal:
    case G.Run{_,_,+px,+py,+hp,+maxHp,_,_,_,_,_,+character,+weapons,+passives,+invuln,_,_,+arcana,+meta,+revivals,_,_,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,_,_}: G.Run{run_phase(shared),run_tick(shared),px,py,hp,maxHp,run_xp(shared),run_xpNeed(shared),run_level(shared),run_kills(shared),run_gold(shared),character,weapons,passives,invuln,run_seed(shared),run_stage(shared),arcana,meta,revivals,run_bosses(shared),run_mode(shared),rerolls,banishes,skips,bannedWeapons,bannedPassives,run_enemyKinds(shared),run_relicCollected(shared)}
def player_replaced(result: C.Replacement<G.World(),G.PlayerRecord>) -> G.World():
  match result:
    case C.Replaced{world,_}: world
    case C.ReplaceRejected{world,_,_}: world
def save_player(world: G.World(),ref: PlayerRef,player: G.PlayerRecord) -> G.World():
  match ref:
    case PlayerRef{_,handle}: player_replaced(C.structural_replace(~G.Schema,~G.Store,~Unit,~Unit,~G.PlayerRest,~G.PlayerRecord,~G.PlayerRecord,~G.PlayerToken,~G.take_players,~G.put_players,~G.project_player,G.player_family(),world,handle,Some{player}))
def save_players(refs: List<&2,PlayerRef>,players: List<&2,G.PlayerRecord>,world: G.World()) -> G.World():
  match refs players:
    case ref <> refs player <> players: save_players(refs,players,save_player(world,ref,player))
    case _ _: world
def load_player_result(next: List<&2,G.PlayerRecord> -> G.World() -> G.World() & List<&2,G.PlayerRecord>,loaded: List<&2,G.PlayerRecord>,result: G.World() & C.Access<G.PlayerRecord>) -> G.World() & List<&2,G.PlayerRecord>:
  match result:
    case (world,C.Found{player}): next(player <> loaded,world)
    case (world,_): next(loaded,world)
def load_players(refs: List<&2,PlayerRef>,loaded: List<&2,G.PlayerRecord>,world: G.World()) -> G.World() & List<&2,G.PlayerRecord>:
  match refs:
    case []: (world,List.reverse(&2,G.PlayerRecord,loaded))
    case PlayerRef{_,handle} <> rest: load_player_result(load_players(rest),loaded,C.get(~G.Schema,~G.Store,~Unit,~Unit,~G.PlayerRest,~G.PlayerRecord,~G.PlayerRecord,~G.PlayerToken,~G.take_players,~G.put_players,~G.project_player,G.player_family(),world,handle))

def record_id(player: G.PlayerRecord) -> U32:
  match player:
    case G.PlayerRecord{id,_,_}: id
def record_run(player: G.PlayerRecord) -> G.Run:
  match player:
    case G.PlayerRecord{_,run,_}: run
def record_connected(player: G.PlayerRecord) -> Bool:
  match player:
    case G.PlayerRecord{_,_,connected}: connected
def find_player(players: List<&2,G.PlayerRecord>,+id: U32,fallback: G.Run) -> G.Run:
  match players:
    case []: fallback
    case G.PlayerRecord{+pid,+run,_} <> rest: Bool.pick(G.Run,U32.is_eq(pid,id),run,find_player(rest,id,fallback))
def offers_for(rows: List<&2,PlayerOffers>,+id: U32) -> List<&2,G.Offer>:
  match rows:
    case []: []
    case PlayerOffers{+pid,offers} <> rest: Bool.pick(List<&2,G.Offer>,U32.is_eq(pid,id),offers,offers_for(rest,id))
def player_json(+shared: G.Run,player: G.PlayerRecord) -> String:
  match player:
    case G.PlayerRecord{+id,+run,connected}: "{\"id\":" ++ U32.show(id) ++ ",\"px\":" ++ F32.show(run_px(run)) ++ ",\"py\":" ++ F32.show(run_py(run)) ++ ",\"hp\":" ++ U32.show(run_hp(run)) ++ ",\"maxHp\":" ++ U32.show(run_maxHp(run)) ++ ",\"character\":" ++ U32.show(run_character(run)) ++ ",\"connected\":" ++ Bool.pick(String,connected,"true","false") ++ ",\"alive\":" ++ Bool.pick(String,U32.is_lt(0,run_hp(run)),"true","false") ++ "}"
def players_json(+shared: G.Run,players: List<&2,G.PlayerRecord>) -> String:
  match players:
    case []: ""
    case player <> []: player_json(shared,player)
    case player <> rest: player_json(shared,player) ++ "," ++ players_json(shared,rest)
# Compose fields before Game closes its JSON object. Never walk or trim the
# serialized world's characters: browser stacks are bounded independently of
# the number of entities the ECS can simulate.
def player_connected(players: List<&2,G.PlayerRecord>,+id: U32) -> Bool:
  match players:
    case []: False{}
    case G.PlayerRecord{+pid,_,connected} <> rest: Bool.pick(Bool,U32.is_eq(pid,id),connected,player_connected(rest,id))
def coop_extra(+shared: G.Run,+players: List<&2,G.PlayerRecord>,+id: U32,+round: U32,+required: List<&2,U32>) -> String:
  ",\"predictionAllowed\":" ++ Bool.pick(String,Prediction.allowed(run_phase(shared),run_hp(find_player(players,id,shared)),player_connected(players,id)),"true","false") ++ ",\"stepDistance\":" ++ F32.show(G.run_step_distance(find_player(players,id,shared))) ++ ",\"coop\":true,\"ownPlayerId\":" ++ U32.show(id) ++ ",\"choicePending\":" ++ Bool.pick(String,G.contains(required,id),"true","false") ++ ",\"roundId\":" ++ U32.show(round) ++ ",\"requiredPlayers\":[" ++ G.nums_json(required) ++ "],\"players\":[" ++ players_json(shared,players) ++ "]"
def observe_packet(shared: G.Run,refs: List<&2,PlayerRef>,round: U32,required: List<&2,U32>,offers: List<&2,PlayerOffers>,pending: List<&2,Reward>,result: G.Packet) -> CorePacket:
  match result:
    case G.Packet{G.State{world,_,bodies,_,snapshots,_},frame}: CorePacket{CoreState{world,shared,refs,bodies,snapshots,round,required,offers,pending},frame}
    case G.Failed{message}: CoreFailed{message}
def spectator_target(players: List<&2,G.PlayerRecord>,fallback: G.Run) -> G.Run:
  match players:
    case []: fallback
    case G.PlayerRecord{_,+run,+connected} <> rest: Bool.pick(G.Run,Bool.and(connected,U32.is_lt(0,run_hp(run))),run,spectator_target(rest,fallback))
def observer_run(+shared: G.Run,+players: List<&2,G.PlayerRecord>,+id: U32) -> G.Run:
  +own = projection(shared,find_player(players,id,shared))
  +target = spectator_target(players,own)
  Bool.pick(G.Run,U32.is_eq(run_hp(own),0),with_py(with_px(own,run_px(target)),run_py(target)),own)
# The detached cohort receives every player's shared clock/configuration together
# with personal movement/stats, exactly as the authoritative team step does.
def forecast_players(+shared:G.Run,players:List<&2,G.PlayerRecord>) -> List<&2,G.PlayerRecord>:
  match players:
    case []: []
    case G.PlayerRecord{id,run,connected} <> tail: G.PlayerRecord{id,projection(shared,run),connected} <> forecast_players(shared,tail)
def combat_forecast_extra(id:U32,shared:G.Run,players:List<&2,G.PlayerRecord>,snapshots:List<&2,G.Snapshot>) -> String:
  match id:
    case 1: ",\"combatForecast\":" ++ CombatPrediction.observe(1,forecast_players(shared,players),snapshots)
    case _: ""
def observe_loaded(+shared: G.Run,+refs: List<&2,PlayerRef>,+bodies: List<&2,G.Body>,+snapshots: List<&2,G.Snapshot>,+round: U32,+required: List<&2,U32>,+offers: List<&2,PlayerOffers>,+pending: List<&2,Reward>,+id: U32,result: G.World() & List<&2,G.PlayerRecord>) -> CorePacket:
  match result:
    case (world,+players): observe_packet(shared,refs,round,required,offers,pending,G.packet_extra(G.State{world,observer_run(shared,players,id),bodies,offers_for(offers,id),snapshots,[]},coop_extra(shared,players,id,round,required) ++ combat_forecast_extra(id,shared,players,snapshots)))
def core_observe(state: CoreState,+id: U32) -> CorePacket:
  match state:
    case CoreState{world,+shared,+refs,+bodies,+snapshots,+round,+required,+offers,+pending}: observe_loaded(shared,refs,bodies,snapshots,round,required,offers,pending,id,load_players(refs,[],world))
def quiet(state: CoreState) -> CorePacket: CorePacket{state,""}
type PlayerCreated is Type:
  PlayerCreated{world: G.World(),ref: PlayerRef}
  PlayerCreateFailed{world: G.World()}
def player_activated(+id: U32,run: G.Run,+handle: W.Handle<G.Schema>,result: G.World() & W.Status) -> PlayerCreated:
  match result:
    case (world,W.Accepted{}): PlayerCreated{save_player(world,PlayerRef{id,handle},G.PlayerRecord{id,run,True{}}),PlayerRef{id,handle}}
    case (world,_): PlayerCreateFailed{world}
def player_reserved(+id: U32,run: G.Run,result: G.World() & W.Reservation<G.Schema>) -> PlayerCreated:
  match result:
    case (world,W.Reserved{+handle}): player_activated(id,run,handle,W.activate(~G.Schema,~G.Store,~Unit,~Unit,world,handle))
    case (world,_): PlayerCreateFailed{world}
def create_player(world: G.World(),id: U32,run: G.Run) -> PlayerCreated:
  player_reserved(id,run,W.reserve_id(~G.Schema,~G.Store,~Unit,~Unit,world))
def core_started(shared: G.Run,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,result: PlayerCreated) -> CorePacket:
  match result:
    case PlayerCreated{world,ref}: quiet(CoreState{world,shared,[ref],bodies,snapshots,0,[],[],[]})
    case PlayerCreateFailed{_}: CoreFailed{"Player entity allocation failed"}
def core_started_packet(packet: G.Packet) -> CorePacket:
  match packet:
    case G.Packet{G.State{world,+run,bodies,_,snapshots,_},_}: core_started(run,bodies,snapshots,create_player(world,0,run))
    case G.Failed{message}: CoreFailed{message}
def core_start(character: U32,meta: U32,seed: U32) -> CorePacket: core_started_packet(G.start_seed_quiet(character,meta,seed))

def unlock_run(+mask: U32,run: G.Run) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+kinds,+relic}: G.Run{phase,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,U32.or(bannedWeapons,U32.and(16777215,U32.xor(mask,16777215))),bannedPassives,kinds,relic}
type PlayerEdit is Data:
  EditConfigure{stage: U32,mode: U32,arcana: U32}
  EditUnlock{mask: U32}
def apply_edit(edit: PlayerEdit,run: G.Run) -> G.Run:
  match edit:
    case EditConfigure{stage,mode,arcana}: G.mode_configured(G.configured(run,stage,arcana),mode)
    case EditUnlock{mask}: unlock_run(mask,run)
def edit_player(+id: U32,+edit: PlayerEdit,players: List<&2,G.PlayerRecord>) -> List<&2,G.PlayerRecord>:
  match players:
    case []: []
    case G.PlayerRecord{+pid,+run,connected} <> rest: G.PlayerRecord{pid,Bool.pick(G.Run,U32.is_eq(pid,id),apply_edit(edit,run),run),connected} <> edit_player(id,edit,rest)
def edit_loaded(+id: U32,edit: PlayerEdit,+shared: G.Run,+refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,required: List<&2,U32>,offers: List<&2,PlayerOffers>,pending: List<&2,Reward>,result: G.World() & List<&2,G.PlayerRecord>) -> CorePacket:
  match result:
    case (world,players): quiet(CoreState{save_players(refs,edit_player(id,edit,players),world),shared,refs,bodies,snapshots,round,required,offers,pending})
def edit_core(state: CoreState,+id: U32,edit: PlayerEdit) -> CorePacket:
  match state:
    case CoreState{world,+shared,+refs,bodies,snapshots,round,required,offers,pending}: edit_loaded(id,edit,shared,refs,bodies,snapshots,round,required,offers,pending,load_players(refs,[],world))
def configure_allowed(allowed: Bool,state: CoreState,+stage: U32,+mode: U32,+arcana: U32) -> CorePacket:
  match allowed state:
    case True{} CoreState{world,+shared,+refs,bodies,snapshots,round,required,offers,pending}: edit_loaded(0,EditConfigure{stage,mode,arcana},G.mode_configured(G.configured(shared,stage,arcana),mode),refs,bodies,snapshots,round,required,offers,pending,load_players(refs,[],world))
    case False{} state: CoreRejected{state,"Match setup is closed"}
def core_configure(state: CoreState,+stage: U32,+mode: U32,+arcana: U32) -> CorePacket:
  match state:
    case CoreState{world,+shared,refs,bodies,snapshots,round,required,offers,pending}: configure_allowed(U32.is_eq(run_tick(shared),0),CoreState{world,shared,refs,bodies,snapshots,round,required,offers,pending},U32.min(4,stage),U32.min(3,mode),U32.min(11,arcana))
def unlock_allowed(allowed: Bool,state: CoreState,id: U32,mask: U32) -> CorePacket:
  match allowed:
    case True{}: edit_core(state,id,EditUnlock{mask})
    case False{}: CoreRejected{state,"Match setup is closed"}
def core_configure_unlocks(state: CoreState,id: U32,mask: U32) -> CorePacket:
  match state:
    case CoreState{world,+shared,refs,bodies,snapshots,round,required,offers,pending}: unlock_allowed(U32.is_eq(run_tick(shared),0),CoreState{world,shared,refs,bodies,snapshots,round,required,offers,pending},id,mask)
def guest_run(+shared: G.Run,+character: U32,+meta: U32,+arcana: U32) -> G.Run:
  G.mode_configured(G.configured(G.Run{0,0,(A.center() + 32.0 : F32),A.center(),G.initial_health(character,meta),G.initial_health(character,meta),0,20,1,0,0,character,G.bump([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],G.starter(character)),[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],0,run_seed(shared),run_stage(shared),arcana,meta,0,0,run_mode(shared),3,3,3,0,0,[],0},run_stage(shared),arcana),run_mode(shared))
def joined(shared: G.Run,refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,required: List<&2,U32>,offers: List<&2,PlayerOffers>,pending: List<&2,Reward>,result: PlayerCreated) -> CorePacket:
  match result:
    case PlayerCreated{world,ref}: quiet(CoreState{world,shared,List.append(&2,PlayerRef,refs,[ref]),bodies,snapshots,round,required,offers,pending})
    case PlayerCreateFailed{world}: CoreRejected{CoreState{world,shared,refs,bodies,snapshots,round,required,offers,pending},"Player allocation failed"}
def join_allowed(allowed: Bool,state: CoreState,character: U32,meta: U32,arcana: U32) -> CorePacket:
  match allowed state:
    case True{} CoreState{world,+shared,refs,bodies,snapshots,round,required,offers,pending}: joined(shared,refs,bodies,snapshots,round,required,offers,pending,create_player(world,1,guest_run(shared,character,meta,arcana)))
    case False{} state: CoreRejected{state,"Join is only allowed before the two-player match starts"}
def core_join(state: CoreState,character: U32,meta: U32,arcana: U32) -> CorePacket:
  match state:
    case CoreState{world,+shared,+refs,bodies,snapshots,round,required,offers,pending}: join_allowed(Bool.and(U32.is_eq(run_tick(shared),0),Nat.is_eq(List.length(&2,PlayerRef,refs),1n)),CoreState{world,shared,refs,bodies,snapshots,round,required,offers,pending},U32.min(7,character),meta,U32.min(11,arcana))

# Views are immutable per-tick projections, never another gameplay authority.
def player_view(+shared: G.Run,+dx0: F32,+dy0: F32,+dx1: F32,+dy1: F32,player: G.PlayerRecord) -> G.PlayerView:
  match player:
    case G.PlayerRecord{+id,+run,+connected}: G.PlayerView{id,with_tick(Bool.pick(G.Run,connected,projection(shared,run),with_hp(projection(shared,run),0)),(run_tick(shared) + 1 : U32)),Bool.pick(F32,U32.is_eq(id,0),dx0,dx1),Bool.pick(F32,U32.is_eq(id,0),dy0,dy1)}
def add_view(eligible: Bool,view: G.PlayerView,tail: List<&2,G.PlayerView>) -> List<&2,G.PlayerView>:
  match eligible:
    case True{}: view <> tail
    case False{}: tail
def player_views(+shared: G.Run,+dx0: F32,+dy0: F32,+dx1: F32,+dy1: F32,players: List<&2,G.PlayerRecord>) -> List<&2,G.PlayerView>:
  match players:
    case []: []
    case +player <> rest: player_view(shared,dx0,dy0,dx1,dy1,player) <> player_views(shared,dx0,dy0,dx1,dy1,rest)
# Contact damage is evaluated for each living player, independently of chase
# target. Pickup payloads are assigned once, by nearest eligible G.collector.
def contact_hit(+run: G.Run,body: G.Body) -> U32:
  match body:
    case G.Body{+x,+y,0,+variant,_,_,_,_,+radius}: (Bool.to_u32(G.close(x,y,run_px(run),run_py(run),(radius + 10.0 : F32))) * (1 + 1000 * Bool.to_u32(U32.is_eq(variant,30))) : U32)
    case G.Body{+x,+y,7,+variant,_,_,_,_,+radius}: (Bool.to_u32(G.close(x,y,run_px(run),run_py(run),(radius + 10.0 : F32))) * (1 + 1000 * Bool.to_u32(U32.is_eq(variant,30))) : U32)
    case _: 0
def kill_owner(motion: G.Motion) -> U32:
  match motion:
    case G.Motion{_,_,_,_,_,_,_,owner,_}: owner
def pickup_owner(+team: G.Team,+body: G.Body,events: U32) -> U32:
  match body events:
    case _ 0: 2
    case G.Body{x,y,_,_,_,_,_,_,_} _: G.view_id(G.collector(team,x,y))
def owned_row_credit(body: G.Body,hit: U32,xp: U32,gold: U32,heal: U32,chest: U32,killed: U32,relic: U32,motion: G.Motion,+own: U32) -> G.EntityRow:
  G.EntityRow{G.Row{body,hit,(xp * own : U32),(gold * own : U32),(heal * own : U32),(chest * own : U32),killed,(relic * own : U32)},motion}
def owned_row_values(+id: U32,+run: G.Run,row: G.EntityRow,collectorId: U32) -> G.EntityRow:
  match row:
    case G.EntityRow{G.Row{+body,_,+xp,+gold,+heal,+chest,+killed,+relic},+motion}:
      owned_row_credit(body,contact_hit(run,body),xp,gold,heal,chest,(killed * Bool.to_u32(U32.is_eq(kill_owner(motion),id)) : U32),relic,motion,Bool.to_u32(U32.is_eq(collectorId,id)))
def owned_row(+team: G.Team,id: U32,run: G.Run,+row: G.EntityRow) -> G.EntityRow:
  match row:
    case G.EntityRow{G.Row{body,_,xp,gold,heal,chest,_,relic},_}: owned_row_values(id,run,row,pickup_owner(team,body,U32.or(U32.or(xp,gold),U32.or(U32.or(heal,chest),relic))))
def owned_rows_run(+team: G.Team,+id: U32,+run: G.Run,rows: List<&2,G.EntityRow>) -> List<&2,G.EntityRow>:
  match rows:
    case []: []
    case row <> rest: owned_row(team,id,run,row) <> owned_rows_run(team,id,run,rest)
def owned_rows(+team: G.Team,+id: U32,rows: List<&2,G.EntityRow>) -> List<&2,G.EntityRow>:
  owned_rows_run(team,id,G.view_run(G.team_for_id(team,id)),rows)
def totals_xp(totals: G.Totals) -> U32:
  match totals:
    case G.Totals{_,xp,_,_,_,_,_,_,_}: xp
def totals_gold(totals: G.Totals) -> U32:
  match totals:
    case G.Totals{_,_,gold,_,_,_,_,_,_}: gold
def totals_chests(totals: G.Totals) -> U32:
  match totals:
    case G.Totals{_,_,_,_,chests,_,_,_,_}: chests
def credit_xp(+run: G.Run,earned: U32) -> U32: G.earned_xp(earned,run_passives(run),run_meta(run),run_arcana(run))
def credit_gold(+run: G.Run,earned: U32) -> U32: (earned * (100 + G.at(run_passives(run),15) * 15 + G.at(run_passives(run),14) * 10 + 50 * Bool.to_u32(U32.is_eq(run_mode(run),1)) + G.meta_rank(run_meta(run),8) * 10 + 25 * Bool.to_u32(U32.is_eq(run_arcana(run),6))) / 100 : U32)
def chest_rewards(fuel: Nat,+id: U32,tail: List<&2,Reward>) -> List<&2,Reward>:
  match fuel:
    case 0n: tail
    case 1n+rest: Reward{2,id} <> chest_rewards(rest,id,tail)
type PlayersFinalized is Type:
  FinalizeFailed{message: String}
  PlayersFinalized{world: G.World(),players: List<&2,G.PlayerRecord>,xp: U32,gold: U32,chests: List<&2,Reward>}
def finalized_player(next: G.World() -> List<&2,G.PlayerRecord> -> U32 -> U32 -> List<&2,Reward> -> PlayersFinalized,+id: U32,+old: G.Run,connected: Bool,players: List<&2,G.PlayerRecord>,xp: U32,gold: U32,chests: List<&2,Reward>,packet: G.Packet) -> PlayersFinalized:
  match packet:
    case G.Packet{G.State{world,run,_,_,_,_},_}: next(world,G.PlayerRecord{id,with_revivals(run,run_revivals(old)),connected} <> players,xp,gold,chests)
    case G.Failed{message}: FinalizeFailed{message}


def finalize_living(next: G.World() -> List<&2,G.PlayerRecord> -> U32 -> U32 -> List<&2,Reward> -> PlayersFinalized,+player: G.PlayerRecord,+view: G.PlayerView,+rows: List<&2,G.EntityRow>,+totals: G.Totals,world: G.World(),done: List<&2,G.PlayerRecord>,xp: U32,gold: U32,chests: List<&2,Reward>) -> PlayersFinalized:
  finalized_player(next,record_id(player),record_run(player),record_connected(player),done,(xp + credit_xp(G.view_run(view),totals_xp(totals)) : U32),(gold + credit_gold(G.view_run(view),totals_gold(totals)) : U32),chest_rewards(U32.to_nat(totals_chests(totals)),record_id(player),chests),G.finish_stats_with(~G.quiet_packet,world,with_revivals(with_xpNeed(with_xp(G.moved_run(view),0),4294967295),1000),totals,G.boss_kills(rows),G.killed_kinds(rows,run_enemyKinds(record_run(player)))))
def finalize_owned(next: G.World() -> List<&2,G.PlayerRecord> -> U32 -> U32 -> List<&2,Reward> -> PlayersFinalized,player: G.PlayerRecord,view: G.PlayerView,+owned: List<&2,G.EntityRow>,world: G.World(),done: List<&2,G.PlayerRecord>,xp: U32,gold: U32,chests: List<&2,Reward>) -> PlayersFinalized:
  finalize_living(next,player,view,owned,G.accumulate(owned,0,0,0,0,0,0,[],[],0),world,done,xp,gold,chests)
def finalize_eligible(eligible: Bool,next: G.World() -> List<&2,G.PlayerRecord> -> U32 -> U32 -> List<&2,Reward> -> PlayersFinalized,+player: G.PlayerRecord,+team: G.Team,+rows: List<&2,G.EntityRow>,world: G.World(),done: List<&2,G.PlayerRecord>,xp: U32,gold: U32,chests: List<&2,Reward>) -> PlayersFinalized:
  match eligible:
    case False{}: next(world,player <> done,xp,gold,chests)
    case True{}: finalize_owned(next,player,G.team_for_id(team,record_id(player)),owned_rows(team,record_id(player),rows),world,done,xp,gold,chests)
def finalize_players(players: List<&2,G.PlayerRecord>,+team: G.Team,+rows: List<&2,G.EntityRow>,world: G.World(),done: List<&2,G.PlayerRecord>,xp: U32,gold: U32,chests: List<&2,Reward>) -> PlayersFinalized:
  match players:
    case []: PlayersFinalized{world,List.reverse(&2,G.PlayerRecord,done),xp,gold,List.reverse(&2,Reward,chests)}
    case +player <> rest: finalize_eligible(Bool.and(record_connected(player),U32.is_lt(0,run_hp(record_run(player)))),finalize_players(rest,team,rows),player,team,rows,world,done,xp,gold,chests)
def living_ids(players: List<&2,G.PlayerRecord>) -> List<&2,U32>:
  match players:
    case []: []
    case G.PlayerRecord{+id,+run,+connected} <> rest: G.free_slot(Bool.and(connected,U32.is_lt(0,run_hp(run))),id,living_ids(rest))
def insert_level(chests: List<&2,Reward>) -> List<&2,Reward>:
  match chests:
    case []: [Reward{1,0}]
    case first <> rest: first <> Reward{1,0} <> rest
def level_rewards(levelup: Bool,chests: List<&2,Reward>) -> List<&2,Reward>:
  match levelup:
    case False{}: chests
    case True{}: insert_level(chests)
def eligible_reward(kind: U32,+collector: U32,players: List<&2,G.PlayerRecord>) -> List<&2,U32>:
  match kind:
    case 1: living_ids(players)
    case _: Bool.pick(List<&2,U32>,G.contains(living_ids(players),collector),[collector],[])
def make_offers(ids: List<&2,U32>,+players: List<&2,G.PlayerRecord>,+shared: G.Run,+kind: U32,+round: U32) -> List<&2,PlayerOffers>:
  match ids:
    case []: []
    case +id <> rest: PlayerOffers{id,G.filter_offers(G.phase_offers(U32.is_eq(kind,2),(run_seed(shared) + run_level(shared) * 13 + id * 31 + round * 7 : U32),run_weapons(find_player(players,id,shared)),run_passives(find_player(players,id,shared))),run_bannedWeapons(find_player(players,id,shared)),U32.or(8192,run_bannedPassives(find_player(players,id,shared))))} <> make_offers(rest,players,shared,kind,round)
def open_reward_eligible(next: G.World() -> @+shared:G.Run -> @+refs:List<&2,PlayerRef> -> List<&2,G.Body> -> List<&2,G.Snapshot> -> @+round:U32 -> @+players:List<&2,G.PlayerRecord> -> CorePacket,+required: List<&2,U32>,pending: List<&2,Reward>,world: G.World(),+shared: G.Run,refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,+round: U32,+players: List<&2,G.PlayerRecord>,+kind: U32) -> CorePacket:
  match required:
    case []: next(world,shared,refs,bodies,snapshots,round,players)
    case _: quiet(CoreState{world,with_phase(shared,kind),refs,bodies,snapshots,(round + 1 : U32),required,make_offers(required,players,shared,kind,(round + 1 : U32)),pending})

def open_rewards_go(rewards: List<&2,Reward>,world: G.World(),+shared: G.Run,+refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,+round: U32,+players: List<&2,G.PlayerRecord>) -> CorePacket:
  match rewards:
    case []: quiet(CoreState{world,with_phase(shared,0),refs,bodies,snapshots,round,[],[],[]})
    case Reward{+kind,collector} <> +rest: open_reward_eligible(open_rewards_go(rest),eligible_reward(kind,collector,players),rest,world,shared,refs,bodies,snapshots,round,players,kind)

def finish_shared(run: G.Run,+earned: U32,coins: U32,killed: U32,bossesKilled: U32,kinds: List<&2,U32>,relic: U32,+dead: Bool) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+xpNeed,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{Bool.pick(U32,dead,Bool.pick(U32,Bool.and(Bool.not(U32.is_eq(mode,2)),U32.is_le(G.run_length(mode),(tick + 1 : U32))),4,3),0),(tick + 1 : U32),px,py,hp,maxHp,G.remainder_xp((xp + earned : U32),xpNeed),Bool.pick(U32,U32.is_le(xpNeed,(xp + earned : U32)),G.next_xp_need(level),xpNeed),(level + Bool.to_u32(U32.is_le(xpNeed,(xp + earned : U32))) : U32),(kills + killed : U32),(gold + coins + 300 * Bool.to_u32(Bool.and(U32.is_eq(mode,3),U32.is_eq((tick + 1 : U32),18000))) + (50 + level * 5 + kills / 20) * Bool.to_u32(dead) : U32),character,weapons,passives,invuln,(seed + 1 : U32),stage,arcana,meta,revivals,(bosses + bossesKilled : U32),mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,kinds,U32.max(relicCollected,relic)}
def finish_match(dead: Bool,world: G.World(),+shared: G.Run,+refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,+players: List<&2,G.PlayerRecord>,rewards: List<&2,Reward>) -> CorePacket:
  match dead:
    case True{}: quiet(CoreState{save_players(refs,players,world),shared,refs,bodies,snapshots,round,[],[],[]})
    case False{}: open_rewards_go(rewards,save_players(refs,players,world),shared,refs,bodies,snapshots,round,players)
def finalized_totals(+shared: G.Run,+refs: List<&2,PlayerRef>,+rows: List<&2,G.EntityRow>,round: U32,world: G.World(),+players: List<&2,G.PlayerRecord>,+earned: U32,+gold: U32,chests: List<&2,Reward>,totals: G.Totals) -> CorePacket:
  match totals:
    case G.Totals{_,_,_,_,_,killed,bodies,snapshots,relic}: finish_match(Nat.is_eq(List.length(&2,U32,living_ids(players)),0n),world,finish_shared(shared,earned,gold,killed,G.boss_kills(rows),G.killed_kinds(rows,run_enemyKinds(shared)),relic,Nat.is_eq(List.length(&2,U32,living_ids(players)),0n)),refs,bodies,snapshots,round,players,level_rewards(U32.is_le(run_xpNeed(shared),(run_xp(shared) + earned : U32)),chests))
def finalized_all(shared: G.Run,refs: List<&2,PlayerRef>,+rows: List<&2,G.EntityRow>,round: U32,result: PlayersFinalized) -> CorePacket:
  match result:
    case PlayersFinalized{world,players,xp,gold,chests}: finalized_totals(shared,refs,rows,round,world,players,xp,gold,chests,G.accumulate(rows,0,0,0,0,0,0,[],[],0))
    case FinalizeFailed{message}: CoreFailed{message}
def core_executed(+shared: G.Run,+refs: List<&2,PlayerRef>,+team: G.Team,round: U32,players: List<&2,G.PlayerRecord>,result: Q.Executed<G.World(),Q.Error<G.Error>,G.EntityRow>) -> CorePacket:
  match result:
    case Q.Executed{world,T.Success{},+rows}: finalized_all(shared,refs,rows,round,finalize_players(players,team,rows,world,[],0,0,[]))
    case Q.Executed{_,T.Failure{_},_}: CoreFailed{"Shared ECS query failed"}
def core_team_ready(shared: G.Run,refs: List<&2,PlayerRef>,round: U32,world: G.World(),players: List<&2,G.PlayerRecord>,+team: G.Team) -> CorePacket: core_executed(shared,refs,team,round,players,G.team_execute(world,team))
def core_team(+shared: G.Run,+refs: List<&2,PlayerRef>,+bodies: List<&2,G.Body>,+snapshots: List<&2,G.Snapshot>,round: U32,world: G.World(),+players: List<&2,G.PlayerRecord>,+views: List<&2,G.PlayerView>) -> CorePacket:
  core_team_ready(shared,refs,round,world,players,G.Team{views,G.combat_args(G.view_run(G.first_view(views,with_tick(shared,(run_tick(shared) + 1 : U32)))),bodies,0.0,0.0,snapshots),G.team_plan(views,snapshots),G.effect_origin_index(snapshots)})
def step_loaded(+shared: G.Run,refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,dx0: F32,dy0: F32,dx1: F32,dy1: F32,result: G.World() & List<&2,G.PlayerRecord>) -> CorePacket:
  match result:
    case (world,+players): core_team(shared,refs,bodies,snapshots,round,world,players,player_views(shared,dx0,dy0,dx1,dy1,players))
def core_clock(state: CoreState) -> CorePacket:
  match state:
    case CoreState{world,+shared,refs,bodies,snapshots,round,required,offers,pending}: CorePacket{CoreState{world,shared,refs,bodies,snapshots,round,required,offers,pending},"{\"tick\":" ++ U32.show(run_tick(shared)) ++ ",\"phase\":" ++ U32.show(run_phase(shared)) ++ ",\"advanced\":false}"}
def stepped_clock(packet: CorePacket) -> CorePacket:
  match packet:
    case CorePacket{CoreState{world,+shared,refs,bodies,snapshots,round,required,offers,pending},_}: CorePacket{CoreState{world,shared,refs,bodies,snapshots,round,required,offers,pending},"{\"tick\":" ++ U32.show(run_tick(shared)) ++ ",\"phase\":" ++ U32.show(run_phase(shared)) ++ ",\"advanced\":true}"}
    case packet: packet
def step_allowed(allowed: Bool,state: CoreState,dx0: F32,dy0: F32,dx1: F32,dy1: F32) -> CorePacket:
  match allowed state:
    case False{} state: core_clock(state)
    case True{} CoreState{world,+shared,+refs,bodies,snapshots,round,_,_,_}: stepped_clock(step_loaded(shared,refs,bodies,snapshots,round,dx0,dy0,dx1,dy1,load_players(refs,[],world)))
def core_step(state: CoreState,dx0: F32,dy0: F32,dx1: F32,dy1: F32) -> CorePacket:
  match state:
    case CoreState{world,+shared,refs,bodies,snapshots,round,required,offers,pending}: step_allowed(U32.is_eq(run_phase(shared),0),CoreState{world,shared,refs,bodies,snapshots,round,required,offers,pending},dx0,dy0,dx1,dy1)

def remove_offers(offers: List<&2,PlayerOffers>,+id: U32) -> List<&2,PlayerOffers>:
  match offers:
    case []: []
    case PlayerOffers{+pid,choices} <> +rest: Bool.pick(List<&2,PlayerOffers>,U32.is_ne(pid,id),PlayerOffers{pid,choices} <> remove_offers(rest,id),remove_offers(rest,id))
def replace_run(players: List<&2,G.PlayerRecord>,+id: U32,+replacement: G.Run) -> List<&2,G.PlayerRecord>:
  match players:
    case []: []
    case G.PlayerRecord{+pid,run,connected} <> rest: G.PlayerRecord{pid,Bool.pick(G.Run,U32.is_eq(id,pid),replacement,run),connected} <> replace_run(rest,id,replacement)
def resume_control(remaining: List<&2,U32>,world: G.World(),+shared: G.Run,refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,+players: List<&2,G.PlayerRecord>,offers: List<&2,PlayerOffers>,pending: List<&2,Reward>) -> CorePacket:
  match remaining:
    case []: open_rewards_go(pending,world,shared,refs,bodies,snapshots,round,players)
    case remaining: quiet(CoreState{world,shared,refs,bodies,snapshots,round,remaining,offers,pending})
def choice_upgraded(+id: U32,+shared: G.Run,+refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,required: List<&2,U32>,offers: List<&2,PlayerOffers>,pending: List<&2,Reward>,world: G.World(),+players: List<&2,G.PlayerRecord>,+upgraded: G.Run) -> CorePacket:
  resume_control(required,save_players(refs,replace_run(players,id,upgraded),world),with_gold(shared,run_gold(upgraded)),refs,bodies,snapshots,round,replace_run(players,id,upgraded),remove_offers(offers,id),pending)
def choice_loaded(+id: U32,choice: U32,+shared: G.Run,refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,required: List<&2,U32>,+offers: List<&2,PlayerOffers>,pending: List<&2,Reward>,result: G.World() & List<&2,G.PlayerRecord>) -> CorePacket:
  match result:
    case (world,+players): choice_upgraded(id,shared,refs,bodies,snapshots,round,required,offers,pending,world,players,G.upgrade(G.offer_at(offers_for(offers,id),choice),projection(shared,find_player(players,id,shared))))
def choice_decided(decision: RP.Decision,state: CoreState,id: U32,choice: U32) -> CorePacket:
  match decision state:
    case RP.Decision{False{},_} state: CoreRejected{state,"Stale, duplicate, ineligible or invalid reward choice"}
    case RP.Decision{True{},remaining} CoreState{world,shared,+refs,bodies,snapshots,round,_,offers,pending}:
      choice_loaded(id,choice,shared,refs,bodies,snapshots,round,remaining,offers,pending,load_players(refs,[],world))
def core_choose(state: CoreState,+id: U32,+requestedRound: U32,+choice: U32) -> CorePacket:
  match state:
    case CoreState{world,+shared,refs,bodies,snapshots,+round,+required,+offers,pending}: choice_decided(RP.decide(round,requestedRound,id,choice,U32.from_nat(List.length(&2,G.Offer,offers_for(offers,id))),required),CoreState{world,shared,refs,bodies,snapshots,round,required,offers,pending},id,choice)
def disconnect_players(players: List<&2,G.PlayerRecord>,+id: U32) -> List<&2,G.PlayerRecord>:
  match players:
    case []: []
    case G.PlayerRecord{+pid,run,+connected} <> rest: G.PlayerRecord{pid,run,Bool.and(connected,U32.is_ne(id,pid))} <> disconnect_players(rest,id)
# Completed run receipts survive later transport teardown. An unfinished match
# stopped by connection loss is an abort, never a bankable defeat/victory.
def disconnect_phase(+shared: G.Run) -> U32:
  Bool.pick(U32,Bool.or(U32.is_eq(run_phase(shared),3),U32.is_eq(run_phase(shared),4)),run_phase(shared),5)
def disconnect_terminal(terminal: Bool,+shared: G.Run,refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,required: List<&2,U32>,offers: List<&2,PlayerOffers>,pending: List<&2,Reward>,world: G.World(),players: List<&2,G.PlayerRecord>,+id: U32) -> CorePacket:
  match terminal:
    case True{}: quiet(CoreState{world,with_phase(shared,disconnect_phase(shared)),refs,bodies,snapshots,round,[],[],[]})
    case False{}: resume_control(RP.remove(required,id),world,shared,refs,bodies,snapshots,round,players,remove_offers(offers,id),pending)
def disconnected(+id: U32,+shared: G.Run,+refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,required: List<&2,U32>,offers: List<&2,PlayerOffers>,pending: List<&2,Reward>,world: G.World(),+players: List<&2,G.PlayerRecord>) -> CorePacket:
  disconnect_terminal(Bool.or(U32.is_le(3,run_phase(shared)),Bool.or(U32.is_eq(id,0),Nat.is_eq(List.length(&2,U32,living_ids(players)),0n))),shared,refs,bodies,snapshots,round,required,offers,pending,save_players(refs,players,world),players,id)
def disconnect_loaded(+id: U32,+shared: G.Run,+refs: List<&2,PlayerRef>,bodies: List<&2,G.Body>,snapshots: List<&2,G.Snapshot>,round: U32,required: List<&2,U32>,offers: List<&2,PlayerOffers>,pending: List<&2,Reward>,result: G.World() & List<&2,G.PlayerRecord>) -> CorePacket:
  match result:
    case (world,players): disconnected(id,shared,refs,bodies,snapshots,round,required,offers,pending,world,disconnect_players(players,id))
def core_disconnect(state: CoreState,id: U32) -> CorePacket:
  match state:
    case CoreState{world,shared,+refs,bodies,snapshots,round,required,offers,pending}: disconnect_loaded(id,shared,refs,bodies,snapshots,round,required,offers,pending,load_players(refs,[],world))
