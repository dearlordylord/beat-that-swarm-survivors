import game-encoder.bend as Encoder
import run-state.bend as RS
import Base
import game.bend as G
import bot-actions.bend as B
import native.bend as N
import native-economy.bend as P

# Optional visible experiment. The single native-owned World is both rendered
# and advanced. External inference pauses simulation, but not window events.
type Command is Data: Command{kind: U32,x: U32,y: U32,index: U32,horizon: U32}
type Bot is Type: Bot{game: G.Packet,directory: String,sequence: U32,published: U32,left: U32,dx: F32,dy: F32,last: Nat}

def number(value: Maybe<&2,U32>) -> U32:
  match value:
    case Some{n}: n
    case None{}: 4294967295

def parse_rows(rows: List<&2,String>) -> Command:
  match rows:
    case a <> b <> c <> d <> e <> _: Command{number(U32.read(a)),number(U32.read(b)),number(U32.read(c)),number(U32.read(d)),number(U32.read(e))}
    case _: Command{4294967295,0,0,0,0}
def parse(text: String) -> Command: parse_rows(String.lines(text))
def axis(n: U32) -> F32: ((U32.to_f32(n) - 1000.0) / 1000.0 : F32)
def valid_move(command: Command) -> Bool:
  match command:
    case Command{0,x,y,_,+horizon}: Bool.and(U32.is_le(x,2000),Bool.and(U32.is_le(y,2000),Bool.and(U32.is_lt(0,horizon),U32.is_le(horizon,30))))
    case _: False{}

def write_done(result: File & Result<&1,&1,U32 & String,Unit>) -> IO(Unit):
  match result:
    case (file,_): File.close(file)
def write_open(text: String,result: Result<&1,&1,U32 & String,File>) -> IO(Unit):
  match result:
    case Fail{_}: IO.print_err("Visible bot could not write session file")
    case Done{file}:
      do IO<Unit>:
        written : File & Result<&1,&1,U32 & String,Unit> <- File.write(file,text)
        write_done(written)
def write(path: String,text: String) -> IO(Unit):
  do IO<Unit>:
    opened : Result<&1,&1,U32 & String,File> <- File.open(path,"w")
    write_open(text,opened)

def text_result(result: Result<&1,&1,U32 & String,String>) -> String:
  match result:
    case Fail{_}: ""
    case Done{text}: text
def read_done(result: File & Result<&1,&1,U32 & String,String>) -> IO(String):
  match result:
    case (file,text):
      do IO<String>:
        File.close(file)
        return text_result(text)
def read_open(result: Result<&1,&1,U32 & String,File>) -> IO(String):
  match result:
    case Fail{_}: IO.pure(String,"")
    case Done{file}:
      do IO<String>:
        read : File & Result<&1,&1,U32 & String,String> <- File.read(file,512)
        read_done(read)
def read(path: String) -> IO(String):
  do IO<String>:
    opened : Result<&1,&1,U32 & String,File> <- File.open(path,"r")
    read_open(opened)

def published(observed: B.Observed,+directory: String,+sequence: U32,last: Nat) -> IO(Bot):
  match observed:
    case B.Observed{state,observation,actions,mechanics}:
      +frame = Encoder.encode(observation)
      do IO<Bot>:
        write(directory ++ "/observation.json","{\"sequence\":" ++ U32.show(sequence) ++ ",\"frame\":" ++ frame ++ ",\"actions\":" ++ actions ++ ",\"mechanics\":" ++ mechanics ++ "}")
        return Bot{G.Packet{state},directory,sequence,1,0,0.0,0.0,last}
    case B.ObserveFailed{error}: IO.pure(Bot,Bot{G.Failed{error},directory,sequence,1,0,0.0,0.0,last})
def publish(state: Bot) -> IO(Bot):
  match state:
    case Bot{G.Packet{game},directory,sequence,0,_,_,_,last}: published(B.observe(game),directory,sequence,last)
    case state: IO.pure(Bot,state)

