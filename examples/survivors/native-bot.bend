import Base
import bot-window-single.bend as Single
import bot-window-grid.bend as Grid

def dispatch(count: U32) -> IO(Unit):
  match count:
    case 1: Single.main()
    case count: Grid.main(count)
def main() -> IO(Unit):
  do IO<Unit>:
    count : Result<&1,&1,U32 & String,String> <- IO.get_env("NIGHTFALL_BOT_COUNT")
    dispatch(Single.number(Single.environment(count),1))
