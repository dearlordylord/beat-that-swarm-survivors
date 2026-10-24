# All browser progression decisions live here. The host only transports values and stores JSON.
# Exact non-negative rational arithmetic avoids F32 precision loss in accumulated gold and kills.
import Base

type Value is Data:
  JNull{}
  JBoolean{value: Bool}
  JNumber{numerator: Nat,denominator: Nat,negative: Bool}
  JText{value: String}
  JDecimal{value: String,numerator: List<&2,Nat>,denominator: List<&2,Nat>,negative: Bool}
  JRatio{numerator: List<&2,Nat>,denominator: List<&2,Nat>}
  JSequence{values: List<&2,Value>}
  JObject{keys: List<&2,String>,values: List<&2,Value>}

type DivisionStep is Data: DivisionStep{remainder: List<&2,Nat>,digit: Nat}
def step_remainder(+step: DivisionStep) -> List<&2,Nat>:
  match step:
    case DivisionStep{remainder,_}: remainder
def step_digit(+step: DivisionStep) -> Nat:
  match step:
    case DivisionStep{_,digit}: digit

# Small decimal limbs keep exact arithmetic within Bend's immediate Nat bound.
def big_trim_zero(+rows: List<&2,Nat>) -> List<&2,Nat>:
  match rows:
    case Con{0n,rest}: big_trim_zero(rest)
    case rows: rows
def big_trim(+rows: List<&2,Nat>) -> List<&2,Nat>: List.reverse(&2,Nat,big_trim_zero(List.reverse(&2,Nat,rows)))
def big_from_go(+fuel: Nat,+n: Nat) -> List<&2,Nat>:
  match fuel n:
    case _ 0n: []
    case 0n _: []
    case 1n+p n: Nat.mod(n,10n) <> big_from_go(p,Nat.div(n,10n))
def big_from(+n: Nat) -> List<&2,Nat>: big_from_go(16n,n)
def big_lex(+a: List<&2,Nat>,+b: List<&2,Nat>) -> U32:
  match a b:
    case Nil{} Nil{}: 1
    case Con{+x,xs} Con{+y,ys}: Bool.pick(U32,Nat.is_eq(x,y),big_lex(xs,ys),Bool.pick(U32,Nat.is_lt(x,y),0,2))
    case _ _: 1
def big_cmp(+a: List<&2,Nat>,+b: List<&2,Nat>) -> U32:
  +al = List.length(&2,Nat,a)
  +bl = List.length(&2,Nat,b)
  Bool.pick(U32,Nat.is_eq(al,bl),big_lex(List.reverse(&2,Nat,a),List.reverse(&2,Nat,b)),Bool.pick(U32,Nat.is_lt(al,bl),0,2))
def big_ge(+a: List<&2,Nat>,+b: List<&2,Nat>) -> Bool: U32.is_ne(big_cmp(a,b),0)
def big_add(+a: List<&2,Nat>,+b: List<&2,Nat>,+carry: Nat) -> List<&2,Nat>:
  match a b:
    case Nil{} Nil{}: big_from(carry)
    case Con{x,xs} Nil{}:
      +sum = Nat.add(x,carry)
      Nat.mod(sum,10n) <> big_add(xs,[],Nat.div(sum,10n))
    case Nil{} Con{y,ys}:
      +sum = Nat.add(y,carry)
      Nat.mod(sum,10n) <> big_add([],ys,Nat.div(sum,10n))
    case Con{x,xs} Con{y,ys}:
      +sum = Nat.add(Nat.add(x,y),carry)
      Nat.mod(sum,10n) <> big_add(xs,ys,Nat.div(sum,10n))
def big_sub(+a: List<&2,Nat>,+b: List<&2,Nat>,+borrow: Nat) -> List<&2,Nat>:
  match a b:
    case Nil{} _: []
    case Con{+x,xs} Nil{}:
      +owes = borrow
      Bool.pick(Nat,Nat.is_ge(x,owes),Nat.sub(x,owes),Nat.sub(Nat.add(x,10n),owes)) <> big_sub(xs,[],Bool.pick(Nat,Nat.is_ge(x,owes),0n,1n))
    case Con{+x,xs} Con{y,ys}:
      +owes = Nat.add(y,borrow)
      Bool.pick(Nat,Nat.is_ge(x,owes),Nat.sub(x,owes),Nat.sub(Nat.add(x,10n),owes)) <> big_sub(xs,ys,Bool.pick(Nat,Nat.is_ge(x,owes),0n,1n))
