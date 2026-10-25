import Base
import ./coop-playback.bend as P
import ./coop-hit-journal.bend as J
import ./body-index.bend as BI
import ./list-map.bend as LM

type Point is Data: Point{x:F32,y:F32}
type Prepared is Data: Prepared{shots:BI.Index<List<&2,J.HitEvent>>,targets:BI.Index<List<&2,J.HitEvent>>,events:List<&2,J.HitEvent>,paths:BI.Index<J.HitEvent>}
type Fx is Data: Fx{id:String,tick:U32,kind:U32,targetSeed:U32,targetGeneration:U32,x:F32,y:F32,radius:F32,age:U32,opacity:F32}
type Output is Data: Output{sample:P.Sample,contacts:List<&2,Fx>}
type Context is Data: Context{baseTick:U32,nextTick:U32,tick:U32,fraction:Nat,base:BI.Index<P.Actor>,next:BI.Index<P.Actor>,prepared:Prepared}
def shot_seed(event:J.HitEvent) -> U32:
  match event:
    case J.HitEvent{_,_,_,_,seed,_,_,_,_,_,_,_,_,_}: seed
def target_seed(event:J.HitEvent) -> U32:
  match event:
    case J.HitEvent{_,_,_,_,_,seed,_,_,_,_,_,_,_,_}: seed
def fraction(event:J.HitEvent) -> F32:
  match event:
    case J.HitEvent{_,_,_,_,_,_,_,fraction,_,_,_,_,_,_}: F32.clamp(fraction,0.0,1.0)
def confirmed(event:J.HitEvent) -> Bool:
  match event:
    case J.HitEvent{_,_,_,_,_,_,_,_,_,_,_,_,_,outcome}: U32.is_eq(outcome,0)
def terminal(event:J.HitEvent) -> Bool:
  match event:
    case J.HitEvent{_,_,kind,_,_,_,_,_,_,_,_,_,_,outcome}: Bool.and(U32.is_eq(kind,2),U32.is_eq(outcome,0))
def target_generation(+seed:U32,generation:U32) -> String: "enemy:" ++ U32.show(seed) ++ ":" ++ U32.show(generation)
def target_matches(actor:P.Actor,event:J.HitEvent) -> Bool:
  match actor event:
    case P.Actor{key,kind,generation,_,_,_,_,_} J.HitEvent{_,_,_,_,_,+seed,born,_,_,_,_,_,_,_}:
      Bool.and(U32.is_eq(kind,0),Bool.and(U32.is_eq(key,seed),String.eq(generation,target_generation(seed,born))))
def shot_matches(actor:P.Actor,event:J.HitEvent) -> Bool:
  match actor event:
    case P.Actor{key,kind,generation,_,_,_,_,_} J.HitEvent{_,_,_,shot,seed,_,_,_,_,_,_,_,_,_}:
      Bool.and(U32.is_eq(kind,1),Bool.and(U32.is_eq(key,seed),String.eq(generation,shot)))
def point(actor:P.Actor) -> Point:
  match actor:
    case P.Actor{_,_,_,x,y,_,_,_}: Point{x,y}
def positioned(actor:P.Actor,point:Point) -> P.Actor:
  match actor point:
    case P.Actor{key,kind,generation,_,_,age,alive,owner} Point{x,y}: P.Actor{key,kind,generation,x,y,age,alive,owner}
def impact(event:J.HitEvent) -> Point:
  match event:
    case J.HitEvent{_,_,_,_,_,_,_,_,x,y,_,_,_,_}: Point{x,y}
def target_at_impact(event:J.HitEvent) -> Point:
  match event:
    case J.HitEvent{_,_,_,_,_,_,_,_,_,_,x,y,_,_}: Point{x,y}
def relative(event:J.HitEvent,target:Point) -> Point:
  match event target:
    case J.HitEvent{_,_,_,_,_,_,_,_,ix,iy,tx,ty,_,_} Point{x,y}: Point{F32.add(x,F32.sub(ix,tx)),F32.add(y,F32.sub(iy,ty))}
