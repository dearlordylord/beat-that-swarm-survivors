# Virtual delivery schedules: no IO, renderer, classifier or real sleeps.
import Base
import ./coop-session.bend as S

type NetEvent is Data:
  Deliver{peer: U32,command: S.Command}
  Disconnect{player: U32}
type Scheduled is Data: Scheduled{at: U32,event: NetEvent}
type Accepted is Data: Accepted{at: U32,event: NetEvent}
type Simulation is Data: Simulation{state: S.State,log: List<&2,Accepted>}
def state_clock(state: S.State) -> U32:
  match state:
    case S.State{_,clock,_,_,_,_}: clock
def retain(accepted: Bool,state: S.State,+event: NetEvent,at: U32,log: List<&2,Accepted>) -> Simulation:
  match accepted:
    case False{}: Simulation{state,log}
    case True{}: Simulation{state,Accepted{at,event} <> log}
def delivered(result: S.Admission,event: NetEvent,at: U32,log: List<&2,Accepted>) -> Simulation:
  match result:
    case S.Admission{state,accepted,_}: retain(accepted,state,event,at,log)
def apply(event: NetEvent,+state: S.State,log: List<&2,Accepted>) -> Simulation:
  match event:
    case Deliver{+peer,+command}: delivered(S.receive(state,peer,command),Deliver{peer,command},state_clock(state),log)
    case Disconnect{+player}: retain(U32.is_le(player,1),S.disconnect(player,state),Disconnect{player},state_clock(state),log)
def due_decided(due: Bool,event: NetEvent,result: Simulation) -> Simulation:
  match due result:
    case False{} result: result
    case True{} Simulation{state,log}: apply(event,state,log)
def due(rows: List<&2,Scheduled>,+now: U32,result: Simulation) -> Simulation:
  match rows:
    case Nil{}: result
    case Con{Scheduled{at,event},rest}: due(rest,now,due_decided(U32.is_eq(at,now),event,result))
def clock_result(result: Simulation) -> Simulation:
  match result:
    case Simulation{state,log}: Simulation{S.clock(state),log}
def run_go(fuel: Nat,+schedule: List<&2,Scheduled>,result: Simulation) -> Simulation:
  match fuel result:
    case 0n result: result
    case 1n+p Simulation{+state,log}: run_go(p,schedule,clock_result(due(schedule,state_clock(state),Simulation{state,log})))
def run(fuel: Nat,session: U32,schedule: List<&2,Scheduled>) -> Simulation: run_go(fuel,schedule,Simulation{S.fresh(session),[]})
def replay_rows(rows: List<&2,Accepted>) -> List<&2,Scheduled>:
  match rows:
    case Nil{}: []
    case Con{Accepted{at,event},rest}: Scheduled{at,event} <> replay_rows(rest)
def replay(fuel: Nat,session: U32,reversedLog: List<&2,Accepted>) -> Simulation: run(fuel,session,replay_rows(List.reverse(&2,Accepted,reversedLog)))
