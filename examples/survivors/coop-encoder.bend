import run-state.bend as RS
import Base
import game-components.bend as Components
import game.bend as G
import game-encoder.bend as GameEncoder
import coop-core.bend as Core
import coop-combat-prediction.bend as CombatPrediction
import coop-combat-encoder.bend as CombatEncoder
import coop-hit-journal.bend as Journal

def player_json(player: Components.PlayerRecord) -> String:
  match player:
    case Components.PlayerRecord{+id,+run,connected}: "{\"id\":" ++ U32.show(id) ++ ",\"px\":" ++ F32.show(RS.player_px(run)) ++ ",\"py\":" ++ F32.show(RS.player_py(run)) ++ ",\"hp\":" ++ U32.show(RS.player_hp(run)) ++ ",\"maxHp\":" ++ U32.show(RS.player_maxHp(run)) ++ ",\"character\":" ++ U32.show(RS.player_character(run)) ++ ",\"connected\":" ++ Bool.pick(String,connected,"true","false") ++ ",\"alive\":" ++ Bool.pick(String,U32.is_lt(0,RS.player_hp(run)),"true","false") ++ "}"
def players_json(players: List<&2,Components.PlayerRecord>) -> String:
  match players:
    case []: ""
    case player <> []: player_json(player)
    case player <> rest: player_json(player) ++ "," ++ players_json(rest)
def view_extra(+predictionAllowed: Bool,stepDistance: F32,ownPlayerId: U32,choicePending: Bool,round: U32,required: List<&2,U32>,players: List<&2,Components.PlayerRecord>,forecast: CombatPrediction.Scene) -> String:
  ",\"predictionAllowed\":" ++ Bool.pick(String,predictionAllowed,"true","false") ++ ",\"stepDistance\":" ++ F32.show(stepDistance) ++ ",\"coop\":true,\"ownPlayerId\":" ++ U32.show(ownPlayerId) ++ ",\"choicePending\":" ++ Bool.pick(String,choicePending,"true","false") ++ ",\"roundId\":" ++ U32.show(round) ++ ",\"requiredPlayers\":[" ++ GameEncoder.nums_json(required) ++ "],\"players\":[" ++ players_json(players) ++ "],\"combatForecast\":" ++ CombatEncoder.native_scene(forecast)
def encode_step(tick: U32,phase: U32,advanced: Bool,contacts: List<&2,Journal.HitEvent>,omitted: U32) -> String:
  match advanced:
    case False{}: "{\"tick\":" ++ U32.show(tick) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"advanced\":false}"
    case True{}: "{\"tick\":" ++ U32.show(tick) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"advanced\":true,\"contactsOmitted\":" ++ U32.show(omitted) ++ ",\"contacts\":" ++ Journal.native_events(contacts) ++ "}"
def encode(observation: Core.Observation) -> Maybe<&2,String>:
  match observation:
    case Core.NoObservation{}: None{}
    case Core.ViewObservation{game,allowed,distance,id,pending,round,required,players,forecast}: Some{GameEncoder.encode_extra(game,view_extra(allowed,distance,id,pending,round,required,players,forecast))}
    case Core.StepObservation{tick,phase,advanced,contacts,omitted}: Some{encode_step(tick,phase,advanced,contacts,omitted)}
