# Input-only fresh-profile diagnostic. No clock, inventory or entity injection.
# Kites nearby enemies and chooses legal defensive upgrades; never requires a win.
import Base
import game-components.bend as Components
import game.bend as G
import enemy-combat.bend as Enemy
import enemy-presentation.bend as EnemyView
import offline-threats.bend as Threats
import native-full-run.bend as F
import native-economy.bend as P
import offline-policy.bend as Policy

type Stats is Data: Stats{firstReward: U32,decisions: U32,maxLiving: U32,firstDamage: U32,hitEvents: U32,minHp: U32,lastHp: U32}
def living(rows: List<&2,Enemy.State>) -> U32: EnemyView.living(rows)
def measured(stats: Stats,+run: G.Run,rows: List<&2,Enemy.State>) -> Stats:
  match stats:
    case Stats{+firstReward,+decisions,maxLiving,+firstDamage,+hitEvents,minHp,+lastHp}: Stats{G.choose_id(Bool.and(U32.is_eq(firstReward,0),Bool.or(U32.is_eq(F.phase(run),1),U32.is_eq(F.phase(run),2))),F.tick(run),firstReward),(decisions + Bool.to_u32(Bool.or(U32.is_eq(F.phase(run),1),U32.is_eq(F.phase(run),2))) : U32),U32.max(maxLiving,living(rows)),G.choose_id(Bool.and(U32.is_eq(firstDamage,0),Bool.and(Bool.not(U32.is_eq(lastHp,4294967295)),U32.is_lt(F.hp(run),lastHp))),F.tick(run),firstDamage),(hitEvents + Bool.to_u32(Bool.and(Bool.not(U32.is_eq(lastHp,4294967295)),U32.is_lt(F.hp(run),lastHp))) : U32),U32.min(minHp,F.hp(run)),F.hp(run)}
def steer_nearest(rows: List<&2,Threats.Threat>,+run: G.Run,aim: G.Aim) -> F32 & F32:
  match aim:
    case G.Aim{+x,+y,_,_}: Policy.avoid(rows,Policy.Point{G.run_px(run),G.run_py(run)},False{},(((G.run_px(run) - x) / F32.max(1.0,F32.sqrt(G.distance2(x,y,G.run_px(run),G.run_py(run))))) * F32.max(0.0,(220.0 - F32.sqrt(G.distance2(x,y,G.run_px(run),G.run_py(run))) : F32)) * 6.0 + (G.run_py(run) - y) / F32.max(1.0,F32.sqrt(G.distance2(x,y,G.run_px(run),G.run_py(run)))) * 35.0 + (G.world_center() - G.run_px(run)) * 0.05 + 1000.0 * U32.to_f32(Bool.to_u32(F32.is_lt(G.run_px(run),(G.world_margin() + 180.0 : F32)))) - 1000.0 * U32.to_f32(Bool.to_u32(F32.is_lt((G.world_size() - G.world_margin() - 180.0 : F32),G.run_px(run)))) : F32),(((G.run_py(run) - y) / F32.max(1.0,F32.sqrt(G.distance2(x,y,G.run_px(run),G.run_py(run))))) * F32.max(0.0,(220.0 - F32.sqrt(G.distance2(x,y,G.run_px(run),G.run_py(run))) : F32)) * 6.0 - (G.run_px(run) - x) / F32.max(1.0,F32.sqrt(G.distance2(x,y,G.run_px(run),G.run_py(run)))) * 35.0 + (G.world_center() - G.run_py(run)) * 0.05 + 1000.0 * U32.to_f32(Bool.to_u32(F32.is_lt(G.run_py(run),(G.world_margin() + 180.0 : F32)))) - 1000.0 * U32.to_f32(Bool.to_u32(F32.is_lt((G.world_size() - G.world_margin() - 180.0 : F32),G.run_py(run)))) : F32))
def moved(state: G.State,direction: F32 & F32) -> G.Packet:
  (dx,dy) = direction
  G.advance(state,dx,dy)
def step(phase: U32,state: G.State,+run: G.Run,offers: List<&2,G.Offer>,+snapshots: List<&2,G.Snapshot>) -> G.Packet:
  match phase:
    case 1: G.choose(state,F.best_offer(offers,run,0,0,0))
    case 2: G.choose(state,F.best_offer(offers,run,0,0,0))
    case _: moved(state,steer_nearest(Policy.threats(snapshots),run,G.nearest(EnemyView.targets(G.enemy_observations(snapshots)),G.run_px(run),G.run_py(run),G.Aim{(G.world_center() + 300.0 : F32),G.world_center(),0,100000000.0})))
def report(+run: G.Run,stats: Stats) -> IO(Unit):
  match stats:
    case Stats{firstReward,decisions,maxLiving,firstDamage,hitEvents,minHp,_}: IO.print("OBSERVED fresh kiting tick=" ++ U32.show(F.tick(run)) ++ " phase=" ++ U32.show(F.phase(run)) ++ " hp=" ++ U32.show(F.hp(run)) ++ " level=" ++ U32.show(F.level(run)) ++ " kills=" ++ U32.show(F.kills(run)) ++ " firstRewardTick=" ++ U32.show(firstReward) ++ " decisions=" ++ U32.show(decisions) ++ " maxLiving=" ++ U32.show(maxLiving) ++ " firstDamageTick=" ++ U32.show(firstDamage) ++ " hitEvents=" ++ U32.show(hitEvents) ++ " minHp=" ++ U32.show(minHp))
def loop(fuel: Nat,active: Bool,packet: G.Packet,+stats: Stats) -> IO(Unit):
  match fuel active packet:
    case 0n _ G.Packet{G.State{_,+run,_,snapshots,_}}: report(run,measured(stats,run,G.enemy_observations(snapshots)))
    case _ False{} G.Packet{G.State{_,+run,_,snapshots,_}}: report(run,measured(stats,run,G.enemy_observations(snapshots)))
    case 1n+rest True{} G.Packet{G.State{world,+run,+offers,+snapshots,pending}}:
      loop(rest,Bool.and(U32.is_lt(F.tick(run),3599),U32.is_lt(F.phase(run),3)),step(F.phase(run),G.State{world,run,offers,snapshots,pending},run,offers,snapshots),measured(stats,run,G.enemy_observations(snapshots)))
    case _ _ _: IO.die(Unit,1,"Pacing diagnostic packet failure")
def unlock(packet: G.Packet) -> G.Packet:
  match packet:
    case G.Packet{state}: G.configure_unlocks(state,P.weapon_mask(P.fresh()))
    case packet: packet
def configure(packet: G.Packet) -> G.Packet:
  match packet:
    case G.Packet{state}: G.configure(state,0,0)
    case packet: packet
def main() -> IO(Unit): loop(5000n,True{},unlock(configure(G.start(0,P.meta(P.fresh())))),Stats{0,0,0,0,0,4294967295,4294967295})
