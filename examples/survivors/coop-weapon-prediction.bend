import Base
import ./game.bend as G
import ./coop-prediction.bend as P
import ./coop-session.bend as S
import ./player-movement.bend as M
import ./projectile-pool.bend as SP
import ./body-index.bend as BI
import ./coop-weapon-prediction-policy.bend as Kernel

# Detached visual forecast only. No World, damage resolution, pickups or rewards
# can be passed to this type. Targets are frozen observations for visual aiming.
type Frame is Data: Frame{player:U32,run:G.Run,shots:List<&2,G.Snapshot>,targets:List<&2,G.Body>,ownSeeds:List<&2,U32>,births:BI.Index<U32>}
def position(frame:Frame) -> M.Point:
  match frame:
    case Frame{_,+run,_,_,_,_}: M.Point{G.run_px(run),G.run_py(run)}
def own_shot(+player:U32,snapshot:G.Snapshot,+tail:List<&2,G.Snapshot>) -> List<&2,G.Snapshot>:
  match snapshot:
    case G.Snapshot{G.Body{+x,+y,1,+variant,+hp,+maxHp,+age,+seed,+radius},G.Motion{+vx,+vy,+life,+pierce,+visited,+slow,+burn,+owner,+slot}}:
      Bool.pick(List<&2,G.Snapshot>,U32.is_eq((slot / 65536 : U32),player),G.Snapshot{G.Body{x,y,1,variant,hp,maxHp,age,seed,radius},G.Motion{vx,vy,life,pierce,visited,slow,burn,owner,slot}} <> tail,tail)
    case _: tail
def own_shots(rows:List<&2,G.Snapshot>,+player:U32) -> List<&2,G.Snapshot>:
  match rows:
    case []: []
    case head <> tail: own_shot(player,head,own_shots(tail,player))
def owned_seeds(player:U32) -> List<&2,U32>: Kernel.owned_seeds(player)
# Immutable birth identity is separate from projectile visual age and the
# authoritative/predicted world clock, which may jump when an ACK is rebased.
def birth_at(births:BI.Index<U32>,tick:U32,snapshot:G.Snapshot) -> U32:
  match snapshot:
    case G.Snapshot{G.Body{_,_,_,_,_,_,age,seed,_},_}: BI.get(~U32,births,seed,(tick - age : U32))
def birth_entry(+snapshot:G.Snapshot,+tick:U32,+prior:BI.Index<U32>,fresh:BI.Index<U32>,index:BI.Index<U32>) -> BI.Index<U32>:
  match snapshot:
    case G.Snapshot{G.Body{_,_,_,_,_,_,_,+seed,_},_}: BI.insert(~U32,index,seed,BI.get(~U32,fresh,seed,birth_at(prior,tick,snapshot)))
def birth_map(rows:List<&2,G.Snapshot>,+tick:U32,+prior:BI.Index<U32>,+fresh:BI.Index<U32>,index:BI.Index<U32>) -> BI.Index<U32>:
  match rows:
    case []: index
    case head <> tail: birth_map(tail,tick,prior,fresh,birth_entry(head,tick,prior,fresh,index))
def initialize_owned(+player:U32,+run:G.Run,+shots:List<&2,G.Snapshot>,bodies:List<&2,G.Body>) -> Frame:
  Frame{player,run,shots,G.enemy_geometry(bodies),owned_seeds(player),birth_map(shots,G.run_tick(run),BI.Empty{},BI.Empty{},BI.Empty{})}
def initialize(+player:U32,run:G.Run,shots:List<&2,G.Snapshot>,bodies:List<&2,G.Body>) -> Frame:
  initialize_owned(player,run,own_shots(shots,player),bodies)
def contains(rows:List<&2,U32>,+seed:U32) -> Bool:
  match rows:
    case []: False{}
    case head <> tail: Bool.or(U32.is_eq(head,seed),contains(tail,seed))
def owns_seed(frame:Frame,seed:U32) -> Bool:
  match frame:
    case Frame{_,_,_,_,ids,_}: contains(ids,seed)
def snapshot_live(snapshot:G.Snapshot) -> Bool:
  match snapshot:
    case G.Snapshot{G.Body{_,_,kind,_,_,_,_,_,_},G.Motion{_,_,life,pierce,_,_,_,_,_}}: Bool.and(U32.is_eq(kind,1),Bool.and(U32.is_gt(life,0),U32.is_gt(pierce,0)))
def spawn(+player:U32,+args:G.Args,seed:U32,request:Maybe<&2,SP.Request>) -> G.EntityRow:
  match request:
    case None{}: G.dormant_entity(0.0,0.0,seed)
    case Some{SP.Request{+owner,+slot,level}}: G.with_shot_owner(G.shot_spawn_ready(True{},seed,owner,slot,level,args),owner,(slot + player * 65536 : U32))
