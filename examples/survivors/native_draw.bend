import Base

# Clipped display lists: each quadtree branch sees only overlapping shapes.
type Rect is Data: Rect{x: F32,y: F32,w: F32,h: F32,color: U32}
def rect(x: F32,y: F32,w: F32,h: F32,color: U32,tail: List<&2,Rect>) -> List<&2,Rect>: Rect{x,y,w,h,color} <> tail

def glyph(code: U32) -> List<&2,U32>:
  match code:
    case 65: [14,17,17,31,17,17,17]
    case 66: [30,17,17,30,17,17,30]
    case 67: [15,16,16,16,16,16,15]
    case 68: [30,17,17,17,17,17,30]
    case 69: [31,16,16,30,16,16,31]
    case 70: [31,16,16,30,16,16,16]
    case 71: [15,16,16,23,17,17,15]
    case 72: [17,17,17,31,17,17,17]
    case 73: [14,4,4,4,4,4,14]
    case 74: [7,2,2,2,18,18,12]
    case 75: [17,18,20,24,20,18,17]
    case 76: [16,16,16,16,16,16,31]
    case 77: [17,27,21,21,17,17,17]
    case 78: [17,25,21,19,17,17,17]
    case 79: [14,17,17,17,17,17,14]
    case 80: [30,17,17,30,16,16,16]
    case 81: [14,17,17,17,21,18,13]
    case 82: [30,17,17,30,20,18,17]
    case 83: [15,16,16,14,1,1,30]
    case 84: [31,4,4,4,4,4,4]
    case 85: [17,17,17,17,17,17,14]
    case 86: [17,17,17,17,17,10,4]
    case 87: [17,17,17,21,21,21,10]
    case 88: [17,17,10,4,10,17,17]
    case 89: [17,17,10,4,4,4,4]
    case 90: [31,1,2,4,8,16,31]
    case 48: [14,17,19,21,25,17,14]
    case 49: [4,12,4,4,4,4,14]
    case 50: [14,17,1,2,4,8,31]
    case 51: [30,1,1,14,1,1,30]
    case 52: [2,6,10,18,31,2,2]
    case 53: [31,16,16,30,1,1,30]
    case 54: [14,16,16,30,17,17,14]
    case 55: [31,1,2,4,8,8,8]
    case 56: [14,17,17,14,17,17,14]
    case 57: [14,17,17,15,1,1,14]
    case 58: [0,4,4,0,4,4,0]
    case 47: [1,2,2,4,8,8,16]
    case 45: [0,0,0,31,0,0,0]
    case 46: [0,0,0,0,0,6,6]
    case 43: [0,4,4,31,4,4,0]
    case 40: [2,4,8,8,8,4,2]
    case 41: [8,4,2,2,2,4,8]
    case 63: [14,17,1,2,4,0,4]
    case 33: [4,4,4,4,4,0,4]
    case 62: [16,8,4,2,4,8,16]
    case 60: [1,2,4,8,4,2,1]
    case 61: [0,0,31,0,31,0,0]
    case 37: [25,26,2,4,8,11,19]
    case 91: [14,8,8,8,8,8,14]
    case 93: [14,2,2,2,2,2,14]
    case 39: [4,4,0,0,0,0,0]
    case 44: [0,0,0,0,0,4,8]
    case _: [0,0,0,0,0,0,0]

def upper_case(lower: Bool,+code: U32) -> U32:
  match lower:
    case True{}: (code - 32 : U32)
    case False{}: code
def upper(+code: U32) -> U32: upper_case(Bool.and(U32.is_le(97,code),U32.is_le(code,122)),code)

def dot(on: Bool,+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,Rect>) -> List<&2,Rect>:
  match on:
    case True{}: rect(x,y,scale,scale,color,tail)
    case False{}: tail

def bits(fuel: Nat,+mask: U32,+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,Rect>) -> List<&2,Rect>:
  match fuel:
    case 0n: tail
    case 1n+k: dot(U32.is_lt(0,U32.and(mask,16)),x,y,scale,color,bits(k,(mask * 2 : U32),(x + scale : F32),y,scale,color,tail))

