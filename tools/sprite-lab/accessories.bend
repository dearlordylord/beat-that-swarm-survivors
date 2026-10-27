import Base
import ./model.bend as M

def ink() -> String:
  "#101729"

def koya() -> String:
  M.polygon([M.Point{1n, 1n}, M.Point{3n, 1n}, M.Point{4n, 2n}, M.Point{8n, 2n}, M.Point{9n, 1n}, M.Point{11n, 1n}, M.Point{12n, 2n}, M.Point{12n, 4n}, M.Point{11n, 5n}, M.Point{11n, 8n}, M.Point{9n, 10n}, M.Point{3n, 10n}, M.Point{1n, 8n}, M.Point{1n, 5n}, M.Point{0n, 4n}, M.Point{0n, 2n}], ink()) ++
  M.rect(1n, 2n, 3n, 3n, "#86bde8") ++ M.rect(8n, 2n, 3n, 3n, "#86bde8") ++
  M.polygon([M.Point{3n, 3n}, M.Point{9n, 3n}, M.Point{10n, 5n}, M.Point{10n, 8n}, M.Point{8n, 9n}, M.Point{4n, 9n}, M.Point{2n, 8n}, M.Point{2n, 5n}], "#86bde8") ++
  M.rect(2n, 3n, 1n, 1n, "#c5def1") ++ M.rect(9n, 3n, 1n, 1n, "#c5def1") ++
  M.rect(3n, 6n, 2n, 1n, ink()) ++ M.rect(8n, 6n, 2n, 1n, ink()) ++
  M.rect(5n, 5n, 3n, 3n, "#8463c7") ++ M.rect(6n, 8n, 1n, 1n, ink())

def rj() -> String:
  M.polygon([M.Point{2n, 1n}, M.Point{4n, 1n}, M.Point{4n, 2n}, M.Point{5n, 2n}, M.Point{5n, 3n}, M.Point{7n, 3n}, M.Point{8n, 2n}, M.Point{8n, 1n}, M.Point{10n, 1n}, M.Point{10n, 3n}, M.Point{11n, 3n}, M.Point{11n, 5n}, M.Point{12n, 5n}, M.Point{12n, 7n}, M.Point{11n, 7n}, M.Point{11n, 9n}, M.Point{9n, 10n}, M.Point{3n, 10n}, M.Point{1n, 9n}, M.Point{1n, 7n}, M.Point{0n, 7n}, M.Point{0n, 5n}, M.Point{1n, 5n}, M.Point{1n, 3n}, M.Point{2n, 3n}], ink()) ++
  M.rect(3n, 2n, 1n, 2n, "#fff8e6") ++ M.rect(8n, 2n, 1n, 2n, "#fff8e6") ++
  M.polygon([M.Point{3n, 3n}, M.Point{5n, 3n}, M.Point{5n, 2n}, M.Point{7n, 2n}, M.Point{8n, 3n}, M.Point{9n, 3n}, M.Point{10n, 4n}, M.Point{10n, 6n}, M.Point{11n, 6n}, M.Point{10n, 7n}, M.Point{10n, 8n}, M.Point{8n, 9n}, M.Point{4n, 9n}, M.Point{2n, 8n}, M.Point{2n, 7n}, M.Point{1n, 6n}, M.Point{2n, 5n}, M.Point{2n, 4n}], "#fff8e6") ++
  M.rect(3n, 6n, 1n, 1n, ink()) ++ M.rect(8n, 6n, 1n, 1n, ink()) ++
  M.rect(5n, 7n, 2n, 1n, ink()) ++ M.rect(6n, 8n, 1n, 1n, ink()) ++
  M.rect(3n, 9n, 6n, 1n, "#e55751") ++ M.rect(8n, 10n, 1n, 2n, "#e55751")

