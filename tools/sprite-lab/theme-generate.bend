import Base
import ./theme-artwork.bend as Art
import ./validation.bend as Validation

def panel(+id: Nat, x: Nat) -> String:
  "<g id=\"character-" ++ Nat.show(id) ++ "\" transform=\"translate(" ++ Nat.show(x) ++ " 0)\">" ++ Art.figure(id) ++ "</g>"

def emit(valid: Bool) -> IO(Unit):
  match valid:
    case False{}: IO.die(Unit, 1, "Sprite geometry invalid; no SVG emitted.")
    case True{}: IO.print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 448 80\">" ++ panel(0n, 0n) ++ panel(1n, 64n) ++ panel(2n, 128n) ++ panel(3n, 192n) ++ panel(4n, 256n) ++ panel(5n, 320n) ++ panel(6n, 384n) ++ "</svg>")

def main() -> IO(Unit):
  emit(Validation.valid())
