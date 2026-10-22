# Headless PPM export of the exact Image returned by the native game view.
import Base
import native.bend as N

def quadrant(+right: Bool,bottom: Bool,tl: Image,tr: Image,bl: Image,br: Image) -> Image:
  Bool.pick(Image,bottom,Bool.pick(Image,right,br,bl),Bool.pick(Image,right,tr,tl))
def pixel_go(fuel: Nat,image: Image,+x: U32,+y: U32,+size: U32) -> U32:
  match fuel image:
    case 0n Pix{color}: color
    case 0n Qua{_,_,_,_}: 0
    case 1n+p Pix{color}: color
    case 1n+p Qua{tl,tr,bl,br}:
      +half = U32.max(1,(size / 2 : U32))
      pixel_go(p,quadrant(U32.is_ge(x,half),U32.is_ge(y,half),tl,tr,bl,br),(x % half : U32),(y % half : U32),half)
def pixel(image: Image,x: U32,y: U32,size: U32) -> U32: pixel_go(10n,image,x,y,size)
def rgb(+color: U32,tail: List<&2,U32>) -> List<&2,U32>:
  (U32.shrn(color,16n) % 256 : U32) <> (U32.shrn(color,8n) % 256 : U32) <> (color % 256 : U32) <> tail
def row(fuel: Nat,+image: Image,+x: U32,+y: U32) -> List<&2,U32>:
  match fuel:
    case 0n: []
    case 1n+p: rgb(pixel(image,x,y,512),row(p,image,(x + 1 : U32),y))
def checked_status(file: File,result: Result<&1,&1,U32 & String,Unit>) -> IO(File):
  match result:
    case Done{_}: IO.pure(File,file)
    case Fail{_}:
      do IO<File>:
        File.close(file)
        IO.die(File,1,"PPM write failed")
def checked(result: File & Result<&1,&1,U32 & String,Unit>) -> IO(File):
  match result:
    case (file,status): checked_status(file,status)
def rows(fuel: Nat,+image: Image,+y: U32,file: File) -> IO(Unit):
  match fuel:
    case 0n: File.close(file)
    case 1n+p:
      do IO<Unit>:
        result : File & Result<&1,&1,U32 & String,Unit> <- File.write_bytes(file,row(512n,image,0,y))
        file : File <- checked(result)
        rows(p,image,(y + 1 : U32),file)
def save(path: String,+image: Image) -> IO(Unit):
  do IO<Unit>:
    file : File <- IO.try(File,File.open(path,"w"))
    header : File & Result<&1,&1,U32 & String,Unit> <- File.write(file,"P6\n512 512\n255\n")
    file : File <- checked(header)
    rows(512n,image,0,file)
def saved_view(path: String,result: N.Native & Image) -> IO(N.Native):
  match result:
    case (state,image):
      do IO<N.Native>:
        save(path,image)
        return state
def view(path: String,state: N.Native) -> IO(N.Native): saved_view(path,N.view(state))
