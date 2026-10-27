import Base
import ./accessories.bend as A

def pair(+id: Nat, +x: Nat) -> String:
  A.placed(id, 0n, x, 0n) ++ A.placed(id, 1n, x, 18n)

def main() -> IO(Unit):
  IO.print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 110 32\" shape-rendering=\"crispEdges\">" ++ pair(0n, 1n) ++ pair(1n, 17n) ++ pair(2n, 33n) ++ pair(3n, 49n) ++ pair(4n, 65n) ++ pair(5n, 81n) ++ pair(6n, 97n) ++ "</svg>")