def big_mul_digit(+a: List<&2,Nat>,+digit: Nat,+carry: Nat) -> List<&2,Nat>:
  match a:
    case Nil{}: big_from(carry)
    case Con{x,xs}:
      +sum = Nat.add(Nat.mul(x,digit),carry)
      Nat.mod(sum,10n) <> big_mul_digit(xs,digit,Nat.div(sum,10n))
def big_mul(+a: List<&2,Nat>,+b: List<&2,Nat>) -> List<&2,Nat>:
  match a:
    case Nil{}: []
    case Con{x,xs}: big_trim(big_add(big_mul_digit(b,x,0n),0n <> big_mul(xs,b),0n))
def big_div_digit(+fuel: Nat,+remainder: List<&2,Nat>,+denominator: List<&2,Nat>,+digit: Nat) -> DivisionStep:
  match fuel:
    case 0n: DivisionStep{remainder,digit}
    case 1n+p:
      +enough = big_ge(remainder,denominator)
      big_div_digit(p,Bool.pick(List<&2,Nat>,enough,big_trim(big_sub(remainder,denominator,0n)),remainder),denominator,Nat.add(digit,U32.to_nat(Bool.to_u32(enough))))
def big_div_go(+digits: List<&2,Nat>,+denominator: List<&2,Nat>,+remainder: List<&2,Nat>,+quotient: List<&2,Nat>) -> List<&2,Nat> & List<&2,Nat>:
  match digits:
    case Nil{}: (big_trim(quotient),remainder)
    case Con{head,rest}:
      +step = big_div_digit(10n,big_trim(head <> remainder),denominator,0n)
      big_div_go(rest,denominator,step_remainder(step),step_digit(step) <> quotient)
def big_div(+numerator: List<&2,Nat>,+denominator: List<&2,Nat>) -> List<&2,Nat> & List<&2,Nat>: big_div_go(List.reverse(&2,Nat,numerator),denominator,[],[])
def big_quotient(result: List<&2,Nat> & List<&2,Nat>) -> List<&2,Nat>:
  match result:
    case (quotient,_): quotient
def big_remainder(result: List<&2,Nat> & List<&2,Nat>) -> List<&2,Nat>:
  match result:
    case (_,remainder): remainder
def bounded_digit(+tooBig: Bool,+acc: Nat,+digit: Nat) -> Nat:
  match tooBig:
    case True{}: Nat.add(Nat.mul(65536n,4294967295n),65535n)
    case False{}: Nat.add(Nat.mul(acc,10n),digit)
def big_to_go(+rows: List<&2,Nat>,+acc: Nat) -> Nat:
  match rows:
    case Nil{}: acc
    case Con{head,rest}: big_to_go(rest,bounded_digit(Nat.is_gt(acc,Nat.sub(Nat.div(Nat.add(Nat.mul(65536n,4294967295n),65535n),10n),1n)),acc,head))
def big_to(+rows: List<&2,Nat>) -> Nat: big_to_go(List.reverse(&2,Nat,rows),0n)

def pick(+test: Bool,+yes: Value,+no: Value) -> Value:
  match test:
    case True{}: yes
    case False{}: no

def natural(+value: Nat) -> Value: JNumber{value,1n,False{}}
def zero() -> Value: natural(0n)
def one() -> Value: natural(1n)
def is_null(+value: Value) -> Bool:
  match value:
    case JNull{}: True{}
    case _: False{}
def flag(+value: Bool) -> Value: JBoolean{value}
def sequence(+values: Value) -> List<&2,Value>:
  match values:
    case JSequence{rows}: rows
    case _: []
def object_keys(+value: Value) -> List<&2,String>:
  match value:
    case JObject{keys,_}: keys
    case _: []
def text(+value: Value) -> String:
  match value:
    case JText{value}: value
    case _: ""
def get_rows(+keys: List<&2,String>,+values: List<&2,Value>,+key: String) -> Value:
  match keys values:
    case Con{name,restKeys} Con{value,restValues}:
      pick(String.eq(name,key),value,get_rows(restKeys,restValues,key))
    case _ _: JNull{}
def get(+object: Value,+key: String) -> Value:
  match object:
    case JObject{keys,values}: get_rows(keys,values,key)
    case _: JNull{}
def prepend_object(+name: String,+old: Value,+value: Value) -> Value:
  match value:
    case JObject{keys,values}: JObject{name <> keys,old <> values}
    case _: JNull{}
