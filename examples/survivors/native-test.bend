# Real native UI event flow; upgrade/terminal boundaries are explicitly fabricated.
import Base
import native.bend as N
import native-economy.bend as P
import native-profile.bend as ProfileIO
import game.bend as G
import native-capture.bend as Capture

type Observation is Data: Observation{run: G.Run,ui: N.Ui,profile: P.Profile}
def run(observation: Observation) -> G.Run:
  match observation:
    case Observation{run,_,_}: run
def ui(observation: Observation) -> N.Ui:
  match observation:
    case Observation{_,ui,_}: ui
def profile(observation: Observation) -> P.Profile:
  match observation:
    case Observation{_,_,profile}: profile
def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def check(state: N.Native,test: Observation -> Bool,label: String) -> IO(N.Native):
  match state:
    case N.Native{G.Packet{G.State{world,+r,rows,offers,snapshots,pending},frame},+u,+p}:
      do IO<N.Native>:
        expect(test(Observation{r,u,p}),label)
        return N.Native{G.Packet{G.State{world,r,rows,offers,snapshots,pending},frame},u,p}
    case state: IO.die(N.Native,1,"Engine failure in " ++ label)
def frames(fuel: Nat,state: N.Native) -> N.Native:
  match fuel:
    case 0n: state
    case 1n+p: frames(p,N.frame(state))
def key(code: U32,state: N.Native) -> N.Native: N.reduce([Key{code,True{}}],state)
def automatic(phase: U32,state: N.Native) -> N.Native:
  match phase:
    case 1: key(49,key(101,state))
    case 2: key(49,key(101,state))
    case _: state
def busy_step(state: N.Native) -> N.Native:
  match state:
    case N.Native{G.Packet{G.State{world,+r,rows,offers,snapshots,pending},frame},ui,profile}:
      N.frame(automatic(N.run_phase(r),N.Native{G.Packet{G.State{world,r,rows,offers,snapshots,pending},frame},ui,profile}))
    case state: state
def busy(fuel: Nat,state: N.Native) -> N.Native:
  match fuel:
    case 0n: state
    case 1n+p: busy(p,busy_step(state))
