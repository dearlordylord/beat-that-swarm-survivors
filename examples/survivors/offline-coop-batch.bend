import run-state.bend as RS
import enemy-combat.bend as Enemy
import enemy-spatial.bend as Space
import pickup-state.bend as Pickup
# Native controller experiment over the actual shared co-op world. The public
# Core path is intentionally retained; its frame JSON is discarded, never parsed.
import Base
import game-components.bend as Components
import game-storage.bend as Storage
import game.bend as G
import coop-core.bend as Core
import native-economy.bend as Economy
import offline-policy.bend as Policy
import offline-coop-control.bend as Control

type Observed is Type: Observed{state:Core.CoreState,shared:RS.Session,p0:G.Run,p1:G.Run,rows:List<&2,Components.Body>,snapshots:List<&2,G.Snapshot>,round:U32,required:List<&2,U32>,offers:List<&2,Core.PlayerOffers>}
type Checked is Type: CoopReady{observed:Observed} CoopBroken{message:String}
type Progress is Type: Progress{packet:Core.CorePacket,m0:Policy.Memory,m1:Policy.Memory,choices0:U32,choices1:U32}

def environment(result:Result<&1,&1,U32 & String,String>) -> String:
  match result:
    case Done{text}: text
    case Fail{_}: ""
def parsed(value:Maybe<&2,U32>,fallback:U32) -> U32:
  match value:
    case Some{value}: value
    case None{}: fallback
def number(text:String,fallback:U32) -> U32: parsed(U32.read(text),fallback)
def profile_meta(advanced:Bool) -> U32: Bool.pick(U32,advanced,364304237,Economy.meta(Economy.fresh()))
def profile_character(advanced:Bool) -> U32: Bool.pick(U32,advanced,2,0)
def profile_arcana(advanced:Bool) -> U32: Bool.pick(U32,advanced,9,0)
def unlock(packet:Core.CorePacket,id:U32) -> Core.CorePacket:
  match packet:
    case Core.CorePacket{state,_}: Core.core_configure_unlocks(state,id,Economy.weapon_mask(Economy.fresh()))
    case packet: packet
def unlock_profile(advanced:Bool,packet:Core.CorePacket) -> Core.CorePacket:
  match advanced:
    case True{}: packet
    case False{}: unlock(unlock(packet,0),1)
def join(packet:Core.CorePacket,character:U32,meta:U32,arcana:U32) -> Core.CorePacket:
  match packet:
    case Core.CorePacket{state,_}: Core.core_join(state,character,meta,arcana)
    case packet: packet
def configure(packet:Core.CorePacket,arcana:U32) -> Core.CorePacket:
  match packet:
    case Core.CorePacket{state,_}: Core.core_configure(state,0,0,arcana)
    case packet: packet
def start(seed:U32,+advanced:Bool,character0:U32,character1:U32,arcana0:U32,arcana1:U32) -> Core.CorePacket:
  unlock_profile(advanced,join(configure(Core.core_start(character0,profile_meta(advanced),seed),arcana0),character1,profile_meta(advanced),arcana1))

# C.get returns the same affine world alongside read-only copied records.
def observed_players(state: Core.CoreState,+shared: RS.Session,rows: List<&2,Components.Body>,snapshots: List<&2,G.Snapshot>,round: U32,required: List<&2,U32>,offers: List<&2,Core.PlayerOffers>,p0: Maybe<&2,RS.PlayerState>,p1: Maybe<&2,RS.PlayerState>) -> Checked:
  match p0 p1:
    case Some{p0} Some{p1}: CoopReady{Observed{state,shared,Core.player_step_context(shared,p0),Core.player_step_context(shared,p1),rows,snapshots,round,required,offers}}
    case _ _: CoopBroken{"native co-op requires both player records"}
def observed_loaded(+shared:RS.Session,+refs:List<&2,Core.PlayerRef>,+rows:List<&2,Components.Body>,+snapshots:List<&2,G.Snapshot>,+round:U32,+required:List<&2,U32>,+offers:List<&2,Core.PlayerOffers>,pending:List<&2,Core.Reward>,result:Storage.World() & List<&2,Components.PlayerRecord>) -> Checked:
  match result:
    case (world,+players): observed_players(Core.CoreState{world,shared,refs,rows,snapshots,round,required,offers,pending},shared,rows,snapshots,round,required,offers,Core.find_player(players,0),Core.find_player(players,1))
