import Base
import ./coop-contact-playback.bend as C
import ./coop-contact-playback-LAWS.bend as L
import ./coop-playback.bend as P

def L.shot_seed_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome):
  {==}

def L.target_seed_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome):
  {==}

def L.fraction_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome):
  {==}

def L.confirmed_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome):
  {==}

def L.terminal_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome):
  {==}

def L.impact_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome):
  {==}

def L.target_at_impact_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome):
  {==}

def L.target_generation_exact(seed,born):
  {==}

def L.target_lifetime_exact(key,actorKind,actorGeneration,x,y,age,hp,owner,id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome):
  {==}

def L.shot_lifetime_exact(key,actorKind,actorGeneration,x,y,age,hp,owner,id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome):
  {==}

def L.point_exact(key,actorKind,actorGeneration,x,y,age,hp,owner):
  {==}

def L.positioned_preserves_metadata(key,actorKind,actorGeneration,x,y,age,hp,owner,nx,ny):
  {==}

def L.contact_relative_geometry(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome,x,y):
  {==}

def L.point_lerp_exact(x0,y0,x1,y1,alpha):
  {==}

def L.receipt_interval_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome,base,next):
  {==}

def L.terminal_order_exact(a,b):
  {==}

def L.newest_initial(event):
  {==}

def L.newest_ordered(old,new):
  {==}

def L.eligible_exact(event,actor,base,next,shot):
  {==}

def L.selected_reject(old,event):
  {==}

def L.selected_accept(old,event):
  {==}

def L.offset_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome,base):
  {==}

def L.cursor_offset_exact(tick,base,fraction):
  {==}

def L.progress_exact(elapsed,duration):
  {==}

def L.event_progress_exact(base,next,tick,fraction,oldIndex,newIndex,prepared,event):
  {==}

def L.reached_exact(base,next,tick,fraction,oldIndex,newIndex,prepared,event):
  {==}

def L.terminal_shot_removed(context,old,event):
  {==}

def L.terminal_shot_path(context,old,event):
  {==}

def L.no_receipt_preserves_actor(shot,context,actor):
  match shot:
    case False{}: {==}
    case True{}: {==}

def L.shot_receipt_dispatch(context,actor,event):
  {==}

def L.dying_target_path(context,actor,event):
  {==}

def L.actor_unchanged(context,actor,shot):
  {==}

def L.actor_changed_dispatch(context,actor,shot):
  {==}

def L.actor_policy_exact(key,actorKind,actorGeneration,x,y,age,hp,owner,context):
  {==}

def L.living_target_endpoint(fallback,old,new,event,base,next):
  {==}

def L.dying_target_endpoint(fallback,old,new,event,base,next):
  {==}

def L.fx_time_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome,display):
  {==}

def L.fx_unknown_target(event):
  {==}

def L.fx_known_target(actor,event):
  {==}

def L.fx_record_exact(id,tick,kind,shot,shotSeed,targetSeed,generation,fraction,ix,iy,tx,ty,radius,outcome,x,y,display):
  {==}

def L.selection_empty(actor,base,next,shot,found):
  {==}

def L.selection_cons(head,tail,actor,base,next,shot,found):
  {==}

def L.bucket_missing():
  {==}

def L.bucket_present(rows):
  {==}

def L.contact_lookup_exact(paths,base,next,tick,fraction,oldIndex,newIndex,shots,targets,events,actor,shot):
  {==}

def L.alive_missing(actor):
  {==}

def L.alive_present(actor,new):
  {==}

def L.continues_lookup(base,next,tick,fraction,oldIndex,newIndex,prepared,actor):
  {==}

def L.endpoint_next_missing(fallback,old,event,base,next):
  {==}

def L.endpoint_next_present(fallback,old,new,event,base,next):
  {==}

def L.endpoint_base_missing(context,event):
  {==}

def L.endpoint_base_present(base,next,tick,fraction,oldIndex,newIndex,prepared,old,event):
  {==}

def L.endpoint_relative(base,next,tick,fraction,oldIndex,newIndex,prepared,event):
  {==}

def L.keep_removed(tail):
  {==}

def L.keep_present(actor,tail):
  {==}

def L.project_rows_empty(context,acc):
  {==}

def L.project_rows_cons(head,tail,context,acc):
  {==}

def L.find_frame_empty(observation,found):
  {==}

