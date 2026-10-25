# Native profile is independent from browser localStorage.
# Slots: 0 gold; 1..10 meta; 11 characters; 12 stages; 13 achievements;
# 14 relics; 15 winning characters; 16 weapons; 17 evolutions; 18 enemies;
# 20..32 aggregate statistics. Terminal identity and settlement are typed fields.
# Call begin for every new run, then record exactly at a terminal observation.
import Base
import native-content-policy.bend as C

type Profile is Data: Profile{values: List<&2,U32>,lastSeed: U32,settled: Bool}
def choose(test: Bool,yes: Profile,no: Profile) -> Profile:
  match test:
    case True{}: yes
    case False{}: no
def choice(test: Bool,yes: Bool,no: Bool) -> Bool:
  match test:
    case True{}: yes
    case False{}: no
def fresh() -> Profile: Profile{[0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0],0,False{}}
def number_result(result: Maybe<&2,U32>) -> U32:
  match result:
    case Some{value}: value
    case None{}: 0
def get(profile: Profile,id: U32) -> U32:
  match profile:
    case Profile{values,_,_}: number_result(List.get(&2,U32,values,U32.to_nat(id)))
def put(profile: Profile,id: U32,value: U32) -> Profile:
  match profile:
    case Profile{values,seed,settled}: Profile{List.set(&2,U32,values,U32.to_nat(id),value),seed,settled}
def gold(profile: Profile) -> U32: get(profile,0)
def set_gold(profile: Profile,gold: U32) -> Profile:
  match profile:
    case Profile{values,seed,settled}: Profile{gold <> List.tail(&2,U32,values),seed,settled}
def credit_wallet(profile: Profile,old: U32,gained: U32) -> Profile:
  set_gold(profile,(old + gained : U32))
def rank(profile: Profile,+id: U32) -> U32: U32.min(C.meta_max(id),get(profile,(id + 1 : U32)))
def meta_go(n: Nat,+profile: Profile,+id: U32) -> U32:
  match n:
    case 0n: 0
    case 1n+p: U32.or(U32.shln(rank(profile,id),U32.to_nat((id * 3 : U32))),meta_go(p,profile,(id + 1 : U32)))
def meta(profile: Profile) -> U32: meta_go(10n,profile,0)
def bit(id: U32) -> U32: U32.shln(1,U32.to_nat((id % 32 : U32)))
def has(mask: U32,id: U32) -> Bool: U32.is_ne(U32.and(mask,bit(id)),0)
def add(+profile: Profile,+slot: U32,id: U32) -> Profile: put(profile,slot,U32.or(get(profile,slot),bit(id)))
def pop(n: Nat,+mask: U32) -> U32:
  match n:
    case 0n: 0
    case 1n+p: ((mask % 2) + pop(p,U32.shrn(mask,1n)) : U32)
def met(+profile: Profile,+category: U32,+id: U32) -> Bool:
  U32.is_ge(get(profile,C.condition_stat(category,id)),C.condition_value(category,id))
def weapon_allowed(+profile: Profile,id: U32) -> Bool:
  match id:
    case 12: has(get(profile,14),0)
    case 14: U32.is_ge(get(profile,20),100)
    case 16: has(get(profile,14),2)
    case 17: has(get(profile,14),4)
    case 18: has(get(profile,14),1)
    case 22: has(get(profile,14),3)
    case _: True{}
def allowed(+profile: Profile,+category: U32,+id: U32) -> Bool:
  match category:
    case 0: Bool.and(U32.is_lt(id,24),weapon_allowed(profile,id))
    case 2: Bool.and(U32.is_lt(id,8),has(get(profile,11),id))
    case 3: Bool.and(U32.is_lt(id,5),has(get(profile,12),id))
    case 9: Bool.and(U32.is_lt(id,4),met(profile,category,id))
    case _: True{}
def weapon_mask_go(n: Nat,+profile: Profile,+id: U32) -> U32:
  match n:
    case 0n: 0
    case 1n+p: U32.or((Bool.to_u32(weapon_allowed(profile,id)) * bit(id) : U32),weapon_mask_go(p,profile,(id + 1 : U32)))
def weapon_mask(profile: Profile) -> U32: weapon_mask_go(24n,profile,0)
def cost(+profile: Profile,+category: U32,+id: U32) -> U32:
  match category:
    case 5: (C.cost(category,id) * (4 + rank(profile,id) * 3) / 4 : U32)
    case _: C.cost(category,id)