def apply_upgrade(valid: Bool,state: G.State,index: U32) -> G.Packet:
  match valid:
    case True{}: G.choose(state,index)
    case False{}: G.packet(state)
def upgrade(state: G.State,+index: U32) -> G.Packet:
  match state:
    case G.State{world,+run,+offers,snapshots,pending}:
      apply_upgrade(Bool.and(Bool.or(U32.is_eq(N.run_phase(run),1),U32.is_eq(N.run_phase(run),2)),U32.is_lt(index,U32.from_nat(List.length(&2,G.Offer,offers)))),G.State{world,run,offers,snapshots,pending},index)
def command_move(valid: Bool,state: Bot,command: Command) -> Bot:
  match valid state command:
    case True{} Bot{game,directory,sequence,_,_,_,_,last} Command{_,x,y,_,horizon}: Bot{game,directory,sequence,1,horizon,axis(x),axis(y),last}
    case _ state _: state
def command_upgrade_valid(valid: Bool,game: G.State,directory: String,sequence: U32,published: U32,last: Nat,index: U32) -> Bot:
  match valid:
    case True{}: Bot{G.choose(game,index),directory,(sequence + 1 : U32),0,0,0.0,0.0,last}
    case False{}: Bot{G.packet(game),directory,sequence,published,0,0.0,0.0,last}
def command_upgrade(state: G.State,directory: String,sequence: U32,published: U32,last: Nat,+index: U32) -> Bot:
  match state:
    case G.State{world,+run,+offers,snapshots,pending}: command_upgrade_valid(Bool.and(Bool.or(U32.is_eq(N.run_phase(run),1),U32.is_eq(N.run_phase(run),2)),U32.is_lt(index,U32.from_nat(List.length(&2,G.Offer,offers)))),G.State{world,run,offers,snapshots,pending},directory,sequence,published,last,index)
def command(state: Bot,+cmd: Command) -> Bot:
  match state cmd:
    case Bot{G.Packet{game},directory,sequence,published,0,_,_,last} Command{1,_,_,index,_}: command_upgrade(game,directory,sequence,published,last,index)
    case state cmd: command_move(valid_move(cmd),state,cmd)
def poll(state: Bot) -> IO(Bot):
  match state:
    case Bot{game,+directory,+sequence,published,0,dx,dy,last}:
      do IO<Bot>:
        text : String <- read(directory ++ "/command-" ++ U32.show(sequence) ++ ".txt")
        return command(Bot{game,directory,sequence,published,0,dx,dy,last},parse(text))
    case state: IO.pure(Bot,state)

def finish_step(active: Bool,packet: G.Packet,directory: String,sequence: U32,left: U32,dx: F32,dy: F32,last: Nat) -> Bot:
  match active left:
    case True{} 0: Bot{packet,directory,(sequence + 1 : U32),0,0,dx,dy,last}
    case True{} _: Bot{packet,directory,sequence,1,left,dx,dy,last}
    case False{} _: Bot{packet,directory,(sequence + 1 : U32),0,0,dx,dy,last}

def after_step(packet: G.Packet,directory: String,sequence: U32,left: U32,dx: F32,dy: F32,last: Nat) -> Bot:
  match packet:
    case G.Packet{G.State{world,+run,offers,snapshots,pending}}:
      finish_step(U32.is_eq(N.run_phase(run),0),G.Packet{G.State{world,run,offers,snapshots,pending}},directory,sequence,left,dx,dy,last)
    case packet: Bot{packet,directory,(sequence + 1 : U32),0,0,dx,dy,last}
def step_ready(ready: Bool,state: Bot,now: Nat) -> Bot:
  match ready state:
    case True{} Bot{G.Packet{game},directory,sequence,published,left,+dx,+dy,_}: after_step(G.advance(game,dx,dy),directory,sequence,(left - 1 : U32),dx,dy,now)
    case _ state: state

