import Base
import ./coop-local-projectiles-policy.bend as P

# Guarantees: overflow accounting reports exactly the rows removed by a bounded take.
# Why it matters: a 513 row local shot ledger must report one eviction, not a boolean or zero.
law overflow_added_exact_removed_rows:
  for +before:Nat
  for +after:Nat
  {P.overflow_added(before,after) == U32.from_nat(Nat.sub(before,after)) : U32}

# Guarantees: trimming from 513 to 512 rows adds one to the overflow counter.
# Why it matters: operators can distinguish one dropped visual from a bulk eviction.
law overflow_513_to_512_is_one:
  {P.overflow_added(513n,512n) == 1 : U32}

# Guarantees: only a successful terminal sweep receipt retires a canonical projectile.
# Why it matters: area and nonterminal contacts must not hide a still-flying authoritative shot.
law terminal_classification_exact:
  for +kind:U32
  for +outcome:U32
  {P.terminal_parts(kind,outcome) == Bool.and(U32.is_eq(kind,2),U32.is_eq(outcome,0)) : Bool}

law terminal_event_uses_kind_and_outcome:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  {P.terminal_event(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome}) == P.terminal_parts(kind,outcome) : Bool}

# Guarantees: a retained event is recent within a 64 tick window in either direction.
# Why it matters: receive-ahead terminal receipts and slightly late receipts use the same window.
law event_recent_exact_window:
  for +now:U32
  for +tick:U32
  {P.event_recent(now,tick) == Bool.or(Bool.and(U32.is_le(tick,now),U32.is_lt((now - tick : U32),64)),Bool.and(U32.is_gt(tick,now),U32.is_lt((tick - now : U32),64))) : Bool}

# Guarantees: current target lookup filters by alive status, seed, and birth generation across the whole list.
# Why it matters: a pooled enemy reusing a seed cannot inherit an older hit's contact point.
law current_life_empty_exact:
  for +seed:U32
  for +generation:U32
  {P.current_life([],seed,generation) == None{} : Maybe<&2,P.Target>}

law current_life_cons_exact:
  for +seed:U32
  for +generation:U32
  for +storedSeed:U32
  for +storedGeneration:U32
  for +x:F32
  for +y:F32
  for +radius:F32
  for +alive:Bool
  for +tail:List<&2,P.Target>
  {P.current_life(P.Target{storedSeed,storedGeneration,x,y,radius,alive} <> tail,seed,generation) == Bool.pick(Maybe<&2,P.Target>,Bool.and(alive,Bool.and(U32.is_eq(storedSeed,seed),U32.is_eq(storedGeneration,generation))),Some{P.Target{storedSeed,storedGeneration,x,y,radius,alive}},P.current_life(tail,seed,generation)) : Maybe<&2,P.Target>}

law target_seed_projects_constructor_field:
  for +seed:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +radius:F32
  for +alive:Bool
  {P.target_seed(P.Target{seed,generation,x,y,radius,alive}) == seed : U32}

law target_generation_projects_constructor_field:
  for +seed:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +radius:F32
  for +alive:Bool
  {P.target_generation(P.Target{seed,generation,x,y,radius,alive}) == generation : U32}

law target_x_projects_constructor_field:
  for +seed:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +radius:F32
  for +alive:Bool
  {P.target_x(P.Target{seed,generation,x,y,radius,alive}) == x : F32}

law target_y_projects_constructor_field:
  for +seed:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +radius:F32
  for +alive:Bool
  {P.target_y(P.Target{seed,generation,x,y,radius,alive}) == y : F32}

law event_seed_projects_constructor_field:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  {P.event_seed(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome}) == seed : U32}

law event_generation_projects_constructor_field:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  {P.event_generation(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome}) == generation : U32}

law event_impact_projects_constructor_fields:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  {P.event_impact(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome}) == P.Point{impactX,impactY} : P.Point}

law hit_shot_id_projects_constructor_field:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  {P.hit_shot_id(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome}) == shotId : String}

law hit_tick_projects_constructor_field:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  {P.hit_tick(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome}) == tick : U32}

law event_x_projects_impact_x:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  {P.event_x(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome}) == impactX : F32}

law event_y_projects_impact_y:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  {P.event_y(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome}) == impactY : F32}

