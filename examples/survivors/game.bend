import Base
import projectile.bend as P
import encounters.bend as E
import actors.bend as A
import spawn-policy.bend as S
import persistent-xp.bend as X
import body-index.bend as BI
import bendvy-ecs-core@0.1.0.1/world.bend as W
import bendvy-ecs-core@0.1.0.1/column.bend as Col
import bendvy-ecs-core@0.1.0.1/component.bend as C
import bendvy-ecs-core@0.1.0.1/commands.bend as Cmd
import bendvy-ecs-core@0.1.0.1/transaction.bend as T
import bendvy-ecs-core@0.1.0.1/compose.bend as Q
import bendvy-ecs-core@0.1.0.1/capabilities.bend as Cap

type Schema is Data: Schema{}
# Frame kinds: enemy0, player shot1, XP2, gold3, heal4, chest5, hostile shot7.
# Dormant8 never renders. Body health values are frame observations; Vitals owns enemy health.
type Body is Data: Body{x: F32,y: F32,kind: U32,variant: U32,hp: U32,maxHp: U32,age: U32,seed: U32,radius: F32}
type Vitals is Data: Vitals{health: U32,maximum: U32}
type VitalToken is Data: VitalToken{}
type Token is Data: Token{}
type Motion is Data: Motion{vx: F32,vy: F32,life: U32,pierce: U32,visited: List<&2,U32>,slow: U32,burn: U32}
type MotionToken is Data: MotionToken{}
type BodyRest is Type: BodyRest{vitals: Col.Column<Schema,Vitals>,motions: Col.Column<Schema,Motion>}
type VitalRest is Type: VitalRest{bodies: Col.Column<Schema,Body>,motions: Col.Column<Schema,Motion>}
type MotionRest is Type: MotionRest{bodies: Col.Column<Schema,Body>,vitals: Col.Column<Schema,Vitals>}
type Store is Type: Store{bodies: Col.Column<Schema,Body>,vitals: Col.Column<Schema,Vitals>,motions: Col.Column<Schema,Motion>}
def take(store: Store) -> BodyRest & Col.Column<Schema,Body>:
  match store:
    case Store{bodies,vitals,motions}: (BodyRest{vitals,motions},bodies)
def put(rest: BodyRest,bodies: Col.Column<Schema,Body>) -> Store:
  match rest:
    case BodyRest{vitals,motions}: Store{bodies,vitals,motions}
def project(body: Body) -> Body & Body:
  match body:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}: (Body{x,y,kind,variant,hp,maxHp,age,seed,radius},Body{x,y,kind,variant,hp,maxHp,age,seed,radius})
def family() -> C.Family<Schema,Store,BodyRest,Body,Body,Token,take,put,project>: C.Family{"body"}
def empty(unit: Unit) -> Store: Store{Col.empty_indexed(~Schema,~Body),Col.empty_indexed(~Schema,~Vitals),Col.empty_indexed(~Schema,~Motion)}
def World() -> Type: W.World<Schema,Store,Unit,Unit>
def take_vitals(store: Store) -> VitalRest & Col.Column<Schema,Vitals>:
  match store:
    case Store{bodies,vitals,motions}: (VitalRest{bodies,motions},vitals)
def put_vitals(rest: VitalRest,vitals: Col.Column<Schema,Vitals>) -> Store:
  match rest:
    case VitalRest{bodies,motions}: Store{bodies,vitals,motions}
def project_vitals(vitals: Vitals) -> Vitals & Vitals:
  match vitals:
    case Vitals{+health,+maximum}: (Vitals{health,maximum},Vitals{health,maximum})
def vital_family() -> C.Family<Schema,Store,VitalRest,Vitals,Vitals,VitalToken,take_vitals,put_vitals,project_vitals>: C.Family{"vitals"}
def take_motion(store: Store) -> MotionRest & Col.Column<Schema,Motion>:
  match store:
    case Store{bodies,vitals,motions}: (MotionRest{bodies,vitals},motions)
def put_motion(rest: MotionRest,motions: Col.Column<Schema,Motion>) -> Store:
  match rest:
    case MotionRest{bodies,vitals}: Store{bodies,vitals,motions}
def project_motion(motion: Motion) -> Motion & Motion:
  match motion:
    case Motion{+vx,+vy,+life,+pierce,+visited,+slow,+burn}: (Motion{vx,vy,life,pierce,visited,slow,burn},Motion{vx,vy,life,pierce,visited,slow,burn})
def motion_family() -> C.Family<Schema,Store,MotionRest,Motion,Motion,MotionToken,take_motion,put_motion,project_motion>: C.Family{"motion"}
def empty_motion() -> Motion: Motion{0.0,0.0,0,0,[],0,0}
def populate_result(result: C.Replacement<World(),Body>) -> World():
  match result:
    case C.Replaced{world,_}: world
    case C.ReplaceRejected{world,_,_}: world
def populate_body(world: World(),handle: W.Handle<Schema>,body: Body) -> World():
  populate_result(C.structural_replace(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,family(),world,handle,Some{body}))
def vital_populated(result: C.Replacement<World(),Vitals>) -> World():
  match result:
    case C.Replaced{world,_}: world
    case C.ReplaceRejected{world,_,_}: world
def populate_shared(world: World(),+handle: W.Handle<Schema>,body: Body) -> World():
  match body:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}:
      vital_populated(C.structural_replace(~Schema,~Store,~Unit,~Unit,~VitalRest,~Vitals,~Vitals,~VitalToken,~take_vitals,~put_vitals,~project_vitals,vital_family(),populate_body(world,handle,Body{x,y,kind,variant,hp,maxHp,age,seed,radius}),handle,Some{Vitals{hp,maxHp}}))
def motion_populated(result: C.Replacement<World(),Motion>) -> World():
  match result:
    case C.Replaced{world,_}: world
    case C.ReplaceRejected{world,_,_}: world
def populate_all(world: World(),+handle: W.Handle<Schema>,body: Body) -> World():
  motion_populated(C.structural_replace(~Schema,~Store,~Unit,~Unit,~MotionRest,~Motion,~Motion,~MotionToken,~take_motion,~put_motion,~project_motion,motion_family(),populate_shared(world,handle,body),handle,Some{empty_motion()}))
def populate(world: World(),handle: W.Handle<Schema>,body: Body) -> World(): populate_all(world,handle,body)
def spawn_finish(result: T.Tx<World(),Unit> & W.Reservation<Schema>) -> World():
  match result:
    case (T.Tx{world,_,commands,_,_},W.Reserved{_}): Cmd.enqueue(~Schema,~Store,~Unit,~Unit,world,commands)
    case (T.Tx{world,_,_,_,_},W.ReservationRejected{_}): world
def spawn(world: World(),body: Body) -> World():
  spawn_finish(Cmd.tx_spawn(~Schema,~Store,~Unit,~Unit,~Body,~populate,T.begin(~World(),~Unit,world),body))
# Enemy slots recycle independently of 256 persistent XP entries.
# Kind2 hp is exact baseXP; maxHp is the pile generation tick, not health.
# Weapons and progression are immutable run data; every entity update uses Q.each.
type Run is Data: Run{phase: U32,tick: U32,px: F32,py: F32,hp: U32,maxHp: U32,xp: U32,xpNeed: U32,level: U32,kills: U32,gold: U32,character: U32,weapons: List<&2,U32>,passives: List<&2,U32>,invuln: U32,seed: U32,stage: U32,arcana: U32,meta: U32,revivals: U32,bosses: U32,mode: U32,rerolls: U32,banishes: U32,skips: U32,bannedWeapons: U32,bannedPassives: U32,enemyKinds: List<&2,U32>,relicCollected: U32}
type Offer is Data: Offer{kind: U32,id: U32,level: U32}
type Snapshot is Data: Snapshot{body: Body,motion: Motion}
type State is Type: State{world: World(),run: Run,bodies: List<&2,Body>,offers: List<&2,Offer>,snapshots: List<&2,Snapshot>,pending: List<&2,U32>}
type Packet is Type: Packet{state: State,frame: String}
  Failed{error: String}
def at(values: List<&2,U32>,index: U32) -> U32:
  match values index:
    case Nil{} _: 0
    case Con{head,_} 0: head
    case Con{_,tail} index: at(tail,(index - 1 : U32))
def bump(values: List<&2,U32>,index: U32) -> List<&2,U32>:
  match values index:
    case Nil{} _: []
    case Con{head,tail} 0: (head + 1 : U32) <> tail
    case Con{head,tail} index: head <> bump(tail,(index - 1 : U32))
def set_at(values: List<&2,U32>,index: U32,+value: U32) -> List<&2,U32>:
  match values index:
    case Nil{} _: []
    case Con{_,rest} 0: value <> rest
    case Con{head,rest} index: head <> set_at(rest,(index - 1 : U32),value)
def dec(+value: U32) -> U32: U32.sub(value,U32.min(value,1))
def lose(+hp: U32,damage: U32) -> U32: U32.sub(hp,U32.min(hp,damage))
def distance2(+x: F32,+y: F32,+px: F32,+py: F32) -> F32: ((x - px) * (x - px) + (y - py) * (y - py) : F32)
def close(x: F32,y: F32,px: F32,py: F32,+radius: F32) -> Bool: F32.is_le(distance2(x,y,px,py),(radius * radius : F32))
def wave(+tick: U32) -> U32: (tick / 3600 : U32)
def angle(+seed: U32) -> F32: (U32.to_f32(((seed * 2399 + 71) % 6283 : U32)) / 1000.0 : F32)
# Early growth is quick; quadratic later costs prevent serial upgrade interruptions.
def next_xp_need(+level: U32) -> U32: (100 + level * 3 + level * level / 3 : U32)
def enemy_at(point: S.Point,+seed: U32,+tick: U32,+variant: U32,+stage: U32,+curse: U32) -> Body:
  match point:
    case S.Point{x,y}: Body{x,y,0,variant,(U32.max(E.health(variant,tick,stage),(10000000 * Bool.to_u32(U32.is_eq(variant,30)) : U32)) * (100 + curse) / 100 : U32),(U32.max(E.health(variant,tick,stage),(10000000 * Bool.to_u32(U32.is_eq(variant,30)) : U32)) * (100 + curse) / 100 : U32),0,seed,E.radius(variant)}
def enemy_new(+seed: U32,+tick: U32,px: F32,py: F32,+variant: U32,stage: U32,curse: U32) -> Body:
  enemy_at(S.choose(seed,tick,px,py,E.radius(variant)),seed,tick,variant,stage,curse)
# Entity seeds remain stable pool identities; run entropy changes only spawn placement.
def enemy_new_seed(+slot: U32,+entropy: U32,+tick: U32,px: F32,py: F32,+variant: U32,stage: U32,curse: U32) -> Body:
  enemy_at(S.choose((slot + (entropy - 12345) * 31 : U32),tick,px,py,E.radius(variant)),slot,tick,variant,stage,curse)
# A 512-slot enemy budget grows from 96 to the full horde by six minutes.
def active_limit(+tick: U32) -> U32: U32.min(512,(96 + tick / 50 : U32))
def initial_body(+slot: U32) -> Body: Body{0.0,0.0,8,slot,0,0,slot,slot,0.0}
def boot_pool(remaining: Nat,+slot: U32,world: World()) -> World():
  match remaining:
    case 0n: world
    case 1n+rest: boot_pool(rest,(slot + 1 : U32),spawn(world,initial_body(slot)))
def body_json(body: Body) -> String:
  match body:
    case Body{x,y,kind,variant,hp,maxHp,age,seed,radius}: "[" ++ F32.show(x) ++ "," ++ F32.show(y) ++ "," ++ U32.show(kind) ++ "," ++ U32.show(variant) ++ "," ++ U32.show(hp) ++ "," ++ U32.show(maxHp) ++ "," ++ U32.show(age) ++ "," ++ U32.show(seed) ++ "," ++ F32.show(radius) ++ "]"
def rows_json(rows: List<&2,Body>) -> String:
  match rows:
    case []: ""
    case body <> []: body_json(body)
    case body <> rest: body_json(body) ++ "," ++ rows_json(rest)
def nums_json(rows: List<&2,U32>) -> String:
  match rows:
    case []: ""
    case n <> []: U32.show(n)
    case n <> rest: U32.show(n) ++ "," ++ nums_json(rest)
def offer_json(offer: Offer) -> String:
  match offer:
    case Offer{kind,id,level}: "{\"kind\":" ++ U32.show(kind) ++ ",\"id\":" ++ U32.show(id) ++ ",\"level\":" ++ U32.show(level) ++ "}"
def offers_json(rows: List<&2,Offer>) -> String:
  match rows:
    case []: ""
    case o <> []: offer_json(o)
    case o <> rest: offer_json(o) ++ "," ++ offers_json(rest)
def visible_bodies(rows: List<&2,Body>) -> List<&2,Body>:
  match rows:
    case []: []
    case Body{_,_,8,_,_,_,_,_,_} <> rest: visible_bodies(rest)
    case body <> rest: body <> visible_bodies(rest)
def relic_x(stage: U32) -> F32: U32.to_f32(at([2400,1800,1200,1800,2400],stage))
def relic_y(stage: U32) -> F32: U32.to_f32(at([1800,1200,1800,2400,2400],stage))
def run_length(mode: U32) -> U32:
  match mode:
    case 3: 18000
    case _: 36000
