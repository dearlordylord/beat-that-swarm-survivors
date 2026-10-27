import Base
import ./accessories.bend as A
import ./accessories-native.bend as Native
import ./theme-artwork.bend as Theme

def body(id: Nat) -> String: Theme.body(id)

def figure(+id: Nat, variant: Nat) -> String:
  body(id) ++ "<g transform=\"translate(40 44) scale(2)\">" ++ A.icon(id, variant) ++ "</g>"

def large(+id: Nat) -> String:
  body(id) ++ "<g transform=\"translate(34 38) scale(2.5)\">" ++ A.icon(id, 1n) ++ "</g>"
def native_figure(+id: Nat) -> String:
  body(id) ++ "<g transform=\"translate(32 38) scale(2)\">" ++ Native.icon(id) ++ "</g>"
def choose_figure(+id: Nat, variant: Nat) -> String:
  match variant:
    case 3n: native_figure(id)
    case 2n: large(id)
    case _: figure(id, variant)
def panel(+id: Nat, +variant: Nat, x: Nat, y: Nat) -> String:
  "<g id=\"study-" ++ Nat.show(id) ++ "-" ++ Nat.show(variant) ++ "\" transform=\"translate(" ++ Nat.show(x) ++ " " ++ Nat.show(y) ++ ")\">" ++ choose_figure(id, variant) ++ "</g>"
def row(+variant: Nat, +y: Nat) -> String:
  panel(0n, variant, 0n, y) ++ panel(1n, variant, 64n, y) ++ panel(2n, variant, 128n, y) ++ panel(3n, variant, 192n, y) ++ panel(4n, variant, 256n, y) ++ panel(5n, variant, 320n, y) ++ panel(6n, variant, 384n, y)
def main() -> IO(Unit):
  IO.print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 448 320\">" ++ row(0n,0n) ++ row(1n,80n) ++ row(2n,160n) ++ row(3n,240n) ++ "</svg>")
