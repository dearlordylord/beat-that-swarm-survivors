import Base

type Point is Data:
  Point{x: Nat, y: Nat}

type EyePair is Data:
  EyePair{left: Point, right: Point, width: Nat, height: Nat}

type Limb is Data:
  Limb{root: Point, knee: Point, tip: Point}

def point_x(p: Point) -> Nat:
  Point{x, y} = p
  x

def point_y(p: Point) -> Nat:
  Point{x, y} = p
  y

def eyes(left: Point, right: Point, width: Nat, height: Nat) -> EyePair:
  EyePair{left, right, width, height}

def eye_width_left(pair: EyePair) -> Nat:
  EyePair{left, right, width, height} = pair
  width

def eye_width_right(pair: EyePair) -> Nat:
  EyePair{left, right, width, height} = pair
  width

def eye_height_left(pair: EyePair) -> Nat:
  EyePair{left, right, width, height} = pair
  height

def eye_height_right(pair: EyePair) -> Nat:
  EyePair{left, right, width, height} = pair
  height

def left_end(limb: Limb) -> Point:
  Limb{root, knee, tip} = limb
  knee

def right_start(limb: Limb) -> Point:
  Limb{root, knee, tip} = limb
  knee

def point_svg(p: Point) -> String:
  Point{x, y} = p
  Nat.show(x) ++ "," ++ Nat.show(y)

def rect(x: Nat, y: Nat, w: Nat, h: Nat, color: String) -> String:
  "<rect x=\"" ++ Nat.show(x) ++ "\" y=\"" ++ Nat.show(y) ++ "\" width=\"" ++ Nat.show(w) ++ "\" height=\"" ++ Nat.show(h) ++ "\" fill=\"" ++ color ++ "\"/>"

def points_svg(points: List<&2, Point>) -> String:
  match points:
    case Nil{}:
      ""
    case Con{p, rest}:
      point_svg(p) ++ " " ++ points_svg(rest)

def polygon(points: List<&2, Point>, color: String) -> String:
  "<polygon points=\"" ++ points_svg(points) ++ "\" fill=\"" ++ color ++ "\"/>"

def line(a: Point, b: Point, width: Nat, color: String) -> String:
  "<polyline points=\"" ++ point_svg(a) ++ " " ++ point_svg(b) ++ "\" fill=\"none\" stroke=\"" ++ color ++ "\" stroke-width=\"" ++ Nat.show(width) ++ "\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>"

def eye_svg(pair: EyePair, +color: String) -> String:
  EyePair{Point{lx, ly}, Point{rx, ry}, +width, +height} = pair
  rect(lx, ly, width, height, color) ++ rect(rx, ry, width, height, color)

def limb_svg(limb: Limb, width: Nat, color: String) -> String:
  Limb{root, knee, tip} = limb
  "<polyline points=\"" ++ point_svg(root) ++ " " ++ point_svg(knee) ++ " " ++ point_svg(tip) ++ "\" fill=\"none\" stroke=\"" ++ color ++ "\" stroke-width=\"" ++ Nat.show(width) ++ "\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>"