def wave_tick(+mode: U32,tick: U32) -> U32: (tick * (1 + Bool.to_u32(U32.is_eq(mode,3))) : U32)
def packet(state: State) -> Packet:
  match state:
    case State{world,Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,+pending}:
      Packet{State{world,Run{phase,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending},"{\"relicCollected\":" ++ U32.show(relicCollected) ++ ",\"relicX\":" ++ F32.show(relic_x(stage)) ++ ",\"relicY\":" ++ F32.show(relic_y(stage)) ++ ",\"runLength\":" ++ U32.show(run_length(mode)) ++ ",\"enemiesKilled\":[" ++ nums_json(enemyKinds) ++ "],\"mode\":" ++ U32.show(mode) ++ ",\"rerolls\":" ++ U32.show(rerolls) ++ ",\"banishes\":" ++ U32.show(banishes) ++ ",\"skips\":" ++ U32.show(skips) ++ ",\"stage\":" ++ U32.show(stage) ++ ",\"arcana\":" ++ U32.show(arcana) ++ ",\"revivalsUsed\":" ++ U32.show(revivals) ++ ",\"bossesKilled\":" ++ U32.show(bosses) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"px\":" ++ F32.show(px) ++ ",\"py\":" ++ F32.show(py) ++ ",\"hp\":" ++ U32.show(hp) ++ ",\"maxHp\":" ++ U32.show(maxHp) ++ ",\"xp\":" ++ U32.show(xp) ++ ",\"xpNeed\":" ++ U32.show(need) ++ ",\"level\":" ++ U32.show(level) ++ ",\"kills\":" ++ U32.show(kills) ++ ",\"gold\":" ++ U32.show(gold) ++ ",\"character\":" ++ U32.show(character) ++ ",\"weapons\":[" ++ nums_json(weapons) ++ "],\"passives\":[" ++ nums_json(passives) ++ "],\"offers\":[" ++ offers_json(offers) ++ "],\"bodies\":[" ++ rows_json(visible_bodies(bodies)) ++ "]}"}
def meta_max(id: U32) -> U32:
  match id:
    case 3: 3
    case 9: 2
    case _: 5
def meta_rank(+meta: U32,+id: U32) -> U32: U32.min(meta_max(id),(U32.shrn(meta,U32.to_nat((id * 3 : U32))) % 8 : U32))
def starter(character: U32) -> U32: at([0,1,4,8,2,10,15,21],(character % 8 : U32))
def character_health(character: U32) -> U32:
  match character:
    case 4: 125
    case _: 100
def initial_health(+character: U32,+meta: U32) -> U32: (character_health(character) * (100 + meta_rank(meta,1) * 10) / 100 : U32)
def stat_bonus(+arcana: U32,+wanted: U32) -> F32: U32.to_f32(Bool.to_u32(U32.is_eq(arcana,wanted)))
def speed_bonus(+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> F32:
  ((1.0 + U32.to_f32(at(passives,5)) * 0.10 + U32.to_f32(meta_rank(meta,5)) * 0.05 + 0.15 * U32.to_f32(Bool.to_u32(U32.is_eq(character,1))) + 0.30 * stat_bonus(arcana,10)) * (1.0 - 0.15 * stat_bonus(arcana,2)) : F32)
def configured(run: Run,+selectedStage: U32,+selectedArcana: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,_,_,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}:
      Run{phase,tick,px,py,F32.to_u32((U32.to_f32(initial_health(character,meta)) * (1.0 - 0.30 * stat_bonus(selectedArcana,0) + 0.25 * stat_bonus(selectedArcana,9)) : F32)),F32.to_u32((U32.to_f32(initial_health(character,meta)) * (1.0 - 0.30 * stat_bonus(selectedArcana,0) + 0.25 * stat_bonus(selectedArcana,9)) : F32)),xp,need,level,kills,gold,character,weapons,passives,invuln,seed,U32.min(selectedStage,4),U32.min(selectedArcana,11),meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def configure(state: State,+stageChoice: U32,+arcanaChoice: U32) -> Packet:
  match state:
    case State{world,Run{+phase,0,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,configured(Run{phase,0,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},stageChoice,arcanaChoice),bodies,offers,snapshots,pending})
    case state: packet(state)
def period(id: U32) -> U32:
  match id:
    case 0: 40
    case 1: 30
    case 2: 90
    case 3: 14
    case 4: 24
    case 5: 120
    case 6: 70
    case 7: 110
    case 8: 80
    case 9: 65
    case 10: 100
    case 11: 600
    case +id: (35 + (id % 6) * 13 : U32)
def lucky_kind(+seed: U32,+luck: U32) -> U32:
  (2 + Bool.to_u32(U32.is_eq((seed % U32.max(3,(1700 / (100 + luck * 10) : U32)) : U32),0)) + 2 * Bool.to_u32(Bool.and(Bool.not(U32.is_eq((seed % U32.max(3,(1700 / (100 + luck * 10) : U32)) : U32),0)),U32.is_eq((seed % U32.max(7,(4100 / (100 + luck * 10) : U32)) : U32),0))) : U32)
def normal_loot(+seed: U32) -> U32:
  (2 + Bool.to_u32(U32.is_eq((seed % 17 : U32),0)) + 2 * Bool.to_u32(Bool.and(Bool.not(U32.is_eq((seed % 17 : U32),0)),U32.is_eq((seed % 41 : U32),0))) : U32)
def loot_kind(+seed: U32,+variant: U32) -> U32:
  match variant:
    case 20: 5
    case 21: 5
    case 22: 5
    case 23: 5
    case 24: 5
    case 25: 5
    case 26: 5
    case 27: 5
    case 28: 5
    case 29: 5
    case _: normal_loot(seed)
type HitPlan is Data: HitPlan{shot: U32,weapon: U32,damage: U32,x: F32,y: F32,radius: F32,area: Bool,targets: List<&2,U32>}
type Args is Data: Args{run: Run,bodies: List<&2,Body>,dx: F32,dy: F32,snapshots: List<&2,Snapshot>,hits: List<&2,HitPlan>}
type Row is Data: Row{body: Body,hit: U32,xp: U32,gold: U32,heal: U32,chest: U32,killed: U32,relic: U32}
type Error is Data: MissingBody{}
type Ops<-H: Type> is Type: Ops{body: Cap.Read<H,Body>,vitals: Cap.Write<H,Vitals,Vitals>,motion: Cap.Write<H,Motion,Motion>}
def OpsType(H: Type) -> Type: Ops<H>
def body_cap(~H: Type,ops: Ops<H>) -> Cap.Read<H,Body>:
  match ops:
    case Ops{body,_,_}: body
def vital_cap(~H: Type,ops: Ops<H>) -> Cap.Write<H,Vitals,Vitals>:
  match ops:
    case Ops{_,vitals,_}: vitals
def motion_cap(~H: Type,ops: Ops<H>) -> Cap.Write<H,Motion,Motion>:
  match ops:
    case Ops{_,_,motion}: motion
def loot_collected(found: Bool,+body: Body,+kind: U32,+amount: U32) -> Row:
  match found body:
    case False{} body: Row{body,0,0,0,0,0,0,0}
    case True{} Body{+x,+y,_,+variant,_,+maxHp,_,+seed,_}: Row{Body{x,y,8,variant,0,maxHp,0,seed,0.0},0,X.credited(U32.is_eq(kind,2),amount),(amount * Bool.to_u32(U32.is_eq(kind,3)) : U32),(25 * Bool.to_u32(U32.is_eq(kind,4)) : U32),Bool.to_u32(U32.is_eq(kind,5)),0,0}
def pickup_radius(+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> F32:
  (24.0 * (1.0 + U32.to_f32(at(passives,8)) * 0.25 + U32.to_f32(meta_rank(meta,6)) * 0.15 + stat_bonus(arcana,6) + 0.50 * U32.to_f32(Bool.to_u32(U32.is_eq(character,7)))) : F32)
def loot_update(body: Body,run: Run) -> Row:
  match body run:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius} Run{_,_,+px,+py,_,_,_,_,_,_,_,+character,_,+passives,_,_,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}:
      loot_collected(Bool.or(close(x,y,px,py,pickup_radius(passives,meta,arcana,character)),Bool.and(Bool.or(U32.is_eq(kind,3),U32.is_eq(kind,4)),U32.is_le(120,age))),Body{x,y,kind,variant,hp,maxHp,(age + 1 : U32),seed,radius},kind,Bool.pick(U32,U32.is_eq(kind,2),hp,(2 + U32.min(4,(variant / 4 : U32)) : U32)))
def enemy_result(+hp: U32,+x: F32,+y: F32,+variant: U32,+maxHp: U32,+age: U32,+seed: U32,+radius: F32,+px: F32,+py: F32) -> Row:
  match hp:
    case 0: Row{Body{x,y,loot_kind(seed,variant),variant,0,maxHp,0,seed,6.0},0,0,0,0,0,1,0}
    case +hp: Row{Body{x,y,0,variant,hp,maxHp,age,seed,radius},(Bool.to_u32(close(x,y,px,py,(radius + 10.0 : F32))) * (1 + 1000 * Bool.to_u32(U32.is_eq(variant,30))) : U32),0,0,0,0,0,0}
def enemy_update(body: Body,run: Run) -> Row:
  match body run:
    case Body{+x,+y,_,+variant,+hp,+maxHp,+age,+seed,+radius} Run{_,_,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,+enemyKinds,+relicCollected}: Row{Body{x,y,0,variant,hp,maxHp,age,seed,radius},(Bool.to_u32(close(x,y,px,py,(radius + 10.0 : F32))) * (1 + 1000 * Bool.to_u32(U32.is_eq(variant,30))) : U32),0,0,0,0,0,0}
def admit_enemy(admission: S.Admission,candidate: Body,previous: Body) -> Row:
  match admission:
    case S.Admit{}: Row{candidate,0,0,0,0,0,0,0}
    case S.Reject{}: Row{previous,0,0,0,0,0,0,0}
def candidate_enemy(candidate: Body,previous: Body,px: F32,py: F32) -> Row:
  match candidate:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}:
      admit_enemy(S.admission(x,y,px,py,radius),Body{x,y,kind,variant,hp,maxHp,age,seed,radius},previous)
def dormant_spawn(active: Bool,+seed: U32,+entropy: U32,+tick: U32,+px: F32,+py: F32,+variant: U32,+stage: U32,+curse: U32,+body: Body) -> Row:
  match active:
    case True{}: candidate_enemy(enemy_new_seed(seed,entropy,tick,px,py,variant,stage,curse),body,px,py)
    case False{}: Row{body,0,0,0,0,0,0,0}
# Spawn cadence rejects five of six slots before evaluating wave limits or
# passive ranks. Variant and curse are only materialized for admitted spawns.
def dormant_admitted(active: Bool,+seed: U32,+body: Body,run: Run) -> Row:
  match active run:
    case False{} _: Row{body,0,0,0,0,0,0,0}
    case True{} Run{_,+tick,+px,+py,_,_,_,_,_,_,_,+character,_,+passives,_,+rng,+stage,+arcana,_,_,_,+mode,_,_,_,_,_,_,_}:
      dormant_spawn(True{},seed,(rng - tick + 1 : U32),wave_tick(mode,tick),px,py,E.variant(stage,wave_tick(mode,tick),seed),stage,(at(passives,14) * 10 + 35 * Bool.to_u32(U32.is_eq(mode,1)) + 20 * Bool.to_u32(U32.is_eq(arcana,5)) + 15 * Bool.to_u32(U32.is_eq(character,6)) : U32),body)
def dormant_scheduled(scheduled: Bool,+seed: U32,+body: Body,+run: Run) -> Row:
  match scheduled run:
    case False{} _: Row{body,0,0,0,0,0,0,0}
    case True{} Run{_,+tick,_,_,_,_,_,_,_,_,_,_,_,+passives,_,_,_,+arcana,_,_,_,+mode,_,_,_,_,_,_,_}:
      dormant_admitted(U32.is_lt((seed % 512 : U32),U32.min(512,(active_limit(wave_tick(mode,tick)) * (100 + at(passives,14) * 10 + 35 * Bool.to_u32(U32.is_eq(mode,1)) + 20 * Bool.to_u32(U32.is_eq(arcana,5))) / 100 : U32))),seed,body,run)
def dormant(body: Body,+run: Run) -> Row:
  match body run:
    case Body{+x,+y,_,+variant,_,+maxHp,+age,+seed,_} Run{_,+tick,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}:
      dormant_scheduled(U32.is_eq(((tick + seed) % 6 : U32),0),seed,Body{x,y,8,variant,0,maxHp,(age + 1 : U32),seed,0.0},run)
def update_body(body: Body,run: Run) -> Row:
  match body:
    case Body{+x,+y,0,+variant,+hp,+maxHp,+age,+seed,+radius}: enemy_update(Body{x,y,0,variant,hp,maxHp,age,seed,radius},run)
    case Body{+x,+y,8,+variant,+hp,+maxHp,+age,+seed,+radius}: dormant(Body{x,y,8,variant,hp,maxHp,age,seed,radius},run)
    case body: loot_update(body,run)
def boss_variant(finale: Bool,tick: U32,stage: U32) -> U32:
  match finale:
    case True{}: 30
    case False{}: (20 + stage * 2 + ((tick / 7200) % 2) : U32)
def update_selected(boss: Bool,finale: Bool,+body: Body,+run: Run,+seed: U32,+entropy: U32,+tick: U32,+px: F32,+py: F32,+stage: U32) -> Row:
  match boss:
    case True{}: candidate_enemy(enemy_new_seed(seed,entropy,tick,px,py,boss_variant(finale,tick,stage),stage,0),body,px,py)
    case False{}: update_body(body,run)
def update(body: Body,run: Run) -> Row:
  match body run:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius} Run{+phase,+tick,+px,+py,+playerHp,+playerMax,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+rng,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}:
      update_selected(Bool.and(U32.is_eq(seed,0),Bool.and(U32.is_lt(0,tick),Bool.or(Bool.and(Bool.or(U32.is_lt(wave_tick(mode,tick),36000),U32.is_eq(mode,2)),U32.is_eq((wave_tick(mode,tick) % 7200 : U32),0)),Bool.or(U32.is_eq(wave_tick(mode,tick),34200),U32.is_eq(wave_tick(mode,tick),36000))))),Bool.and(Bool.not(U32.is_eq(mode,2)),U32.is_eq(wave_tick(mode,tick),36000)),Body{x,y,kind,variant,hp,maxHp,age,seed,radius},Run{phase,tick,px,py,playerHp,playerMax,xp,need,level,kills,gold,character,weapons,passives,invuln,rng,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},seed,(rng - tick + 1 : U32),wave_tick(mode,tick),px,py,stage)
type EntityRow is Data: EntityRow{row: Row,motion: Motion}
# Spatial snapshots are only observations; Q capabilities own all three components.
type Aim is Data: Aim{x: F32,y: F32,id: U32,distance: F32}
def prefer_aim(closer: Bool,+x: F32,+y: F32,+id: U32,+distance: F32,rest: Aim) -> Aim:
  match closer:
    case True{}: Aim{x,y,id,distance}
    case False{}: rest
def aim_distance(aim: Aim) -> F32:
  match aim:
    case Aim{_,_,_,distance}: distance
def nearest(rows: List<&2,Body>,+x: F32,+y: F32,+best: Aim) -> Aim:
  match rows:
    case []: best
    case Body{+tx,+ty,0,_,_,_,_,+seed,_} <> rest: nearest(rest,x,y,prefer_aim(F32.is_lt(distance2(x,y,tx,ty),aim_distance(best)),tx,ty,seed,distance2(x,y,tx,ty),best))
    case _ <> rest: nearest(rest,x,y,best)
def contains(rows: List<&2,U32>,+id: U32) -> Bool:
  match rows:
    case []: False{}
    case head <> rest: Bool.or(U32.is_eq(head,id),contains(rest,id))
def add_contact(hit: Bool,seed: U32,rest: List<&2,U32>) -> List<&2,U32>:
  match hit:
    case True{}: seed <> rest
    case False{}: rest
def contacts(rows: List<&2,Body>,+x: F32,+y: F32,+radius: F32,+visited: List<&2,U32>) -> List<&2,U32>:
  match rows:
    case []: []
    case Body{+tx,+ty,0,_,_,_,_,+seed,+r} <> rest: add_contact(Bool.and(Bool.not(contains(visited,seed)),close(x,y,tx,ty,(radius + r : F32))),seed,contacts(rest,x,y,radius,visited))
    case _ <> rest: contacts(rest,x,y,radius,visited)
def planned_targets(unlimited: Bool,+pierce: U32,+bodies: List<&2,Body>,+x: F32,+y: F32,+radius: F32,+visited: List<&2,U32>) -> List<&2,U32>:
  match unlimited:
    case True{}: []
    case False{}: List.take(&2,U32,contacts(bodies,x,y,radius,visited),U32.to_nat(pierce))
def append_hit_plan(active: Bool,+seed: U32,+id: U32,+damage: U32,+x: F32,+y: F32,+radius: F32,+pierce: U32,+visited: List<&2,U32>,+bodies: List<&2,Body>,tail: List<&2,HitPlan>) -> List<&2,HitPlan>:
  match active:
    case False{}: tail
    case True{}: HitPlan{seed,id,damage,x,y,radius,U32.is_le(9999,pierce),planned_targets(U32.is_le(9999,pierce),pierce,bodies,x,y,radius,visited)} <> tail
def plan_hits(rows: List<&2,Snapshot>,+bodies: List<&2,Body>) -> List<&2,HitPlan>:
  match rows:
    case []: []
    case Snapshot{Body{+x,+y,1,+id,+damage,_,+age,+seed,+radius},Motion{_,_,+life,+pierce,+visited,_,_}} <> rest: append_hit_plan(Bool.and(P.active_hit(id,age),Bool.and(U32.is_lt(0,life),U32.is_lt(0,pierce))),seed,id,damage,x,y,radius,pierce,visited,bodies,plan_hits(rest,bodies))
    case Snapshot{Body{+x,+y,11,+phase,+hp,_,_,+seed,_},Motion{_,_,+cooldown,_,_,_,_}} <> rest: append_hit_plan(A.pulse(11,hp,phase,cooldown),seed,10,A.ward_damage(),x,y,A.ward_radius(),9999,[],bodies,plan_hits(rest,bodies))
    case _ <> rest: plan_hits(rest,bodies)
# Frozen targeting inputs contain enemies only. XP, actors, shots and dormant
# bodies remain in the full frame/snapshots, without multiplying aim/contact work.
def enemy_geometry(rows: List<&2,Body>) -> List<&2,Body>:
  match rows:
    case []: []
    case Body{+x,+y,0,+variant,+hp,+maxHp,+age,+seed,+radius} <> rest: Body{x,y,0,variant,hp,maxHp,age,seed,radius} <> enemy_geometry(rest)
    case _ <> rest: enemy_geometry(rest)
def combat_args_enemies(run: Run,+enemies: List<&2,Body>,dx: F32,dy: F32,+snapshots: List<&2,Snapshot>) -> Args:
  Args{run,enemies,dx,dy,snapshots,plan_hits(snapshots,enemies)}
def combat_args(run: Run,bodies: List<&2,Body>,dx: F32,dy: F32,snapshots: List<&2,Snapshot>) -> Args:
  combat_args_enemies(run,enemy_geometry(bodies),dx,dy,snapshots)
def select_hit_targets(selected: Bool,targets: List<&2,U32>) -> List<&2,U32>:
  match selected:
    case True{}: targets
    case False{}: []
def hit_targets(rows: List<&2,HitPlan>,+seed: U32) -> List<&2,U32>:
  match rows:
    case []: []
    case HitPlan{+shot,_,_,_,_,_,_,+targets} <> rest: List.append(&2,U32,select_hit_targets(U32.is_eq(shot,seed),targets),hit_targets(rest,seed))
def cooldown_for(+id: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> U32:
  U32.max(6,F32.to_u32((U32.to_f32(period(id)) * F32.max(0.12,(1.0 - U32.to_f32(at(passives,1)) * 0.07 - U32.to_f32(meta_rank(meta,4)) * 0.03 - 0.20 * stat_bonus(arcana,1) - 0.10 * U32.to_f32(Bool.to_u32(U32.is_eq(character,5))) + 0.15 * stat_bonus(arcana,3) : F32)) : F32)))
def area_bonus(+passives: List<&2,U32>,+arcana: U32,+level: U32) -> F32:
  ((1.0 + U32.to_f32(at(passives,2)) * 0.10 + 0.35 * stat_bonus(arcana,2) + 0.15 * stat_bonus(arcana,11) + U32.to_f32(level) * 0.025) * (1.0 - 0.15 * stat_bonus(arcana,1)) * (1.0 + 0.35 * U32.to_f32(Bool.to_u32(U32.is_le(9,level)))) : F32)
def duration_bonus(+passives: List<&2,U32>,+arcana: U32) -> F32: (1.0 + U32.to_f32(at(passives,3)) * 0.15 + 0.50 * stat_bonus(arcana,7) : F32)
def projectile_speed(+passives: List<&2,U32>,+arcana: U32) -> F32: ((1.0 + U32.to_f32(at(passives,12)) * 0.15 + 0.50 * stat_bonus(arcana,8)) * (1.0 - 0.20 * stat_bonus(arcana,7)) : F32)
def weapon_damage(+id: U32,+level: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> U32:
  F32.to_u32((U32.to_f32((5 + level * 3 + id % 4 * 2 : U32)) * (1.0 + U32.to_f32(at(passives,0)) * 0.10 + U32.to_f32(meta_rank(meta,0)) * 0.05 + 0.35 * stat_bonus(arcana,0) + 0.15 * stat_bonus(arcana,8) + 0.10 * U32.to_f32(Bool.to_u32(U32.is_eq(character,0))) + 0.20 * U32.to_f32(Bool.to_u32(U32.is_eq(character,6)))) * (1.0 - 0.15 * stat_bonus(arcana,4)) * (1.0 + (0.20 + U32.to_f32(at(passives,14)) * 0.05) * U32.to_f32(Bool.to_u32(Bool.and(U32.is_eq(arcana,5),Bool.or(U32.is_eq(id,9),U32.is_eq(id,11)))))) * (1.0 + 1.2 * U32.to_f32(Bool.to_u32(U32.is_le(9,level)))) : F32))
def dormant_entity(+x: F32,+y: F32,+seed: U32) -> EntityRow: EntityRow{Row{Body{x,y,8,0,0,0,0,seed,0.0},0,0,0,0,0,0,0},empty_motion()}
def shot_created(+id: U32,+seed: U32,+damage: U32,shot: P.Shot) -> EntityRow:
  match shot:
    case P.Shot{+x,+y,+vx,+vy,+radius,+life,+pierce}: EntityRow{Row{Body{x,y,1,id,damage,damage,0,seed,radius},0,0,0,0,0,0,0},Motion{vx,vy,life,pierce,[],0,0}}
def direction_x(+dx: F32,+dy: F32) -> F32: ((dx + U32.to_f32(Bool.to_u32(F32.is_lt((dx * dx + dy * dy : F32),0.01)))) / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32)
def direction_y(+dx: F32,+dy: F32) -> F32: (dy / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32)
def union_base(+id: U32) -> U32: at([0,1,2,3,4,6],id)
def union_partner(+id: U32) -> U32: at([5,13,15,23,19,17],id)
def secondary_weapon(+id: U32) -> U32: at([5,13,15,23,19,0,17,20,9,23,5,17,4,8,17,2,6,14,9,4,3,5,20,5],id)
def choose_id(select: Bool,yes: U32,no: U32) -> U32:
  match select:
    case True{}: yes
    case False{}: no
def effective_weapon(+base: U32,+level: U32,+slot: U32) -> U32:
  choose_id(Bool.and(U32.is_le(10,level),U32.is_eq((slot % 3 : U32),2)),at([16,23,3,18,20,14],lose(level,10)),choose_id(Bool.and(U32.is_le(10,level),U32.is_eq((slot % 2 : U32),1)),union_partner(lose(level,10)),choose_id(Bool.and(U32.is_le(9,level),U32.is_eq((slot % 2 : U32),1)),secondary_weapon(base),choose_id(Bool.and(U32.is_eq(base,21),U32.is_eq((slot % 2 : U32),1)),0,base))))
def familiar_x(+id: U32,+seed: U32,+slot: U32,+px: F32,+tick: U32) -> F32:
  (px + E.choose_float(Bool.and(U32.is_eq(((seed - 512) / 8 : U32),21),Bool.not(U32.is_eq(id,21))),(F32.cos((U32.to_f32(tick) * 0.035 + U32.to_f32(slot) * 0.3926991 : F32)) * 80.0 : F32),0.0) : F32)
def familiar_y(+id: U32,+seed: U32,+slot: U32,+py: F32,+tick: U32) -> F32:
  (py + E.choose_float(Bool.and(U32.is_eq(((seed - 512) / 8 : U32),21),Bool.not(U32.is_eq(id,21))),(F32.sin((U32.to_f32(tick) * 0.035 + U32.to_f32(slot) * 0.3926991 : F32)) * 80.0 : F32),0.0) : F32)
def aim_direction_x(+dx: F32,+dy: F32,+px: F32,+py: F32,+tx: F32,+ty: F32) -> F32:
  E.choose_float(F32.is_lt((dx * dx + dy * dy : F32),0.01),P.aim_x(px,py,tx,ty),direction_x(dx,dy))
def aim_direction_y(+dx: F32,+dy: F32,+px: F32,+py: F32,+tx: F32,+ty: F32) -> F32:
  E.choose_float(F32.is_lt((dx * dx + dy * dy : F32),0.01),P.aim_y(px,py,tx,ty),direction_y(dx,dy))
def shot_spawn_aim(fire: Bool,+seed: U32,+id: U32,+slot: U32,+level: U32,+run: Run,+dx: F32,+dy: F32,aim: Aim) -> EntityRow:
  match fire run aim:
    case False{} _ _: dormant_entity(0.0,0.0,seed)
    case True{} Run{_,+tick,+px,+py,_,_,_,_,_,_,_,+character,_,+passives,_,_,_,+arcana,+meta,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected} Aim{+tx,+ty,_,_}:
      shot_created(id,seed,weapon_damage(id,level,passives,meta,arcana,character),P.spawn(id,level,(slot * 2 : U32),familiar_x(id,seed,slot,px,tick),familiar_y(id,seed,slot,py,tick),tx,ty,aim_direction_x(dx,dy,px,py,tx,ty),aim_direction_y(dx,dy,px,py,tx,ty),projectile_speed(passives,arcana),area_bonus(passives,arcana,level),duration_bonus(passives,arcana)))
# Ballistic volleys rotate through the whole pool; long-lived fields keep their slots.
def rotates_pool(id: U32) -> Bool:
  match id:
    case 3: False{}
    case 4: False{}
    case 7: False{}
    case 9: False{}
    case 19: False{}
    case 20: False{}
    case 21: False{}
    case 22: False{}
    case _: True{}
def projectile_amount(+base: U32,+level: U32,+passives: List<&2,U32>,+arcana: U32) -> U32:
  U32.min(8,(1 + at(passives,4) + level / 3 + Bool.to_u32(U32.is_eq(arcana,3)) + Bool.to_u32(U32.is_eq(base,21)) : U32))
def volley_slot(+base: U32,+slot: U32,+amount: U32,+tick: U32,+cooldown: U32) -> Bool:
  U32.is_lt(choose_id(rotates_pool(base),((slot + 8 - (tick / cooldown * amount) % 8) % 8 : U32),slot),amount)
def scheduled_shot_owned(owned: Bool,+base: U32,+slot: U32,+level: U32,+passives: List<&2,U32>,+tick: U32,+meta: U32,+arcana: U32,+character: U32) -> Bool:
  match owned:
    case False{}: False{}
    case True{}: Bool.and(volley_slot(base,slot,projectile_amount(base,level,passives,arcana),tick,cooldown_for(base,passives,meta,arcana,character)),U32.is_eq((tick % cooldown_for(base,passives,meta,arcana,character) : U32),1))
def scheduled_shot(+base: U32,+slot: U32,+level: U32,+passives: List<&2,U32>,+tick: U32,+meta: U32,+arcana: U32,+character: U32) -> Bool:
  scheduled_shot_owned(U32.is_lt(0,level),base,slot,level,passives,tick,meta,arcana,character)
# Resolve the complete firing predicate before preparing a projectile. Most
# unowned/unscheduled slots stay dormant and need neither aim nor materialization.
def shot_spawn_ready(fire: Bool,+seed: U32,+base: U32,+slot: U32,+level: U32,args: Args) -> EntityRow:
  match fire args:
    case False{} _: dormant_entity(0.0,0.0,seed)
    case True{} Args{Run{_,+tick,+px,+py,_,_,_,_,_,_,_,+character,+weapons,+passives,_,_,_,+arcana,+meta,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+dx,+dy,_,_}:
      shot_spawn_aim(True{},seed,effective_weapon(base,level,slot),slot,level,Run{0,tick,px,py,0,0,0,0,0,0,0,character,weapons,passives,0,0,0,arcana,meta,0,0,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},dx,dy,nearest(bodies,px,py,Aim{(px + 180.0 : F32),py,0,10000000.0}))
def shot_spawn(+seed: U32,+args: Args) -> EntityRow:
  match args:
    case Args{Run{_,+tick,_,_,_,_,_,_,_,_,_,+character,+weapons,+passives,+invuln,_,_,+arcana,+meta,_,_,_,_,_,_,_,_,_,_},_,_,_,_,_}:
      +base = ((seed - 512) / 8 : U32)
      +slot = ((seed - 512) % 8 : U32)
      +level = at(weapons,base)
      shot_spawn_ready(Bool.or(scheduled_shot(base,slot,level,passives,tick,meta,arcana,character),Bool.and(U32.is_eq(arcana,4),Bool.and(U32.is_eq(base,19),Bool.and(U32.is_eq(slot,0),Bool.and(U32.is_lt(30,invuln),U32.is_eq((tick % 12 : U32),0)))))),seed,base,slot,level,args)
def shot_surviving(alive: Bool,+x: F32,+y: F32,+id: U32,+damage: U32,+age: U32,+seed: U32,+radius: F32,+vx: F32,+vy: F32,+life: U32,+pierce: U32,+visited: List<&2,U32>) -> EntityRow:
  match alive:
    case True{}: EntityRow{Row{Body{x,y,1,id,damage,damage,age,seed,radius},0,0,0,0,0,0,0},Motion{vx,vy,life,pierce,visited,0,0}}
    case False{}: dormant_entity(x,y,seed)
def shot_contacted(+id: U32,+age: U32,+seed: U32,+damage: U32,+visited: List<&2,U32>,+newHits: List<&2,U32>,shot: P.Shot) -> EntityRow:
  match shot:
    case P.Shot{+x,+y,+vx,+vy,+radius,+life,+pierce}:
      shot_surviving(Bool.and(U32.is_lt(0,life),U32.is_lt((U32.from_nat(List.length(&2,U32,newHits)) * Bool.to_u32(Bool.and(P.active_hit(id,age),U32.is_lt(pierce,9999))) : U32),pierce)),x,y,id,damage,(age + 1 : U32),seed,radius,vx,vy,life,lose(pierce,(U32.from_nat(List.length(&2,U32,newHits)) * Bool.to_u32(Bool.and(P.active_hit(id,age),U32.is_lt(pierce,9999))) : U32)),List.append(&2,U32,visited,newHits))
def shot_advanced(+id: U32,+age: U32,+seed: U32,+damage: U32,+oldX: F32,+oldY: F32,+oldRadius: F32,+bodies: List<&2,Body>,+visited: List<&2,U32>,+hits: List<&2,HitPlan>,shot: P.Shot) -> EntityRow:
  shot_contacted(id,age,seed,damage,visited,hit_targets(hits,seed),shot)
def ballistic(id: U32) -> Bool:
  match id:
    case 3: False{}
    case 4: False{}
    case 5: False{}
    case 7: False{}
    case 9: False{}
    case 11: False{}
    case 19: False{}
    case 20: False{}
    case 21: False{}
    case 22: False{}
    case _: True{}
def reflected(enabled: Bool,shot: P.Shot) -> P.Shot:
  match enabled shot:
    case False{} shot: shot
    case True{} P.Shot{+x,+y,+vx,+vy,+radius,+life,+pierce}: P.Shot{F32.clamp(x,20.0,3580.0),F32.clamp(y,20.0,3580.0),(vx * E.choose_float(Bool.or(F32.is_lt(x,20.0),F32.is_lt(3580.0,x)),(0.0 - 1.0 : F32),1.0) : F32),(vy * E.choose_float(Bool.or(F32.is_lt(y,20.0),F32.is_lt(3580.0,y)),(0.0 - 1.0 : F32),1.0) : F32),radius,life,pierce}
def shot_step_aim(body: Body,motion: Motion,args: Args,aim: Aim) -> EntityRow:
  match body motion args aim:
    case Body{+x,+y,_,+id,+damage,_,+age,+seed,+radius} Motion{+vx,+vy,+life,+pierce,+visited,_,_} Args{Run{_,+tick,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,+arcana,_,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,_,_,+snapshots,+hits} Aim{+tx,+ty,_,_}:
      shot_advanced(id,age,seed,damage,x,y,radius,bodies,visited,hits,reflected(Bool.and(U32.is_eq(arcana,8),ballistic(id)),P.step(id,(age + 1 : U32),P.Shot{x,y,vx,vy,radius,life,pierce},px,py,tx,ty)))
def nearest_from_args(args: Args,+x: F32,+y: F32) -> Aim:
  match args:
    case Args{_,bodies,_,_,+snapshots,+hits}: nearest(bodies,x,y,Aim{(x + 180.0 : F32),y,0,10000000.0})
def shot_step(body: Body,motion: Motion,+args: Args) -> EntityRow:
  match body motion:
    case Body{+x,+y,1,+id,+damage,+maxHp,+age,+seed,+radius} Motion{_,_,0,_,_,_,_}: shot_spawn(seed,args)
    case Body{+x,+y,1,+id,+damage,+maxHp,+age,+seed,+radius} Motion{_,_,_,0,_,_,_}: shot_spawn(seed,args)
    case Body{+x,+y,1,+id,+damage,+maxHp,+age,+seed,+radius} +motion: shot_step_aim(Body{x,y,1,id,damage,maxHp,age,seed,radius},motion,args,nearest_from_args(args,x,y))
    case Body{_,_,_,_,_,_,_,+seed,_} _: shot_spawn(seed,args)
type Collision is Data: Collision{damage: U32,slow: U32,burn: U32,pull: U32,knock: U32,pullX: F32,pullY: F32}
def slow_factor(+slow: U32) -> F32: E.choose_float(U32.is_le(65536,slow),0.0,E.choose_float(U32.is_lt(0,slow),0.35,1.0))
def cool_status(+slow: U32) -> U32: (dec((slow % 65536 : U32)) + 65536 * Bool.to_u32(Bool.and(U32.is_le(65536,slow),U32.is_lt(1,(slow % 65536 : U32)))) : U32)
def collision_add(hit: Bool,+id: U32,+damage: U32,+cx: F32,+cy: F32,tail: Collision) -> Collision:
  match hit tail:
    case False{} tail: tail
    case True{} Collision{+d,+s,+b,+p,+k,+sumX,+sumY}: Collision{(d + damage : U32),U32.max(s,(90 * Bool.to_u32(Bool.or(U32.is_eq(P.status(id),1),U32.is_eq(P.status(id),2))) + 65536 * Bool.to_u32(U32.is_eq(P.status(id),2)) : U32)),U32.max(b,(120 * Bool.to_u32(U32.is_eq(P.status(id),3)) : U32)),(p + Bool.to_u32(U32.is_eq(P.status(id),4)) : U32),(k + Bool.to_u32(U32.is_eq(P.status(id),5)) : U32),(sumX + cx * U32.to_f32(Bool.to_u32(U32.is_eq(P.status(id),4))) : F32),(sumY + cy * U32.to_f32(Bool.to_u32(U32.is_eq(P.status(id),4))) : F32)}
def hit_recipient(area: Bool,+targets: List<&2,U32>,+target: U32,+x: F32,+y: F32,+radius: F32,+tx: F32,+ty: F32,+r: F32) -> Bool:
  match area:
    case True{}: close(x,y,tx,ty,(radius + r : F32))
    case False{}: contains(targets,target)
def collisions(rows: List<&2,HitPlan>,+x: F32,+y: F32,+radius: F32,+target: U32) -> Collision:
  match rows:
    case []: Collision{0,0,0,0,0,0.0,0.0}
    case HitPlan{_,+id,+damage,+tx,+ty,+r,+area,+targets} <> rest: collision_add(hit_recipient(area,targets,target,x,y,radius,tx,ty,r),id,damage,tx,ty,collisions(rest,x,y,radius,target))
def lucky_row(row: Row,+luck: U32) -> Row:
  match row:
    case Row{Body{+x,+y,+kind,+variant,0,+maxHp,+age,+seed,+radius},+hit,+xp,+gold,+heal,+chest,1,+relic}: Row{Body{x,y,choose_id(U32.is_lt(variant,20),lucky_kind(seed,luck),kind),variant,0,maxHp,age,seed,radius},hit,xp,gold,heal,chest,1,0}
    case row: row
def pull_x(+x: F32,+y: F32,+sumX: F32,+sumY: F32,+count: U32) -> F32:
  ((sumX / U32.to_f32(U32.max(1,count)) - x) / F32.max(1.0,F32.sqrt(distance2(x,y,(sumX / U32.to_f32(U32.max(1,count)) : F32),(sumY / U32.to_f32(U32.max(1,count)) : F32)))) : F32)
def pull_y(+x: F32,+y: F32,+sumX: F32,+sumY: F32,+count: U32) -> F32:
  ((sumY / U32.to_f32(U32.max(1,count)) - y) / F32.max(1.0,F32.sqrt(distance2(x,y,(sumX / U32.to_f32(U32.max(1,count)) : F32),(sumY / U32.to_f32(U32.max(1,count)) : F32)))) : F32)
def enemy_applied_effects(+oldX: F32,+oldY: F32,row: Row,motion: Motion,collision: Collision,run: Run) -> EntityRow:
  match row motion collision run:
    case Row{Body{+x,+y,0,+variant,+hp,+maxHp,+age,+seed,+radius},_,_,_,_,_,_,+relic} Motion{_,_,_,_,_,+slow,+burn} Collision{+damage,+s,+b,+pull,+knock,+pullX,+pullY} Run{_,+tick,+px,+py,_,_,_,_,_,_,_,_,_,+passives,_,_,_,+arcana,_,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}:
      EntityRow{lucky_row(enemy_result(lose(hp,(damage + (2 + 2 * Bool.to_u32(U32.is_eq(arcana,7))) * Bool.to_u32(Bool.and(U32.is_lt(0,burn),U32.is_eq((tick % 30 : U32),0))) : U32)),(oldX + (x - oldX) * slow_factor(U32.max(slow,s)) + (oldX - px) / F32.max(1.0,F32.sqrt(distance2(oldX,oldY,px,py))) * U32.to_f32(knock) * (6.0 * (1.0 + U32.to_f32(at(passives,16)) * 0.15 + 0.75 * stat_bonus(arcana,11)) : F32) + pull_x(oldX,oldY,pullX,pullY,pull) * U32.to_f32(pull) * (3.0 + 4.0 * stat_bonus(arcana,11)) : F32),(oldY + (y - oldY) * slow_factor(U32.max(slow,s)) + (oldY - py) / F32.max(1.0,F32.sqrt(distance2(oldX,oldY,px,py))) * U32.to_f32(knock) * (6.0 * (1.0 + U32.to_f32(at(passives,16)) * 0.15 + 0.75 * stat_bonus(arcana,11)) : F32) + pull_y(oldX,oldY,pullX,pullY,pull) * U32.to_f32(pull) * (3.0 + 4.0 * stat_bonus(arcana,11)) : F32),variant,maxHp,age,seed,radius,px,py),at(passives,10)),Motion{0.0,0.0,0,0,[],U32.max(cool_status(slow),s),U32.max(dec(burn),(b * (1 + Bool.to_u32(U32.is_eq(arcana,7))) : U32))}}
    case row motion _ _: EntityRow{row,motion}
# Dawn's pursuer takes damage but cannot be frozen, slowed or displaced.
def immune_motion(immune: Bool,motion: Motion) -> Motion:
  match immune motion:
    case True{} Motion{vx,vy,life,pierce,visited,_,burn}: Motion{vx,vy,life,pierce,visited,0,burn}
    case False{} motion: motion
def immune_collision(immune: Bool,collision: Collision) -> Collision:
  match immune collision:
    case True{} Collision{damage,_,burn,_,_,_,_}: Collision{damage,0,burn,0,0,0.0,0.0}
    case False{} collision: collision
def enemy_applied(+oldX: F32,+oldY: F32,row: Row,motion: Motion,collision: Collision,run: Run) -> EntityRow:
  match row:
    case Row{Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius},hit,xp,gold,heal,chest,killed,relic}: enemy_applied_effects(oldX,oldY,Row{Body{x,y,kind,variant,hp,maxHp,age,seed,radius},hit,xp,gold,heal,chest,killed,relic},immune_motion(U32.is_eq(variant,30),motion),immune_collision(U32.is_eq(variant,30),collision),run)
def relic_result(collected: Bool,+stage: U32,+px: F32,+py: F32) -> EntityRow:
  match collected:
    case True{}: EntityRow{Row{Body{px,py,8,0,0,0,0,511,0.0},0,50,75,0,0,0,1},empty_motion()}
    case False{}: EntityRow{Row{Body{relic_x(stage),relic_y(stage),9,stage,0,0,0,511,18.0},0,0,0,0,0,0,0},empty_motion()}
def relic_run(run: Run) -> EntityRow:
  match run:
    case Run{_,_,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,+stage,_,_,_,_,_,_,_,_,_,_,_,0}: relic_result(close(px,py,relic_x(stage),relic_y(stage),30.0),stage,px,py)
    case _: dormant_entity(0.0,0.0,511)
def relic_entity(args: Args) -> EntityRow:
  match args:
    case Args{run,_,_,_,_,_}: relic_run(run)
def normal_regular_entity(body: Body,motion: Motion,args: Args) -> EntityRow:
  match body args:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius} Args{+run,+bodies,_,_,+snapshots,+hits}: enemy_applied(x,y,update(Body{x,y,kind,variant,hp,maxHp,age,seed,radius},run),motion,collisions(hits,x,y,radius,seed),run)
def actor_row(+kind: U32,+seed: U32,actor: A.Actor) -> EntityRow:
  match actor:
    case A.Actor{+x,+y,+hp,+age,+cooldown,+phase,+reward}: EntityRow{Row{Body{x,y,kind,phase,hp,(80 + 80 * Bool.to_u32(U32.is_eq(kind,11)) : U32),age,seed,12.0},0,(40 * reward : U32),(50 * reward : U32),(15 * reward : U32),0,0,0},Motion{0.0,0.0,cooldown,0,[],0,0}}
def actor_step_aim(body: Body,motion: Motion,run: Run,aim: Aim) -> EntityRow:
  match body motion run aim:
    case Body{+x,+y,+kind,+phase,+hp,_,+age,+seed,_} Motion{_,_,+cooldown,_,_,_,_} Run{_,_,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_} Aim{+ex,+ey,_,+range}: actor_row(kind,seed,A.step(kind,seed,x,y,hp,age,cooldown,phase,px,py,ex,ey,F32.is_le(range,8100.0)))
def actor_entity(body: Body,motion: Motion,args: Args) -> EntityRow:
  match body args:
    case Body{_,_,8,_,_,_,_,+seed,_} _: actor_row(choose_id(U32.is_lt(seed,744),10,11),seed,A.spawn(choose_id(U32.is_lt(seed,744),10,11),((seed - 736) % 4 + 4 * Bool.to_u32(Bool.and(U32.is_lt(seed,744),U32.is_le(740,seed))) : U32)))
    case Body{+x,+y,+kind,+phase,+hp,+maxHp,+age,+seed,+radius} Args{run,bodies,_,_,_,_}: actor_step_aim(Body{x,y,kind,phase,hp,maxHp,age,seed,radius},motion,run,nearest(bodies,x,y,Aim{0.0,0.0,0,10000000.0}))
def normal_dispatch(actor: Bool,body: Body,motion: Motion,args: Args) -> EntityRow:
  match actor:
    case True{}: actor_entity(body,motion,args)
    case False{}: normal_regular_entity(body,motion,args)
def xp_amount(body: Body) -> U32:
  match body:
    case Body{_,_,2,_,amount,_,_,_,_}: amount
    case _: 0
def xp_entity(body: Body,args: Args) -> EntityRow:
  match body args:
    case Body{+x,+y,2,+variant,+amount,+generation,+age,+seed,+radius} Args{run,_,_,_,_,_}: EntityRow{loot_update(Body{x,y,2,variant,amount,generation,age,seed,radius},run),empty_motion()}
    case Body{+x,+y,_,+variant,_,+generation,+age,+seed,_} _: dormant_entity(x,y,seed)
def extra_entity(xp: Bool,body: Body,motion: Motion,args: Args) -> EntityRow:
  match xp:
    case True{}: xp_entity(body,args)
    case False{}: normal_dispatch(True{},body,motion,args)
def normal_pool(extra: Bool,body: Body,motion: Motion,args: Args) -> EntityRow:
  match extra body:
    case True{} Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}: extra_entity(U32.is_le(748,seed),Body{x,y,kind,variant,hp,maxHp,age,seed,radius},motion,args)
    case False{} body: normal_dispatch(False{},body,motion,args)
def normal_entity(body: Body,motion: Motion,args: Args) -> EntityRow:
  match body:
    case Body{_,_,_,_,_,_,_,511,_}: relic_entity(args)
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}: normal_pool(U32.is_le(736,seed),Body{x,y,kind,variant,hp,maxHp,age,seed,radius},motion,args)
def intent_fire(intent: E.Intent) -> Bool:
  match intent:
    case E.Intent{_,_,fire}: fire
def nearest_shooter(rows: List<&2,Body>,+x: F32,+y: F32,+best: Aim) -> Aim:
  match rows:
    case []: best
    case Body{+tx,+ty,0,+variant,_,_,+age,+seed,_} <> rest: nearest_shooter(rest,x,y,prefer_aim(Bool.and(intent_fire(E.intent(variant,age,tx,ty,x,y)),F32.is_lt(distance2(x,y,tx,ty),aim_distance(best))),tx,ty,seed,distance2(x,y,tx,ty),best))
    case _ <> rest: nearest_shooter(rest,x,y,best)
def hostile_created(fire: Bool,+seed: U32,+px: F32,+py: F32,aim: Aim) -> EntityRow:
  match fire aim:
    case True{} Aim{+x,+y,_,_}: EntityRow{Row{Body{x,y,7,0,8,8,0,seed,6.0},0,0,0,0,0,0,0},Motion{((px - x) / F32.max(1.0,F32.sqrt(distance2(x,y,px,py))) * 3.5 : F32),((py - y) / F32.max(1.0,F32.sqrt(distance2(x,y,px,py))) * 3.5 : F32),240,1,[],0,0}}
    case False{} _: dormant_entity(0.0,0.0,seed)
def hostile_spawn(+seed: U32,args: Args) -> EntityRow:
  match args:
    case Args{Run{_,+tick,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,_,_,+snapshots,+hits}: hostile_created(Bool.and(U32.is_lt((seed - 704 : U32),U32.min(12,(2 + tick / 3600 : U32))),Bool.and(U32.is_eq((tick % 12 : U32),((seed - 704) % 12 : U32)),F32.is_lt(aim_distance(nearest_shooter(bodies,px,py,Aim{0.0,0.0,0,10000000.0})),10000000.0))),seed,px,py,nearest_shooter(bodies,px,py,Aim{0.0,0.0,0,10000000.0}))
def hostile_advance(alive: Bool,+body: Body,+motion: Motion,+args: Args) -> EntityRow:
  match alive body motion args:
    case False{} Body{_,_,_,_,_,_,_,+seed,_} _ args: hostile_spawn(seed,args)
    case True{} Body{+x,+y,_,+variant,+damage,+maxHp,+age,+seed,+radius} Motion{+vx,+vy,+life,+pierce,+visited,+slow,+burn} Args{Run{_,+tick,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},_,_,_,+snapshots,+hits}: EntityRow{Row{Body{(x + vx : F32),(y + vy : F32),7,variant,damage,maxHp,(age + 1 : U32),seed,radius},(Bool.to_u32(close(x,y,px,py,(radius + 10.0 : F32))) * (1 + 1000 * Bool.to_u32(U32.is_eq(variant,30))) : U32),0,0,0,0,0,0},Motion{vx,vy,dec(life),pierce,visited,slow,burn}}
def hostile_step(body: Body,motion: Motion,args: Args) -> EntityRow:
  match motion:
    case Motion{+vx,+vy,+life,+pierce,+visited,+slow,+burn}: hostile_advance(U32.is_lt(0,life),body,Motion{vx,vy,life,pierce,visited,slow,burn},args)
def entity_selected(projectile: Bool,hostile: Bool,body: Body,motion: Motion,args: Args) -> EntityRow:
  match projectile hostile:
    case True{} False{}: shot_step(body,motion,args)
    case True{} True{}: hostile_step(body,motion,args)
    case _ _: normal_entity(body,motion,args)
def entity_update(body: Body,motion: Motion,args: Args) -> EntityRow:
  match body:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius}: entity_selected(U32.is_le(512,seed),U32.is_le(704,seed),Body{x,y,kind,variant,hp,maxHp,age,seed,radius},motion,args)

# Each pass has an independently checked access contract. Read capabilities cannot write.
def missing_row() -> EntityRow: EntityRow{Row{Body{0.0,0.0,8,0,0,0,0,0,0.0},0,0,0,0,0,0,0},empty_motion()}
def Frame() -> Type: Q.Frame<Schema,Store,Unit,Unit>
def selected_kind(+mode: U32,+kind: U32,+seed: U32) -> Bool:
  Bool.or(Bool.and(U32.is_eq(mode,0),Bool.and(U32.is_le(512,seed),U32.is_lt(seed,736))),Bool.or(Bool.and(U32.is_eq(mode,2),U32.is_le(736,seed)),Bool.and(U32.is_lt(seed,512),Bool.or(U32.is_eq(mode,2),Bool.and(U32.is_eq(mode,1),U32.is_eq(kind,0))))))
def selected_observed(+mode: U32,result: Frame() & C.Access<Body>) -> Frame() & Bool:
  match result:
    case (frame,C.Found{Body{_,_,+kind,_,_,_,_,+seed,_}}): (frame,selected_kind(mode,kind,seed))
    case (frame,_): (frame,False{})
def selected_projectile(frame: Frame()) -> Frame() & Bool: selected_observed(0,Q.get(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family(),frame))
def selected_enemy(frame: Frame()) -> Frame() & Bool: selected_observed(1,Q.get(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family(),frame))
def selected_pool(frame: Frame()) -> Frame() & Bool: selected_observed(2,Q.get(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family(),frame))

# Projectile pass owns positions and trajectories, with no access to entity health.
type ProjectileOps<-H: Type> is Type: ProjectileOps{body: Cap.Write<H,Body,Body>,motion: Cap.Write<H,Motion,Motion>}
def ProjectileOpsType(H: Type) -> Type: ProjectileOps<H>
def projectile_body_cap(~H: Type,ops: ProjectileOps<H>) -> Cap.Write<H,Body,Body>:
  match ops:
    case ProjectileOps{body,_}: body
def projectile_motion_cap(~H: Type,ops: ProjectileOps<H>) -> Cap.Write<H,Motion,Motion>:
  match ops:
    case ProjectileOps{_,motion}: motion
def projectile_write(~H: Type,~ops: ProjectileOps<H>,ctx: H,row: EntityRow) -> H & (T.Outcome<Error> & EntityRow):
  match row:
    case EntityRow{Row{+body,+hit,+xp,+gold,+heal,+chest,+killed,+relic},+motion}: (Cap.set(~H,~Motion,~Motion,~projectile_motion_cap(~H,ops),Cap.set(~H,~Body,~Body,~projectile_body_cap(~H,ops),ctx,body),motion),(T.Success{},EntityRow{Row{body,hit,xp,gold,heal,chest,killed,0},motion}))
def projectile_motion_observed(~H: Type,~ops: ProjectileOps<H>,+args: Args,body: Body,result: H & C.Access<Motion>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{motion}): projectile_write(~H,~ops,ctx,entity_update(body,motion,args))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def projectile_body_observed(~H: Type,~ops: ProjectileOps<H>,+args: Args,result: H & C.Access<Body>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{body}): projectile_motion_observed(~H,~ops,args,body,Cap.get(~H,~Motion,~Motion,~projectile_motion_cap(~H,ops),ctx))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def projectile_system(~H: Type,~ops: ProjectileOps<H>,args: Args,ctx: H) -> H & (T.Outcome<Error> & EntityRow): projectile_body_observed(~H,~ops,args,Cap.get(~H,~Body,~Body,~projectile_body_cap(~H,ops),ctx))
def projectile_plan() -> Q.Plan<Schema,Store,Unit,Unit,ProjectileOpsType>: Q.Plan{ProjectileOps{Q.write_family(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family()),Q.write_family(~Schema,~Store,~Unit,~Unit,~MotionRest,~Motion,~Motion,~MotionToken,~take_motion,~put_motion,~project_motion,~motion_family())},selected_projectile}

# Movement reads status and writes geometry. It has no health writer or status writer.
type MoveOps<-H: Type> is Type: MoveOps{body: Cap.Write<H,Body,Body>,motion: Cap.Read<H,Motion>}
def MoveOpsType(H: Type) -> Type: MoveOps<H>
def move_body_cap(~H: Type,ops: MoveOps<H>) -> Cap.Write<H,Body,Body>:
  match ops:
    case MoveOps{body,_}: body
def move_motion_cap(~H: Type,ops: MoveOps<H>) -> Cap.Read<H,Motion>:
  match ops:
    case MoveOps{_,motion}: motion
def moved_intent(body: Body,intent: E.Intent,+factor: F32) -> Body:
  match body intent:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius} E.Intent{+vx,+vy,_}: Body{(x + vx * factor : F32),(y + vy * factor : F32),kind,variant,hp,maxHp,(age + 1 : U32),seed,radius}
