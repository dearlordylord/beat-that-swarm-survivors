import Base
import native_audio.bend as A

# Exercise the generated native synthesis code and report actual runtime cost.
def energy(rows: List<&2,F32>) -> F32:
  match rows:
    case []: 0.0
    case sample <> rest: (F32.abs(sample) + energy(rest) : F32)
def busy_voices(+index: U32) -> List<&2,A.Voice>:
  [A.Voice{0,index,4096,0.005,0.8},A.Voice{1,index,4096,0.010,0.8},A.Voice{1,index,4096,0.015,0.8},A.Voice{2,index,4096,0.020,0.8},A.Voice{2,index,4096,0.025,0.8},A.Voice{3,index,4096,0.003,0.8},A.Voice{4,index,4096,0.004,0.8},A.Voice{5,index,4096,0.010,0.8},A.Voice{6,index,4096,0.010,0.8},A.Voice{7,index,4096,0.010,0.8}]
def bench(fuel: Nat,+index: U32) -> F32:
  match fuel:
    case 0n: 0.0
    case 1n+k: (energy(A.samples(1024n,index,busy_voices(index))) + bench(k,(index + 1024 : U32)) : F32)
def measured(start: Nat,sum: F32) -> IO(Unit):
  do IO<Unit>:
    end : Nat <- IO.now()
    IO.print("PCM_BENCH voices=10 frames=22528 elapsed_ms=" ++ Nat.show(Nat.sub(end,start)) ++ " energy=" ++ F32.show(sum))
def main() -> IO(Unit):
  do IO<Unit>:
    start : Nat <- IO.now()
    measured(start,bench(22n,0))
