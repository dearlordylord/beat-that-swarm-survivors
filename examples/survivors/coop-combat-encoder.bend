import Base
import game.bend as G
import coop-combat-prediction.bend as Prediction
import coop-combat-codec.bend as W
import coop-session.bend as Session
import coop-combat-prediction-policy.bend as Policy
import coop-playback-wire-policy.bend as PlaybackProjection
import body-index.bend as BI

# Wire snapshots preserve contact visitation and enemy statuses. Omitting either
# would let a new anchor repeat an already consumed contact or erase slow/burn.
def native_motion(value:G.Motion) -> String:
  match value:
    case G.Motion{vx,vy,life,pierce,visited,slow,burn,owner,slot}: "{\"$\":\"Motion\",\"vx\":" ++ F32.show(vx) ++ ",\"vy\":" ++ F32.show(vy) ++ ",\"life\":" ++ U32.show(life) ++ ",\"pierce\":" ++ U32.show(pierce) ++ ",\"visited\":" ++ W.native_nums(visited) ++ ",\"slow\":" ++ U32.show(slow) ++ ",\"burn\":" ++ U32.show(burn) ++ ",\"ownerBase\":" ++ U32.show(owner) ++ ",\"logicalSlot\":" ++ U32.show(slot) ++ "}"
def native_snapshot(value:G.Snapshot) -> String:
  match value:
    case G.Snapshot{body,motion}: "{\"$\":\"Snapshot\",\"body\":" ++ W.native_body(body) ++ ",\"motion\":" ++ native_motion(motion) ++ "}"
def native_snapshots(rows:List<&2,G.Snapshot>) -> String:
  match rows:
    case []: "{\"$\":\"Nil\"}"
    case head <> tail: "{\"$\":\"Con\",\"head\":" ++ native_snapshot(head) ++ ",\"tail\":" ++ native_snapshots(tail) ++ "}"
def native_player(value:G.PlayerRecord) -> String:
  match value:
    case G.PlayerRecord{id,run,connected}: "{\"$\":\"PlayerRecord\",\"id\":" ++ U32.show(id) ++ ",\"run\":" ++ W.native_run(run) ++ ",\"connected\":" ++ Bool.pick(String,connected,"true","false") ++ "}"
def native_players(rows:List<&2,G.PlayerRecord>) -> String:
  match rows:
    case []: "{\"$\":\"Nil\"}"
    case head <> tail: "{\"$\":\"Con\",\"head\":" ++ native_player(head) ++ ",\"tail\":" ++ native_players(tail) ++ "}"
def native_directions(value:Session.Directions) -> String:
  match value:
    case Session.Directions{x0,y0,x1,y1}: "{\"$\":\"Directions\",\"x0\":" ++ F32.show(x0) ++ ",\"y0\":" ++ F32.show(y0) ++ ",\"x1\":" ++ F32.show(x1) ++ ",\"y1\":" ++ F32.show(y1) ++ "}"

def witness_fields(value:Policy.Witness) -> String:
  match value:
    case Policy.Witness{kind,tick,shot,target,shotBirth,targetBirth,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,time}: "\"kind\":" ++ U32.show(kind) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"shot\":" ++ U32.show(shot) ++ ",\"target\":" ++ U32.show(target) ++ ",\"shotBirth\":" ++ U32.show(shotBirth) ++ ",\"targetBirth\":" ++ U32.show(targetBirth) ++ ",\"x0\":" ++ F32.show(x0) ++ ",\"y0\":" ++ F32.show(y0) ++ ",\"x1\":" ++ F32.show(x1) ++ ",\"y1\":" ++ F32.show(y1) ++ ",\"ex0\":" ++ F32.show(ex0) ++ ",\"ey0\":" ++ F32.show(ey0) ++ ",\"ex1\":" ++ F32.show(ex1) ++ ",\"ey1\":" ++ F32.show(ey1) ++ ",\"radius\":" ++ F32.show(radius) ++ ",\"time\":" ++ F32.show(time)
def native_witness(value:Policy.Witness) -> String: "{\"$\":\"Witness\"," ++ witness_fields(value) ++ "}"
def native_contacts(rows:List<&2,Policy.Witness>) -> String:
  match rows:
    case []: "{\"$\":\"Nil\"}"
    case head <> tail: "{\"$\":\"Con\",\"head\":" ++ native_witness(head) ++ ",\"tail\":" ++ native_contacts(tail) ++ "}"
def native_scene(scene:Prediction.Scene) -> String:
  match scene:
    case Prediction.Scene{own,players,snapshots,births,directions,contacts,tick,diagnostics}: "{\"$\":\"Scene\",\"own\":" ++ U32.show(own) ++ ",\"players\":" ++ native_players(players) ++ ",\"snapshots\":" ++ native_snapshots(snapshots) ++ ",\"births\":" ++ W.native_births(births) ++ ",\"directions\":" ++ native_directions(directions) ++ ",\"contacts\":" ++ native_contacts(contacts) ++ ",\"tick\":" ++ U32.show(tick) ++ ",\"diagnostics\":" ++ Bool.pick(String,diagnostics,"true","false") ++ "}"
def observe(own:U32,players:List<&2,G.PlayerRecord>,snapshots:List<&2,G.Snapshot>) -> String: native_scene(Prediction.initialize(own,players,snapshots))
def generation(kind:U32,seed:U32,born:U32,owner:U32,slot:U32) -> String:
  PlaybackProjection.generation(kind,seed,born,owner,slot)
