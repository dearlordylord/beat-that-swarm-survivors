import Base
import starter-mechanics.bend as M
import starter-mechanics-integration-test.bend as T
import game.bend as G
import projectile-state.bend as S
import pools.bend as PL
import projectile-pool.bend as SP
import game-components.bend as K
import enemy-spatial.bend as Space

def raised(fuel: Nat,+run: G.Run) -> G.Run:
  match fuel:
    case 0n: run
    case 1n+rest: raised(rest,G.upgrade(G.Offer{0,G.starter(G.run_character(run)),0},run))
def evolved_afterbeat() -> Bool:
  U32.is_lt(0,G.accepted(G.team_plan([G.PlayerView{0,raised(6n,T.run(3,1,M.empty())),0.0,0.0,True{}}],[]),0,22,M.PrimaryKind{}))
def blocked_echo() -> Bool:
  U32.is_eq(U32.from_nat(List.length(&2,M.Echo,M.due(G.settle_owner(G.PlayerView{0,T.run(5,27,M.enqueue(M.empty(),M.fresh_echo(7,27,20.0,30.0,100,2,1.0,1.0,1.0,3))),0.0,0.0,True{}},G.empty_shot_plan(),[],[]),27))),1)
def count_upgrade() -> Bool:
  Bool.not(G.retire_trail(T.shot(22,PL.player_start(),40,9999,M.Attack{1,True{},M.Trail{True{}}}),T.team(T.run(3,100,M.empty()),T.trails(3n,30))))
def capture() -> M.Echo: M.fresh_echo(7,27,20.0,30.0,100,3,1.0,1.0,1.0,3)
def echo_owner() -> M.Owner: M.enqueue(M.empty(),capture())
def echo_view() -> G.PlayerView: G.PlayerView{0,T.run(5,27,echo_owner()),0.0,0.0,True{}}
def partial_plan() -> SP.Plan:
  SP.allocate([PL.player_start()],G.empty_owner_counts(),PL.caps(),G.mechanic_requests(0,T.run(5,27,echo_owner()),[],G.empty_owner_counts()))
def partial_preserved(rows: List<&2,M.Echo>) -> Bool:
  match rows:
    case M.Echo{7,27,x,y,100,3,_,_,_,_,1 <> 2 <> Nil{}} <> Nil{}: Bool.and(F32.is_eq(x,20.0),F32.is_eq(y,30.0))
    case _: False{}
def partial_echo() -> Bool:
  partial_preserved(M.due(G.settle_owner(echo_view(),partial_plan(),[],[]),28))
def filled_echoes(+fuel: Nat,owner: M.Owner) -> M.Owner:
  match fuel:
    case 0n: owner
    case 1n+rest: filled_echoes(rest,M.enqueue(owner,M.fresh_echo(U32.from_nat(fuel),27,20.0,30.0,100,3,1.0,1.0,1.0,3)))
def queue_backpressure() -> Bool:
  U32.is_eq(G.accepted(G.team_plan([G.PlayerView{0,T.run(5,1,filled_echoes(8n,M.empty())),0.0,0.0,True{}}],[]),0,23,M.PrimaryKind{}),0)
def one_echo_attempt() -> Bool:
  U32.is_eq(T.request_count(G.mechanic_requests(0,T.run(5,27,filled_echoes(8n,M.empty())),[],G.empty_owner_counts()),M.EchoKind{}),3)
def evolved_v_run() -> G.Run: raised(6n,T.run(5,1,M.empty()))
def evolved_v_team() -> G.Team: T.team(evolved_v_run(),[])
def evolved_v_echo(rows: List<&2,M.Echo>) -> Bool:
  match rows:
    case M.Echo{1,28,_,_,_,2,_,_,_,_,0 <> 1 <> Nil{}} <> Nil{}: True{}
    case _: False{}
def evolved_radial_capture() -> Bool:
  evolved_v_echo(M.due(G.run_mechanics(G.view_run(G.settled_view(evolved_v_team(),0))),28))
def horizontal(value: S.State,left: Bool) -> Bool:
  match value:
    case S.State{_,_,_,K.ShotPayload{23,_,_,_},K.Trajectory{+vx,vy,_,_,_,_,_,_}}: Bool.and(F32.is_lt(F32.abs(vy),0.001),Bool.pick(Bool,left,F32.is_lt(vx,0.0),F32.is_lt(0.0,vx)))
    case _: False{}
def evolved_radial_spacing() -> Bool:
  Bool.and(horizontal(T.row(G.team_shot_spawn(evolved_v_team(),512,Some{SP.Request{23,SP.Emission{0,0},9,M.Primary{}}})),False{}),horizontal(T.row(G.team_shot_spawn(evolved_v_team(),513,Some{SP.Request{23,SP.Emission{0,2},9,M.Primary{}}})),True{}))
def hearth_shot(source: U32,slot: U32,x: F32,y: F32) -> G.Snapshot:
  G.ProjectileSnapshot{S.State{Space.Spatial{x,y,60,14.0},700,S.PlayerShot{},K.ShotPayload{21,10,True{},M.ordinary()},K.Trajectory{1.0,80.0,180,9999,[],21,slot,Some{source}}}}
def same_position(a: S.State,b: S.State) -> Bool:
  match a b:
    case S.State{Space.Spatial{x,y,_,_},_,_,_,_} S.State{Space.Spatial{xx,yy,_,_},_,_,_,_}: Bool.and(F32.is_lt(F32.abs((x - xx : F32)),0.001),F32.is_lt(F32.abs((y - yy : F32)),0.001))
def hearth_spark(team: G.Team,slot: U32) -> S.State:
  T.row(G.team_shot_spawn(team,800,Some{SP.Request{21,SP.Emission{0,slot},1,M.Primary{}}}))
def hearth_live_origin() -> Bool:
  same_position(hearth_spark(T.team(T.run(1,400,M.empty()),[hearth_shot(1,0,900.0,900.0),hearth_shot(0,2,20.0,30.0),hearth_shot(0,0,145.0,167.0)]),1),T.row(G.ProjectileRow{S.Outcome{S.State{Space.Spatial{145.0,167.0,0,1.0},0,S.PlayerShot{},K.ShotPayload{0,0,True{},M.ordinary()},K.Trajectory{0.0,0.0,1,1,[],21,1,Some{0}}},0}}))
def hearth_initial_origin() -> Bool:
  +team = T.team(T.run(1,1,M.empty()),[])
  same_position(hearth_spark(team,1),T.row(G.team_shot_spawn(team,801,Some{SP.Request{21,SP.Emission{0,0},1,M.Primary{}}})))
def main() -> IO(Unit):
  do IO<Unit>:
    T.expect(hearth_live_origin(),"Hearth sparks spawn at their own live paired familiar")
    T.expect(hearth_initial_origin(),"first-level Hearth spark begins at the simultaneously spawned familiar")
    T.expect(evolved_afterbeat(),"evolved Afterbeat retains scheduled Gathering Ink")
    T.expect(blocked_echo(),"allocation rejection retains a due captured echo")
    T.expect(count_upgrade(),"weapon level projectile bonus increases armed trail capacity")
    T.expect(partial_echo(),"partial allocation retries only missing spokes at the captured origin and spacing")
    T.expect(queue_backpressure(),"full echo queue waits new primary casts automatically")
    T.expect(one_echo_attempt(),"one owner attempts only its oldest delayed volley each tick")
    T.expect(evolved_radial_capture(),"evolved Waking Frame captures only actual radial spokes")
    T.expect(evolved_radial_spacing(),"evolved primary radial spokes retain even spacing")
    return Unit{}