def live_step(+args:G.Args,snapshot:G.Snapshot) -> G.EntityRow:
  match snapshot:
    case G.Snapshot{G.Body{+x,+y,+kind,+variant,+hp,+maximum,+age,+seed,+radius},G.Motion{+vx,+vy,+life,+pierce,+visited,+slow,+burn,+owner,+slot}}:
      G.with_shot_owner(G.shot_step_aim(G.Body{x,y,kind,variant,hp,maximum,age,seed,radius},G.Motion{vx,vy,life,pierce,visited,slow,burn,owner,slot},args,G.nearest_from_args(args,x,y)),owner,slot)
def retain_snapshot(row:G.EntityRow,tail:List<&2,G.Snapshot>) -> List<&2,G.Snapshot>:
  match row:
    case G.EntityRow{G.Row{G.Body{x,y,1,variant,hp,maximum,age,seed,radius},_,_,_,_,_,_,_},motion}: G.Snapshot{G.Body{x,y,1,variant,hp,maximum,age,seed,radius},motion} <> tail
    case _: tail
def update_existing(rows:List<&2,G.Snapshot>,+args:G.Args) -> List<&2,G.Snapshot>:
  match rows:
    case []: []
    case head <> tail: retain_snapshot(live_step(args,head),update_existing(tail,args))
def spawn_assignments(index:BI.Index<SP.Request>,+player:U32,+args:G.Args) -> List<&2,G.Snapshot>:
  match index:
    case BI.Empty{}: []
    case BI.Item{seed,request}: retain_snapshot(spawn(player,args,seed,Some{request}),[])
    case BI.Fork{_,_,zero,one}: List.append(&2,G.Snapshot,spawn_assignments(zero,player,args),spawn_assignments(one,player,args))
def spawned(plan:SP.Plan,player:U32,args:G.Args) -> List<&2,G.Snapshot>:
  match plan:
    case SP.Plan{index,_}: spawn_assignments(index,player,args)
def moved_run(+run:G.Run,point:M.Point) -> G.Run:
  match point:
    case M.Point{x,y}: G.with_py(G.with_px(run,x),y)
def move_run(+run:G.Run,dx:F32,dy:F32) -> G.Run:
  moved_run(run,M.move_point(G.run_px(run),G.run_py(run),G.run_step_distance(run),dx,dy))
def visual_args(run:G.Run,targets:List<&2,G.Body>,dx:F32,dy:F32,shots:List<&2,G.Snapshot>) -> G.Args: G.Args{run,targets,dx,dy,shots,[]}
def assignment_births(index:BI.Index<SP.Request>,+tick:U32) -> BI.Index<U32>:
  match index:
    case BI.Empty{}: BI.Empty{}
    case BI.Item{seed,_}: BI.Item{seed,tick}
    case BI.Fork{sample,mask,zero,one}: BI.Fork{sample,mask,assignment_births(zero,tick),assignment_births(one,tick)}
def plan_births(plan:SP.Plan,tick:U32) -> BI.Index<U32>:
  match plan:
    case SP.Plan{index,_}: assignment_births(index,tick)
def planned(+player:U32,+run:G.Run,+shots:List<&2,G.Snapshot>,+targets:List<&2,G.Body>,ids:List<&2,U32>,births:BI.Index<U32>,+dx:F32,+dy:F32,+plan:SP.Plan) -> Frame:
  +updated = List.append(&2,G.Snapshot,update_existing(shots,visual_args(run,targets,dx,dy,shots)),spawned(plan,player,visual_args(run,targets,dx,dy,shots)))
  Frame{player,move_run(run,dx,dy),updated,targets,ids,birth_map(updated,G.run_tick(run),births,plan_births(plan,G.run_tick(run)),BI.Empty{})}
def clocked(+player:U32,+run:G.Run,+shots:List<&2,G.Snapshot>,+targets:List<&2,G.Body>,ids:List<&2,U32>,births:BI.Index<U32>,+dx:F32,+dy:F32) -> Frame:
  planned(player,run,shots,targets,ids,births,dx,dy,G.player_plan(G.PlayerView{player,run,dx,dy},shots))
def advance_unchecked(frame:Frame,x:U32,y:U32) -> Frame:
  match frame:
    case Frame{player,+run,shots,targets,ids,births}: clocked(player,G.with_tick(run,(G.run_tick(run) + 1 : U32)),shots,targets,ids,births,S.axis(x),S.axis(y))
def advance_allowed(allowed:Bool,frame:Frame,x:U32,y:U32) -> Frame: Kernel.guard(~Frame,~advance_unchecked,allowed,frame,x,y)
def eligible(frame:Frame,+x:U32,+y:U32) -> Bool:
  match frame:
    case Frame{_,+run,_,_,_,_}: Kernel.eligible(G.run_phase(run),G.run_hp(run),x,y)