def set_head(+test: Bool,+name: String,+restKeys: List<&2,String>,+old: Value,+restValues: List<&2,Value>,+value: Value,+next: Value) -> Value:
  match test:
    case True{}: JObject{name <> restKeys,value <> restValues}
    case False{}: prepend_object(name,old,next)
def set_rows(+keys: List<&2,String>,+values: List<&2,Value>,+key: String,+value: Value) -> Value:
  match keys values:
    case Con{+name,+restKeys} Con{old,+restValues}: set_head(String.eq(name,key),name,restKeys,old,restValues,value,set_rows(restKeys,restValues,key,value))
    case _ _: JObject{[key],[value]}
def set(+object: Value,+key: String,+value: Value) -> Value:
  match object:
    case JObject{keys,values}: set_rows(keys,values,key,value)
    case _: JObject{[key],[value]}
def is_sequence(+value: Value) -> Bool:
  match value:
    case JSequence{_}: True{}
    case _: False{}
def read_natural(+result: Maybe<&2,Nat>) -> Value:
  match result:
    case Some{value}: natural(value)
    case None{}: zero()
def ratio(+value: Value) -> Value:
  match value:
    case JNumber{n,d,_}: JRatio{big_from(n),big_from(d)}
    case JRatio{n,d}: JRatio{n,d}
    case JDecimal{_,n,d,_}: JRatio{n,d}
    case _: JRatio{[],[1n]}
def decimal_digit(+char: Char) -> Nat:
  match char:
    case Chr{code}: U32.to_nat(U32.sub(code,48))
def valid_decimal_digits(+chars: List<&2,Char>) -> Bool:
  match chars:
    case Nil{}: True{}
    case Con{head,rest}: Bool.and(Nat.is_lt(decimal_digit(head),10n),valid_decimal_digits(rest))
def decimal_digits(+chars: List<&2,Char>) -> List<&2,Nat>:
  match chars:
    case Nil{}: []
    case Con{head,rest}: decimal_digit(head) <> decimal_digits(rest)
def parsed_decimal(+whole: String,+fraction: String) -> Value:
  +digits = String.to_list(whole ++ fraction)
  pick(valid_decimal_digits(digits),JRatio{big_trim(List.reverse(&2,Nat,decimal_digits(digits))),List.append(&2,Nat,List.replicate(Nat,String.length(fraction),0n),[1n])},zero())
def decimal_parts(+parts: List<&2,String>) -> Value:
  match parts:
    case Con{whole,Nil{}}: parsed_decimal(whole,"")
    case Con{whole,Con{fraction,Nil{}}}: parsed_decimal(whole,fraction)
    case _: zero()
def decimal_unsigned(+value: String) -> Value: decimal_parts(String.split(value,'.'))
def decimal_sign(+value: String) -> Value:
  match value:
    case SCon{'-',_}: zero()
    case SCon{'+',rest}: decimal_unsigned(rest)
    case value: decimal_unsigned(value)
def parse_number(+value: String) -> Value: decimal_sign(String.trim(value))
def number(+value: Value) -> Value:
  match value:
    case JNumber{n,+d,False{}}: pick(Nat.is_gt(d,0n),JNumber{n,d,False{}},zero())
    case JDecimal{v,n,+d,False{}}: pick(Nat.is_gt(List.length(&2,Nat,d),0n),JDecimal{v,n,d,False{}},zero())
    case JRatio{n,+d}: pick(Nat.is_gt(List.length(&2,Nat,d),0n),JRatio{n,d},zero())
    case JText{value}: parse_number(value)
    case JBoolean{True{}}: one()
    case _: zero()
def integer_data(+value: Value) -> Nat:
  match value:
    case JRatio{n,d}: big_to(big_quotient(big_div(n,d)))
    case _: 0n
def integer(+value: Value) -> Nat: integer_data(ratio(number(value)))
def whole_ratio(+value: Value) -> Value:
  match value:
    case JRatio{n,d}: JRatio{big_quotient(big_div(n,d)),[1n]}
    case _: zero()
def whole(+value: Value) -> Value: whole_ratio(ratio(number(value)))
def integer_value(+value: Value) -> Bool:
  match value:
    case JNumber{n,+d,_}: Bool.and(Nat.is_gt(d,0n),Nat.is_eq(Nat.mod(n,d),0n))
    case _: False{}
