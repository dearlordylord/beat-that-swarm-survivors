import Base
import enemy-effects.bend as Effect
import game-components.bend as Components

def boolean(value: Bool) -> String:
  match value:
    case True{}: "true"
    case False{}: "false"
def source(value: Maybe<&2,U32>) -> String:
  match value:
    case None{}: "null"
    case Some{player}: U32.show(player)
def slow(value: Effect.Slow) -> String:
  match value:
    case Effect.Slow{ticks,frozen}: "{\"ticks\":" ++ U32.show(ticks) ++ ",\"frozen\":" ++ boolean(frozen) ++ "}"
def burn(value: Effect.Burn) -> String:
  match value:
    case Effect.Burn{ticks,player}: "{\"ticks\":" ++ U32.show(ticks) ++ ",\"sourcePlayer\":" ++ source(player) ++ "}"
def encode(value: Components.Status) -> String:
  match value:
    case Components.Status{s,b}: "{\"slow\":" ++ slow(s) ++ ",\"burn\":" ++ burn(b) ++ "}"
def native_source(value: Maybe<&2,U32>) -> String:
  match value:
    case None{}: "{\"$\":\"None\"}"
    case Some{player}: "{\"$\":\"Some\",\"value\":" ++ U32.show(player) ++ "}"
def native(value: Components.Status) -> String:
  match value:
    case Components.Status{Effect.Slow{ticks,frozen},Effect.Burn{duration,player}}:
      "{\"$\":\"Status\",\"slow\":{\"$\":\"Slow\",\"ticks\":" ++ U32.show(ticks) ++ ",\"frozen\":" ++ boolean(frozen) ++ "},\"burn\":{\"$\":\"Burn\",\"ticks\":" ++ U32.show(duration) ++ ",\"sourcePlayer\":" ++ native_source(player) ++ "}}"