law target_at_x_projects_constructor_field:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  {P.target_at_x(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome}) == targetX : F32}

law target_at_y_projects_constructor_field:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  {P.target_at_y(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome}) == targetY : F32}

law target_contact_uses_impact_minus_target_offset:
  for +shotId:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +impactX:F32
  for +impactY:F32
  for +targetX:F32
  for +targetY:F32
  for +radius:F32
  for +outcome:U32
  for +displayX:F32
  for +displayY:F32
  {P.target_contact(P.Hit{shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome},displayX,displayY) == P.Point{(displayX + (impactX - targetX : F32) : F32),(displayY + (impactY - targetY : F32) : F32)} : P.Point}

law contact_found_empty_uses_canonical_impact:
  for +event:P.Hit
  {P.contact_found(None{},event) == P.event_impact(event) : P.Point}

law contact_found_live_exact_lifetime_uses_display_offset:
  for +event:P.Hit
  for +seed:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +radius:F32
  for +alive:Bool
  {P.contact_found(Some{P.Target{seed,generation,x,y,radius,alive}},event) == Bool.pick(P.Point,U32.is_eq(generation,P.event_generation(event)),P.target_contact(event,x,y),P.event_impact(event)) : P.Point}

# Guarantees: a missing or dead target lifetime keeps the event's immutable world impact point.
# Why it matters: a skipped-death presentation jump cannot steer a confirmed projectile onto an old corpse pose.
law event_contact_empty_keeps_impact:
  for +event:P.Hit
  {P.event_contact(event,[]) == P.event_impact(event) : P.Point}

# Guarantees: a live matching lifetime moves the event point by its recorded impact-to-target offset.
# Why it matters: contact FX and a guided local preview agree at the displayed enemy pose.
law event_contact_uses_matching_lifetime_offset:
  {P.event_contact(P.Hit{"shot",20,2,7,3,15.0,27.0,10.0,20.0,1.0,0},[P.Target{7,3,30.0,40.0,5.0,True{}}]) == P.Point{(30.0 + (15.0 - 10.0 : F32) : F32),(40.0 + (27.0 - 20.0 : F32) : F32)} : P.Point}

# Guarantees: the same seed with a different generation cannot move the confirmed impact.
# Why it matters: a reused enemy slot cannot attract a prior lifetime's contact marker.
law event_contact_rejects_reused_seed:
  {P.event_contact(P.Hit{"shot",20,2,7,3,15.0,27.0,10.0,20.0,1.0,0},[P.Target{7,4,30.0,40.0,5.0,True{}}]) == P.Point{15.0,27.0} : P.Point}

# Guarantees: the complete lookup and contact fallback are connected for every event and target cohort.
# Why it matters: a correct helper cannot be bypassed by a renderer that binds only the nearest seed.
law event_contact_wires_exact_lifetime_lookup:
  for +event:P.Hit
  for +targets:List<&2,P.Target>
  {P.event_contact(event,targets) == P.contact_found(P.current_life(targets,P.event_seed(event),P.event_generation(event)),event) : P.Point}

# Guarantees: pending previews, confirmed previews, live shots, and fade rows follow the complete draw predicate.
# Why it matters: constant-false rendering cannot silently hide a local preview that is still alive.
law draw_fields_exact:
  for +life:U32
  for +pending:Bool
  for +confirmed:Bool
  for +late:Bool
  for +fade:U32
  {P.draw_fields(life,pending,confirmed,late,fade) == Bool.or(pending,Bool.or(Bool.and(confirmed,Bool.or(Bool.not(late),U32.is_gt(fade,0))),Bool.or(U32.is_gt(life,0),U32.is_gt(fade,0)))) : Bool}

law should_draw_uses_complete_fields:
  for +id:String
  for +player:U32
  for +life:U32
  for +pending:Bool
  for +confirmed:Bool
  for +late:Bool
  for +fade:U32
  {P.should_draw(P.VisibleShot{id,player,life,pending,confirmed,late,fade}) == P.draw_fields(life,pending,confirmed,late,fade) : Bool}

# Guarantees: visible identity lookup checks every row and requires both player and shot ID.
# Why it matters: a different player's same-ID visual cannot suppress this player's canonical echo.
law visible_id_empty_exact:
  for +player:U32
  for +id:String
  {P.visible_id([],player,id) == False{} : Bool}

