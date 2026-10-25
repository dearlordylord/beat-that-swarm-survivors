import offline-batch.bend as Solo
import native-full-run.bend as Full
import run-state.bend as RS
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
def pickup_snapshot(identity: U32,item: Pickup.Item,active: Bool) -> G.Snapshot:
  G.PickupSnapshot{Pickup.State{Space.Spatial{7200.0,7200.0,0,6.0},Pickup.Payload{item,12,active},identity}}
def pickup_fixtures() -> List<&2,G.Snapshot>:
  [pickup_snapshot(1056,Pickup.Xp{4,False{}},True{}),metric_snapshot(0,17,1),G.ProjectileSnapshot{Shot.dormant(7200.0,7200.0,512,Shot.PlayerShot{})},pickup_snapshot(1057,Pickup.Xp{9,True{}},True{}),pickup_snapshot(1058,Pickup.Xp{99,False{}},False{}),pickup_snapshot(0,Pickup.Gold{17},True{}),pickup_snapshot(2,Pickup.Chest{},True{}),pickup_snapshot(511,Pickup.Relic{0},True{})]
def identities(rows: List<&2,G.Snapshot>) -> List<&2,U32>:
  match rows:
    case []: []
    case head <> rest: G.snapshot_identity(head) <> identities(rest)
def same_ids(left: List<&2,U32>,right: List<&2,U32>) -> Bool:
  match left right:
    case Nil{} Nil{}: True{}
    case Con{a,at} Con{b,bt}: Bool.and(U32.is_eq(a,b),same_ids(at,bt))
    case _ _: False{}
def pickup_consumers_match(+rows: List<&2,G.Snapshot>) -> Bool:
  Bool.and(Bool.and(U32.is_eq(Solo.piles(rows),2),U32.is_eq(Solo.xp_sum(rows),13)),Bool.and(same_ids(identities(Full.movement_snapshots(False{},rows)),[1056,1,512,1057,1058,0,511]),same_ids(identities(Full.movement_snapshots(True{},rows)),[1056,1,512,1057,1058,0,2,511])))
def fixture_run() -> G.Run:
  G.Run{RS.Session{0,120,0,20,1,0,0,12345,0,0,0,[],0},RS.PlayerState{7200.0,7200.0,70,70,0,[],[],0,0,0,0,0,0,0,0,0}}
def report_pickup_consumers(ok: Bool) -> IO(Unit):
  match ok:
    case False{}: IO.die(Unit,1,"Typed pickup summary or chest eligibility fixture failed")
    case True{}:
      do IO<Unit>:
        IO.print("PASS typed pickup summary: two active piles, 13 XP; inactive/non-XP excluded; planner chest readiness false/true preserves order and other actor snapshots")
        started : Nat <- IO.now()
        Solo.report(0,12345,0,0,started,120,fixture_run(),pickup_fixtures())
def main() -> IO(Unit):
  do IO<Unit>:
    report(Bool.and(all_match(fixtures()),first_timed_boss_matches(EnemySpawn.boss_variant(False{},7200,0))))
    report_pickup_consumers(pickup_consumers_match(pickup_fixtures()))
