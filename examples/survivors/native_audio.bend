import Base

# Short procedural monophonic cues use Bend's native Audio effect. Failed audio
# initialization is nonfatal: the game still has every visual and input path.
def samples(fuel: Nat,+index: U32,+frequency: F32,+length: F32) -> List<&2,F32>:
  match fuel:
    case 0n: []
    case 1n+k:
      (F32.sin((U32.to_f32(index) * frequency * 6.283185 / 44100.0 : F32)) * 0.12 * (1.0 - U32.to_f32(index) / length) : F32) <> samples(k,(index + 1 : U32),frequency,length)
def frequency(cue: U32) -> F32:
  match cue:
    case 1: 220.0
    case 2: 660.0
    case 3: 880.0
    case _: 440.0

def written(result: Audio & U32) -> IO(Maybe<Audio>):
  (audio,count) = result
  IO.pure(Maybe<Audio>,Some{audio})
def emit(cue: U32,audio: Audio) -> IO(Maybe<Audio>):
  match cue:
    case 0: IO.pure(Maybe<Audio>,Some{audio})
    case +id: IO.bind(Audio & U32,Maybe<Audio>,Audio.write(audio,samples(441n,0,frequency(id),441.0)),written)
def play(audio: Maybe<Audio>,cue: U32) -> IO(Maybe<Audio>):
  match audio:
    case None{}: IO.pure(Maybe<Audio>,None{})
    case Some{device}: emit(cue,device)
def opened(result: Result<&1,&1,U32 & String,Audio>) -> IO(Maybe<Audio>):
  match result:
    case Fail{error}: IO.pure(Maybe<Audio>,None{})
    case Done{audio}: IO.pure(Maybe<Audio>,Some{audio})
def open() -> IO(Maybe<Audio>): IO.bind(Result<&1,&1,U32 & String,Audio>,Maybe<Audio>,Audio.open(44100),opened)
def close(audio: Maybe<Audio>) -> IO(Unit):
  match audio:
    case None{}: IO.pure(Unit,Unit{})
    case Some{device}: Audio.close(device)
