# Typed projection only. This module exposes no world-forecast operation.
import Base
import game-components.bend as Components
import ./game.bend as G
import ./coop-combat-prediction.bend as Wire
import ./coop-playback.bend as P
import ./coop-playback-wire-policy.bend as Projection
import ./body-index.bend as BI
import ./list-map.bend as LM

type BodyContext is Data: BodyContext{tick:U32,births:BI.Index<U32>}
def player_actor(player:G.PlayerSnapshot) -> P.Actor:
  match player:
    case G.PlayerSnapshot{id,+run,connected}: Projection.player_actor(id,G.run_character(run),G.run_px(run),G.run_py(run),G.run_hp(run),connected)
def mapped_player(context:Unit,player:G.PlayerSnapshot) -> P.Actor: player_actor(player)
def body_liveness(kind:U32,hp:U32,life:U32,pierce:U32) -> U32: Projection.body_liveness(kind,hp,life,pierce)
def body_actor(body:Components.Body,motion:G.Motion,born:U32) -> P.Actor:
  match body motion:
    case Components.Body{x,y,kind,_,hp,_,age,seed,_} G.Motion{_,_,life,pierce,_,_,_,weapon,slot}: Projection.body_actor(seed,kind,born,weapon,slot,x,y,age,hp,life,pierce)
def snapshot_actor(context:BodyContext,snapshot:G.Snapshot) -> P.Actor:
  match context snapshot:
    case BodyContext{tick,births} G.Snapshot{Components.Body{x,y,kind,_,hp,_,+age,+seed,_},G.Motion{_,_,life,pierce,_,_,_,weapon,slot}}: Projection.body_actor(seed,kind,Projection.birth(births,tick,age,seed),weapon,slot,x,y,age,hp,life,pierce)
def extra_selected(keep:Bool,key:U32,kind:U32,variant:U32,x:F32,y:F32,age:U32,hp:U32,tick:U32) -> Maybe<&2,P.Actor>:
  Projection.extra_selected(keep,key,kind,variant,x,y,age,hp,tick)
def extra_actor(key:U32,kind:U32,variant:U32,x:F32,y:F32,age:U32,hp:U32,tick:U32) -> Maybe<&2,P.Actor>:
  Projection.extra_actor(key,kind,variant,x,y,age,hp,tick)
def join(first:List<&2,P.Actor>,second:List<&2,P.Actor>) -> List<&2,P.Actor>: Projection.join(first,second)
def project(scene:Wire.Scene,observation:U32,receivedAt:Nat,extras:List<&2,P.Actor>) -> P.Frame:
  match scene:
    case Wire.Scene{_,players,snapshots,births,_,_,+tick,_}: Projection.frame(observation,tick,receivedAt,LM.map(~G.PlayerSnapshot,~P.Actor,~Unit,~mapped_player,Unit{},players),LM.map(~G.Snapshot,~P.Actor,~BodyContext,~snapshot_actor,BodyContext{tick,births},snapshots),extras)
def own_run(scene:Wire.Scene) -> Maybe<&2,G.Run>:
  match scene:
    case Wire.Scene{own,players,_,_,_,_,_,_}: Wire.find_run(players,own)
