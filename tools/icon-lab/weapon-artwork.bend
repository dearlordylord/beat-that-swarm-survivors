import Base
import ./artwork.bend as A

def object(path: String, hero: Nat) -> String: A.shape(path,hero,0n)
def trace(path: String, hero: Nat) -> String: A.detail(path,A.accent(hero))
def pale(path: String) -> String: A.detail(path,"#fff0ce")

def letter() -> String:
  object("M13 9L26 12L23 24L10 21Z",1n) ++ pale("M14 12L18 17L23 14") ++ trace("M5 21Q4 10 12 7",1n) ++ A.solid("M9 6L14 6L12 11Z",A.accent(1n))
def vinyl() -> String:
  object("M17 10C29 10 29 27 17 27C5 27 5 10 17 10Z",5n) ++ A.solid("M17 16C21 16 21 21 17 21C13 21 13 16 17 16Z",A.ink()) ++ trace("M5 12Q10 3 22 6",5n) ++ A.solid("M22 3L27 8L21 8Z",A.accent(5n))
def moons() -> String:
  trace("M7 10C24 3 31 23 14 26C4 28 2 17 7 10",1n) ++ object("M16 10C22 11 23 18 19 22C12 24 8 17 12 12C11 17 15 20 18 17C20 14 18 12 16 10Z",1n) ++ A.solid("M7 9C11 9 11 14 7 14C3 14 3 9 7 9Z",A.accent(1n))
def hearth() -> String:
  trace("M5 25C2 12 8 5 16 5C25 5 30 16 26 25",1n) ++ object("M10 24L10 17L16 11L22 17V24Z",1n) ++ A.solid("M16 16Q11 21 15 24Q21 25 20 19L18 21Z","#e9aa67") ++ pale("M8 27H24")
def spotlight() -> String:
  object("M11 5L23 8L20 14L8 11Z",3n) ++ A.solid("M12 14L8 25H25L18 16Z",A.accent(3n)) ++ pale("M9 27H25")
def burnverse() -> String:
  object("M10 10H19L23 15L20 24H10Z",2n) ++ pale("M12 13H17M12 17H17") ++ A.solid("M22 7Q19 12 24 14Q30 12 25 5Q27 10 24 11Z",A.accent(2n)) ++ trace("M5 23L10 19",2n)
def rain() -> String:
  object("M8 23Q16 18 25 23L23 27H9Z",0n) ++ A.solid("M10 7Q4 13 10 15Q16 13 10 7ZM22 5Q16 12 22 14Q28 12 22 5Z",A.accent(0n)) ++ pale("M16 16V20")
def fragments() -> String:
  object("M5 7L13 5L15 15L7 17Z",0n) ++ object("M19 9L26 12L23 22L16 19Z",0n) ++ pale("M8 9L11 8M8 12L12 11M20 13L23 14") ++ trace("M7 24Q15 29 23 25",0n)
def reflection() -> String:
  object("M15 5L24 14L18 27L8 18Z",4n) ++ pale("M15 9L12 17L17 21") ++ trace("M4 12L8 12M4 19H7M23 23H28",4n)
def curtain() -> String:
  object("M6 7H26V10H6Z",1n) ++ object("M6 10H12L10 23L6 25Z",1n) ++ object("M20 10H26V25L22 23Z",1n) ++ A.solid("M16 13L19 18L16 23L13 18Z",A.light(0n)) ++ pale("M16 10V11M16 25V27") ++ trace("M4 28H28",1n)
def ribbon() -> String:
  object("M5 22Q7 9 18 8Q26 7 27 14Q25 23 13 20L10 26L6 25L10 16Q21 21 23 14Q22 11 15 13Q9 14 8 23Z",4n) ++ pale("M4 8L8 6M25 25L28 22")
def thrust() -> String:
  object("M7 24L20 11L17 8L27 5L25 15L22 13L9 27Z",6n) ++ pale("M13 16L19 10") ++ trace("M5 16L8 13M11 6L14 5",6n)
def blades() -> String:
  object("M15 5L19 12L16 16L12 12Z",2n) ++ object("M24 16L27 24L19 21L18 17Z",2n) ++ object("M6 17L12 18L13 22L5 25Z",2n) ++ pale("M15 17L16 19")
def crumb() -> String:
  A.solid("M16 7Q23 6 25 11Q20 10 22 15Q19 16 25 19Q25 26 17 26Q8 27 8 18Q6 11 16 7Z","#d0a373") ++ A.detail("M16 7Q23 6 25 11Q20 10 22 15Q19 16 25 19Q25 26 17 26Q8 27 8 18Q6 11 16 7Z",A.ink()) ++ A.solid("M13 11H16V14H13ZM17 17H20V20H17ZM11 20H14V23H11Z","#654735") ++ trace("M4 18Q3 8 10 5",2n)
def comet() -> String:
  object("M6 6L19 13Q27 12 27 20Q26 28 18 27Q11 26 12 19Z",1n) ++ pale("M9 5L18 12M6 11L11 16") ++ A.solid("M20 17Q25 17 24 22Q20 25 18 21Z",A.light(0n))
def beam() -> String:
  object("M4 10H11V23H4Z",6n) ++ object("M11 12H28V21H11Z",6n) ++ pale("M12 16H27") ++ A.solid("M6 14H9V19H6Z",A.ink())
def leaves() -> String:
  trace("M9 8C25 4 30 23 17 26C5 28 1 15 9 8",0n) ++ A.solid("M7 10Q10 3 16 6Q15 14 7 10ZM21 17Q28 13 28 20Q24 26 21 17ZM5 22Q9 16 14 23Q10 29 5 22Z","#b6d2aa")

def icon(id: Nat) -> String:
  match id:
    case 0n: letter()
    case 1n: A.icon(6n,1n,0n)
    case 2n: vinyl()
    case 3n: moons()
    case 4n: hearth()
    case 5n: spotlight()
    case 6n: burnverse()
    case 7n: rain()
    case 8n: A.icon(4n,1n,0n)
    case 9n: fragments()
    case 10n: reflection()
    case 11n: curtain()
    case 12n: ribbon()
    case 13n: thrust()
    case 14n: A.icon(2n,1n,0n)
    case 15n: blades()
    case 16n: crumb()
    case 17n: comet()
    case 18n: beam()
    case 19n: leaves()
    case 20n: A.icon(0n,1n,0n)
    case 21n: A.icon(1n,1n,0n)
    case 22n: A.icon(3n,1n,0n)
    case _: A.icon(5n,1n,0n)

def panel(+id: Nat) -> String:
  "<g data-id=\"" ++ Nat.show(id) ++ "\">" ++ icon(id) ++ "</g>"
def family() -> String:
  panel(0n) ++ panel(1n) ++ panel(2n) ++ panel(3n) ++ panel(4n) ++ panel(5n) ++ panel(6n) ++ panel(7n) ++ panel(8n) ++ panel(9n) ++ panel(10n) ++ panel(11n) ++ panel(12n) ++ panel(13n) ++ panel(14n) ++ panel(15n) ++ panel(16n) ++ panel(17n) ++ panel(18n) ++ panel(19n) ++ panel(20n) ++ panel(21n) ++ panel(22n) ++ panel(23n)
def main() -> IO(Unit):
  IO.print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 32 32\">" ++ family() ++ "</svg>")
