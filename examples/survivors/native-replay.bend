import Base
import game.bend as G
import native-replay-format.bend as F
import native-replay-common.bend as C
import native-replay-observe.bend as O

# Replays actual recorded controls through the game. This module and its import
# graph have no Policy dependency. Parsing, warmup, full observations and output
# occur outside the timed suffix. A nonserializing full-state completion fold
# runs before the endpoint clock; check mode records intermediate states.
type Cursor is Type: Cursor{packet: G.Packet,actions: List<&2,F.Action>,step: U32}
type WarmReady is Type: WarmReady{ready: Bool,cursor: Cursor}
type Completed is Type: Completed{state: G.State,step: U32,tick: U32,phase: U32}

def apply_packet(action: F.Action,packet: G.Packet) -> G.Packet:
  match packet:
    case G.Packet{state}: C.apply(action,state)
    case G.Failed{error}: G.Failed{error}
def warm_gate(+target: U32,cursor: Cursor) -> WarmReady:
  match cursor:
    case Cursor{G.Packet{G.State{world,+run,rows,offers,snapshots,pending}},actions,step}:
      WarmReady{U32.is_le(target,C.tick(run)),Cursor{G.Packet{G.State{world,run,rows,offers,snapshots,pending}},actions,step}}
    case cursor: WarmReady{True{},cursor}
def warm_loop(fuel: Nat,+target: U32,ready: WarmReady) -> Cursor:
  match fuel ready:
    case _ WarmReady{True{},cursor}: cursor
    case 0n _: Cursor{G.Failed{"Replay warmup exhausted safety fuel"},[],0}
    case _ WarmReady{False{},Cursor{_,Nil{},_}}: Cursor{G.Failed{"Replay trace ended before warmup"},[],0}
    case 1n+rest WarmReady{False{},Cursor{packet,Con{action,tail},step}}:
      warm_loop(rest,target,warm_gate(target,Cursor{apply_packet(action,packet),tail,(step + 1 : U32)}))
def execute(actions: List<&2,F.Action>,packet: G.Packet,step: U32) -> Cursor:
  match actions:
    case []: Cursor{packet,[],step}
    case action <> rest: execute(rest,apply_packet(action,packet),(step + 1 : U32))
def complete(cursor: Cursor) -> Result<&1,&1,String,Completed>:
  match cursor:
    case Cursor{G.Failed{error},_,_}: Fail{error}
    case Cursor{G.Packet{G.State{world,+run,rows,offers,snapshots,pending}},_,step}:
      Done{Completed{G.State{world,run,rows,offers,snapshots,pending},step,C.tick(run),G.run_phase(run)}}
def final_checkpoint(result: G.State & String,+fixture: String,+step: U32,+firstTick: U32,+actualEnd: U32,+finalPhase: U32) -> IO(Unit):
  match result:
    case (_,payload):
      do IO<Unit>:
        IO.print("{\"type\":\"checkpoint\",\"fixture\":\"" ++ C.escape(fixture) ++ "\",\"step\":" ++ U32.show(step) ++ ",\"payload\":" ++ payload ++ "}")
        IO.print("{\"type\":\"summary\",\"fixture\":\"" ++ C.escape(fixture) ++ "\",\"actions\":" ++ U32.show(step) ++ ",\"firstTick\":" ++ U32.show(firstTick) ++ ",\"endTick\":" ++ U32.show(actualEnd) ++ ",\"phase\":" ++ U32.show(finalPhase) ++ "}")
def final_valid(valid: Bool,+fixture: String,+firstTick: U32,expectedEnd: U32,expectedPhase: U32,state: G.State,step: U32) -> IO(Unit):
  match valid:
    case True{}: final_checkpoint(O.snapshot(state),fixture,step,firstTick,expectedEnd,expectedPhase)
    case False{}: IO.die(Unit,1,"Replay final tick/phase differs from recorded outcome")
def checked_finish(result: Result<&1,&1,String,Completed>,+fixture: String,+firstTick: U32,+expectedEnd: U32,+expectedPhase: U32) -> IO(Unit):
  match result:
    case Fail{error}: IO.die(Unit,1,"Native replay failed: " ++ error)
    case Done{Completed{state,step,tick,phase}}:
      final_valid(Bool.and(U32.is_eq(tick,expectedEnd),U32.is_eq(phase,expectedPhase)),fixture,firstTick,expectedEnd,expectedPhase,state,step)
def timed_forced(result: G.State & U32,+step: U32,+tick: U32,+phase: U32,+started: Nat,+fixture: String,+firstTick: U32,+firstStep: U32) -> IO(Unit):
  match result:
    case (state,+digest):
      do IO<Unit>:
        stopped : Nat <- IO.now()
        IO.print("{\"type\":\"replay-summary\",\"fixture\":\"" ++ C.escape(fixture) ++ "\",\"windowMs\":" ++ Nat.show(Nat.sub(stopped,started)) ++ ",\"windowActions\":" ++ U32.show((step - firstStep : U32)) ++ ",\"firstTick\":" ++ U32.show(firstTick) ++ ",\"endTick\":" ++ U32.show(tick) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"stateDigest32\":" ++ U32.show(digest) ++ "}")
        final_checkpoint(O.snapshot(state),fixture,step,firstTick,tick,phase)
def timed_valid(valid: Bool,state: G.State,+step: U32,+tick: U32,+phase: U32,+started: Nat,+fixture: String,+firstTick: U32,+firstStep: U32) -> IO(Unit):
  match valid:
    case False{}: IO.die(Unit,1,"Timed replay final tick/phase differs from recorded outcome")
    case True{}: timed_forced(O.force(state),step,tick,phase,started,fixture,firstTick,firstStep)
