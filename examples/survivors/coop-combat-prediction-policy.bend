import Base
import ./projectile-contact.bend as Contact
import ./coop-prediction.bend as P
import ./coop-prediction-replay.bend as Replay
import ./body-index.bend as BI

# Detached visual combat has one clock and one canonical anchor. A prior
# presentation state is never an alternative source of projectile geometry.
def cohort_kind(+kind:U32) -> Bool: Bool.or(U32.is_eq(kind,0),Bool.or(U32.is_eq(kind,1),U32.is_eq(kind,7)))
def next_tick(tick:U32) -> U32: (tick + 1 : U32)
def from_bits(value:U32) -> F32:
  match value:
    case U32{word}: F32{word}
# Decimal JSON is read as JS binary64. Restore the native F32 ABI before any
# shared game arithmetic touches nested records received over the wire.
def normalize(value:F32) -> F32: from_bits(F32.bits(value))
def canonical(~A:Data,previous:A,fresh:A) -> A: fresh
def rebase(~A:Data,~advance:@+frame:A -> @+x:U32 -> @+y:U32 -> A,previous:A,anchor:A,prediction:P.State) -> A:
  Replay.forecast(~A,~advance,canonical(~A,previous,anchor),prediction)
type Witness is Data: Witness{kind:U32,tick:U32,shot:U32,target:U32,shotBirth:U32,targetBirth:U32,x0:F32,y0:F32,x1:F32,y1:F32,ex0:F32,ey0:F32,ex1:F32,ey1:F32,radius:F32,time:F32}
def record(impact:Contact.Impact,tick:U32,shot:U32,target:U32,x0:F32,y0:F32,x1:F32,y1:F32,ex0:F32,ey0:F32,ex1:F32,ey1:F32,radius:F32) -> Maybe<&2,Witness>:
  match impact:
    case Contact.Miss{}: None{}
    case Contact.Hit{time}: Some{Witness{0,tick,shot,target,0,0,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,time}}
def witness(tick:U32,shot:U32,target:U32,+x0:F32,+y0:F32,+x1:F32,+y1:F32,+ex0:F32,+ey0:F32,+ex1:F32,+ey1:F32,+radius:F32) -> Maybe<&2,Witness>:
  record(Contact.sweep(x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius),tick,shot,target,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius)
def point_record(hit:Bool,tick:U32,shot:U32,target:U32,+x:F32,+y:F32,+ex:F32,+ey:F32,radius:F32) -> Maybe<&2,Witness>:
  match hit:
    case False{}: None{}
    case True{}: Some{Witness{1,tick,shot,target,0,0,x,y,x,y,ex,ey,ex,ey,radius,0.0}}
def ttl_ticks() -> U32: 4
def recent(+now:U32,value:Witness) -> Bool:
  match value:
    case Witness{_,tick,_,_,_,_,_,_,_,_,_,_,_,_,_,_}: U32.is_lt((now - tick : U32),ttl_ticks())
def stamp_births(+births:BI.Index<U32>,value:Witness) -> Witness:
  match value:
    case Witness{kind,tick,+shot,+target,_,_,x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,time}: Witness{kind,tick,shot,target,BI.get(~U32,births,shot,0),BI.get(~U32,births,target,0),x0,y0,x1,y1,ex0,ey0,ex1,ey1,radius,time}