def L.find_frame_cons(head,tail,observation,found):
  {==}

def L.project_pair_present(obs,next,tick,fraction,alpha,players,bodies,old,new,oldPlayers,newPlayers,baseIndex,nextIndex,prepared):
  {==}

def L.project_pair_base_missing(new,sample,prepared):
  {==}

def L.project_pair_next_missing(old,sample,prepared):
  match old:
    case P.Indexed{frame,players,bodies}: {==}

def L.fx_add_hidden(event,index,display,tail):
  {==}

def L.fx_add_visible(event,index,display,tail):
  {==}

def L.effects_empty(index,display,acc):
  {==}

def L.effects_cons(head,tail,index,display,acc):
  {==}

def L.output_exact(paths,obs,next,tick,fraction,alpha,players,bodies,shots,targets,events):
  {==}

def L.project_exact(obs,next,tick,fraction,alpha,players,bodies,rows,cursor,recovered,delay,prepared):
  {==}

def L.prepare_exact(epoch,now,events,overflow,expired):
  {==}

def L.prepare_rows_empty(shots,targets,events):
  {==}

def L.prepare_rows_cons(head,tail,shots,targets,events):
  {==}

def L.bucket_add_exact(index,key,event):
  {==}

def L.bucket_existing_key(key,oldKey,event,rows):
  {==}

def L.bucket_new_key(key,oldKey,event,rows):
  {==}

def L.bucket_empty(fuel,key,event,above,one):
  match fuel above one:
    case 0n False{} False{}: {==}
    case 0n False{} True{}: {==}
    case 0n True{} False{}: {==}
    case 0n True{} True{}: {==}
    case 1n+rest False{} False{}: {==}
    case 1n+rest False{} True{}: {==}
    case 1n+rest True{} False{}: {==}
    case 1n+rest True{} True{}: {==}

def L.bucket_item_dispatch(fuel,key,oldKey,event,rows,above,one):
  match fuel above one:
    case 0n False{} False{}: {==}
    case 0n False{} True{}: {==}
    case 0n True{} False{}: {==}
    case 0n True{} True{}: {==}
    case 1n+rest False{} False{}: {==}
    case 1n+rest False{} True{}: {==}
    case 1n+rest True{} False{}: {==}
    case 1n+rest True{} True{}: {==}

def L.bucket_branch_zero(fuel,sample,mask,zero,one,key,event):
  {==}

def L.bucket_branch_one(fuel,sample,mask,zero,one,key,event):
  {==}

def L.bucket_above(fuel,sample,mask,zero,one,key,event,side):
  match fuel side:
    case 0n False{}: {==}
    case 0n True{}: {==}
    case 1n+rest False{}: {==}
    case 1n+rest True{}: {==}

def L.bucket_exhausted(sample,mask,zero,one,key,event,side):
  {==}

def L.path_insert_missing(index):
  {==}

def L.path_insert_present(index,event):
  {==}

def L.path_candidate_yes(actor,context,index):
  {==}

def L.path_candidate_no(actor,context,index):
  {==}

def L.path_candidate_kind(key,kind,generation,x,y,age,hp,owner,context,index):
  {==}

def L.path_rows_empty(context,index):
  {==}

def L.path_rows_cons(head,tail,context,index):
  {==}

def L.path_prepared_exact(shots,targets,events,paths,rows,base,next):
  {==}

def L.path_lookup_exact(base,next,tick,fraction,oldIndex,newIndex,shots,targets,events,paths,key):
  {==}

def L.selected_shot_contact(context,actor):
  {==}

def L.selected_target_contact(context,actor):
  {==}

def L.target_trajectory_exact(actor,path,time,base):
  {==}

def L.dead_endpoint_missing(old,event,base):
  {==}

def L.dead_endpoint_shared(old,path,event,base):
  {==}

def L.dying_endpoint_lookup(base,next,tick,fraction,oldIndex,newIndex,prepared,old,event):
  {==}

def L.target_display_shared(base,next,tick,fraction,oldIndex,newIndex,prepared,actor,path):
  {==}

def L.shared_target_trajectory_at_contact(base,next,tick,fraction,oldIndex,newIndex,prepared,actor,path,event,at_contact):
  %at_contact : {C.target_trajectory(actor,path,C.cursor_offset(tick,base,fraction),base) == C.target_trajectory(actor,path,_,base) : C.Point}
  {==}
