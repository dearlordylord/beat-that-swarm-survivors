import Base
import ./coop-contact-playback.bend as C
import ./coop-playback.bend as P
import ./coop-hit-journal.bend as J
import ./body-index.bend as BI

# Guarantees: shot_seed uses exactly the corresponding confirmed receipt fields.
# Why it matters: Contact geometry and terminal admission must not use unrelated metadata.
law shot_seed_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {C.shot_seed(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome}) == shotSeed : U32}

# Guarantees: target_seed uses exactly the corresponding confirmed receipt fields.
# Why it matters: Contact geometry and terminal admission must not use unrelated metadata.
law target_seed_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {C.target_seed(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome}) == targetSeed : U32}

# Guarantees: fraction uses exactly the corresponding confirmed receipt fields.
# Why it matters: Contact geometry and terminal admission must not use unrelated metadata.
law fraction_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {C.fraction(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome}) == F32.clamp(fraction,0.0,1.0) : F32}

# Guarantees: confirmed uses exactly the corresponding confirmed receipt fields.
# Why it matters: Contact geometry and terminal admission must not use unrelated metadata.
law confirmed_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {C.confirmed(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome}) == U32.is_eq(outcome,0) : Bool}

# Guarantees: terminal uses exactly the corresponding confirmed receipt fields.
# Why it matters: Contact geometry and terminal admission must not use unrelated metadata.
law terminal_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {C.terminal(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome}) == Bool.and(U32.is_eq(kind,2),U32.is_eq(outcome,0)) : Bool}

# Guarantees: impact uses exactly the corresponding confirmed receipt fields.
# Why it matters: Contact geometry and terminal admission must not use unrelated metadata.
law impact_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {C.impact(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome}) == C.Point{ix,iy} : C.Point}

# Guarantees: target_at_impact uses exactly the corresponding confirmed receipt fields.
# Why it matters: Contact geometry and terminal admission must not use unrelated metadata.
law target_at_impact_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {C.target_at_impact(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome}) == C.Point{tx,ty} : C.Point}

# Guarantees: Enemy lifetime identifiers include both seed and authoritative birth tick.
# Why it matters: A recycled seed cannot refer to a prior enemy incarnation.
law target_generation_exact:
  for +seed:U32
  for +born:U32
  {C.target_generation(seed,born) == "enemy:" ++ U32.show(seed) ++ ":" ++ U32.show(born) : String}

# Guarantees: A target matches only kind zero with identical seed and birth generation.
# Why it matters: Confirmed contacts must never nudge a reused enemy slot.
law target_lifetime_exact:
  for +key:U32
  for +actorKind:U32
  for +actorGeneration:String
  for +x:F32
  for +y:F32
  for +age:U32
  for +alive:Bool
  for +owner:U32
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {C.target_matches(P.Actor{key,actorKind,actorGeneration,x,y,age,alive,owner},J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome}) == Bool.and(U32.is_eq(actorKind,0),Bool.and(U32.is_eq(key,targetSeed),String.eq(actorGeneration,"enemy:" ++ U32.show(targetSeed) ++ ":" ++ U32.show(generation)))) : Bool}

# Guarantees: A shot matches only kind one with identical seed and shot lifetime identifier.
# Why it matters: A terminal contact cannot remove a later projectile using the same slot.
law shot_lifetime_exact:
  for +key:U32
  for +actorKind:U32
  for +actorGeneration:String
  for +x:F32
  for +y:F32
  for +age:U32
  for +alive:Bool
  for +owner:U32
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  {C.shot_matches(P.Actor{key,actorKind,actorGeneration,x,y,age,alive,owner},J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome}) == Bool.and(U32.is_eq(actorKind,1),Bool.and(U32.is_eq(key,shotSeed),String.eq(actorGeneration,shot))) : Bool}

# Guarantees: An actor point exposes its current x and y.
# Why it matters: Geometry cannot silently anchor at an unrelated actor field.
law point_exact:
  for +key:U32
  for +actorKind:U32
  for +actorGeneration:String
  for +x:F32
  for +y:F32
  for +age:U32
  for +alive:Bool
  for +owner:U32
  {C.point(P.Actor{key,actorKind,actorGeneration,x,y,age,alive,owner}) == C.Point{x,y} : C.Point}

# Guarantees: Position correction changes only x and y.
# Why it matters: Contact playback cannot invent damage, ownership, health or actor lifetime.
law positioned_preserves_metadata:
  for +key:U32
  for +actorKind:U32
  for +actorGeneration:String
  for +x:F32
  for +y:F32
  for +age:U32
  for +alive:Bool
  for +owner:U32
  for +nx:F32
  for +ny:F32
  {C.positioned(P.Actor{key,actorKind,actorGeneration,x,y,age,alive,owner},C.Point{nx,ny}) == P.Actor{key,actorKind,actorGeneration,nx,ny,age,alive,owner} : P.Actor}

# Guarantees: The visible contact equals displayed target position plus the authoritative contact offset.
# Why it matters: Projectiles and hit effects must meet the displayed enemy rather than its delayed coordinates.
law contact_relative_geometry:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  for +x:F32
  for +y:F32
  {C.relative(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome},C.Point{x,y}) == C.Point{F32.add(x,F32.sub(ix,tx)),F32.add(y,F32.sub(iy,ty))} : C.Point}

