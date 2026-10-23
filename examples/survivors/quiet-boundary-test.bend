# Full authoritative-state parity at the presentation-free batch boundary.
# This fixture owns actual independent worlds; no World or column is fabricated.
import Base
import game.bend as G
import bot-actions.bend as B
import offline-policy.bend as Policy
import native-replay-observe.bend as O

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def compare_states(label: String,left: G.State & String,right: G.State & String) -> IO(Unit):
  match left:
    case (_,a):
      match right:
        case (_,b): expect(String.eq(a,b),label)
def compare_packets(+label: String,left: G.Packet,right: G.Packet) -> IO(Unit):
  match left right:
    case G.Packet{a,_} G.Packet{b,frame}:
      do IO<Unit>:
        expect(String.eq(frame,""),label ++ " emits no quiet frame")
        compare_states(label,O.snapshot(a),O.snapshot(b))
    case _ _: IO.die(Unit,1,"FAIL " ++ label ++ " unexpected packet failure")
# Controlled phase/queue fixtures retain the real initialized world and payloads.
# Only Run phase, offered rewards and pending queue are selected for the boundary.
def scenario(packet: G.Packet,+phase: U32,pending: List<&2,U32>) -> G.Packet:
  match packet:
    case G.Packet{G.State{world,+run,rows,_,shots,_},_}: G.quiet_packet(G.State{world,G.with_phase(run,phase),rows,G.reward_offers(run,U32.is_eq(phase,2)),shots,pending})
    case packet: packet
def choose_packets(label: String,+choice: U32,left: G.Packet,right: G.Packet) -> IO(Unit):
  match left right:
    case G.Packet{a,_} G.Packet{b,_}: compare_packets(label,G.choose(a,choice),G.choose_quiet(b,choice))
    case _ _: IO.die(Unit,1,"FAIL phase fixture initialization")
def choose_case(label: String,+phase: U32,choice: U32,+pending: List<&2,U32>) -> IO(Unit):
  choose_packets(label,choice,scenario(B.fresh_start_seed(100),phase,pending),scenario(B.fresh_start_seed_quiet(100),phase,pending))
type QuietProgress is Type: QuietProgress{memory: Policy.Memory,packet: G.Packet,choices: U32}
type QuietReady is Type: QuietReady{finished: Bool,progress: QuietProgress}
type QuietDriven is Type: QuietDriven{packet: G.Packet,choices: U32}
def tick(run: G.Run) -> U32:
  match run:
    case G.Run{_,value,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: value
def selected(quiet: Bool,state: G.State,choice: U32) -> G.Packet:
  match quiet:
    case True{}: G.choose_quiet(state,choice)
    case False{}: G.choose(state,choice)
def move_direction(quiet: Bool,state: G.State,memory: Policy.Memory,dx: F32,dy: F32,choices: U32) -> QuietProgress:
  match quiet:
    case True{}: QuietProgress{memory,G.advance_quiet(state,dx,dy),choices}
    case False{}: QuietProgress{memory,G.advance_quiet(state,dx,dy),choices}
def moved(quiet: Bool,state: G.State,result: Policy.Memory & (F32 & F32),choices: U32) -> QuietProgress:
  (memory,direction) = result
  (dx,dy) = direction
  move_direction(quiet,state,memory,dx,dy,choices)
def next_step(phase: U32,+quiet: Bool,state: G.State,+run: G.Run,rows: List<&2,G.Body>,offers: List<&2,G.Offer>,memory: Policy.Memory,+choices: U32) -> QuietProgress:
  match phase:
    case 1: QuietProgress{memory,selected(quiet,state,Policy.upgrade(run,offers)),(choices + 1 : U32)}
    case 2: QuietProgress{memory,selected(quiet,state,Policy.upgrade(run,offers)),(choices + 1 : U32)}
    case _: moved(quiet,state,Policy.movement(memory,run,rows),choices)
def gate(result: QuietProgress) -> QuietReady:
  match result:
    case QuietProgress{memory,G.Packet{G.State{world,+run,rows,offers,shots,pending},frame},choices}: QuietReady{Bool.or(U32.is_le(1200,tick(run)),U32.is_le(3,G.run_phase(run))),QuietProgress{memory,G.Packet{G.State{world,run,rows,offers,shots,pending},frame},choices}}
    case result: QuietReady{True{},result}
def drive(fuel: Nat,+quiet: Bool,observed: QuietReady) -> QuietDriven:
  match fuel observed:
    case _ QuietReady{_,QuietProgress{_,G.Failed{error},choices}}: QuietDriven{G.Failed{error},choices}
    case _ QuietReady{True{},QuietProgress{_,packet,choices}}: QuietDriven{packet,choices}
    case 0n _: QuietDriven{G.Failed{"Quiet boundary test exhausted fuel"},0}
    case 1n+rest QuietReady{False{},QuietProgress{memory,G.Packet{G.State{world,+run,+rows,+offers,shots,pending},_},choices}}:
      drive(rest,quiet,gate(next_step(G.run_phase(run),quiet,G.State{world,run,rows,offers,shots,pending},run,rows,offers,memory,choices)))
def natural_packets(+label: String,left: G.Packet,right: G.Packet) -> IO(Unit):
  match left right:
    case G.Packet{G.State{a,+ar,ab,ao,as,ap},af} G.Packet{G.State{b,+br,bb,bo,bs,bp},bf}:
      do IO<Unit>:
        expect(Bool.and(U32.is_eq(tick(ar),1200),U32.is_eq(tick(br),1200)),label ++ " reaches1200ticks")
        compare_packets(label,G.Packet{G.State{a,ar,ab,ao,as,ap},af},G.Packet{G.State{b,br,bb,bo,bs,bp},bf})
    case _ _: IO.die(Unit,1,"FAIL natural fixture did not complete")
def natural_compare(+label: String,left: QuietDriven,right: QuietDriven) -> IO(Unit):
  match left right:
    case QuietDriven{a,+x} QuietDriven{b,+y}:
      do IO<Unit>:
        expect(Bool.and(U32.is_eq(x,y),U32.is_lt(0,x)),label ++ " natural upgrades reached")
        natural_packets(label,a,b)
def main() -> IO(Unit):
  do IO<Unit>:
    compare_packets("fresh seed100",B.fresh_start_seed(100),B.fresh_start_seed_quiet(100))
    compare_packets("fresh wrapping seed",B.fresh_start_seed(4294967295),B.fresh_start_seed_quiet(4294967295))
    compare_packets("advanced seed101",B.advanced_start_seed(101),B.advanced_start_seed_quiet(101))
    compare_packets("advanced wrapping seed",B.advanced_start_seed(4294967295),B.advanced_start_seed_quiet(4294967295))
    choose_case("phase0 preserves/promotes existing queue",0,0,[1,2])
    choose_case("level choice promotes queued chest",1,0,[2,1])
    choose_case("chest choice promotes queued level",2,2,[1,2])
    choose_case("invalid choice clamps identically",1,4294967295,[])
    choose_case("phase3 terminal choice",3,0,[1,2])
    choose_case("phase4 terminal choice",4,2,[2,1])
    natural_compare("fresh1200 full state",drive(4900n,False{},gate(QuietProgress{Policy.initial(),B.fresh_start_seed(100),0})),drive(4900n,True{},gate(QuietProgress{Policy.initial(),B.fresh_start_seed_quiet(100),0})))
    natural_compare("advanced1200 full state",drive(4900n,False{},gate(QuietProgress{Policy.initial(),B.advanced_start_seed(101),0})),drive(4900n,True{},gate(QuietProgress{Policy.initial(),B.advanced_start_seed_quiet(101),0})))