def move_body(body: Body,motion: Motion,args: Args) -> Body:
  match body motion args:
    case Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius} Motion{_,_,_,_,_,+slow,_} Args{Run{_,+tick,+px,+py,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,+mode,_,_,_,_,_,+enemyKinds,+relicCollected},_,_,_,_,+hits}: moved_intent(Body{x,y,kind,variant,hp,maxHp,age,seed,radius},E.intent(variant,age,x,y,px,py),(E.choose_float(U32.is_eq(variant,30),1.0,slow_factor(slow)) * (1.25 + F32.min(0.60,(U32.to_f32(tick) / 60000.0 : F32)) + F32.min(4.0,(U32.to_f32(age) / 120.0 : F32)) * U32.to_f32(Bool.to_u32(U32.is_eq(variant,30)))) : F32))
def move_motion_observed(~H: Type,~ops: MoveOps<H>,+args: Args,body: Body,result: H & C.Access<Motion>) -> H & (T.Outcome<Error> & Unit):
  match result:
    case (ctx,C.Found{motion}): (Cap.set(~H,~Body,~Body,~move_body_cap(~H,ops),ctx,move_body(body,motion,args)),(T.Success{},Unit{}))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},Unit{}))
def move_body_observed(~H: Type,~ops: MoveOps<H>,+args: Args,result: H & C.Access<Body>) -> H & (T.Outcome<Error> & Unit):
  match result:
    case (ctx,C.Found{body}): move_motion_observed(~H,~ops,args,body,Cap.read(~H,~Motion,~move_motion_cap(~H,ops),ctx))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},Unit{}))
