import Base

# Shared, Game-free policy at the local projectile runtime boundary. The caller
# adapts ECS rows into these DTOs; geometry, visibility and
# eviction accounting below are the same functions used by the runtime.
type Point is Data: Point{x:F32,y:F32}
type Target is Data: Target{seed:U32,generation:U32,x:F32,y:F32,radius:F32,alive:Bool}
type Hit is Data: Hit{shotId:String,tick:U32,kind:U32,targetSeed:U32,targetGeneration:U32,impactX:F32,impactY:F32,targetAtImpactX:F32,targetAtImpactY:F32,radius:F32,outcome:U32}
type VisibleShot is Data: VisibleShot{id:String,player:U32,life:U32,pending:Bool,confirmed:Bool,late:Bool,fade:U32}
type Visibility is Data: Visibility{now:U32,shots:List<&2,VisibleShot>,events:List<&2,Hit>}

def history_window() -> U32: 64
def fade_ticks() -> U32: 4
def overflow_added(before:Nat,after:Nat) -> U32: U32.from_nat(Nat.sub(before,after))
def terminal_parts(kind:U32,outcome:U32) -> Bool: Bool.and(U32.is_eq(kind,2),U32.is_eq(outcome,0))
def terminal_event(event:Hit) -> Bool:
  match event:
    case Hit{_,_,kind,_,_,_,_,_,_,_,outcome}: terminal_parts(kind,outcome)
def event_recent(+now:U32,+tick:U32) -> Bool:
  Bool.or(Bool.and(U32.is_le(tick,now),U32.is_lt((now - tick : U32),history_window())),Bool.and(U32.is_gt(tick,now),U32.is_lt((tick - now : U32),history_window())))

def target_seed(value:Target) -> U32:
  match value:
    case Target{seed,_,_,_,_,_}: seed
def target_generation(value:Target) -> U32:
  match value:
    case Target{_,generation,_,_,_,_}: generation
def current_life(rows:List<&2,Target>,+seed:U32,+generation:U32) -> Maybe<&2,Target>:
  match rows:
    case []: None{}
    case Target{+storedSeed,+storedGeneration,x,y,radius,+alive} <> tail:
      Bool.pick(Maybe<&2,Target>,Bool.and(alive,Bool.and(U32.is_eq(storedSeed,seed),U32.is_eq(storedGeneration,generation))),Some{Target{storedSeed,storedGeneration,x,y,radius,alive}},current_life(tail,seed,generation))
def event_x(event:Hit) -> F32:
  match event:
    case Hit{_,_,_,_,_,x,_,_,_,_,_}: x
def event_y(event:Hit) -> F32:
  match event:
    case Hit{_,_,_,_,_,_,y,_,_,_,_}: y
def target_at_x(event:Hit) -> F32:
  match event:
    case Hit{_,_,_,_,_,_,_,x,_,_,_}: x
def target_at_y(event:Hit) -> F32:
  match event:
    case Hit{_,_,_,_,_,_,_,_,y,_,_}: y
def event_seed(event:Hit) -> U32:
  match event:
    case Hit{_,_,_,seed,_,_,_,_,_,_,_}: seed
def event_generation(event:Hit) -> U32:
  match event:
    case Hit{_,_,_,_,generation,_,_,_,_,_,_}: generation
def event_impact(event:Hit) -> Point:
  match event:
    case Hit{_,_,_,_,_,x,y,_,_,_,_}: Point{x,y}
def target_x(target:Target) -> F32:
  match target:
    case Target{_,_,x,_,_,_}: x
def target_y(target:Target) -> F32:
  match target:
    case Target{_,_,_,y,_,_}: y