def lerp(a:Point,b:Point,+alpha:F32) -> Point:
  match a b:
    case Point{x0,y0} Point{x1,y1}: Point{F32.lerp(x0,x1,alpha),F32.lerp(y0,y1,alpha)}

# Build mutable-in-shape immutable bucket indices once per received journal.
# Existing BI.insert intentionally keeps the first value, so bucket updates
# replace a matching leaf while retaining its Patricia branch structure.
def bucket_item(same:Bool,+key:U32,event:J.HitEvent,+oldKey:U32,rows:List<&2,J.HitEvent>) -> BI.Index<List<&2,J.HitEvent>>:
  match same:
    case True{}: BI.Item{oldKey,event <> rows}
    case False{}: BI.insert(~List<&2,J.HitEvent>,BI.Item{oldKey,rows},key,[event])
def bucket_go(fuel:Nat,index:BI.Index<List<&2,J.HitEvent>>,+key:U32,+event:J.HitEvent,above:Bool,one:Bool) -> BI.Index<List<&2,J.HitEvent>>:
  match fuel index above one:
    case _ BI.Empty{} _ _: BI.Item{key,[event]}
    case _ BI.Item{+oldKey,rows} _ _: bucket_item(U32.is_eq(oldKey,key),key,event,oldKey,rows)
    case _ +index True{} _: BI.insert(~List<&2,J.HitEvent>,index,key,[event])
    case 0n index False{} _: index
    case 1n+rest BI.Fork{sample,mask,+zero,other} False{} False{}: BI.Fork{sample,mask,bucket_go(rest,zero,key,event,BI.outside(~List<&2,J.HitEvent>,zero,key),BI.branch(~List<&2,J.HitEvent>,zero,key)),other}
    case 1n+rest BI.Fork{sample,mask,other,+one} False{} True{}: BI.Fork{sample,mask,other,bucket_go(rest,one,key,event,BI.outside(~List<&2,J.HitEvent>,one,key),BI.branch(~List<&2,J.HitEvent>,one,key))}
def bucket_add(+index:BI.Index<List<&2,J.HitEvent>>,+key:U32,event:J.HitEvent) -> BI.Index<List<&2,J.HitEvent>>:
  bucket_go(32n,index,key,event,BI.outside(~List<&2,J.HitEvent>,index,key),BI.branch(~List<&2,J.HitEvent>,index,key))
def prepare_rows(rows:List<&2,J.HitEvent>,shots:BI.Index<List<&2,J.HitEvent>>,targets:BI.Index<List<&2,J.HitEvent>>,events:List<&2,J.HitEvent>) -> Prepared:
  match rows:
    case []: Prepared{shots,targets,events,BI.Empty{}}
    case +head <> tail: prepare_rows(tail,bucket_add(shots,shot_seed(head),head),bucket_add(targets,target_seed(head),head),head <> events)
def prepare(journal:J.State) -> Prepared:
  match journal:
    case J.State{_,_,events,_,_}: prepare_rows(List.take(&2,J.HitEvent,events,512n),BI.Empty{},BI.Empty{},[])
def bucket(found:Maybe<&2,List<&2,J.HitEvent>>) -> List<&2,J.HitEvent>:
  match found:
    case None{}: []
    case Some{rows}: rows

def within(+event:J.HitEvent,base:U32,next:U32) -> Bool: Bool.and(U32.is_gt(J.event_tick(event),base),U32.is_le(J.event_tick(event),next))
def later(+a:J.HitEvent,+b:J.HitEvent) -> Bool:
  Bool.or(U32.is_gt(J.event_tick(a),J.event_tick(b)),Bool.and(U32.is_eq(J.event_tick(a),J.event_tick(b)),F32.is_gt(fraction(a),fraction(b))))
def newest(old:Maybe<&2,J.HitEvent>,+new:J.HitEvent) -> Maybe<&2,J.HitEvent>:
  match old:
    case None{}: Some{new}
    case Some{+old}: Some{Bool.pick(J.HitEvent,later(new,old),new,old)}
def selected(accept:Bool,+old:Maybe<&2,J.HitEvent>,event:J.HitEvent) -> Maybe<&2,J.HitEvent>:
  match accept:
    case False{}: old
    case True{}: newest(old,event)