def release(code: U32,state: N.Native) -> N.Native: N.reduce([Key{code,False{}}],state)
def phase_run(run: G.Run,+newPhase: U32,+newGold: U32) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{newPhase,tick,px,py,hp,maxHp,xp,need,level,kills,newGold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def boundary(state: N.Native,phase: U32,gold: U32) -> N.Native:
  match state:
    case N.Native{G.Packet{G.State{world,+run,rows,_,snapshots,_},frame},ui,profile}:
      N.Native{G.Packet{G.State{world,phase_run(run,phase,gold),rows,[G.Offer{0,0,(G.at(N.run_weapons(run),0) + 1 : U32)},G.Offer{1,0,1},G.Offer{0,1,1}],snapshots,[]},frame},N.set_paused(ui,0),profile}
    case state: state
def paid_run(run: G.Run) -> G.Run:
  match run:
    case G.Run{+phase,+tick,+px,+py,+hp,+maxHp,_,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: G.Run{0,tick,px,py,hp,maxHp,need,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def earned_panel_test(state: N.Native) -> IO(Unit):
  match state:
    case N.Native{G.Packet{G.State{world,r,rows,offers,snapshots,pending},frame},u,p}:
      do IO<Unit>:
        state : N.Native <- check(N.frame(N.Native{G.Packet{G.State{world,paid_run(r),rows,offers,snapshots,pending},frame},u,p}),+o => Bool.and(U32.is_eq(N.run_phase(run(o)),1),U32.is_eq(N.ui_paused(ui(o)),2)),"seeded XP: actual ECS level automatically opens panel")
        return Unit{}
    case _: IO.die(Unit,1,"Automatic level engine failure")
def automatic_test(state: N.Native) -> IO(N.Native):
  do IO<N.Native>:
    state : N.Native <- check(N.new_reward(0,state),o => U32.is_eq(N.ui_paused(ui(o)),2),"new reward opens automatically")
    state : N.Native <- check(frames(2n,key(109,state)),o => U32.is_eq(N.ui_paused(ui(o)),2),"map key preserves open reward selection")
    return key(27,state)
def pending_test(state: N.Native) -> IO(N.Native):
  match state:
    case N.Native{G.Packet{G.State{world,+r,rows,offers,snapshots,pending},frame},u,p}:
      do IO<N.Native>:
        state : N.Native <- check(key(49,N.Native{G.Packet{G.State{world,r,rows,offers,snapshots,pending},frame},N.set_screen(u,1),p}),+o => Bool.and(U32.is_eq(N.run_phase(run(o)),N.run_phase(r)),U32.is_eq(G.at(N.run_weapons(run(o)),0),G.at(N.run_weapons(r),0))),"pending upgrade ignores numeric key before opening")
        state : N.Native <- check(frames(1n,state),+o => Bool.and(U32.is_eq(N.run_phase(run(o)),N.run_phase(r)),U32.is_eq(N.run_tick(run(o)),(N.run_tick(r) + 1 : U32))),"pending upgrade keeps battlefield ticking")
        state : N.Native <- check(key(101,state),o => U32.is_eq(N.ui_paused(ui(o)),2),"E deliberately opens upgrade panel")
        state : N.Native <- check(frames(2n,state),o => U32.is_eq(N.run_tick(run(o)),(N.run_tick(r) + 1 : U32)),"open upgrade panel freezes battlefield")
        state : N.Native <- check(key(27,state),+o => Bool.and(U32.is_eq(N.ui_paused(ui(o)),0),U32.is_eq(N.run_phase(run(o)),N.run_phase(r))),"Escape defers upgrade without consuming it")
        return state
    case state: IO.die(N.Native,1,"Pending upgrade engine failure")
def queued_test(state: N.Native) -> IO(N.Native):
  match state:
    case N.Native{G.Packet{G.State{world,r,rows,offers,snapshots,_},frame},u,p}:
      check(key(49,key(101,N.Native{G.Packet{G.State{world,r,rows,offers,snapshots,[1]},frame},u,p})),+o => Bool.and(U32.is_eq(N.run_phase(run(o)),1),U32.is_eq(N.ui_paused(ui(o)),2)),"queued next level automatically opens after one choice")
    case state: IO.die(N.Native,1,"Queued upgrade engine failure")
def choose_test(state: N.Native) -> IO(N.Native):
  match state:
    case N.Native{G.Packet{G.State{world,+r,rows,offers,snapshots,pending},frame},ui,profile}:
      check(key(49,key(101,N.Native{G.Packet{G.State{world,r,rows,offers,snapshots,pending},frame},ui,profile})),+o => Bool.and(U32.is_eq(N.run_phase(run(o)),0),U32.is_eq(G.at(N.run_weapons(run(o)),0),(G.at(N.run_weapons(r),0) + 1 : U32))),"fabricated upgrade boundary: key1 increments actual weapon rank")
    case state: IO.die(N.Native,1,"Upgrade engine failure")
def abandon_test(state: N.Native) -> IO(N.Native):
  match state:
    case N.Native{G.Packet{G.State{world,+r,rows,offers,snapshots,pending},frame},u,+p}:
      +expected = (P.gold(p) + N.run_gold(r) : U32)
      do IO<N.Native>:
        IO.print("Observed expedition Q bank amount: " ++ U32.show(N.run_gold(r)))
        state : N.Native <- N.persist(N.settle(key(113,key(27,N.Native{G.Packet{G.State{world,r,rows,offers,snapshots,pending},frame},u,p}))))
        state : N.Native <- check(state,+o => Bool.and(U32.is_eq(N.ui_screen(ui(o)),0),U32.is_eq(P.gold(profile(o)),expected)),"paused Q banks actual expedition gold and returns camp")
        state : N.Native <- N.persist(N.settle(key(113,state)))
        state : N.Native <- check(state,o => U32.is_eq(P.gold(profile(o)),expected),"repeated Q cannot bank expedition twice")
        loaded : P.Profile <- ProfileIO.load()
        expect(U32.is_eq(P.gold(loaded),expected),"paused Q persists banked gold")
        return key(32,state)
    case state: IO.die(N.Native,1,"Abandon engine failure")
def terminal_test(state: N.Native) -> IO(N.Native):
  match state:
    case N.Native{game,u,+p}:
      +expected = (P.gold(p) + 777 : U32)
      do IO<N.Native>:
        state : N.Native <- N.persist(N.settle(boundary(N.Native{game,u,p},3,777)))
        state : N.Native <- check(state,o => U32.is_eq(P.gold(profile(o)),expected),"fabricated terminal boundary awards gold")
        state : N.Native <- N.persist(N.settle(state))
        state : N.Native <- check(state,o => U32.is_eq(P.gold(profile(o)),expected),"terminal repeated frame cannot duplicate reward")
        loaded : P.Profile <- ProfileIO.load()
        expect(U32.is_eq(P.gold(loaded),expected),"UI dirty profile persisted through native IO")
        return state
def quit_result(result: Maybe<N.Native>) -> IO(Unit):
  match result:
    case None{}: IO.print("PASS Close event exits")
    case Some{_}: IO.die(Unit,1,"FAIL Close event exits")
def main() -> IO(Unit):
  do IO<Unit>:
    state : N.Native <- Capture.view("menu.ppm",N.initial(P.fresh()))
    state : N.Native <- check(state,o => U32.is_eq(N.ui_screen(ui(o)),0),"native menu initial")
    state : N.Native <- check(key(115,state),o => U32.is_eq(N.ui_selected(ui(o)),1),"menu keyboard selection")
    state : N.Native <- check(key(13,state),o => U32.is_eq(N.ui_character(ui(o)),0),"locked character cannot equip")
    state : N.Native <- check(key(109,state),o => U32.is_eq(N.ui_screen(ui(o)),2),"meta menu key")
    state : N.Native <- check(key(99,state),o => U32.is_eq(N.ui_screen(ui(o)),3),"collection menu key")
    state : N.Native <- check(key(27,state),o => U32.is_eq(N.ui_screen(ui(o)),0),"escape returns camp")
    state : N.Native <- check(key(32,state),o => U32.is_eq(N.ui_screen(ui(o)),1),"space starts actual ECS game")
    state : N.Native <- check(frames(10n,key(100,state)),o => F32.is_gt(N.run_px(run(o)),G.world_center()),"real D input moves player")
    state : N.Native <- check(release(100,state),o => U32.is_eq(N.ui_keys(ui(o)),0),"key release clears movement")
    state : N.Native <- check(frames(5n,key(27,state)),+o => Bool.and(U32.is_eq(N.ui_paused(ui(o)),1),U32.is_eq(N.run_tick(run(o)),10)),"pause stops simulation")
    state : N.Native <- check(frames(1n,key(27,state)),+o => Bool.and(U32.is_eq(N.ui_paused(ui(o)),0),U32.is_eq(N.run_tick(run(o)),11)),"resume continues simulation")
    state : N.Native <- check(frames(2n,key(109,state)),+o => Bool.and(U32.is_eq(N.ui_paused(ui(o)),1),U32.is_eq(N.run_tick(run(o)),11)),"M map stops simulation")
    state : N.Native <- Capture.view("map.ppm",state)
    state : N.Native <- check(key(109,state),o => U32.is_eq(N.ui_paused(ui(o)),0),"M closes map")
    state : N.Native <- check(busy(160n,state),o => U32.is_ge(N.run_tick(run(o)),120),"genuine ECS battlefield advanced at least120 ticks")
    state : N.Native <- Capture.view("gameplay.ppm",state)
    state : N.Native <- abandon_test(state)
    IO.print("Explicit UI boundary: inject37 collected gold into an otherwise live run")
    state : N.Native <- abandon_test(boundary(state,0,37))
    state : N.Native <- automatic_test(boundary(state,1,777))
    state : N.Native <- pending_test(state)
    state : N.Native <- Capture.view("upgrade.ppm",key(101,state))
    state : N.Native <- choose_test(state)
    state : N.Native <- automatic_test(boundary(state,2,777))
    state : N.Native <- pending_test(state)
    state : N.Native <- check(key(49,key(101,state)),o => U32.is_eq(N.ui_paused(ui(o)),0),"treasure choice closes explicit panel")
    state : N.Native <- queued_test(boundary(state,1,777))
    state : N.Native <- terminal_test(state)
    state : N.Native <- check(key(13,state),o => U32.is_eq(N.ui_screen(ui(o)),0),"terminal Enter returns camp")
    result : Maybe<N.Native> <- N.tick([Close{}],state)
    quit_result(result)
    earned_panel_test(key(32,N.initial(P.fresh())))
    IO.print("NATIVE UI PASS")
