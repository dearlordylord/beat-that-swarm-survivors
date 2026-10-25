import Base
import native-economy.bend as P

type Receipt is Data: Receipt{phase: U32,tick: U32,level: U32,kills: U32,gained: U32,character: U32,weapons: List<&2,U32>,seed: U32,stage: U32,revivals: U32,bosses: U32,enemies: List<&2,U32>,relic: U32}
def weapon_collection(levels: List<&2,U32>,+id: U32,+profile: P.Profile) -> P.Profile:
  match levels:
    case Nil{}: profile
    case Con{+level,rest}:
      +used = P.choose(U32.is_gt(level,0),P.add(profile,16,id),profile)
      +evolved = P.choose(U32.is_ge(level,9),P.add(used,17,id),used)
      weapon_collection(rest,(id + 1 : U32),evolved)
def enemy_collection(kinds: List<&2,U32>,+profile: P.Profile) -> P.Profile:
  match kinds:
    case Nil{}: profile
    case Con{id,rest}: enemy_collection(rest,P.add(profile,18,id))
def evolved_count(levels: List<&2,U32>) -> U32:
  match levels:
    case Nil{}: 0
    case Con{level,rest}: (Bool.to_u32(U32.is_ge(level,9)) + evolved_count(rest) : U32)
def record_stats(+profile: P.Profile,run: Receipt) -> P.Profile:
  match run:
    case Receipt{phase,tick,level,kills,+gained,character,+weapons,seed,stage,revivals,bosses,enemies,relic}:
      +p1 = P.put(profile,20,(P.get(profile,20) + kills : U32))
      +p2 = P.put(p1,21,(P.get(profile,21) + gained : U32))
      +p3 = P.put(p2,22,U32.max(P.get(profile,22),(tick / 60 : U32)))
      +p4 = P.put(p3,25,U32.max(P.get(profile,25),level))
      +p5 = P.put(p4,29,(P.get(profile,29) + revivals : U32))
      +p6 = P.put(p5,30,(P.get(profile,30) + bosses : U32))
      +p7 = P.choose(U32.is_eq(phase,4),P.add(P.put(p6,23,(P.get(profile,23) + 1 : U32)),15,character),p6)
      +p8 = P.choose(U32.is_eq(relic,1),P.add(p7,14,stage),p7)
      +p9 = weapon_collection(weapons,0,p8)
      +p10 = enemy_collection(enemies,p9)
      +p11 = P.put(p10,24,(P.get(profile,24) + evolved_count(weapons) : U32))
      +p12 = P.put(p11,28,P.pop(32n,P.get(p11,16)))
      +p13 = P.put(p12,31,P.pop(32n,P.get(p12,15)))
      +p14 = P.put(p13,32,P.pop(32n,P.get(p13,14)))
      p14
def gained(run: Receipt) -> U32:
  match run:
    case Receipt{_,_,_,_,gained,_,_,_,_,_,_,_,_}: gained
def payment(+profile: P.Profile,+run: Receipt) -> P.Profile:
  P.credit_wallet(P.award(record_stats(profile,run)),P.gold(profile),gained(run))
def run_seed(run: Receipt) -> U32:
  match run:
    case Receipt{_,_,_,_,_,_,_,seed,_,_,_,_,_}: seed
def terminal(run: Receipt) -> Bool:
  match run:
    case Receipt{+phase,_,_,_,_,_,_,_,_,_,_,_,_}: Bool.or(U32.is_eq(phase,3),U32.is_eq(phase,4))
def record(+profile: P.Profile,+run: Receipt) -> P.Profile: P.settle(terminal(run),run_seed(run),profile,payment(profile,run))
