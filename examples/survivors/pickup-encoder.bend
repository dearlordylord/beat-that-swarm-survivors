import Base
import pickup-state.bend as Pickup
import enemy-spatial.bend as Space

# Current pickup wire data is named and typed. No health-shaped aliases or arrays.
def boolean(value: Bool) -> String:
  match value:
    case True{}: "true"
    case False{}: "false"
def item(value: Pickup.Item) -> String:
  match value:
    case Pickup.Xp{amount,accumulator}: "{\"kind\":\"xp\",\"amount\":" ++ U32.show(amount) ++ ",\"accumulator\":" ++ boolean(accumulator) ++ "}"
    case Pickup.Gold{coins}: "{\"kind\":\"gold\",\"coins\":" ++ U32.show(coins) ++ "}"
    case Pickup.Healing{health}: "{\"kind\":\"healing\",\"health\":" ++ U32.show(health) ++ "}"
    case Pickup.Chest{}: "{\"kind\":\"chest\"}"
    case Pickup.Relic{stage}: "{\"kind\":\"relic\",\"stage\":" ++ U32.show(stage) ++ "}"
def state(value: Pickup.State) -> String:
  match value:
    case Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{payload,generation,active},slot}:
      "{\"slot\":" ++ U32.show(slot) ++ ",\"generation\":" ++ U32.show(generation) ++ ",\"active\":" ++ boolean(active) ++ ",\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"age\":" ++ U32.show(age) ++ ",\"radius\":" ++ F32.show(radius) ++ ",\"item\":" ++ item(payload) ++ "}"
def rows(values: List<&2,Pickup.State>) -> String:
  match values:
    case []: ""
    case head <> []: state(head)
    case head <> tail: state(head) ++ "," ++ rows(tail)
def encode(values: List<&2,Pickup.State>) -> String: "[" ++ rows(values) ++ "]"

# Affine-native snapshots preserve the actual payload constructor and fields.
def native_item(value: Pickup.Item) -> String:
  match value:
    case Pickup.Xp{amount,accumulator}: "{\"$\":\"Xp\",\"amount\":" ++ U32.show(amount) ++ ",\"accumulator\":" ++ boolean(accumulator) ++ "}"
    case Pickup.Gold{coins}: "{\"$\":\"Gold\",\"coins\":" ++ U32.show(coins) ++ "}"
    case Pickup.Healing{health}: "{\"$\":\"Healing\",\"health\":" ++ U32.show(health) ++ "}"
    case Pickup.Chest{}: "{\"$\":\"Chest\"}"
    case Pickup.Relic{stage}: "{\"$\":\"Relic\",\"stage\":" ++ U32.show(stage) ++ "}"
def native_state(value: Pickup.State) -> String:
  match value:
    case Pickup.State{Space.Spatial{x,y,age,radius},Pickup.Payload{item,generation,active},identity}:
      "{\"$\":\"State\",\"spatial\":{\"$\":\"Spatial\",\"x\":" ++ F32.show(x) ++ ",\"y\":" ++ F32.show(y) ++ ",\"age\":" ++ U32.show(age) ++ ",\"radius\":" ++ F32.show(radius) ++ "},\"payload\":{\"$\":\"Payload\",\"item\":" ++ native_item(item) ++ ",\"generation\":" ++ U32.show(generation) ++ ",\"active\":" ++ boolean(active) ++ "},\"identity\":" ++ U32.show(identity) ++ "}"