def achievement(profile: Profile,id: U32) -> Bool: has(get(profile,13),id)
def qualifies(+profile: Profile,id: U32) -> Bool:
  match id:
    case 0: Bool.and(U32.is_ge(get(profile,20),100),True{})
    case 1: Bool.and(U32.is_ge(get(profile,20),1000),True{})
    case 2: Bool.and(U32.is_ge(get(profile,20),10000),True{})
    case 3: Bool.and(U32.is_ge(get(profile,20),50000),True{})
    case 4: Bool.and(U32.is_ge(get(profile,21),1000),True{})
    case 5: Bool.and(U32.is_ge(get(profile,21),10000),True{})
    case 6: Bool.and(U32.is_ge(get(profile,22),60),True{})
    case 7: Bool.and(U32.is_ge(get(profile,22),300),True{})
    case 8: Bool.and(U32.is_ge(get(profile,23),1),True{})
    case 9: Bool.and(U32.is_ge(get(profile,23),10),True{})
    case 10: Bool.and(U32.is_ge(get(profile,24),1),True{})
    case 11: Bool.and(U32.is_ge(get(profile,24),12),True{})
    case 12: Bool.and(U32.is_ge(get(profile,25),20),True{})
    case 13: Bool.and(U32.is_ge(get(profile,25),50),True{})
    case 14: Bool.and(U32.is_ge(get(profile,26),8),True{})
    case 15: Bool.and(U32.is_ge(get(profile,27),5),True{})
    case 16: Bool.and(U32.is_ge(get(profile,28),24),True{})
    case 17: Bool.and(U32.is_ge(get(profile,29),1),True{})
    case 18: Bool.and(U32.is_ge(get(profile,30),20),True{})
    case 19: Bool.and(U32.is_ge(get(profile,31),8),True{})
    case _: False{}
def award_go(n: Nat,+id: U32,+profile: Profile) -> Profile:
  match n:
    case 0n: profile
    case 1n+p:
      next = choose(qualifies(profile,id),add(profile,13,id),profile)
      award_go(p,(id + 1 : U32),next)
def award(profile: Profile) -> Profile: award_go(20n,0,profile)
def purchased_by(category: U32,+profile: Profile,+id: U32,+paid: Profile) -> Profile:
  match category:
    case 5: put(paid,(id + 1 : U32),(rank(profile,id) + 1 : U32))
    case 2: award(put(add(paid,11,id),26,(pop(32n,get(profile,11)) + 1 : U32)))
    case 3: award(put(add(paid,12,id),27,(pop(32n,get(profile,12)) + 1 : U32)))
    case _: profile
def purchased(+profile: Profile,+category: U32,+id: U32) -> Profile:
  purchased_by(category,profile,id,put(profile,0,(gold(profile) - cost(profile,category,id) : U32)))
def can_purchase(+profile: Profile,+category: U32,+id: U32) -> Bool:
  valid = Bool.and(U32.is_lt(id,C.count(category)),U32.is_ge(gold(profile),cost(profile,category,id)))
  eligible = choice(U32.is_eq(category,5),U32.is_lt(rank(profile,id),C.meta_max(id)),Bool.and(met(profile,category,id),Bool.not(allowed(profile,category,id))))
  Bool.and(valid,eligible)
def purchase(+profile: Profile,+category: U32,+id: U32) -> Profile:
  choose(can_purchase(profile,category,id),purchased(profile,category,id),profile)
def last_seed(profile: Profile) -> U32:
  match profile:
    case Profile{_,seed,_}: seed
def settled(profile: Profile) -> Bool:
  match profile:
    case Profile{_,_,settled}: settled
def begin(profile: Profile) -> Profile:
  match profile:
    case Profile{values,seed,_}: Profile{values,seed,False{}}

# Receipt settlement is separate from calculating awards: a duplicate ignores any recomputed payment.
def stamp(profile: Profile,seed: U32) -> Profile:
  match profile:
    case Profile{values,_,_}: Profile{values,seed,True{}}
def seen(+profile: Profile,seed: U32) -> Bool:
  Bool.and(settled(profile),U32.is_eq(last_seed(profile),seed))
def settle(+active: Bool,+seed: U32,+profile: Profile,paid: Profile) -> Profile:
  choose(active,choose(seen(profile,seed),profile,stamp(paid,seed)),profile)
