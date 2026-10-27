import Base

def ink() -> String: "#101729"

def accent(hero: Nat) -> String:
  match hero:
    case 0n: "#8faadb"
    case 1n: "#f0d990"
    case 2n: "#ef7f83"
    case 3n: "#f1bf55"
    case 4n: "#c7bddf"
    case 5n: "#d7a78e"
    case _: "#eaca70"

def fill(hero: Nat, style: Nat) -> String:
  match style:
    case 0n: accent(hero)
    case _: "#20333b"

def edge(hero: Nat, style: Nat) -> String:
  match style:
    case 0n: ink()
    case _: accent(hero)

def shape(data: String, +hero: Nat, +style: Nat) -> String:
  "<path d=\"" ++ data ++ "\" fill=\"" ++ fill(hero,style) ++ "\" stroke=\"" ++ edge(hero,style) ++ "\" stroke-width=\"2\" stroke-linejoin=\"round\"/>"

def detail(data: String, color: String) -> String:
  "<path d=\"" ++ data ++ "\" fill=\"none\" stroke=\"" ++ color ++ "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>"

def solid(data: String, color: String) -> String:
  "<path d=\"" ++ data ++ "\" fill=\"" ++ color ++ "\"/>"

def light(style: Nat) -> String:
  match style:
    case 0n: "#fff0ce"
    case _: "#ecdec4"

def notebook(+style: Nat) -> String:
  shape("M8 5H24Q26 5 26 7V25Q26 27 24 27H8Q6 27 6 25V7Q6 5 8 5Z",0n,style) ++
  detail("M10 6V26",ink()) ++
  solid("M15 21C12 13 18 10 23 10C23 16 21 22 15 21Z","#d7e5c0") ++
  detail("M15 23L21 13",edge(0n,style))

def composition(+style: Nat) -> String:
  shape("M13 10H24V23H13Z",0n,style) ++
  detail("M16 13H21M16 17H21M16 20H19",light(style)) ++
  detail("M8 7C3 10 4 20 10 24M25 7C29 10 29 17 26 21",accent(0n)) ++
  solid("M8 20L12 25L6 25ZM24 18L25 23L29 20Z",accent(0n))

def lantern(+style: Nat) -> String:
  detail("M14 8V6Q14 4 16 4Q18 4 18 6V8",accent(1n)) ++
  shape("M10 10H22L24 25H8Z",1n,style) ++
  shape("M8 8H24V11H8Z",1n,style) ++
  solid("M12 13H20V23H12Z",ink()) ++
  solid("M18 14C12 13 11 22 17 23C14 20 15 16 18 14Z",light(style)) ++
  solid("M10 25H13V28H10ZM19 25H22V28H19Z",accent(1n))

def orbit(+style: Nat) -> String:
  shape("M16 11C22 11 22 21 16 21C10 21 10 11 16 11Z",1n,style) ++
  detail("M6 13C12 6 26 10 27 16C28 23 13 27 6 22",light(style)) ++
  solid("M6 18L6 24L11 22Z",light(style)) ++
  solid("M7 9C11 9 11 15 7 15C3 15 3 9 7 9Z",accent(1n))

def keys(+style: Nat) -> String:
  shape("M6 8H26V26H6Z",2n,style) ++
  solid("M7 10H25V25H7Z",light(style)) ++
  detail("M12 11V25M19 11V25",ink()) ++
  solid("M10 9H14V18H10ZM17 9H21V18H17Z",ink()) ++
  solid("M15 20H17V24H15Z",accent(2n))

def release(+style: Nat) -> String:
  shape("M7 7H13V13L11 16L13 19V25H7Z",2n,style) ++
  shape("M19 7H25V25H19V19L21 16L19 13Z",2n,style) ++
  solid("M8 8H12V13L10 16L12 19V24H8ZM20 8H24V24H20V19L22 16L20 13Z",light(style)) ++
  solid("M16 11L18 14L17 16L19 18L17 19L16 23L14 19L13 18L15 16L14 14Z",accent(2n)) ++
  detail("M4 12L6 13M4 20L6 19M26 13L28 12M26 19L28 20",light(style))

