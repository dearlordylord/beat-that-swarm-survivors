# Pixel assertions run through the actual native body renderer and quadtree image.
import Base
import game-components.bend as Components
import game.bend as G
import enemy-combat.bend as Enemy
import enemy-spatial.bend as Space
import native.bend as N
import native_draw.bend as D
import native-capture.bend as Capture

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def enemy(x: F32,y: F32,archetype: U32,health: U32,maximum: U32,identity: U32) -> Enemy.State:
  Enemy.State{Space.Spatial{x,y,0,10.0},archetype,identity,Components.Vitals{health,maximum},Components.Status{0,0}}
def image(kind: U32,variant: U32,hp: U32,maxHp: U32) -> Image:
  match kind:
    case 0: D.image(N.enemies([enemy(1800.0,1800.0,variant,hp,maxHp,0)],1800.0,1800.0,[]))
    case kind: D.image(N.bodies([Components.Body{1800.0,1800.0,kind,variant,hp,maxHp,0,0,10.0}],1800.0,1800.0,[]))
def pixel(kind: U32,variant: U32,hp: U32,maxHp: U32,x: U32,y: U32) -> U32:
  Capture.pixel(image(kind,variant,hp,maxHp),x,y,512)
def variants(fuel: Nat,+index: U32) -> IO(Unit):
  match fuel:
    case 0n: IO.pure(Unit,Unit{})
    case 1n+p:
      do IO<Unit>:
        expect(U32.is_eq(pixel(0,index,100,100,261,187),10871200),"full-health bar for enemy variant " ++ U32.show(index))
        variants(p,(index + 1 : U32))
def overlapping_image() -> Image:
  D.image(N.enemies([enemy(1800.0,1800.0,0,100,100,0),enemy(1800.0,1765.0,5,100,100,1)],1800.0,1800.0,[]))
def main() -> IO(Unit):
  do IO<Unit>:
    variants(31n,0)
    expect(U32.is_eq(pixel(0,0,50,100,250,187),10871200),"half-health filled half")
    expect(U32.is_eq(pixel(0,0,50,100,261,187),5841972),"half-health empty half")
    expect(U32.is_eq(pixel(0,0,100,100,247,186),15391673),"contrasting border")
    expect(U32.is_eq(pixel(0,0,0,100,250,187),725017),"dead enemy has no bar")
    expect(U32.is_eq(pixel(2,0,50,100,250,187),725017),"loot has no enemy bar")
    expect(U32.is_eq(pixel(0,0,200,100,265,187),725017),"overheal never overflows bar")
    expect(U32.is_eq(Capture.pixel(overlapping_image(),261,187,512),10871200),"neighboring sprite cannot cover enemy bar")
    Capture.save("enemy-healthbars.ppm",D.image(N.enemies([enemy(1700.0,1800.0,0,100,100,0),enemy(1800.0,1800.0,5,50,100,1),enemy(1900.0,1800.0,30,10,100,2)],1800.0,1800.0,[])))
