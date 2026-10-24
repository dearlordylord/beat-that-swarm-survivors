import Base
import game.bend as G
import spawn-policy.bend as S

def run() -> G.Run:
  G.Run{0,1,1800.0,1800.0,100,100,0,100,1,0,0,0,[],[],0,12345,0,0,0,0,0,0,3,3,3,0,0,[],0}
def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def born(result: G.EntityRow) -> Bool:
  match result:
    case G.EntityRow{G.Row{G.Body{x,y,0,_,hp,_,0,17,radius},0,0,0,0,0,0,0},G.Motion{0.0,0.0,0,0,[],0,0,_,_}}: Bool.and(U32.is_lt(0,hp),S.admissible(x,y,1800.0,1800.0,radius))
    case _: False{}
def apply(slow: U32,burn: U32,hits: List<&2,G.HitPlan>) -> G.EntityRow:
  G.normal_regular_entity(G.Body{1800.0,1800.0,8,0,0,0,17,17,0.0},G.Motion{0.0,0.0,0,0,[],slow,burn,0,0},G.Args{run(),[],0.0,0.0,[],hits})
def main() -> IO(Unit):
  do IO<Unit>:
    expect(born(apply(90,0,[])),"slow from dead incarnation cannot move respawn inside screen")
    expect(born(apply(65626,120,[])),"freeze and burn cannot teleport new incarnation to corpse")
    expect(born(apply(0,0,[G.HitPlan{(G.pool_actor_start() + 8 : U32),10,24,1800.0,1800.0,120.0,True{},[]}])),"tower collision at old corpse cannot hit newborn outside screen")
