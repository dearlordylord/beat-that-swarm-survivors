import Base

def ink() -> String: "#101729"
def cream() -> String: "#fff0ce"
def shape(data: String, color: String) -> String:
  "<path d=\"" ++ data ++ "\" fill=\"" ++ color ++ "\" stroke=\"#101729\" stroke-width=\"2\" stroke-linejoin=\"round\"/>"
def line(data: String, color: String) -> String:
  "<path d=\"" ++ data ++ "\" fill=\"none\" stroke=\"" ++ color ++ "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>"
def solid(data: String, color: String) -> String:
  "<path d=\"" ++ data ++ "\" fill=\"" ++ color ++ "\"/>"

def weight() -> String:
  shape("M10 14H22V18H10Z","#eaca70") ++
  shape("M4 11H6V8H11V24H6V21H4Z","#eaca70") ++
  shape("M21 8H26V11H28V21H26V24H21Z","#eaca70") ++
  line("M8 10V22M24 10V22",cream())
def metronome() -> String:
  shape("M13 5H19L25 27H7Z","#d7a78e") ++
  shape("M13 9H19L21 23H11Z","#20333b") ++
  line("M16 23L21 10",cream()) ++ solid("M18 9H23V13H18Z","#f1bf55")
def lens() -> String:
  shape("M13 5C23 4 28 17 20 23C13 30 3 23 5 14C6 8 8 6 13 5Z","#8faadb") ++
  shape("M13 9C20 8 23 16 18 20C13 24 7 20 8 15C8 12 10 10 13 9Z","#29444b") ++
  line("M22 23L27 28",cream()) ++ line("M11 11L9 15",cream())
def spool() -> String:
  shape("M8 6H24V10H21V22H24V26H8V22H11V10H8Z","#c7bddf") ++
  line("M12 12H20M12 16H20M12 20H20",ink()) ++ line("M23 24Q28 26 26 28",cream())
def reed() -> String:
  shape("M8 5H12V14Q12 18 16 18Q20 18 20 14V5H24V14Q24 22 18 23V28H14V23Q8 22 8 14Z","#f0d990") ++
  line("M10 7V13M22 7V13",cream())
def soles() -> String:
  shape("M8 7H14L16 14L23 19H26Q28 19 28 22V25H5V20L8 17Z","#f1bf55") ++
  line("M6 22H26M12 12L16 11M13 16L18 14",cream())
def guard() -> String:
  shape("M16 4L27 8V17Q26 24 16 28Q6 24 5 17V8Z","#c7bddf") ++
  shape("M16 9L22 11V17Q21 21 16 23Q11 21 10 17V11Z","#29444b") ++
  line("M12 12L18 10",cream())
def locket() -> String:
  line("M10 6Q16 2 22 6L20 11M10 6L12 11","#eaca70") ++
  shape("M16 13C9 7 3 15 8 21L16 28L24 21C29 15 23 7 16 13Z","#ef7f83") ++
  line("M10 16Q9 18 11 20",cream())
def leaf() -> String:
  shape("M7 25C4 13 12 5 27 5C27 18 21 27 7 25Z","#b8d6a0") ++
  line("M6 27L23 10M13 20L12 15M18 15L23 15","#29444b")
def notebook() -> String:
  shape("M7 5H25V27H7Q4 26 5 23V8Q5 5 7 5Z","#8faadb") ++
  line("M10 7V25",ink()) ++
  line("M14 11H21M14 16H21M14 21H19",cream())
def die() -> String:
  shape("M10 5L27 10L23 27L5 22Z","#d7a78e") ++
  solid("M11 10H14V13H11ZM20 13H23V16H20ZM10 19H13V22H10ZM17 21H20V24H17Z",ink())
def thermos() -> String:
  shape("M11 5H21V9H11Z","#f0d990") ++
  shape("M10 9H22V26Q16 29 10 26Z","#f6ddba") ++
  line("M22 12H25Q28 12 27 17Q26 21 23 21","#f0d990") ++
  line("M11 12H21M13 23H19","#b58b50")
def feather() -> String:
  shape("M6 25L11 13L19 5L27 6L25 16L17 23Z","#eaca70") ++
  line("M5 28L23 9M13 20L12 15M18 15L22 15",ink()) ++
  line("M20 8L24 8",cream())
def wick() -> String:
  shape("M10 17H22V27H10Z","#fff0ce") ++
  shape("M16 4C22 10 22 15 16 17C10 15 10 10 16 4Z","#f1bf55") ++
  solid("M16 10Q20 15 16 16Q12 15 16 10Z","#ef7f83") ++
  line("M9 27H23","#d7a78e")
def jackbox() -> String:
  shape("M7 15H25V27H7Z","#ef7f83") ++
  shape("M5 12L21 5L26 9L10 16Z","#d7a78e") ++
  line("M12 24L16 20L20 24",ink()) ++
  line("M17 10L13 12L18 14L14 16L18 18","#f0d990")
def record() -> String:
  shape("M16 4C23 4 28 9 28 16C28 23 23 28 16 28C9 28 4 23 4 16C4 9 9 4 16 4Z","#eaca70") ++
  shape("M16 11C22 11 22 21 16 21C10 21 10 11 16 11Z","#20333b") ++
  solid("M15 15H17V17H15Z",cream()) ++
  line("M9 10Q6 15 9 21M23 11Q26 16 23 21",cream())
def speaker() -> String:
  shape("M6 5H22V27H6Z","#8faadb") ++
  shape("M14 14C21 14 21 24 14 24C7 24 7 14 14 14Z","#29444b") ++
  solid("M12 8H16V11H12Z",cream()) ++
  line("M26 10Q30 16 26 22","#c7bddf")
def ladle() -> String:
  shape("M19 5H23L18 19L14 18Z","#d7a78e") ++
  shape("M5 17H20Q20 27 13 27Q5 26 5 17Z","#f0d990") ++
  line("M7 18Q12 21 18 18",cream()) ++
  line("M8 11Q5 9 8 6M13 12Q10 10 13 7","#f6ddba")

def icon(id: Nat) -> String:
  match id:
    case 0n: weight()
    case 1n: metronome()
    case 2n: lens()
    case 3n: spool()
    case 4n: reed()
    case 5n: soles()
    case 6n: guard()
    case 7n: locket()
    case 8n: leaf()
    case 9n: notebook()
    case 10n: die()
    case 11n: thermos()
    case 12n: feather()
    case 13n: wick()
    case 14n: jackbox()
    case 15n: record()
    case 16n: speaker()
    case _: ladle()

def panel(+id: Nat) -> String:
  "<g data-id=\"" ++ Nat.show(id) ++ "\">" ++ icon(id) ++ "</g>"
def main() -> IO(Unit):
  IO.print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 32 32\">" ++ panel(0n) ++ panel(1n) ++ panel(2n) ++ panel(3n) ++ panel(4n) ++ panel(5n) ++ panel(6n) ++ panel(7n) ++ panel(8n) ++ panel(9n) ++ panel(10n) ++ panel(11n) ++ panel(12n) ++ panel(13n) ++ panel(14n) ++ panel(15n) ++ panel(16n) ++ panel(17n) ++ "</svg>")