def advance(+frame:Frame,+x:U32,+y:U32) -> Frame: advance_allowed(eligible(frame,x,y),frame,x,y)
def advance_steps(fuel:Nat,frame:Frame,x:U32,y:U32) -> Frame: Kernel.advance_steps(~Frame,~advance,fuel,frame,x,y)
def forecast(frame:Frame,prediction:P.State) -> Frame: Kernel.forecast(~Frame,~advance,frame,prediction)

# Native data JSON is an IO encoding: lists retain Bend's Con/Nil ABI so the
# browser can pass the parsed Frame directly back into this module.
def native_nums(rows:List<&2,U32>) -> String:
  match rows:
    case []: "{\"$\":\"Nil\"}"
    case head <> tail: "{\"$\":\"Con\",\"head\":" ++ U32.show(head) ++ ",\"tail\":" ++ native_nums(tail) ++ "}"
def native_run(value:G.Run) -> String:
  match value:
    case G.Run{phase,tick,px,py,hp,maxHp,xp,xpNeed,level,kills,gold,character,weapons,passives,invuln,seed,stage,arcana,meta,revivals,bosses,mode,rerolls,banishes,skips,bannedWeapons,bannedPassives,enemyKinds,relicCollected}: "{\"$\":\"Run\"" ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"px\":" ++ F32.show(px) ++ ",\"py\":" ++ F32.show(py) ++ ",\"hp\":" ++ U32.show(hp) ++ ",\"maxHp\":" ++ U32.show(maxHp) ++ ",\"xp\":" ++ U32.show(xp) ++ ",\"xpNeed\":" ++ U32.show(xpNeed) ++ ",\"level\":" ++ U32.show(level) ++ ",\"kills\":" ++ U32.show(kills) ++ ",\"gold\":" ++ U32.show(gold) ++ ",\"character\":" ++ U32.show(character) ++ ",\"weapons\":" ++ native_nums(weapons) ++ ",\"passives\":" ++ native_nums(passives) ++ ",\"invuln\":" ++ U32.show(invuln) ++ ",\"seed\":" ++ U32.show(seed) ++ ",\"stage\":" ++ U32.show(stage) ++ ",\"arcana\":" ++ U32.show(arcana) ++ ",\"meta\":" ++ U32.show(meta) ++ ",\"revivals\":" ++ U32.show(revivals) ++ ",\"bosses\":" ++ U32.show(bosses) ++ ",\"mode\":" ++ U32.show(mode) ++ ",\"rerolls\":" ++ U32.show(rerolls) ++ ",\"banishes\":" ++ U32.show(banishes) ++ ",\"skips\":" ++ U32.show(skips) ++ ",\"bannedWeapons\":" ++ U32.show(bannedWeapons) ++ ",\"bannedPassives\":" ++ U32.show(bannedPassives) ++ ",\"enemyKinds\":" ++ native_nums(enemyKinds) ++ ",\"relicCollected\":" ++ U32.show(relicCollected) ++ "}"
def native_body(value:G.Body) -> String:
  match value:
    case G.Body{x,y,kind,variant,hp,maxHp,age,seed,radius}: "{\"$\":\"Body\"" ++ ",\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"kind\":" ++ U32.show(kind) ++ ",\"variant\":" ++ U32.show(variant) ++ ",\"hp\":" ++ U32.show(hp) ++ ",\"maxHp\":" ++ U32.show(maxHp) ++ ",\"age\":" ++ U32.show(age) ++ ",\"seed\":" ++ U32.show(seed) ++ ",\"radius\":" ++ F32.show(radius) ++ "}"
def native_motion(value:G.Motion) -> String:
  match value:
    case G.Motion{vx,vy,life,pierce,_,slow,burn,owner,slot}: "{\"$\":\"Motion\",\"vx\":" ++ F32.show(vx) ++ ",\"vy\":" ++ F32.show(vy) ++ ",\"life\":" ++ U32.show(life) ++ ",\"pierce\":" ++ U32.show(pierce) ++ ",\"visited\":{\"$\":\"Nil\"},\"slow\":" ++ U32.show(slow) ++ ",\"burn\":" ++ U32.show(burn) ++ ",\"ownerBase\":" ++ U32.show(owner) ++ ",\"logicalSlot\":" ++ U32.show(slot) ++ "}"
def native_snapshot(value:G.Snapshot) -> String:
  match value:
    case G.Snapshot{body,motion}: "{\"$\":\"Snapshot\",\"body\":" ++ native_body(body) ++ ",\"motion\":" ++ native_motion(motion) ++ "}"