def step(+now: Nat,state: Bot) -> Bot:
  match state:
    case Bot{game,directory,sequence,published,+left,dx,dy,+last}: step_ready(Bool.and(U32.is_lt(0,left),Nat.is_le(16n,Nat.sub(now,last))),Bot{game,directory,sequence,published,left,dx,dy,last},now)
def closes(events: List<Event>) -> Bool:
  match events:
    case []: False{}
    case Close{} <> _: True{}
    case Key{27,True{}} <> _: True{}
    case _ <> rest: closes(rest)
def continue(state: Bot) -> IO(Maybe<Bot>):
  do IO<Maybe<Bot>>:
    now : Nat <- IO.now()
    state : Bot <- publish(step(now,state))
    state : Bot <- poll(state)
    return Some{state}
def tick_closed(closed: Bool,state: Bot) -> IO(Maybe<Bot>):
  match closed state:
    case True{} Bot{_,directory,_,_,_,_,_,_}:
      do IO<Maybe<Bot>>:
        write(directory ++ "/closed.json","{\"closed\":true}")
        return None{}
    case False{} state: continue(state)
def tick(events: List<Event>,state: Bot) -> IO(Maybe<Bot>): tick_closed(closes(events),state)
def rendering_run(run: G.Run,packet: G.Packet) -> N.Native:
  match run:
    case G.Run{RS.Session{+phase,_,_,_,_,_,_,_,_,_,_,_,_},RS.PlayerState{_,_,_,_,character,_,_,_,_,_,_,_,_,_,_,_}}: N.Native{packet,N.set_character(N.set_paused(N.set_screen(N.initial_ui(),1),(Bool.to_u32(Bool.or(U32.is_eq(phase,1),U32.is_eq(phase,2))) * 2 : U32)),character),P.fresh()}
def rendering_native(packet: G.Packet) -> N.Native:
  match packet:
    case G.Packet{G.State{world,+run,offers,snapshots,pending}}:
      rendering_run(run,G.Packet{G.State{world,run,offers,snapshots,pending}})
    case packet: N.Native{packet,N.set_screen(N.initial_ui(),1),P.fresh()}
def bot_view_return(directory: String,sequence: U32,published: U32,left: U32,dx: F32,dy: F32,last: Nat,native: N.Native,image: Image) -> Bot & Image:
  match native:
    case N.Native{game,_,_}: (Bot{game,directory,sequence,published,left,dx,dy,last},image)
def bot_image(directory: String,sequence: U32,published: U32,left: U32,dx: F32,dy: F32,last: Nat,result: N.Native & Image) -> Bot & Image:
  (native,image) = result
  bot_view_return(directory,sequence,published,left,dx,dy,last,native,image)
def view(state: Bot) -> Bot & Image:
  match state:
    case Bot{game,directory,sequence,published,left,dx,dy,last}: bot_image(directory,sequence,published,left,dx,dy,last,N.view(rendering_native(game)))
def environment(result: Result<&1,&1,U32 & String,String>) -> String: text_result(result)
def seed_result(value: Maybe<&2,U32>) -> U32:
  match value:
    case Some{n}: n
    case None{}: 12345
def seed_value(text: String) -> U32: seed_result(U32.read(text))
def initial_game(mode: String,seed: U32) -> G.Packet:
  match mode:
    case "advanced": B.advanced_start_seed(seed)
    case _: B.fresh_start_seed(seed)
def launch(directory: String,mode: String,seed: U32) -> IO(Unit):
  match directory:
    case "": IO.print_err("Set NIGHTFALL_BOT_SESSION to a writable session directory")
    case _: App.run(~Bot,~App{view,tick},"Nightfall - Visible Bot (inference pauses simulation)",1024,768,Bot{initial_game(mode,seed),directory,1,0,0,0.0,0.0,0n})
def main() -> IO(Unit):
  do IO<Unit>:
    directory : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_SESSION")
    mode : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_PROFILE")
    seed : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_SEED")
    launch(environment(directory),environment(mode),seed_value(environment(seed)))