def move_system(~H: Type,~ops: MoveOps<H>,args: Args,ctx: H) -> H & (T.Outcome<Error> & Unit): move_body_observed(~H,~ops,args,Cap.get(~H,~Body,~Body,~move_body_cap(~H,ops),ctx))
def move_plan() -> Q.Plan<Schema,Store,Unit,Unit,MoveOpsType>: Q.Plan{MoveOps{Q.write_family(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family()),Q.read_family(~Schema,~Store,~Unit,~Unit,~MotionRest,~Motion,~Motion,~MotionToken,~take_motion,~put_motion,~project_motion,~motion_family())},selected_enemy}

# Combat only observes geometry. Independent health/status columns own its decisions.
def write_row(~H: Type,~ops: Ops<H>,ctx: H,row: EntityRow) -> H & (T.Outcome<Error> & EntityRow):
  match row:
    case EntityRow{Row{Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+seed,+radius},+hit,+xp,+gold,+heal,+chest,+killed,+relic},+motion}:
      (Cap.set(~H,~Motion,~Motion,~motion_cap(~H,ops),Cap.set(~H,~Vitals,~Vitals,~vital_cap(~H,ops),ctx,Vitals{hp,maxHp}),motion),(T.Success{},EntityRow{Row{Body{x,y,kind,variant,hp,maxHp,age,seed,radius},hit,xp,gold,heal,chest,killed,relic},motion}))