def eligible(+event:J.HitEvent,+actor:P.Actor,base:U32,next:U32,shot:Bool) -> Bool:
  Bool.and(within(event,base,next),Bool.pick(Bool,shot,Bool.and(terminal(event),shot_matches(actor,event)),Bool.and(confirmed(event),target_matches(actor,event))))
def select(rows:List<&2,J.HitEvent>,+actor:P.Actor,+base:U32,+next:U32,+shot:Bool,found:Maybe<&2,J.HitEvent>) -> Maybe<&2,J.HitEvent>:
  match rows:
    case []: found
    case +head <> tail: select(tail,actor,base,next,shot,selected(eligible(head,actor,base,next,shot),found,head))
def contact_for(context:Context,+actor:P.Actor,+shot:Bool) -> Maybe<&2,J.HitEvent>:
  match context:
    case Context{base,next,_,_,_,_,Prepared{shots,targets,_,_}}: select(bucket(BI.find(~List<&2,J.HitEvent>,Bool.pick(BI.Index<List<&2,J.HitEvent>>,shot,shots,targets),P.actor_key(actor))),actor,base,next,shot,None{})
# Select one target trajectory per lifetime and bracket. Projectile endpoints
# reuse this index, so many shots hitting one target never rescan its receipts.
def path_insert(found:Maybe<&2,J.HitEvent>,index:BI.Index<J.HitEvent>) -> BI.Index<J.HitEvent>:
  match found:
    case None{}: index
    case Some{+event}: BI.insert(~J.HitEvent,index,target_seed(event),event)
def path_candidate_selected(enemy:Bool,actor:P.Actor,context:Context,+index:BI.Index<J.HitEvent>) -> BI.Index<J.HitEvent>:
  match enemy:
    case True{}: path_insert(contact_for(context,actor,False{}),index)
    case False{}: index
def path_candidate(+actor:P.Actor,context:Context,index:BI.Index<J.HitEvent>) -> BI.Index<J.HitEvent>:
  match actor:
    case P.Actor{_,kind,_,_,_,_,_,_}: path_candidate_selected(U32.is_eq(kind,0),actor,context,index)
def path_rows(rows:List<&2,P.Actor>,+context:Context,index:BI.Index<J.HitEvent>) -> BI.Index<J.HitEvent>:
  match rows:
    case []: index
    case head <> tail: path_rows(tail,context,path_candidate(head,context,index))
def path_prepared(+prepared:Prepared,rows:List<&2,P.Actor>,base:U32,next:U32) -> Prepared:
  match prepared:
    case Prepared{shots,targets,events,_}: Prepared{shots,targets,events,path_rows(rows,Context{base,next,0,0n,BI.Empty{},BI.Empty{},prepared},BI.Empty{})}
def path_lookup(context:Context,key:U32) -> Maybe<&2,J.HitEvent>:
  match context:
    case Context{_,_,_,_,_,_,Prepared{_,_,_,paths}}: BI.find(~J.HitEvent,paths,key)
def selected_contact(shot:Bool,context:Context,actor:P.Actor) -> Maybe<&2,J.HitEvent>:
  match shot:
    case True{}: contact_for(context,actor,True{})
    case False{}: path_lookup(context,P.actor_key(actor))
def alive_same(found:Maybe<&2,P.Actor>,+actor:P.Actor) -> Bool:
  match found:
    case None{}: False{}
    case Some{new}: P.identity(actor,new)
def continues(context:Context,+actor:P.Actor) -> Bool:
  match context:
    case Context{_,_,_,_,_,next,_}: alive_same(BI.find(~P.Actor,next,P.actor_key(actor)),actor)
def offset(+event:J.HitEvent,+base:U32) -> F32:
  F32.add(U32.to_f32((U32.max(1,(U32.max(base,J.event_tick(event)) - base : U32)) - 1 : U32)),fraction(event))
