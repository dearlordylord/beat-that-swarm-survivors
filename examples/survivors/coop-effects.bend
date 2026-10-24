import Base
import game.bend as G
import body-index.bend as BI

# Test/public compatibility boundary. All effect decisions live in the shared
# Game implementation used by both solo and cooperative execution.
type Player is Data: Player{id: U32,run: G.Run}
def players(rows: List<&2,Player>) -> List<&2,G.effect_Player>:
  match rows:
    case []: []
    case Player{id,run} <> rest: G.effect_Player{id,run} <> players(rest)
def source(snapshots: List<&2,G.Snapshot>,shot: U32) -> U32: G.effect_source(snapshots,shot)
def origin_index(snapshots: List<&2,G.Snapshot>) -> BI.Index<U32>: G.effect_origin_index(snapshots)
def indexed_source(origins: BI.Index<U32>,shot: U32) -> U32: G.effect_indexed_source(origins,shot)
def burn_duration(burn: U32) -> U32: G.effect_burn_duration(burn)
def burn_source(burn: U32) -> U32: G.effect_burn_source(burn)
def pack_burn(duration: U32,id: U32) -> U32: G.effect_pack_burn(duration,id)
def cool_burn(burn: U32) -> U32: G.effect_cool_burn(burn)
def stronger_burn(old: U32,fresh: U32) -> U32: G.effect_stronger_burn(old,fresh)
def indexed_killer(hits: List<&2,G.HitPlan>,origins: BI.Index<U32>,x: F32,y: F32,radius: F32,target: U32,hp: U32,fallback: U32) -> U32:
  G.effect_indexed_killer(hits,origins,x,y,radius,target,hp,fallback)
def credited_killer(hits: List<&2,G.HitPlan>,snapshots: List<&2,G.Snapshot>,x: F32,y: F32,radius: F32,target: U32,hp: U32,fallback: U32) -> U32:
  G.effect_credited_killer(hits,snapshots,x,y,radius,target,hp,fallback)
def apply_indexed(rows: List<&2,Player>,oldX: F32,oldY: F32,row: G.Row,motion: G.Motion,hits: List<&2,G.HitPlan>,origins: BI.Index<U32>) -> G.EntityRow:
  G.effect_apply_indexed(players(rows),oldX,oldY,row,motion,hits,origins)
def apply(rows: List<&2,Player>,oldX: F32,oldY: F32,row: G.Row,motion: G.Motion,hits: List<&2,G.HitPlan>,snapshots: List<&2,G.Snapshot>) -> G.EntityRow:
  G.effect_apply(players(rows),oldX,oldY,row,motion,hits,snapshots)
