import Base

# Versioned decimal-U32 stream. Moves contain IEEE-754 binary32 bits, never
# formatted float decimals. Header and command count make truncation fail closed.
type Action is Data:
  ReplayMove{tick: U32,phase: U32,dxBits: U32,dyBits: U32}
  ReplayUpgrade{tick: U32,phase: U32,index: U32}
type Trace is Data: Trace{profile: U32,seed: U32,warmup: U32,endTick: U32,actualEnd: U32,finalPhase: U32,actions: List<&2,Action>}

def float_bits(value: F32) -> U32:
  match value:
    case F32{word}: U32{word}
def from_bits(bits: U32) -> F32:
  match bits:
    case U32{word}: F32{word}
def finite(bits: U32) -> Bool: Bool.not(U32.is_eq((U32.shrn(bits,23n) % 256 : U32),255))
def choose_word(test: Bool,a: U32,b: U32) -> U32:
  match test:
    case True{}: a
    case False{}: b
def choose_words(test: Bool,a: List<&2,U32>,b: List<&2,U32>) -> List<&2,U32>:
  match test:
    case True{}: a
    case False{}: b
def token_finish(valid: Bool,words: List<&2,U32>) -> Maybe<&2,List<&2,U32>>:
  match valid:
    case True{}: Some{List.reverse(&2,U32,words)}
    case False{}: None{}
def tokens(text: String,+valid: Bool,+active: Bool,+current: U32,+words: List<&2,U32>) -> Maybe<&2,List<&2,U32>>:
  match text:
    case SNil{}: token_finish(valid,choose_words(active,current <> words,words))
    case SCon{Chr{+code},rest}:
      +white=Bool.or(U32.is_eq(code,32),Bool.or(U32.is_eq(code,9),Bool.or(U32.is_eq(code,10),U32.is_eq(code,13))))
      +digit=Bool.and(U32.is_le(48,code),U32.is_le(code,57))
      +value=(code - 48 : U32)
      +fits=Bool.or(U32.is_lt(current,429496729),Bool.and(U32.is_eq(current,429496729),U32.is_le(value,5)))
      tokens(rest,Bool.and(valid,Bool.or(white,Bool.and(digit,fits))),Bool.not(white),choose_word(white,0,(current * 10 + value : U32)),choose_words(Bool.and(white,active),current <> words,words))
def decoded(valid: Bool,actions: List<&2,Action>) -> Maybe<&2,List<&2,Action>>:
  match valid:
    case True{}: Some{List.reverse(&2,Action,actions)}
    case False{}: None{}
def actions(words: List<&2,U32>,+valid: Bool,+count: U32,+acc: List<&2,Action>) -> Maybe<&2,List<&2,Action>>:
  match words:
    case Nil{}: decoded(Bool.and(valid,U32.is_eq(count,0)),acc)
    case Con{0,Con{+tick,Con{+phase,Con{+dx,Con{+dy,rest}}}}}:
      actions(rest,Bool.and(valid,Bool.and(U32.is_lt(0,count),Bool.and(U32.is_eq(phase,0),Bool.and(finite(dx),finite(dy))))),(count - 1 : U32),ReplayMove{tick,phase,dx,dy} <> acc)
    case Con{1,Con{+tick,Con{+phase,Con{+choice,rest}}}}:
      actions(rest,Bool.and(valid,Bool.and(U32.is_lt(0,count),Bool.or(U32.is_eq(phase,1),U32.is_eq(phase,2)))),(count - 1 : U32),ReplayUpgrade{tick,phase,choice} <> acc)
    case _: None{}
def decoded_trace(result: Maybe<&2,List<&2,Action>>,profile: U32,seed: U32,warmup: U32,endTick: U32,actualEnd: U32,finalPhase: U32) -> Maybe<&2,Trace>:
  match result:
    case None{}: None{}
    case Some{rows}: Some{Trace{profile,seed,warmup,endTick,actualEnd,finalPhase,rows}}
def header_valid(valid: Bool,words: List<&2,U32>,profile: U32,seed: U32,warmup: U32,endTick: U32,actualEnd: U32,finalPhase: U32,count: U32) -> Maybe<&2,Trace>:
  match valid:
    case False{}: None{}
    case True{}: decoded_trace(actions(words,True{},count,[]),profile,seed,warmup,endTick,actualEnd,finalPhase)
def header(result: Maybe<&2,List<&2,U32>>) -> Maybe<&2,Trace>:
  match result:
    case Some{Con{1313231410,Con{1,Con{+profile,Con{seed,Con{+warmup,Con{+endTick,Con{+actualEnd,Con{+finalPhase,Con{count,rest}}}}}}}}}}:
      header_valid(Bool.and(U32.is_le(profile,1),Bool.and(U32.is_le(warmup,actualEnd),Bool.and(U32.is_le(actualEnd,endTick),U32.is_le(finalPhase,4)))),rest,profile,seed,warmup,endTick,actualEnd,finalPhase,count)
    case _: None{}
def parse(text: String) -> Maybe<&2,Trace>: header(tokens(text,True{},False{},0,[]))
def action_text(action: Action) -> String:
  match action:
    case ReplayMove{tick,phase,dx,dy}: "0 " ++ U32.show(tick) ++ " " ++ U32.show(phase) ++ " " ++ U32.show(dx) ++ " " ++ U32.show(dy) ++ "\n"
    case ReplayUpgrade{tick,phase,index}: "1 " ++ U32.show(tick) ++ " " ++ U32.show(phase) ++ " " ++ U32.show(index) ++ "\n"
def actions_text(rows: List<&2,Action>) -> String:
  match rows:
    case []: ""
    case row <> rest: action_text(row) ++ actions_text(rest)
def encode(trace: Trace) -> String:
  match trace:
    case Trace{profile,seed,warmup,endTick,actualEnd,finalPhase,+rows}:
      "1313231410 1 " ++ U32.show(profile) ++ " " ++ U32.show(seed) ++ " " ++ U32.show(warmup) ++ " " ++ U32.show(endTick) ++ " " ++ U32.show(actualEnd) ++ " " ++ U32.show(finalPhase) ++ " " ++ Nat.show(List.length(&2,Action,rows)) ++ "\n" ++ actions_text(rows)