# Guarantees: Both position axes use the same interpolation fraction.
# Why it matters: Contact reconstruction cannot put x and y on different presentation times.
law point_lerp_exact:
  for +x0:F32
  for +y0:F32
  for +x1:F32
  for +y1:F32
  for +alpha:F32
  {C.lerp(C.Point{x0,y0},C.Point{x1,y1},alpha) == C.Point{F32.lerp(x0,x1,alpha),F32.lerp(y0,y1,alpha)} : C.Point}

# Guarantees: Receipt eligibility is strictly after base tick and no later than next tick.
# Why it matters: A prior or future contact cannot rewrite this authoritative interpolation segment.
law receipt_interval_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  for +base:U32
  for +next:U32
  {C.within(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome},base,next) == Bool.and(U32.is_gt(tick,base),U32.is_le(tick,next)) : Bool}

# Guarantees: Receipts order by tick first and fractional contact time second.
# Why it matters: A piercing projectile ends at its last terminal contact instead of the first hit.
law terminal_order_exact:
  for +a:J.HitEvent
  for +b:J.HitEvent
  {C.later(a,b) == Bool.or(U32.is_gt(J.event_tick(a),J.event_tick(b)),Bool.and(U32.is_eq(J.event_tick(a),J.event_tick(b)),F32.is_gt(C.fraction(a),C.fraction(b)))) : Bool}

# Guarantees: The first eligible receipt becomes the selected receipt.
# Why it matters: A valid terminal hit must not be silently discarded.
law newest_initial:
  for +event:J.HitEvent
  {C.newest(None{},event) == Some{event} : Maybe<&2,J.HitEvent>}

# Guarantees: An existing receipt is replaced only by a later tick or greater contact fraction.
# Why it matters: The selected endpoint remains the final contact of an exhausted shot.
law newest_ordered:
  for +old:J.HitEvent
  for +new:J.HitEvent
  {C.newest(Some{old},new) == Some{Bool.pick(J.HitEvent,C.later(new,old),new,old)} : Maybe<&2,J.HitEvent>}

# Guarantees: Shot selection requires terminal confirmation and shot identity; target selection requires confirmation and target identity, both within the bracket.
# Why it matters: Nonterminal piercing contacts and reused lifetimes cannot remove unrelated shots.
law eligible_exact:
  for +event:J.HitEvent
  for +actor:P.Actor
  for +base:U32
  for +next:U32
  for +shot:Bool
  {C.eligible(event,actor,base,next,shot) == Bool.and(C.within(event,base,next),Bool.pick(Bool,shot,Bool.and(C.terminal(event),C.shot_matches(actor,event)),Bool.and(C.confirmed(event),C.target_matches(actor,event)))) : Bool}

# Guarantees: An ineligible receipt leaves the existing selection unchanged.
# Why it matters: Unconfirmed or unrelated events cannot enter the terminal path.
law selected_reject:
  for +old:Maybe<&2,J.HitEvent>
  for +event:J.HitEvent
  {C.selected(False{},old,event) == old : Maybe<&2,J.HitEvent>}

# Guarantees: An eligible receipt enters the explicit latest-contact ordering.
# Why it matters: The event selector cannot bypass terminal-time ordering.
law selected_accept:
  for +old:Maybe<&2,J.HitEvent>
  for +event:J.HitEvent
  {C.selected(True{},old,event) == C.newest(old,event) : Maybe<&2,J.HitEvent>}

# Guarantees: A contact lies at end tick minus one plus its clamped fractional contact time relative to the base frame.
# Why it matters: Removing a projectile at the whole end tick would leave it visibly beyond the actual impact.
law offset_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  for +base:U32
  {C.offset(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome},base) == F32.add(U32.to_f32((U32.max(1,(U32.max(base,tick) - base : U32)) - 1 : U32)),F32.clamp(fraction,0.0,1.0)) : F32}

# Guarantees: Presentation tick and millionth fraction form one relative world time.
# Why it matters: Contact paths use the same presentation cursor as authoritative snapshot interpolation.
law cursor_offset_exact:
  for +tick:U32
  for +base:U32
  for +fraction:Nat
  {C.cursor_offset(tick,base,fraction) == F32.add(U32.to_f32((tick - base : U32)),F32.div(F32.from_nat(fraction),1000000.0)) : F32}

# Guarantees: Progress clamps elapsed over positive duration and completes immediately for nonpositive duration.
# Why it matters: A contact reconstruction cannot extrapolate beyond its confirmed endpoint.
law progress_exact:
  for +elapsed:F32
  for +duration:F32
  {C.progress(elapsed,duration) == Bool.pick(F32,F32.is_le(duration,0.0),1.0,F32.clamp(F32.div(elapsed,F32.max(duration,0.000001)),0.0,1.0)) : F32}

# Guarantees: Path progress combines the shared cursor and that receipt contact time.
# Why it matters: A terminal shot and its dying target must reach impact on the same display time.
law event_progress_exact:
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +oldIndex:BI.Index<P.Actor>
  for +newIndex:BI.Index<P.Actor>
  for +prepared:C.Prepared
  for +event:J.HitEvent
  {C.event_progress(C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},event) == C.progress(C.cursor_offset(tick,base,fraction),C.offset(event,base)) : F32}