def observe(packet:Core.CorePacket) -> Checked:
  match packet:
    case Core.CorePacket{Core.CoreState{world,+shared,+refs,+rows,snapshots,+round,+required,+offers,pending},_}: observed_loaded(shared,refs,rows,snapshots,round,required,offers,pending,Core.load_players(refs,[],world))
    case Core.CoreRejected{_,message}: CoopBroken{"Co-op command rejected: " ++ message}
    case Core.CoreFailed{message}: CoopBroken{"Co-op game failed: " ++ message}

def moved_xy1(state:Core.CoreState,m0:Policy.Memory,m1:Policy.Memory,choices0:U32,choices1:U32,dx0:F32,dy0:F32,d1:F32 & F32) -> Progress:
  (dx1,dy1) = d1
  Progress{Core.core_step(state,dx0,dy0,dx1,dy1),m0,m1,choices0,choices1}
def moved_xy0(state:Core.CoreState,m0:Policy.Memory,m1:Policy.Memory,choices0:U32,choices1:U32,d0:F32 & F32,d1:F32 & F32) -> Progress:
  (dx0,dy0) = d0
  moved_xy1(state,m0,m1,choices0,choices1,dx0,dy0,d1)
def moved_right(state:Core.CoreState,m0:Policy.Memory,choices0:U32,choices1:U32,d0:F32 & F32,move1:Policy.Memory & (F32 & F32)) -> Progress:
  (m1,d1) = move1
  moved_xy0(state,m0,m1,choices0,choices1,d0,d1)
def moved(state:Core.CoreState,choices0:U32,choices1:U32,move0:Policy.Memory & (F32 & F32),move1:Policy.Memory & (F32 & F32)) -> Progress:
  (m0,d0) = move0
  moved_right(state,m0,choices0,choices1,d0,move1)
def choose_or_move(required:List<&2,U32>,state:Core.CoreState,shared:RS.Session,+p0:G.Run,+p1:G.Run,+rows:List<&2,Components.Body>,+snapshots:List<&2,G.Snapshot>,round:U32,offers:List<&2,Core.PlayerOffers>,m0:Policy.Memory,m1:Policy.Memory,+choices0:U32,+choices1:U32) -> Progress:
  match required:
    case +id <> _: Progress{Core.core_choose(state,id,round,Policy.upgrade(Bool.pick(G.Run,U32.is_eq(id,0),p0,p1),Core.offers_for(offers,id))),m0,m1,(choices0 + Bool.to_u32(U32.is_eq(id,0)) : U32),(choices1 + Bool.to_u32(U32.is_eq(id,1)) : U32)}
    case []: moved(state,choices0,choices1,Policy.movement(m0,p0,rows,snapshots),Policy.movement(m1,p1,rows,snapshots))

def population_go(rows:List<&2,G.Snapshot>,+boss:U32,+ordinary:U32) -> U32 & U32:
  match rows:
    case []: (ordinary,boss)
    case G.EnemySnapshot{Enemy.State{_,+variant,_,Components.Vitals{+hp,_},_}} <> tail: population_go(tail,(boss + Bool.to_u32(Control.boss(0,variant,hp)) : U32),(ordinary + Bool.to_u32(Control.ordinary(0,variant,hp)) : U32))
    case _ <> tail: population_go(tail,boss,ordinary)
def near_go(rows:List<&2,G.Snapshot>,+px:F32,+py:F32,+count:U32) -> U32:
  match rows:
    case []: count
    case G.EnemySnapshot{Enemy.State{Space.Spatial{x,y,_,_},_,_,Components.Vitals{hp,_},_}} <> tail: near_go(tail,px,py,(count + Bool.to_u32(Bool.and(U32.is_lt(0,hp),F32.is_le(((x - px) * (x - px) + (y - py) * (y - py) : F32),14400.0))) : U32))
    case _ <> tail: near_go(tail,px,py,count)
def xp_go(rows:List<&2,G.Snapshot>,+piles:U32,+value:U32) -> U32 & U32:
  match rows:
    case []: (piles,value)
    case G.PickupSnapshot{Pickup.State{_,Pickup.Payload{Pickup.Xp{amount,_},_,True{}},_}} <> tail: xp_go(tail,(piles + 1 : U32),(value + amount : U32))
    case _ <> tail: xp_go(tail,piles,value)
def population_fields(pair:U32 & U32) -> String:
  (+ordinary,+boss) = pair
  "\"population\":" ++ U32.show((ordinary + boss : U32)) ++ ",\"ordinaryPopulation\":" ++ U32.show(ordinary) ++ ",\"bossPopulation\":" ++ U32.show(boss)
