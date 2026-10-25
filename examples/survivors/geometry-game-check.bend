import pickup-state.bend as Pickup
import pickup-xp-pool.bend as Pool
import pickup-from-death.bend as DeathPickup
import enemy-combat.bend as Enemy
import enemy-spatial.bend as Space
import projectile-state.bend as Shot
import run-state.bend as RS
import enemy-effects.bend as Effect
import Base
import game-components.bend as Components
import game.bend as G
import arena.bend as A
import body-index.bend as BI
import pools.bend as PL

# Native integration: exercise the actual death, XP overflow and frozen combat
# paths. Numerical checks supplement the encoded/structural kernel laws.
def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def reachable(state: Pickup.State) -> Bool:
  match state:
    case Pickup.State{Space.Spatial{+x,+y,_,_},_,_}: F32.is_le(G.distance2(x,y,F32.clamp(x,A.player_min(),A.player_max()),F32.clamp(y,A.player_min(),A.player_max())),(G.pickup_radius([],0,0,0) * G.pickup_radius([],0,0,0) : F32))
def death_pickup(state: Maybe<&2,Pickup.State>) -> Bool:
  match state:
    case Some{state}: reachable(state)
    case None{}: False{}
def batch_reachable(states: List<&2,Pickup.State>) -> Bool:
  match states:
    case head <> _: reachable(head)
    case []: False{}
def run() -> G.Run:
  G.Run{RS.Session{0,1,0,20,1,0,0,12345,0,0,0,[],0},RS.PlayerState{1000.0,1000.0,100,100,0,[],[],0,0,0,0,3,3,3,0,0}}
def enemy(x:F32,seed:U32) -> G.Snapshot:
  G.EnemySnapshot{Enemy.State{Space.Spatial{x,1000.0,0,6.0},17,seed,Components.Vitals{100,100},Components.Status{Effect.Slow{0,False{}},Effect.Burn{0,None{}}}}}
def shot() -> G.Snapshot:
  G.ProjectileSnapshot{Shot.State{Space.Spatial{1000.0,1000.0,0,1.0},PL.player_start(),Shot.PlayerShot{},Components.ShotPayload{1,10,True{}},Components.Trajectory{100.0,0.0,10,1,[],0,0,Some{0}}}}
def team(rows:List<&2,G.Snapshot>) -> G.Team:
  G.Team{[G.PlayerView{0,run(),0.0,0.0,True{}}],G.Args{run(),G.enemy_targets([enemy(1080.0,2),enemy(1040.0,1)]),0.0,0.0,rows,[]},G.empty_shot_plan(),BI.Empty{}}
def selected(team:G.Team) -> List<&2,U32>:
  match team:
    case G.Team{_,G.Args{_,_,_,_,_,hits},_,_}: G.hit_targets(hits,PL.player_start())
def first_target(rows:List<&2,U32>) -> Bool:
  match rows:
    case head <> []: U32.is_eq(head,1)
    case _: False{}
def main() -> IO(Unit):
  do IO<Unit>:
    expect(death_pickup(DeathPickup.create(Enemy.DeathReward{Enemy.GoldDrop{},1,42.0,42.0,17,1,None{}},1)),"edge death loot has a legal physical pickup position")
    expect(batch_reachable(Pool.route([Pool.Drop{7,42.0,42.0}],[Pickup.State{Space.Spatial{0.0,0.0,0,0.0},Pickup.Payload{Pickup.Xp{0,False{}},0,False{}},PL.xp_start()}],1,A.player_min(),A.player_min())),"new XP allocation stays physically reachable")
    expect(reachable(Pool.merge_overflow(True{},Pickup.State{Space.Spatial{42.0,42.0,0,6.0},Pickup.Payload{Pickup.Xp{7,False{}},1,True{}},PL.xp_start()},1)),"existing overflow accumulator stays physically reachable")
    expect(first_target(selected(G.contact_team(team([shot(),enemy(1080.0,2),enemy(1040.0,1)])))),"fast projectile contacts the first crossed enemy")
    expect(first_target(selected(G.contact_team(team([enemy(1040.0,1),shot(),enemy(1080.0,2)])))),"contact priority survives ECS row permutation")
    IO.print("NATIVE GAME GEOMETRY PASS")
