import Base
import arena.bend as A
import encounters.bend as E
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
def bounded_body(body: G.Body) -> Bool:
  match body:
    case G.Body{+x,+y,_,_,_,_,_,_,+radius}: Bool.and(Bool.and(F32.is_le(A.envelope(radius),x),F32.is_le(x,(A.size() - A.envelope(radius) : F32))),Bool.and(F32.is_le(A.envelope(radius),y),F32.is_le(y,(A.size() - A.envelope(radius) : F32))))
def bounded_row(row: G.Row) -> Bool:
  match row:
    case G.Row{body,_,_,_,_,_,_,_}: bounded_body(body)
def main() -> IO(Unit):
  do IO<Unit>:
    expect(born(apply(90,0,[])),"slow from dead incarnation cannot move respawn inside screen")
    expect(born(apply(65626,120,[])),"freeze and burn cannot teleport new incarnation to corpse")
    expect(born(apply(0,0,[G.HitPlan{G.pool_player_start(),10,24,1800.0,1800.0,120.0,True{},[]}])),"stale area collision at old corpse cannot hit newborn outside screen")
    expect(bounded_body(G.moved_intent(G.Body{14240.0,160.0,0,25,100,100,240,0,42.0},E.Intent{50000.0,(0.0 - 50000.0 : F32),False{}},1.0)),"large charging enemy stays fully inside arena")
    expect(bounded_row(G.enemy_result(100,(0.0 - 50000.0 : F32),50000.0,25,100,240,0,42.0,A.center(),A.center())),"combat displacement keeps full large-enemy footprint inside arena")