# Guarantees: A terminal contact is reached precisely when relative display time is at least its impact time.
# Why it matters: The projectile must disappear at the fractional contact boundary.
law reached_exact:
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +oldIndex:BI.Index<P.Actor>
  for +newIndex:BI.Index<P.Actor>
  for +prepared:C.Prepared
  for +event:J.HitEvent
  {C.reached(C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},event) == F32.is_ge(C.cursor_offset(tick,base,fraction),C.offset(event,base)) : Bool}

# Guarantees: A shot at or after its selected confirmed terminal time is absent.
# Why it matters: An exhausted projectile cannot freeze at its older snapshot position.
law terminal_shot_removed:
  for +context:C.Context
  for +old:P.Actor
  for +event:J.HitEvent
  {C.shot_projected(True{},context,old,event) == None{} : Maybe<&2,P.Actor>}

# Guarantees: Before contact a shot moves from its older position to the target-relative confirmed endpoint.
# Why it matters: Remote projectiles must visibly approach the target they actually hit.
law terminal_shot_path:
  for +context:C.Context
  for +old:P.Actor
  for +event:J.HitEvent
  {C.shot_projected(False{},context,old,event) == Some{C.positioned(old,C.lerp(C.point(old),C.endpoint(context,event),C.event_progress(context,event)))} : Maybe<&2,P.Actor>}

# Guarantees: Without a matching receipt ordinary snapshot presentation is preserved exactly.
# Why it matters: Missing evidence must never fabricate a hit or remove a projectile.
law no_receipt_preserves_actor:
  for +shot:Bool
  for +context:C.Context
  for +actor:P.Actor
  {C.project_found(shot,None{},context,actor) == Some{actor} : Maybe<&2,P.Actor>}

# Guarantees: A terminal shot receipt controls removal through the exact reached predicate.
# Why it matters: The live projection path cannot bypass the fractional terminal-time guard.
law shot_receipt_dispatch:
  for +context:C.Context
  for +actor:P.Actor
  for +event:J.HitEvent
  {C.project_found(True{},Some{event},context,actor) == C.shot_projected(C.reached(context,event),context,actor,event) : Maybe<&2,P.Actor>}

# Guarantees: A dying target follows its selected shared trajectory at the current presentation time and retains its metadata.
# Why it matters: A shot cannot hit beside a target frozen at its earlier snapshot position.
law dying_target_path:
  for +context:C.Context
  for +actor:P.Actor
  for +event:J.HitEvent
  {C.project_found(False{},Some{event},context,actor) == Some{C.positioned(actor,C.target_display(context,actor,event))} : Maybe<&2,P.Actor>}

# Guarantees: An actor excluded from contact reconstruction keeps its exact sampled state.
# Why it matters: Ordinary live interpolation and unrelated actor families remain coherent.
law actor_unchanged:
  for +context:C.Context
  for +actor:P.Actor
  for +shot:Bool
  {C.actor_selected(False{},context,actor,shot) == Some{actor} : Maybe<&2,P.Actor>}

# Guarantees: A reconstruction candidate is changed only through its matching indexed receipt.
# Why it matters: Every position correction remains tied to authoritative evidence.
law actor_changed_dispatch:
  for +context:C.Context
  for +actor:P.Actor
  for +shot:Bool
  {C.actor_selected(True{},context,actor,shot) == C.project_found(shot,C.selected_contact(shot,context,actor),context,actor) : Maybe<&2,P.Actor>}

# Guarantees: Only enemy or friendly-projectile actors whose live identity does not continue are reconstruction candidates.
# Why it matters: Living targets keep ordinary interpolation and unrelated visual bodies are never nudged.
law actor_policy_exact:
  for +key:U32
  for +actorKind:U32
  for +actorGeneration:String
  for +x:F32
  for +y:F32
  for +age:U32
  for +alive:Bool
  for +owner:U32
  for +context:C.Context
  {C.project_actor(context,P.Actor{key,actorKind,actorGeneration,x,y,age,alive,owner}) == C.actor_selected(Bool.and(Bool.or(U32.is_eq(actorKind,0),U32.is_eq(actorKind,1)),Bool.not(C.continues(context,P.Actor{key,actorKind,actorGeneration,x,y,age,alive,owner}))),context,P.Actor{key,actorKind,actorGeneration,x,y,age,alive,owner},U32.is_eq(actorKind,1)) : Maybe<&2,P.Actor>}

# Guarantees: A continuing target endpoint is its position on the same authority bracket at impact time.
# Why it matters: Remote shots and moving enemies must meet under one display clock.
law living_target_endpoint:
  for +fallback:C.Point
  for +old:P.Actor
  for +new:P.Actor
  for +event:J.HitEvent
  for +base:U32
  for +next:U32
  {C.target_endpoint_next(True{},old,new,event,base,next,fallback) == C.lerp(C.point(old),C.point(new),C.progress(C.offset(event,base),U32.to_f32((next - base : U32)))) : C.Point}

# Guarantees: A noncontinuing target endpoint uses the supplied shared-trajectory position.
# Why it matters: A removed or reused target cannot redirect a shot toward the next incarnation.
law dying_target_endpoint:
  for +fallback:C.Point
  for +old:P.Actor
  for +new:P.Actor
  for +event:J.HitEvent
  for +base:U32
  for +next:U32
  {C.target_endpoint_next(False{},old,new,event,base,next,fallback) == fallback : C.Point}

