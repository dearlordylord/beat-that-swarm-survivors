# Throwaway serialization experiment. No production callers or game rules.
import Base
import ./coop-core.bend as C
import ./game.bend as G
import ./coop-prediction.bend as P
import ./coop-combat-prediction.bend as Combat

type Player is Data: Player{id:U32,px:F32,py:F32,hp:U32,maxHp:U32,character:U32,connected:Bool,alive:Bool}
type Observation is Data: Observation{run:G.Run,bodies:List<&2,G.Body>,offers:List<&2,G.Offer>,worldSize:F32,worldMargin:F32,relicX:F32,relicY:F32,runLength:U32,predictionAllowed:Bool,stepDistance:F32,ownPlayerId:U32,choicePending:Bool,roundId:U32,requiredPlayers:List<&2,U32>,players:List<&2,Player>,combatForecast:Combat.Scene}
type Observed is Type: Observed{state:C.CoreState,observation:Observation}
def players(rows:List<&2,G.PlayerRecord>) -> List<&2,Player>:
  match rows:
    case []: []
    case G.PlayerRecord{id,+run,+connected} <> tail: Player{id,C.run_px(run),C.run_py(run),C.run_hp(run),C.run_maxHp(run),C.run_character(run),connected,U32.is_gt(C.run_hp(run),0)} <> players(tail)
def observation(+run:G.Run,bodies:List<&2,G.Body>,offers:List<&2,G.Offer>,prediction:Bool,step:F32,id:U32,choice:Bool,round:U32,required:List<&2,U32>,team:List<&2,G.PlayerRecord>,scene:Combat.Scene) -> Observation:
  Observation{run,G.visible_bodies(bodies),offers,G.world_size(),G.world_margin(),G.relic_x(G.run_stage(run)),G.relic_y(G.run_stage(run)),G.run_length(G.run_mode(run)),prediction,step,id,choice,round,required,players(team),scene}
def loaded(+shared:G.Run,refs:List<&2,C.PlayerRef>,+bodies:List<&2,G.Body>,+snapshots:List<&2,G.Snapshot>,+round:U32,+required:List<&2,U32>,+offers:List<&2,C.PlayerOffers>,pending:List<&2,C.Reward>,+id:U32,result:G.World() & List<&2,G.PlayerRecord>) -> Observed:
  match result:
    case (world,+team): Observed{C.CoreState{world,shared,refs,bodies,snapshots,round,required,offers,pending},observation(C.observer_run(shared,team,id),bodies,C.offers_for(offers,id),P.allowed(C.run_phase(shared),C.run_hp(C.find_player(team,id,shared)),C.player_connected(team,id)),G.run_step_distance(C.find_player(team,id,shared)),id,G.contains(required,id),round,required,team,Combat.initialize(id,C.forecast_players(shared,team),snapshots))}
def observe(state:C.CoreState,+id:U32) -> Observed:
  match state:
    case C.CoreState{world,+shared,+refs,bodies,snapshots,round,required,offers,pending}: loaded(shared,refs,bodies,snapshots,round,required,offers,pending,id,C.load_players(refs,[],world))
def baseline(state:C.CoreState,id:U32) -> C.CorePacket: C.core_observe(state,id)
def start() -> C.CorePacket: C.core_start(0,0,12345)
def join(state:C.CoreState) -> C.CorePacket: C.core_join(state,1,0,0)
def step(state:C.CoreState) -> C.CorePacket: C.core_step(state,1.0,0.0,0.0,1.0)
def disconnect(state:C.CoreState) -> C.CorePacket: C.core_disconnect(state,1)