def sneaker(+style: Nat) -> String:
  shape("M8 8H14L16 15L23 19H26Q28 19 28 22V25H5V20L8 17Z",3n,style) ++
  detail("M6 22H26M12 13L16 12M13 17L18 15",light(style)) ++
  detail("M8 9V16",edge(3n,style))

def afterbeat(+style: Nat) -> String:
  detail("M6 23C3 29 27 30 27 23",accent(3n)) ++
  "<g transform=\"rotate(-28 16 16)\">" ++
  shape("M15 5C9 5 8 10 9 13L12 17H18L22 12C26 8 22 5 17 5Z",3n,style) ++
  shape("M12 22H18V24Q18 27 15 27Q12 27 12 24Z",3n,style) ++
  detail("M10 13L20 15",light(style)) ++ "</g>"

def fan(+style: Nat) -> String:
  shape("M5 19L9 10L16 5L23 10L27 19L16 24Z",4n,style) ++
  detail("M16 23V7M16 23L10 12M16 23L22 12M16 23L7 19M16 23L25 19",edge(4n,style)) ++
  detail("M16 23V28",light(style))

def silk(+style: Nat) -> String:
  shape("M5 18L9 11L16 8L23 12L25 20L16 24Z",4n,style) ++
  detail("M16 23L10 13M16 23L16 10M16 23L22 14",edge(4n,style)) ++
  detail("M6 8C14 3 26 5 27 12",light(style)) ++
  solid("M23 10L28 15L28 8Z",light(style))

def viewfinder(+style: Nat) -> String:
  shape("M6 7L27 10L24 26L4 23Z",5n,style) ++
  solid("M10 12L22 14L21 21L8 19Z",ink()) ++
  detail("M6 25L10 25M24 6L26 7",light(style))

def dream(+style: Nat) -> String:
  shape("M14 11L23 13L20 24L11 21Z",5n,style) ++
  solid("M16 14L20 15L18 20L14 19Z",ink()) ++
  solid("M14 4L19 8L12 9ZM25 17L28 23L24 22ZM5 16L8 20L3 22Z",accent(5n))

def glove(+style: Nat) -> String:
  shape("M10 7H21Q24 7 24 10V18L27 15L28 18L24 25H10L7 18V12Q7 10 10 11Z",6n,style) ++
  detail("M13 8V13M18 8V13M10 23H22",edge(6n,style)) ++
  detail("M11 18H20",light(style)) ++
  solid("M10 24H23V27H10Z","#d9a1b7")

def drive(+style: Nat) -> String:
  detail("M5 9H11M4 16H10M6 24H12",accent(6n)) ++
  shape("M16 9H24Q27 9 27 12V18L25 24H16L12 19V14Q12 11 16 13Z",6n,style) ++
  detail("M20 10V14M16 21H24",light(style))

def icon(hero: Nat, kind: Nat, style: Nat) -> String:
  match hero kind:
    case 0n 0n: notebook(style)
    case 0n _: composition(style)
    case 1n 0n: lantern(style)
    case 1n _: orbit(style)
    case 2n 0n: keys(style)
    case 2n _: release(style)
    case 3n 0n: sneaker(style)
    case 3n _: afterbeat(style)
    case 4n 0n: fan(style)
    case 4n _: silk(style)
    case 5n 0n: viewfinder(style)
    case 5n _: dream(style)
    case _ 0n: glove(style)
    case _ _: drive(style)

def panel(+hero: Nat, +kind: Nat, +style: Nat) -> String:
  "<g data-hero=\"" ++ Nat.show(hero) ++ "\" data-kind=\"" ++ Nat.show(kind) ++ "\" data-style=\"" ++ Nat.show(style) ++ "\">" ++ icon(hero,kind,style) ++ "</g>"

def pair(+hero: Nat, +style: Nat) -> String:
  panel(hero,0n,style) ++ panel(hero,1n,style)

def family(+style: Nat) -> String:
  pair(0n,style) ++ pair(1n,style) ++ pair(2n,style) ++ pair(3n,style) ++ pair(4n,style) ++ pair(5n,style) ++ pair(6n,style)

def main() -> IO(Unit):
  IO.print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 32 32\">" ++ family(0n) ++ family(1n) ++ "</svg>")