def xp_fields(pair:U32 & U32) -> String:
  (piles,value) = pair
  ",\"xpPiles\":" ++ U32.show(piles) ++ ",\"uncollectedBaseXp\":" ++ U32.show(value)
def u32_items(values:List<&2,U32>) -> String:
  match values:
    case []: ""
    case value <> []: U32.show(value)
    case value <> tail: U32.show(value) ++ "," ++ u32_items(tail)
def player_setup(+run:G.Run) -> String:
  "{\"character\":" ++ U32.show(Core.run_character(run)) ++ ",\"arcana\":" ++ U32.show(Core.run_arcana(run)) ++ ",\"meta\":" ++ U32.show(Core.run_meta(run)) ++ ",\"bannedWeapons\":" ++ U32.show(Core.run_bannedWeapons(run)) ++ ",\"weapons\":[" ++ u32_items(Core.run_weapons(run)) ++ "],\"passives\":[" ++ u32_items(Core.run_passives(run)) ++ "],\"hp\":" ++ U32.show(Core.run_hp(run)) ++ ",\"maxHp\":" ++ U32.show(Core.run_maxHp(run)) ++ "}"
def initial_setup_fields(initial:Bool,+shared:RS.Session,p0:G.Run,p1:G.Run) -> String:
  match initial:
    case False{}: ""
    case True{}: ",\"initialSetup\":{\"stage\":" ++ U32.show(RS.session_stage(shared)) ++ ",\"mode\":" ++ U32.show(RS.session_mode(shared)) ++ ",\"players\":[" ++ player_setup(p0) ++ "," ++ player_setup(p1) ++ "]}"
def fields(+seed:U32,+index:U32,+ticks:U32,+shared:RS.Session,+p0:G.Run,+p1:G.Run,+snapshots:List<&2,G.Snapshot>,choices0:U32,choices1:U32) -> String:
  "\"seed\":" ++ U32.show(seed) ++ ",\"index\":" ++ U32.show(index) ++ ",\"tick\":" ++ U32.show(RS.session_tick(shared)) ++ ",\"phase\":" ++ U32.show(RS.session_phase(shared)) ++ ",\"requestedTicks\":" ++ U32.show(ticks) ++ "," ++ population_fields(population_go(snapshots,0,0)) ++ ",\"hp0\":" ++ U32.show(Core.run_hp(p0)) ++ ",\"hp1\":" ++ U32.show(Core.run_hp(p1)) ++ ",\"maxHp0\":" ++ U32.show(Core.run_maxHp(p0)) ++ ",\"maxHp1\":" ++ U32.show(Core.run_maxHp(p1)) ++ ",\"px0\":" ++ F32.show(Core.run_px(p0)) ++ ",\"py0\":" ++ F32.show(Core.run_py(p0)) ++ ",\"px1\":" ++ F32.show(Core.run_px(p1)) ++ ",\"py1\":" ++ F32.show(Core.run_py(p1)) ++ ",\"nearEnemies0\":" ++ U32.show(near_go(snapshots,Core.run_px(p0),Core.run_py(p0),0)) ++ ",\"nearEnemies1\":" ++ U32.show(near_go(snapshots,Core.run_px(p1),Core.run_py(p1),0)) ++ ",\"xp\":" ++ U32.show(RS.session_xp(shared)) ++ ",\"xpNeed\":" ++ U32.show(RS.session_need(shared)) ++ ",\"level\":" ++ U32.show(RS.session_level(shared)) ++ ",\"kills\":" ++ U32.show(RS.session_kills(shared)) ++ ",\"gold\":" ++ U32.show(RS.session_gold(shared)) ++ ",\"choices0\":" ++ U32.show(choices0) ++ ",\"choices1\":" ++ U32.show(choices1) ++ xp_fields(xp_go(snapshots,0,0)) ++ initial_setup_fields(U32.is_eq(RS.session_tick(shared),0),shared,p0,p1)

def sampled(emit:Bool,text:String,nextSample:Nat,progress:Progress,next:Progress -> Nat -> IO(Unit)) -> IO(Unit):
  match emit:
    case True{}:
      do IO<Unit>:
        IO.print("{\"type\":\"sample\"," ++ text ++ "}")
        IO.print_err("Co-op balance sample")
        next(progress,nextSample)
    case False{}: next(progress,nextSample)
