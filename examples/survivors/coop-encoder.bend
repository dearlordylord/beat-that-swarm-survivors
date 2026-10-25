import run-state.bend as RS
import Base
import player-presentation.bend as Players
import game-components.bend as Components
import game.bend as G
import game-encoder.bend as GameEncoder
import coop-core.bend as Core
import coop-combat-prediction.bend as CombatPrediction
import coop-combat-encoder.bend as CombatEncoder
import coop-hit-journal.bend as Journal

def view_extra(+predictionAllowed: Bool,stepDistance: F32,ownPlayerId: U32,choicePending: Bool,round: U32,required: List<&2,U32>,forecast: CombatPrediction.Scene) -> String:
  ",\"predictionAllowed\":" ++ Bool.pick(String,predictionAllowed,"true","false") ++ ",\"stepDistance\":" ++ F32.show(stepDistance) ++ ",\"coop\":true,\"ownPlayerId\":" ++ U32.show(ownPlayerId) ++ ",\"choicePending\":" ++ Bool.pick(String,choicePending,"true","false") ++ ",\"roundId\":" ++ U32.show(round) ++ ",\"requiredPlayers\":[" ++ GameEncoder.nums_json(required) ++ "],\"combatForecast\":" ++ CombatEncoder.native_scene(forecast)
def encode_step(tick: U32,phase: U32,advanced: Bool,contacts: List<&2,Journal.HitEvent>,omitted: U32) -> String:
  match advanced:
    case False{}: "{\"tick\":" ++ U32.show(tick) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"advanced\":false}"
    case True{}: "{\"tick\":" ++ U32.show(tick) ++ ",\"phase\":" ++ U32.show(phase) ++ ",\"advanced\":true,\"contactsOmitted\":" ++ U32.show(omitted) ++ ",\"contacts\":" ++ Journal.native_events(contacts) ++ "}"
def encode(observation: Core.Observation) -> Maybe<&2,String>:
  match observation:
    case Core.NoObservation{}: None{}
    case Core.ViewObservation{game,allowed,distance,id,pending,round,required,players,forecast}: Some{GameEncoder.encode_extra(game,Players.from_records(players),view_extra(allowed,distance,id,pending,round,required,forecast))}
    case Core.StepObservation{tick,phase,advanced,contacts,omitted}: Some{encode_step(tick,phase,advanced,contacts,omitted)}
