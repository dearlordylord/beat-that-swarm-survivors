import Base
import ./artwork.bend as Art
import ./validation.bend as Validation

def panel(id: Nat, frame: Nat, x: Nat, y: Nat, key: String) -> String:
  "<g id=\"" ++ key ++ "\" transform=\"translate(" ++ Nat.show(x) ++ " " ++ Nat.show(y) ++ ")\">" ++ Art.figure(id, frame) ++ "</g>"

def catalog() -> String:
  panel(0n, 0n, 0n, 0n, "character-01") ++ panel(1n, 0n, 64n, 0n, "character-02") ++ panel(2n, 0n, 128n, 0n, "character-03") ++ panel(3n, 0n, 192n, 0n, "character-04") ++ panel(4n, 0n, 256n, 0n, "character-05") ++ panel(5n, 0n, 320n, 0n, "character-06") ++ panel(6n, 0n, 384n, 0n, "character-07")

def walk() -> String:
  panel(2n, 0n, 0n, 80n, "walk-00") ++ panel(2n, 1n, 64n, 80n, "walk-01") ++ panel(2n, 2n, 128n, 80n, "walk-02") ++ panel(2n, 3n, 192n, 80n, "walk-03") ++ panel(2n, 4n, 256n, 80n, "walk-04") ++ panel(2n, 5n, 320n, 80n, "walk-05") ++ panel(2n, 6n, 384n, 80n, "walk-06") ++ panel(2n, 7n, 448n, 80n, "walk-07")

def emit(valid: Bool) -> IO(Unit):
  match valid:
    case False{}: IO.die(Unit, 1, "Sprite geometry invalid; no SVG emitted.")
    case True{}: IO.print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 512 160\">" ++ catalog() ++ walk() ++ "</svg>")


def main() -> IO(Unit):
  emit(Validation.valid())