def visual_owner(kind:U32,slot:U32) -> U32: PlaybackProjection.visual_owner(kind,slot)
def visual_body(+tick:U32,born:U32,body:G.Body,motion:G.Motion) -> String:
  match body motion:
    case G.Body{x,y,+kind,variant,hp,maximum,age,+seed,radius} G.Motion{_,_,_,_,_,_,_,owner,+slot}: "[" ++ F32.show(x) ++ "," ++ F32.show(y) ++ "," ++ U32.show(kind) ++ "," ++ U32.show(variant) ++ "," ++ U32.show(hp) ++ "," ++ U32.show(maximum) ++ "," ++ U32.show(age) ++ "," ++ U32.show(seed) ++ "," ++ F32.show(radius) ++ ",\"" ++ generation(kind,seed,born,owner,slot) ++ "\"," ++ U32.show(visual_owner(kind,slot)) ++ "," ++ U32.show(tick) ++ "]"
def visual_snapshot(tick:U32,born:U32,snapshot:G.Snapshot) -> String:
  match snapshot:
    case G.Snapshot{body,motion}: visual_body(tick,born,body,motion)
def visual_row(+tick:U32,births:BI.Index<U32>,+snapshot:G.Snapshot) -> String: visual_snapshot(tick,W.birth_at(births,tick,snapshot),snapshot)
def visual_rows(rows:List<&2,G.Snapshot>,+tick:U32,+births:BI.Index<U32>) -> String:
  match rows:
    case []: ""
    case head <> []: visual_row(tick,births,head)
    case head <> tail: visual_row(tick,births,head) ++ "," ++ visual_rows(tail,tick,births)
def visual_player(value:G.PlayerRecord) -> String:
  match value:
    case G.PlayerRecord{id,+run,+connected}: "{\"id\":" ++ U32.show(id) ++ ",\"px\":" ++ F32.show(G.run_px(run)) ++ ",\"py\":" ++ F32.show(G.run_py(run)) ++ ",\"hp\":" ++ U32.show(G.run_hp(run)) ++ ",\"maxHp\":" ++ U32.show(G.run_maxHp(run)) ++ ",\"character\":" ++ U32.show(G.run_character(run)) ++ ",\"connected\":" ++ Bool.pick(String,connected,"true","false") ++ ",\"alive\":" ++ Bool.pick(String,Bool.and(connected,U32.is_gt(G.run_hp(run),0)),"true","false") ++ "}"
def visual_players(rows:List<&2,G.PlayerRecord>) -> String:
  match rows:
    case []: ""
    case head <> []: visual_player(head)
    case head <> tail: visual_player(head) ++ "," ++ visual_players(tail)
def point_fields(run:Maybe<&2,G.Run>) -> String:
  match run:
    case None{}: ",\"px\":0,\"py\":0"
    case Some{+run}: ",\"px\":" ++ F32.show(G.run_px(run)) ++ ",\"py\":" ++ F32.show(G.run_py(run))
def contact_kind(value:Policy.Witness) -> String:
  match value:
    case Policy.Witness{kind,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: Bool.pick(String,U32.is_eq(kind,0),"sweep","point")
def visual_witness_fields(value:Policy.Witness) -> String:
  match value:
    case Policy.Witness{_,tick,shot,target,shotBirth,targetBirth,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,time}: "\"tick\":" ++ U32.show(tick) ++ ",\"shot\":" ++ U32.show(shot) ++ ",\"target\":" ++ U32.show(target) ++ ",\"shotBirth\":" ++ U32.show(shotBirth) ++ ",\"targetBirth\":" ++ U32.show(targetBirth) ++ ",\"x0\":" ++ F32.show(x0) ++ ",\"y0\":" ++ F32.show(y0) ++ ",\"x1\":" ++ F32.show(x1) ++ ",\"y1\":" ++ F32.show(y1) ++ ",\"ex0\":" ++ F32.show(ex0) ++ ",\"ey0\":" ++ F32.show(ey0) ++ ",\"ex1\":" ++ F32.show(ex1) ++ ",\"ey1\":" ++ F32.show(ey1) ++ ",\"radius\":" ++ F32.show(radius) ++ ",\"time\":" ++ F32.show(time)
def visual_contact(+value:Policy.Witness) -> String: "{\"kind\":\"" ++ contact_kind(value) ++ "\"," ++ visual_witness_fields(value) ++ "}"
def visual_contacts(rows:List<&2,Policy.Witness>) -> String:
  match rows:
    case []: ""
    case head <> []: visual_contact(head)
    case head <> tail: visual_contact(head) ++ "," ++ visual_contacts(tail)
def render(scene:Prediction.Scene) -> String:
  match scene:
    case Prediction.Scene{+own,+players,snapshots,births,_,contacts,+tick,diagnostics}: "{\"bodies\":[" ++ visual_rows(snapshots,tick,births) ++ "],\"players\":[" ++ visual_players(players) ++ "],\"tick\":" ++ U32.show(tick) ++ ",\"cohortTick\":" ++ U32.show(tick) ++ ",\"ownPlayerId\":" ++ U32.show(own) ++ point_fields(Prediction.find_run(players,own)) ++ ",\"predictedCohort\":true,\"diagnosticsEnabled\":" ++ Bool.pick(String,diagnostics,"true","false") ++ ",\"contacts\":[" ++ visual_contacts(contacts) ++ "],\"contactTtlTicks\":" ++ U32.show(Policy.ttl_ticks()) ++ ",\"assumptions\":{\"remoteMovement\":\"bounded-held-last-observed\",\"remoteFutureBirths\":true,\"remoteFireAssumption\":\"current-loadout-and-held-input\",\"newEnemyBirths\":false,\"playerDamage\":false,\"durableAwards\":false}}"
