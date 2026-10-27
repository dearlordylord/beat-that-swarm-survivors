import Base
import native-economy.bend as N
import native-profile-codec.bend as Codec
import menu-progression.bend as P
import menu-amount.bend as A
import coop-session.bend as S

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)

def entries() -> List<&2,P.UnlockEntry>:
  [P.UnlockEntry{0,A.zero(),None{}},P.UnlockEntry{1,A.zero(),None{}},P.UnlockEntry{2,A.zero(),None{}},P.UnlockEntry{3,A.zero(),None{}},P.UnlockEntry{4,A.zero(),None{}},P.UnlockEntry{5,A.zero(),None{}},P.UnlockEntry{6,A.zero(),None{}}]
def catalog() -> P.Catalog:
  P.Catalog{entries(),[P.UnlockEntry{0,A.zero(),None{}}],[0],[],[P.Upgrade{0,100n,5n}],[],[],[P.Achievement{"heroes",[P.Condition{P.Characters{},A.natural(7n)}]},P.Achievement{"champions",[P.Condition{P.CharacterWins{},A.natural(7n)}]}]}
def native_legacy() -> N.Profile:
  N.put(N.put(N.put(N.put(N.put(N.put(N.put(N.fresh(),0,1234),1,3),11,191),15,191),26,8),31,8),13,524288)
def browser_legacy() -> P.Progress:
  +p0 = P.set_wonCharacters(P.set_characters(P.fresh(),[0,1,2,3,4,5,7,7]),[0,1,2,3,4,5,7,7])
  +p1 = P.set_profile_stat(P.set_profile_stat(p0,P.Characters{},A.natural(8n)),P.CharacterWins{},A.natural(8n))
  P.set_recorded(P.set_achievements(P.set_meta(P.set_gold(p1,A.natural(1234n)),[3n]),["old-achievement"]),["old-receipt"])

def main() -> IO(Unit):
  +native = Codec.decode(Codec.encode(native_legacy()))
  +browser = P.normalize(browser_legacy(),catalog())
  do IO<Unit>:
    expect(Bool.and(U32.is_eq(N.get(native,11),63),U32.is_eq(N.get(native,15),63)),"native decode removes retired ownership and wins")
    expect(Bool.and(U32.is_eq(N.get(native,26),6),U32.is_eq(N.get(native,31),6)),"native decode rebuilds character counts")
    expect(Bool.and(U32.is_eq(N.gold(native),1234),Bool.and(U32.is_eq(N.rank(native,0),3),N.achievement(native,19))),"native decode preserves wallet upgrades and earned achievements")
    expect(Bool.and(Bool.not(N.qualifies(native,14)),Bool.not(N.qualifies(native,19))),"retired native slot cannot complete seven-member achievements")
    expect(Bool.and(Bool.not(P.contains_id(P.progress_characters(browser),7)),Bool.not(P.contains_id(P.progress_wonCharacters(browser),7))),"browser normalization removes retired ownership and wins")
    expect(Bool.and(A.equal(P.stat(P.Characters{},P.progress_stats(browser)),A.natural(6n)),A.equal(P.stat(P.CharacterWins{},P.progress_stats(browser)),A.natural(6n))),"browser normalization rebuilds deduplicated character counts")
    expect(Bool.and(A.equal(P.progress_gold(browser),A.natural(1234n)),Bool.and(Nat.is_eq(P.rank_at(P.progress_meta(browser),0n),3n),Bool.and(P.contains_text(P.progress_achievements(browser),"old-achievement"),P.contains_text(P.progress_recorded(browser),"old-receipt")))),"browser normalization preserves wallet upgrades achievements and receipts")
    expect(Bool.and(Bool.not(P.contains_text(P.progress_achievements(P.award(browser,catalog())),"heroes")),Bool.not(P.contains_text(P.progress_achievements(P.award(browser,catalog())),"champions"))),"retired browser slot cannot complete seven-member achievements")
    expect(Bool.and(N.qualifies(N.put(native,26,7),14),N.qualifies(N.put(native,31,7),19)),"native achievements accept all seven current members")
    expect(P.contains_text(P.progress_achievements(P.award(P.normalize(P.set_characters(browser,[0,1,2,3,4,5,6]),catalog()),catalog())),"heroes"),"browser achievement accepts all seven current members")
    expect(Bool.not(N.allowed(N.put(native,11,255),2,7)),"native admission refuses retired eighth even with stale ownership")
    expect(Bool.and(S.action_allowed(S.Setup{6,0,0,16777215}),Bool.not(S.action_allowed(S.Setup{7,0,0,16777215}))),"co-op admits seventh character and refuses retired eighth")
    return Unit{}