def cursor_offset(tick:U32,base:U32,fraction:Nat) -> F32: F32.add(U32.to_f32((tick - base : U32)),F32.div(F32.from_nat(fraction),1000000.0))
def progress(elapsed:F32,+duration:F32) -> F32: Bool.pick(F32,F32.is_le(duration,0.0),1.0,F32.clamp(F32.div(elapsed,F32.max(duration,0.000001)),0.0,1.0))
def event_progress(context:Context,+event:J.HitEvent) -> F32:
  match context:
    case Context{+base,_,tick,fraction,_,_,_}: progress(cursor_offset(tick,base,fraction),offset(event,base))
def reached(context:Context,+event:J.HitEvent) -> Bool:
  match context:
    case Context{+base,_,tick,fraction,_,_,_}: F32.is_ge(cursor_offset(tick,base,fraction),offset(event,base))
def target_endpoint_next(same:Bool,old:P.Actor,new:P.Actor,+event:J.HitEvent,+base:U32,next:U32,fallback:Point) -> Point:
  match same:
    case False{}: fallback
    case True{}: lerp(point(old),point(new),progress(offset(event,base),U32.to_f32((next - base : U32))))
def target_endpoint_found(new:Maybe<&2,P.Actor>,+old:P.Actor,+event:J.HitEvent,base:U32,next:U32,fallback:Point) -> Point:
  match new:
    case None{}: fallback
    case Some{+new}: target_endpoint_next(P.identity(old,new),old,new,event,base,next,fallback)
def target_trajectory(actor:P.Actor,+path:J.HitEvent,time:F32,base:U32) -> Point:
  lerp(point(actor),target_at_impact(path),progress(time,offset(path,base)))
def dead_endpoint(found:Maybe<&2,J.HitEvent>,old:P.Actor,+event:J.HitEvent,+base:U32) -> Point:
  match found:
    case None{}: target_at_impact(event)
    case Some{path}: target_trajectory(old,path,offset(event,base),base)
def dying_endpoint(+context:Context,+old:P.Actor,event:J.HitEvent) -> Point:
  match context:
    case Context{base,_,_,_,_,_,_}: dead_endpoint(path_lookup(context,P.actor_key(old)),old,event,base)
def target_display(+context:Context,actor:P.Actor,path:J.HitEvent) -> Point:
  match context:
    case Context{+base,_,tick,fraction,_,_,_}: target_trajectory(actor,path,cursor_offset(tick,base,fraction),base)
def target_endpoint_old(found:Maybe<&2,P.Actor>,+context:Context,+event:J.HitEvent) -> Point:
  match found context:
    case None{} _: target_at_impact(event)
    case Some{+old} Context{base,next,_,_,_,index,_}: Bool.pick(Point,target_matches(old,event),target_endpoint_found(BI.find(~P.Actor,index,target_seed(event)),old,event,base,next,dying_endpoint(context,old,event)),target_at_impact(event))
def endpoint(+context:Context,+event:J.HitEvent) -> Point:
  match context:
    case Context{_,_,_,_,base,_,_}: relative(event,target_endpoint_old(BI.find(~P.Actor,base,target_seed(event)),context,event))
def shot_projected(past:Bool,+context:Context,+old:P.Actor,+event:J.HitEvent) -> Maybe<&2,P.Actor>:
  match past:
    case True{}: None{}
    case False{}: Some{positioned(old,lerp(point(old),endpoint(context,event),event_progress(context,event)))}
def project_found(shot:Bool,event:Maybe<&2,J.HitEvent>,+context:Context,+actor:P.Actor) -> Maybe<&2,P.Actor>:
  match shot event:
    case _ None{}: Some{actor}
    case True{} Some{+event}: shot_projected(reached(context,event),context,actor,event)
    case False{} Some{+event}: Some{positioned(actor,target_display(context,actor,event))}
def actor_selected(changed:Bool,+context:Context,+actor:P.Actor,+shot:Bool) -> Maybe<&2,P.Actor>:
  match changed:
    case False{}: Some{actor}
    case True{}: project_found(shot,selected_contact(shot,context,actor),context,actor)
