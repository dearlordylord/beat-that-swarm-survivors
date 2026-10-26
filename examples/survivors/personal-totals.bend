import Base

type Totals is Data: Totals{hit:U32,xp:U32,gold:U32,heal:U32,chest:U32,kills:U32}
type Delta is Data: Empty{} Projectile{hit:U32} Enemy{hit:U32,kills:U32} Pickup{xp:U32,gold:U32,heal:U32,chest:U32}
def add(delta:Delta,totals:Totals) -> Totals:
  match delta totals:
    case Empty{} totals: totals
    case Projectile{h} Totals{hit,x,g,he,c,k}: Totals{(hit + h : U32),x,g,he,c,k}
    case Enemy{h,n} Totals{hit,x,g,he,c,k}: Totals{(hit + h : U32),x,g,he,c,(k + n : U32)}
    case Pickup{x0,g0,he0,c0} Totals{hit,x,g,he,c,k}: Totals{hit,(x + x0 : U32),(g + g0 : U32),(he + he0 : U32),(c + c0 : U32),k}
def fold(~Row:Data,~Context:Data,~own:Context -> Row -> Row,~count:Row -> Delta,+context:Context,rows:List<&2,Row>,totals:Totals) -> Totals:
  match rows:
    case []: totals
    case row <> rest: fold(~Row,~Context,~own,~count,context,rest,add(count(own(context,row)),totals))