def equal(+a: Value,+b: Value) -> Bool:
  match a b:
    case JNull{} JNull{}: True{}
    case JBoolean{x} JBoolean{y}: Bool.not(Bool.xor(x,y))
    case JText{x} JText{y}: String.eq(x,y)
    case JNumber{n,d,s} JNumber{m,e,t}: Bool.and(Bool.not(Bool.xor(s,t)),Nat.is_eq(Nat.mul(n,e),Nat.mul(m,d)))
    case _ _: False{}
def at(+values: List<&2,Value>,+index: Nat) -> Value:
  match values index:
    case Con{head,_} 0n: head
    case Con{_,tail} 1n+p: at(tail,p)
    case _ _: JNull{}
def contains(+values: List<&2,Value>,+value: Value) -> Bool:
  match values:
    case Nil{}: False{}
    case Con{head,tail}: Bool.or(equal(head,value),contains(tail,value))
def append_unique_if(+test: Bool,+values: List<&2,Value>,+value: Value) -> List<&2,Value>:
  match test:
    case True{}: values
    case False{}: List.append(&2,Value,values,[value])
def append_unique(+values: List<&2,Value>,+value: Value) -> List<&2,Value>: append_unique_if(contains(values,value),values,value)
def maybe_append(+test: Bool,+values: List<&2,Value>,+value: Value) -> List<&2,Value>:
  match test:
    case True{}: append_unique(values,value)
    case False{}: values
def unique_go(+values: List<&2,Value>,+acc: List<&2,Value>) -> List<&2,Value>:
  match values:
    case Nil{}: acc
    case Con{head,tail}: unique_go(tail,append_unique(acc,head))
def unique(+value: Value) -> Value: JSequence{unique_go(sequence(value),[])}
def ge_data(+a: Value,+b: Value) -> Bool:
  match a b:
    case JRatio{n,d} JRatio{m,e}: big_ge(big_mul(n,e),big_mul(m,d))
    case _ _: False{}
def ge(+a: Value,+b: Value) -> Bool: ge_data(ratio(number(a)),ratio(number(b)))
def add_data(+a: Value,+b: Value) -> Value:
  match a b:
    case JRatio{n,+d} JRatio{m,+e}: JRatio{big_trim(big_add(big_mul(n,e),big_mul(m,d),0n)),big_mul(d,e)}
    case _ _: zero()
def add(+a: Value,+b: Value) -> Value: add_data(ratio(number(a)),ratio(number(b)))
def subtract_data(+a: Value,+b: Value) -> Value:
  match a b:
    case JRatio{n,+d} JRatio{m,+e}:
      +left = big_mul(n,e)
      +right = big_mul(m,d)
      pick(big_ge(left,right),JRatio{big_trim(big_sub(left,right,0n)),big_mul(d,e)},zero())
    case _ _: zero()
def subtract(+a: Value,+b: Value) -> Value: subtract_data(ratio(number(a)),ratio(number(b)))
def maximum(+a: Value,+b: Value) -> Value: pick(ge(a,b),a,b)
def minimum(+a: Value,+b: Value) -> Value: pick(ge(a,b),b,a)
def length(+value: Value) -> Value: natural(List.length(&2,Value,sequence(value)))
def fresh() -> Value: JObject{["version","gold","meta","characters","stages","achievements","stats","collection","stageRelics","wonCharacters","recorded","settings"],[JNumber{1n,1n,False{}},JNumber{0n,1n,False{}},JSequence{[JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}}]},JSequence{[JNumber{0n,1n,False{}}]},JSequence{[JNumber{0n,1n,False{}}]},JSequence{[]},JObject{["kills","totalgold","survive","wins","evolutions","levels","characters","stages","weapons","revivals","bosskills","characterwins","relics"],[JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{1n,1n,False{}},JNumber{1n,1n,False{}},JNumber{1n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}},JNumber{0n,1n,False{}}]},JObject{["weapons","evolutions","enemies"],[JSequence{[]},JSequence{[]},JSequence{[]}]},JSequence{[]},JSequence{[]},JSequence{[]},JObject{["muted","volume","reducedMotion","showDamage"],[JBoolean{False{}},JNumber{35n,100n,False{}},JBoolean{False{}},JBoolean{True{}}]}]}

def merge_rows(+keys: List<&2,String>,+values: List<&2,Value>,+object: Value) -> Value:
  match keys values:
    case Con{key,restKeys} Con{value,restValues}: merge_rows(restKeys,restValues,set(object,key,value))
    case _ _: object
def merge(+object: Value,+extra: Value) -> Value:
  match extra:
    case JObject{keys,values}: merge_rows(keys,values,object)
    case _: object