def observed_motion(~H: Type,~ops: Ops<H>,+args: Args,body: Body,result: H & C.Access<Motion>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{motion}): write_row(~H,~ops,ctx,normal_entity(body,motion,args))
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def observed_vitals(~H: Type,~ops: Ops<H>,+args: Args,body: Body,result: H & C.Access<Vitals>) -> H & (T.Outcome<Error> & EntityRow):
  match body result:
    case Body{+x,+y,+kind,+variant,_,_,+age,+seed,+radius} Tuple{ctx,C.Found{Vitals{+health,+maximum}}}: observed_motion(~H,~ops,args,Body{x,y,kind,variant,health,maximum,age,seed,radius},Cap.get(~H,~Motion,~Motion,~motion_cap(~H,ops),ctx))
    case _ Tuple{ctx,_}: (ctx,(T.Failure{MissingBody{}},missing_row()))
def observed_pool_selected(~H: Type,~ops: Ops<H>,xp: Bool,+args: Args,+body: Body,ctx: H) -> H & (T.Outcome<Error> & EntityRow):
  match xp:
    case True{}: write_row(~H,~ops,ctx,xp_entity(body,args))
    case False{}: observed_vitals(~H,~ops,args,body,Cap.get(~H,~Vitals,~Vitals,~vital_cap(~H,ops),ctx))