law visible_id_cons_exact:
  for +head:P.VisibleShot
  for +tail:List<&2,P.VisibleShot>
  for +player:U32
  for +id:String
  {P.visible_id(head <> tail,player,id) == Bool.or(P.visible_row(head,player,id),P.visible_id(tail,player,id)) : Bool}

law visible_row_exact:
  for +storedId:String
  for +storedPlayer:U32
  for +life:U32
  for +pending:Bool
  for +confirmed:Bool
  for +late:Bool
  for +fade:U32
  for +player:U32
  for +id:String
  {P.visible_row(P.VisibleShot{storedId,storedPlayer,life,pending,confirmed,late,fade},player,id) == Bool.and(U32.is_eq(storedPlayer,player),Bool.and(P.draw_fields(life,pending,confirmed,late,fade),String.eq(storedId,id))) : Bool}

law terminal_receipt_matches_exact:
  for +now:U32
  for +shotId:String
  for +event:P.Hit
  {P.terminal_receipt_matches(now,shotId,event) == Bool.and(String.eq(P.hit_shot_id(event),shotId),Bool.and(P.terminal_event(event),P.event_recent(now,P.hit_tick(event)))) : Bool}

law terminal_receipt_search_empty:
  for +now:U32
  for +shotId:String
  {P.contains_terminal_receipt([],now,shotId) == False{} : Bool}

law terminal_receipt_search_cons:
  for +now:U32
  for +shotId:String
  for +head:P.Hit
  for +tail:List<&2,P.Hit>
  {P.contains_terminal_receipt(head <> tail,now,shotId) == Bool.or(P.terminal_receipt_matches(now,shotId,head),P.contains_terminal_receipt(tail,now,shotId)) : Bool}

# Guarantees: canonical local shots are hidden only for a drawable same-player preview or a recent terminal receipt.
# Why it matters: a speculative preview expiring without host confirmation must reveal the host projectile again.
law nonplayer_kind_is_always_shown:
  for +player:U32
  for +owner:U32
  for +id:String
  for +now:U32
  for +shots:List<&2,P.VisibleShot>
  for +events:List<&2,P.Hit>
  {P.kind_selected(False{},U32.is_eq(owner,player),player,id,now,shots,events) == True{} : Bool}

law nonowner_projectile_is_always_shown:
  for +player:U32
  for +id:String
  for +now:U32
  for +shots:List<&2,P.VisibleShot>
  for +events:List<&2,P.Hit>
  {P.kind_selected(True{},False{},player,id,now,shots,events) == True{} : Bool}

law local_projectile_suppression_checks_preview_or_terminal:
  for +player:U32
  for +id:String
  for +now:U32
  for +shots:List<&2,P.VisibleShot>
  for +events:List<&2,P.Hit>
  {P.kind_selected(True{},True{},player,id,now,shots,events) == Bool.not(Bool.or(P.contains_terminal_receipt(events,now,id),P.visible_id(shots,player,id))) : Bool}

law prepared_visibility_wires_kind_and_owner:
  for +now:U32
  for +shots:List<&2,P.VisibleShot>
  for +events:List<&2,P.Hit>
  for +player:U32
  for +kind:U32
  for +owner:U32
  for +id:String
  {P.should_show_prepared(P.Visibility{now,shots,events},player,kind,owner,id) == P.kind_selected(U32.is_eq(kind,1),U32.is_eq(owner,player),player,id,now,shots,events) : Bool}

# Guarantees: the external JSON frame contains all three typed row groups in their declared order.
# Why it matters: an empty encoder cannot pass while dropping projectile, contact, or corpse output.
law render_frame_encodes_each_collection:
  for +shots:List<&2,P.RenderShot>
  for +contacts:List<&2,P.ContactFx>
  for +corpses:List<&2,P.TargetFade>
  {P.native_render_frame(P.RenderFrame{shots,contacts,corpses}) == "{\"shots\":[" ++ P.native_shots(shots) ++ "],\"contacts\":[" ++ P.native_contacts(contacts) ++ "],\"corpses\":[" ++ P.native_corpses(corpses) ++ "]}" : String}

