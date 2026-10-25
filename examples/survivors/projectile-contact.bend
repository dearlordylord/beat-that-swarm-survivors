import Base

# A tick is the straight interpolation between the authoritative endpoints.
# Area fields use the game's separate point-contact path.
type Target is Data: Target{seed:U32,x0:F32,y0:F32,x1:F32,y1:F32,radius:F32}
type Contact is Data: Contact{seed:U32,time:F32}
type Impact is Data:
  Miss{}
  Hit{time:F32}

def within_tick(inside:Bool,time:F32) -> Impact:
  match inside:
    case True{}: Hit{time}
    case False{}: Miss{}
def root_time(+b:F32,+c:F32,+disc:F32) -> Impact:
  +time = (c / ((0.0 - b) + F32.sqrt(disc)) : F32)
  within_tick(Bool.and(F32.is_le(0.0,time),F32.is_le(time,1.0)),time)
def discriminant_valid(valid:Bool,b:F32,c:F32,disc:F32) -> Impact:
  match valid:
    case True{}: root_time(b,c,disc)
    case False{}: Miss{}
def moving_towards(valid:Bool,+a:F32,+b:F32,+c:F32) -> Impact:
  match valid:
    case False{}: Miss{}
    case True{}:
      +disc = (b * b - a * c : F32)
      discriminant_valid(F32.is_le(0.0,disc),b,c,disc)
def initial_overlap(overlap:Bool,+a:F32,+b:F32,c:F32) -> Impact:
  match overlap:
    case True{}: Hit{0.0}
    case False{}: moving_towards(Bool.and(F32.is_lt(0.0,a),F32.is_lt(b,0.0)),a,b,c)
def relative(+rx:F32,+ry:F32,+dx:F32,+dy:F32,+radius:F32) -> Impact:
  +c = (rx * rx + ry * ry - radius * radius : F32)
  initial_overlap(F32.is_le(c,0.0),(dx * dx + dy * dy : F32),(rx * dx + ry * dy : F32),c)
def sweep(+x0:F32,+y0:F32,x1:F32,y1:F32,+ex0:F32,+ey0:F32,ex1:F32,ey1:F32,radius:F32) -> Impact:
  relative((x0 - ex0 : F32),(y0 - ey0 : F32),((x1 - x0) - (ex1 - ex0) : F32),((y1 - y0) - (ey1 - ey0) : F32),radius)

# Accepted contact times are finite nonnegative values, so IEEE payload order
# agrees with time order. The seed breaks equal-time ties independently of ECS order.
def time_word(time:F32) -> U32:
  match time:
    case F32{word}: U32{word}
def tie_order(order:Cmp,left:U32,right:U32) -> Cmp:
  match order:
    case EQ{}: U32.cmp(left,right)
    case LT{}: LT{}
    case GT{}: GT{}
def compare(left:Contact,right:Contact) -> Cmp:
  match left right:
    case Contact{a,ta} Contact{b,tb}: tie_order(U32.cmp(time_word(ta),time_word(tb)),a,b)
def comes_first(left:Contact,right:Contact) -> Bool:
  Cmp.is_le(compare(left,right))
def insert_at(before:Bool,+item:Contact,+head:Contact,+tail:List<&2,Contact>,later:List<&2,Contact>) -> List<&2,Contact>:
  match before:
    case True{}: item <> head <> tail
    case False{}: head <> later
def insert(+item:Contact,rows:List<&2,Contact>) -> List<&2,Contact>:
  match rows:
    case []: item <> []
    case +head <> +tail: insert_at(comes_first(item,head),item,head,tail,insert(item,tail))
def contains(rows:List<&2,U32>,+seed:U32) -> Bool:
  match rows:
    case []: False{}
    case head <> tail: Bool.or(U32.is_eq(head,seed),contains(tail,seed))
def add(seed:U32,impact:Impact,rows:List<&2,Contact>) -> List<&2,Contact>:
  match impact:
    case Hit{time}: insert(Contact{seed,time},rows)
    case Miss{}: rows
def collect(visited:Bool,seed:U32,impact:Impact,rows:List<&2,Contact>) -> List<&2,Contact>:
  match visited:
    case True{}: rows
    case False{}: add(seed,impact,rows)
def contacts(rows:List<&2,Target>,+x0:F32,+y0:F32,+x1:F32,+y1:F32,+radius:F32,+visited:List<&2,U32>) -> List<&2,Contact>:
  match rows:
    case []: []
    case Target{+seed,ex0,ey0,ex1,ey1,r} <> tail:
      collect(contains(visited,seed),seed,sweep(x0,y0,x1,y1,ex0,ey0,ex1,ey1,(radius + r : F32)),contacts(tail,x0,y0,x1,y1,radius,visited))
def ids(rows:List<&2,Contact>) -> List<&2,U32>:
  match rows:
    case []: []
    case Contact{seed,_} <> tail: seed <> ids(tail)
def first_ids(budget:U32,rows:List<&2,Contact>) -> List<&2,U32>:
  ids(List.take(&2,Contact,rows,U32.to_nat(budget)))