def offset_x(+event:Hit) -> F32: (event_x(event) - target_at_x(event) : F32)
def offset_y(+event:Hit) -> F32: (event_y(event) - target_at_y(event) : F32)
def target_contact(+event:Hit,+x:F32,+y:F32) -> Point: Point{(x + offset_x(event) : F32),(y + offset_y(event) : F32)}
def contact_found(found:Maybe<&2,Target>,+event:Hit) -> Point:
  match found event:
    case None{} _: event_impact(event)
    case Some{+target} _:
      Bool.pick(Point,U32.is_eq(target_generation(target),event_generation(event)),target_contact(event,target_x(target),target_y(target)),event_impact(event))
def event_contact(+event:Hit,targets:List<&2,Target>) -> Point:
  contact_found(current_life(targets,event_seed(event),event_generation(event)),event)

def draw_fields(life:U32,pending:Bool,confirmed:Bool,late:Bool,+fade:U32) -> Bool:
  Bool.or(pending,Bool.or(Bool.and(confirmed,Bool.or(Bool.not(late),U32.is_gt(fade,0))),Bool.or(U32.is_gt(life,0),U32.is_gt(fade,0))))
def should_draw(value:VisibleShot) -> Bool:
  match value:
    case VisibleShot{_,_,life,pending,confirmed,late,+fade}:
      draw_fields(life,pending,confirmed,late,fade)
def visible_row(value:VisibleShot,+player:U32,+id:String) -> Bool:
  match value:
    case VisibleShot{storedId,storedPlayer,life,pending,confirmed,late,+fade}:
      Bool.and(U32.is_eq(storedPlayer,player),Bool.and(draw_fields(life,pending,confirmed,late,fade),String.eq(storedId,id)))
def visible_id(rows:List<&2,VisibleShot>,+player:U32,+id:String) -> Bool:
  match rows:
    case []: False{}
    case +head <> tail:
      Bool.or(visible_row(head,player,id),visible_id(tail,player,id))
def hit_shot_id(value:Hit) -> String:
  match value:
    case Hit{shotId,_,_,_,_,_,_,_,_,_,_}: shotId
def hit_tick(value:Hit) -> U32:
  match value:
    case Hit{_,tick,_,_,_,_,_,_,_,_,_}: tick
def terminal_receipt_matches(+now:U32,+shotId:String,+event:Hit) -> Bool:
  Bool.and(String.eq(hit_shot_id(event),shotId),Bool.and(terminal_event(event),event_recent(now,hit_tick(event))))
def contains_terminal_receipt(rows:List<&2,Hit>,+now:U32,+shotId:String) -> Bool:
  match rows:
    case []: False{}
    case +head <> tail:
      Bool.or(terminal_receipt_matches(now,shotId,head),contains_terminal_receipt(tail,now,shotId))
def owner_selected(localOwner:Bool,+player:U32,+shotId:String,+now:U32,+shots:List<&2,VisibleShot>,+events:List<&2,Hit>) -> Bool:
  match localOwner:
    case False{}: True{}
    case True{}: Bool.not(Bool.or(contains_terminal_receipt(events,now,shotId),visible_id(shots,player,shotId)))
def kind_selected(localShot:Bool,localOwner:Bool,+player:U32,+shotId:String,+now:U32,+shots:List<&2,VisibleShot>,+events:List<&2,Hit>) -> Bool:
  match localShot:
    case False{}: True{}
    case True{}: owner_selected(localOwner,player,shotId,now,shots,events)
def should_show_prepared(context:Visibility,+player:U32,+kind:U32,+owner:U32,+shotId:String) -> Bool:
  match context:
    case Visibility{now,shots,events}:
      kind_selected(U32.is_eq(kind,1),U32.is_eq(owner,player),player,shotId,now,shots,events)
def should_show_authoritative(+player:U32,+kind:U32,+owner:U32,+shotId:String,+now:U32,+shots:List<&2,VisibleShot>,+events:List<&2,Hit>) -> Bool:
  should_show_prepared(Visibility{now,shots,events},player,kind,owner,shotId)

def fade_opacity(+fade:U32) -> F32:
  Bool.pick(F32,U32.is_gt(fade,0),(U32.to_f32(U32.min(fade,fade_ticks())) / U32.to_f32(fade_ticks()) : F32),1.0)
