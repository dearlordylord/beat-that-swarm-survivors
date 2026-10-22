import Base
import native-content.bend as C
import native-profile.bend as P
import game.bend as G

def sample(seed: U32) -> G.Run:
  G.Run{4,36000,1800.0,1800.0,50,100,0,12,30,1200,2500,0,[9,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],0,seed,0,0,0,1,5,0,3,3,3,0,0,[0,1,20],1}
def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def tests() -> IO(Unit):
  +fresh = P.fresh()
  +reward = P.record(fresh,sample(500))
  +bought = P.purchase(reward,5,0)
  +character = P.purchase(reward,2,1)
  +stage = P.purchase(reward,3,1)
  +capped = P.put(reward,1,5)
  do IO<Unit>:
    expect(U32.is_eq(P.gold(fresh),0),"fresh gold")
    expect(P.allowed(fresh,2,0),"starter unlocked")
    expect(Bool.not(P.allowed(fresh,2,1)),"paid character locked")
    expect(U32.is_eq(P.meta(fresh),0),"fresh meta")
    expect(String.eq(P.encode(P.purchase(fresh,5,0)),P.encode(fresh)),"unaffordable purchase unchanged")
    expect(U32.is_eq(P.gold(reward),2500),"terminal gold reward")
    expect(U32.is_eq(P.gold(P.record(reward,sample(500))),2500),"duplicate terminal reward ignored")
    expect(U32.is_eq(P.gold(P.record(P.begin(reward),sample(500))),5000),"new run may share deterministic seed")
    expect(U32.is_eq(P.rank(bought,0),1),"upgrade rank increments")
    expect(U32.is_eq(P.gold(bought),2350),"upgrade exact cost")
    expect(U32.is_eq(P.cost(bought,5,0),262),"next upgrade cost")
    expect(String.eq(P.encode(P.purchase(capped,5,0)),P.encode(capped)),"max rank purchase refused")
    expect(P.allowed(character,2,1),"character condition and purchase")
    expect(U32.is_eq(P.gold(character),2250),"character cost")
    expect(P.allowed(stage,3,1),"stage condition and purchase")
    expect(P.allowed(reward,9,2),"endless unlocked by victory")
    expect(P.allowed(reward,0,12),"stage relic unlocks weapon")
    expect(P.achievement(reward,0),"kill achievement")
    expect(P.has(P.get(reward,16),0),"weapon collection")
    expect(P.has(P.get(reward,17),0),"evolution collection")
    expect(P.has(P.get(reward,18),20),"boss collection")
    expect(String.eq(P.encode(P.decode(P.encode(bought))),P.encode(bought)),"profile roundtrip")
    expect(String.eq(P.encode(P.decode("bad save")),P.encode(fresh)),"invalid save resets")
    expect(String.eq(P.encode(P.decode("NIGHTFALL1\n0\n")),P.encode(fresh)),"truncated save resets")
    expect(U32.is_eq(C.count(0),24),"all weapon names ported")
    expect(U32.is_eq(C.count(6),31),"all enemy names ported")
    P.save(bought)
    +loaded : P.Profile <- P.load()
    expect(String.eq(P.encode(loaded),P.encode(bought)),"native file persistence")
    IO.print("NATIVE PROFILE PASS")
def main() -> IO(Unit): tests()