def shooky() -> String:
  M.polygon([M.Point{3n, 1n}, M.Point{9n, 1n}, M.Point{11n, 3n}, M.Point{11n, 5n}, M.Point{12n, 5n}, M.Point{12n, 7n}, M.Point{11n, 8n}, M.Point{10n, 10n}, M.Point{9n, 11n}, M.Point{7n, 11n}, M.Point{7n, 10n}, M.Point{5n, 10n}, M.Point{5n, 11n}, M.Point{3n, 11n}, M.Point{2n, 10n}, M.Point{1n, 8n}, M.Point{0n, 7n}, M.Point{0n, 5n}, M.Point{1n, 5n}, M.Point{1n, 3n}], ink()) ++
  M.polygon([M.Point{3n, 2n}, M.Point{9n, 2n}, M.Point{10n, 4n}, M.Point{10n, 8n}, M.Point{8n, 10n}, M.Point{4n, 10n}, M.Point{2n, 8n}, M.Point{2n, 4n}], "#b47b47") ++
  M.rect(1n, 5n, 1n, 2n, "#b47b47") ++
  M.rect(10n, 5n, 1n, 2n, "#b47b47") ++
  M.rect(3n, 10n, 1n, 1n, "#b47b47") ++
  M.rect(8n, 10n, 1n, 1n, "#b47b47") ++
  M.rect(3n, 4n, 2n, 1n, ink()) ++ M.rect(7n, 4n, 2n, 1n, ink()) ++
  M.rect(3n, 5n, 1n, 1n, ink()) ++ M.rect(8n, 5n, 1n, 1n, ink()) ++
  M.rect(4n, 7n, 4n, 2n, ink()) ++ M.rect(5n, 7n, 2n, 1n, "#fff8e6")

def mang() -> String:
  M.polygon([M.Point{4n, 0n}, M.Point{8n, 0n}, M.Point{8n, 2n}, M.Point{10n, 2n}, M.Point{11n, 4n}, M.Point{10n, 6n}, M.Point{12n, 6n}, M.Point{12n, 9n}, M.Point{11n, 10n}, M.Point{8n, 12n}, M.Point{4n, 11n}, M.Point{2n, 9n}, M.Point{1n, 6n}, M.Point{1n, 2n}, M.Point{3n, 1n}], ink()) ++
  M.rect(5n, 1n, 2n, 3n, "#8b6aba") ++ M.rect(3n, 2n, 2n, 7n, "#8b6aba") ++
  M.polygon([M.Point{5n, 3n}, M.Point{9n, 3n}, M.Point{10n, 5n}, M.Point{10n, 8n}, M.Point{7n, 10n}, M.Point{4n, 9n}, M.Point{4n, 5n}], "#66c9d5") ++
  M.rect(2n, 3n, 1n, 2n, "#66c9d5") ++ M.rect(7n, 4n, 2n, 2n, "#fff8e6") ++ M.rect(8n, 4n, 1n, 1n, ink()) ++
  M.polygon([M.Point{7n, 7n}, M.Point{8n, 6n}, M.Point{9n, 7n}, M.Point{10n, 6n}, M.Point{11n, 7n}, M.Point{11n, 9n}, M.Point{9n, 11n}, M.Point{7n, 9n}], "#f2a3c2")

def chimmy() -> String:
  M.polygon([M.Point{3n, 0n}, M.Point{9n, 0n}, M.Point{11n, 2n}, M.Point{12n, 5n}, M.Point{11n, 9n}, M.Point{9n, 11n}, M.Point{3n, 11n}, M.Point{1n, 9n}, M.Point{0n, 5n}, M.Point{1n, 2n}], ink()) ++
  M.polygon([M.Point{3n, 1n}, M.Point{9n, 1n}, M.Point{11n, 4n}, M.Point{10n, 9n}, M.Point{8n, 10n}, M.Point{4n, 10n}, M.Point{2n, 9n}, M.Point{1n, 4n}], "#f8d447") ++
  M.polygon([M.Point{1n, 3n}, M.Point{3n, 3n}, M.Point{4n, 5n}, M.Point{3n, 9n}, M.Point{1n, 10n}, M.Point{0n, 8n}, M.Point{0n, 5n}], "#292838") ++
  M.rect(1n, 5n, 1n, 3n, "#424052") ++ M.rect(9n, 4n, 2n, 5n, "#292838") ++
  M.polygon([M.Point{4n, 3n}, M.Point{8n, 3n}, M.Point{9n, 6n}, M.Point{8n, 9n}, M.Point{4n, 9n}, M.Point{3n, 6n}], "#fff8e6") ++
  M.rect(4n, 5n, 1n, 1n, ink()) ++ M.rect(7n, 5n, 1n, 1n, ink()) ++ M.rect(5n, 6n, 2n, 2n, ink()) ++
  M.rect(6n, 8n, 1n, 2n, "#ed8899")

