import Base
import ./coop-playback-wire-policy.bend as W
import ./coop-playback-wire-policy-LAWS.bend as L
import ./coop-playback.bend as P
import ../../vendor/bendlib/packages/bend-mathlib/list.bend as F

def L.enemy_generation_exact(seed,born):
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

def L.enemy_projection_exact(identity,born,x,y,age,health):
  {==}

def L.projectile_projection_exact(hostile,seed,born,weapon,slot,sourcePlayer,x,y,age,life,pierce):
  {==}

def L.birth_lookup_exact(births,tick,age,seed):
  {==}

def L.join_preserves_order(first,second):
  %F.reverse_reverse(&2,P.Actor,first) : {W.join(first,second) == List.append(&2,P.Actor,_,second) : List<&2,P.Actor>}
  F.reverse_go_spec(&2,P.Actor,List.reverse(&2,P.Actor,first),second)

def L.frame_exact(observation,tick,receivedAt,players,bodies,extras):
  {==}

def L.xp_projection_exact(key,generation,x,y,age,radius,active,amount,accumulator):
  {==}

def L.gold_projection_exact(key,generation,x,y,age,radius,active,coins):
  {==}

def L.healing_projection_exact(key,generation,x,y,age,radius,active,health):
  {==}

def L.chest_projection_exact(key,generation,x,y,age,radius,active):
  {==}

def L.relic_projection_exact(key,generation,x,y,age,radius,active,stage):
  {==}
