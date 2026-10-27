import Base
import ./model.bend as M
import ./artwork.bend as Shared
import ./theme-artwork.bend as Theme
import ./accessories-native.bend as Accessories

type Step is Data:
  Step{ground: Nat, lift: Nat}

def step(frame: Nat) -> Step:
  match frame:
    case 0n: Step{76n, 0n}
    case 1n: Step{75n, 0n}
    case 2n: Step{74n, 0n}
    case 3n: Step{73n, 0n}
    case 4n: Step{72n, 0n}
    case 5n: Step{73n, 3n}
    case 6n: Step{74n, 4n}
    case _: Step{75n, 2n}

def opposite(frame: Nat) -> Nat:
  Nat.mod(Nat.add(frame, 4n), 8n)

def wrist(frame: Nat) -> Nat:
  match frame:
    case 0n: 2n
    case 1n: 1n
    case 2n: 0n
    case 3n: 1n
    case 4n: 2n
    case 5n: 3n
    case 6n: 4n
    case _: 3n

def lane(left: Bool) -> Nat:
  match left:
    case True{}: 27n
    case False{}: 38n

def boot_x(left: Bool) -> Nat:
  match left:
    case True{}: 22n
    case False{}: 36n

def leg(+left: Bool, s: Step) -> M.Limb:
  Step{ground, lift} = s
  +x = lane(left)
  M.Limb{M.Point{x, 59n}, M.Point{x, 64n}, M.Point{x, Nat.sub(Nat.sub(ground, lift), 5n)}}

def boot(+left: Bool, s: Step, color: String) -> String:
  Step{ground, lift} = s
  +bottom = Nat.sub(ground, lift)
  +x = boot_x(left)
  M.rect(x, Nat.sub(bottom, 5n), 7n, 5n, color)

def leg_width(outline: Bool) -> Nat:
  match outline:
    case True{}: 4n
    case False{}: 6n

def legs(+outline: Bool, +frame: Nat, +color: String) -> String:
  +l = step(frame)
  +r = step(opposite(frame))
  M.limb_svg(leg(True{}, l), leg_width(outline), Shared.paint(outline, "#18334c")) ++
  M.limb_svg(leg(False{}, r), leg_width(outline), Shared.paint(outline, "#18334c")) ++
  boot(True{}, l, Shared.paint(outline, color)) ++ boot(False{}, r, Shared.paint(outline, color))

def arms(+outline: Bool, +frame: Nat, +color: String) -> String:
  +a = wrist(frame)
  +r = wrist(opposite(frame))
  M.limb_svg(M.Limb{M.Point{25n,44n}, M.Point{22n,50n}, M.Point{20n,Nat.add(54n,a)}}, Shared.thick(outline,8n), Shared.paint(outline,color)) ++
  M.limb_svg(M.Limb{M.Point{40n,44n}, M.Point{43n,50n}, M.Point{45n,Nat.add(54n,r)}}, Shared.thick(outline,8n), Shared.paint(outline,color)) ++
  M.rect(17n,Nat.add(52n,a),6n,6n,Shared.paint(outline,"#f4d7b2")) ++
  M.rect(43n,Nat.add(52n,r),6n,6n,Shared.paint(outline,"#f4d7b2"))

def torso(+outline: Bool, c: Shared.Colors) -> String:
  Shared.Colors{hair,light,shade,+coat,+coatlight,inner,boot} = c
  M.rect(24n,39n,17n,23n,Shared.paint(outline,coat)) ++
  M.rect(31n,41n,4n,19n,Shared.paint(outline,inner)) ++
  M.rect(28n,42n,3n,6n,Shared.paint(outline,coatlight)) ++
  M.rect(35n,42n,3n,6n,Shared.paint(outline,coatlight)) ++
  M.polygon([M.Point{25n,41n},M.Point{29n,40n},M.Point{31n,43n},M.Point{29n,47n}],Shared.paint(outline,coatlight)) ++
  M.polygon([M.Point{36n,40n},M.Point{40n,41n},M.Point{36n,47n},M.Point{34n,43n}],Shared.paint(outline,coatlight)) ++
  M.rect(25n,58n,4n,2n,Shared.paint(outline,"#18334c")) ++
  M.rect(37n,58n,3n,2n,Shared.paint(outline,"#18334c")) ++
  M.rect(29n,35n,7n,5n,Shared.paint(outline,"#f4d7b2"))

def shadows(id: Nat) -> String:
  +shade = Theme.shadow(id)
  M.polygon([M.Point{24n,45n},M.Point{27n,47n},M.Point{27n,54n},M.Point{25n,56n},M.Point{24n,53n}],shade) ++
  M.polygon([M.Point{39n,44n},M.Point{41n,46n},M.Point{41n,56n},M.Point{38n,55n},M.Point{38n,49n}],shade) ++
  M.rect(21n,49n,2n,3n,shade) ++ M.rect(44n,49n,2n,3n,shade)

def body_layer(+outline: Bool, +frame: Nat, +c: Shared.Colors) -> String:
  Shared.Colors{hair,light,shade,+coat,coatlight,inner,boot} = c
  legs(outline,frame,boot) ++ arms(outline,frame,coat) ++ torso(outline,c)

def foreground_boots(+frame: Nat, c: Shared.Colors) -> String:
  Shared.Colors{hair,light,shade,coat,coatlight,inner,+color} = c
  boot(True{},step(frame),color) ++ boot(False{},step(opposite(frame)),color)

def figure(+id: Nat, +frame: Nat) -> String:
  +c = Theme.colors(id)
  +r = wrist(opposite(frame))
  "<g stroke=\"#101729\" stroke-width=\"4\" stroke-linejoin=\"round\">" ++ body_layer(True{},frame,c) ++ Shared.head(True{},id,c) ++ "</g>" ++
  body_layer(False{},frame,c) ++
  shadows(id) ++ Shared.head(False{},id,c) ++ Shared.accents(id,c) ++ Shared.hair_marks(c) ++
  "<g transform=\"translate(32 " ++ Nat.show(Nat.add(36n,r)) ++ ") scale(2)\">" ++ Accessories.icon(id) ++ "</g>" ++ foreground_boots(frame, c)

def metadata(s: Step) -> String:
  Step{ground,lift} = s
  " data-ground=\"" ++ Nat.show(ground) ++ "\" data-lift=\"" ++ Nat.show(lift) ++ "\""

def panel(+id: Nat, +frame: Nat) -> String:
  "<g" ++ metadata(step(frame)) ++ " data-character=\"" ++ Nat.show(id) ++ "\" data-frame=\"" ++ Nat.show(frame) ++ "\">" ++ figure(id,frame) ++ "</g>"

def frames(+id: Nat) -> String:
  panel(id,0n) ++ panel(id,1n) ++ panel(id,2n) ++ panel(id,3n) ++ panel(id,4n) ++ panel(id,5n) ++ panel(id,6n) ++ panel(id,7n)

def emit() -> String:
  frames(0n) ++ frames(1n) ++ frames(2n) ++ frames(3n) ++ frames(4n) ++ frames(5n) ++ frames(6n)

def main() -> IO(Unit):
  IO.print("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 80\">" ++ emit() ++ "</svg>")