def tata() -> String:
  M.polygon([M.Point{2n, 0n}, M.Point{5n, 0n}, M.Point{6n, 2n}, M.Point{7n, 0n}, M.Point{10n, 0n}, M.Point{12n, 2n}, M.Point{12n, 5n}, M.Point{10n, 7n}, M.Point{6n, 11n}, M.Point{2n, 7n}, M.Point{0n, 5n}, M.Point{0n, 2n}], ink()) ++
  M.polygon([M.Point{2n, 1n}, M.Point{4n, 1n}, M.Point{6n, 3n}, M.Point{8n, 1n}, M.Point{10n, 1n}, M.Point{11n, 2n}, M.Point{11n, 5n}, M.Point{6n, 10n}, M.Point{1n, 5n}, M.Point{1n, 2n}], "#ee565e") ++
  M.rect(3n, 4n, 1n, 1n, ink()) ++ M.rect(8n, 4n, 1n, 1n, ink()) ++
  M.rect(4n, 6n, 4n, 3n, "#ffd858") ++ M.rect(5n, 7n, 2n, 1n, ink())

def cooky() -> String:
  M.polygon([M.Point{2n, 0n}, M.Point{4n, 0n}, M.Point{5n, 4n}, M.Point{7n, 4n}, M.Point{7n, 2n}, M.Point{9n, 2n}, M.Point{9n, 3n}, M.Point{11n, 3n}, M.Point{12n, 4n}, M.Point{12n, 6n}, M.Point{10n, 6n}, M.Point{12n, 7n}, M.Point{11n, 10n}, M.Point{9n, 12n}, M.Point{3n, 12n}, M.Point{1n, 10n}, M.Point{0n, 7n}, M.Point{2n, 5n}], ink()) ++
  M.rect(3n, 1n, 1n, 5n, "#ed95bd") ++ M.rect(8n, 3n, 1n, 2n, "#ed95bd") ++ M.rect(9n, 4n, 2n, 1n, "#ed95bd") ++
  M.polygon([M.Point{3n, 5n}, M.Point{9n, 5n}, M.Point{11n, 7n}, M.Point{10n, 10n}, M.Point{8n, 11n}, M.Point{4n, 11n}, M.Point{2n, 10n}, M.Point{1n, 7n}], "#ed95bd") ++
  M.rect(3n, 6n, 2n, 1n, ink()) ++ M.rect(4n, 7n, 1n, 1n, ink()) ++ M.rect(8n, 7n, 1n, 1n, ink()) ++
  M.rect(5n, 9n, 4n, 2n, "#fff8e6") ++ M.rect(6n, 9n, 1n, 1n, ink())

def head(id: Nat) -> String:
  match id:
    case 0n: koya()
    case 1n: rj()
    case 2n: shooky()
    case 3n: mang()
    case 4n: chimmy()
    case 5n: tata()
    case _: cooky()

def plush_color(id: Nat) -> String:
  match id:
    case 0n: "#86bde8"
    case 1n: "#fff8e6"
    case 2n: "#b47b47"
    case 3n: "#8b6aba"
    case 4n: "#f8d447"
    case 5n: "#5297d6"
    case _: "#ed95bd"

def body_marks(id: Nat) -> String:
  match id:
    case 0n: M.rect(5n, 10n, 2n, 2n, "#fff8e6")
    case 5n: M.rect(4n, 11n, 1n, 1n, "#ffd858") ++ M.rect(7n, 12n, 1n, 1n, "#ffd858")
    case _: ""

def plush_body(+id: Nat) -> String:
  M.rect(3n, 9n, 6n, 5n, ink()) ++ M.rect(2n, 10n, 8n, 2n, ink()) ++
  M.rect(4n, 10n, 4n, 3n, plush_color(id)) ++
  M.rect(4n, 13n, 1n, 1n, plush_color(id)) ++ M.rect(7n, 13n, 1n, 1n, plush_color(id)) ++
  body_marks(id) ++ head(id)

def plush(+id: Nat) -> String:
  match id:
    case 2n: "<g transform=\"translate(0 1)\">" ++ shooky() ++ "</g>"
    case _: plush_body(id)

def icon(+id: Nat, variant: Nat) -> String:
  match variant:
    case 0n: "<g transform=\"translate(0 1)\">" ++ head(id) ++ "</g>"
    case _: plush(id)

def placed(id: Nat, variant: Nat, x: Nat, y: Nat) -> String:
  "<g transform=\"translate(" ++ Nat.show(x) ++ " " ++ Nat.show(y) ++ ")\">" ++ icon(id, variant) ++ "</g>"
