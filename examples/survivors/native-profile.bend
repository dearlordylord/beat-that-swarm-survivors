# Native run observations and file IO adapt the proved profile economy.
import Base
import game.bend as G
import native-economy.bend as E
import native-record.bend as R
import native-profile-codec.bend as Codec

def receipt(run: G.Run) -> R.Receipt:
  match run:
    case G.Run{phase,tick,_,_,_,_,_,_,level,kills,gained,character,weapons,_,_,seed,stage,_,_,revivals,bosses,_,_,_,_,_,_,enemies,relic}:
      R.Receipt{phase,tick,level,kills,gained,character,weapons,seed,stage,revivals,bosses,enemies,relic}
def record(profile: E.Profile,run: G.Run) -> E.Profile: R.record(profile,receipt(run))
def loaded_text(result: Result<&1,&1,U32 & String,String>) -> E.Profile:
  match result:
    case Fail{_}: E.fresh()
    case Done{text}: Codec.decode(text)
def loaded_read(read: File & Result<&1,&1,U32 & String,String>) -> IO(E.Profile):
  match read:
    case (file,result):
      do IO<E.Profile>:
        File.close(file)
        return loaded_text(result)
def loaded(opened: Result<&1,&1,U32 & String,File>) -> IO(E.Profile):
  match opened:
    case Fail{_}: IO.pure(E.Profile,E.fresh())
    case Done{file}:
      do IO<E.Profile>:
        read : File & Result<&1,&1,U32 & String,String> <- File.read(file,8192)
        loaded_read(read)
def load() -> IO(E.Profile):
  do IO<E.Profile>:
    opened : Result<&1,&1,U32 & String,File> <- File.open("nightfall-profile.txt","r")
    loaded(opened)
def moved(result: Result<&1,&1,U32 & String,U32 & (String & String)>) -> IO(Unit):
  match result:
    case Fail{_}: IO.print_err("Could not save native profile: replacing file failed.")
    case Done{(status,(_,error))}:
      IO.print_err(error ++ U32.show(status))
def moved_status(result: Result<&1,&1,U32 & String,U32 & (String & String)>) -> IO(Unit):
  match result:
    case Done{(0,_)}: IO.pure(Unit,Unit{})
    case result: moved(result)
def saved_result(result: Result<&1,&1,U32 & String,Unit>) -> IO(Unit):
  match result:
    case Fail{_}: IO.print_err("Could not save native profile: writing file failed.")
    case Done{_}:
      do IO<Unit>:
        result : Result<&1,&1,U32 & String,U32 & (String & String)> <- Process.run("/bin/mv",["-f","nightfall-profile.tmp","nightfall-profile.txt"],"",4096,2000)
        moved_status(result)
def saved_write(written: File & Result<&1,&1,U32 & String,Unit>) -> IO(Unit):
  match written:
    case (file,result):
      do IO<Unit>:
        File.close(file)
        saved_result(result)
def saved(opened: Result<&1,&1,U32 & String,File>,profile: E.Profile) -> IO(Unit):
  match opened:
    case Fail{_}: IO.print_err("Could not save native profile: opening file failed.")
    case Done{file}:
      do IO<Unit>:
        written : File & Result<&1,&1,U32 & String,Unit> <- File.write(file,Codec.encode(profile))
        saved_write(written)
def save(profile: E.Profile) -> IO(Unit):
  do IO<Unit>:
    opened : Result<&1,&1,U32 & String,File> <- File.open("nightfall-profile.tmp","w")
    saved(opened,profile)