def observed_pool(~H: Type,~ops: Ops<H>,+args: Args,+body: Body,ctx: H) -> H & (T.Outcome<Error> & EntityRow):
  match body:
    case Body{_,_,_,_,_,_,_,+seed,_}: observed_pool_selected(~H,~ops,U32.is_le(748,seed),args,body,ctx)
def observed(~H: Type,~ops: Ops<H>,+args: Args,result: H & C.Access<Body>) -> H & (T.Outcome<Error> & EntityRow):
  match result:
    case (ctx,C.Found{body}): observed_pool(~H,~ops,args,body,ctx)
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},missing_row()))
def body_system(~H: Type,~ops: Ops<H>,args: Args,ctx: H) -> H & (T.Outcome<Error> & EntityRow): observed(~H,~ops,args,Cap.read(~H,~Body,~body_cap(~H,ops),ctx))
def plan() -> Q.Plan<Schema,Store,Unit,Unit,OpsType>: Q.Plan{Ops{Q.read_family(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family()),Q.write_family(~Schema,~Store,~Unit,~Unit,~VitalRest,~Vitals,~Vitals,~VitalToken,~take_vitals,~put_vitals,~project_vitals,~vital_family()),Q.write_family(~Schema,~Store,~Unit,~Unit,~MotionRest,~Motion,~Motion,~MotionToken,~take_motion,~put_motion,~project_motion,~motion_family())},selected_pool}

# The final lifecycle pass applies spawn/death/drop observations and owns only Body.
type LootOps<-H: Type> is Type: LootOps{body: Cap.Write<H,Body,Body>}
def LootOpsType(H: Type) -> Type: LootOps<H>
def loot_body_cap(~H: Type,ops: LootOps<H>) -> Cap.Write<H,Body,Body>:
  match ops:
    case LootOps{body}: body
def prefer_body(found: Bool,body: Body,fallback: Body) -> Body:
  match found:
    case True{}: body
    case False{}: fallback
# Carry the equality result into the recursive matcher so a hit never evaluates
# the remaining lookup. The first matching row wins, including duplicate IDs.
def planned_body_match(rows: List<&2,EntityRow>,found: Bool,+seed: U32,+fallback: Body,current: Body) -> Body:
  match rows found:
    case _ True{}: current
    case Nil{} False{}: fallback
    case Con{EntityRow{Row{Body{+x,+y,+kind,+variant,+hp,+maxHp,+age,+id,+radius},_,_,_,_,_,_,_},_},rest} False{}: planned_body_match(rest,U32.is_eq(id,seed),seed,fallback,Body{x,y,kind,variant,hp,maxHp,age,id,radius})
def planned_body(rows: List<&2,EntityRow>,+seed: U32,+fallback: Body) -> Body:
  planned_body_match(rows,False{},seed,fallback,fallback)
# Construct once per lifecycle tick. Insertion order matches the original scan,
# retaining the first occurrence of a seed and every opaque Body field.
def body_seed(body: Body) -> U32:
  match body:
    case Body{_,_,_,_,_,_,_,seed,_}: seed
def body_index_rows(rows: List<&2,EntityRow>,index: BI.Index<Body>) -> BI.Index<Body>:
  match rows:
    case []: index
    case EntityRow{Row{+body,_,_,_,_,_,_,_},_} <> rest: body_index_rows(rest,BI.insert(~Body,index,body_seed(body),body))
def body_index(rows: List<&2,EntityRow>) -> BI.Index<Body>: body_index_rows(rows,BI.Empty{})
def indexed_body(index: BI.Index<Body>,seed: U32,fallback: Body) -> Body:
  BI.get(~Body,index,seed,fallback)
def loot_observed_body(~H: Type,~ops: LootOps<H>,index: BI.Index<Body>,+body: Body,ctx: H) -> H & (T.Outcome<Error> & Unit):
  match body:
    case Body{_,_,_,_,_,_,_,+seed,_}: (Cap.set(~H,~Body,~Body,~loot_body_cap(~H,ops),ctx,indexed_body(index,seed,body)),(T.Success{},Unit{}))
def loot_observed(~H: Type,~ops: LootOps<H>,+index: BI.Index<Body>,result: H & C.Access<Body>) -> H & (T.Outcome<Error> & Unit):
  match result:
    case (ctx,C.Found{+body}): loot_observed_body(~H,~ops,index,body,ctx)
    case (ctx,_): (ctx,(T.Failure{MissingBody{}},Unit{}))
def loot_system(~H: Type,~ops: LootOps<H>,index: BI.Index<Body>,ctx: H) -> H & (T.Outcome<Error> & Unit): loot_observed(~H,~ops,index,Cap.get(~H,~Body,~Body,~loot_body_cap(~H,ops),ctx))
def loot_plan() -> Q.Plan<Schema,Store,Unit,Unit,LootOpsType>: Q.Plan{LootOps{Q.write_family(~Schema,~Store,~Unit,~Unit,~BodyRest,~Body,~Body,~Token,~take,~put,~project,~family())},selected_pool}

# All collision inputs are frozen once per tick; no pass sees partly updated shots.
def lifecycle_done(+rows: List<&2,EntityRow>,result: Q.Executed<World(),Q.Error<Error>,Unit>) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},_}: Q.Executed{world,T.Success{},rows}
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
# XP entries preserve exact drop positions until the dedicated pool is full.
# Overflow merges into the nearest existing pile; no XP is silently discarded.
def xp_pool_keep(keep: Bool,row: EntityRow,rest: List<&2,EntityRow>) -> List<&2,EntityRow>:
  match keep:
    case True{}: row <> rest
    case False{}: rest
def xp_pool_filter(+row: EntityRow,+pool: Bool,rest: List<&2,EntityRow>) -> List<&2,EntityRow>:
  match row:
    case EntityRow{Row{Body{_,_,_,_,_,_,_,+seed,_},_,_,_,_,_,_,_},_}: xp_pool_keep(Bool.or(Bool.and(U32.is_le(748,seed),pool),Bool.and(Bool.not(U32.is_le(748,seed)),Bool.not(pool))),row,rest)
def xp_pool_rows(rows: List<&2,EntityRow>,+pool: Bool) -> List<&2,EntityRow>:
  match rows:
    case []: []
    case +row <> rest: xp_pool_filter(row,pool,xp_pool_rows(rest,pool))
def xp_available(rows: List<&2,EntityRow>,+x: F32,+y: F32,+best: Aim) -> Aim:
  match rows:
    case []: best
    case EntityRow{Row{Body{_,_,8,_,_,_,_,+seed,_},_,_,_,_,_,_,_},_} <> _: Aim{0.0,0.0,seed,0.0}
    case EntityRow{Row{Body{+px,+py,_,_,_,_,_,+seed,_},_,_,_,_,_,_,_},_} <> rest: xp_available(rest,x,y,prefer_aim(F32.is_lt(distance2(x,y,px,py),aim_distance(best)),px,py,seed,distance2(x,y,px,py),best))
def xp_deposit_body(selected: Bool,+body: Body,+amount: U32,+x: F32,+y: F32,+tick: U32) -> Body:
  match selected body:
    case False{} body: body
    case True{} Body{+px,+py,2,+variant,+old,+generation,+age,+seed,_}: Body{px,py,2,variant,X.merge(old,amount),generation,age,seed,6.0}
    case True{} Body{_,_,_,_,_,_,_,+seed,_}: Body{x,y,2,0,amount,tick,0,seed,6.0}
def xp_deposit_selected(rows: List<&2,EntityRow>,+selected: U32,+amount: U32,+x: F32,+y: F32,+tick: U32) -> List<&2,EntityRow>:
  match rows:
    case []: []
    case EntityRow{Row{Body{+px,+py,+kind,+variant,+hp,+maxHp,+age,+seed,+radius},+hit,+xp,+gold,+heal,+chest,+killed,+relic},+motion} <> rest: EntityRow{Row{xp_deposit_body(U32.is_eq(seed,selected),Body{px,py,kind,variant,hp,maxHp,age,seed,radius},amount,x,y,tick),hit,xp,gold,heal,chest,killed,relic},motion} <> xp_deposit_selected(rest,selected,amount,x,y,tick)
def xp_deposit_target(pool: List<&2,EntityRow>,amount: U32,x: F32,y: F32,tick: U32,target: Aim) -> List<&2,EntityRow>:
  match target:
    case Aim{_,_,seed,_}: xp_deposit_selected(pool,seed,amount,x,y,tick)
def xp_apply_events(events: List<&2,EntityRow>,+pool: List<&2,EntityRow>,+tick: U32) -> List<&2,EntityRow>:
  match events:
    case []: pool
    case EntityRow{Row{Body{+x,+y,2,+variant,_,_,_,_,_},_,_,_,_,_,1,_},_} <> rest: xp_apply_events(rest,xp_deposit_target(pool,X.drop_amount(variant),x,y,tick,xp_available(pool,x,y,Aim{0.0,0.0,748,100000000.0})),tick)
    case _ <> rest: xp_apply_events(rest,pool,tick)
def xp_free_enemies(rows: List<&2,EntityRow>) -> List<&2,EntityRow>:
  match rows:
    case []: []
    case EntityRow{Row{Body{+x,+y,2,+variant,_,+maximum,_,+seed,_},+hit,+xp,+gold,+heal,+chest,1,+relic},motion} <> rest: EntityRow{Row{Body{x,y,8,variant,0,maximum,0,seed,0.0},hit,xp,gold,heal,chest,1,relic},motion} <> xp_free_enemies(rest)
    case row <> rest: row <> xp_free_enemies(rest)
def xp_route_rows(+rows: List<&2,EntityRow>,+tick: U32) -> List<&2,EntityRow>:
  List.append(&2,EntityRow,xp_free_enemies(xp_pool_rows(rows,False{})),xp_apply_events(rows,xp_pool_rows(rows,True{}),tick))
def args_tick(args: Args) -> U32:
  match args:
    case Args{Run{_,tick,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_},_,_,_,_,_}: tick
