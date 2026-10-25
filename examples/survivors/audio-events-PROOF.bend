import Base
import ./audio-events.bend as S
import ./body-index.bend as BI
import ./audio-events-LAWS.bend as L

def L.birth_exact(tick,age):
  {==}

def L.generation_exact(a,b,at,bt):
  {==}

def L.attack_exact(kind):
  {==}

def L.attack_kind_exact(kind):
  {==}

def L.pan_exact(x,viewer):
  {==}

def L.sound_added_exact(kind,x,viewer,tail):
  {==}

def L.sound_refused_exact(kind,x,viewer,tail):
  {==}

def L.new_shot(seed,variant,age,hp,x,radius,generation,born,viewer,confirmed):
  {==}

def L.new_area(seed,variant,age,hp,x,radius,generation,born,viewer,confirmed):
  {==}

def L.new_hostile(seed,variant,age,hp,x,radius,generation,born,viewer,confirmed):
  {==}

def L.new_enemy_is_not_a_shot(seed,x,viewer,confirmed):
  {==}

def L.body_changes_exact(matching,oldHp,oldRadius,kind,hp,x,radius,viewer,confirmed,events):
  {==}

def L.baseline_discards_history(meta,bodies,events):
  match meta:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.initial_observation_baselines(old,bodies,impact,current,rows):
  match old current:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,_} S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.same_tick_keeps_body_history(old,current,bodies,impact,rows):
  match current:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.stale_frame_is_silent(state,old,current,bodies,impact,rows):
  {==}

def L.new_run_baselines(state,current,rows):
  match state current:
    case S.State{_,_,_,_} S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.setup_is_silent(old,current,bodies,impact,rows):
  {==}

def L.impact_admission_exact(tick,after,now):
  {==}

def L.rejected_impact_preserves(head,tail):
  match head tail:
    case S.Impact{_,_} None{}: {==}
    case S.Impact{_,_} Some{_}: {==}

def L.latest_impact_empty(after,now,best):
  {==}

def L.latest_impact_step(head,tail,after,now,best):
  {==}

def L.no_impact_is_silent(state):
  match state:
    case S.State{_,_,_,_}: {==}

def L.impact_commit_exact(ready,meta,bodies,previous,tick,x):
  {==}

def L.public_impacts_exact(meta,bodies,after,rows):
  {==}

def L.unattached_impacts_are_silent(meta,bodies,after,rows):
  {==}

def L.known_row_dispatch(old,current,viewer,confirmed,events):
  match old current:
    case S.Stamp{_,_} S.Stamp{_,_}: {==}

def L.scan_empty(previous,tick,viewer,confirmed,index,events):
  {==}

def L.scan_step(head,tail,previous,tick,viewer,confirmed,index,events):
  match head:
    case S.Body{_,_,_,_,_,_,_,_}: {==}

def L.baseline_public_exact(meta,rows):
  match meta:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.observed_public_exact(old,current,impact,bodies,events):
  {==}

def L.newer_frame_scans(old,current,bodies,impact,rows):
  match current:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.configuration_dispatch(old,current,bodies,impact,rows):
  match old current:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,_} S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.time_dispatch(state,old,current,bodies,impact,rows):
  match old current:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,_} S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.existing_run_dispatch(ready,old,current,bodies,impact,rows):
  match old current:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,_} S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.public_ready_dispatch(old,current,bodies,impact,rows):
  match old current:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,_} S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.impact_row_dispatch(at,x,after,now,best):
  {==}

def L.impact_latest_entry(rows,after,now):
  {==}

def L.impact_first_candidate(head):
  match head:
    case S.Impact{_,_}: {==}

def L.impact_newest_candidate(at,x,other,otherX):
  {==}

def L.name_shot():
  {==}

def L.name_impact():
  {==}

def L.name_hit():
  {==}

def L.name_kill():
  {==}

def L.name_heal():
  {==}

def L.name_pickup():
  {==}

def L.name_hostile():
  {==}

def L.name_cast():
  {==}

def L.name_explosion():
  {==}

def L.name_level():
  {==}

def L.name_chest():
  {==}

def L.name_gameover():
  {==}

def L.name_victory():
  {==}

def L.same_identity_exact(a,b):
  match a b:
    case S.Stamp{S.Body{_,_,_,_,_,_,_,_},_} S.Stamp{S.Body{_,_,_,_,_,_,_,_},_}: {==}

def L.metadata_sounds_exact(old,current,events):
  match old current:
    case S.Meta{_,_,_,_,_,_,_,_,_,_,_} S.Meta{_,_,_,_,_,_,_,_,_,_,_}: {==}

def L.stamp_exact(seed,kind,variant,age,hp,x,radius,generation,tick): {==}
