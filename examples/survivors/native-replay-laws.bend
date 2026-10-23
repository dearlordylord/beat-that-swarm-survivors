import Base
import native-replay-format.bend as F

law exact_float_bit_roundtrip:
  for bits: U32
  {F.float_bits(F.from_bits(bits)) == bits : U32}
