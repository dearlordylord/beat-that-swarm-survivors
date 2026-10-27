import Base
import ./model.bend as M

type Colors is Data:
  Colors{hair: String, light: String, shade: String, coat: String, coatlight: String, inner: String, boot: String}

def colors(id: Nat) -> Colors:
  match id:
    case 0n: Colors{"#49302b", "#795040", "#30232a", "#536044", "#74805a", "#f4eddb", "#9d5928"}
    case 1n: Colors{"#69402a", "#985a35", "#452d28", "#d985a0", "#efa9bc", "#f4eddb", "#e2ede6"}
    case 2n: Colors{"#e87333", "#ffc078", "#bd512b", "#1e828a", "#429da2", "#f6f6ee", "#815229"}
    case 3n: Colors{"#64d6bc", "#a4f0cc", "#39a99e", "#d8a64d", "#f1c66a", "#c94742", "#e2ede6"}
    case 4n: Colors{"#e885ad", "#ffb2c9", "#c6598b", "#e2ede6", "#ffffff", "#18334c", "#263344"}
    case 5n: Colors{"#745038", "#a2784d", "#49382d", "#8c8465", "#b1a78a", "#f4eddb", "#72452d"}
    case _: Colors{"#252b37", "#414350", "#151c2c", "#e2ede6", "#ffffff", "#ba3d43", "#263344"}

type Pose is Data:
  Pose{leftlift: Nat, rightlift: Nat, arm: Nat, bob: Nat}

def pose(frame: Nat) -> Pose:
  match frame:
    case 0n: Pose{0n, 0n, 0n, 0n}
    case 1n: Pose{0n, 1n, 1n, 0n}
    case 2n: Pose{0n, 2n, 2n, 1n}
    case 3n: Pose{0n, 1n, 1n, 0n}
    case 4n: Pose{0n, 0n, 0n, 0n}
    case 5n: Pose{1n, 0n, 1n, 0n}
    case 6n: Pose{2n, 0n, 2n, 1n}
    case _: Pose{1n, 0n, 1n, 0n}

def eye_pair() -> M.EyePair:
  M.eyes(M.Point{25n, 27n}, M.Point{37n, 27n}, 3n, 8n)

def ink() -> String: "#101729"
def paint(outline: Bool, color: String) -> String:
  match outline:
    case True{}: ink()
    case False{}: color

def thick(outline: Bool, width: Nat) -> Nat:
  match outline:
    case True{}: Nat.add(width, 4n)
    case False{}: width

def shifted(x: Nat, y: Nat, bob: Nat) -> M.Point:
  M.Point{x, Nat.add(y, bob)}

def boot_left() -> Nat: 22n
def boot_right() -> Nat: 35n
def boot_width() -> Nat: 8n

def knee_x(left: Bool, lift: Nat) -> Nat:
  match left lift:
    case True{} 0n: 27n
    case True{} _: 28n
    case False{} 0n: 38n
    case False{} _: 37n

def leg(+left: Bool, +lift: Nat, bob: Nat) -> M.Limb:
  match left:
    case True{}: M.Limb{shifted(27n, 59n, bob), M.Point{knee_x(left, lift), Nat.sub(64n, Nat.div(lift, 2n))}, M.Point{27n, Nat.sub(69n, lift)}}
    case False{}: M.Limb{shifted(38n, 59n, bob), M.Point{knee_x(left, lift), Nat.sub(64n, Nat.div(lift, 2n))}, M.Point{38n, Nat.sub(69n, lift)}}

def arm(left: Bool, phase: Nat, +bob: Nat) -> M.Limb:
  match left:
    case True{}: M.Limb{shifted(25n, 44n, bob), shifted(22n, 50n, bob), shifted(20n, Nat.add(55n, phase), bob)}
    case False{}: M.Limb{shifted(40n, 44n, bob), shifted(43n, 50n, bob), shifted(45n, Nat.sub(57n, phase), bob)}

