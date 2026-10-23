import Base
import native-replay-format.bend as F
import native-replay-laws.bend as L

def L.exact_float_bit_roundtrip(bits):
  match bits:
    case U32{word}: {==}
