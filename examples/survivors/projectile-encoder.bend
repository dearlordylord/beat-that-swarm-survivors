import Base
import projectile-state.bend as Shot
import enemy-spatial.bend as Space
import game-components.bend as Components
import coop-playback-wire-policy.bend as Playback

# Encoders consume immutable projectile observations. Rules never import this
# module, and no health/XP interpretation or legacy array format exists here.
def hostile(side: Shot.Side) -> Bool:
  match side:
    case Shot.PlayerShot{}: False{}
    case Shot.HostileShot{}: True{}
def kind(side: Shot.Side) -> U32:
  match side:
    case Shot.PlayerShot{}: 1
    case Shot.HostileShot{}: 7
def active(state: Shot.State) -> Bool:
  match state:
    case Shot.State{_,_,_,Components.ShotPayload{_,_,active},_}: active
def native_nums(rows: List<&2,U32>) -> String:
  match rows:
    case []: "{\"$\":\"Nil\"}"
    case head <> tail: "{\"$\":\"Con\",\"head\":" ++ U32.show(head) ++ ",\"tail\":" ++ native_nums(tail) ++ "}"
def native_side(side: Shot.Side) -> String:
  match side:
    case Shot.PlayerShot{}: "{\"$\":\"PlayerShot\"}"
    case Shot.HostileShot{}: "{\"$\":\"HostileShot\"}"
def native_source(value: Maybe<&2,U32>) -> String:
  match value:
    case None{}: "{\"$\":\"None\"}"
    case Some{player}: "{\"$\":\"Some\",\"value\":" ++ U32.show(player) ++ "}"
def visual_source(value: Maybe<&2,U32>) -> String:
  match value:
    case None{}: "null"
    case Some{player}: U32.show(player)
def native_state(state: Shot.State) -> String:
  match state:
    case Shot.State{Space.Spatial{x,y,age,radius},identity,side,Components.ShotPayload{weapon,damage,active},Components.Trajectory{vx,vy,life,pierce,visited,owner,slot,+sourcePlayer}}:
      "{\"$\":\"State\",\"spatial\":{\"$\":\"Spatial\",\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"age\":" ++ U32.show(age) ++ ",\"radius\":" ++ F32.show(radius) ++ "},\"identity\":" ++ U32.show(identity) ++ ",\"side\":" ++ native_side(side) ++ ",\"payload\":{\"$\":\"ShotPayload\",\"weapon\":" ++ U32.show(weapon) ++ ",\"damage\":" ++ U32.show(damage) ++ ",\"active\":" ++ Bool.pick(String,active,"true","false") ++ "},\"trajectory\":{\"$\":\"Trajectory\",\"vx\":" ++ F32.show(vx) ++ ",\"vy\":" ++ F32.show(vy) ++ ",\"life\":" ++ U32.show(life) ++ ",\"pierce\":" ++ U32.show(pierce) ++ ",\"visited\":" ++ native_nums(visited) ++ ",\"weaponOwner\":" ++ U32.show(owner) ++ ",\"logicalSlot\":" ++ U32.show(slot) ++ ",\"sourcePlayer\":" ++ native_source(sourcePlayer) ++ "}}"
def visual(+tick: U32,+born: U32,state: Shot.State) -> String:
  match state:
    case Shot.State{Space.Spatial{x,y,age,radius},+identity,+side,Components.ShotPayload{weapon,damage,_},Components.Trajectory{vx,vy,life,pierce,_,+owner,+slot,+sourcePlayer}}:
      "{\"identity\":" ++ U32.show(identity) ++ ",\"hostile\":" ++ Bool.pick(String,hostile(side),"true","false") ++ ",\"weapon\":" ++ U32.show(weapon) ++ ",\"damage\":" ++ U32.show(damage) ++ ",\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"age\":" ++ U32.show(age) ++ ",\"radius\":" ++ F32.show(radius) ++ ",\"vx\":" ++ F32.show(vx) ++ ",\"vy\":" ++ F32.show(vy) ++ ",\"life\":" ++ U32.show(life) ++ ",\"pierce\":" ++ U32.show(pierce) ++ ",\"sourcePlayer\":" ++ visual_source(sourcePlayer) ++ ",\"weaponOwner\":" ++ U32.show(owner) ++ ",\"logicalSlot\":" ++ U32.show(slot) ++ ",\"birthTick\":" ++ U32.show(born) ++ ",\"lifetime\":\"" ++ Playback.generation(kind(side),identity,born,owner,slot,sourcePlayer) ++ "\",\"tick\":" ++ U32.show(tick) ++ "}"