def native_shots(rows:List<&2,G.Snapshot>) -> String:
  match rows:
    case []: "{\"$\":\"Nil\"}"
    case head <> tail: "{\"$\":\"Con\",\"head\":" ++ native_snapshot(head) ++ ",\"tail\":" ++ native_shots(tail) ++ "}"
def native_bodies(rows:List<&2,G.Body>) -> String:
  match rows:
    case []: "{\"$\":\"Nil\"}"
    case head <> tail: "{\"$\":\"Con\",\"head\":" ++ native_body(head) ++ ",\"tail\":" ++ native_bodies(tail) ++ "}"
def native_births(index:BI.Index<U32>) -> String:
  match index:
    case BI.Empty{}: "{\"$\":\"Empty\"}"
    case BI.Item{key,value}: "{\"$\":\"Item\",\"key\":" ++ U32.show(key) ++ ",\"value\":" ++ U32.show(value) ++ "}"
    case BI.Fork{sample,mask,zero,one}: "{\"$\":\"Fork\",\"sample\":" ++ U32.show(sample) ++ ",\"mask\":" ++ U32.show(mask) ++ ",\"zero\":" ++ native_births(zero) ++ ",\"one\":" ++ native_births(one) ++ "}"
def native_frame(frame:Frame) -> String:
  match frame:
    case Frame{player,run,shots,targets,ids,births}: "{\"$\":\"Frame\",\"player\":" ++ U32.show(player) ++ ",\"run\":" ++ native_run(run) ++ ",\"shots\":" ++ native_shots(shots) ++ ",\"targets\":" ++ native_bodies(targets) ++ ",\"ownSeeds\":" ++ native_nums(ids) ++ ",\"births\":" ++ native_births(births) ++ "}"
# The ownership layout is constant for this player and never belongs on each
# network snapshot. Reconstruct it in Bend at the receiving IO boundary.
def wire(frame:Frame) -> Frame:
  match frame:
    case Frame{player,run,shots,targets,_,births}: Frame{player,run,shots,targets,[],births}
def receive(frame:Frame) -> Frame:
  match frame:
    case Frame{+player,run,shots,targets,_,births}: Frame{player,run,shots,targets,owned_seeds(player),births}
def observe(run:G.Run,player:U32,snapshots:List<&2,G.Snapshot>,bodies:List<&2,G.Body>) -> String: native_frame(wire(initialize(player,run,snapshots,bodies)))
def generation(player:U32,born:U32,body:G.Body,motion:G.Motion) -> String:
  match body motion:
    case G.Body{_,_,_,_,_,_,_,_,_} G.Motion{_,_,_,_,_,_,_,owner,slot}: Kernel.generation(player,born,0,owner,slot)
def visual_body(+player:U32,born:U32,+body:G.Body,motion:G.Motion) -> String:
  match body:
    case G.Body{+x,+y,+kind,+variant,+hp,+maximum,+age,+seed,+radius}: "[" ++ F32.show(x) ++ "," ++ F32.show(y) ++ "," ++ U32.show(kind) ++ "," ++ U32.show(variant) ++ "," ++ U32.show(hp) ++ "," ++ U32.show(maximum) ++ "," ++ U32.show(age) ++ "," ++ U32.show(seed) ++ "," ++ F32.show(radius) ++ ",\"" ++ generation(player,born,G.Body{x,y,kind,variant,hp,maximum,age,seed,radius},motion) ++ "\"," ++ U32.show(player) ++ "]"
def visual_snapshot(player:U32,born:U32,snapshot:G.Snapshot) -> String:
  match snapshot:
    case G.Snapshot{body,motion}: visual_body(player,born,body,motion)
def visual_row(player:U32,tick:U32,births:BI.Index<U32>,+snapshot:G.Snapshot) -> String:
  visual_snapshot(player,birth_at(births,tick,snapshot),snapshot)
def visual_rows(rows:List<&2,G.Snapshot>,+player:U32,+tick:U32,+births:BI.Index<U32>) -> String:
  match rows:
    case []: ""
    case head <> []: visual_row(player,tick,births,head)
    case head <> tail: visual_row(player,tick,births,head) ++ "," ++ visual_rows(tail,player,tick,births)
def render(frame:Frame) -> String:
  match frame:
    case Frame{player,+run,shots,_,ids,births}: "{\"bodies\":[" ++ visual_rows(shots,player,G.run_tick(run),births) ++ "],\"ownSeeds\":[" ++ G.nums_json(ids) ++ "],\"tick\":" ++ U32.show(G.run_tick(run)) ++ ",\"px\":" ++ F32.show(G.run_px(run)) ++ ",\"py\":" ++ F32.show(G.run_py(run)) ++ "}"