def next_sample(emit:Bool,tick:U32,current:Nat) -> Nat: Bool.pick(Nat,emit,Nat.add(U32.to_nat(tick),60n),current)
def run_observed(stopped:Bool,+outcome:Control.Outcome,+seed:U32,index:U32,+ticks:U32,started:Nat,+nextSample:Nat,m0:Policy.Memory,m1:Policy.Memory,+choices0:U32,+choices1:U32,observed:Observed,next:Progress -> Nat -> IO(Unit)) -> IO(Unit):
  match stopped observed:
    case True{} Observed{_,+shared,p0,p1,rows,snapshots,_,_,_}:
      do IO<Unit>:
        now : Nat <- IO.now()
        IO.print("{\"type\":\"summary\"," ++ fields(seed,index,ticks,shared,p0,p1,snapshots,choices0,choices1) ++ ",\"outcome\":\"" ++ Control.name(outcome) ++ "\",\"wallMs\":" ++ Nat.show(Nat.sub(now,started)) ++ "}")
        IO.print_err("Completed native co-op seed " ++ U32.show(seed) ++ " at tick " ++ U32.show(RS.session_tick(shared)))
    case False{} Observed{state,+shared,+p0,+p1,+rows,+snapshots,round,+required,offers}:
      +emit = Nat.is_ge(U32.to_nat(RS.session_tick(shared)),nextSample)
      sampled(emit,fields(seed,index,ticks,shared,p0,p1,snapshots,choices0,choices1),next_sample(emit,RS.session_tick(shared),nextSample),choose_or_move(required,state,shared,p0,p1,rows,snapshots,round,offers,m0,m1,choices0,choices1),next)
def inspect(seed:U32,index:U32,+ticks:U32,started:Nat,nextSample:Nat,m0:Policy.Memory,m1:Policy.Memory,choices0:U32,choices1:U32,observed:Observed,next:Progress -> Nat -> IO(Unit)) -> IO(Unit):
  match observed:
    case Observed{state,+shared,p0,p1,rows,snapshots,round,required,offers}:
      +result = Control.outcome(RS.session_phase(shared),RS.session_tick(shared),ticks)
      run_observed(Control.stopped(result),result,seed,index,ticks,started,nextSample,m0,m1,choices0,choices1,Observed{state,shared,p0,p1,rows,snapshots,round,required,offers},next)
def inspect_ready(ready:Checked,seed:U32,index:U32,ticks:U32,started:Nat,nextSample:Nat,m0:Policy.Memory,m1:Policy.Memory,choices0:U32,choices1:U32,next:Progress -> Nat -> IO(Unit)) -> IO(Unit):
  match ready:
    case CoopBroken{message}: IO.die(Unit,1,message)
    case CoopReady{observed}: inspect(seed,index,ticks,started,nextSample,m0,m1,choices0,choices1,observed,next)
def loop(fuel:Nat,+seed:U32,+index:U32,+ticks:U32,+started:Nat,nextSample:Nat,progress:Progress) -> IO(Unit):
  match fuel progress:
    case 0n _: IO.die(Unit,1,"Native co-op exhausted safety fuel")
    case 1n+rest Progress{packet,m0,m1,choices0,choices1}: inspect_ready(observe(packet),seed,index,ticks,started,nextSample,m0,m1,choices0,choices1,(progress => (nextSample => loop(rest,seed,index,ticks,started,nextSample,progress))))

def launch(seedText:String,indexText:String,ticksText:String,profileText:String,character0Text:String,character1Text:String,arcana0Text:String,arcana1Text:String,+started:Nat) -> IO(Unit):
  +advanced = String.eq(profileText,"advanced")
  +seed = number(seedText,12345)
  +index = number(indexText,0)
  +ticks = U32.max(1,U32.min(37000,number(ticksText,7200)))
  loop(U32.to_nat((ticks * 8 + 100 : U32)),seed,index,ticks,started,0n,Progress{start(seed,advanced,number(character0Text,profile_character(advanced)),number(character1Text,profile_character(advanced)),number(arcana0Text,profile_arcana(advanced)),number(arcana1Text,profile_arcana(advanced))),Policy.initial(),Policy.initial(),0,0})

def main() -> IO(Unit):
  do IO<Unit>:
    seedText : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_SEED")
    indexText : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_INDEX")
    ticksText : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_TICKS")
    profileText : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_PROFILE")
    character0Text : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_CHARACTER0")
    character1Text : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_CHARACTER1")
    arcana0Text : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_ARCANA0")
    arcana1Text : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_COOP_ARCANA1")
    started : Nat <- IO.now()
    launch(environment(seedText),environment(indexText),environment(ticksText),environment(profileText),environment(character0Text),environment(character1Text),environment(arcana0Text),environment(arcana1Text),started)
