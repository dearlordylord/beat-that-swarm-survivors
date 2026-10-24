import Base
import protocol.bend as P

def encoded(result: P.Send) -> IO(Unit):
  match result:
    case P.Send{_,True{},wire,_,_,_}: IO.print(wire)
    case P.Send{_,False{},_,_,_,reason}: IO.print("REJECT|" ++ reason)
def decoded(result: P.Receive) -> IO(Unit):
  match result:
    case P.Receive{_,True{},seq,text,_}: IO.print("ACCEPT|" ++ U32.show(seq) ++ "|" ++ text)
    case P.Receive{_,False{},_,_,reason}: IO.print("REJECT|" ++ reason)
def command(args: List<String>) -> IO(Unit):
  match args:
    case _ <> "encode" <> text <> []: encoded(P.send(P.fresh(),text))
    case _ <> "decode" <> wire <> []: decoded(P.receive(P.fresh(),wire))
    case _: IO.die(Unit,2,"Usage: protocol-native encode TEXT | decode WIRE")
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    command(args)