def project_actor(+context:Context,+actor:P.Actor) -> Maybe<&2,P.Actor>:
  match actor:
    case P.Actor{_,+kind,_,_,_,_,_,_}: actor_selected(Bool.and(Bool.or(U32.is_eq(kind,0),U32.is_eq(kind,1)),Bool.not(continues(context,actor))),context,actor,U32.is_eq(kind,1))
def keep(found:Maybe<&2,P.Actor>,tail:List<&2,P.Actor>) -> List<&2,P.Actor>:
  match found:
    case None{}: tail
    case Some{actor}: actor <> tail
def project_rows(rows:List<&2,P.Actor>,+context:Context,acc:List<&2,P.Actor>) -> List<&2,P.Actor>:
  match rows:
    case []: List.reverse(&2,P.Actor,acc)
    case head <> tail: project_rows(tail,context,keep(project_actor(context,head),acc))

def find_frame(rows:List<&2,P.Indexed>,+observation:U32,found:Maybe<&2,P.Indexed>) -> Maybe<&2,P.Indexed>:
  match rows:
    case []: found
    case +head <> tail: find_frame(tail,observation,Bool.pick(Maybe<&2,P.Indexed>,U32.is_eq(P.observation(P.frame(head)),observation),Some{head},found))
def project_pair(old:Maybe<&2,P.Indexed>,new:Maybe<&2,P.Indexed>,+sample:P.Sample,prepared:Prepared) -> P.Sample:
  match old new sample:
    case Some{P.Indexed{+old,_,baseIndex}} Some{P.Indexed{+new,_,nextIndex}} P.Sample{obs,next,tick,fraction,alpha,players,+bodies}:
      P.Sample{obs,next,tick,fraction,alpha,players,project_rows(bodies,Context{P.world_tick(old),P.world_tick(new),tick,fraction,baseIndex,nextIndex,path_prepared(prepared,bodies,P.world_tick(old),P.world_tick(new))},[])}
    case _ _ _: sample

def fx_recent(event:J.HitEvent,+display:U32) -> Bool:
  match event:
    case J.HitEvent{_,+tick,_,_,_,_,_,_,_,_,_,_,_,outcome}: Bool.and(U32.is_eq(outcome,0),Bool.and(U32.is_le(tick,display),U32.is_lt((display - tick : U32),4)))
def fx_point(found:Maybe<&2,P.Actor>,+event:J.HitEvent) -> Point:
  match found:
    case None{}: impact(event)
    case Some{+actor}: Bool.pick(Point,target_matches(actor,event),relative(event,point(actor)),impact(event))
def fx(event:J.HitEvent,point:Point,+display:U32) -> Fx:
  match event point:
    case J.HitEvent{id,+tick,kind,_,_,seed,generation,_,_,_,_,_,radius,_} Point{x,y}: Fx{id,tick,kind,seed,generation,x,y,radius,(display - tick : U32),F32.div(U32.to_f32((4 - (display - tick : U32) : U32)),4.0)}
def fx_add(visible:Bool,+event:J.HitEvent,index:BI.Index<P.Actor>,display:U32,tail:List<&2,Fx>) -> List<&2,Fx>:
  match visible:
    case False{}: tail
    case True{}: fx(event,fx_point(BI.find(~P.Actor,index,target_seed(event)),event),display) <> tail
def effects(rows:List<&2,J.HitEvent>,+index:BI.Index<P.Actor>,+display:U32,acc:List<&2,Fx>) -> List<&2,Fx>:
  match rows:
    case []: List.reverse(&2,Fx,acc)
    case +head <> tail: effects(tail,index,display,fx_add(fx_recent(head,display),head,index,display,acc))
def output(+sample:P.Sample,prepared:Prepared) -> Output:
  match sample prepared:
    case P.Sample{_,_,tick,_,_,_,bodies} Prepared{_,_,events,_}: Output{sample,effects(events,P.index_rows(bodies,BI.Empty{}),tick,[])}
def project(state:P.State,+sample:P.Sample,+prepared:Prepared) -> Output:
  match state sample:
    case P.State{+rows,_,_,_} P.Sample{base,next,_,_,_,_,_}: output(project_pair(find_frame(rows,base,None{}),find_frame(rows,next,None{}),sample,prepared),prepared)