def copy_rows(+keys: List<&2,String>,+raw: Value,+base: Value) -> Value:
  match keys:
    case Nil{}: base
    case Con{+key,rest}: copy_rows(rest,raw,set(base,key,pick(is_null(get(raw,key)),get(base,key),get(raw,key))))
def by_id(+rows: List<&2,Value>,+id: Value) -> Value:
  match rows:
    case Nil{}: JNull{}
    case Con{+head,tail}: pick(equal(get(head,"id"),id),head,by_id(tail,id))
def catalog_name(+kind: String) -> String:
  match kind:
    case "character": "CHARACTERS"
    case "stage": "STAGES"
    case "mode": "RUN_MODES"
    case "weapon": "WEAPONS"
    case "arcana": "ARCANA"
    case _: ""
def item(+catalog: Value,+kind: String,+id: Value) -> Value: by_id(sequence(get(catalog,catalog_name(kind))),id)
def normalize_meta(+rows: List<&2,Value>,+ranks: List<&2,Value>,+index: Nat) -> List<&2,Value>:
  match rows:
    case Nil{}: []
    case Con{head,tail}: minimum(whole(at(ranks,index)),get(head,"maxLevel")) <> normalize_meta(tail,ranks,1n+index)
def valid_catalog_ids(+values: List<&2,Value>,+catalog: List<&2,Value>,+acc: List<&2,Value>) -> List<&2,Value>:
  match values:
    case Nil{}: acc
    case Con{+head,tail}: valid_catalog_ids(tail,catalog,maybe_append(Bool.not(is_null(by_id(catalog,head))),acc,head))
def valid_integers(+values: List<&2,Value>,+acc: List<&2,Value>) -> List<&2,Value>:
  match values:
    case Nil{}: acc
    case Con{+head,tail}: valid_integers(tail,maybe_append(integer_value(head),acc,head))
def valid_relics(+values: List<&2,Value>,+acc: List<&2,Value>) -> List<&2,Value>:
  match values:
    case Nil{}: acc
    case Con{+head,tail}: valid_relics(tail,maybe_append(Bool.and(integer_value(head),Bool.and(equal(head,number(head)),Bool.not(ge(head,natural(5n))))),acc,head))
def normalize_stats(+keys: List<&2,String>,+stats: Value,+acc: Value) -> Value:
  match keys:
    case Nil{}: acc
    case Con{+key,rest}: normalize_stats(rest,stats,set(acc,key,number(get(stats,key))))
def normalize_sequences(+keys: List<&2,String>,+raw: Value,+base: Value) -> Value:
  match keys:
    case Nil{}: base
    case Con{+key,rest}: normalize_sequences(rest,raw,set(base,key,pick(is_sequence(get(raw,key)),get(raw,key),get(fresh(),key))))
def normalized(+raw: Value,+catalog: Value) -> Value:
  +base0 = copy_rows(["gold","meta","characters","stages","achievements","stageRelics","wonCharacters","recorded"],raw,fresh())
  +stats = merge(get(base0,"stats"),get(raw,"stats"))
  +collections = merge(get(base0,"collection"),get(raw,"collection"))
  +base1 = set(set(set(base0,"stats",normalize_stats(object_keys(stats),stats,JObject{[],[]})),"collection",collections),"settings",merge(get(base0,"settings"),get(raw,"settings")))
  +base2 = set(set(base1,"gold",whole(get(base1,"gold"))),"meta",JSequence{normalize_meta(sequence(get(catalog,"META_UPGRADES")),sequence(get(base1,"meta")),0n)})
  +base3 = normalize_sequences(["characters","stages","achievements","stageRelics","wonCharacters","recorded"],base2,base2)
  +base4 = set(set(set(base3,"characters",JSequence{valid_catalog_ids(sequence(get(base3,"characters")),sequence(get(catalog,"CHARACTERS")),[zero()])}),"stages",JSequence{valid_catalog_ids(sequence(get(base3,"stages")),sequence(get(catalog,"STAGES")),[zero()])}),"stageRelics",JSequence{valid_relics(sequence(get(base3,"stageRelics")),[])})
  +c0 = set(collections,"weapons",JSequence{valid_integers(sequence(get(collections,"weapons")),[])})
  +c1 = set(c0,"evolutions",JSequence{valid_integers(sequence(get(collections,"evolutions")),[])})
  set(base4,"collection",set(c1,"enemies",JSequence{valid_integers(sequence(get(collections,"enemies")),[])}))
