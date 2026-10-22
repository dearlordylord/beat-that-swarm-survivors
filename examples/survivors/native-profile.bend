# Native profile is independent from browser localStorage.
# Slots: 0 gold; 1..10 meta; 11 characters; 12 stages; 13 achievements;
# 14 relics; 15 winning characters; 16 weapons; 17 evolutions; 18 enemies;
# 20..32 aggregate statistics; 33 last terminal seed; 34 record guard.
# Call begin for every new run, then record exactly at a terminal observation.
import Base
import game.bend as G
import native-content.bend as C

type Profile is Data: Profile{values: List<&2,U32>}
def choose(test: Bool,yes: Profile,no: Profile) -> Profile:
  match test:
    case True{}: yes
    case False{}: no
def choice(test: Bool,yes: Bool,no: Bool) -> Bool:
  match test:
    case True{}: yes
    case False{}: no
def fresh() -> Profile: Profile{[0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}
def get(profile: Profile,id: U32) -> U32:
  match profile:
    case Profile{values}: G.at(values,id)
def put(profile: Profile,id: U32,value: U32) -> Profile:
  match profile:
    case Profile{values}: Profile{G.set_at(values,id,value)}
def gold(profile: Profile) -> U32: get(profile,0)
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
def purchase(+profile: Profile,+category: U32,+id: U32) -> Profile:
  valid = Bool.and(U32.is_lt(id,C.count(category)),U32.is_ge(gold(profile),cost(profile,category,id)))
  eligible = choice(U32.is_eq(category,5),U32.is_lt(rank(profile,id),C.meta_max(id)),Bool.and(met(profile,category,id),Bool.not(allowed(profile,category,id))))
  choose(Bool.and(valid,eligible),purchased(profile,category,id),profile)
def weapon_collection(levels: List<&2,U32>,+id: U32,+profile: Profile) -> Profile:
  match levels:
    case Nil{}: profile
    case Con{+level,rest}:
      +used = choose(U32.is_gt(level,0),add(profile,16,id),profile)
      +evolved = choose(U32.is_ge(level,9),add(used,17,id),used)
      weapon_collection(rest,(id + 1 : U32),evolved)
def enemy_collection(kinds: List<&2,U32>,+profile: Profile) -> Profile:
  match kinds:
    case Nil{}: profile
    case Con{id,rest}: enemy_collection(rest,add(profile,18,id))
def evolved_count(levels: List<&2,U32>) -> U32:
  match levels:
    case Nil{}: 0
    case Con{level,rest}: (Bool.to_u32(U32.is_ge(level,9)) + evolved_count(rest) : U32)
def record_raw(+profile: Profile,run: G.Run) -> Profile:
  match run:
    case G.Run{phase,tick,_,_,_,_,_,_,level,kills,+gained,character,+weapons,_,_,seed,stage,_,_,revivals,bosses,_,_,_,_,_,_,enemies,relic}:
      +p0 = put(profile,0,(gold(profile) + gained : U32))
      +p1 = put(p0,20,(get(profile,20) + kills : U32))
      +p2 = put(p1,21,(get(profile,21) + gained : U32))
      +p3 = put(p2,22,U32.max(get(profile,22),(tick / 60 : U32)))
      +p4 = put(p3,25,U32.max(get(profile,25),level))
      +p5 = put(p4,29,(get(profile,29) + revivals : U32))
      +p6 = put(p5,30,(get(profile,30) + bosses : U32))
      +p7 = choose(U32.is_eq(phase,4),add(put(p6,23,(get(profile,23) + 1 : U32)),15,character),p6)
      +p8 = choose(U32.is_eq(relic,1),add(p7,14,stage),p7)
      +p9 = weapon_collection(weapons,0,p8)
      +p10 = enemy_collection(enemies,p9)
      +p11 = put(p10,24,(get(profile,24) + evolved_count(weapons) : U32))
      +p12 = put(p11,28,pop(32n,get(p11,16)))
      +p13 = put(p12,31,pop(32n,get(p12,15)))
      +p14 = put(p13,32,pop(32n,get(p13,14)))
      put(p14,33,seed)
def record_once(+profile: Profile,+run: G.Run,seed: U32) -> Profile:
  choose(Bool.and(U32.is_eq(get(profile,34),1),U32.is_eq(get(profile,33),seed)),profile,award(put(record_raw(profile,run),34,1)))
def run_seed(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,seed,_,_,_,_,_,_,_,_,_,_,_,_,_}: seed
def begin(profile: Profile) -> Profile: put(profile,34,0)
def terminal(run: G.Run) -> Bool:
  match run:
    case G.Run{+phase,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: Bool.or(U32.is_eq(phase,3),U32.is_eq(phase,4))
def record(+profile: Profile,+run: G.Run) -> Profile: choose(terminal(run),record_once(profile,run,run_seed(run)),profile)
def encode_values(values: List<&2,U32>) -> String:
  match values:
    case Nil{}: ""
    case Con{value,rest}: U32.show(value) ++ "\n" ++ encode_values(rest)
def encode(profile: Profile) -> String:
  match profile:
    case Profile{values}: "NIGHTFALL1\n" ++ encode_values(values)
def number_result(result: Maybe<&2,U32>) -> U32:
  match result:
    case Some{value}: value
    case None{}: 0
def read_number(text: String) -> U32: number_result(U32.read(text))
def decode_values(n: Nat,rows: List<&2,String>) -> List<&2,U32>:
  match n rows:
    case 0n _: []
    case 1n+p Nil{}: 0 <> decode_values(p,[])
    case 1n+p Con{head,tail}: read_number(head) <> decode_values(p,tail)
def decode_lines(rows: List<&2,String>) -> Profile:
  match rows:
    case Nil{}: fresh()
    case Con{head,tail}:
      choose(String.eq(head,"NIGHTFALL1"),Profile{decode_values(64n,tail)},fresh())
def valid_number(result: Maybe<&2,U32>) -> Bool:
  match result:
    case None{}: False{}
    case Some{_}: True{}
def valid_rows(n: Nat,rows: List<&2,String>) -> Bool:
  match n rows:
    case 0n Nil{}: True{}
    case 0n Con{head,Nil{}}: String.eq(head,"")
    case 0n _: False{}
    case 1n+p Nil{}: False{}
    case 1n+p Con{head,tail}: Bool.and(valid_number(U32.read(head)),valid_rows(p,tail))
def valid_save(rows: List<&2,String>) -> Bool:
  match rows:
    case Nil{}: False{}
    case Con{head,tail}: Bool.and(String.eq(head,"NIGHTFALL1"),valid_rows(64n,tail))
def normalize_ranks(n: Nat,+id: U32,+profile: Profile) -> Profile:
  match n:
    case 0n: profile
    case 1n+p: normalize_ranks(p,(id + 1 : U32),put(profile,(id + 1 : U32),rank(profile,id)))
def normalize(+profile: Profile) -> Profile:
  +p0 = put(profile,11,U32.or(1,U32.and(get(profile,11),255)))
  +p1 = put(p0,12,U32.or(1,U32.and(get(p0,12),31)))
  normalize_ranks(10n,0,p1)
def decode_rows(+rows: List<&2,String>) -> Profile:
  choose(valid_save(rows),normalize(decode_lines(rows)),fresh())
def decode(text: String) -> Profile: decode_rows(String.lines(text))
def loaded_text(result: Result<&1,&1,U32 & String,String>) -> Profile:
  match result:
    case Fail{_}: fresh()
    case Done{text}: decode(text)
def loaded_read(read: File & Result<&1,&1,U32 & String,String>) -> IO(Profile):
  match read:
    case (file,result):
      do IO<Profile>:
        File.close(file)
        return loaded_text(result)
def loaded(opened: Result<&1,&1,U32 & String,File>) -> IO(Profile):
  match opened:
    case Fail{_}: IO.pure(Profile,fresh())
    case Done{file}:
      do IO<Profile>:
        read : File & Result<&1,&1,U32 & String,String> <- File.read(file,8192)
        loaded_read(read)
def load() -> IO(Profile):
  do IO<Profile>:
    opened : Result<&1,&1,U32 & String,File> <- File.open("nightfall-profile.txt","r")
    loaded(opened)
def moved(result: Result<&1,&1,U32 & String,U32 & (String & String)>) -> IO(Unit):
  match result:
    case Fail{_}: IO.print_err("Could not save native profile: replacing file failed.")
    case Done{(status,(_,error))}:
      IO.print_err(error ++ U32.show(status))
def moved_status(result: Result<&1,&1,U32 & String,U32 & (String & String)>) -> IO(Unit):
  match result:
    case Done{(0,_)}: IO.pure(Unit,Unit{})
    case result: moved(result)
def saved_result(result: Result<&1,&1,U32 & String,Unit>) -> IO(Unit):
  match result:
    case Fail{_}: IO.print_err("Could not save native profile: writing file failed.")
    case Done{_}:
      do IO<Unit>:
        result : Result<&1,&1,U32 & String,U32 & (String & String)> <- Process.run("/bin/mv",["-f","nightfall-profile.tmp","nightfall-profile.txt"],"",4096,2000)
        moved_status(result)
def saved_write(written: File & Result<&1,&1,U32 & String,Unit>) -> IO(Unit):
  match written:
    case (file,result):
      do IO<Unit>:
        File.close(file)
        saved_result(result)
def saved(opened: Result<&1,&1,U32 & String,File>,profile: Profile) -> IO(Unit):
  match opened:
    case Fail{_}: IO.print_err("Could not save native profile: opening file failed.")
    case Done{file}:
      do IO<Unit>:
        written : File & Result<&1,&1,U32 & String,Unit> <- File.write(file,encode(profile))
        saved_write(written)
def save(profile: Profile) -> IO(Unit):
  do IO<Unit>:
    opened : Result<&1,&1,U32 & String,File> <- File.open("nightfall-profile.tmp","w")
    saved(opened,profile)
