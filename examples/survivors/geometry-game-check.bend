import run-state.bend as RS
import Base
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
def reachable(body:G.Body) -> Bool:
  match body:
    case G.Body{+x,+y,+kind,_,_,_,_,_,_}:
      G.pickup_admission(x,y,F32.clamp(x,A.player_min(),A.player_max()),F32.clamp(y,A.player_min(),A.player_max()),G.pickup_radius([],0,0,0),0,kind)
def death_reachable(row:G.Row) -> Bool:
  match row:
    case G.Row{body,_,_,_,_,_,killed,_}: Bool.and(U32.is_eq(killed,1),reachable(body))
def batch_reachable(batch:G.XpBatch) -> Bool:
  match batch:
    case G.XpBatch{_,+body,index,_}: reachable(G.xp_batch_body(body,index,PL.xp_start(),0))
def run() -> G.Run:
  G.Run{RS.Session{0,1,0,20,1,0,0,12345,0,0,0,[],0},RS.PlayerState{1000.0,1000.0,100,100,0,[],[],0,0,0,0,3,3,3,0,0}}
def enemy(x:F32,seed:U32) -> G.Snapshot:
  G.Snapshot{G.Body{x,1000.0,0,17,100,100,0,seed,6.0},G.empty_motion()}
def shot() -> G.Snapshot:
  G.Snapshot{G.Body{1000.0,1000.0,1,1,10,10,0,PL.player_start(),1.0},G.Motion{100.0,0.0,10,1,[],0,0,0,0}}
def team(rows:List<&2,G.Snapshot>) -> G.Team:
  G.Team{[G.PlayerView{0,run(),0.0,0.0}],G.Args{run(),[G.Body{1080.0,1000.0,0,17,100,100,0,2,6.0},G.Body{1040.0,1000.0,0,17,100,100,0,1,6.0}],0.0,0.0,rows,[]},G.empty_shot_plan(),BI.Empty{}}
def selected(team:G.Team) -> List<&2,U32>:
  match team:
    case G.Team{_,G.Args{_,_,_,_,_,hits},_,_}: G.hit_targets(hits,PL.player_start())
def first_target(rows:List<&2,U32>) -> Bool:
  match rows:
    case head <> []: U32.is_eq(head,1)
    case _: False{}
def main() -> IO(Unit):
  do IO<Unit>:
    expect(death_reachable(G.enemy_result(0,42.0,42.0,17,1,0,1,6.0,A.player_min(),A.player_min())),"edge death loot has a legal physical pickup position")
    expect(batch_reachable(G.xp_batch_drop(7,42.0,42.0,1,G.XpBatch{[PL.xp_start()],G.initial_body(PL.xp_start()),BI.Empty{},0})),"new XP allocation stays physically reachable")
    expect(reachable(G.xp_overflow_body(True{},G.Body{42.0,42.0,2,0,7,1,0,PL.xp_start(),6.0},1)),"existing overflow accumulator stays physically reachable")
    expect(first_target(selected(G.contact_team(team([shot(),enemy(1080.0,2),enemy(1040.0,1)])))),"fast projectile contacts the first crossed enemy")
    expect(first_target(selected(G.contact_team(team([enemy(1040.0,1),shot(),enemy(1080.0,2)])))),"contact priority survives ECS row permutation")
    IO.print("NATIVE GAME GEOMETRY PASS")