def normalize(+raw: Value,+catalog: Value) -> Value: pick(equal(get(raw,"version"),one()),normalized(raw,catalog),fresh())
def requirements_met(+profile: Value,+item: Value) -> Bool:
  +condition = get(item,"condition")
  Bool.or(is_null(condition),ge(get(get(profile,"stats"),text(get(condition,"stat"))),get(condition,"value")))
def upgrade_item(+catalog: Value,+id: Value) -> Value: by_id(sequence(get(catalog,"META_UPGRADES")),id)
def upgrade_cost(+profile: Value,+id: Value,+catalog: Value) -> Value:
  +entry = upgrade_item(catalog,id)
  +base = integer(get(entry,"costBase"))
  +rank = integer(at(sequence(get(profile,"meta")),integer(id)))
  pick(is_null(entry),JNull{},natural(Nat.div(Nat.mul(base,Nat.add(4n,Nat.mul(rank,3n))),4n)))
def weapon_allowed(+profile: Value,+entry: Value) -> Bool:
  +relic = get(entry,"stageRelic")
  Bool.pick(Bool,is_null(relic),requirements_met(profile,entry),contains(sequence(get(profile,"stageRelics")),relic))
def allowed_go(+rows: List<&2,Value>,+profile: Value,+mask: U32) -> U32:
  match rows:
    case Nil{}: mask
    case Con{+head,tail}: allowed_go(tail,profile,U32.and(mask,U32.not((Bool.to_u32(Bool.not(weapon_allowed(profile,head))) * U32.shln(1,integer(get(head,"id"))) : U32))))
def allowed_weapons(+profile: Value,+catalog: Value) -> U32: allowed_go(sequence(get(catalog,"WEAPON_UNLOCKS")),profile,16777215)
def owned_list(+kind: String) -> String:
  match kind:
    case "character": "characters"
    case _: "stages"
def unlocked_kind(+kind: String,+profile: Value,+id: Value,+catalog: Value) -> Bool:
  match kind:
    case "arcana": Bool.not(is_null(item(catalog,"arcana",id)))
    case "mode": Bool.and(Bool.not(is_null(item(catalog,"mode",id))),requirements_met(profile,item(catalog,"mode",id)))
    case "weapon": U32.is_ne(U32.and(allowed_weapons(profile,catalog),U32.shln(1,integer(id))),0)
    case _: contains(sequence(get(profile,owned_list(kind))),id)
def unlocked(+profile: Value,+kind: String,+id: Value,+catalog: Value) -> Bool: unlocked_kind(kind,profile,id,catalog)
def meta_go(+rows: List<&2,Value>,+index: Nat) -> U32:
  match rows:
    case Nil{}: 0
    case Con{head,tail}: U32.or(U32.shln(U32.from_nat(integer(minimum(head,natural(7n)))),Nat.mul(index,3n)),meta_go(tail,1n+index))
def meta_code(+profile: Value) -> U32: meta_go(sequence(get(profile,"meta")),0n)
def conditions_met(+keys: List<&2,String>,+conditions: Value,+stats: Value) -> Bool:
  match keys:
    case Nil{}: True{}
    case Con{+key,rest}: Bool.and(ge(get(stats,key),get(conditions,key)),conditions_met(rest,conditions,stats))
def qualifies(+profile: Value,+achievement: Value) -> Bool:
  +conditions = get(achievement,"conditions")
  Bool.pick(Bool,is_null(conditions),requirements_met(profile,achievement),conditions_met(object_keys(conditions),conditions,get(profile,"stats")))
def award_go(+rows: List<&2,Value>,+profile: Value) -> Value:
  match rows:
    case Nil{}: profile
    case Con{+entry,tail}: award_go(tail,set(profile,"achievements",JSequence{maybe_append(qualifies(profile,entry),sequence(get(profile,"achievements")),get(entry,"id"))}))
def award(+profile: Value,+catalog: Value) -> Value: award_go(sequence(get(catalog,"ACHIEVEMENTS")),profile)
def set_stat(+profile: Value,+key: String,+value: Value) -> Value: set(profile,"stats",set(get(profile,"stats"),key,value))
def refresh_counts(+profile: Value) -> Value:
  +p0 = set_stat(profile,"characters",length(get(profile,"characters")))
  set_stat(p0,"stages",length(get(p0,"stages")))
