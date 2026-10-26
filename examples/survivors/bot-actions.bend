import Base
import game.bend as G
import native-economy.bend as P
import projectile.bend as Shots

def shot_radius(shot: Shots.Shot) -> F32:
  match shot:
    case Shots.Shot{_,_,_,_,radius,_,_}: radius

def self_field_radius(enabled: Bool,id: U32,rank: U32,speed: F32,area: F32,duration: F32) -> F32:
  match enabled:
    case False{}: 0.0
    case True{}: shot_radius(Shots.spawn(id,rank,0,0.0,0.0,0.0,0.0,1.0,0.0,speed,area,duration))

def start_unlocks(packet: G.Packet,mask: U32) -> G.Packet:
  match packet:
    case G.Packet{state}: G.configure_unlocks(state,mask)
    case G.Failed{error}: G.Failed{error}
def start_mode(packet: G.Packet,mode: U32) -> G.Packet:
  match packet:
    case G.Packet{state}: G.set_mode(state,mode)
    case G.Failed{error}: G.Failed{error}
def start_configured(packet: G.Packet,stage: U32,arcana: U32) -> G.Packet:
  match packet:
    case G.Packet{state}: G.configure(state,stage,arcana)
    case G.Failed{error}: G.Failed{error}
# Same fresh profile, stage and mode as the native UI. No profile injection.
def fresh_start_seed(seed: U32) -> G.Packet:
  start_unlocks(start_mode(start_configured(G.start_seed(0,P.meta(P.fresh()),seed),0,0),0),P.weapon_mask(P.fresh()))

def fresh_start() -> G.Packet: fresh_start_seed(12345)
# Explicit qualification preset: advanced profile, Agatha, Living Tree Arcana.
def advanced_start_seed(seed: U32) -> G.Packet:
  start_mode(start_configured(G.start_seed(2,364304237,seed),0,9),0)

def advanced_start() -> G.Packet: advanced_start_seed(12345)