# Guarantees: Effects require confirmed outcome and an end tick no later than display, younger than four ticks.
# Why it matters: Future journal contacts cannot reveal hits early or replay indefinitely.
law fx_time_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  for +display:U32
  {C.fx_recent(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome},display) == Bool.and(U32.is_eq(outcome,0),Bool.and(U32.is_le(tick,display),U32.is_lt((display - tick : U32),4))) : Bool}

# Guarantees: An effect without a known target uses the authoritative contact point.
# Why it matters: Unknown lifetimes do not attach effects to unrelated visible enemies.
law fx_unknown_target:
  for +event:J.HitEvent
  {C.fx_point(None{},event) == C.impact(event) : C.Point}

# Guarantees: A matching visible target supplies contact-relative geometry; a different lifetime uses canonical fallback.
# Why it matters: Hit flashes cannot follow a reused enemy slot.
law fx_known_target:
  for +actor:P.Actor
  for +event:J.HitEvent
  {C.fx_point(Some{actor},event) == Bool.pick(C.Point,C.target_matches(actor,event),C.relative(event,C.point(actor)),C.impact(event)) : C.Point}

# Guarantees: An effect preserves receipt identity and contact radius, with age and opacity from display time.
# Why it matters: Rendering repeated frames cannot manufacture new authoritative contact records.
law fx_record_exact:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +shot:String
  for +shotSeed:U32
  for +targetSeed:U32
  for +generation:U32
  for +fraction:F32
  for +ix:F32
  for +iy:F32
  for +tx:F32
  for +ty:F32
  for +radius:F32
  for +outcome:U32
  for +x:F32
  for +y:F32
  for +display:U32
  {C.fx(J.HitEvent{id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome},C.Point{x,y},display) == C.Fx{id,tick,kind,targetSeed,generation,x,y,radius,(display - tick : U32),F32.div(U32.to_f32((4 - (display - tick : U32) : U32)),4.0)} : C.Fx}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law selection_empty:
  for +actor:P.Actor
  for +base:U32
  for +next:U32
  for +shot:Bool
  for +found:Maybe<&2,J.HitEvent>
  {C.select([],actor,base,next,shot,found) == found : Maybe<&2,J.HitEvent>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law selection_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +actor:P.Actor
  for +base:U32
  for +next:U32
  for +shot:Bool
  for +found:Maybe<&2,J.HitEvent>
  {C.select(head <> tail,actor,base,next,shot,found) == C.select(tail,actor,base,next,shot,C.selected(C.eligible(head,actor,base,next,shot),found,head)) : Maybe<&2,J.HitEvent>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law bucket_missing:
  {C.bucket(None{}) == [] : List<&2,J.HitEvent>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law bucket_present:
  for +rows:List<&2,J.HitEvent>
  {C.bucket(Some{rows}) == rows : List<&2,J.HitEvent>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law contact_lookup_exact:
  for +paths:BI.Index<J.HitEvent>
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +oldIndex:BI.Index<P.Actor>
  for +newIndex:BI.Index<P.Actor>
  for +shots:BI.Index<List<&2,J.HitEvent>>
  for +targets:BI.Index<List<&2,J.HitEvent>>
  for +events:List<&2,J.HitEvent>
  for +actor:P.Actor
  for +shot:Bool
  {C.contact_for(C.Context{base,next,tick,fraction,oldIndex,newIndex,C.Prepared{shots,targets,events,paths}},actor,shot) == C.select(C.bucket(BI.find(~List<&2,J.HitEvent>,Bool.pick(BI.Index<List<&2,J.HitEvent>>,shot,shots,targets),P.actor_key(actor))),actor,base,next,shot,None{}) : Maybe<&2,J.HitEvent>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law alive_missing:
  for +actor:P.Actor
  {C.alive_same(None{},actor) == False{} : Bool}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law alive_present:
  for +actor:P.Actor
  for +new:P.Actor
  {C.alive_same(Some{new},actor) == P.identity(actor,new) : Bool}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law continues_lookup:
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +oldIndex:BI.Index<P.Actor>
  for +newIndex:BI.Index<P.Actor>
  for +prepared:C.Prepared
  for +actor:P.Actor
  {C.continues(C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},actor) == C.alive_same(BI.find(~P.Actor,newIndex,P.actor_key(actor)),actor) : Bool}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law endpoint_next_missing:
  for +fallback:C.Point
  for +old:P.Actor
  for +event:J.HitEvent
  for +base:U32
  for +next:U32
  {C.target_endpoint_found(None{},old,event,base,next,fallback) == fallback : C.Point}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law endpoint_next_present:
  for +fallback:C.Point
  for +old:P.Actor
  for +new:P.Actor
  for +event:J.HitEvent
  for +base:U32
  for +next:U32
  {C.target_endpoint_found(Some{new},old,event,base,next,fallback) == C.target_endpoint_next(P.identity(old,new),old,new,event,base,next,fallback) : C.Point}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law endpoint_base_missing:
  for +context:C.Context
  for +event:J.HitEvent
  {C.target_endpoint_old(None{},context,event) == C.target_at_impact(event) : C.Point}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law endpoint_base_present:
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +oldIndex:BI.Index<P.Actor>
  for +newIndex:BI.Index<P.Actor>
  for +prepared:C.Prepared
  for +old:P.Actor
  for +event:J.HitEvent
  {C.target_endpoint_old(Some{old},C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},event) == Bool.pick(C.Point,C.target_matches(old,event),C.target_endpoint_found(BI.find(~P.Actor,newIndex,C.target_seed(event)),old,event,base,next,C.dying_endpoint(C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},old,event)),C.target_at_impact(event)) : C.Point}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law endpoint_relative:
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +oldIndex:BI.Index<P.Actor>
  for +newIndex:BI.Index<P.Actor>
  for +prepared:C.Prepared
  for +event:J.HitEvent
  {C.endpoint(C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},event) == C.relative(event,C.target_endpoint_old(BI.find(~P.Actor,oldIndex,C.target_seed(event)),C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},event)) : C.Point}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law keep_removed:
  for +tail:List<&2,P.Actor>
  {C.keep(None{},tail) == tail : List<&2,P.Actor>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law keep_present:
  for +actor:P.Actor
  for +tail:List<&2,P.Actor>
  {C.keep(Some{actor},tail) == actor <> tail : List<&2,P.Actor>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law project_rows_empty:
  for +context:C.Context
  for +acc:List<&2,P.Actor>
  {C.project_rows([],context,acc) == List.reverse(&2,P.Actor,acc) : List<&2,P.Actor>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law project_rows_cons:
  for +head:P.Actor
  for +tail:List<&2,P.Actor>
  for +context:C.Context
  for +acc:List<&2,P.Actor>
  {C.project_rows(head <> tail,context,acc) == C.project_rows(tail,context,C.keep(C.project_actor(context,head),acc)) : List<&2,P.Actor>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law find_frame_empty:
  for +observation:U32
  for +found:Maybe<&2,P.Indexed>
  {C.find_frame([],observation,found) == found : Maybe<&2,P.Indexed>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law find_frame_cons:
  for +head:P.Indexed
  for +tail:List<&2,P.Indexed>
  for +observation:U32
  for +found:Maybe<&2,P.Indexed>
  {C.find_frame(head <> tail,observation,found) == C.find_frame(tail,observation,Bool.pick(Maybe<&2,P.Indexed>,U32.is_eq(P.observation(P.frame(head)),observation),Some{head},found)) : Maybe<&2,P.Indexed>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law project_pair_present:
  for +obs:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +alpha:F32
  for +players:List<&2,P.Actor>
  for +bodies:List<&2,P.Actor>
  for +old:P.Frame
  for +new:P.Frame
  for +oldPlayers:BI.Index<P.Actor>
  for +newPlayers:BI.Index<P.Actor>
  for +baseIndex:BI.Index<P.Actor>
  for +nextIndex:BI.Index<P.Actor>
  for +prepared:C.Prepared
  {C.project_pair(Some{P.Indexed{old,oldPlayers,baseIndex}},Some{P.Indexed{new,newPlayers,nextIndex}},P.Sample{obs,next,tick,fraction,alpha,players,bodies},prepared) == P.Sample{obs,next,tick,fraction,alpha,players,C.project_rows(bodies,C.Context{P.world_tick(old),P.world_tick(new),tick,fraction,baseIndex,nextIndex,C.path_prepared(prepared,bodies,P.world_tick(old),P.world_tick(new))},[])} : P.Sample}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law project_pair_base_missing:
  for +new:Maybe<&2,P.Indexed>
  for +sample:P.Sample
  for +prepared:C.Prepared
  {C.project_pair(None{},new,sample,prepared) == sample : P.Sample}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law project_pair_next_missing:
  for +old:P.Indexed
  for +sample:P.Sample
  for +prepared:C.Prepared
  {C.project_pair(Some{old},None{},sample,prepared) == sample : P.Sample}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law fx_add_hidden:
  for +event:J.HitEvent
  for +index:BI.Index<P.Actor>
  for +display:U32
  for +tail:List<&2,C.Fx>
  {C.fx_add(False{},event,index,display,tail) == tail : List<&2,C.Fx>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law fx_add_visible:
  for +event:J.HitEvent
  for +index:BI.Index<P.Actor>
  for +display:U32
  for +tail:List<&2,C.Fx>
  {C.fx_add(True{},event,index,display,tail) == C.fx(event,C.fx_point(BI.find(~P.Actor,index,C.target_seed(event)),event),display) <> tail : List<&2,C.Fx>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law effects_empty:
  for +index:BI.Index<P.Actor>
  for +display:U32
  for +acc:List<&2,C.Fx>
  {C.effects([],index,display,acc) == List.reverse(&2,C.Fx,acc) : List<&2,C.Fx>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law effects_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +index:BI.Index<P.Actor>
  for +display:U32
  for +acc:List<&2,C.Fx>
  {C.effects(head <> tail,index,display,acc) == C.effects(tail,index,display,C.fx_add(C.fx_recent(head,display),head,index,display,acc)) : List<&2,C.Fx>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: FX uses the final projected target cohort, never a separate stale target position list.
law output_exact:
  for +paths:BI.Index<J.HitEvent>
  for +obs:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +alpha:F32
  for +players:List<&2,P.Actor>
  for +bodies:List<&2,P.Actor>
  for +shots:BI.Index<List<&2,J.HitEvent>>
  for +targets:BI.Index<List<&2,J.HitEvent>>
  for +events:List<&2,J.HitEvent>
  {C.output(P.Sample{obs,next,tick,fraction,alpha,players,bodies},C.Prepared{shots,targets,events,paths}) == C.Output{P.Sample{obs,next,tick,fraction,alpha,players,bodies},C.effects(events,P.index_rows(bodies,BI.Empty{}),tick,[])} : C.Output}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law project_exact:
  for +obs:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +alpha:F32
  for +players:List<&2,P.Actor>
  for +bodies:List<&2,P.Actor>
  for +rows:List<&2,P.Indexed>
  for +cursor:P.Cursor
  for +recovered:Bool
  for +delay:U32
  for +prepared:C.Prepared
  {C.project(P.State{rows,cursor,recovered,delay},P.Sample{obs,next,tick,fraction,alpha,players,bodies},prepared) == C.output(C.project_pair(C.find_frame(rows,obs,None{}),C.find_frame(rows,next,None{}),P.Sample{obs,next,tick,fraction,alpha,players,bodies},prepared),prepared) : C.Output}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: Preparing a received journal cannot retain more than 512 input receipts.
law prepare_exact:
  for +epoch:U32
  for +now:U32
  for +events:List<&2,J.HitEvent>
  for +overflow:U32
  for +expired:U32
  {C.prepare(J.State{epoch,now,events,overflow,expired}) == C.prepare_rows(List.take(&2,J.HitEvent,events,512n),BI.Empty{},BI.Empty{},[]) : C.Prepared}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law prepare_rows_empty:
  for +shots:BI.Index<List<&2,J.HitEvent>>
  for +targets:BI.Index<List<&2,J.HitEvent>>
  for +events:List<&2,J.HitEvent>
  {C.prepare_rows([],shots,targets,events) == C.Prepared{shots,targets,events,BI.Empty{}} : C.Prepared}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: Every receipt is indexed in its own shot and target buckets, not scanned once per actor.
law prepare_rows_cons:
  for +head:J.HitEvent
  for +tail:List<&2,J.HitEvent>
  for +shots:BI.Index<List<&2,J.HitEvent>>
  for +targets:BI.Index<List<&2,J.HitEvent>>
  for +events:List<&2,J.HitEvent>
  {C.prepare_rows(head <> tail,shots,targets,events) == C.prepare_rows(tail,C.bucket_add(shots,C.shot_seed(head),head),C.bucket_add(targets,C.target_seed(head),head),head <> events) : C.Prepared}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law bucket_add_exact:
  for +index:BI.Index<List<&2,J.HitEvent>>
  for +key:U32
  for +event:J.HitEvent
  {C.bucket_add(index,key,event) == C.bucket_go(32n,index,key,event,BI.outside(~List<&2,J.HitEvent>,index,key),BI.branch(~List<&2,J.HitEvent>,index,key)) : BI.Index<List<&2,J.HitEvent>>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: Multiple piercing contacts with the same shot seed must all remain selectable.
law bucket_existing_key:
  for +key:U32
  for +oldKey:U32
  for +event:J.HitEvent
  for +rows:List<&2,J.HitEvent>
  {C.bucket_item(True{},key,event,oldKey,rows) == BI.Item{oldKey,event <> rows} : BI.Index<List<&2,J.HitEvent>>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law bucket_new_key:
  for +key:U32
  for +oldKey:U32
  for +event:J.HitEvent
  for +rows:List<&2,J.HitEvent>
  {C.bucket_item(False{},key,event,oldKey,rows) == BI.insert(~List<&2,J.HitEvent>,BI.Item{oldKey,rows},key,[event]) : BI.Index<List<&2,J.HitEvent>>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law bucket_empty:
  for +fuel:Nat
  for +key:U32
  for +event:J.HitEvent
  for +above:Bool
  for +one:Bool
  {C.bucket_go(fuel,BI.Empty{},key,event,above,one) == BI.Item{key,[event]} : BI.Index<List<&2,J.HitEvent>>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law bucket_item_dispatch:
  for +fuel:Nat
  for +key:U32
  for +oldKey:U32
  for +event:J.HitEvent
  for +rows:List<&2,J.HitEvent>
  for +above:Bool
  for +one:Bool
  {C.bucket_go(fuel,BI.Item{oldKey,rows},key,event,above,one) == C.bucket_item(U32.is_eq(oldKey,key),key,event,oldKey,rows) : BI.Index<List<&2,J.HitEvent>>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law bucket_branch_zero:
  for +fuel:Nat
  for +sample:U32
  for +mask:U32
  for +zero:BI.Index<List<&2,J.HitEvent>>
  for +one:BI.Index<List<&2,J.HitEvent>>
  for +key:U32
  for +event:J.HitEvent
  {C.bucket_go(1n+fuel,BI.Fork{sample,mask,zero,one},key,event,False{},False{}) == BI.Fork{sample,mask,C.bucket_go(fuel,zero,key,event,BI.outside(~List<&2,J.HitEvent>,zero,key),BI.branch(~List<&2,J.HitEvent>,zero,key)),one} : BI.Index<List<&2,J.HitEvent>>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law bucket_branch_one:
  for +fuel:Nat
  for +sample:U32
  for +mask:U32
  for +zero:BI.Index<List<&2,J.HitEvent>>
  for +one:BI.Index<List<&2,J.HitEvent>>
  for +key:U32
  for +event:J.HitEvent
  {C.bucket_go(1n+fuel,BI.Fork{sample,mask,zero,one},key,event,False{},True{}) == BI.Fork{sample,mask,zero,C.bucket_go(fuel,one,key,event,BI.outside(~List<&2,J.HitEvent>,one,key),BI.branch(~List<&2,J.HitEvent>,one,key))} : BI.Index<List<&2,J.HitEvent>>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law bucket_above:
  for +fuel:Nat
  for +sample:U32
  for +mask:U32
  for +zero:BI.Index<List<&2,J.HitEvent>>
  for +one:BI.Index<List<&2,J.HitEvent>>
  for +key:U32
  for +event:J.HitEvent
  for +side:Bool
  {C.bucket_go(fuel,BI.Fork{sample,mask,zero,one},key,event,True{},side) == BI.insert(~List<&2,J.HitEvent>,BI.Fork{sample,mask,zero,one},key,[event]) : BI.Index<List<&2,J.HitEvent>>}

# Guarantees: The public path is exactly connected to the stated pure policy operations.
# Why it matters: The production contact path must use its separately specified decisions.
law bucket_exhausted:
  for +sample:U32
  for +mask:U32
  for +zero:BI.Index<List<&2,J.HitEvent>>
  for +one:BI.Index<List<&2,J.HitEvent>>
  for +key:U32
  for +event:J.HitEvent
  for +side:Bool
  {C.bucket_go(0n,BI.Fork{sample,mask,zero,one},key,event,False{},side) == BI.Fork{sample,mask,zero,one} : BI.Index<List<&2,J.HitEvent>>}


# Guarantees: No matching target receipt leaves the target-path index unchanged.
# Why it matters: Unknown targets cannot acquire fabricated trajectories.
law path_insert_missing:
  for +index:BI.Index<J.HitEvent>
  {C.path_insert(None{},index) == index : BI.Index<J.HitEvent>}

# Guarantees: One selected receipt is indexed under its exact target seed.
# Why it matters: Multiple shots can reuse one selected target trajectory without rescanning the journal.
law path_insert_present:
  for +index:BI.Index<J.HitEvent>
  for +event:J.HitEvent
  {C.path_insert(Some{event},index) == BI.insert(~J.HitEvent,index,C.target_seed(event),event) : BI.Index<J.HitEvent>}

# Guarantees: Enemy path selection uses the same target eligibility and latest-receipt policy.
# Why it matters: The target body and all shots need one canonical choice of trajectory.
law path_candidate_yes:
  for +actor:P.Actor
  for +context:C.Context
  for +index:BI.Index<J.HitEvent>
  {C.path_candidate_selected(True{},actor,context,index) == C.path_insert(C.contact_for(context,actor,False{}),index) : BI.Index<J.HitEvent>}

# Guarantees: Non-enemy actors do not add target trajectories.
# Why it matters: Projectile seed namespaces cannot overwrite enemy trajectories.
law path_candidate_no:
  for +actor:P.Actor
  for +context:C.Context
  for +index:BI.Index<J.HitEvent>
  {C.path_candidate_selected(False{},actor,context,index) == index : BI.Index<J.HitEvent>}

# Guarantees: Only actor kind zero enters target path preparation.
# Why it matters: The shared path index contains enemy lifetimes only.
law path_candidate_kind:
  for +key:U32
  for +kind:U32
  for +generation:String
  for +x:F32
  for +y:F32
  for +age:U32
  for +alive:Bool
  for +owner:U32
  for +context:C.Context
  for +index:BI.Index<J.HitEvent>
  {C.path_candidate(P.Actor{key,kind,generation,x,y,age,alive,owner},context,index) == C.path_candidate_selected(U32.is_eq(kind,0),P.Actor{key,kind,generation,x,y,age,alive,owner},context,index) : BI.Index<J.HitEvent>}

# Guarantees: Path preparation preserves its accumulated index when all actors are processed.
# Why it matters: Completed target selections remain available to all projectile endpoints.
law path_rows_empty:
  for +context:C.Context
  for +index:BI.Index<J.HitEvent>
  {C.path_rows([],context,index) == index : BI.Index<J.HitEvent>}

# Guarantees: Each base inventory actor contributes to path selection exactly through the enemy guard.
# Why it matters: One traversal prepares target trajectories for the whole cohort.
law path_rows_cons:
  for +head:P.Actor
  for +tail:List<&2,P.Actor>
  for +context:C.Context
  for +index:BI.Index<J.HitEvent>
  {C.path_rows(head <> tail,context,index) == C.path_rows(tail,context,C.path_candidate(head,context,index)) : BI.Index<J.HitEvent>}

# Guarantees: Preparing bracket paths retains receipt buckets and builds one target-path index from this bracket and inventory.
# Why it matters: Receipts from a different display interval cannot choose the trajectory.
law path_prepared_exact:
  for +shots:BI.Index<List<&2,J.HitEvent>>
  for +targets:BI.Index<List<&2,J.HitEvent>>
  for +events:List<&2,J.HitEvent>
  for +paths:BI.Index<J.HitEvent>
  for +rows:List<&2,P.Actor>
  for +base:U32
  for +next:U32
  {C.path_prepared(C.Prepared{shots,targets,events,paths},rows,base,next) == C.Prepared{shots,targets,events,C.path_rows(rows,C.Context{base,next,0,0n,BI.Empty{},BI.Empty{},C.Prepared{shots,targets,events,paths}},BI.Empty{})} : C.Prepared}

# Guarantees: Shared target-path lookup reads the prepared index at the supplied seed.
# Why it matters: Every endpoint references the same selected receipt rather than independently choosing a path.
law path_lookup_exact:
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +oldIndex:BI.Index<P.Actor>
  for +newIndex:BI.Index<P.Actor>
  for +shots:BI.Index<List<&2,J.HitEvent>>
  for +targets:BI.Index<List<&2,J.HitEvent>>
  for +events:List<&2,J.HitEvent>
  for +paths:BI.Index<J.HitEvent>
  for +key:U32
  {C.path_lookup(C.Context{base,next,tick,fraction,oldIndex,newIndex,C.Prepared{shots,targets,events,paths}},key) == BI.find(~J.HitEvent,paths,key) : Maybe<&2,J.HitEvent>}

# Guarantees: Shots retain terminal-event selection from their own receipt bucket.
# Why it matters: Piercing and terminal selection remain independent of the shared target trajectory.
law selected_shot_contact:
  for +context:C.Context
  for +actor:P.Actor
  {C.selected_contact(True{},context,actor) == C.contact_for(context,actor,True{}) : Maybe<&2,J.HitEvent>}

# Guarantees: Targets use exactly their prepared shared trajectory receipt.
# Why it matters: A target cannot independently select a different motion path than its impacting shots.
law selected_target_contact:
  for +context:C.Context
  for +actor:P.Actor
  {C.selected_contact(False{},context,actor) == C.path_lookup(context,P.actor_key(actor)) : Maybe<&2,J.HitEvent>}

# Guarantees: The one target path is older position to its selected receipt target position evaluated at a supplied relative time.
# Why it matters: An earlier terminal shot and a later dying target receipt must still share one visible path.
law target_trajectory_exact:
  for +actor:P.Actor
  for +path:J.HitEvent
  for +time:F32
  for +base:U32
  {C.target_trajectory(actor,path,time,base) == C.lerp(C.point(actor),C.target_at_impact(path),C.progress(time,C.offset(path,base))) : C.Point}

# Guarantees: Missing shared path information uses the shot receipt canonical target position.
# Why it matters: Unknown target histories do not manufacture a different target trajectory.
law dead_endpoint_missing:
  for +old:P.Actor
  for +event:J.HitEvent
  for +base:U32
  {C.dead_endpoint(None{},old,event,base) == C.target_at_impact(event) : C.Point}

# Guarantees: A terminal shot evaluates the selected target path at that shot contact time.
# Why it matters: An earlier hit cannot use a separate target world when later receipts change the selected trajectory.
law dead_endpoint_shared:
  for +old:P.Actor
  for +path:J.HitEvent
  for +event:J.HitEvent
  for +base:U32
  {C.dead_endpoint(Some{path},old,event,base) == C.target_trajectory(old,path,C.offset(event,base),base) : C.Point}

# Guarantees: Dying-target endpoint reconstruction uses the prepared path of the exact older actor key.
# Why it matters: Shot endpoints cannot bypass the shared trajectory lookup.
law dying_endpoint_lookup:
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +oldIndex:BI.Index<P.Actor>
  for +newIndex:BI.Index<P.Actor>
  for +prepared:C.Prepared
  for +old:P.Actor
  for +event:J.HitEvent
  {C.dying_endpoint(C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},old,event) == C.dead_endpoint(C.path_lookup(C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},P.actor_key(old)),old,event,base) : C.Point}

# Guarantees: The displayed dying target evaluates that same selected path at the shared presentation cursor.
# Why it matters: Target motion and terminal-shot endpoint evaluation differ only in the requested time.
law target_display_shared:
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +oldIndex:BI.Index<P.Actor>
  for +newIndex:BI.Index<P.Actor>
  for +prepared:C.Prepared
  for +actor:P.Actor
  for +path:J.HitEvent
  {C.target_display(C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},actor,path) == C.target_trajectory(actor,path,C.cursor_offset(tick,base,fraction),base) : C.Point}

# Guarantees: At a shot contact time, target display and that shot target endpoint are exactly equal on their shared path.
# Why it matters: Different-time hits on one nonlinear dying target cannot produce competing visual target positions.
law shared_target_trajectory_at_contact:
  for +base:U32
  for +next:U32
  for +tick:U32
  for +fraction:Nat
  for +oldIndex:BI.Index<P.Actor>
  for +newIndex:BI.Index<P.Actor>
  for +prepared:C.Prepared
  for +actor:P.Actor
  for +path:J.HitEvent
  for +event:J.HitEvent
  for at_contact:{C.cursor_offset(tick,base,fraction) == C.offset(event,base) : F32}
  {C.target_display(C.Context{base,next,tick,fraction,oldIndex,newIndex,prepared},actor,path) == C.dead_endpoint(Some{path},actor,event,base) : C.Point}