def replace_at(+rows: List<&2,Value>,+index: Nat,+value: Value) -> List<&2,Value>:
  match rows index:
    case Con{_,tail} 0n: value <> tail
    case Con{head,tail} 1n+p: head <> replace_at(tail,p,value)
    case _ _: []
def buy_upgrade_ok(+profile: Value,+id: Value,+catalog: Value) -> Value:
  +ranks = sequence(get(profile,"meta"))
  set(set(profile,"gold",subtract(get(profile,"gold"),upgrade_cost(profile,id,catalog))),"meta",JSequence{replace_at(ranks,integer(id),add(at(ranks,integer(id)),one()))})
def upgrade_status(+profile: Value,+id: Value,+catalog: Value) -> Value:
  +entry = upgrade_item(catalog,id)
  +cost = upgrade_cost(profile,id,catalog)
  +rank = at(sequence(get(profile,"meta")),integer(id))
  +maxed = ge(rank,get(entry,"maxLevel"))
  JObject{["rank","cost","maxed","canBuy"],[rank,cost,flag(maxed),flag(Bool.and(Bool.not(is_null(entry)),Bool.and(Bool.not(maxed),ge(get(profile,"gold"),cost))))]}
def boolean(+value: Value) -> Bool:
  match value:
    case JBoolean{value}: value
    case _: False{}
def buy_upgrade(+profile: Value,+id: Value,+catalog: Value) -> Value:
  pick(boolean(get(upgrade_status(profile,id,catalog),"canBuy")),buy_upgrade_ok(profile,id,catalog),JNull{})
def purchase_status(+profile: Value,+kind: String,+id: Value,+catalog: Value) -> Value:
  +entry = item(catalog,kind,id)
  +owned = unlocked(profile,kind,id,catalog)
  +eligible = requirements_met(profile,entry)
  +cost = get(entry,"cost")
  +affordable = ge(get(profile,"gold"),cost)
  +validKind = Bool.or(String.eq(kind,"character"),String.eq(kind,"stage"))
  JObject{["owned","eligible","affordable","canBuy","missingGold","cost"],[flag(owned),flag(eligible),flag(affordable),flag(Bool.and(validKind,Bool.and(Bool.not(is_null(entry)),Bool.and(Bool.not(owned),Bool.and(eligible,affordable))))),subtract(cost,get(profile,"gold")),cost]}
def purchase_ok(+profile: Value,+kind: String,+id: Value,+catalog: Value) -> Value:
  +cost = get(item(catalog,kind,id),"cost")
  +paid = set(profile,"gold",subtract(get(profile,"gold"),cost))
  award(refresh_counts(set(paid,owned_list(kind),JSequence{append_unique(sequence(get(paid,owned_list(kind))),id)})),catalog)
def purchase(+profile: Value,+kind: String,+id: Value,+catalog: Value) -> Value:
  pick(boolean(get(purchase_status(profile,kind,id,catalog),"canBuy")),purchase_ok(profile,kind,id,catalog),JNull{})

def collect_union(+rows: List<&2,Value>,+acc: List<&2,Value>) -> List<&2,Value>:
  match rows:
    case Nil{}: acc
    case Con{head,tail}: collect_union(tail,append_unique(acc,head))
def add_property(+profile: Value,+key: String,+value: Value) -> Value: set(profile,key,JSequence{append_unique(sequence(get(profile,key)),value)})
def add_stat(+profile: Value,+key: String,+value: Value) -> Value: set_stat(profile,key,add(get(get(profile,"stats"),key),value))
def max_stat(+profile: Value,+key: String,+value: Value) -> Value: set_stat(profile,key,maximum(get(get(profile,"stats"),key),value))
def used_levels(+rows: List<&2,Value>,+index: Nat,+threshold: Value,+acc: List<&2,Value>) -> List<&2,Value>:
  match rows:
    case Nil{}: acc
    case Con{head,tail}: used_levels(tail,1n+index,threshold,maybe_append(ge(head,threshold),acc,natural(index)))
def collection_add(+profile: Value,+key: String,+values: List<&2,Value>) -> Value:
  +collection = get(profile,"collection")
  set(profile,"collection",set(collection,key,JSequence{collect_union(values,sequence(get(collection,key)))}))
def record_signature(+frame: Value) -> Value:
  +runId = get(frame,"runId")
  pick(is_null(runId),JText{Nat.show(integer(get(frame,"character"))) ++ ":" ++ Nat.show(integer(get(frame,"stage"))) ++ ":" ++ Nat.show(integer(get(frame,"tick"))) ++ ":" ++ Nat.show(integer(get(frame,"kills"))) ++ ":" ++ Nat.show(integer(get(frame,"gold"))) ++ ":" ++ Nat.show(integer(get(frame,"phase")))},runId)
