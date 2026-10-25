import Base
import ./coop-hit-effects-LAWS.bend as L

def L.limits_exact(): ({==},{==})
def L.fresh_exact(): {==}
def L.attach_exact(journal): {==}
def L.receive_current(state,journal): {==}
def L.receive_changed(state,journal): {==}
def L.receive_entry(state,journal): {==}
def L.epoch_exact(attached,epoch,seen,effects,dropped,other,now,events,overflow,expired): {==}
def L.recent_exact(started,tick): {==}
def L.visible_exact(event,started,tick): {==}
def L.key_exact(event,started): {==}
def L.retained_true(effect,rows): {==}
def L.retained_false(effect,rows): {==}
def L.retain_nil(tick,acc): {==}
def L.retain_cons(head,tail,tick,acc): {==}
def L.contains_nil(id,found): {==}
def L.contains_cons(head,tail,id,found): {==}
def L.contains_entry(rows,id): {==}
def L.eligible_exact(id,at,kind,shot,shotSeed,target,generation,fraction,x,y,tx,ty,radius,outcome,tick): {==}
def L.add_new(event,tick,rows): {==}
def L.add_duplicate(allowed,event,tick,rows):
  match allowed:
    case True{}: {==}
    case False{}: {==}
def L.add_ineligible(duplicate,event,tick,rows): {==}
def L.add_entry(event,tick,rows): {==}
def L.add_rows_nil(tick,effects): {==}
def L.add_rows_cons(head,tail,tick,effects): {==}
def L.bounded_exact(played,rows,dropped): {==}
def L.completed_exact(played,events,rows,tick,dropped): {==}
def L.advance_same_exact(attached,played,rows,dropped,journal,sample): {==}
def L.advance_changed(state,journal,sample): {==}
def L.advance_current(state,journal,sample): {==}
def L.advance_entry(state,journal,sample): {==}
def L.rendered_exact(id,at,kind,shot,shotSeed,target,generation,fraction,x,y,tx,ty,radius,outcome,started,tick,dx,dy): {==}
def L.render_effect_exact(event,started,tick,index): {==}
def L.render_hidden(effect,tick,index,acc): {==}
def L.render_visible(effect,tick,index,acc): {==}
def L.render_nil(tick,index,acc): {==}
def L.render_cons(head,tail,tick,index,acc): {==}
def L.render_entry(attached,played,rows,dropped,base,next,tick,fraction,alpha,players,bodies): {==}
