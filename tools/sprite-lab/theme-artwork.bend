import Base
import ./model.bend as M
import ./artwork.bend as Shared
import ./accessories-native.bend as Accessories

def colors(id: Nat) -> Shared.Colors:
  match id:
    case 0n: Shared.Colors{"#64534c", "#a18a71", "#3c3440", "#344d83", "#768fbd", "#eee9da", "#5a4438"}
    case 1n: Shared.Colors{"#614431", "#ae8050", "#362c30", "#eee4cf", "#fff8e5", "#344969", "#555f75"}
    case 2n: Shared.Colors{"#292d37", "#5b626c", "#151c2c", "#32343f", "#61616d", "#c8494d", "#282c39"}
    case 3n: Shared.Colors{"#9a653e", "#dcaf65", "#664337", "#e5b74f", "#ffe09b", "#3d7d80", "#dbede4"}
    case 4n: Shared.Colors{"#d49aaf", "#ffccd7", "#a56386", "#dce7e9", "#ffffff", "#8379ac", "#566078"}
    case 5n: Shared.Colors{"#69513d", "#ae946b", "#403632", "#77525b", "#b18b84", "#d5c399", "#58433c"}
    case _: Shared.Colors{"#292e38", "#555965", "#151c2c", "#c79b46", "#f6d98b", "#343c50", "#e7e6d9"}

def shadow(id: Nat) -> String:
  match id:
    case 0n: "#27365e"
    case 1n: "#b7b9b1"
    case 2n: "#212735"
    case 3n: "#a77935"
    case 4n: "#a7b8cf"
    case 5n: "#533d4c"
    case _: "#8f6835"

def garment_shadows(id: Nat) -> String:
  +shade = shadow(id)
  M.polygon([M.Point{24n, 45n}, M.Point{27n, 47n}, M.Point{27n, 54n}, M.Point{25n, 56n}, M.Point{24n, 53n}], shade) ++
  M.polygon([M.Point{39n, 44n}, M.Point{41n, 46n}, M.Point{41n, 56n}, M.Point{38n, 55n}, M.Point{38n, 49n}], shade) ++
  M.rect(21n, 49n, 2n, 3n, shade) ++ M.rect(44n, 49n, 2n, 3n, shade) ++
  M.rect(25n, 62n, 2n, 4n, "#29465c") ++ M.rect(36n, 62n, 2n, 3n, "#29465c")

def boot_shape(left: Bool, +lift: Nat) -> List<&2, M.Point>:
  match left:
    case True{}: [M.Point{23n, Nat.sub(70n, lift)}, M.Point{29n, Nat.sub(70n, lift)}, M.Point{29n, Nat.sub(74n, lift)}, M.Point{22n, Nat.sub(74n, lift)}, M.Point{22n, Nat.sub(72n, lift)}, M.Point{23n, Nat.sub(72n, lift)}]
    case False{}: [M.Point{36n, Nat.sub(70n, lift)}, M.Point{42n, Nat.sub(70n, lift)}, M.Point{42n, Nat.sub(72n, lift)}, M.Point{43n, Nat.sub(72n, lift)}, M.Point{43n, Nat.sub(74n, lift)}, M.Point{36n, Nat.sub(74n, lift)}]

def clothes(+outline: Bool, p: Shared.Pose, c: Shared.Colors) -> String:
  match p c:
    case Shared.Pose{+ll, +rl, +a, +b} Shared.Colors{hair, light, shade, +coat, +coatlight, inner, +boot}:
      M.limb_svg(Shared.leg(True{}, ll, b), Shared.thick(outline, 6n), Shared.paint(outline, "#18334c")) ++
      M.limb_svg(Shared.leg(False{}, rl, b), Shared.thick(outline, 6n), Shared.paint(outline, "#18334c")) ++
      M.polygon(boot_shape(True{}, ll), Shared.paint(outline, boot)) ++
      M.polygon(boot_shape(False{}, rl), Shared.paint(outline, boot)) ++
      M.limb_svg(Shared.arm(True{}, a, b), Shared.thick(outline, 8n), Shared.paint(outline, coat)) ++
      M.limb_svg(Shared.arm(False{}, a, b), Shared.thick(outline, 8n), Shared.paint(outline, coat)) ++
      M.rect(24n, Nat.add(39n, b), 17n, 23n, Shared.paint(outline, coat)) ++
      M.rect(31n, Nat.add(41n, b), 4n, 19n, Shared.paint(outline, inner)) ++
      M.rect(28n, Nat.add(42n, b), 3n, 6n, Shared.paint(outline, coatlight)) ++
      M.rect(35n, Nat.add(42n, b), 3n, 6n, Shared.paint(outline, coatlight)) ++
      M.polygon([Shared.shifted(25n, 41n, b), Shared.shifted(29n, 40n, b), Shared.shifted(31n, 43n, b), Shared.shifted(29n, 47n, b)], Shared.paint(outline, coatlight)) ++
      M.polygon([Shared.shifted(36n, 40n, b), Shared.shifted(40n, 41n, b), Shared.shifted(36n, 47n, b), Shared.shifted(34n, 43n, b)], Shared.paint(outline, coatlight)) ++
      M.rect(25n, Nat.add(58n, b), 4n, 2n, Shared.paint(outline, "#18334c")) ++
      M.rect(37n, Nat.add(58n, b), 3n, 2n, Shared.paint(outline, "#18334c")) ++
      M.rect(29n, Nat.add(35n, b), 7n, 5n, Shared.paint(outline, "#f4d7b2")) ++
      M.rect(17n, Nat.add(Nat.add(53n, a), b), 6n, 6n, Shared.paint(outline, "#f4d7b2")) ++
      M.rect(43n, Nat.add(Nat.sub(55n, a), b), 6n, 6n, Shared.paint(outline, "#f4d7b2"))

def body(+id: Nat) -> String:
  +c = colors(id)
  +p = Shared.pose(0n)
  "<g stroke=\"#101729\" stroke-width=\"4\" stroke-linejoin=\"round\">" ++ clothes(True{}, p, c) ++ Shared.head(True{}, id, c) ++ "</g>" ++
  clothes(False{}, p, c) ++ garment_shadows(id) ++ Shared.head(False{}, id, c) ++ Shared.accents(id, c) ++ Shared.hair_marks(c)

def figure(+id: Nat) -> String:
  body(id) ++ "<g transform=\"translate(32 38) scale(2)\">" ++ Accessories.icon(id) ++ "</g>"
