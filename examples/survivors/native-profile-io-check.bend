import Base
import native-economy.bend as P
import native-profile.bend as Storage
import native-profile-codec.bend as Codec

def expect(ok: Bool,label: String) -> IO(Unit):
  match ok:
    case True{}: IO.print("PASS " ++ label)
    case False{}: IO.die(Unit,1,"FAIL " ++ label)
def raw_written(written: File & Result<&1,&1,U32 & String,Unit>) -> IO(Unit):
  match written:
    case (file,Done{_}): File.close(file)
    case (file,Fail{_}):
      do IO<Unit>:
        File.close(file)
        IO.die(Unit,1,"could not write profile fixture")
def raw_opened(opened: Result<&1,&1,U32 & String,File>,text: String) -> IO(Unit):
  match opened:
    case Fail{_}: IO.die(Unit,1,"could not open profile fixture")
    case Done{file}:
      do IO<Unit>:
        written : File & Result<&1,&1,U32 & String,Unit> <- File.write(file,text)
        raw_written(written)
def raw_profile(text: String) -> IO(Unit):
  do IO<Unit>:
    opened : Result<&1,&1,U32 & String,File> <- File.open("nightfall-profile.txt","w")
    raw_opened(opened,text)
def main() -> IO(Unit):
  +profile = P.stamp(P.put(P.fresh(),0,2500),500)
  do IO<Unit>:
    Storage.save(profile)
    +loaded : P.Profile <- Storage.load()
    expect(String.eq(Codec.encode(loaded),Codec.encode(profile)),"native file persistence")
    expect(Bool.and(P.settled(loaded),U32.is_eq(P.last_seed(loaded),P.last_seed(profile))),"terminal receipt survives file persistence")
    raw_profile("bad save")
    invalid : P.Profile <- Storage.load()
    expect(String.eq(Codec.encode(invalid),Codec.encode(P.fresh())),"invalid file rejected")
    raw_profile("NIGHTFALL1\n0\n")
    truncated : P.Profile <- Storage.load()
    expect(String.eq(Codec.encode(truncated),Codec.encode(P.fresh())),"truncated file rejected")
    IO.print("NATIVE PROFILE IO PASS")
