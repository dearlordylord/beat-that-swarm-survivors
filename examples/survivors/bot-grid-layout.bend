import Base

def columns(+count: U32) -> U32:
  Bool.pick(U32,U32.is_le(count,4),2,Bool.pick(U32,U32.is_le(count,16),4,8))
def depth(+count: U32) -> Nat:
  Bool.pick(Nat,U32.is_le(count,4),1n,Bool.pick(Nat,U32.is_le(count,16),2n,3n))
def rows(+count: U32) -> U32: ((count + columns(count) - 1) / columns(count) : U32)
def height(+count: U32) -> U32: (1024 / columns(count) * rows(count) : U32)
def index(row: U32,column: U32,stride: U32) -> U32: (row * stride + column : U32)
def seed(base: U32,id: U32) -> U32: (base + id : U32)
def at(images: List<&2,Image>,index: Nat) -> Image:
  match images index:
    case [] _: Pix{725017}
    case image <> _ 0n: image
    case _ <> rest 1n+k: at(rest,k)
def tile(fuel: Nat,+images: List<&2,Image>,+row: U32,+column: U32,+side: U32,+stride: U32) -> Image:
  match fuel:
    case 0n: at(images,U32.to_nat(index(row,column,stride)))
    case 1n+ +k:
      +half = (side / 2 : U32)
      tl tr = tile(k,images,row,column,half,stride) tile(k,images,row,(column + half : U32),half,stride)
      bl br = tile(k,images,(row + half : U32),column,half,stride) tile(k,images,(row + half : U32),(column + half : U32),half,stride)
      Qua{tl,tr,bl,br}
def image(+count: U32,images: List<&2,Image>) -> Image:
  tile(depth(count),images,0,0,columns(count),columns(count))
