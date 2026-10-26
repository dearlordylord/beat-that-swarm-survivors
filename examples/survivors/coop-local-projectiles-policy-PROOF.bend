import Base
import ./coop-local-projectiles-policy-LAWS.bend as L
import ./coop-local-projectiles-policy.bend as P

def L.overflow_added_exact_removed_rows(before,after): {==}
def L.overflow_513_to_512_is_one(): {==}
def L.terminal_classification_exact(kind,outcome): {==}
def L.terminal_event_uses_kind_and_outcome(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome): {==}
def L.event_recent_exact_window(now,tick): {==}
def L.current_life_empty_exact(seed,generation): {==}
def L.current_life_cons_exact(seed,generation,storedSeed,storedGeneration,x,y,radius,alive,tail): {==}
def L.target_seed_projects_constructor_field(seed,generation,x,y,radius,alive): {==}
def L.target_generation_projects_constructor_field(seed,generation,x,y,radius,alive): {==}
def L.target_x_projects_constructor_field(seed,generation,x,y,radius,alive): {==}
def L.target_y_projects_constructor_field(seed,generation,x,y,radius,alive): {==}
def L.event_seed_projects_constructor_field(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome): {==}
def L.event_generation_projects_constructor_field(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome): {==}
def L.event_impact_projects_constructor_fields(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome): {==}
def L.hit_shot_id_projects_constructor_field(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome): {==}
def L.hit_tick_projects_constructor_field(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome): {==}
def L.event_x_projects_impact_x(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome): {==}
def L.event_y_projects_impact_y(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome): {==}
def L.target_at_x_projects_constructor_field(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome): {==}
def L.target_at_y_projects_constructor_field(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome): {==}
def L.target_contact_uses_impact_minus_target_offset(shotId,tick,kind,seed,generation,impactX,impactY,targetX,targetY,radius,outcome,displayX,displayY): {==}
def L.contact_found_empty_uses_canonical_impact(event): {==}
def L.contact_found_live_exact_lifetime_uses_display_offset(event,seed,generation,x,y,radius,alive): {==}
def L.event_contact_empty_keeps_impact(event): {==}
def L.event_contact_uses_matching_lifetime_offset(): {==}
def L.event_contact_rejects_reused_seed(): {==}
def L.event_contact_wires_exact_lifetime_lookup(event,targets): {==}
def L.draw_fields_exact(life,pending,confirmed,late,fade): {==}
def L.should_draw_uses_complete_fields(id,player,life,pending,confirmed,late,fade): {==}
def L.visible_id_empty_exact(player,id): {==}
def L.visible_id_cons_exact(head,tail,player,id): {==}
def L.visible_row_exact(storedId,storedPlayer,life,pending,confirmed,late,fade,player,id): {==}
def L.terminal_receipt_matches_exact(now,shotId,event): {==}
def L.terminal_receipt_search_empty(now,shotId): {==}
def L.terminal_receipt_search_cons(now,shotId,head,tail): {==}
def L.nonplayer_kind_is_always_shown(player,owner,id,now,shots,events): {==}
def L.nonowner_projectile_is_always_shown(player,id,now,shots,events): {==}
def L.local_projectile_suppression_checks_preview_or_terminal(player,id,now,shots,events): {==}
def L.prepared_visibility_wires_kind_and_owner(now,shots,events,player,kind,owner,id): {==}