def xp_lifecycle(+projectiles: List<&2,EntityRow>,+rows: List<&2,EntityRow>,world: World()) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  lifecycle_done(List.append(&2,EntityRow,projectiles,rows),Q.each(~Schema,~Store,~Unit,~Unit,~LootOpsType,~BI.Index<Body>,~Error,~Unit,~loot_plan(),~loot_system,body_index(rows),world))
def combat_done(+args: Args,+projectiles: List<&2,EntityRow>,result: Q.Executed<World(),Q.Error<Error>,EntityRow>) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},+rows}: xp_lifecycle(projectiles,xp_route_rows(rows,args_tick(args)),world)
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
def movement_done(+args: Args,+projectiles: List<&2,EntityRow>,result: Q.Executed<World(),Q.Error<Error>,Unit>) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},_}: combat_done(args,projectiles,Q.each(~Schema,~Store,~Unit,~Unit,~OpsType,~Args,~Error,~EntityRow,~plan(),~body_system,args,world))
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
def projectile_done(+args: Args,result: Q.Executed<World(),Q.Error<Error>,EntityRow>) -> Q.Executed<World(),Q.Error<Error>,EntityRow>:
  match result:
    case Q.Executed{world,T.Success{},rows}: movement_done(args,rows,Q.each(~Schema,~Store,~Unit,~Unit,~MoveOpsType,~Args,~Error,~Unit,~move_plan(),~move_system,args,world))
    case Q.Executed{world,T.Failure{error},_}: Q.Executed{world,T.Failure{error},[]}
def execute(world: World(),+args: Args) -> Q.Executed<World(),Q.Error<Error>,EntityRow>: projectile_done(args,Q.each(~Schema,~Store,~Unit,~Unit,~ProjectileOpsType,~Args,~Error,~EntityRow,~projectile_plan(),~projectile_system,args,world))

def owned(rows: List<&2,U32>) -> U32:
  match rows:
    case []: 0
    case n <> rest: (Bool.to_u32(U32.is_lt(0,n)) + owned(rest) : U32)
def offer_candidate(allowed: Bool,+kind: U32,+id: U32,+level: U32) -> Offer:
  match allowed:
    case True{}: Offer{kind,id,(level + 1 : U32)}
    case False{}: Offer{2,0,1}
def offer_for(+roll: U32,+weapons: List<&2,U32>,+passives: List<&2,U32>) -> Offer:
  match roll:
    case +roll: offer_candidate(Bool.and(U32.is_lt(at(weapons,(roll % 24 : U32)),8),Bool.or(U32.is_lt(0,at(weapons,(roll % 24 : U32))),U32.is_lt(owned(weapons),6))),0,(roll % 24 : U32),at(weapons,(roll % 24 : U32)))
def passive_offer(+id: U32,+passives: List<&2,U32>) -> Offer:
  offer_candidate(Bool.and(U32.is_lt(at(passives,id),5),Bool.or(U32.is_lt(0,at(passives,id)),U32.is_lt(owned(passives),6))),1,id,at(passives,id))
def prefer_offer(valid: Bool,candidate: Offer,fallback: Offer) -> Offer:
  match valid:
    case True{}: candidate
    case False{}: fallback
def equipped_offer(weapons: List<&2,U32>,+index: U32) -> Offer:
  match weapons:
    case []: Offer{2,0,1}
    case +level <> rest: prefer_offer(Bool.and(U32.is_lt(0,level),U32.is_lt(level,8)),Offer{0,index,(level + 1 : U32)},equipped_offer(rest,(index + 1 : U32)))
def evolution_passive(+id: U32) -> U32: at([1,12,2,4,11,4,0,3,10,3,1,9,7,12,2,0,4,2,3,6,8,10,3,12],id)
def evolution_offer(weapons: List<&2,U32>,+index: U32,+passives: List<&2,U32>) -> Offer:
  match weapons:
    case []: Offer{4,0,50}
    case +level <> rest: prefer_offer(Bool.and(U32.is_eq(level,8),U32.is_lt(0,at(passives,evolution_passive(index)))),Offer{3,index,9},evolution_offer(rest,(index + 1 : U32),passives))
def make_offers(+seed: U32,+weapons: List<&2,U32>,+passives: List<&2,U32>) -> List<&2,Offer>:
  [equipped_offer(weapons,0),passive_offer(((seed * 7 + 3) % 18 : U32),passives),offer_for((seed % 24 : U32),weapons,passives)]
def union_offer(remaining: Nat,+id: U32,+weapons: List<&2,U32>,+fallback: Offer) -> Offer:
  match remaining:
    case 0n: fallback
    case 1n+rest: prefer_offer(Bool.and(Bool.and(U32.is_le(8,at(weapons,union_base(id))),U32.is_le(at(weapons,union_base(id)),9)),Bool.and(U32.is_le(8,at(weapons,union_partner(id))),U32.is_le(at(weapons,union_partner(id)),9))),Offer{5,id,(10 + id : U32)},union_offer(rest,(id + 1 : U32),weapons,fallback))
def chest_offers(+seed: U32,+weapons: List<&2,U32>,+passives: List<&2,U32>) -> List<&2,Offer>:
  [union_offer(6n,0,weapons,evolution_offer(weapons,0,passives)),evolution_offer(weapons,0,passives),Offer{4,0,50}]
def phase_offers(chest: Bool,+seed: U32,+weapons: List<&2,U32>,+passives: List<&2,U32>) -> List<&2,Offer>:
  match chest:
    case True{}: chest_offers(seed,weapons,passives)
    case False{}: make_offers(seed,weapons,passives)
def banned(+mask: U32,+id: U32) -> Bool: U32.is_lt(0,U32.and(mask,U32.shln(1,U32.to_nat(id))))
def filter_offer(offer: Offer,+bannedWeapons: U32,+bannedPassives: U32) -> Offer:
  match offer:
    case Offer{0,+id,+level}: prefer_offer(Bool.not(banned(bannedWeapons,id)),Offer{0,id,level},Offer{2,0,1})
    case Offer{1,+id,+level}: prefer_offer(Bool.not(banned(bannedPassives,id)),Offer{1,id,level},Offer{2,0,1})
    case offer: offer
def filter_offers(offers: List<&2,Offer>,+bannedWeapons: U32,+bannedPassives: U32) -> List<&2,Offer>:
  match offers:
    case []: []
    case offer <> rest: filter_offer(offer,bannedWeapons,bannedPassives) <> filter_offers(rest,bannedWeapons,bannedPassives)
def evolve_weapon(weapons: List<&2,U32>,+id: U32) -> List<&2,U32>:
  match weapons id:
    case Nil{} _: []
    case Con{+level,rest} 0: U32.min(9,(level + Bool.to_u32(U32.is_eq(level,8)) : U32)) <> rest
    case Con{level,rest} +id: level <> evolve_weapon(rest,(id - 1 : U32))