def drop(+rows: List<&2,Value>,+count: Nat) -> List<&2,Value>:
  match rows count:
    case Con{_,tail} 1n+p: drop(tail,p)
    case _ _: rows
def recent(+rows: List<&2,Value>) -> List<&2,Value>: drop(rows,Nat.sub(List.length(&2,Value,rows),100n))
def newly_awarded(+rows: List<&2,Value>,+old: List<&2,Value>) -> List<&2,Value>:
  match rows:
    case Nil{}: []
    case Con{+head,tail}:
      List.append(&2,Value,sequence(pick(contains(old,head),JSequence{[]},JSequence{[head]})),newly_awarded(tail,old))
def recording(+profile: Value,+frame: Value,+catalog: Value) -> Value:
  +gained = whole(get(frame,"gold"))
  +p0 = set(profile,"recorded",JSequence{recent(List.append(&2,Value,sequence(get(profile,"recorded")),[record_signature(frame)]))})
  +p1 = set(p0,"gold",add(get(p0,"gold"),gained))
  +p2 = add_stat(add_stat(p1,"totalgold",gained),"kills",get(frame,"kills"))
  +p3 = max_stat(p2,"survive",JNumber{integer(get(frame,"tick")),60n,False{}})
  +p4 = max_stat(p3,"levels",pick(is_null(get(frame,"level")),one(),get(frame,"level")))
  +p5 = add_stat(add_stat(p4,"revivals",get(frame,"revivalsUsed")),"bosskills",get(frame,"bossesKilled"))
  +p6 = pick(equal(get(frame,"phase"),natural(4n)),add_property(add_stat(p5,"wins",one()),"wonCharacters",get(frame,"character")),p5)
  +p7 = pick(equal(get(frame,"relicCollected"),one()),add_property(p6,"stageRelics",get(frame,"stage")),p6)
  +p8 = set_stat(p7,"relics",length(get(p7,"stageRelics")))
  +used = used_levels(sequence(get(frame,"weapons")),0n,one(),sequence(get(frame,"usedWeapons")))
  +evolved = used_levels(sequence(get(frame,"weapons")),0n,natural(9n),sequence(get(frame,"evolvedWeapons")))
  +p9 = collection_add(collection_add(collection_add(p8,"weapons",used),"evolutions",evolved),"enemies",sequence(get(frame,"enemiesKilled")))
  +p10 = add_stat(p9,"evolutions",natural(List.length(&2,Value,evolved)))
  +p11 = set_stat(set_stat(refresh_counts(p10),"weapons",length(get(get(p10,"collection"),"weapons"))),"characterwins",length(get(p10,"wonCharacters")))
  +result = award(p11,catalog)
  JObject{["profile","added"],[result,JSequence{newly_awarded(sequence(get(result,"achievements")),sequence(get(profile,"achievements")))}]}
def record_run(+profile: Value,+frame: Value,+catalog: Value) -> Value:
  pick(contains(sequence(get(profile,"recorded")),record_signature(frame)),JObject{["profile","added"],[profile,JSequence{[]}]},recording(profile,frame,catalog))
def setup_id(+profile: Value,+setup: Value,+catalog: Value,+kind: String) -> Value:
  +id = get(setup,kind)
  pick(Bool.and(Bool.not(is_null(item(catalog,kind,id))),unlocked(profile,kind,id,catalog)),id,zero())
def validate_setup(+profile: Value,+setup: Value,+catalog: Value) -> Value:
  +arcana = get(setup,"arcana")
  JObject{["character","stage","arcana","mode"],[setup_id(profile,setup,catalog,"character"),setup_id(profile,setup,catalog,"stage"),pick(is_null(item(catalog,"arcana",arcana)),zero(),arcana),setup_id(profile,setup,catalog,"mode")]}

# Retain the history of weapons used before loadout swaps; thresholds stay in Bend.
def observe_run(+history: Value,+frame: Value) -> Value:
  JObject{["usedWeapons","evolvedWeapons"],[JSequence{used_levels(sequence(get(frame,"weapons")),0n,one(),sequence(get(history,"usedWeapons")))},JSequence{used_levels(sequence(get(frame,"weapons")),0n,natural(9n),sequence(get(history,"evolvedWeapons")))}]}