def hair_shape(id: Nat) -> List<&2, M.Point>:
  match id:
    case 2n: [M.Point{12n, 22n}, M.Point{16n, 17n}, M.Point{14n, 12n}, M.Point{22n, 11n}, M.Point{21n, 5n}, M.Point{33n, 5n}, M.Point{39n, 3n}, M.Point{42n, 7n}, M.Point{49n, 7n}, M.Point{48n, 13n}, M.Point{53n, 18n}, M.Point{52n, 26n}, M.Point{46n, 31n}, M.Point{43n, 27n}, M.Point{40n, 25n}, M.Point{35n, 20n}, M.Point{30n, 20n}, M.Point{27n, 24n}, M.Point{24n, 26n}, M.Point{22n, 22n}, M.Point{17n, 29n}, M.Point{15n, 26n}]
    case 3n: [M.Point{12n, 23n}, M.Point{14n, 13n}, M.Point{22n, 7n}, M.Point{43n, 7n}, M.Point{51n, 14n}, M.Point{53n, 26n}, M.Point{42n, 27n}, M.Point{39n, 23n}, M.Point{25n, 25n}, M.Point{21n, 29n}, M.Point{16n, 25n}]
    case 4n: [M.Point{12n, 23n}, M.Point{15n, 13n}, M.Point{24n, 8n}, M.Point{44n, 5n}, M.Point{51n, 13n}, M.Point{53n, 24n}, M.Point{48n, 31n}, M.Point{43n, 21n}, M.Point{30n, 24n}, M.Point{21n, 30n}, M.Point{23n, 20n}, M.Point{16n, 27n}]
    case 1n: [M.Point{12n, 22n}, M.Point{15n, 12n}, M.Point{24n, 7n}, M.Point{43n, 7n}, M.Point{52n, 16n}, M.Point{51n, 26n}, M.Point{43n, 23n}, M.Point{39n, 27n}, M.Point{33n, 23n}, M.Point{27n, 27n}, M.Point{23n, 23n}, M.Point{17n, 27n}]
    case 5n: [M.Point{13n, 23n}, M.Point{16n, 13n}, M.Point{24n, 8n}, M.Point{44n, 8n}, M.Point{51n, 15n}, M.Point{51n, 27n}, M.Point{44n, 25n}, M.Point{41n, 20n}, M.Point{37n, 26n}, M.Point{31n, 21n}, M.Point{27n, 26n}, M.Point{23n, 22n}, M.Point{17n, 27n}]
    case _: [M.Point{11n, 21n}, M.Point{16n, 17n}, M.Point{14n, 13n}, M.Point{23n, 13n}, M.Point{22n, 7n}, M.Point{33n, 8n}, M.Point{39n, 5n}, M.Point{43n, 10n}, M.Point{50n, 10n}, M.Point{49n, 16n}, M.Point{54n, 20n}, M.Point{50n, 29n}, M.Point{44n, 27n}, M.Point{41n, 21n}, M.Point{35n, 25n}, M.Point{29n, 21n}, M.Point{23n, 26n}, M.Point{20n, 22n}, M.Point{15n, 28n}]

def boot_shape(left: Bool, +lift: Nat) -> List<&2, M.Point>:
  match left:
    case True{}: [M.Point{23n, Nat.sub(70n, lift)}, M.Point{30n, Nat.sub(70n, lift)}, M.Point{30n, Nat.sub(74n, lift)}, M.Point{22n, Nat.sub(74n, lift)}, M.Point{22n, Nat.sub(72n, lift)}, M.Point{23n, Nat.sub(72n, lift)}]
    case False{}: [M.Point{35n, Nat.sub(70n, lift)}, M.Point{42n, Nat.sub(70n, lift)}, M.Point{42n, Nat.sub(72n, lift)}, M.Point{43n, Nat.sub(72n, lift)}, M.Point{43n, Nat.sub(74n, lift)}, M.Point{35n, Nat.sub(74n, lift)}]

def clothes(+outline: Bool, p: Pose, c: Colors) -> String:
  match p c:
    case Pose{+ll, +rl, +a, +b} Colors{hair, light, shade, +coat, +coatlight, inner, +boot}:
      M.limb_svg(leg(True{}, ll, b), thick(outline, 6n), paint(outline, "#18334c")) ++
      M.limb_svg(leg(False{}, rl, b), thick(outline, 6n), paint(outline, "#18334c")) ++
      M.polygon(boot_shape(True{}, ll), paint(outline, boot)) ++
      M.polygon(boot_shape(False{}, rl), paint(outline, boot)) ++
      M.limb_svg(arm(True{}, a, b), thick(outline, 8n), paint(outline, coat)) ++
      M.limb_svg(arm(False{}, a, b), thick(outline, 8n), paint(outline, coat)) ++
      M.rect(24n, Nat.add(39n, b), 17n, 23n, paint(outline, coat)) ++
      M.rect(31n, Nat.add(41n, b), 4n, 19n, paint(outline, inner)) ++
      M.rect(28n, Nat.add(42n, b), 3n, 6n, paint(outline, coatlight)) ++
      M.rect(35n, Nat.add(42n, b), 3n, 6n, paint(outline, coatlight)) ++
      M.polygon([shifted(25n, 41n, b), shifted(29n, 40n, b), shifted(31n, 43n, b), shifted(29n, 47n, b)], paint(outline, coatlight)) ++
      M.polygon([shifted(36n, 40n, b), shifted(40n, 41n, b), shifted(36n, 47n, b), shifted(34n, 43n, b)], paint(outline, coatlight)) ++
      M.rect(25n, Nat.add(58n, b), 4n, 2n, paint(outline, "#18334c")) ++
      M.rect(37n, Nat.add(58n, b), 3n, 2n, paint(outline, "#18334c")) ++
      M.rect(29n, Nat.add(35n, b), 7n, 5n, paint(outline, "#f4d7b2")) ++
      M.rect(17n, Nat.add(Nat.add(53n, a), b), 6n, 6n, paint(outline, "#f4d7b2")) ++
      M.rect(43n, Nat.add(Nat.sub(55n, a), b), 6n, 6n, paint(outline, "#f4d7b2"))

