import Base
import ./accessories-native.bend as A

def placed(id: Nat,x: Nat) -> String:
  "<g transform=\"translate(" ++ Nat.show(x) ++ " 0)\">" ++ A.icon(id) ++ "</g>"
def main() -> IO(Unit):
  IO.print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 126 18\">" ++ placed(0n,0n) ++ placed(1n,18n) ++ placed(2n,36n) ++ placed(3n,54n) ++ placed(4n,72n) ++ placed(5n,90n) ++ placed(6n,108n) ++ "</svg>")