def timed_finish(result: Result<&1,&1,String,Completed>,+started: Nat,+fixture: String,+firstTick: U32,+expectedEnd: U32,+expectedPhase: U32,+firstStep: U32) -> IO(Unit):
  match result:
    case Fail{error}: IO.die(Unit,1,"Native timed replay failed: " ++ error)
    case Done{Completed{state,+step,+tick,+phase}}: timed_valid(Bool.and(U32.is_eq(tick,expectedEnd),U32.is_eq(phase,expectedPhase)),state,step,tick,phase,started,fixture,firstTick,firstStep)
def timed_cursor(cursor: Cursor,+fixture: String,+firstTick: U32,+expectedEnd: U32,+expectedPhase: U32) -> IO(Unit):
  match cursor:
    case Cursor{packet,actions,+step}:
      do IO<Unit>:
        started : Nat <- IO.now()
        # complete forces Packet/State/Run and their actual tick/phase before
        # timed_finish reaches its IO.now. Native C dominance is audited too.
        timed_finish(complete(execute(actions,packet,step)),started,fixture,firstTick,expectedEnd,expectedPhase,step)
def checkpoint_result(result: G.State & String,+fixture: String,+step: U32,+actions: List<&2,F.Action>,use: Cursor -> IO(Unit)) -> IO(Unit):
  match result:
    case (state,payload):
      do IO<Unit>:
        IO.print("{\"type\":\"checkpoint\",\"fixture\":\"" ++ C.escape(fixture) ++ "\",\"step\":" ++ U32.show(step) ++ ",\"payload\":" ++ payload ++ "}")
        use(Cursor{G.Packet{state},actions,step})
def checkpoint(cursor: Cursor,+fixture: String,use: Cursor -> IO(Unit)) -> IO(Unit):
  match cursor:
    case Cursor{G.Packet{state},+actions,+step}: checkpoint_result(O.snapshot(state),fixture,step,actions,use)
    case Cursor{G.Failed{error},_,_}: IO.die(Unit,1,"Replay checkpoint failed: " ++ error)
def checkpoint_if(enabled: Bool,cursor: Cursor,+fixture: String,use: Cursor -> IO(Unit)) -> IO(Unit):
  match enabled:
    case True{}: checkpoint(cursor,fixture,use)
    case False{}: use(cursor)
def check_advance(cursor: Cursor,use: Cursor -> IO(Unit)) -> IO(Unit):
  match cursor:
    case Cursor{packet,Con{action,tail},step}: use(Cursor{apply_packet(action,packet),tail,(step + 1 : U32)})
    case cursor: use(cursor)
def check_loop(+fuel: Nat,cursor: Cursor,+fixture: String,+firstTick: U32,+expectedEnd: U32,+expectedPhase: U32,+every: U32,+first: Bool) -> IO(Unit):
  match fuel cursor:
    case _ Cursor{_,Nil{},_}: checked_finish(complete(cursor),fixture,firstTick,expectedEnd,expectedPhase)
    case 0n _: IO.die(Unit,1,"Replay validation exhausted safety fuel")
    case 1n+rest Cursor{packet,Con{+action,+tail},+step}:
      checkpoint_if(Bool.and(Bool.not(first),U32.is_eq((step % U32.max(1,every) : U32),0)),Cursor{packet,action <> tail,step},fixture,(cursor =>
        check_advance(cursor,(next => check_loop(rest,next,fixture,firstTick,expectedEnd,expectedPhase,every,False{})))
      ))
def measured(mode: Bool,cursor: Cursor,+fixture: String,+firstTick: U32,+expectedEnd: U32,+expectedPhase: U32,+every: U32) -> IO(Unit):
  match mode:
    case True{}: timed_cursor(cursor,fixture,firstTick,expectedEnd,expectedPhase)
    case False{}: check_loop(10000000n,cursor,fixture,firstTick,expectedEnd,expectedPhase,every,True{})
def begin(trace: F.Trace,+every: U32) -> IO(Unit):
  match trace:
    case F.Trace{+profile,+seed,+warmup,+endTick,+actualEnd,+finalPhase,actions}:
      do IO<Unit>:
        IO.print("{\"type\":\"start\",\"schemaVersion\":1,\"fixture\":\"" ++ C.fixture(seed,profile,warmup,endTick) ++ "\",\"seed\":" ++ U32.show(seed) ++ ",\"profile\":" ++ U32.show(profile) ++ ",\"warmup\":" ++ U32.show(warmup) ++ ",\"endTick\":" ++ U32.show(endTick) ++ "}")
        checkpoint(warm_loop(10000000n,warmup,warm_gate(warmup,Cursor{C.start(profile,seed),actions,0})),C.fixture(seed,profile,warmup,endTick),(cursor => measured(U32.is_eq(every,0),cursor,C.fixture(seed,profile,warmup,endTick),warmup,actualEnd,finalPhase,every)))
def parsed(trace: Maybe<&2,F.Trace>,every: U32) -> IO(Unit):
  match trace:
    case None{}: IO.die(Unit,1,"Malformed or unsupported native replay trace")
    case Some{trace}: begin(trace,every)
def main() -> IO(Unit):
  do IO<Unit>:
    path : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_REPLAY_TRACE")
    every : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_REPLAY_CHECKPOINT_EVERY")
    text : String <- C.load(C.default_text(C.environment(path),"/tmp/nightfall-actions.trace"))
    parsed(F.parse(text),C.number(C.environment(every),0))
