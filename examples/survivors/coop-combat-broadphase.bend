import Base
import ./projectile-contact.bend as Contact

# Broadphase candidates only: the original swept solver still decides contacts.
# The guarded Float32 world envelope uses deliberately generous outward slack;
# anything outside it takes the complete unvisited reference path. This is not
# presented as a kernel theorem about IEEE geometry: differential contacts and
# complete combat-state parity qualify this optimization.
type Box is Data: Box{fast:Bool,minX:F32,maxX:F32,minY:F32,maxY:F32}
type Item is Data: Item{target:Contact.Target,box:Box}
type Index is Data: Index{rows:List<&2,Item>}
def coordinate(+value:F32) -> Bool: Bool.and(F32.is_le((0.0 - 32768.0 : F32),value),F32.is_le(value,32768.0))
def envelope(+x0:F32,+y0:F32,+x1:F32,+y1:F32,+radius:F32) -> Bool:
  Bool.and(Bool.and(coordinate(x0),coordinate(y0)),Bool.and(Bool.and(coordinate(x1),coordinate(y1)),Bool.and(Bool.and(F32.is_le(0.0,radius),F32.is_le(radius,1024.0)),Bool.and(F32.is_le(F32.abs((x1 - x0 : F32)),256.0),F32.is_le(F32.abs((y1 - y0 : F32)),256.0)))))
def padding() -> F32: 64.0
def bounds(+x0:F32,+y0:F32,+x1:F32,+y1:F32,+radius:F32) -> Box:
  Box{envelope(x0,y0,x1,y1,radius),((F32.min(x0,x1) - radius) - padding() : F32),((F32.max(x0,x1) + radius) + padding() : F32),((F32.min(y0,y1) - radius) - padding() : F32),((F32.max(y0,y1) + radius) + padding() : F32)}
def item(+target:Contact.Target) -> Item:
  match target:
    case Contact.Target{_,x0,y0,x1,y1,radius}: Item{target,bounds(x0,y0,x1,y1,radius)}
def prepare_rows(rows:List<&2,Contact.Target>) -> List<&2,Item>:
  match rows:
    case []: []
    case head <> tail: item(head) <> prepare_rows(tail)
def prepare(rows:List<&2,Contact.Target>) -> Index: Index{prepare_rows(rows)}
def overlaps(left:Box,right:Box) -> Bool:
  match left right:
    case Box{False{},_,_,_,_} _: True{}
    case _ Box{False{},_,_,_,_}: True{}
    case Box{True{},lx0,lx1,ly0,ly1} Box{True{},rx0,rx1,ry0,ry1}: Bool.and(Bool.and(F32.is_le(lx0,rx1),F32.is_le(rx0,lx1)),Bool.and(F32.is_le(ly0,ry1),F32.is_le(ry0,ly1)))
def target_seed(target:Contact.Target) -> U32:
  match target:
    case Contact.Target{seed,_,_,_,_,_}: seed
def unvisited(visited:Bool,left:Box,right:Box) -> Bool:
  match visited:
    case True{}: False{}
    case False{}: overlaps(left,right)
def put(keep:Bool,target:Contact.Target,tail:List<&2,Contact.Target>) -> List<&2,Contact.Target>:
  match keep:
    case False{}: tail
    case True{}: target <> tail
def candidates(rows:List<&2,Item>,+source:Box,+visited:List<&2,U32>) -> List<&2,Contact.Target>:
  match rows:
    case []: []
    case Item{+target,box} <> tail: put(unvisited(Contact.contains(visited,target_seed(target)),source,box),target,candidates(tail,source,visited))
def query(index:Index,x0:F32,y0:F32,x1:F32,y1:F32,radius:F32,visited:List<&2,U32>) -> List<&2,Contact.Target>:
  match index:
    case Index{rows}: candidates(rows,bounds(x0,y0,x1,y1,radius),visited)
