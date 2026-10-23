import Base

type Answer is Data: Answer{checksum:U32,valid:Bool}
def join(a:Answer,b:Answer) -> Answer:
  match a b:
    case Answer{x,ok} Answer{y,good}: Answer{(x + y : U32),Bool.and(ok,good)}
def text(value:Result<&1,&1,U32 & String,String>) -> String:
  match value:
    case Done{s}:s
    case Fail{_}:""
def number(value:Maybe<&2,U32>,fallback:U32) -> U32:
  match value:
    case Some{n}:n
    case None{}:fallback
def parsed(s:String,fallback:U32) -> U32:number(U32.read(s),fallback)
def report(probe:String,iterations:U32,result:Answer) -> IO(Unit):
  match result:
    case Answer{_,False{}}:IO.die(Unit,1,"Probe storage/model mismatch")
    case Answer{checksum,True{}}:IO.print("{\"type\":\"probe\",\"probe\":\"" ++ probe ++ "\",\"checksum\":" ++ U32.show(checksum) ++ ",\"iterations\":" ++ U32.show(iterations) ++ ",\"jobs\":8}")
