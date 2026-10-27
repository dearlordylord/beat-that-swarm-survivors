import Base
import starter-mechanics.bend as M
import game.bend as G
import run-state.bend as RS
import projectile-state.bend as S
import projectile.bend as P
import projectile-pool.bend as SP
import projectile-contact.bend as C
import game-components.bend as K
import enemy-spatial.bend as Space
import enemy-combat.bend as E
import enemy-effects.bend as Effects
import body-index.bend as BI
import pools.bend as PL

def expect(ok:Bool,label:String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def run(+character:U32,tick:U32,mechanics:M.Owner) -> G.Run:
  G.Run{RS.Session{1,tick,0,40,1,0,0,1,0,0,0,[],0},RS.PlayerState{100.0,100.0,100,100,character,G.set_at(G.empty_owner_counts(),G.starter(character),3),[],0,99,0,0,0,0,0,0,0,mechanics}}
def team(+run:G.Run,+snapshots:List<&2,G.Snapshot>) -> G.Team:
  G.Team{[G.PlayerView{0,run,1.0,0.0,True{}}],G.combat_args(run,1.0,0.0,snapshots),G.team_plan([G.PlayerView{0,run,1.0,0.0,True{}}],snapshots),G.effect_origin_index(snapshots)}
def shot(+weapon:U32,seed:U32,age:U32,pierce:U32,attack:M.Attack) -> S.State:
  S.State{Space.Spatial{100.0,100.0,age,10.0},seed,S.PlayerShot{},K.ShotPayload{weapon,100,True{},attack},K.Trajectory{1.0,0.0,100,pierce,[],weapon,0,Some{0}}}
def row(value:G.EntityRow) -> S.State:
  match value:
    case G.ProjectileRow{S.Outcome{shot,_}}: shot
    case _: S.dormant(0.0,0.0,0,S.PlayerShot{})
def outcome(value:S.Outcome) -> S.State:
  match value:
    case S.Outcome{shot,_}: shot
def input() -> S.StepInput: S.StepInput{100.0,100.0,200.0,100.0,False{}}
def plans(+shot:S.State) -> List<&2,G.HitPlan>:
  G.contact_shot_plan(True{},shot,team(run(4,50,M.empty()),[]),[C.Target{10,100.0,100.0,100.0,100.0,1.0},C.Target{11,100.0,100.0,100.0,100.0,1.0}],[])
def target_damage(rows:List<&2,G.HitPlan>,+target:U32) -> U32:
  match rows:
    case []: 0
    case G.HitPlan{_,_,damage,_,_,_,area,targets} <> rest: (M.number(Bool.or(area,G.contains(targets,target)),damage,0) + target_damage(rest,target) : U32)
def enemy(id:U32) -> G.Snapshot:
  G.EnemySnapshot{E.State{Space.Spatial{100.0,100.0,0,1.0},0,id,K.Vitals{100,100},K.Status{Effects.empty_slow(),Effects.empty_burn()}}}
def ink(ticks:U32,resolved:Bool) -> S.State: shot(20,PL.player_start(),1,9999,M.Attack{1,True{},M.Ink{ticks,resolved}})
def ink_plans(+value:S.State,enemies:List<&2,G.Snapshot>) -> List<&2,G.HitPlan>:
  G.contact_shot_plan(False{},value,team(run(0,100,M.empty()),enemies),[],[])
def ink_ticks_attack(value:M.Attack) -> U32:
  match value:
    case M.Attack{_,_,M.Ink{ticks,_}}: ticks
    case _: 999
def ink_ticks(value:S.State) -> U32: ink_ticks_attack(S.attack(value))
def ready_notes() -> M.Owner: M.Owner{0,3,0.0,0.0,0,0,0,0,0,[]}
def notes(value:M.Owner) -> U32:
  match value:
    case M.Owner{_,notes,_,_,_,_,_,_,_,_}: notes
def count(rows:List<&2,U32>) -> U32: U32.from_nat(List.length(&2,U32,rows))
def echo_ok(value:S.State) -> Bool:
  match value:
    case S.State{Space.Spatial{x,y,_,_},_,_,K.ShotPayload{23,damage,_,M.Attack{cast,False{},_}},K.Trajectory{vx,vy,_,_,_,23,_,Some{0}}}:
      Bool.and(F32.is_eq(x,20.0),Bool.and(F32.is_eq(y,30.0),Bool.and(U32.is_eq(damage,50),Bool.and(U32.is_eq(cast,7),Bool.and(F32.is_lt(F32.abs(vx),0.001),F32.is_lt(F32.abs((vy - 8.0 : F32)),0.001))))))
    case _: False{}
def trails(+fuel:Nat,+age:U32) -> List<&2,G.Snapshot>:
  match fuel:
    case 0n: []
    case 1n+rest: G.ProjectileSnapshot{shot(22,(PL.player_start() + U32.from_nat(fuel) : U32),age,9999,M.Attack{1,True{},M.Trail{False{}}})} <> trails(rest,age)
def ready_trail() -> M.Owner: M.Owner{0,0,40.0,0.0,0,0,0,0,0,[]}
def request_count(rows:List<&2,SP.Request>,+kind:M.EmissionKind) -> U32:
  match rows:
    case []: 0
    case SP.Request{_,_,_,emission} <> rest: (Bool.to_u32(M.emission_is(emission,kind)) + request_count(rest,kind) : U32)
def prepared_owner(character:U32,owner:M.Owner,snapshots:List<&2,G.Snapshot>) -> M.Owner:
  G.run_mechanics(G.view_run(G.prepare_view(G.PlayerView{0,run(character,100,owner),0.0,0.0,True{}},snapshots)))
def orbit_phase(value:M.Owner) -> F32:
  match value:
    case M.Owner{_,_,_,phase,_,_,_,_,_,_}: phase
def pulse_ok(value:S.State) -> Bool:
  match value:
    case S.State{_,_,_,K.ShotPayload{12,0,True{},M.Attack{_,False{},_}},K.Trajectory{_,_,1,9999,_,21,_,Some{0}}}: True{}
    case _: False{}
def hits_of(value:G.Team) -> List<&2,G.HitPlan>:
  match value:
    case G.Team{_,G.Args{_,_,_,_,_,hits},_,_}: hits
def combo_snapshot(seed:U32,primary:Bool,credited:Bool) -> G.Snapshot:
  G.ProjectileSnapshot{shot(1,seed,1,5,M.Attack{1,primary,M.Streak{credited}})}
def combo_pending(value:M.Owner) -> U32:
  match value:
    case M.Owner{_,_,_,_,_,_,_,_,pending,_}: pending
def six_streaks(+seed:U32) -> List<&2,G.Snapshot>:
  [combo_snapshot(seed,True{},False{}),combo_snapshot((seed + 1 : U32),True{},False{}),combo_snapshot((seed + 2 : U32),True{},False{}),combo_snapshot((seed + 3 : U32),True{},False{}),combo_snapshot((seed + 4 : U32),True{},False{}),combo_snapshot((seed + 5 : U32),True{},False{}),enemy(10)]
def six_contact_team() -> G.Team: G.contact_team(team(run(6,100,M.empty()),six_streaks(PL.player_start())))
def no_assignment(value: Maybe<&2,SP.Request>) -> Bool:
  match value:
    case None{}: True{}
    case _: False{}
def exhausted_fan_plan() -> SP.Plan:
  G.team_plan([G.PlayerView{0,run(4,1,M.empty()),0.0,0.0,True{}}],[G.ProjectileSnapshot{shot(8,PL.player_start(),10,0,M.Attack{1,True{},M.Fan{[10],1,False{}}})}])
def four_views() -> List<&2,G.PlayerView>:
  [G.PlayerView{0,run(6,1,M.empty()),0.0,0.0,True{}},G.PlayerView{1,run(6,1,M.empty()),0.0,0.0,True{}},G.PlayerView{2,run(6,1,M.empty()),0.0,0.0,True{}},G.PlayerView{3,run(6,1,M.empty()),0.0,0.0,True{}}]
def partitioned(index: BI.Index<SP.Request>) -> Bool:
  match index:
    case BI.Empty{}: True{}
    case BI.Item{seed,SP.Request{_,SP.Emission{source,_},_,_}}: U32.is_eq((seed % PL.coop_player_capacity() : U32),source)
    case BI.Fork{_,_,zero,one}: Bool.and(partitioned(zero),partitioned(one))
def four_assignments(+plan: SP.Plan) -> Bool:
  match plan:
    case SP.Plan{index,_}: Bool.and(partitioned(index),Bool.and(U32.is_lt(0,G.accepted(plan,0,1,M.PrimaryKind{})),Bool.and(U32.is_lt(0,G.accepted(plan,1,1,M.PrimaryKind{})),Bool.and(U32.is_lt(0,G.accepted(plan,2,1,M.PrimaryKind{})),U32.is_lt(0,G.accepted(plan,3,1,M.PrimaryKind{}))))))
def source_is(value: S.State,+source: U32) -> Bool:
  match value:
    case S.State{_,_,_,K.ShotPayload{1,_,_,M.Attack{1,True{},M.Streak{False{}}}},K.Trajectory{_,_,_,_,_,1,_,Some{player}}}: U32.is_eq(source,player)
    case _: False{}
def fourth_owner_spawn() -> S.State:
  row(G.team_shot_spawn(G.Team{four_views(),G.combat_args(run(6,1,M.empty()),0.0,0.0,[]),G.team_plan(four_views(),[]),BI.Empty{}},(PL.player_start() + 3 : U32),Some{SP.Request{1,SP.Emission{3,0},3,M.Primary{}}}))
def main() -> IO(Unit):
  do IO<Unit>:
    expect(four_assignments(G.team_plan(four_views(),[])),"four owners receive distinct nonempty projectile assignments")
    expect(source_is(fourth_owner_spawn(),3),"fourth owner starter keeps its source and mechanic provenance")
    expect(no_assignment(SP.lookup(exhausted_fan_plan(),PL.player_start())),"allocator reserves an exhausted outward fan until return")
    expect(S.active(outcome(S.step(shot(8,PL.player_start(),10,1,M.Attack{1,True{},M.Fan{[],1,False{}}}),input(),[10]))),"fan survives exhausted outgoing budget")
    expect(Bool.and(U32.is_eq(target_damage(plans(shot(8,PL.player_start(),45,0,M.Attack{1,True{},M.Fan{[10],2,False{}}})),10),130),U32.is_eq(target_damage(plans(shot(8,PL.player_start(),45,0,M.Attack{1,True{},M.Fan{[10],2,False{}}})),11),100)),"return contacts restore finite budget and split marked damage")
    expect(U32.is_eq(count(G.hit_targets(plans(shot(8,PL.player_start(),45,0,M.Attack{1,True{},M.Fan{[10],1,False{}}})),PL.player_start())),1),"return leg respects independent finite pierce budget")
    expect(U32.is_eq(ink_ticks(G.prepared_projectile(ink(59,False{}),team(run(0,100,M.empty()),[enemy(10),enemy(11)]))),0),"ink continuous capture resets below three enemies")
    expect(U32.is_eq(target_damage(ink_plans(ink(59,False{}),[enemy(10),enemy(11),enemy(12)]),10),30),"ink finishing pulse adds only thirty percent off ordinary cadence")
    expect(U32.is_eq(U32.from_nat(List.length(&2,G.HitPlan,ink_plans(ink(60,True{}),[enemy(10),enemy(11),enemy(12)]))),0),"resolved ink cannot emit another finishing pulse")
    expect(U32.is_eq(G.accepted(G.team_plan([G.PlayerView{0,run(2,1,ready_notes()),1.0,0.0,True{}}],[]),0,14,M.PrimaryKind{}),2),"held note cast allocates a multishot volley")
    expect(U32.is_eq(notes(G.settle_owner(G.PlayerView{0,run(2,1,ready_notes()),1.0,0.0,True{}},G.empty_shot_plan(),[],[])),3),"rejected cast preserves full note bank")
    expect(U32.is_eq(notes(G.settle_owner(G.PlayerView{0,run(2,1,ready_notes()),1.0,0.0,True{}},G.team_plan([G.PlayerView{0,run(2,1,ready_notes()),1.0,0.0,True{}}],[]),[],[])),0),"allocated cast consumes bank once")
    expect(Bool.and(U32.is_eq(S.damage(row(G.primary_spawn(team(run(2,1,ready_notes()),[]),PL.player_start(),14,0,0,3))),(G.weapon_damage(14,3,[],0,99,2) * 175 / 100 : U32)),U32.is_eq(S.damage(row(G.primary_spawn(team(run(2,1,ready_notes()),[]),(PL.player_start() + 1 : U32),14,0,1,3))),(G.weapon_damage(14,3,[],0,99,2) * 175 / 100 : U32))),"every admitted shot shares held-note damage boost")
    expect(echo_ok(row(G.bonus_spawn(team(run(5,100,M.empty()),[]),PL.player_start(),23,0,0,3,M.EchoEmission{M.fresh_echo(7,34,20.0,30.0,100,2,1.0,1.0,1.0,3)}))),"echo preserves captured origin and cast with half spacing and half damage")
    expect(U32.is_eq(request_count(G.mechanic_requests(0,run(3,100,ready_trail()),trails(8n,20),G.empty_owner_counts()),M.TrailKind{}),0),"eight pending trails suppress placement")
    expect(U32.is_eq(request_count(G.mechanic_requests(0,run(3,100,ready_trail()),trails(7n,20),G.empty_owner_counts()),M.TrailKind{}),1),"seventh pending trail permits exactly one placement")
    expect(Bool.not(G.retire_trail(shot(22,PL.player_start(),25,9999,M.Attack{1,True{},M.Trail{False{}}}),team(run(3,100,M.empty()),trails(8n,26)))),"first trail pulse cannot be evicted by armed marks")
    expect(F32.is_eq(orbit_phase(prepared_owner(1,M.empty(),[G.ProjectileSnapshot{shot(21,PL.player_start(),10,9999,M.ordinary())},G.ProjectileSnapshot{shot(21,(PL.player_start() + 1 : U32),10,9999,M.ordinary())}])),0.035),"multiple familiars advance one owner orbit clock")
    expect(pulse_ok(row(G.bonus_spawn(team(run(1,100,M.empty()),[]),PL.player_start(),21,0,0,3,M.PulseEmission{}))),"safe return creates only one-tick zero-damage knockback field")
    expect(U32.is_eq(G.combo_credits([combo_snapshot(PL.player_start(),True{},False{})],hits_of(G.contact_team(team(run(6,100,M.empty()),[combo_snapshot(PL.player_start(),True{},False{}),enemy(10),enemy(11)]))),0),1),"two contacts on one starter projectile earn one combo credit")
    expect(U32.is_eq(G.combo_credits([combo_snapshot(PL.player_start(),False{},False{}),combo_snapshot((PL.player_start() + 1 : U32),True{},True{})],[G.HitPlan{PL.player_start(),1,100,100.0,100.0,10.0,False{},[10]},G.HitPlan{(PL.player_start() + 1 : U32),1,100,100.0,100.0,10.0,False{},[10]}],0),0),"bonus and already credited projectiles earn no combo credit")
    expect(U32.is_eq(combo_pending(G.run_mechanics(G.view_run(G.settled_view(six_contact_team(),0)))),2),"six distinct projectile contacts retain two earned punches")
    expect(U32.is_eq(G.combo_credits(six_streaks(PL.player_start()),hits_of(six_contact_team()),1),0),"contact credits cannot cross player ownership")
    return Unit{}
