import Base
import ../native-economy.bend as P
import ../native-record.bend as R
import ../proof-facts.bend as F
import LAWS.bend as Laws

def Laws.receipt_stamp_exact(values,oldSeed,oldSettled,seed): {==}
def fresh_settle(+profile: P.Profile,+paid: P.Profile,+seed: U32,+active: Bool,+seen: Bool,terminal: {True{} == active : Bool},unseen: {False{} == seen : Bool}) -> {P.choose(active,P.choose(seen,profile,P.stamp(paid,seed)),profile) == P.stamp(paid,seed) : P.Profile}:
  %terminal : {P.choose(_,P.choose(seen,profile,P.stamp(paid,seed)),profile) == P.stamp(paid,seed) : P.Profile}
  %unseen : {P.choose(_,profile,P.stamp(paid,seed)) == P.stamp(paid,seed) : P.Profile}
  {==}
def Laws.fresh_terminal_records(profile,receipt,terminal,unseen):
  fresh_settle(profile,R.payment(profile,receipt),R.run_seed(receipt),R.terminal(receipt),P.seen(profile,R.run_seed(receipt)),terminal,unseen)
def stamped_settle(+seed: U32,+paid: P.Profile,+next: P.Profile) -> {P.settle(True{},seed,P.stamp(paid,seed),next) == P.stamp(paid,seed) : P.Profile}:
  match paid:
    case P.Profile{+values,_,_}:
      %Equal.sym(Bool,U32.is_eq(seed,seed),True{},F.u32_eq_refl(seed)) : {P.choose(_,P.Profile{values,seed,True{}},P.stamp(next,seed)) == P.Profile{values,seed,True{}} : P.Profile}
      {==}
def settle_branch(active: Bool,seen: Bool,+seed: U32,+profile: P.Profile,+paid: P.Profile,+next: P.Profile,condition: {seen == P.seen(profile,seed) : Bool}) -> {P.settle(active,seed,P.choose(active,P.choose(seen,profile,P.stamp(paid,seed)),profile),next) == P.choose(active,P.choose(seen,profile,P.stamp(paid,seed)),profile) : P.Profile}:
  match active seen:
    case False{} _: {==}
    case True{} True{}:
      %condition : {P.choose(_,profile,P.stamp(next,seed)) == profile : P.Profile}
      {==}
    case True{} False{}: stamped_settle(seed,paid,next)
def settle_idempotent(+active: Bool,+seed: U32,+profile: P.Profile,+paid: P.Profile,+next: P.Profile) -> {P.settle(active,seed,P.settle(active,seed,profile,paid),next) == P.settle(active,seed,profile,paid) : P.Profile}:
  settle_branch(active,P.seen(profile,seed),seed,profile,paid,next,{==})
def Laws.public_record_idempotent(profile,receipt):
  settle_idempotent(R.terminal(receipt),R.run_seed(receipt),profile,R.payment(profile,receipt),R.payment(R.record(profile,receipt),receipt))
def Laws.nonterminal_preserves(profile,receipt,active):
  %active : {P.choose(_,P.choose(P.seen(profile,R.run_seed(receipt)),profile,P.stamp(R.payment(profile,receipt),R.run_seed(receipt))),profile) == profile : P.Profile}
  {==}
def gold_written(+profile: P.Profile,+gold: U32) -> {P.gold(P.set_gold(profile,gold)) == gold : U32}:
  match profile:
    case P.Profile{_,_,_}: {==}
def Laws.payment_gold_exact(profile,receipt):
  gold_written(P.award(R.record_stats(profile,receipt)),(P.gold(profile) + R.gained(receipt) : U32))