def head(+outline: Bool, id: Nat, c: Colors) -> String:
  match c:
    case Colors{hair, light, shade, coat, coatlight, inner, boot}:
      M.polygon([M.Point{18n, 17n}, M.Point{46n, 17n}, M.Point{48n, 24n}, M.Point{46n, 33n}, M.Point{41n, 39n}, M.Point{25n, 39n}, M.Point{20n, 33n}, M.Point{18n, 25n}], paint(outline, "#f4d7b2")) ++
      M.polygon(hair_shape(id), paint(outline, hair))

def accents(id: Nat, c: Colors) -> String:
  match c:
    case Colors{hair, +light, shade, coat, coatlight, inner, boot}:
      M.polygon([M.Point{19n, 16n}, M.Point{22n, 13n}, M.Point{28n, 12n}, M.Point{28n, 14n}, M.Point{23n, 15n}, M.Point{21n, 18n}], light) ++ M.rect(30n, 11n, 3n, 2n, light) ++ M.rect(36n, 10n, 3n, 2n, light) ++
      M.polygon([M.Point{44n, 14n}, M.Point{49n, 19n}, M.Point{48n, 25n}, M.Point{45n, 23n}], shade) ++
      M.eye_svg(eye_pair(), ink()) ++
      M.rect(32n, 36n, 2n, 1n, "#df8188") ++
      M.rect(20n, 33n, 3n, 1n, "#e99695") ++
      M.rect(43n, 33n, 3n, 1n, "#e99695")

def coat_shadow(id: Nat) -> String:
  match id:
    case 0n: "#3c4837"
    case 1n: "#b56786"
    case 2n: "#285e6a"
    case 3n: "#a2773b"
    case 4n: "#a6c3c0"
    case 5n: "#645e4d"
    case _: "#a6c3c0"

def garment_marks(id: Nat, p: Pose) -> String:
  match p:
    case Pose{+ll, +rl, a, +b}:
      +shade = coat_shadow(id)
      M.polygon([shifted(24n, 45n, b), shifted(27n, 47n, b), shifted(27n, 54n, b), shifted(25n, 56n, b), shifted(24n, 53n, b)], shade) ++
      M.polygon([shifted(39n, 44n, b), shifted(41n, 46n, b), shifted(41n, 56n, b), shifted(38n, 55n, b), shifted(38n, 49n, b)], shade) ++
      M.rect(21n, Nat.add(49n, b), 2n, 3n, shade) ++
      M.rect(44n, Nat.add(49n, b), 2n, 3n, shade) ++
      M.rect(25n, Nat.sub(62n, ll), 2n, 4n, "#29465c") ++
      M.rect(36n, Nat.sub(62n, rl), 2n, 3n, "#29465c")

def hair_marks(c: Colors) -> String:
  match c:
    case Colors{hair, +light, +shade, coat, coatlight, inner, boot}:
      M.polygon([M.Point{29n, 12n}, M.Point{34n, 12n}, M.Point{34n, 14n}, M.Point{38n, 14n}, M.Point{38n, 16n}, M.Point{33n, 16n}, M.Point{33n, 15n}, M.Point{29n, 15n}], light) ++
      M.polygon([M.Point{16n, 21n}, M.Point{20n, 18n}, M.Point{23n, 20n}, M.Point{22n, 24n}, M.Point{18n, 26n}], shade) ++
      M.polygon([M.Point{38n, 18n}, M.Point{43n, 20n}, M.Point{45n, 25n}, M.Point{42n, 27n}, M.Point{39n, 24n}], shade)

def chest_mark(id: Nat, p: Pose) -> String:
  match id p:
    case 2n Pose{ll, rl, a, b}: M.rect(28n, Nat.add(48n, b), 2n, 2n, "#b45a59")
    case _ _: ""

def figure(+id: Nat, frame: Nat) -> String:
  +p = pose(frame)
  +c = colors(id)
  "<g stroke=\"#101729\" stroke-width=\"4\" stroke-linejoin=\"round\">" ++ clothes(True{}, p, c) ++ head(True{}, id, c) ++ "</g>" ++
  clothes(False{}, p, c) ++ garment_marks(id, p) ++ chest_mark(id, p) ++ head(False{}, id, c) ++ accents(id, c) ++ hair_marks(c)