def glyph_rows(rows: List<&2,U32>,+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,Rect>) -> List<&2,Rect>:
  match rows:
    case []: tail
    case mask <> rest: bits(5n,mask,x,y,scale,color,glyph_rows(rest,x,(y + scale : F32),scale,color,tail))

def text(value: String,+x: F32,+y: F32,+scale: F32,+color: U32,tail: List<&2,Rect>) -> List<&2,Rect>:
  match value:
    case SNil{}: tail
    case SCon{Chr{code},rest}: glyph_rows(glyph(upper(code)),x,y,scale,color,text(rest,(x + 6.0 * scale : F32),y,scale,color,tail))

def wrapped_chars(value: String,fuel: Nat,+x: F32,+y: F32,+left: F32,+width: U32,+column: U32,+color: U32,tail: List<&2,Rect>) -> List<&2,Rect>:
  match value fuel:
    case SNil{} n: tail
    case str 0n: tail
    case SCon{Chr{code},rest} 1n+k:
      glyph_rows(glyph(upper(code)),x,y,1.0,color,wrapped_chars(rest,k,(left + U32.to_f32(((column + 1) % width : U32)) * 6.0 : F32),(y + 10.0 * U32.to_f32(Bool.to_u32(U32.is_eq(((column + 1) % width : U32),0))) : F32),left,width,(column + 1 : U32),color,tail))
def wrapped(value: String,+x: F32,+y: F32,left: F32,right: F32,bottom: F32,color: U32,tail: List<&2,Rect>) -> List<&2,Rect>:
  +width = U32.max(1,F32.to_u32(((right - x) / 6.0 : F32)))
  wrapped_chars(value,U32.to_nat((width * F32.to_u32(((bottom - y + 10.0) / 10.0 : F32)) : U32)),x,y,left,width,0,color,tail)

def overlap(r: Rect,+x: F32,+y: F32,+size: F32) -> Bool:
  match r:
    case Rect{+rx,+ry,w,h,color}: Bool.and(Bool.and(F32.is_lt(rx,(x + size : F32)),F32.is_lt(x,(rx + w : F32))),Bool.and(F32.is_lt(ry,(y + size : F32)),F32.is_lt(y,(ry + h : F32))))
def keep(found: Bool,r: Rect,tail: List<&2,Rect>) -> List<&2,Rect>:
  match found:
    case True{}: r <> tail
    case False{}: tail

def clip(rows: List<&2,Rect>,+x: F32,+y: F32,+size: F32) -> List<&2,Rect>:
  match rows:
    case []: []
    case +r <> rest: keep(overlap(r,x,y,size),r,clip(rest,x,y,size))

def covers(r: Rect,+x: F32,+y: F32,+size: F32) -> Bool:
  match r:
    case Rect{+rx,+ry,w,h,color}: Bool.and(Bool.and(F32.is_le(rx,x),F32.is_le(ry,y)),Bool.and(F32.is_le((x + size : F32),(rx + w : F32)),F32.is_le((y + size : F32),(ry + h : F32))))
def rectangle_color(r: Rect) -> U32:
  match r:
    case Rect{x,y,w,h,color}: color
def solid_or(covered: Bool,color: U32,draw: Unit -> Image) -> Image:
  match covered:
    case True{}: Pix{color}
    case False{}: draw(Unit{})

def tile(fuel: Nat,rows: List<&2,Rect>,+x: F32,+y: F32,+size: F32) -> Image:
  match fuel rows:
    case 0n Nil{}: Pix{725017}
    case 0n Con{Rect{rx,ry,w,h,color},rest}: Pix{color}
    case 1n+k Nil{}: Pix{725017}
    case 1n++k Con{+r,+rest}:
      +half = (size / 2.0 : F32)
      +rows : List<&2,Rect> = r <> rest
      solid_or(covers(r,x,y,size),rectangle_color(r),unit => Qua{tile(k,clip(rows,x,y,half),x,y,half),tile(k,clip(rows,(x + half : F32),y,half),(x + half : F32),y,half),tile(k,clip(rows,x,(y + half : F32),half),x,(y + half : F32),half),tile(k,clip(rows,(x + half : F32),(y + half : F32),half),(x + half : F32),(y + half : F32),half)})

def image(rows: List<&2,Rect>) -> Image: tile(9n,clip(rows,0.0,0.0,512.0),0.0,0.0,512.0)