# Guarantees: shot JSON rows preserve every field from the runtime DTO.
# Why it matters: a correct visibility decision must still serialize the selected point and life metadata.
law native_render_shot_encodes_all_fields:
  for +id:String
  for +player:U32
  for +kind:U32
  for +weapon:U32
  for +seed:U32
  for +age:U32
  for +x:F32
  for +y:F32
  for +radius:F32
  for +life:U32
  for +fade:U32
  for +opacity:F32
  {P.native_render_shot(P.RenderShot{id,player,kind,weapon,seed,age,x,y,radius,life,fade,opacity}) == "{\"id\":\"" ++ id ++ "\",\"player\":" ++ U32.show(player) ++ ",\"kind\":" ++ U32.show(kind) ++ ",\"weapon\":" ++ U32.show(weapon) ++ ",\"seed\":" ++ U32.show(seed) ++ ",\"age\":" ++ U32.show(age) ++ ",\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"radius\":" ++ F32.show(radius) ++ ",\"life\":" ++ U32.show(life) ++ ",\"fade\":" ++ U32.show(fade) ++ ",\"opacity\":" ++ F32.show(opacity) ++ "}" : String}

law native_contact_encodes_all_fields:
  for +id:String
  for +tick:U32
  for +kind:U32
  for +seed:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +radius:F32
  for +age:U32
  for +opacity:F32
  {P.native_contact(P.ContactFx{id,tick,kind,seed,generation,x,y,radius,age,opacity}) == "{\"id\":\"" ++ id ++ "\",\"tick\":" ++ U32.show(tick) ++ ",\"kind\":" ++ U32.show(kind) ++ ",\"targetSeed\":" ++ U32.show(seed) ++ ",\"targetGeneration\":" ++ U32.show(generation) ++ ",\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"radius\":" ++ F32.show(radius) ++ ",\"age\":" ++ U32.show(age) ++ ",\"opacity\":" ++ F32.show(opacity) ++ "}" : String}

law native_corpse_encodes_all_fields:
  for +id:String
  for +seed:U32
  for +generation:U32
  for +x:F32
  for +y:F32
  for +radius:F32
  for +lastSeen:U32
  {P.native_corpse(P.TargetFade{id,seed,generation,x,y,radius,lastSeen}) == "{\"id\":\"" ++ id ++ "\",\"seed\":" ++ U32.show(seed) ++ ",\"generation\":" ++ U32.show(generation) ++ ",\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"radius\":" ++ F32.show(radius) ++ ",\"lastSeen\":" ++ U32.show(lastSeen) ++ "}" : String}

# Guarantees: shot list encoding emits every row with exactly one comma between adjacent rows.
# Why it matters: a nonempty frame must not become an empty array or malformed JSON list.
law native_shots_empty_exact:
  {P.native_shots([]) == "" : String}
law native_shots_cons_exact:
  for +head:P.RenderShot
  for +tailHead:P.RenderShot
  for +tail:List<&2,P.RenderShot>
  {P.native_shots(head <> (tailHead <> tail)) == P.native_render_shot(head) ++ "," ++ P.native_shots(tailHead <> tail) : String}
law native_shots_singleton_exact:
  for +head:P.RenderShot
  {P.native_shots([head]) == P.native_render_shot(head) : String}

# Guarantees: contact and corpse lists retain their rows through JSON encoding.
# Why it matters: confirmed hit FX and lifetime markers survive the host boundary.
law native_contacts_empty_exact:
  {P.native_contacts([]) == "" : String}
law native_contacts_cons_exact:
  for +head:P.ContactFx
  for +tailHead:P.ContactFx
  for +tail:List<&2,P.ContactFx>
  {P.native_contacts(head <> (tailHead <> tail)) == P.native_contact(head) ++ "," ++ P.native_contacts(tailHead <> tail) : String}
law native_contacts_singleton_exact:
  for +head:P.ContactFx
  {P.native_contacts([head]) == P.native_contact(head) : String}
law native_corpses_empty_exact:
  {P.native_corpses([]) == "" : String}
law native_corpses_cons_exact:
  for +head:P.TargetFade
  for +tailHead:P.TargetFade
  for +tail:List<&2,P.TargetFade>
  {P.native_corpses(head <> (tailHead <> tail)) == P.native_corpse(head) ++ "," ++ P.native_corpses(tailHead <> tail) : String}
law native_corpses_singleton_exact:
  for +head:P.TargetFade
  {P.native_corpses([head]) == P.native_corpse(head) : String}
