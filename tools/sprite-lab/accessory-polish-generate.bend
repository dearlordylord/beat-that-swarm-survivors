import Base
import ./theme-artwork.bend as Theme
import ./accessory-polish-art.bend as Art

def pair(+id: Nat,+v: Nat) -> String:
  "<g>" ++ Art.icon(id,v) ++ "</g><g>" ++ Theme.body(id) ++ "<g transform=\"translate(32 38) scale(2)\">" ++ Art.icon(id,v) ++ "</g></g>"
def row(+v: Nat) -> String: pair(3n,v) ++ pair(0n,v) ++ pair(4n,v)
def main() -> IO(Unit):
  IO.print("<svg xmlns=\"http://www.w3.org/2000/svg\">" ++ row(0n) ++ row(1n) ++ row(2n) ++ "</svg>")
