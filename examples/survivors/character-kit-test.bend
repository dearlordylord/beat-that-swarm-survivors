import Base
import character-policy.bend as C
import game.bend as G

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def main() -> IO(Unit):
  do IO<Unit>:
    expect(Bool.and(U32.is_eq(G.starter(0),20),Bool.and(U32.is_eq(G.starter(1),21),Bool.and(U32.is_eq(G.starter(2),14),Bool.and(U32.is_eq(G.starter(3),22),Bool.and(U32.is_eq(G.starter(4),8),Bool.and(U32.is_eq(G.starter(5),23),U32.is_eq(G.starter(6),1))))))),"seven distinct thematic starters reach combat")
    expect(Bool.and(U32.is_eq(C.normalize(7),0),U32.is_eq(G.starter(7),20)),"retired character falls back to RM")
    expect(F32.is_eq(G.pickup_radius([],0,99,0),36.0),"RM has fifty percent wider pickup")
    expect(Bool.and(U32.is_eq(C.regeneration(1),1),U32.is_eq(C.regeneration(2),0)),"only Jin has innate regeneration")
    expect(U32.is_eq(G.weapon_damage(0,1,[],0,99,2),9),"SUGA receives twenty percent might")
    expect(F32.is_eq(G.speed_bonus([],0,99,3),1.15),"j-hope moves fifteen percent faster")
    expect(Bool.and(U32.is_eq(G.player_damage(1,0,[],0,99,4),5),U32.is_eq(G.player_damage(1,0,[],0,99,0),6)),"Jimin gains one armor")
    expect(U32.is_eq(G.cooldown_for(0,[],0,99,5),36),"V reduces attack cooldown by ten percent")
    expect(Bool.and(U32.is_eq(G.character_health(6),125),U32.is_eq(C.might_percent(6),10)),"Jung Kook has strength and endurance")
    expect(Bool.and(U32.is_eq(U32.and(G.starter_unlocks(0,3),4194304),4194304),U32.is_eq(U32.and(G.starter_unlocks(0,2),16384),16384)),"personal starter stays upgradeable before global weapon discovery")
    return Unit{}
