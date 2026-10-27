import Base
import bot-window-single.bend as Single
import bot-window-grid.bend as Grid
import bot-window-stream.bend as Stream

def dispatch(count: U32) -> IO(Unit):
  match count:
    case 1: Single.main()
    case count: Grid.main(count)
def selected(stream: String,count: U32) -> IO(Unit):
  match stream:
    case "1": Stream.main()
    case _: dispatch(count)
def main() -> IO(Unit):
  do IO<Unit>:
    count : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_COUNT")
    stream : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_STREAM")
    selected(Single.environment(stream),Single.number(Single.environment(count),1))
