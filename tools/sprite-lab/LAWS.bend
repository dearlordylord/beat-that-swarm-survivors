import Base
import ./model.bend as M

# Guarantees: Both full eyes read their width from one shared record.
# Why it matters: A face edit cannot accidentally resize just one eye.
law eye_widths_equal:
  for pair: M.EyePair
  {M.eye_width_left(pair) == M.eye_width_right(pair) : Nat}

# Guarantees: Both full eyes read their height from one shared record.
# Why it matters: The neutral face does not acquire uneven full eye heights.
law eye_heights_equal:
  for pair: M.EyePair
  {M.eye_height_left(pair) == M.eye_height_right(pair) : Nat}

# Guarantees: The adjoining limb segments refer to the same knee record.
# Why it matters: Coordinate drift cannot detach their mathematical endpoints.
law limb_joint_shared:
  for limb: M.Limb
  {M.left_end(limb) == M.right_start(limb) : M.Point}

# Guarantees: The constructor preserves the supplied eye width.
# Why it matters: Equal eyes must retain the authored size rather than collapse to zero.
law eyes_preserve_width:
  for left: M.Point
  for right: M.Point
  for width: Nat
  for height: Nat
  {M.eye_width_left(M.eyes(left, right, width, height)) == width : Nat}

# Guarantees: The constructor preserves the supplied eye height.
# Why it matters: Equal eyes must retain the authored height.
law eyes_preserve_height:
  for left: M.Point
  for right: M.Point
  for width: Nat
  for height: Nat
  {M.eye_height_right(M.eyes(left, right, width, height)) == height : Nat}

# Guarantees: The unit origin rectangle emits the expected literal SVG.
# Why it matters: The primitive has a checked serialization example; this is not a general serializer proof.
law origin_rect_serialization:
  {M.rect(0n, 0n, 1n, 1n, "#fff") == "<rect x=\"0\" y=\"0\" width=\"1\" height=\"1\" fill=\"#fff\"/>" : String}
