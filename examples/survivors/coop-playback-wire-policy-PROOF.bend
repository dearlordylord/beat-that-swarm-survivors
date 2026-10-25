import Base
import ./coop-playback-wire-policy.bend as W
import ./coop-playback-wire-policy-LAWS.bend as L
import ./coop-playback.bend as P
import ../../vendor/bendlib/packages/bend-mathlib/list.bend as F

def L.enemy_generation_exact(seed,born,weapon,slot):
  {==}

def L.projectile_generation_exact(seed,born,weapon,slot,sourcePlayer):
  {==}

def L.hostile_generation_exact(seed,born,weapon,slot):
  {==}

def L.visual_owner_exact(sourcePlayer):
  match sourcePlayer:
    case None{}: {==}
    case Some{_}: {==}

def L.player_projection_exact(id,character,x,y,hp,connected):
  {==}

def L.body_liveness_exact(kind,hp,life,pierce):
  {==}

def L.body_projection_exact(seed,kind,born,weapon,slot,sourcePlayer,x,y,age,hp,life,pierce):
  {==}

def L.birth_lookup_exact(births,tick,age,seed):
  {==}

def L.extra_rejected(key,kind,variant,x,y,age,hp,tick):
  {==}

def L.extra_kept(key,kind,variant,x,y,age,hp,tick):
  {==}

def L.extra_policy_exact(key,kind,variant,x,y,age,hp,tick):
  {==}

def L.join_preserves_order(first,second):
  %F.reverse_reverse(&2,P.Actor,first) : {W.join(first,second) == List.append(&2,P.Actor,_,second) : List<&2,P.Actor>}
  F.reverse_go_spec(&2,P.Actor,List.reverse(&2,P.Actor,first),second)

def L.frame_exact(observation,tick,receivedAt,players,bodies,extras):
  {==}
