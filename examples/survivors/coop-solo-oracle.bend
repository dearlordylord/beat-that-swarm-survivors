import Base
import game.bend as G
import projectile-pool.bend as SP
import pools.bend as PL
import bendvy-ecs-core@0.1.0.1/transaction.bend as T
import bendvy-ecs-core@0.1.0.1/compose.bend as Q

# Test-only copy of the pre-coop query schedule. Production solo and coop use
# Game.execute / Game.team_execute; this scalar schedule is an independent
# behavioral oracle for the migration, never a runtime option.
def combat_done(+args: G.Args,+projectiles: List<&2,G.EntityRow>,result: Q.Executed<G.World(),Q.Error<G.Error>,G.EntityRow>) -> Q.Executed<G.World(),Q.Error<G.Error>,G.EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},+rows}: G.xp_lifecycle(projectiles,G.xp_route_args(rows,args),world)
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
def movement_done(+args: G.Args,+projectiles: List<&2,G.EntityRow>,result: Q.Executed<G.World(),Q.Error<G.Error>,Unit>) -> Q.Executed<G.World(),Q.Error<G.Error>,G.EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},_}: combat_done(args,projectiles,G.candidate_query(~G.PoolOpsType,~G.ArgsCarrier,~G.EntityRow,~G.plan(),~G.carried_body_system,False{},G.ArgsHeld{args},world))
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
def projectile_done(+args: G.Args,result: Q.Executed<G.World(),Q.Error<G.Error>,G.EntityRow>) -> Q.Executed<G.World(),Q.Error<G.Error>,G.EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},rows}: movement_done(args,rows,G.execute_movement(world,args))
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
def execute_scalar(world: G.World(),+args: G.Args) -> Q.Executed<G.World(),Q.Error<G.Error>,G.EntityRow>:
  projectile_done(args,G.candidate_query(~G.ProjectileOpsType,~G.ArgsCarrier,~G.EntityRow,~G.projectile_plan(),~G.carried_projectile_system,True{},G.ArgsShots{args,G.prepare_shot_plan(args)},world))
def step_ready(ready: Bool,state: G.State,+dx: F32,+dy: F32) -> G.Packet:
  match ready state:
    case True{} G.State{world,+run,bodies,_,snapshots,_}: G.executed_with(~G.quiet_packet,G.moved_run(G.PlayerView{0,G.with_tick(run,(G.run_tick(run) + 1 : U32)),dx,dy}),execute_scalar(world,G.combat_args(G.with_tick(run,(G.run_tick(run) + 1 : U32)),bodies,dx,dy,snapshots)))
    case False{} state: G.quiet_packet(state)
def step_scalar(state: G.State,+dx: F32,+dy: F32) -> G.Packet:
  match state:
    case G.State{world,+run,bodies,offers,snapshots,+pending}: G.attach_pending_with(~G.quiet_packet,step_ready(U32.is_eq(G.run_phase(run),0),G.State{world,run,bodies,offers,snapshots,[]},dx,dy),pending)

# Independent pre-optimization request enumeration: every owner visits all eight
# logical spread slots, including the reactive unowned Arcana 4 exception.
def requests_scalar(fuel: Nat,+owner: U32,+run: G.Run,+locks: List<&2,U32>) -> List<&2,SP.Request>:
  match fuel:
    case 0n: []
    case 1n+rest: G.request_slots(8n,owner,0,run,G.at(locks,owner),requests_scalar(rest,((owner + 1) % PL.owner_count() : U32),run,locks))
