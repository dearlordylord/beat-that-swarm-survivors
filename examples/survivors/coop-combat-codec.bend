import run-state.bend as RS
import Base
import game-components.bend as Components
import ./game.bend as G
import ./projectile-pool.bend as SP
import ./body-index.bend as BI

# Shared detached combat data only: projectile birth identities and the native
# Bend JSON ABI. There is no weapon-only simulation or trajectory retention.
def birth_at(births:BI.Index<U32>,tick:U32,+snapshot:G.Snapshot) -> U32:
  BI.get(~U32,births,G.snapshot_identity(snapshot),(tick - G.snapshot_age(snapshot) : U32))
def birth_entry(+snapshot:G.Snapshot,+tick:U32,+prior:BI.Index<U32>,fresh:BI.Index<U32>,index:BI.Index<U32>) -> BI.Index<U32>:
  BI.insert(~U32,index,G.snapshot_identity(snapshot),BI.get(~U32,fresh,G.snapshot_identity(snapshot),birth_at(prior,tick,snapshot)))
def birth_map(rows:List<&2,G.Snapshot>,+tick:U32,+prior:BI.Index<U32>,+fresh:BI.Index<U32>,index:BI.Index<U32>) -> BI.Index<U32>:
  match rows:
    case []: index
    case head <> tail: birth_map(tail,tick,prior,fresh,birth_entry(head,tick,prior,fresh,index))

def assignment_births(index:BI.Index<SP.Request>,+tick:U32) -> BI.Index<U32>:
  match index:
    case BI.Empty{}: BI.Empty{}
    case BI.Item{seed,_}: BI.Item{seed,tick}
    case BI.Fork{sample,mask,zero,one}: BI.Fork{sample,mask,assignment_births(zero,tick),assignment_births(one,tick)}

def plan_births(plan:SP.Plan,tick:U32) -> BI.Index<U32>:
  match plan:
    case SP.Plan{index,_}: assignment_births(index,tick)

def native_nums(rows:List<&2,U32>) -> String:
  match rows:
    case []: "{\"$\":\"Nil\"}"
    case head <> tail: "{\"$\":\"Con\",\"head\":" ++ U32.show(head) ++ ",\"tail\":" ++ native_nums(tail) ++ "}"

def native_session(value:RS.Session) -> String:
  match value:
    case RS.Session{phase,tick,xp,xpNeed,level,kills,gold,seed,stage,bosses,mode,enemyKinds,relicCollected}: "{\"$\":\"Session\"" ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"xp\":" ++ U32.show(xp) ++ ",\"xpNeed\":" ++ U32.show(xpNeed) ++ ",\"level\":" ++ U32.show(level) ++ ",\"kills\":" ++ U32.show(kills) ++ ",\"gold\":" ++ U32.show(gold) ++ ",\"seed\":" ++ U32.show(seed) ++ ",\"stage\":" ++ U32.show(stage) ++ ",\"bosses\":" ++ U32.show(bosses) ++ ",\"mode\":" ++ U32.show(mode) ++ ",\"enemyKinds\":" ++ native_nums(enemyKinds) ++ ",\"relicCollected\":" ++ U32.show(relicCollected) ++ "}"

def native_personal(value:RS.PlayerState) -> String:
  match value:
    case RS.PlayerState{px,py,hp,maxHp,character,weapons,passives,invuln,arcana,meta,revivals,rerolls,banishes,skips,bannedWeapons,bannedPassives}: "{\"$\":\"PlayerState\"" ++ ",\"px\":" ++ F32.show(px) ++ ",\"py\":" ++ F32.show(py) ++ ",\"hp\":" ++ U32.show(hp) ++ ",\"maxHp\":" ++ U32.show(maxHp) ++ ",\"character\":" ++ U32.show(character) ++ ",\"weapons\":" ++ native_nums(weapons) ++ ",\"passives\":" ++ native_nums(passives) ++ ",\"invuln\":" ++ U32.show(invuln) ++ ",\"arcana\":" ++ U32.show(arcana) ++ ",\"meta\":" ++ U32.show(meta) ++ ",\"revivals\":" ++ U32.show(revivals) ++ ",\"rerolls\":" ++ U32.show(rerolls) ++ ",\"banishes\":" ++ U32.show(banishes) ++ ",\"skips\":" ++ U32.show(skips) ++ ",\"bannedWeapons\":" ++ U32.show(bannedWeapons) ++ ",\"bannedPassives\":" ++ U32.show(bannedPassives) ++ "}"

def native_run(value:G.Run) -> String:
  match value:
    case G.Run{session,personal}: "{\"$\":\"Run\",\"session\":" ++ native_session(session) ++ ",\"player\":" ++ native_personal(personal) ++ "}"

def native_body(value:Components.Body) -> String:
  match value:
    case Components.Body{x,y,kind,variant,hp,maxHp,age,seed,radius}: "{\"$\":\"Body\"" ++ ",\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"kind\":" ++ U32.show(kind) ++ ",\"variant\":" ++ U32.show(variant) ++ ",\"hp\":" ++ U32.show(hp) ++ ",\"maxHp\":" ++ U32.show(maxHp) ++ ",\"age\":" ++ U32.show(age) ++ ",\"seed\":" ++ U32.show(seed) ++ ",\"radius\":" ++ F32.show(radius) ++ "}"

def native_births(index:BI.Index<U32>) -> String:
  match index:
    case BI.Empty{}: "{\"$\":\"Empty\"}"
    case BI.Item{key,value}: "{\"$\":\"Item\",\"key\":" ++ U32.show(key) ++ ",\"value\":" ++ U32.show(value) ++ "}"
    case BI.Fork{sample,mask,zero,one}: "{\"$\":\"Fork\",\"sample\":" ++ U32.show(sample) ++ ",\"mask\":" ++ U32.show(mask) ++ ",\"zero\":" ++ native_births(zero) ++ ",\"one\":" ++ native_births(one) ++ "}"
