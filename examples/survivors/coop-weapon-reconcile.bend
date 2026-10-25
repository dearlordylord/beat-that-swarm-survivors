import Base
import ./game.bend as G
import ./coop-weapon-prediction.bend as W
import ./body-index.bend as BI
import ./coop-prediction.bend as P
import ./coop-weapon-prediction-policy.bend as Kernel

# Reconciliation of detached weapon visuals, never of the authoritative world.
# A continuing generation keeps its already displayed trajectory. Replaying a
# newer aiming observation may introduce new births, but cannot teleport a shot
# that the player has already seen leave the weapon.
def lane(snapshot:G.Snapshot) -> U32:
  match snapshot:
    case G.Snapshot{_,G.Motion{_,_,_,_,_,_,_,owner,slot}}: (owner * 65536 + slot % 65536 : U32)
def physical_seed(snapshot:G.Snapshot) -> U32:
  match snapshot:
    case G.Snapshot{G.Body{_,_,_,_,_,_,_,seed,_},_}: seed

def replace_inner(fuel:Nat,index:BI.Index<BI.Index<G.Snapshot>>,+birth:U32,+value:BI.Index<G.Snapshot>,one:Bool) -> BI.Index<BI.Index<G.Snapshot>>:
  match fuel index one:
    case _ BI.Empty{} _: BI.Item{birth,value}
    case _ BI.Item{+key,old} _: Bool.pick(BI.Index<BI.Index<G.Snapshot>>,U32.is_eq(key,birth),BI.Item{birth,value},BI.insert(~BI.Index<G.Snapshot>,BI.Item{key,old},birth,value))
    case 0n index _: index
    case 1n+rest BI.Fork{sample,mask,+zero,one} False{}: BI.Fork{sample,mask,replace_inner(rest,zero,birth,value,BI.branch(~BI.Index<G.Snapshot>,zero,birth)),one}
    case 1n+rest BI.Fork{sample,mask,zero,+one} True{}: BI.Fork{sample,mask,zero,replace_inner(rest,one,birth,value,BI.branch(~BI.Index<G.Snapshot>,one,birth))}

def store_inner(found:Maybe<&2,BI.Index<G.Snapshot>>,+index:BI.Index<BI.Index<G.Snapshot>>,+born:U32,+value:BI.Index<G.Snapshot>) -> BI.Index<BI.Index<G.Snapshot>>:
  match found:
    case None{}: BI.insert(~BI.Index<G.Snapshot>,index,born,value)
    case Some{_}: replace_inner(32n,index,born,value,BI.branch(~BI.Index<G.Snapshot>,index,born))
def index_one(+index:BI.Index<BI.Index<G.Snapshot>>,+tick:U32,births:BI.Index<U32>,+snapshot:G.Snapshot) -> BI.Index<BI.Index<G.Snapshot>>:
  +born = W.birth_at(births,tick,snapshot)
  inner = BI.get(~BI.Index<G.Snapshot>,index,born,BI.Empty{})
  store_inner(BI.find(~BI.Index<G.Snapshot>,index,born),index,born,BI.insert(~G.Snapshot,inner,lane(snapshot),snapshot))
def index_rows(rows:List<&2,G.Snapshot>,+tick:U32,+births:BI.Index<U32>,index:BI.Index<BI.Index<G.Snapshot>>) -> BI.Index<BI.Index<G.Snapshot>>:
  match rows:
    case []: index
    case head <> tail: index_rows(tail,tick,births,index_one(index,tick,births,head))

def reseed(snapshot:G.Snapshot,seed:U32) -> G.Snapshot:
  match snapshot:
    case G.Snapshot{G.Body{x,y,kind,variant,hp,maximum,age,_,radius},motion}: G.Snapshot{G.Body{x,y,kind,variant,hp,maximum,age,seed,radius},motion}
def retain(previous:G.Snapshot,fresh:G.Snapshot) -> G.Snapshot: reseed(previous,physical_seed(fresh))
def choose(previous:Maybe<&2,G.Snapshot>,fresh:G.Snapshot) -> G.Snapshot:
  Kernel.prefer_existing(~G.Snapshot,~retain,previous,fresh)
def merge_one(index:BI.Index<BI.Index<G.Snapshot>>,+tick:U32,births:BI.Index<U32>,+fresh:G.Snapshot) -> G.Snapshot:
  choose(BI.find(~G.Snapshot,BI.get(~BI.Index<G.Snapshot>,index,W.birth_at(births,tick,fresh),BI.Empty{}),lane(fresh)),fresh)
def merge_rows(rows:List<&2,G.Snapshot>,+tick:U32,+births:BI.Index<U32>,+index:BI.Index<BI.Index<G.Snapshot>>) -> List<&2,G.Snapshot>:
  match rows:
    case []: []
    case head <> tail: merge_one(index,tick,births,head) <> merge_rows(tail,tick,births,index)

# An ACK changes the authoritative anchor, not the local presentation clock.
# Existing trajectories have already advanced on local fixed ticks. Advancing
# them again to a received world clock would turn a packet burst into a jump.
def rebase_rows(+player:U32,+run:G.Run,fresh:List<&2,G.Snapshot>,targets:List<&2,G.Body>,ids:List<&2,U32>,+births:BI.Index<U32>,previous:W.Frame) -> W.Frame:
  match previous:
    case W.Frame{_,+priorRun,priorShots,_,_,priorBirths}: W.Frame{player,run,merge_rows(fresh,G.run_tick(run),births,index_rows(priorShots,G.run_tick(priorRun),priorBirths,BI.Empty{})),targets,ids,births}
def rebase_allowed(allowed:Bool,previous:W.Frame,+fresh:W.Frame) -> W.Frame:
  match allowed fresh:
    case False{} _: fresh
    case True{} W.Frame{player,run,shots,targets,ids,births}: rebase_rows(player,run,shots,targets,ids,births,previous)
def compatible(previous:W.Frame,fresh:W.Frame) -> Bool:
  match previous fresh:
    case W.Frame{prior,+priorRun,_,_,_,_} W.Frame{player,+run,_,_,_,_}:
      Bool.and(U32.is_eq(prior,player),Bool.and(U32.is_eq(G.run_stage(priorRun),G.run_stage(run)),Bool.and(U32.is_le(G.run_tick(priorRun),G.run_tick(run)),U32.is_le((G.run_tick(run) - G.run_tick(priorRun) : U32),P.horizon()))))
def rebase(+previous:W.Frame,+fresh:W.Frame) -> W.Frame:
  rebase_allowed(compatible(previous,fresh),previous,fresh)
