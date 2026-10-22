# Native complete-run consumer: only public start/configure/choose/advance inputs.
# No injected clock, inventory, entity, health or terminal state.
import Base
import game.bend as G

type Stats is Data: Stats{boss: Bool,chest: Bool,level: Bool,decisions: U32}
type Target is Data: Target{x: F32,y: F32,distance: F32,found: Bool}
type Direction is Data: Direction{x: F32,y: F32}
def phase(run: G.Run) -> U32:
  match run:
    case G.Run{phase,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: phase
def tick(run: G.Run) -> U32:
  match run:
    case G.Run{_,tick,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: tick
def px(run: G.Run) -> F32:
  match run:
    case G.Run{_,_,px,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: px
def py(run: G.Run) -> F32:
  match run:
    case G.Run{_,_,_,py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: py
def hp(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,hp,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: hp
def maxHp(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,maxHp,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: maxHp
def weapons(run: G.Run) -> List<&2,U32>:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,weapons,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: weapons
def passives(run: G.Run) -> List<&2,U32>:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,_,_,_,passives,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: passives
def level(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,level,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: level
def kills(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,kills,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: kills
def gold(run: G.Run) -> U32:
  match run:
    case G.Run{_,_,_,_,_,_,_,_,_,_,gold,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: gold
def contains(values: List<&2,U32>,+id: U32) -> Bool:
  match values:
    case []: False{}
    case value <> rest: Bool.or(U32.is_eq(value,id),contains(rest,id))
def preferred_weapon(id: U32) -> Bool: contains([4,19,10,0,2,17],id)
def passive_rank(id: U32) -> U32: G.at([4,1,3,99,99,99,2,5,99,99,99,0,99,99,99,99,99,99],id)
def offer_score(offer: G.Offer,+run: G.Run) -> U32:
  match offer:
    case G.Offer{3,_,_}: 1000
    case G.Offer{5,_,_}: 1000
    case G.Offer{0,+id,_}: ((170 + 90 * Bool.to_u32(U32.is_eq(id,4)) + 30 * Bool.to_u32(U32.is_lt(0,G.at(weapons(run),id)))) * Bool.to_u32(preferred_weapon(id)) : U32)
    case G.Offer{1,+id,_}: ((210 - U32.min(99,passive_rank(id)) * 5 + 20 * Bool.to_u32(U32.is_eq(G.at(passives(run),id),0))) * Bool.to_u32(U32.is_lt(passive_rank(id),6)) : U32)
    case G.Offer{2,_,_}: (10 + 290 * Bool.to_u32(U32.is_lt((hp(run) * 10 : U32),(maxHp(run) * 7 : U32))) : U32)
    case G.Offer{4,_,_}: 5
    case _: 0
def best_offer(offers: List<&2,G.Offer>,+run: G.Run,+index: U32,+best: U32,+score: U32) -> U32:
  match offers:
    case []: best
    case +offer <> rest: best_offer(rest,run,(index + 1 : U32),G.choose_id(U32.is_lt(score,offer_score(offer,run)),index,best),U32.max(score,offer_score(offer,run)))
def prefer(found: Bool,x: F32,y: F32,distance: F32,old: Target) -> Target:
  match found:
    case True{}: Target{x,y,distance,True{}}
    case False{}: old
def target_distance(target: Target) -> F32:
  match target:
    case Target{_,_,distance,_}: distance
def nearest_kind(rows: List<&2,G.Body>,+kind: U32,+px: F32,+py: F32,+best: Target) -> Target:
  match rows:
    case []: best
    case G.Body{+x,+y,+k,_,_,_,_,_,_} <> rest: nearest_kind(rest,kind,px,py,prefer(Bool.and(U32.is_eq(k,kind),F32.is_lt(G.distance2(x,y,px,py),target_distance(best))),x,y,G.distance2(x,y,px,py),best))
def chest_target(chest: Target,loot: Target) -> Target:
  match chest:
    case Target{x,y,distance,True{}}: Target{x,y,distance,True{}}
    case _: loot
def ready(weapons: List<&2,U32>,+passives: List<&2,U32>,+id: U32) -> Bool:
  match weapons:
    case []: False{}
    case level <> rest: Bool.or(Bool.and(U32.is_eq(level,8),U32.is_lt(0,G.at(passives,G.evolution_passive(id)))),ready(rest,passives,(id + 1 : U32)))
def pick_target(ready: Bool,+rows: List<&2,G.Body>,+run: G.Run) -> Target:
  match ready:
    case True{}: chest_target(nearest_kind(rows,5,px(run),py(run),Target{0.0,0.0,100000000.0,False{}}),nearest_kind(rows,2,px(run),py(run),Target{(1800.0 + F32.cos((U32.to_f32(tick(run)) / 180.0 : F32)) * 300.0 : F32),(1800.0 + F32.sin((U32.to_f32(tick(run)) / 180.0 : F32)) * 300.0 : F32),100000000.0,False{}}))
    case False{}: nearest_kind(rows,2,px(run),py(run),Target{(1800.0 + F32.cos((U32.to_f32(tick(run)) / 180.0 : F32)) * 300.0 : F32),(1800.0 + F32.sin((U32.to_f32(tick(run)) / 180.0 : F32)) * 300.0 : F32),100000000.0,False{}})
def avoid_force(+kind: U32,+distance: F32) -> F32:
  (F32.max(0.0,(140.0 - distance : F32)) * 4.0 * U32.to_f32(Bool.to_u32(Bool.or(U32.is_eq(kind,0),U32.is_eq(kind,7)))) : F32)
def avoid(rows: List<&2,G.Body>,+px: F32,+py: F32,+dx: F32,+dy: F32) -> Direction:
  match rows:
    case []: Direction{dx,dy}
    case G.Body{+x,+y,+kind,_,_,_,_,_,_} <> rest: avoid(rest,px,py,(dx + (px - x) / F32.max(1.0,F32.sqrt(G.distance2(x,y,px,py))) * avoid_force(kind,F32.sqrt(G.distance2(x,y,px,py))) : F32),(dy + (py - y) / F32.max(1.0,F32.sqrt(G.distance2(x,y,px,py))) * avoid_force(kind,F32.sqrt(G.distance2(x,y,px,py))) : F32))
def steer(+rows: List<&2,G.Body>,+run: G.Run,target: Target) -> Direction:
  match target:
    case Target{x,y,_,_}: avoid(rows,px(run),py(run),(x - px(run) + 400.0 * U32.to_f32(Bool.to_u32(F32.is_lt(px(run),160.0))) - 400.0 * U32.to_f32(Bool.to_u32(F32.is_lt(3440.0,px(run)))) : F32),(y - py(run) + 400.0 * U32.to_f32(Bool.to_u32(F32.is_lt(py(run),160.0))) - 400.0 * U32.to_f32(Bool.to_u32(F32.is_lt(3440.0,py(run)))) : F32))
def move(state: G.State,direction: Direction) -> G.Packet:
  match direction:
    case Direction{+dx,+dy}: G.advance(state,(dx / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),(dy / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32))
def step(phase: U32,state: G.State,+run: G.Run,+rows: List<&2,G.Body>,offers: List<&2,G.Offer>) -> G.Packet:
  match phase:
    case 1: G.choose(state,best_offer(offers,run,0,0,0))
    case 2: G.choose(state,best_offer(offers,run,0,0,0))
    case _: move(state,steer(rows,run,pick_target(ready(weapons(run),passives(run),0),rows,run)))
def saw_boss(rows: List<&2,G.Body>) -> Bool:
  match rows:
    case []: False{}
    case G.Body{_,_,+kind,variant,_,_,_,_,_} <> rest: Bool.or(Bool.and(U32.is_eq(kind,0),U32.is_le(20,variant)),saw_boss(rest))
def observe(stats: Stats,+run: G.Run,rows: List<&2,G.Body>) -> Stats:
  match stats:
    case Stats{boss,chest,level,decisions}: Stats{Bool.or(boss,saw_boss(rows)),Bool.or(chest,U32.is_eq(phase(run),2)),Bool.or(level,U32.is_eq(phase(run),1)),(decisions + Bool.to_u32(Bool.or(U32.is_eq(phase(run),1),U32.is_eq(phase(run),2))) : U32)}
def evolved(weapons: List<&2,U32>) -> Bool:
  match weapons:
    case []: False{}
    case level <> rest: Bool.or(U32.is_le(9,level),evolved(rest))
def finish(ok: Bool,message: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS native full run " ++ message)
    case False{}: IO.die(Unit,1,"FAIL native full run " ++ message)
def report(+run: G.Run,stats: Stats) -> IO(Unit):
  match stats:
    case Stats{boss,chest,seenLevel,decisions}: finish(Bool.and(Bool.and(U32.is_eq(phase(run),4),U32.is_eq(hp(run),0)),Bool.and(Bool.and(U32.is_le(36000,tick(run)),U32.is_le(tick(run),37000)),Bool.and(boss,Bool.and(chest,Bool.and(seenLevel,evolved(weapons(run))))))),"tick=" ++ U32.show(tick(run)) ++ " phase=" ++ U32.show(phase(run)) ++ " hp=" ++ U32.show(hp(run)) ++ " level=" ++ U32.show(level(run)) ++ " kills=" ++ U32.show(kills(run)) ++ " gold=" ++ U32.show(gold(run)) ++ " decisions=" ++ U32.show(decisions))
def remaining(active: Bool,fuel: Nat) -> Nat:
  match active:
    case True{}: fuel
    case False{}: 0n
def progress(log: Bool,+run: G.Run) -> IO(Unit):
  match log:
    case True{}: IO.print("checkpoint tick=" ++ U32.show(tick(run)) ++ " level=" ++ U32.show(level(run)) ++ " hp=" ++ U32.show(hp(run)) ++ " kills=" ++ U32.show(kills(run)))
    case False{}:
      do IO<Unit>:
        return Unit{}
def loop(fuel: Nat,active: Bool,packet: G.Packet,+stats: Stats) -> IO(Unit):
  match fuel active packet:
    case 0n _ G.Packet{G.State{_,run,_,_,_,_},_}: report(run,stats)
    case _ False{} G.Packet{G.State{_,run,_,_,_,_},_}: report(run,stats)
    case 1n+rest True{} G.Packet{G.State{world,+run,+rows,+offers,+snapshots,+pending},_}:
      do IO<Unit>:
        progress(Bool.and(U32.is_eq(phase(run),0),U32.is_eq((tick(run) % 3600 : U32),0)),run)
        loop(rest,Bool.not(Bool.or(U32.is_eq(phase(run),3),U32.is_eq(phase(run),4))),step(phase(run),G.State{world,run,rows,offers,snapshots,pending},run,rows,offers),observe(stats,run,rows))
    case _ _ _: IO.die(Unit,1,"Game packet failure")
def configured(packet: G.Packet) -> G.Packet:
  match packet:
    case G.Packet{state,_}: G.configure(state,0,9)
    case packet: packet
def main() -> IO(Unit): loop(42000n,True{},configured(G.start(2,364304237)),Stats{False{},False{},False{},0})
