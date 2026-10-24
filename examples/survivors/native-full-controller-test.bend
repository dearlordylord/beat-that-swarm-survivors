# Pure qualification-controller decisions. These Run samples are not injected
# into gameplay; the full witness still uses only public input actions.
import Base
import game.bend as G
import native-full-run.bend as C

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def observed_run(packet: G.Packet) -> G.Run:
  match packet:
    case G.Packet{G.State{_,run,_,_,_,_},_}: run
    case _: G.Run{0,0,0.0,0.0,0,0,0,0,0,0,0,0,[],[],0,0,0,0,0,0,0,0,0,0,0,0,0,[],0}
def sample(rank: U32,owned: U32,charges: U32,run: G.Run) -> G.Run:
  match run:
    case G.Run{_,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,_,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: G.Run{1,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,G.set_at(weapons,C.witness_weapon(),rank),G.set_at(passives,C.required_passive(),owned),invuln,seed,stage,arcana,meta,revivals,bosses,mode,charges,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def supports(passives: List<&2,U32>,run: G.Run) -> G.Run:
  match run:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,_,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def chosen(index: U32,action: C.RewardAction) -> Bool:
  match action:
    case C.Choose{actual}: U32.is_eq(index,actual)
    case _: False{}
def rerolled(action: C.RewardAction) -> Bool:
  match action:
    case C.Reroll{}: True{}
    case _: False{}
def reward_priorities(+base: G.Run) -> IO(Unit):
  +missing = sample(7,0,2,base)
  +starter: G.Offer = G.Offer{0,C.witness_weapon(),8}
  +prerequisite: G.Offer = G.Offer{1,C.required_passive(),1}
  +unrelated: G.Offer = G.Offer{0,(C.witness_weapon() + 1 : U32),1}
  do IO<Unit>:
    expect(U32.is_lt(C.offer_score(starter,missing),C.offer_score(prerequisite,missing)),"missing engine recipe prerequisite outranks starter upgrade")
    expect(chosen(1,C.reward_action([starter,prerequisite],missing)),"real prerequisite offer is selected")
    expect(U32.is_eq(C.offer_score(unrelated,missing),0),"unrelated weapons cannot expand the pre-evolution build")
    expect(chosen(0,C.reward_action([starter,unrelated],missing)),"useful starter upgrade does not spend a reroll")
def support_capacity(+base: G.Run) -> IO(Unit):
  +maxedMissing = sample(8,0,2,base)
  +prerequisite: G.Offer = G.Offer{1,C.required_passive(),1}
  +heal: G.Offer = G.Offer{2,0,1}
  +support: G.Offer = G.Offer{1,0,1}
  +fiveSupports = G.bump(G.bump(G.bump(G.bump(G.bump(C.passives(base),0),1),2),6),7)
  +reserved = supports(fiveSupports,maxedMissing)
  do IO<Unit>:
    expect(U32.is_lt(C.offer_score(support,maxedMissing),C.offer_score(prerequisite,maxedMissing)),"recipe remains above support improvement")
    expect(chosen(1,C.reward_action([heal,support],maxedMissing)),"useful support is taken without spending a reroll")
    expect(C.support_keeps_slot(0,reserved),"existing support upgrade does not consume reserved recipe slot")
    expect(Bool.not(C.support_keeps_slot(3,reserved)),"new support cannot consume final missing-recipe slot")
    expect(C.recipe_slot_available(G.passive_offer(C.required_passive(),fiveSupports)),"reserved slot remains legal under actual engine capacity")
def reroll_availability(+base: G.Run) -> IO(Unit):
  +oneStep = G.seeded_run(sample(8,0,1,base),9)
  +heal: G.Offer = G.Offer{2,0,1}
  +unrelated: G.Offer = G.Offer{0,(C.witness_weapon() + 1 : U32),1}
  do IO<Unit>:
    expect(rerolled(C.reward_action([heal,unrelated],oneStep)),"reachable recipe spends an actual available reroll")
    expect(chosen(0,C.reward_action([heal,unrelated],sample(8,0,0,base))),"exhausted rerolls use the safe fallback instead of issuing a no-op")
    expect(C.recipe_offered(C.reroll_offers(G.reroll_seed(C.seed(oneStep)),oneStep)),"one-step forecast uses actual engine offers")
def reroll_reachability(+base: G.Run) -> IO(Unit):
  +maxedMissing = sample(8,0,2,base)
  +twoSteps = G.seeded_run(sample(8,0,2,base),4)
  +twoStepsShort = G.seeded_run(sample(8,0,1,base),4)
  +heal: G.Offer = G.Offer{2,0,1}
  +support: G.Offer = G.Offer{1,0,1}
  +unrelated: G.Offer = G.Offer{0,(C.witness_weapon() + 1 : U32),1}
  do IO<Unit>:
    expect(rerolled(C.reward_action([heal,support],twoSteps)),"known two-step recipe path takes priority over optional support")
    expect(chosen(1,C.reward_action([heal,support],twoStepsShort)),"insufficient charges preserve rerolls and take useful support")
    expect(chosen(0,C.reward_action([heal,unrelated],maxedMissing)),"unreachable recipe preserves charges and takes safe fallback")
def reroll_masks(+base: G.Run) -> IO(Unit):
  +oneStep = G.seeded_run(sample(8,0,1,base),9)
  +twoSteps = G.seeded_run(sample(8,0,2,base),4)
  +prerequisite: G.Offer = G.Offer{1,C.required_passive(),1}
  +banned = G.banish_offer(twoSteps,G.Offer{1,C.required_passive(),1})
  do IO<Unit>:
    expect(chosen(0,C.reward_action([prerequisite],oneStep)),"already offered recipe does not waste a reroll")
    expect(Bool.not(C.reroll_reaches_recipe(2n,C.seed(banned),banned)),"forecast honors actual ban masks")
def chest_gating(+base: G.Run) -> IO(Unit):
  +missing = sample(7,0,2,base)
  +maxedMissing = sample(8,0,2,base)
  +ready = sample(8,1,2,base)
  +evolved = sample(9,1,2,base)
  do IO<Unit>:
    expect(Bool.not(C.chest_ready(missing)),"unmaxed starter retains chest goals")
    expect(Bool.not(C.chest_ready(maxedMissing)),"maxed starter without actual recipe retains chest goals")
    expect(C.chest_ready(ready),"engine evolution offer releases chest goals")
    expect(C.chest_ready(evolved),"already evolved build keeps chests available")
def chest_filter(unit: Unit) -> IO(Unit):
  +enemy: G.Body = G.Body{10.0,20.0,0,0,5,5,0,1,6.0}
  +chest: G.Body = G.Body{30.0,40.0,5,0,0,0,0,2,6.0}
  +xp: G.Body = G.Body{50.0,60.0,2,0,7,123,0,3,6.0}
  do IO<Unit>:
    expect(String.eq(G.rows_json(C.movement_rows(False{},[enemy,chest,xp])),G.rows_json([enemy,xp])),"deferring chest goals preserves other observations and their order")
    expect(String.eq(G.rows_json(C.movement_rows(True{},[enemy,chest,xp])),G.rows_json([enemy,chest,xp])),"ready planner receives every observed body unchanged")
def main() -> IO(Unit):
  +base = observed_run(C.configured(G.start(2,364304237)))
  do IO<Unit>:
    reward_priorities(base)
    support_capacity(base)
    reroll_availability(base)
    reroll_reachability(base)
    reroll_masks(base)
    chest_gating(base)
    chest_filter(Unit{})