def upgrade(offer: Offer,run: Run) -> Run:
  match offer run:
    case Offer{0,+id,_} Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,bump(weapons,id),passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
    case Offer{5,+id,_} Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,U32.min(maxHp,(hp + 30 : U32)),maxHp,xp,need,level,kills,(gold + 50 : U32),character,set_at(set_at(weapons,union_partner(id),0),union_base(id),(10 + id : U32)),passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
    case Offer{3,+id,_} Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,U32.min(maxHp,(hp + 20 : U32)),maxHp,xp,need,level,kills,(gold + 25 : U32),character,evolve_weapon(weapons,id),passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
    case Offer{4,_,+amount} Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,(gold + amount : U32),character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
    case Offer{1,+id,_} Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,U32.min((maxHp + maxHp * 20 / (100 + at(passives,7) * 20) * Bool.to_u32(U32.is_eq(id,7)) : U32),(hp + maxHp * 20 / (100 + at(passives,7) * 20) * Bool.to_u32(U32.is_eq(id,7)) : U32)),(maxHp + maxHp * 20 / (100 + at(passives,7) * 20) * Bool.to_u32(U32.is_eq(id,7)) : U32),xp,need,level,kills,gold,character,weapons,bump(passives,id),invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
    case Offer{_,_,_} Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{0,tick,px,py,U32.min(maxHp,(hp + 30 : U32)),maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def offer_at(offers: List<&2,Offer>,index: U32) -> Offer:
  match offers index:
    case Nil{} _: Offer{2,0,1}
    case Con{offer,_} 0: offer
    case Con{_,rest} index: offer_at(rest,(index - 1 : U32))
def choose_unchecked(state: State,+choice: U32) -> Packet:
  match state:
    case State{world,Run{0,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case State{world,run,+bodies,+offers,+snapshots,pending}: packet(State{world,upgrade(offer_at(offers,U32.min(choice,2)),run),bodies,[],snapshots,pending})
def choose_raw(state: State,+choice: U32) -> Packet:
  match state:
    case State{world,Run{3,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,Run{3,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case State{world,Run{4,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,Run{4,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case state: choose_unchecked(state,choice)
type Totals is Data: Totals{hit: U32,xp: U32,gold: U32,heal: U32,chest: U32,kills: U32,bodies: List<&2,Body>,snapshots: List<&2,Snapshot>,relic: U32}
def accumulate(rows: List<&2,EntityRow>,+hit: U32,+xp: U32,+gold: U32,+heal: U32,+chest: U32,+kills: U32,+bodies: List<&2,Body>,+snapshots: List<&2,Snapshot>,+relicTotal: U32) -> Totals:
  match rows:
    case []: Totals{hit,xp,gold,heal,chest,kills,bodies,snapshots,relicTotal}
    case EntityRow{Row{+body,+h,+x,+g,+he,+c,+k,+relic},+motion} <> rest: accumulate(rest,(hit + h : U32),(xp + x : U32),(gold + g : U32),(heal + he : U32),(chest + c : U32),(kills + k : U32),body <> bodies,Snapshot{body,motion} <> snapshots,(relicTotal + relic : U32))
def phase_for(dead: Bool,won: Bool,chest: Bool,levelup: Bool) -> U32:
  match dead won chest levelup:
    case True{} _ _ _: 3
    case _ True{} _ _: 4
    case _ _ True{} _: 2
    case _ _ _ True{}: 1
    case _ _ _ _: 0
def boss_kills(rows: List<&2,EntityRow>) -> U32:
  match rows:
    case []: 0
    case EntityRow{Row{Body{_,_,_,+variant,_,_,_,_,_},_,_,_,_,_,+killed,+relic},_} <> rest: (killed * Bool.to_u32(U32.is_le(20,variant)) + boss_kills(rest) : U32)
def earned_xp(+earned: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32) -> U32: (earned * (100 + at(passives,9) * 10 + at(passives,14) * 10 + meta_rank(meta,7) * 5 + 30 * Bool.to_u32(U32.is_eq(arcana,5))) / 100 : U32)
def player_damage(+hit: U32,+invuln: U32,+passives: List<&2,U32>,+meta: U32,+arcana: U32,+character: U32) -> U32:
  (U32.max(1,lose(9,(at(passives,6) + meta_rank(meta,3) + 3 * Bool.to_u32(U32.is_eq(arcana,4)) + Bool.to_u32(U32.is_eq(character,3)) : U32))) * Bool.to_u32(Bool.and(U32.is_lt(0,hit),U32.is_eq(invuln,0))) : U32)
# Armor remains valuable, but crowd pressure cannot be reduced to one damage.
# The last minute is a deliberate lethal gauntlet rather than an empty victory lap.
def pressure_damage(+hit: U32,+tick: U32,+mode: U32,+invuln: U32,passives: List<&2,U32>,meta: U32,arcana: U32,character: U32) -> U32:
  ((player_damage(hit,invuln,passives,meta,arcana,character) + (tick / 3600 + U32.min(6,(hit / 3 : U32)) + U32.min(24,(lose(tick,lose(run_length(mode),3600)) / 150 : U32)) + 2000 * Bool.to_u32(U32.is_le(1000,hit))) * Bool.to_u32(Bool.and(U32.is_lt(0,hit),U32.is_eq(invuln,0)))) : U32)
def revival_available(+hp: U32,+passives: List<&2,U32>,+meta: U32,+used: U32) -> Bool: Bool.and(U32.is_eq(hp,0),U32.is_lt(used,(meta_rank(meta,9) + at(passives,13) : U32)))
def revive_hp(revive: Bool,hp: U32,maxHp: U32) -> U32:
  match revive:
    case True{}: maxHp
    case False{}: hp
def remainder_xp(+xp: U32,+need: U32) -> U32: lose(xp,(need * Bool.to_u32(U32.is_le(need,xp)) : U32))
def reward_repeat(count: Nat,+kind: U32) -> List<&2,U32>:
  match count:
    case 0n: []
    case 1n+rest: kind <> reward_repeat(rest,kind)
def reward_extra(levelup: Bool,queue: List<&2,U32>) -> List<&2,U32>:
  match levelup:
    case True{}: 1 <> queue
    case False{}: queue
def reward_backlog(+chests: U32,levelup: Bool) -> List<&2,U32>:
  reward_extra(Bool.and(U32.is_lt(0,chests),levelup),reward_repeat(U32.to_nat(dec(chests)),2))
def finish_run(world: World(),run: Run,+bodies: List<&2,Body>,+offers: List<&2,Offer>,snapshots: List<&2,Snapshot>,pending: List<&2,U32>) -> Packet: packet(State{world,run,bodies,offers,snapshots,pending})
def finish_values(world: World(),run: Run,+bodies: List<&2,Body>,+totalXp: U32,+health: U32,+wasHit: U32,+chest: U32,+killed: U32,+coins: U32,+bossKills: U32,+snapshots: List<&2,Snapshot>,+relicEvent: U32) -> Packet:
  match run:
    case Run{_,+tick,+px,+py,_,+maxHp,_,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}:
      finish_run(world,Run{phase_for(Bool.and(Bool.and(U32.is_eq(health,0),Bool.not(revival_available(health,passives,meta,revivals))),Bool.or(U32.is_eq(mode,2),U32.is_lt(tick,run_length(mode)))),Bool.and(Bool.and(Bool.not(U32.is_eq(mode,2)),U32.is_le(run_length(mode),tick)),Bool.and(U32.is_eq(health,0),Bool.not(revival_available(health,passives,meta,revivals)))),U32.is_lt(0,chest),U32.is_le(need,totalXp)),tick,px,py,revive_hp(revival_available(health,passives,meta,revivals),health,maxHp),maxHp,remainder_xp(totalXp,need),(need + lose(next_xp_need(level),need) * Bool.to_u32(U32.is_le(need,totalXp)) : U32),(level + Bool.to_u32(U32.is_le(need,totalXp)) : U32),(kills + killed : U32),(gold + 300 * Bool.to_u32(Bool.and(U32.is_eq(mode,3),U32.is_eq(18000,tick))) + (50 + level * 5 + kills / 20) * Bool.to_u32(Bool.and(U32.is_eq(health,0),Bool.not(revival_available(health,passives,meta,revivals)))) + coins * (100 + at(passives,15) * 15 + at(passives,14) * 10 + 50 * Bool.to_u32(U32.is_eq(mode,1)) + meta_rank(meta,8) * 10 + 25 * Bool.to_u32(U32.is_eq(arcana,6))) / 100 : U32),character,weapons,passives,U32.max(dec(invuln),(30 * wasHit + 180 * Bool.to_u32(revival_available(health,passives,meta,revivals)) : U32)),(seed + 1 : U32),stage,arcana,meta,(revivals + Bool.to_u32(revival_available(health,passives,meta,revivals)) : U32),(bosses + bossKills : U32),mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,U32.max(relicCollected,relicEvent)},bodies,filter_offers(phase_offers(U32.is_lt(0,chest),(seed + level * 13 : U32),weapons,passives),bannedWeapons,bannedPassives),snapshots,reward_backlog(chest,U32.is_le(need,totalXp)))
def heal_after_damage(hp: U32,damage: U32,healing: U32,healingPercent: U32,maxHp: U32) -> U32:
  U32.min(maxHp,(lose(hp,damage) + healing * healingPercent / 100 : U32))
def add_killed_kind(known: Bool,+kind: U32,kinds: List<&2,U32>) -> List<&2,U32>:
  match known:
    case True{}: kinds
    case False{}: kind <> kinds
def killed_kinds(rows: List<&2,EntityRow>,+kinds: List<&2,U32>) -> List<&2,U32>:
  match rows:
    case []: kinds
    case EntityRow{Row{Body{_,_,_,+variant,_,_,_,_,_},_,_,_,_,_,1,+relic},_} <> rest: killed_kinds(rest,add_killed_kind(contains(kinds,variant),variant,kinds))
    case _ <> rest: killed_kinds(rest,kinds)
def run_kinds(run: Run) -> List<&2,U32>:
  match run:
    case Run{_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,kinds,+relicCollected}: kinds
def finish_stats(world: World(),run: Run,totals: Totals,+bossKills: U32,+kinds: List<&2,U32>) -> Packet:
  match run totals:
    case Run{_,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected} Totals{+hit,+earned,+coins,+heal,+chest,+killed,+bodies,+snapshots,+relic}:
      finish_values(world,Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,kinds,relicCollected},bodies,(xp + earned_xp(earned,passives,meta,arcana) : U32),heal_after_damage(hp,(pressure_damage(hit,tick,mode,invuln,passives,meta,arcana,character) + E.hazard(stage,tick,px,py) * Bool.to_u32(U32.is_eq(invuln,0)) : U32),(heal + killed * Bool.to_u32(Bool.and(U32.is_eq((tick % 12 : U32),0),Bool.and(U32.is_eq(arcana,9),Bool.or(U32.is_lt(0,at(weapons,4)),U32.is_lt(0,at(weapons,19)))))) + (meta_rank(meta,2) + at(passives,11) + 2 * Bool.to_u32(U32.is_eq(arcana,9)) + Bool.to_u32(U32.is_eq(character,2))) * Bool.to_u32(U32.is_eq((tick % 60 : U32),0)) : U32),(100 + at(passives,17) * 20 + 30 * Bool.to_u32(U32.is_eq(arcana,10)) : U32),maxHp),Bool.to_u32(Bool.and(U32.is_lt(0,hit),U32.is_eq(invuln,0))),chest,killed,coins,bossKills,snapshots,relic)
def executed(+run: Run,result: Q.Executed<World(),Q.Error<Error>,EntityRow>) -> Packet:
  match result:
    case Q.Executed{world,T.Success{},+rows}: finish_stats(world,run,accumulate(rows,0,0,0,0,0,0,[],[],0),boss_kills(rows),killed_kinds(rows,run_kinds(run)))
    case Q.Executed{_,T.Failure{_},_}: Failed{"ECS query failed"}
def advance_raw(state: State,+dx: F32,+dy: F32) -> Packet:
  match state:
    case State{world,Run{0,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+snapshot,_,+snapshots,pending}:
      executed(Run{0,(tick + 1 : U32),F32.clamp((px + dx * (2.5 * speed_bonus(passives,meta,arcana,character) : F32) / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),20.0,3580.0),F32.clamp((py + dy * (2.5 * speed_bonus(passives,meta,arcana,character) : F32) / F32.max(1.0,F32.sqrt((dx * dx + dy * dy : F32))) : F32),20.0,3580.0),hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},execute(world,combat_args(Run{0,(tick + 1 : U32),px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},snapshot,dx,dy,snapshots)))
    case state: packet(state)
def started(+character: U32,+meta: U32,created: W.Creation<Schema,Store,Unit,Unit>) -> Packet:
  match created:
    case W.Created{_,world}: packet(State{W.barrier(~Schema,~Store,~Unit,~Unit,boot_pool(1004n,0,world)),Run{0,0,1800.0,1800.0,(initial_health(character,meta) * 70 / 100 : U32),(initial_health(character,meta) * 70 / 100 : U32),0,100,1,0,0,character,bump([0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],starter(character)),[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],0,12345,0,0,meta,0,0,0,3,3,3,0,0,[],0},[],[],[],[]})
    case W.CreateRejected{_,_}: Failed{"World creation refused"}
def start(character: U32,meta: U32) -> Packet: started(U32.min(character,7),meta,W.create(~Schema,~Store,~Unit,~Unit,~empty,W.factory(),Unit{}))

def seeded_run(run: Run,+selectedSeed: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,_,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{phase,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,selectedSeed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def seeded_packet(packetValue: Packet,+selectedSeed: U32) -> Packet:
  match packetValue:
    case Packet{State{world,run,bodies,offers,snapshots,pending},_}: packet(State{world,seeded_run(run,selectedSeed),bodies,offers,snapshots,pending})
    case Failed{error}: Failed{error}
def start_seed(character: U32,meta: U32,seed: U32) -> Packet: seeded_packet(start(character,meta),seed)

def mode_configured(run: Run,+selected: U32) -> Run:
  match run:
    case Run{+phase,0,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: configured(Run{phase,0,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,choose_id(U32.is_eq(selected,3),0,meta),revivals,bosses,U32.min(selected,3),rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},stage,arcana)
    case run: run
def set_mode(state: State,+selected: U32) -> Packet:
  match state:
    case State{world,Run{+phase,0,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,mode_configured(Run{phase,0,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},selected),bodies,offers,snapshots,pending})
    case state: packet(state)
def configure_unlocks(state: State,+unlockedMask: U32) -> Packet:
  match state:
    case State{world,Run{+phase,0,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,Run{phase,0,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,U32.or(bannedWeapons,U32.and(16777215,U32.xor(unlockedMask,16777215))),bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case state: packet(state)

def reroll(state: State) -> Packet:
  match state:
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,0,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,Run{1,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,0,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,_,+snapshots,pending}: packet(State{world,Run{1,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,(seed + 41 : U32),stage,arcana,meta,revivals,bosses,mode,dec(rerolls),banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,filter_offers(make_offers((seed + 41 : U32),weapons,passives),bannedWeapons,bannedPassives),snapshots,pending})
    case state: packet(state)

def skip_raw(state: State) -> Packet:
  match state:
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,0,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,Run{1,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,0,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,_,+snapshots,pending}: packet(State{world,Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,(gold + 10 : U32),character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,dec(skips),bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,[],snapshots,pending})
    case state: packet(state)

def banish_offer(run: Run,offer: Offer) -> Run:
  match run offer:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected} Offer{0,+id,_}: Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,dec(banishes),skips,U32.or(bannedWeapons,U32.shln(1,U32.to_nat(id))),bannedPassives,enemyKinds,relicCollected}
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected} Offer{1,+id,_}: Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,dec(banishes),skips,bannedWeapons,U32.or(bannedPassives,U32.shln(1,U32.to_nat(id))),enemyKinds,relicCollected}
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected} _: Run{0,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}

def banish_raw(state: State,+choice: U32) -> Packet:
  match state:
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,0,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,Run{1,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,0,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},bodies,offers,snapshots,pending})
    case State{world,Run{1,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected},+bodies,+offers,+snapshots,pending}: packet(State{world,banish_offer(Run{1,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected},offer_at(offers,U32.min(choice,2))),bodies,[],snapshots,pending})
    case state: packet(state)

# Deferred rewards are owned by the game state. The legacy advance entry pauses;
# advance_live lets a host keep the arena running until the player opens a choice.
def run_phase(run: Run) -> U32:
  match run:
    case Run{phase,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: phase
def run_level(run: Run) -> U32:
  match run:
    case Run{_,_,_,_,_,_,_,_,level,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: level
def with_phase(run: Run,selected: U32) -> Run:
  match run:
    case Run{+phase,+tick,+px,+py,+hp,+maxHp,+xp,+need,+level,+kills,+gold,+character,+weapons,+passives,+invuln,+seed,+stage,+arcana,+meta,+revivals,+bosses,+mode,+rerolls,+banishes,+skips,+bannedWeapons,+bannedPassives,+enemyKinds,+relicCollected}: Run{selected,tick,px,py,hp,maxHp,xp,need,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}
def pending_append(rows: List<&2,U32>,+kind: U32) -> List<&2,U32>:
  match rows:
    case []: [kind]
    case head <> rest: head <> pending_append(rest,kind)
def pending_add(active: Bool,rows: List<&2,U32>,kind: U32) -> List<&2,U32>:
  match active:
    case True{}: pending_append(rows,kind)
    case False{}: rows
def pending_join(left: List<&2,U32>,+right: List<&2,U32>) -> List<&2,U32>:
  match left:
    case []: right
    case head <> rest: head <> pending_join(rest,right)
def terminal_queue(terminal: Bool,pending: List<&2,U32>) -> List<&2,U32>:
  match terminal:
    case True{}: []
    case False{}: pending
def attach_pending(result: Packet,pending: List<&2,U32>) -> Packet:
  match result:
    case Packet{State{world,+run,bodies,offers,snapshots,newPending},_}: packet(State{world,run,bodies,offers,snapshots,terminal_queue(U32.is_le(3,run_phase(run)),pending_join(pending,newPending))})
    case result: result
def advance(state: State,dx: F32,dy: F32) -> Packet:
  match state:
    case State{world,run,bodies,offers,snapshots,+pending}: attach_pending(advance_raw(State{world,run,bodies,offers,snapshots,[]},dx,dy),pending)
def reward_offers(run: Run,chest: Bool) -> List<&2,Offer>:
  match run:
    case Run{_,_,_,_,_,_,_,_,+level,_,_,_,+weapons,+passives,_,+seed,_,_,_,_,_,_,_,_,_,+bannedWeapons,+bannedPassives,_,_}: filter_offers(phase_offers(chest,(seed + level * 13 : U32),weapons,passives),bannedWeapons,bannedPassives)
def promote_ready(ready: Bool,world: World(),+run: Run,bodies: List<&2,Body>,offers: List<&2,Offer>,snapshots: List<&2,Snapshot>,pending: List<&2,U32>) -> Packet:
  match ready pending:
    case True{} +kind <> rest: packet(State{world,with_phase(run,kind),bodies,reward_offers(run,U32.is_eq(kind,2)),snapshots,rest})
    case _ pending: packet(State{world,run,bodies,offers,snapshots,pending})
def promote(result: Packet) -> Packet:
  match result:
    case Packet{State{world,+run,bodies,offers,snapshots,pending},_}: promote_ready(U32.is_eq(run_phase(run),0),world,run,bodies,offers,snapshots,pending)
    case result: result
def choose(state: State,choice: U32) -> Packet: promote(choose_raw(state,choice))
def skip(state: State) -> Packet: promote(skip_raw(state))
def banish(state: State,choice: U32) -> Packet: promote(banish_raw(state,choice))
def live_selected(terminal: Bool,held: Bool,+oldPhase: U32,+oldLevel: U32,oldOffers: List<&2,Offer>,pending: List<&2,U32>,world: World(),+run: Run,bodies: List<&2,Body>,offers: List<&2,Offer>,snapshots: List<&2,Snapshot>) -> Packet:
  match terminal held:
    case True{} _: packet(State{world,run,bodies,[],snapshots,[]})
    case False{} True{}: packet(State{world,with_phase(run,oldPhase),bodies,oldOffers,snapshots,pending_add(Bool.or(U32.is_eq(run_phase(run),1),U32.is_eq(run_phase(run),2)),pending,run_phase(run))})
    case False{} False{}: packet(State{world,run,bodies,offers,snapshots,pending})
def live_result(+oldPhase: U32,+oldLevel: U32,oldOffers: List<&2,Offer>,pending: List<&2,U32>,result: Packet) -> Packet:
  match result:
    case Packet{State{world,+run,bodies,+offers,snapshots,newPending},_}: live_selected(Bool.or(U32.is_eq(run_phase(run),3),U32.is_eq(run_phase(run),4)),Bool.or(U32.is_eq(oldPhase,1),U32.is_eq(oldPhase,2)),oldPhase,oldLevel,oldOffers,pending_join(pending,newPending),world,run,bodies,offers,snapshots)
    case result: result
def advance_live(state: State,dx: F32,dy: F32) -> Packet:
  match state:
    case State{world,+run,bodies,+offers,snapshots,pending}: live_result(run_phase(run),run_level(run),offers,pending,advance_raw(State{world,with_phase(run,choose_id(Bool.or(U32.is_eq(run_phase(run),1),U32.is_eq(run_phase(run),2)),0,run_phase(run))),bodies,offers,snapshots,[]},dx,dy))
