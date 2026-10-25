import enemy-spawn.bend as EnemySpawn
import enemy-combat.bend as Enemy
import enemy-spatial.bend as Space
# Execute the runner's actual counter on typed actor snapshots, natively.
import enemy-effects.bend as Effect
import projectile-state.bend as Shot
import pickup-state.bend as Pickup
import Base
import game-components.bend as Components
import game.bend as G
import offline-coop-batch.bend as Batch

type MetricCase is Data: MetricCase{kind:U32,variant:U32,hp:U32,ordinary:U32,boss:U32}
def fixtures() -> List<&2,MetricCase>:
  [MetricCase{0,0,1,1,0},MetricCase{0,19,1,1,0},MetricCase{0,20,1,0,1},MetricCase{0,21,1,0,1},MetricCase{0,29,1,0,1},MetricCase{0,30,1,0,1},MetricCase{0,31,1,1,0},MetricCase{0,4294967295,1,1,0},MetricCase{0,0,0,0,0},MetricCase{0,19,0,0,0},MetricCase{0,20,0,0,0},MetricCase{0,21,0,0,0},MetricCase{0,29,0,0,0},MetricCase{0,30,0,0,0},MetricCase{1,21,1,0,0},MetricCase{2,21,1,0,0},MetricCase{7,21,1,0,0},MetricCase{8,21,1,0,0}]
def pair_matches(expectedOrdinary:U32,expectedBoss:U32,pair:U32 & U32) -> Bool:
  (ordinary,boss) = pair
  Bool.and(U32.is_eq(ordinary,expectedOrdinary),U32.is_eq(boss,expectedBoss))
def metric_snapshot(kind: U32,variant: U32,+hp: U32) -> G.Snapshot:
  match kind:
    case 0: G.EnemySnapshot{Enemy.State{Space.Spatial{0.0,0.0,0,1.0},variant,1,Components.Vitals{hp,hp},Components.Status{Effect.Slow{0,False{}},Effect.Burn{0,None{}}}}}
    case 2: G.PickupSnapshot{Pickup.State{Space.Spatial{0.0,0.0,0,1.0},Pickup.Payload{Pickup.Xp{hp,False{}},0,True{}},1}}
    case 8: G.EnemySnapshot{Enemy.State{Space.Spatial{0.0,0.0,0,1.0},variant,1,Components.Vitals{0,hp},Components.Status{Effect.Slow{0,False{}},Effect.Burn{0,None{}}}}}
    case 7: G.ProjectileSnapshot{Shot.dormant(0.0,0.0,1,Shot.HostileShot{})}
    case _: G.ProjectileSnapshot{Shot.dormant(0.0,0.0,1,Shot.PlayerShot{})}
def case_matches(value:MetricCase) -> Bool:
  match value:
    case MetricCase{kind,variant,+hp,ordinary,boss}: pair_matches(ordinary,boss,Batch.population_go([metric_snapshot(kind,variant,hp)],0,0))
def all_match(rows:List<&2,MetricCase>) -> Bool:
  match rows:
    case []: True{}
    case row <> tail: Bool.and(case_matches(row),all_match(tail))
def first_timed_boss_matches(+variant:U32) -> Bool:
  Bool.and(U32.is_eq(variant,21),pair_matches(0,1,Batch.population_go([metric_snapshot(0,variant,10)],0,0)))
def report(ok:Bool) -> IO(Unit):
  match ok:
    case False{}: IO.die(Unit,1,"Native co-op population counter fixture failed")
    case True{}: IO.print("{\"status\":\"PASS\",\"counterCases\":18,\"firstTimedBossVariant\":21,\"scope\":\"actual native runner population counter, not whole-game balance\"}")
def main() -> IO(Unit):
  report(Bool.and(all_match(fixtures()),first_timed_boss_matches(EnemySpawn.boss_variant(False{},7200,0))))
